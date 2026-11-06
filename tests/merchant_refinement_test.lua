-- Headless regression: merchant reframe and silhouette-only score feedback.
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local Opponent=require('src.features.farkle.ui_v2.opponent_scene')
local Scene=require('src.engine3d.g3d_scenery')
local Mesh=require('src.engine3d.g3d_mesh')
local View=require('src.engine3d.view')
local Tray=require('src.features.farkle.tray_view')
local L=Layout.build('table_minimal')
assert(Layout.validate(L))
assert(L.host.y+L.host.h==L.tray.y,'rear framing must meet the room')
assert(L.tray.y>=378 and L.tray.y<=398,'board not lowered 40-60px')
assert(L.tray.y+L.tray.h<=L.footer.y,'command rail clipped')
local portrait=Opponent.portrait_bounds(700,1000,L)
assert(portrait.h>350 and portrait.h<=408 and portrait.y>=9)
assert(math.abs(portrait.x+portrait.w*.5-L.tray.x-L.tray.w*.5)<.01)
assert(portrait.y+portrait.h==L.tray.y+35,'opponent not tucked behind table')
local function read(path)
 local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s
end
local overlay=read('src/features/farkle/ui_v2/overlay.lua')
local score=assert(overlay:match('local function score_mark(.-)\nend\nfunction M.draw'))
assert(not score:find('g.line(',1,true) and not score:find('glyph()',1,true),
 'scoring indicators must have no detached under-die strokes')
assert(score:find("g.polygon('line',m.outline)",1,true),
 'selection must follow the physical silhouette')
local vertices=Scene.style_vertices(Mesh,{-14,14,-6.05,6.05},.74,'merchant')
assert(#vertices>0)
local xmax=-math.huge
for _,v in ipairs(vertices) do xmax=math.max(xmax,v[1]) end
assert(xmax<=14.281,'merchant decorative rail too thick')
local oldDice,oldYaw,oldPitch,oldDistance,oldProjection=dice,View.yaw,View.pitch,View.distance,View.projection
dice={{body={position={0,0,.47},{.47,.47,.47}}}}
local schema=require('src.data.dice_scene_schema')
View.yaw,View.pitch,View.distance=schema.tray_camera.yaw,schema.tray_camera.pitch,schema.tray_camera.distance
View.cos_yaw,View.sin_yaw=math.cos(View.yaw),math.sin(View.yaw)
View.cos_pitch,View.sin_pitch=math.cos(View.pitch),math.sin(View.pitch)
for _,wh in ipairs{{1280,720},{1920,1080},{3440,1440}} do
 local factor=math.min(wh[1]/1920,wh[2]/1080)
 local offset=(wh[1]-1920*factor)*.5
 local r={x=offset+L.tray.x*factor,y=L.tray.y*factor,
          w=L.tray.w*factor,h=L.tray.h*factor}
 local owner={minimalHud=true}
 local cx,cy,scale=Tray.fit(owner,r,View,{-14,14,-6.05,6.05})
 local px,py=View.project(7,1.5,.47)
 local sx,sy=cx+px*scale,cy+py*scale
 assert(sx>r.x and sx<r.x+r.w and sy>r.y and sy<r.y+r.h,
  'D6 projection clipped at '..wh[1]..'x'..wh[2])
 assert(owner.trayProjection.cx==cx and owner.trayProjection.cy==cy and
  owner.trayProjection.scale==scale,'GPU and picking transforms diverged')
 local left=select(1,View.project(-14.4,-6.05,0))
 local right=select(1,View.project(14.4,-6.05,0))
 local fraction=(right-left)*scale/(1920*factor)
 assert(fraction>.70 and fraction<.75,'board still dominates the scene')
end
dice=oldDice
View.yaw,View.pitch,View.distance,View.projection=oldYaw,oldPitch,oldDistance,oldProjection
View.cos_yaw,View.sin_yaw=math.cos(View.yaw),math.sin(View.yaw)
View.cos_pitch,View.sin_pitch=math.cos(View.pitch),math.sin(View.pitch)

-- Use the actual UI painter with mock projected silhouettes, so this
-- catches future regressions even if another line-drawing path is added.
local R=require('src.gameplay.farkle.rules')
local Overlay=require('src.features.farkle.ui_v2.overlay')
local Bridge=require('src.core.engine_bridge')
local game=R.new()
assert(R.start(game) and R.settle(game,{1,5,2,3,4,6}))
local pointerX=0
local strokes={lines=0,polygons=0}
local hit={index=1,x=120,y=130,r=23,outline={99,110,140,112,142,151,100,153}}
local savedLove=love
love={mouse={getPosition=function()return pointerX,130 end},graphics={
 push=function()end,pop=function()end,setColor=function()end,
 setLineWidth=function()end,
 line=function()strokes.lines=strokes.lines+1 end,
 polygon=function(mode,points)
  if mode=='line' then assert(points==hit.outline);strokes.polygons=strokes.polygons+1 end
 end}}
Bridge.configure({pick_scriptorium_tray_die=function()
 return pointerX==120 and 1 or nil end})
local u={game=game}
Overlay.draw(u,{hit})
assert(strokes.lines==0 and strokes.polygons==0,
 'passive eligibility must use die-face tint, not detached marks')
pointerX=120
Overlay.draw(u,{hit})
assert(strokes.lines==0 and strokes.polygons==2,
 'hover must trace the physical silhouette')
pointerX=0
assert(R.toggle(game,1))
Overlay.draw(u,{hit})
assert(strokes.lines==0 and strokes.polygons==4,
 'scoring selection must remain outlined without hover')
love=savedLove
print('PASS merchant refinement: clean markers, thinner rim, 720p/1080p/ultrawide projection, replaceable portrait')
