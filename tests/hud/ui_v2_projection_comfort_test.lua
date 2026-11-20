-- Composition/physical-picking regression for the lowered g3d merchant table.
-- Presentation only: no launcher, RNG or Farkle rules are modified.
local Layout=require('src.farkle.ui').layout
local Fit=require('src.farkle.tabletop').tray_view.fit
local View=require('src.engine3d.view')
local Scene=require('src.data.dice_schema').scene
local layout=Layout.build()
assert(Layout.validate(layout))
assert(Scene.tray_camera.locked and
 math.abs(Scene.tray_camera.pitch-1.16)<1e-9 and
 Scene.tray_camera.yaw==0 and Scene.tray_camera.distance==52,
 'approved modest top-down preset must retain yaw, distance and camera lock')
assert(layout.tray.x==60 and layout.tray.y==538 and
 layout.tray.w==1800 and layout.tray.h==426,
 'do not move the physical mouse hitbox to fake a camera fix')
assert(layout.host.y+layout.host.h>=650,
 'rear rail should be lower than the original 614px opponent seam')

local previousDice=dice
dice={}
View.yaw=Scene.tray_camera.yaw
View.cos_yaw,View.sin_yaw=math.cos(View.yaw),math.sin(View.yaw)
local owner={}
local extents={-14,14,Scene.regions.unified.y_back,
 Scene.regions.unified.y_front}
local cx,cy,scale=Fit(owner,layout.tray,View,extents)
assert(type(scale)=='number' and scale>460,
 'lowering the camera must not make physical dice hard to read')
assert(math.abs(View.pitch-Scene.tray_camera.pitch)<1e-9)
local _,rear=View.project(0,extents[3],0)
local rearScreen=cy+rear*scale
assert(math.abs(rearScreen-(layout.host.y+layout.host.h))<1e-5,
 'projected rear floor and illustrated opponent seam must coincide')
local front=owner.trayProjection.floorEnd
assert(front>880 and front<910,
 'a slightly top-down view must shorten the visible tabletop depth')
local _,apron=View.project(0,extents[4]+.4,-Scene.box.border_height)
local apronY=cy+apron*scale
assert(apronY<=layout.footer.y and layout.footer.y-apronY<=20,
 'front plank must stay close to the command plaque after camera tilt')
assert(cx>layout.tray.x and cx<layout.tray.x+layout.tray.w)
assert(owner.trayProjection.rect==layout.tray)
dice=previousDice
print('PASS lowered merchant table: shared projection, useful die scale and unchanged physical hitbox')
