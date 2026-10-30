-- Adapt the existing, unmodified physics.lua to the shared fixture.
require('core')
love=love or {graphics={}}
love.graphics=love.graphics or {}
love.graphics.newImage=love.graphics.newImage or function()return nil end
local P=require('src.engine3d.physics')
local G=require('src.engine3d.geometry')
local scene=require('src.data.dice_scene_schema')
local O={}
function O.new(rows)
 local world=clone(P.box,{timeleft=0,log_buffer={}})
 world:configure(scene.box)
 for i,row in ipairs(rows) do
  local b=G.newD6Body(1.0):set(row.position,row.velocity,row.angular)
  P.materials.apply(b,P.materials.get('bone'))
  world[i]=b
 end
 return world
end
function O.step(world,dt)world:update(dt)end
function O.snapshot(world)
 local bodies={}
 for i,b in ipairs(world) do
  local verts={}
  for j=1,#b do
   verts[j]={b[j][1]+b.position[1],b[j][2]+b.position[2],
              b[j][3]+b.position[3]}
  end
  bodies[i]={position={b.position[1],b.position[2],b.position[3]},
             vertices=verts,asleep=b.asleep or false}
 end
 return bodies
end
return O
