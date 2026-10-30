-- Physics Lab 1: identical initial states, independent solver instances.
-- Run from project root AFTER building fpslab DLL/.so:
--     luajit experiments/physics_lab/run.lua [runs=6] [steps=450]
-- Does not load the game, mutate scores, or use a graphics context.
local F=require('experiments.physics_lab.fixtures')
local M=require('experiments.physics_lab.metrics')
local Old=require('experiments.physics_lab.old')
local Native=require('experiments.physics_lab.fps')
local scene=require('src.data.dice_scene_schema').box
local runs=tonumber(arg and arg[1]) or 6
local steps=tonumber(arg and arg[2]) or F.default_steps
assert(runs>=1 and runs<=200 and runs%1==0,'runs must be an integer 1..200')
assert(steps>=20 and steps<=3000 and steps%1==0,'steps must be an integer 20..3000')
local output='experiments/physics_lab/build/results.csv'
local csv=assert(io.open(output,'w'))
csv:write('seed,solver,steps,seconds_cpu,samples,overlap_events,max_overlap,airborne_sleep_events,floor_penetration_events,max_floor_penetration,settle_s,unsettled,invalid_faces,face1,face2,face3,face4,face5,face6\n')
local function measure(solver,rows,steps)
 local world,count=solver.new(rows)
 local stats=M.new()
 local t0=os.clock()
 for i=1,steps do
  solver.step(world,F.dt)
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
  s.unsettled,s.invalid_faces}
 for i=1,6 do columns[#columns+1]=s.faces[i] end
 csv:write(table.concat(columns,',')..'\n')
 local acc=totals[name] or {runs=0,cpu=0,overlaps=0,airborne=0,invalid=0,unsettled=0,penetration=0}
 acc.runs=acc.runs+1
 acc.cpu=acc.cpu+s.cpu
 acc.overlaps=acc.overlaps+s.overlap_events
 acc.airborne=acc.airborne+s.airborne_sleep_events
 acc.invalid=acc.invalid+s.invalid_faces
 acc.unsettled=acc.unsettled+s.unsettled
 acc.penetration=math.max(acc.penetration,s.max_overlap)
 totals[name]=acc
 print(string.format('seed %d | %-6s | overlap samples %d | max depth %.4f | airborne sleep %d | unsettled %d | invalid faces %d | CPU %.3fs',
  seed,name,s.overlap_events,s.max_overlap,s.airborne_sleep_events,
  s.unsettled,s.invalid_faces,s.cpu))
end
for i=1,runs do
 local seed=1337+(i-1)*7919
 local rows=F.generate(seed)
 for _,source in ipairs({{name='legacy',solver=Old},{name='FPS',solver=Native}}) do
  local s=measure(source.solver,rows,steps)
  record(seed,source.name,s,steps)
 end
end
csv:close()
for _,name in ipairs({'legacy','FPS'}) do
 local t=assert(totals[name])
 print(string.format('SUMMARY %s: %.3fs average CPU/run; %d overlapping pair-samples; max depth %.4f; %d airborne-sleep samples; %d invalid face finishes; %d still moving',
  name,t.cpu/t.runs,t.overlaps,t.penetration,t.airborne,t.invalid,t.unsettled))
end
print('CSV: '..output)
print('NOTE: native FPS uses convex static rim/floor, legacy has its existing wall rules. These results are preliminary, not a controlled fairness/equity test.')
