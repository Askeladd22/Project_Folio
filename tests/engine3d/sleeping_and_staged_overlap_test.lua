-- Collisions must repair resting overlaps without waking calm dice.
require('lib.core')
love={graphics={newImage=function() end}}
local Geometry=require('src.engine3d.geometry')
local Physics=require('src.engine3d.physics')
local Collision=require('src.engine3d.die_collision')
local D=require('src.farkle.dice')
local function die(x,y,z)
 return Geometry.newD6Body(.8):set({x,y,z},{0,0,0},{0,0,0})
end
local function world()
 local w=clone(Physics.box,{timeleft=0,simulated_time=0,log_buffer={}}):
  set(100,100,100,0,.3,.6,.01)
 w.linear_damping=0;w.angular_damping=0
 return w
end
-- A pair that settles while overlapping must be corrected even if both
-- bodies are asleep (the previous solver skipped exactly this case).
do
 local w=world()
 w[1]=die(0,0,3);w[2]=die(.40,0,3)
 w[1].asleep=true;w[2].asleep=true
 assert(Collision.overlap(w[1],w[2]))
 w:update(.01)
 local overlap=Collision.overlap(w[1],w[2])
 assert(not overlap or overlap.depth<.001,
  'two sleeping cubes remained penetrated after SAT passes')
 assert(w[1].asleep and w[2].asleep,
  'separating resting cubes must not introduce a jittering wake-up')
end
-- Staging a scored cube in an occupied rear slot must find empty
-- geometry instead of leaving an immovable collider inside its neighbour.
do
 local entries={}
 for i=1,6 do
  local b=die(0,3,1)
  entries[i]={body=b}
 end
 local used={[1]=true}
 local candidate=(1-3.5)*2
 entries[2].body.position[1]=candidate
 entries[2].body.position[2]=-4.45
 entries[2].body.position[3]=.5
 D.stage_kept(entries,used)
 assert(entries[1].body._kept_solid and entries[1].body._manual_pending)
 assert(entries[1].body.position[1]~=candidate,
  'occupied rear position must be rejected')
 assert(not Collision.overlap(entries[1].body,entries[2].body),
  'staged solid die intersects unscored resting die')
 for i=2,6 do assert(not entries[i].body._kept_solid) end
end
-- Post-containment can create an overlap after the main solver: the
-- second contact pass must correct it without advancing physics time.
do
 local w=world()
 w[1]=die(0,0,3);w[2]=die(1.1,0,3)
 w[1].asleep=true;w[2].asleep=true
 local first=Collision.overlap(w[1],w[2])
 assert(not first)
 w.after_step=function()
  w[2].position[1]=.4 -- deterministic synthetic region clamp
  Collision.solve(w,nil,.01)
 end
 w:update(.01)
 local residual=Collision.overlap(w[1],w[2])
 assert(not residual or residual.depth<.001,
  'a post-boundary overlap was not corrected')
end
print('PASS resting SAT, collision-free scored rear slot and post-containment correction')
