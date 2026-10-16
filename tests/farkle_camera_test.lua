local V=require('src.engine3d.view')
local T=require('src.features.farkle.tray_view')
package.loaded['src.core.resolution_manager']={get_scale=function() return 1 end}
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
local scene=require('src.data.dice_scene_schema')
local roll=require('src.data.dice_roll_schema')
local originalYaw=V.yaw
V.yaw=scene.tray_camera.yaw;V.cos_yaw=math.cos(V.yaw);V.sin_yaw=math.sin(V.yaw)
local oldRect={x=70,y=84,w=1400,h=760}
local newRect={x=40,y=60,w=1460,h=808}
local oldOwner,newOwner={},{}
T.fit(oldOwner,oldRect,V,{-7.2,7.2,-3.4,3.4})
T.fit(newOwner,newRect,V,{-scene.box.half_x,scene.box.half_x,-scene.box.half_y,scene.box.half_y})
local oldWidth=oldOwner.trayProjection.front[2].x-oldOwner.trayProjection.front[1].x
local newWidth=newOwner.trayProjection.front[2].x-newOwner.trayProjection.front[1].x
local widthRatio=newWidth/oldWidth
local dieRatio=roll.sizes.base/.92*newOwner.trayScale/oldOwner.trayScale
assert(widthRatio>=1.20 and widthRatio<=1.30,'projected tray width must grow 20-30%')
assert(dieRatio>=.85 and dieRatio<=.90,'projected dice must shrink 10-15%')
assert(newRect.x+newRect.w/2==oldRect.x+oldRect.w/2 and newRect.y+newRect.h/2==oldRect.y+oldRect.h/2,'tray framing center must remain fixed')
assert(roll.spawn_layout.main.row_spacing>=2*roll.sizes.base,'initial rows need breathing room')
print(string.format('PASS tray width +%.1f%%, dice scale %.1f%%',100*(widthRatio-1),100*dieRatio))
V.yaw=originalYaw;V.cos_yaw=math.cos(V.yaw);V.sin_yaw=math.sin(V.yaw)
V.projection=nil
local g,h,i=V.to_camera(5,4,7);assert(g==d-5 and h==e-4 and i==f-7)
print('PASS stable tray framing, orthographic scale and projection-aware culling')
