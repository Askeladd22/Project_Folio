-- Physics Lab 3: support/airborne diagnostics with unchanged FPS 1.2.5.
-- Usage: luajit experiments/physics_lab/run_support.lua [runs=64] [steps=450]
-- Five distinct worlds per seed: current physics, FPS, FPS2x, FPS4x,
-- and FPS4x with optional unsupported-body wake before each FPS substep.
local F=require('experiments.physics_lab.fixtures')
local M=require('experiments.physics_lab.metrics')
local Old=require('experiments.physics_lab.old')
local FPS=require('experiments.physics_lab.fps')
local schema=require('src.data.dice_scene_schema').box
local runs=tonumber(arg and arg[1]) or 64
local steps=tonumber(arg and arg[2]) or 450
assert(runs>=1 and runs<=200 and runs%1==0,'runs must be 1..200')
assert(steps>=20 and steps<=3000 and steps%1==0,'steps must be 20..3000')
local columns={'seed','solver','dt','dice','seconds','invalid_faces','invalid_floor',
 'invalid_tilt','invalid_moving','unsettled','overlap_events','max_overlap',
 'airborne_body_steps','penetrating_body_steps','max_probe_floor_depth','wakeups','cpu_seconds'}
local filename='experiments/physics_lab/build/results-support.csv'
local out=assert(io.open(filename,'w'))
out:write(table.concat(columns,',')..'\n')
local modes={{name='current',legacy=true,substeps=1},
 {name='FPS',substeps=1},{name='FPS2x',substeps=2},
 {name='FPS4x',substeps=4},{name='FPS4x+wake',substeps=4,wake=true}}
local totals={}
for _,mode in ipairs(modes) do
 totals[mode.name]={invalid=0,floor=0,tilt=0,moving=0,airborne=0,
  penetrated=0,wakeups=0,max_depth=0,overlap=0,cpu=0,unsettled=0}
end
for index=1,runs do
 local seed=1337+(index-1)*7919
 local rows=F.generate(seed)
 for _,mode in ipairs(modes) do
  local world,count=(mode.legacy and Old or FPS).new(rows)
  local stats=M.new()
  local airborne,penetrated,max_depth,wakeups=0,0,0,0
  local t0=os.clock()
  for tick=1,steps do
   for sub=1,mode.substeps do
    if mode.legacy then Old.step(world,F.dt)
    elseif mode.wake then wakeups=wakeups+FPS.support_step(world,F.dt/mode.substeps)
    else FPS.step(world,F.dt/mode.substeps) end
    if not mode.legacy then
     local p=FPS.probe(world)
     airborne=airborne+p.airborne
     penetrated=penetrated+p.penetrating
     max_depth=math.max(max_depth,p.max_depth)
    end
   end
   if tick%10==0 or tick==steps then
    local bodies=mode.legacy and Old.snapshot(world) or FPS.snapshot(world,count)
    M.observe(stats,bodies,tick*F.dt,schema.half_x,schema.half_y)
   end
  end
  local last=mode.legacy and Old.snapshot(world) or FPS.snapshot(world,count)
  M.finish(stats,last)
  local cpu=os.clock()-t0
  local row={seed,mode.name,string.format('%.6f',F.dt/mode.substeps),#rows,
   string.format('%.2f',steps*F.dt),stats.invalid_faces,stats.invalid_floor,
   stats.invalid_tilt,stats.invalid_moving,stats.unsettled,stats.overlap_events,
   string.format('%.6f',stats.max_overlap),airborne,penetrated,
   string.format('%.6f',max_depth),wakeups,string.format('%.6f',cpu)}
  out:write(table.concat(row,',')..'\n')
  local a=totals[mode.name]
  a.invalid=a.invalid+stats.invalid_faces
  a.floor=a.floor+stats.invalid_floor
  a.tilt=a.tilt+stats.invalid_tilt
  a.moving=a.moving+stats.invalid_moving
  a.unsettled=a.unsettled+stats.unsettled
  a.overlap=a.overlap+stats.overlap_events
  a.airborne=a.airborne+airborne
  a.penetrated=a.penetrated+penetrated
  a.max_depth=math.max(a.max_depth,max_depth)
  a.wakeups=a.wakeups+wakeups
  a.cpu=a.cpu+cpu
  world=nil
  collectgarbage('collect')
 end
end
out:close()
for _,mode in ipairs(modes) do
 local a=totals[mode.name]
 local n=steps*mode.substeps*runs*F.count
 print(string.format(
  'SUPPORT %-12s invalid=%d/%d [floor=%d tilt=%d moving=%d] unsettled=%d overlaps=%d airborne_body_steps=%d/%d penetrating_body_steps=%d/%d max_depth=%.5f wakeups=%d avg_cpu=%.4fs',
  mode.name,a.invalid,runs*F.count,a.floor,a.tilt,a.moving,
  a.unsettled,a.overlap,a.airborne,n,a.penetrated,n,a.max_depth,
  a.wakeups,a.cpu/runs))
end
print('CSV: '..filename)
print('CAUTION: substep samples differ across dt; rates use body-step denominators. Awake forcing is experimental and not a contact solver fix.')
