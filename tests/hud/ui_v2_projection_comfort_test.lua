-- Composition/physical-picking regression for the lowered g3d opponent table.
-- Presentation only: no launcher, RNG or Farkle rules are modified.
local Layout=require('src.farkle.ui').layout
local Fit=require('src.farkle.tabletop').tray_view.fit
local View=require('src.engine3d.view')
local Scene=require('src.data.dice_schema').scene
local layout=Layout.build()
assert(Layout.validate(layout))
assert(Scene.tray_camera.locked and
 math.abs(Scene.tray_camera.pitch-0.90)<1e-9 and
 Scene.tray_camera.yaw==0 and Scene.tray_camera.distance==24,
 'raised-seat camera preset must preserve yaw, distance and lock')
assert(layout.tray.x==8 and layout.tray.y==580 and
 layout.tray.w==1904 and layout.tray.h==475 and
 layout.tray.y+layout.tray.h==1055,
 'screen-space picking must include the newly visible back edge while keeping the same front')
assert(layout.host.y+layout.host.h==650 and
 layout.host.h-layout.tray.y==70,
 'board must be centered while its rear stays within the picking viewport')

local previousDice=dice
dice={}
View.yaw=Scene.tray_camera.yaw
View.cos_yaw,View.sin_yaw=math.cos(View.yaw),math.sin(View.yaw)
local owner={}
local extents={-14,14,Scene.regions.unified.y_back,
 Scene.regions.unified.y_front}
local cx,cy,scale=Fit(owner,layout.tray,View,extents)
assert(type(scale)=='number' and scale>=205 and scale<=240,
 'raised-seat board must retain readable physical die size')
assert(math.abs(View.pitch-Scene.tray_camera.pitch)<1e-9)
local _,rear=View.project(0,extents[3],0)
local rearScreen=cy+rear*scale
assert(math.abs(rearScreen-(layout.host.y+layout.host.h))<1e-5,
 'projected rear floor and illustrated opponent seam must coincide')
local front=owner.trayProjection.floorEnd
assert(front>970 and front<1030 and
 front-(layout.host.y+layout.host.h)>345,
 'the tabletop must fill the center without swallowing the player\'s view')
local _,apron=View.project(0,extents[4]+.4,-Scene.box.border_height)
local apronY=cy+apron*scale
assert(apronY>=layout.footer.y and apronY-layout.footer.y<=105 and apronY<=1080,
 'front plank must reach the lower edge behind the action plaque')
assert(cx>layout.tray.x and cx<layout.tray.x+layout.tray.w)
assert(owner.trayProjection.rect==layout.tray)
local _,backDie=View.project(0,extents[3],Scene.box.border_height/2)
assert(cy+backDie*scale>=layout.tray.y,
 'raised back-of-board dice must remain pickable in shared screen coordinates')
dice=previousDice
print('PASS raised-seat Opponent table: stable rear seam, readable physical dice and identical pick projection')
