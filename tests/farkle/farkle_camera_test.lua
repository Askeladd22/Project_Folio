local V=require('src.engine3d.view')
local T=require('src.farkle.tabletop').tray_view
package.loaded['src.core.navigation']={resolution={get_scale=function() return 1 end}}
dice={{body={position={0,0,0},{1,1,1}}}}
local owner={};local rect={x=40,y=230,w=1370,h=550}
local x,y,k=T.fit(owner,rect,V,{-7.2,7.2,-3.4,3.4})
for z=0,9 do
 dice[1].body.position={z*.3,-z*.2,z}
 local a,b,c=T.fit(owner,rect,V,{-7.2,7.2,-3.4,3.4})
 assert(x==a and y==b and k==c,'moving dice must not move the view')
 local a1=V.project(0,0,z);local b1=V.project(1,0,z)
 assert(math.abs((b1-a1)-V.cos_yaw*V.focus/V.distance)<1e-12,'orthographic width changes with height')
end
local a,b,c=V.to_camera(0,0,0);local d,e,f=V.to_camera(5,4,7)
assert(a==d and b==e and c==f,'parallel viewing rays required for orthographic culling')
local diceSchema=require('src.data.dice_schema')
local scene=diceSchema.scene
local roll=diceSchema.roll
local originalYaw=V.yaw
V.yaw=scene.tray_camera.yaw;V.cos_yaw=math.cos(V.yaw);V.sin_yaw=math.sin(V.yaw)
local region=scene.regions.unified
local extents={-region.half_back,region.half_back,region.y_back,region.y_front}
local layout=require('src.farkle.ui').layout.build()
for _,width in ipairs{1280,1920,2560} do
 local factor=width/1920
 local tray={}
 for k,v in pairs(layout.tray) do tray[k]=v*factor end
 local owner={minimalHud=true}
 local cx,cy,k=T.fit(owner,tray,V,extents)
 local _,rear=V.project(0,extents[3],0)
 local left=V.project(extents[1]-.4,extents[3]-.4,scene.box.border_height)
 local right=V.project(extents[2]+.4,extents[3]-.4,scene.box.border_height)
 local farScale=select(4,V.project(0,region.y_back,.6))
 local nearScale=select(4,V.project(0,region.y_front,.6))
 assert(nearScale/farScale>1.12 and nearScale/farScale<1.24,'dice depth cue must stay readable')
 local fraction=(right-left)*k/width
 assert(fraction>=.63 and fraction<=.70,'table must occupy 63–70% of screen width')
 assert(math.abs(cy+rear*k-(layout.host.y+layout.host.h)*factor)<1,'rear rail disconnected from portrait')
 -- Compare actual projected surfaces, not the larger render viewport.
 local seamLeft=V.project(extents[1]-.4,extents[3],0)
 local seamRight=V.project(extents[2]+.4,extents[3],0)
 assert(math.abs((cx+seamLeft*k)+(cx+seamRight*k)-width)<1 and
  cx+seamLeft*k>300*factor and cx+seamLeft*k<360*factor,
  'reframed rear wood must stay symmetric around the table')
 local _,apron=V.project(0,extents[4]+.4,-scene.box.border_height)
 local gap=layout.footer.y*factor-(cy+apron*k)
 assert(gap>=0 and gap<=20*factor,'command plaque too far from the visible front plank')
 local instructionGap=layout.idle_message.y*factor-(cy+apron*k)
 assert(instructionGap>=0 and instructionGap<=24*factor,'idle instruction detached from the visible table')
 local savedLove=love
 local time=0
 love={timer={getTime=function() return time end}}
 for frame=1,120 do
  time=frame/60
  owner.mouseThrow=frame<=60 and {group=true} or nil
  local gx,gy,gk=T.fit(owner,tray,V,extents)
  assert(math.abs((right-left)*(gk-k))<.01 and gx==cx and gy==cy,
   'group pickup or release moved the table against its fixed illustration')
 end
 love=savedLove
 local camera=require('src.engine3d.g3d.scene').camera
 for _,x in ipairs{extents[1]+.6,extents[2]-.6} do
  for _,y in ipairs{region.y_back+.6,region.y_front-.6} do
   local px,py=V.project(x,y,.6)
   local gx,gy=camera.screen(V,tray.w,tray.h,k,x,y,.6)
   assert(math.abs(gx-tray.w/2-px*k)<1e-7 and math.abs(gy-tray.h/2-py*k)<1e-7)
   local mx,my=require('src.farkle.interaction').single.world_motion(24,-18,V,k,{x,y,.6})
   local qx,qy=V.project(x+mx,y+my,.6)
   assert(math.abs((qx-px)*k-24)<1e-6 and math.abs((qy-py)*k+18)<1e-6)
   assert(cx+px*k>=tray.x and cx+px*k<=tray.x+tray.w and cy+py*k>=tray.y and cy+py*k<=tray.y+tray.h)
  end
 end
 print(string.format('PASS %d px: table %.1f%%, rear seam %.2f px',width,100*fraction,cy+rear*k-layout.host.h*factor))
end
V.yaw=originalYaw;V.cos_yaw=math.cos(V.yaw);V.sin_yaw=math.sin(V.yaw)
local eyeX,eyeY,eyeZ=V.get()
V.projection=nil
local g,h,i=V.to_camera(5,4,7);assert(g==eyeX-5 and h==eyeY-4 and i==eyeZ-7)
print('PASS stable tray framing, orthographic scale and projection-aware culling')
