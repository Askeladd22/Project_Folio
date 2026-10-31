-- The Farkle V2 HUD has ONE visual skin and ONE action hitbox table.
-- Geometry is already virtual 1920x1080; only display scaling varies.
-- No engine, dice, game rules or splash imports are modified by this test.
local R=require('src.gameplay.farkle.rules')
local P=require('src.features.farkle.presentation')
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local Surface=require('src.features.ui_v2.menu_surface')
local Res=require('src.core.resolution_manager')
unpack=unpack or table.unpack

local oldLove=love
local w,h=1920,1080
local pushes,pops=0,0
local drawCalls={}
local currentColor={}
local function fakeFont(sz)
 sz=type(sz)=='number' and sz or 18
 return {
  getWidth=function(_,v)return #tostring(v)*sz*.54 end,
  getHeight=function()return sz*1.15 end,
  getWrap=function(_,v)return #tostring(v)*sz*.54,{tostring(v)} end
 }
end
local gfx=setmetatable({
 getDimensions=function()return w,h end,
 getWidth=function()return w end,getHeight=function()return h end,
 newFont=function(a,b)return fakeFont(b or a)end,
 getFont=function()return fakeFont(18)end,
 push=function()pushes=pushes+1 end,
 pop=function()pops=pops+1 end,
 setColor=function(...)currentColor={...}end,
 rectangle=function(mode,x,y,rw,rh)
  drawCalls[#drawCalls+1]={mode=mode,x=x,y=y,w=rw,h=rh,c=currentColor}
 end,
},{__index=function()return function()end end})
love={graphics=gfx}
local Hud=require('src.features.farkle.ui_v2.hud')
local layout=Layout.build('single_folio')
assert(Layout.validate(layout))
local function matchingFill(rect)
 for _,call in ipairs(drawCalls) do
  if call.mode=='fill' and call.x==rect.x and call.y==rect.y
    and call.w==rect.w and call.h==rect.h
    and math.abs((call.c[1] or 0)-.89)<.001
    and math.abs((call.c[2] or 0)-.81)<.001
    and math.abs((call.c[3] or 0)-.65)<.001 then
   return true
  end
 end
 return false
end
for _,size in ipairs{{1920,1080},{1280,720},{2560,1440}} do
 w,h=size[1],size[2]
 Res.init(1920,1080)
 Res.refresh(w,h)
 drawCalls={}
 local game=R.new()
 local ui={game=game,presentation=P.new(game)}
 local oldBank,oldPot,oldPhase=game.bank,game.pot,game.phase
 Hud.draw(ui)
 assert(pushes==pops,'Folio HUD leaked graphics state')
 assert(matchingFill(layout.header),'header must use ink-on-parchment')
 assert(matchingFill(layout.context),'tools panel must use parchment')
 assert(ui.buttons.roll and ui.buttons.bank)
 assert(ui.buttons.help and ui.buttons.runmenu and ui.buttons.folio)
 assert(ui.buttons.roll.enabled and not ui.buttons.bank.enabled)
 assert(game.bank==oldBank and game.pot==oldPot and game.phase==oldPhase,
  'rendering is not allowed to change the Farkle state')
 for _,id in ipairs{'roll','bank','help','runmenu'} do
  local rect=ui.buttons[id]
  assert(Surface.within(rect,1920,1080),'off-viewport '..id)
  assert(Layout.overlap(layout.tray,rect)==0,
   'an action obscures the physical 3D dice plane: '..id)
 end
 assert(ui.buttons.roll.x==layout.primary.x and
   ui.buttons.roll.y==layout.primary.y and
   ui.buttons.roll.w==layout.primary.w and
   ui.buttons.roll.h==layout.primary.h,'visual/input rectangles drifted')
end
local f=assert(io.open('src/features/farkle/ui_v2/hud.lua','rb'))
local source=f:read('*a');f:close()
assert(source:find("src.features.ui_v2.menu_surface",1,true))
assert(source:find("MenuSurface.item(rect",1,true))
assert(source:find("Folio.draw(s,u.presentation",1,true))
assert(source:find("Indicators.draw(u,hits)",1,true))
assert(not source:find("hud_minimal",1,true))
love=oldLove
print('PASS Farkle HUD ink/parchment, preserved hitboxes and zero gameplay mutation at 720p/1080p/1440p')
