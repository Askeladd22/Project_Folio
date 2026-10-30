-- GPU portrait of an already accepted physical die for the shelf HUD.
-- Captures once per held die, without stepping physics or changing a score.
local P={}
local images={}
local function physical_pose(entry)
 local body=assert(entry.body,'die body required')
 local copy={position={0,0,0}}
 for i,v in ipairs(body) do copy[i]={v[1],v[2],v[3]} end
 return copy
end
P.physical_pose=physical_pose
function P.capture(entry,projection)
 assert(entry and entry.die and entry.body,'held die required')
 assert(projection and projection.pitch and projection.yaw,'tray projection required')
 local g=assert(love and love.graphics,'LÖVE graphics required')
 local models={}
 local image=nil
 g.push('all')
 local ok,result=xpcall(function()
  local g3d=require('lib.g3d')
  local Mesh=require('src.engine3d.g3d_mesh')
  local Camera=require('src.engine3d.g3d_camera')
  local body=physical_pose(entry)
  local size=112
  image=g.newCanvas(size,size)
  local v={yaw=projection.yaw,pitch=projection.pitch,distance=14.1,focus=5}
  Camera.apply(v,g3d.camera,size,size,150)
  g.origin()
  g.setCanvas({image,depth=true})
  g.clear(0,0,0,0,true,1)
  g.setDepthMode('lequal',true)
  g.setShader()
  g.setColor(1,1,1,1)
  g.setBlendMode('alpha','alphamultiply')
  for face_idx,face in ipairs(entry.die.faces) do
   local key=entry.die.faceValueMap[face_idx]
   local texture
   if #face==4 and key and key>=1 and key<=6 then
    if not images[key] then images[key]=g.newImage('resources/dice/'..key..'.png') end
    texture=images[key]
   else
    if not images.white then
     local pixel=love.image.newImageData(1,1)
     pixel:setPixel(0,0,1,1,1,1)
     images.white=g.newImage(pixel)
    end
    texture=images.white
   end
   local vertices=Mesh.face_vertices(body,face)
   if #face==3 then
    local tint=require('src.engine3d.g3d_scenery').face_color(entry.die,face_idx)
    for _,vert in ipairs(vertices) do
     vert[9]=vert[9]*tint[1]
     vert[10]=vert[10]*tint[2]
     vert[11]=vert[11]*tint[3]
    end
   end
   local model=g3d.newModel(vertices,texture)
   models[#models+1]=model
   model:draw()
  end
  g.setDepthMode()
  g.setCanvas()
  return image
 end,debug.traceback)
 for _,model in ipairs(models) do pcall(function() model.mesh:release() end) end
 g.pop()
 if not ok then
  if image then pcall(function() image:release() end) end
  error(result)
 end
 return result
end
return P
