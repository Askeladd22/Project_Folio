-- The Farkle V2 HUD has ONE visual skin and ONE action hitbox table.
-- Geometry is already virtual 1920x1080; only display scaling varies.
-- No engine, dice, game rules or splash imports are modified by this test.
local R=require('src.farkle.rules')
local P=require('src.farkle.presentation')
local Layout=require('src.farkle.ui').layout
local Surface=require('src.screens.folio_surface').menu_surface
local Art=require('src.data.frontend_schema').palette
local Res=require('src.core.navigation').resolution
unpack=unpack or table.unpack

local oldLove=love
local w,h=1920,1080
local pushes,pops=0,0
local drawCalls={}
local currentColor={}
local mouseX,mouseY=nil,nil
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
 newImage=function()return {getWidth=function()return 944 end,getHeight=function()return 229 end}end,
 push=function()pushes=pushes+1 end,
 pop=function()pops=pops+1 end,
 setColor=function(...)currentColor={...}end,
 rectangle=function(mode,x,y,rw,rh)
  drawCalls[#drawCalls+1]={mode=mode,x=x,y=y,w=rw,h=rh,c=currentColor}
 end,
},{__index=function()return function()end end})
love={graphics=gfx,mouse={getPosition=function()return mouseX,mouseY end}}
local Hud=require('src.farkle.ui').hud
local layout=Layout.build()
assert(Layout.validate(layout))
local function sameRgb(color,name)
 local expected=Art.rgb(name)
 for i=1,3 do
  if math.abs((color[i] or 0)-expected[i])>=.001 then return false end
 end
 return true
end
local function activeFill(rect)
 for _,call in ipairs(drawCalls) do
  if call.mode=='fill' and call.x==rect.x and call.y==rect.y
   and call.w==rect.w and call.h==rect.h
   and sameRgb(call.c,'sage_light') then
   return true
  end
 end
 return false
end
local function matchingFill(rect)
 for _,call in ipairs(drawCalls) do
  if call.mode=='fill' and call.x==rect.x and call.y==rect.y
    and call.w==rect.w and call.h==rect.h
    and sameRgb(call.c,'surface') then
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
 mouseX,mouseY=Res.to_screen(layout.single_action.x+layout.single_action.w/2,
  layout.single_action.y+layout.single_action.h/2)
 local game=R.new()
 local ui={game=game,presentation=P.new(game)}
 local oldBank,oldPot,oldPhase=game.bank,game.pot,game.phase
 Hud.draw(ui)
 assert(pushes==pops,'Folio HUD leaked graphics state')
 assert(matchingFill(layout.score_panel),'scorecard must use ink-on-parchment')
 assert(activeFill(layout.single_action),'roll button should react to hover using screen-to-virtual mapping')
 assert(not activeFill(layout.secondary),'disabled action should never show hover')
 assert(ui.buttons.roll and not ui.buttons.bank)
 assert(ui.buttons.help and ui.buttons.runmenu and not ui.buttons.folio)
 assert(ui.buttons.roll.enabled)
 assert(game.bank==oldBank and game.pot==oldPot and game.phase==oldPhase,
  'rendering is not allowed to change the Farkle state')
 for _,id in ipairs{'roll','help','runmenu'} do
  local rect=ui.buttons[id]
  assert(Surface.within(rect,1920,1080),'off-viewport '..id)
  assert(Layout.overlap(layout.tray,rect)==0,
   'an action obscures the physical 3D dice plane: '..id)
 end
 assert(ui.buttons.roll.x==layout.single_action.x and
   ui.buttons.roll.y==layout.single_action.y and
   ui.buttons.roll.w==layout.single_action.w and
   ui.buttons.roll.h==layout.single_action.h,'visual/input rectangles drifted')
end
local f=assert(io.open('src/farkle/ui.lua','rb'))
local source=f:read('*a');f:close()
assert(source:find("src.screens.folio_surface",1,true))
assert(source:find("MenuSurface.item(rect",1,true))
assert(source:find("Dialogs.overlay(u,hits)",1,true))
assert(source:find("Indicators.draw(u,hits)",1,true))
assert(not source:find("hud_minimal",1,true))
love=oldLove
print('PASS Merchant HUD ink/parchment, hover mapping, hitboxes and score at three sizes')
