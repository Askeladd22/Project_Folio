-- Scored D6: kinematic solid, unlike a pending/held D6.
require('lib.core')
love={graphics={newImage=function() end}}
local Physics=require('src.engine3d.physics')
local Geometry=require('src.engine3d.geometry')
local function world()
 local w=clone(Physics.box,{timeleft=0,log_buffer={},simulated_time=0}):
  set(100,100,100,0,.3,.6,.01)
 w.linear_damping=0;w.angular_damping=0;w.sleep_linear=0
 w.sleep_angular=0;w.sleep_time=1e5
 return w
end
local function die(x,vx)
 return Geometry.newD6Body(.8):set({x,0,3},{vx or 0,0,0},{0,0,0})
end
local function close(a,b) return math.abs(a-b)<1e-8 end
local parked=die(0,0)
parked._manual_pending=true
parked._kept_solid=true
parked.asleep=true
local moving=die(1.25,-60)
local w=world();w[1]=parked;w[2]=moving
local impacts=0
w.on_contact=function(_,kind,i,j,speed)
 if kind=='pair' then
  assert(i==1 and j==2 and speed>0)
  impacts=impacts+1
 end
end
w:update(.01)
assert(impacts>=1,'released die passed through parked solid D6')
assert(close(parked.position[1],0) and close(parked.position[2],0)
 and close(parked.position[3],3),'set-aside D6 moved')
assert(parked.asleep and parked._manual_pending and parked._kept_solid)
assert(close(parked.velocity[1],0) and close(parked.angular[1],0),
 'parked die must not acquire speed or spin')
assert(moving.position[1]>0.5 and moving.velocity[1]>-60,
 'active die must react to scored cube')
-- A pending hand remains non-colliding, not a stationary obstacle.
local held=die(0,0);held._manual_pending=true;held.asleep=true
local active=die(1.25,-60)
local w2=world();w2[1]=held;w2[2]=active
local phantom=0
w2.on_contact=function(_,kind)if kind=='pair' then phantom=phantom+1 end end
w2:update(.01)
assert(phantom==0 and close(held.position[1],0),
 'ordinary pending D6 must remain non-colliding')
-- New turn re-enables the scored die without changing its rest geometry.
local rest={}
for k,v in ipairs(parked) do rest[k]={v[1],v[2],v[3]} end
require('src.farkle.dice').stage_opening({{body=parked,restPose=rest}})
assert(not parked._kept_solid and not parked._manual_pending,
 'the new hand must restore normal D6 collisions')
print('PASS solid scored D6 / nonsolid held D6 / stage reactivation')
