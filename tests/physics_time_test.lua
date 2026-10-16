require('core')
love={graphics={newImage=function() end}}
local P=require('src.engine3d.physics')
local G=require('src.engine3d.geometry')
local function world()
 local w=clone(P.box,{timeleft=0,log_buffer={}}):set(100,100,100,0,.25,.75,.01)
 local a=G.newD6Body(.92):set({0,0,5},{1,0,0},{0,0,0});a.linear_damping=0;a.angular_damping=0;w[1]=a;return w,a
end
local w,a=world();w[2]=G.newD6Body(.92):set({1,0,5},{0,0,0},{0,0,0});w:update(0)
assert(a.position[1]==0 and w[2].position[1]==1,'update(0) must not separate bodies')
for _,hz in ipairs{20,30,60,144} do w,a=world();local calls=0;w.after_step=function(_,dt) assert(dt==.01);calls=calls+1 end
 for i=1,hz do w:update(1/hz) end
 assert(math.abs(a.position[1]-1)<1e-10,'lost physical time at '..hz)
 assert(calls==100,'constraints must execute once per fixed step')
end
w,a=world();w:update(1);assert(a.position[1]<=.05000001,'bounded work');assert(w.timeleft>0,'preserve backlog');assert(w.dropped_time>0,'report overload clipping')
local before=a.position[1];w:update(0);assert(before==a.position[1],'zero must not consume backlog')
print('PASS zero dt, 20/30/60/144Hz fixed-step clock and bounded backlog')
