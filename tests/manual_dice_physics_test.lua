-- Actual production fixed-step physics with a staged/held/released D6.
require('core')
love={graphics={newImage=function() end}}
local P=require('src.engine3d.physics')
local G=require('src.engine3d.geometry')
local Mouse=require('src.features.farkle.mouse_throw')
local function new_world()
 local world=clone(P.box,{timeleft=0,log_buffer={}}):set(9.2,3.8,10,16,.3,.6,.01)
 world.linear_damping=0
 world.angular_damping=0
 world[1]=G.newD6Body(.8):set({-3,0,3},{1,0,0},{0,0,0})
 world[2]=G.newD6Body(.8):set({2,0,3},{0,0,0},{0,0,0})
 world[2]._manual_pending=true
 world[2].asleep=true
 return world
end
local w=new_world()
local body=w[2]
local z=body.position[3]
local x=body.position[1]
for _=1,12 do w:update(.01) end
assert(body.position[1]==x and body.position[3]==z,
 'pending die must remain exactly fixed under gravity')
assert(w[1].position[3]<3,'released die must fall independently of pending body')
local orientation=body[1][1]
local gesture=assert(Mouse.begin(2,body,100,100,1))
assert(Mouse.move(gesture,130,90,1.04,
 {yaw=0,pitch=.48,focus=5,distance=14.1},25,{half_x=9.2,half_y=3.8}))
Mouse.tick(gesture,.03)
assert(body[1][1]~=orientation,'the physical vertices must tumble while held')
local now_x,now_z=body.position[1],body.position[3]
for _=1,10 do w:update(.01) end
assert(body.position[1]==now_x and body.position[3]==now_z,
 'physics solver must not fight the mouse over a held body')
local release=Mouse.release(gesture,170,55,1.08,
 {yaw=0,pitch=.48,focus=5,distance=14.1},25,{half_x=9.2,half_y=3.8})
assert(release and not body.asleep and not body._manual_pending)
local vz=body.velocity[3]
for _=1,6 do w:update(.01) end
assert(body.velocity[3]<vz or body.position[3]<now_z,
 'released body must re-enter gravity integration')
print('PASS individual dice against production physics: pending frozen, held tumble, gravity resumes')
