-- Physics Labs 1 and 2: identical initial states; Lab 2 has an explicit experimental floor guard.
-- Run from project root AFTER building fpslab DLL/.so:
--     luajit experiments/physics_lab/run.lua [runs=6] [steps=450] [baseline|lab2]
-- Does not load the game, mutate scores, or use a graphics context.
local F=require('experiments.physics_lab.fixtures')
local M=require('experiments.physics_lab.metrics')
local Old=require('experiments.physics_lab.old')
local Native=require('experiments.physics_lab.fps')
local scene=require('src.data.dice_scene_schema').box
local runs=tonumber(arg and arg[1]) or 6
local steps=tonumber(arg and arg[2]) or F.default_steps
local mode=(arg and arg[3]) or 'baseline'
assert(mode=='baseline' or mode=='lab2','mode must be baseline or lab2')
assert(runs>=1 and runs<=200 and runs%1==0,'runs must be an integer 1..200')
assert(steps>=20 and steps<=3000 and steps%1==0,'steps must be an integer 20..3000')
local output='experiments/physics_lab/build/'..(mode=='lab2' and 'results-lab2.csv' or 'results.csv')
local csv=assert(io.open(output,'w'))
csv:write('seed,solver,steps,seconds_cpu,samples,overlap_events,max_overlap,airborne_sleep_events,floor_penetration_events,max_floor_penetration,settle_s,unsettled,invalid_faces,invalid_tilt,invalid_gap,invalid_floor,invalid_moving,invalid_airborne,face1,face2,face3,face4,face5,face6,guard_corrections,max_guard_correction\n')
local function measure(solver,rows,steps)
 local world,count=solver.new(rows)
 local stats=M.new()
 stats.guard_corrections=0
 stats.max_guard_correction=0
 local t0=os.clock()
 for i=1,steps do
  local corrections,depth=solver.step(world,F.dt)
  stats.guard_corrections=stats.guard_corrections+(corrections or 0)
  stats.max_guard_correction=math.max(stats.max_guard_correction,depth or 0)
  if i%10==0 or i==steps then
   local bodies=solver.snapshot(world,count)
   M.observe(stats,bodies,i*F.dt,scene.half_x,scene.half_y)
  end
 end
 local sample=solver.snapshot(world,count)
 M.finish(stats,sample)
 stats.cpu=os.clock()-t0
 -- Keep FFI finalizer as the owner of native resources; explicitly close
 -- before reading next fixture to avoid carrying native allocation forward.
 world=nil
 collectgarbage('collect')
 return stats
end
local totals={}
local function record(seed,name,s,steps)
 local columns={seed,name,steps,string.format('%.6f',s.cpu),s.samples,
  s.overlap_events,string.format('%.6f',s.max_overlap),
  s.airborne_sleep_events,s.floor_penetration_events,
  string.format('%.6f',s.max_floor_penetration),
  s.settle_s and string.format('%.2f',s.settle_s) or 'NA',
  s.unsettled,s.invalid_faces,s.invalid_tilt,s.invalid_gap,
  s.invalid_floor,s.invalid_moving,s.invalid_airborne}
 for i=1,6 do columns[#columns+1]=s.faces[i] end
 columns[#columns+1]=s.guard_corrections
 columns[#columns+1]=string.format('%.6f',s.max_guard_correction)
 csv:write(table.concat(columns,',')..'\n')
 local acc=totals[name] or {runs=0,cpu=0,overlaps=0,airborne=0,invalid=0,unsettled=0,penetration=0,floor_penetration=0,tilt=0,gap=0,floor=0,moving=0,airborne_final=0,guard_corrections=0,max_guard_correction=0}
 acc.runs=acc.runs+1
 acc.cpu=acc.cpu+s.cpu
 acc.overlaps=acc.overlaps+s.overlap_events
 acc.airborne=acc.airborne+s.airborne_sleep_events
 acc.invalid=acc.invalid+s.invalid_faces
 acc.tilt=acc.tilt+s.invalid_tilt
 acc.gap=acc.gap+s.invalid_gap
 acc.floor=acc.floor+s.invalid_floor
 acc.moving=acc.moving+s.invalid_moving
 acc.airborne_final=acc.airborne_final+s.invalid_airborne
 acc.unsettled=acc.unsettled+s.unsettled
 acc.penetration=math.max(acc.penetration,s.max_overlap)
 acc.floor_penetration=math.max(acc.floor_penetration,s.max_floor_penetration)
 acc.guard_corrections=acc.guard_corrections+s.guard_corrections
 acc.max_guard_correction=math.max(acc.max_guard_correction,s.max_guard_correction)
 totals[name]=acc
 print(string.format('seed %d | %-6s | overlap samples %d | max depth %.4f | airborne sleep %d | unsettled %d | invalid faces %d | worst floor %.5f | CPU %.3fs',
  seed,name,s.overlap_events,s.max_overlap,s.airborne_sleep_events,
  s.unsettled,s.invalid_faces,s.max_floor_penetration,s.cpu))
end
local sources={{name='legacy',solver=Old},{name='FPS',solver=Native}}
if mode=='lab2' then
 -- Substep variants integrate exactly the same elapsed physical time.
 -- Unlike the floor guard, these do not alter upstream FPS contacts or poses.
 local function substep_solver(n)
  return {new=Native.new,snapshot=Native.snapshot,
   step=function(world,dt)
    for _=1,n do Native.step(world,dt/n) end
   end}
 end
 sources[#sources+1]={name='FPS2x',solver=substep_solver(2)}
 sources[#sources+1]={name='FPS4x',solver=substep_solver(4)}
 sources[#sources+1]={name='FPS+guard',solver={new=Native.new,
  step=Native.guarded_step,snapshot=Native.snapshot}}
end
for i=1,runs do
 local seed=1337+(i-1)*7919
 local rows=F.generate(seed)
 for _,source in ipairs(sources) do
  local s=measure(source.solver,rows,steps)
  record(seed,source.name,s,steps)
 end
end
csv:close()
for _,source in ipairs(sources) do
 local name=source.name
 local t=assert(totals[name])
 print(string.format('SUMMARY %s: %.3fs average CPU/run; %d overlapping pair-samples; max depth %.4f; %d airborne-sleep samples; %d invalid face finishes; %d still moving',
  name,t.cpu/t.runs,t.overlaps,t.penetration,t.airborne,t.invalid,t.unsettled))
 print(string.format('CAUSES %s: tilt=%d, face-gap=%d, floor=%d, moving=%d, airborne-final=%d, worst floor penetration=%.6f',
  name,t.tilt,t.gap,t.floor,t.moving,t.airborne_final,t.floor_penetration))
 if mode=='lab2' then
  print(string.format('GUARD %s: %d corrections, maximum individual raise %.6f',
   name,t.guard_corrections,t.max_guard_correction))
 end
end
print('CSV: '..output)
print('NOTE: native FPS uses convex static rim/floor, legacy has its existing wall rules. These results are preliminary, not a controlled fairness/equity test.')
if mode=='lab2' then
 print('WARNING: FPS+guard is an intervention AFTER stepping: vertical positional correction and downward velocity clamp. It is NOT upstream FPS nor evidence of a solver fix.')
 print('NOTE: FPS2x/FPS4x run 2 or 4 native 0.005/0.0025 s steps for every baseline 0.01 s step; equal simulated time, higher computation.')
end
