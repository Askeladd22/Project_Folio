-- FPS-FIX-002: angular-only contact and 3–6-body stabilization.
-- Headless production world, no renderer or gameplay stubs beyond LÖVE image.
require('lib.core')
love={graphics={newImage=function() end}}
local Physics=require('src.engine3d.physics')
local Geometry=require('src.engine3d.geometry')
local Collision=require('src.engine3d.die_collision')
local n=0
local function check(name,fn)
 fn();n=n+1;print('PASS D6 refinement '..name)
end
local function world()
 local w=clone(Physics.box,{timeleft=0,simulated_time=0,log_buffer={}}):
   set(100,100,100,0,.3,.6,.01)
 w.linear_damping=0
 w.angular_damping=0
 w.sleep_time=1e6
 return w
end
local function die(x,y,z,vx,vy,vz,wx,wy,wz)
 return Geometry.newD6Body(.8):set(
  {x or 0,y or 0,z or 3},
  {vx or 0,vy or 0,vz or 0},
  {wx or 0,wy or 0,wz or 0})
end
local function max_penetration(w)
 local depth=0
 for i=1,#w-1 do
  for j=i+1,#w do
   local hit=Collision.overlap(w[i],w[j])
   if hit and hit.depth>depth then depth=hit.depth end
  end
 end
 return depth
end
local function chain(length,passes)
 local w=world()
 w.pair_solver_passes=passes
 for i=1,length do
  w[i]=die((i-1)*.94,0,3)
 end
 return w
end

check('pure angular 90-degree sweep sees transient cube collision',function()
 local w=world()
 local spinning=die(0,0,3,0,0,0,0,0,math.pi/(2*.01))
 local target=die(1.12,0,3)
 w[1],w[2]=spinning,target
 assert(not Collision.overlap(spinning,target),
  'the angular CCD counterexample must start separated')
 local event_count=0
 w.on_contact=function(_,kind,a,b,speed)
  assert(kind=='pair' and a==1 and b==2 and speed>0)
  event_count=event_count+1
 end
 local fixed=0
 w.after_step=function(_,dt)
  assert(math.abs(dt-.01)<1e-12)
  fixed=fixed+1
 end
 w:update(.01)
 assert(w.angular_substeps and w.angular_substeps>=5,
  'high rotation must trigger several internal integration checks')
 assert(event_count>=1,'spinning D6 must contact neighbour at intermediate orientation')
 assert(event_count==1,'contact audio must only fire once per fixed tick')
 assert(fixed==1 and math.abs(w.simulated_time-.01)<1e-10,
  'substeps must not change fixed-time cadence')
end)

check('three-body chain converges faster with iterative SAT contacts',function()
 local once=chain(3,1)
 local refined=chain(3,4)
 once:update(.01);refined:update(.01)
 local a=max_penetration(once)
 local b=max_penetration(refined)
 assert(a>1e-5,'test must expose one-pass residual overlap')
 assert(b<a*.65,('four-pass solver failed to improve 3-body depth %.6f -> %.6f'):format(a,b))
 assert(b<.01,('3-body penetration too large: %.6f'):format(b))
end)

check('six interacting dice bound residual penetration',function()
 local once=chain(6,1)
 local refined=chain(6,4)
 once:update(.01);refined:update(.01)
 local a=max_penetration(once)
 local b=max_penetration(refined)
 assert(b<a,('6-body refinement did not reduce %.6f -> %.6f'):format(a,b))
 assert(b<.025,('6-body remaining depth %.6f'):format(b))
 for i=1,6 do
  assert(refined[i].position[1]==refined[i].position[1] and
         math.abs(refined[i].position[1])<10,'solver exploded')
 end
end)

check('pair audio events deduplicate across substeps and SAT passes',function()
 local w=world()
 w[1]=die(-.9,0,3,3,0,0,0,0,35)
 w[2]=die(0,0,3,0,0,0)
 w[3]=die(.9,0,3,-3,0,0,0,0,35)
 local events={}
 w.on_contact=function(_,kind,a,b)
  assert(kind=='pair')
  local key=a..':'..b
  events[key]=(events[key] or 0)+1
 end
 w:update(.01)
 local heard=0
 for _,count in pairs(events) do
  assert(count==1,'duplicate audio callback for a pair')
  heard=heard+count
 end
 assert(heard>=1,'test must include real impacts')
end)

check('normal fixed-step clocks unchanged with no rotation',function()
 local w=world()
 w[1]=die(0,0,3,1,0,0)
 local fixed=0
 w.after_step=function(_,dt) assert(dt==.01);fixed=fixed+1 end
 w:update(.03)
 assert(fixed==3)
 assert((w.angular_substeps or 0)==0)
 assert(math.abs(w.simulated_time-.03)<1e-10)
 assert(math.abs(w[1].position[1]-.03)<1e-10)
end)

check('angular substep cap is explicit and pending dice ignored',function()
 local held=world()
 held[1]=die(0,0,3,0,0,0,0,0,3000)
 held[1]._manual_pending=true
 held:update(.01)
 assert((held.angular_substeps or 0)==0)
 assert((held.angular_substep_cap_hits or 0)==0)
 local w=world()
 w[1]=die(0,0,3,0,0,0,0,0,3000)
 w:update(.01)
 assert(w.angular_substep_cap_hits==1)
 assert(w.angular_substeps==11,'12 bounded slices, not unbounded work')
end)
print('PASS D6 refinement '..n..'/6 groups')
