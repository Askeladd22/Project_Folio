-- Camera parity adapter for g3d Lab 2. Pure functions except apply().
-- The historical painter projects screen X to the right but uses a
-- left-handed screen basis. Compose that basis in the 3D view matrix,
-- never by mirroring an already rendered Canvas.
local C={}
function C.matrix(view)
 local yaw,pitch,distance=view.yaw,view.pitch,view.distance
 local c,s=math.cos(yaw),math.sin(yaw)
 local cp,sp=math.cos(pitch),math.sin(pitch)
 -- Right, screen-up, and camera-back axes; screen-up = -legacy screen Y.
 return {
  c,-s,0,0,
  -s*cp,-c*cp,sp,0,
  s*sp,c*sp,cp,-distance,
  0,0,0,1,
 }
end
function C.screen(view,w,h,scale,x,y,z)
 local m=C.matrix(view)
 local sx=m[1]*x+m[2]*y+m[3]*z+m[4]
 local sy=m[5]*x+m[6]*y+m[7]*z+m[8]
 local sz=m[9]*x+m[10]*y+m[11]*z+m[12]
 local zoom=view.focus/view.distance
 return w/2+sx*scale*zoom,h/2-sy*scale*zoom,sz
end
function C.apply(view,camera,w,h,scale)
 assert(w>0 and h>0 and scale>0,'valid viewport and zoom required')
 local m=C.matrix(view)
 for i=1,16 do camera.viewMatrix[i]=m[i] end
 camera.fov=math.pi/2
 camera.aspectRatio=w/h
 camera.updateOrthographicMatrix(h/(2*scale*(view.focus/view.distance)))
end
return C
