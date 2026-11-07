local C=require('src.engine3d.g3d.scene').camera
local V=require('src.engine3d.view')
local function nearly(a,b,label)
 assert(math.abs(a-b)<1e-7,string.format('%s: %.12f != %.12f',label,a,b))
end
for _,yaw in ipairs({-2.4,-.8,0,.2,1.7,3.0}) do
 for _,pitch in ipairs({.18,.48,1.1}) do
  local v={yaw=yaw,pitch=pitch,distance=14.1,focus=5,projection='orthographic',
   cos_yaw=math.cos(yaw),sin_yaw=math.sin(yaw),
   cos_pitch=math.cos(pitch),sin_pitch=math.sin(pitch)}
  for _,pos in ipairs({{0,0,0},{3,-2,1},{-5,4,6},{1,3,-.4},{7,-2,9}}) do
   local x,y,z=unpack(pos)
   local previous={yaw=V.yaw,pitch=V.pitch,distance=V.distance,
    focus=V.focus,projection=V.projection,
    cos_yaw=V.cos_yaw,sin_yaw=V.sin_yaw,
    cos_pitch=V.cos_pitch,sin_pitch=V.sin_pitch}
   for k,value in pairs(v) do V[k]=value end
   local oldx,oldy,oldz=V.project(x,y,z)
   for k,value in pairs(previous) do V[k]=value end
   -- Compare with the actual historical painter, not a second approximation.
   local xr=v.cos_yaw*x-v.sin_yaw*y
   local yr=v.sin_yaw*x+v.cos_yaw*y
   local py=v.cos_pitch*yr-v.sin_pitch*z
   local pz=v.sin_pitch*yr+v.cos_pitch*z
   local px=xr*v.focus/v.distance
   py=py*v.focus/v.distance
   local matrix=C.matrix(v)
   nearly(matrix[1]*x+matrix[2]*y+matrix[3]*z, xr,'camera basis X')
   nearly(matrix[5]*x+matrix[6]*y+matrix[7]*z,-(v.cos_pitch*yr-v.sin_pitch*z),'camera basis Y')
   local sx,sy,sz=C.screen(v,800,600,70,x,y,z)
   nearly(sx,400+px*70,'analytical projected x')
   nearly(sy,300+py*70,'analytical projected y')
   nearly(sz,pz-v.distance,'analytical depth parity')
   nearly(sx,400+oldx*70,'actual legacy painter X')
   nearly(sy,300+oldy*70,'actual legacy painter Y')
   nearly(sz,oldz,'actual legacy painter Z')
  end
 end
end
local mock={viewMatrix={},updateOrthographicMatrix=function()end}
local v={yaw=.2,pitch=.48,distance=14.1,focus=5}
C.apply(v,mock,900,550,61)
local m=C.matrix(v)
for i=1,16 do nearly(mock.viewMatrix[i],m[i],'matrix '..i) end
nearly(mock.aspectRatio,900/550,'aspect')
print('PASS g3d camera parity: screen X/Y and camera depth at 18 angles')

-- Exercise the real g3d projection matrix, including the off-centre canvas.
local vendor=package.loaded['lib.g3d']
package.loaded['lib.g3d']={path='lib.g3d'}
local newMatrix=require('lib.g3d.matrices')
package.loaded['lib.g3d']=vendor
local gpu={viewMatrix=newMatrix(),projectionMatrix=newMatrix()}
gpu.updateProjectionMatrix=function()
 gpu.projectionMatrix:setProjectionMatrix(gpu.fov,.01,1000,gpu.aspectRatio)
end
local function transform(matrix,vec)
 local out={}
 for row=0,3 do
  local i=row*4
  out[row+1]=matrix[i+1]*vec[1]+matrix[i+2]*vec[2]+matrix[i+3]*vec[3]+matrix[i+4]*vec[4]
 end
 return out
end
local scene=require('src.data.dice_schema').scene
local cam=scene.tray_camera
V.yaw,V.pitch,V.distance=cam.yaw,cam.pitch,cam.distance
V.cos_yaw,V.sin_yaw=math.cos(V.yaw),math.sin(V.yaw)
V.cos_pitch,V.sin_pitch=math.cos(V.pitch),math.sin(V.pitch)
V.projection='perspective'
local w,h,scale,dx,dy=1800,860,530,12,84
C.apply(V,gpu,w,h,scale,dx,dy)
for _,x in ipairs{-13,13} do
 for _,y in ipairs{-6,6} do
  for _,z in ipairs{.6,3.7,9} do
   local clip=transform(gpu.projectionMatrix,transform(gpu.viewMatrix,{x,y,z,1}))
   local px,py=V.project(x,y,z)
   nearly(w*(1+clip[1]/clip[4])/2,w/2+dx+px*scale,'GPU/pick X')
   nearly(h*(1-clip[2]/clip[4])/2,h/2+dy+py*scale,'GPU/pick Y')
  end
 end
end
print('PASS perspective GPU matrix and picking at rear/front, held and airborne heights')
