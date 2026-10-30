local C=require('src.engine3d.g3d_camera')
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
