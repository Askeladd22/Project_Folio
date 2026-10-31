-- Pure-original mouse-shake detector; no .NET/Unity/FPS dependency.
local Shake=require('src.features.farkle.shake_detector')
local Mouse=require('src.features.farkle.mouse_throw')
local Group=require('src.features.farkle.group_throw')
local scene=require('src.data.dice_scene_schema')
local view={yaw=0,pitch=.48,focus=5,distance=14.1}
local function new_body(index)
 local b={position={-3+index,0,.8},velocity={0,0,0},
  angular={0,0,0},radius=.55,asleep=true,sleep_timer=0,
  {1,1,1},{-1,-1,-1}}
 function b:update(dt)
  for _,p in ipairs(self) do p[1]=p[1]+dt*self.angular[2] end
 end
 b._manual_pending=true
 return b
end

local g=Shake.new(1,0,0,0)
assert(not Shake.sample(g,60,0,.1),'single motion cannot constitute shaking')
assert(not Shake.sample(g,0,0,.2),'one strong reversal should not yet trigger')
local impulse=Shake.sample(g,60,0,.3)
assert(impulse and g.events==1 and Shake.recent(g,.35),
 'alternating movement must trigger a single shake event')
assert(not Shake.sample(g,0,0,.32),'cooldown must prevent repeated events')
assert(g.events==1)
assert(not Shake.recent(g,2),'shake effect must expire')

local swipe=Shake.new(2,0,0,0)
for i=1,6 do
 Shake.sample(swipe,i*40,0,i*.07)
end
assert(swipe.events==0,'one-direction swipe must not be mistaken for shake')
local jitter=Shake.new(3,0,0,0)
for i=1,20 do
 Shake.sample(jitter,i%2==0 and 2 or -2,0,i*.06)
end
assert(jitter.events==0,'tiny pointer jitter must not trigger shake')
local slow=Shake.new(4,0,0,0)
Shake.sample(slow,30,0,.3)
Shake.sample(slow,0,0,.6)
Shake.sample(slow,30,0,.9)
assert(slow.events==0,'slow hand movement should not trigger shake')
local stale=Shake.new(5,0,0,0)
Shake.sample(stale,50,0,.1)
Shake.sample(stale,0,0,.2)
Shake.sample(stale,50,0,1.5)
assert(stale.events==0,'old direction changes must expire')
assert(not Shake.sample(stale,60,0,1.5),'duplicate timestamp ignored')

local body=new_body(2)
local hold=assert(Mouse.begin(2,body,0,0,10))
Mouse.move(hold,50,0,10.1,view,25,scene.box)
Mouse.move(hold,0,0,10.2,view,25,scene.box)
Mouse.move(hold,50,0,10.3,view,25,scene.box)
assert(hold.shake.events==1,'real held die must receive a confirmed shake')
local before=body[1][1]
Mouse.tick(hold,.03)
assert(body[1][1]~=before,'shake must rotate the real rigid body vertices')
local released=assert(Mouse.release(hold,50,0,10.4,view,25,scene.box))
assert(released.shake_events==1 and not body._manual_pending,
 'shake must not block normal physical release')
assert(math.abs(body.angular[1])<=14 and math.abs(body.angular[2])<=14
 and math.abs(body.angular[3])<=10,
 'shake spin must remain bounded')
local a=Mouse.begin(1,new_body(1),0,0,0)
Mouse.move(a,150,0,.1,view,25,scene.box)
local plain=assert(Mouse.release(a,150,0,.2,view,25,scene.box))
assert(plain.shake_events==0,'fast throw alone does not imply shaking')

-- A selected group uses the SAME single-die detector, without changing
-- logical Farkle roll or creating extra global random draws.
local dice={}
for i=1,3 do dice[i]={body=new_body(i),kept=false} end
local group=assert(Group.begin({1,2,3},dice,200,200,0,view,25,scene.box,2,200,200))
Group.move(group,250,200,.1,view,25,scene.box)
Group.move(group,200,200,.2,view,25,scene.box)
Group.move(group,250,200,.3,view,25,scene.box)
for _,held in ipairs(group.held) do
 assert(held.shake.events==1,'each selected die must respond to a group shake')
end
for _=1,16 do Group.tick(group,.03) end
local results=assert(Group.release(group,250,200,.4,view,25,scene.box))
assert(#results==3)
for _,r in ipairs(results) do
 assert(r.shake_events==1)
 assert(not dice[r.index].body._manual_pending)
end
print('PASS TTS-inspired shake: reversal window, immunity to jitter/swipe, actual-body tumble and group throw')
