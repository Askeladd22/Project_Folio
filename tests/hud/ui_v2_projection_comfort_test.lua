-- Composition/physical-picking regression for the lowered g3d merchant table.
-- Presentation only: no launcher, RNG or Farkle rules are modified.
local Layout=require('src.farkle.ui').layout
local Fit=require('src.farkle.tabletop').tray_view.fit
local View=require('src.engine3d.view')
local Scene=require('src.data.dice_schema').scene
local layout=Layout.build()
assert(Layout.validate(layout))
assert(Scene.tray_camera.locked and
 math.abs(Scene.tray_camera.pitch-1.00)<1e-9 and
 Scene.tray_camera.yaw==0 and Scene.tray_camera.distance==52,
 'actual overhead camera preset must retain yaw, distance and lock')
assert(layout.tray.x==60 and layout.tray.y==538 and
 layout.tray.w==1800 and layout.tray.h==426,
 'do not move the physical mouse hitbox to fake a camera fix')
assert(layout.host.y+layout.host.h>=590 and
 layout.host.y+layout.host.h<=615,
 'rear rail must be lifted to show more usable tabletop')

local previousDice=dice
dice={}
View.yaw=Scene.tray_camera.yaw
View.cos_yaw,View.sin_yaw=math.cos(View.yaw),math.sin(View.yaw)
local owner={}
local extents={-14,14,Scene.regions.unified.y_back,
 Scene.regions.unified.y_front}
local cx,cy,scale=Fit(owner,layout.tray,View,extents)
assert(type(scale)=='number' and scale>=490,
 'deeper board must retain close to the old on-screen die size')
assert(math.abs(View.pitch-Scene.tray_camera.pitch)<1e-9)
local _,rear=View.project(0,extents[3],0)
local rearScreen=cy+rear*scale
assert(math.abs(rearScreen-(layout.host.y+layout.host.h))<1e-5,
 'projected rear floor and illustrated opponent seam must coincide')
local front=owner.trayProjection.floorEnd
assert(front>900 and front<940 and
 front-(layout.host.y+layout.host.h)>300,
 'the tabletop must be appreciably deeper without clipping its front edge')
local _,apron=View.project(0,extents[4]+.4,-Scene.box.border_height)
local apronY=cy+apron*scale
assert(apronY<=layout.footer.y and layout.footer.y-apronY<=20,
 'front plank must stay close to the command plaque after camera tilt')
assert(cx>layout.tray.x and cx<layout.tray.x+layout.tray.w)
assert(owner.trayProjection.rect==layout.tray)
dice=previousDice
print('PASS true overhead Merchant board: deeper playfield, aligned projection, useful die scale and unchanged hitbox')
