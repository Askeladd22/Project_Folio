-- Nine independent single-cube contact orientation fixtures.
-- The position/orientation is controlled; FPS upstream header is unchanged.
local FPS=require('experiments.physics_lab.fps')
local M=require('experiments.physics_lab.metrics')
local pi=math.pi
local poses={
 {name='face',rx=0,ry=0,rz=0},
 {name='edge',rx=pi/4,ry=0,rz=0},
 {name='corner',rx=math.atan(math.sqrt(2)),ry=pi/4,rz=0}
}
local steps={{name='1x',dt=.01},{name='2x',dt=.005},{name='4x',dt=.0025}}
local path='experiments/physics_lab/build/results-contact-poses.csv'
local f=assert(io.open(path,'w'))
f:write('pose,step,dt,simulated_seconds,invalid,reason,airborne_body_steps,penetrating_body_steps,worst_floor_penetration,wakeups,final_height\n')
for _,pose in ipairs(poses) do
 for _,step in ipairs(steps) do
  local world,count=FPS.new({{position={0,0,3},velocity={0,0,0},
   angular={0,0,0}}})
  assert(count==1)
  FPS.set_euler(world,1,pose.rx,pose.ry,pose.rz)
  local initial=FPS.snapshot(world,count)[1]
  assert(math.abs(initial.position[3]-3)<1e-5,
   'rotation must preserve world translation')
  local n=math.floor(4.5/step.dt+.5)
  local stats=M.new()
  local airborne,penetrating,worst=0,0,0
  for i=1,n do
   FPS.step(world,step.dt)
   local probe=FPS.probe(world)
   airborne=airborne+probe.airborne
   penetrating=penetrating+probe.penetrating
   worst=math.max(worst,probe.max_depth)
   if i%math.max(1,math.floor(.10/step.dt+.5))==0 or i==n then
    M.observe(stats,FPS.snapshot(world,count),i*step.dt,9.2,3.8)
   end
  end
  local result=FPS.snapshot(world,count)[1]
  M.finish(stats,{result})
  local reason=stats.invalid_moving>0 and 'moving'
   or stats.invalid_floor>0 and 'floor'
   or stats.invalid_tilt>0 and 'tilt'
   or stats.invalid_gap>0 and 'gap' or 'valid'
  f:write(string.format('%s,%s,%.6f,%.2f,%d,%s,%d,%d,%.6f,0,%.6f\n',
   pose.name,step.name,step.dt,n*step.dt,stats.invalid_faces,reason,
   airborne,penetrating,worst,M.floor_height(result)))
  print(string.format('POSE %-6s %-2s final=%s pen_steps=%d airborne_steps=%d max_floor=%.5f',
   pose.name,step.name,reason,penetrating,airborne,worst))
 end
end
f:close()
print('CSV: '..path)
print('These isolated drops expose contacts but do NOT establish fair or reliable multi-die outcomes.')
