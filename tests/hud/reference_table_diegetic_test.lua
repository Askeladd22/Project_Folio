-- Fixed 21-Nov screenshot reference: g3d and HUD share geometry.
local UI=require('src.farkle.ui')
local L=UI.layout.build()
local S=require('src.data.dice_schema').scene
local V=require('src.engine3d.view')
local fit=require('src.farkle.tabletop').tray_view.fit
local Opp=UI.opponent_scene
assert(UI.layout.validate(L))
assert(L.host.h==650 and L.tray.y==580 and L.tray.h==475)
assert(L.score_panel.x==38 and L.opponent_panel.x==1342)
assert(UI.layout.overlap(L.score_panel,L.opponent_panel)==0)
assert(L.opponent_panel.y+L.opponent_panel.h<L.tray.y)
assert(UI.layout.overlap(L.score_panel,L.tray)==0)
assert(UI.layout.overlap(L.opponent_panel,L.tray)==0)
assert(UI.layout.overlap(L.help,L.opponent_panel)==0)
assert(UI.layout.overlap(L.runmenu,L.opponent_panel)==0)
local oldDice=dice
dice={}
local yaw=V.yaw
V.yaw=0
V.cos_yaw,V.sin_yaw=1,0
local owner={}
local ext={-14,14,S.regions.unified.y_back,S.regions.unified.y_front}
local cx,cy,scale=fit(owner,L.tray,V,ext)
local left=select(1,V.project(ext[1]-.4,ext[3],0))
local right=select(1,V.project(ext[2]+.4,ext[3],0))
local rearW=(right-left)*scale
local _,rear=V.project(0,ext[3],0)
assert(math.abs(cy+rear*scale-650)<.001)
assert(rearW>1070 and rearW<1140,'far rail must match reference')
local near=owner.trayProjection.floorEnd
assert(near>990 and near<1030,'front tabletop must fill the foreground')
local nearL=select(1,V.project(ext[1],ext[4],0))
local nearR=select(1,V.project(ext[2],ext[4],0))
assert((nearR-nearL)*scale>1580,'near edge is not visible')
local portrait=Opp.portrait_bounds(700,1000,L)
assert(portrait.h>550 and portrait.y>=0 and portrait.y+portrait.h==L.host.h)
for _,mode in ipairs({'help','runmenu'}) do
 assert(UI.layout.overlap(L[mode],L.tray)==0,'header intercepts dice: '..mode)
end
V.yaw=yaw
V.cos_yaw,V.sin_yaw=math.cos(yaw),math.sin(yaw)
dice=oldDice
print('PASS reference table: lowered rail, apron, pinned HUD, portrait, shared picking')
