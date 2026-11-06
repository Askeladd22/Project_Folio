package.path='./?.lua;./?/init.lua;'..package.path
local V=require('src.engine3d.view')
local T=require('src.features.farkle.tray_view')
package.loaded['src.core.resolution_manager']={get_scale=function() return 1 end}
dice={{body={position={0,0,0},{1,1,1}}}}
T.fit({},{x=40,y=230,w=1370,h=550},V,{-7.2,7.2,-3.4,3.4})
local scene=require('src.data.dice_scene_schema')
V.yaw=scene.tray_camera.yaw;V.cos_yaw=math.cos(V.yaw);V.sin_yaw=math.sin(V.yaw)
local region=scene.regions.unified
local ext={-region.half_back,region.half_back,region.y_back,region.y_front}
local L=require('src.features.farkle.ui_v2.layout_candidates').build('table_minimal')
for _,width in ipairs{1280,1920,2560} do
 local factor=width/1920;local tray={x=L.tray.x*factor,y=L.tray.y*factor,w=L.tray.w*factor,h=L.tray.h*factor}
 local cx,cy,k=T.fit({minimalHud=true},tray,V,ext)
 local left=V.project(ext[1]-.4,ext[3],0);local right=V.project(ext[2]+.4,ext[3],0)
 local seamleft=V.project(ext[1]-.4,ext[3],0);local seamright=V.project(ext[2]+.4,ext[3],0)
 print(width,'frac',100*(right-left)*k/width,'seam',cx+seamleft*k,cx+seamright*k,'scale',k,'host',L.host.h*factor)
end
