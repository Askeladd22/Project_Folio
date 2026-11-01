-- Headless regression on the actual V2 modal renderer, not the retired
-- legacy fallback. Dialogue artwork is tested using measured font mocks.
local R=require('src.gameplay.farkle.rules')
local P=require('src.features.farkle.presentation')
local H=require('src.features.farkle.hud_model')
local Res=require('src.core.resolution_manager')
local UI=require('src.core.runtime_ui')
local MenuLayout=require('src.features.farkle.ui_v2.modal_layout')
local oldLove=love
local oldScale,oldBig,oldHigh=UI.scale,UI.big_text,UI.high_contrast
local big=false
UI.scale=function() return 1 end
UI.big_text=function() return big end
UI.high_contrast=function()return big end
local width,height=1920,1080
local graphicsCalls={}
local fontCurrent
local pushes,pops=0,0
unpack=unpack or table.unpack
local function font(px)
 px=type(px)=='number' and px or 18
 local current={}
 current.getHeight=function()return px*1.13 end
 current.getLineHeight=function()return 1 end
 current.getWidth=function(_,text)return #tostring(text)*px*.50 end
 current.getWrap=function(_,value,w)
  local text=tostring(value)
  local lines={}
  local widest=0
  for line in (text..'\n'):gmatch('([^\n]*)\n') do
   local lineW=#line*px*.50
   local count=math.max(1,math.ceil(lineW/math.max(1,w)))
   for i=1,count do lines[#lines+1]=line end
   widest=math.max(widest,math.min(lineW,w))
  end
  return widest,lines
 end
 return current
end
local g=setmetatable({
 newFont=function(a,b)return font(b or a) end,
 getFont=function()return font(18)end,
 getWidth=function()return width end,
 getHeight=function()return height end,
 getDimensions=function()return width,height end,
 setFont=function(f)fontCurrent=f end,
 push=function()pushes=pushes+1 end,
 pop=function()pops=pops+1 end,
 printf=function(content,x,y,w)
  local widest,lines=fontCurrent:getWrap(content,w)
  graphicsCalls[#graphicsCalls+1]={
   kind='text',text=tostring(content),x=x,y=y,w=w,
   lines=#lines,h=#lines*fontCurrent:getHeight(),widest=widest}
 end,
 rectangle=function(mode,x,y,w,h)
  graphicsCalls[#graphicsCalls+1]={kind=mode,x=x,y=y,w=w,h=h}
 end,
},{__index=function()return function()end end})
love={graphics=g}
local Dialogs=require('src.features.farkle.ui_v2.dialogs')
local function captured(text,x,y,h)
 for _,draw in ipairs(graphicsCalls) do
  if draw.kind=='text' and draw.text:find(text,1,true)
   and draw.x==x and draw.y==y then
   assert(draw.widest<=draw.w+1,'paragraph exceeds page width: '..text)
   assert(draw.h<=h+1,'paragraph exceeds reserved height: '..text)
   return true
  end
 end
 return false
end
for _,screen in ipairs{{1280,720},{1920,1080},{2560,1440}} do
 width,height=screen[1],screen[2]
 Res.init(1920,1080);Res.refresh(width,height)
 for _,a11y in ipairs{false,true} do
  big=a11y
  for _,mode in ipairs{'help','scores','special','medals','medaluse',
                       'upgrade','medal-reward'} do
   local game=R.new()
   local reward=mode=='upgrade' or mode=='medal-reward'
   if mode=='medaluse' then
    assert(R.start(game) and R.settle(game,{1,5,2,3,4,6}))
    game.medal='reroll_tin'
    require('src.gameplay.farkle.medals').reset(game)
   end
   if reward then game.phase=mode=='upgrade' and 'upgrade' or 'medal' end
   local ui={game=game,presentation=P.new(game),
    modal=reward and nil or (mode=='scores' or mode=='special') and 'help' or mode,
    buttons={},helpTab=mode=='scores' and 2 or mode=='special' and 3 or 1,
    medalPage=1}
   graphicsCalls={}
   local beforeBank,beforePot,beforePhase=game.bank,game.pot,game.phase
   Dialogs.overlay(ui,{})
   assert(pushes==pops,'modal art leaked graphics state')
   assert(game.bank==beforeBank and game.pot==beforePot
    and game.phase==beforePhase,'reading modal changed actual game')
   if reward then
    assert(captured('Your choice carries',440,359,50))
    if mode=='upgrade' then
     assert(captured('Die 1 favours',450,516,126))
     assert(captured('Replace the 2',1010,516,126))
    else
     assert(captured('One second chance',450,516,126))
     assert(captured('Continue with your current dice',1010,516,126))
    end
    local ids=mode=='upgrade' and {'weighted','engraved'} or {'medal','none'}
    for i,id in ipairs(ids) do
     local a,b=ui.buttons[id],MenuLayout.reward_buttons[i]
     assert(a and a.x==b.x and a.y==b.y and
      a.w==b.w and a.h==b.h,'reward click region changed')
    end
   elseif mode=='help' then
    assert(captured('1. Press Space',445,333,66))
    assert(captured('Reach the target',445,333+6*76,66))
   elseif mode=='scores' then
    assert(captured('Singles:',445,329,56))
    assert(captured('Straight 1',445,735,55))
    assert(captured('Three pairs:',445,794,55))
   elseif mode=='special' then
    assert(captured('Farkle:',445,333,66))
    assert(captured('Medal exceptions',445,333+6*76,66))
   elseif mode=='medals' then
    assert(captured('Reference experiment.',440,243,78))
    local d=require('src.gameplay.farkle.medals').list[1]
    assert(captured('Reroll one',1050,402,132))
    assert(captured('Uses:',1050,553,142))
    assert(ui.modalButtons.inspect1 and ui.modalButtons.equip)
   elseif mode=='medaluse' then
    assert(captured('Reroll one',440,258,79))
    assert(captured('Medal targets',440,351,93))
    assert(captured('Uses left:',440,705,74))
    assert(ui.modalButtons.activate and ui.modalButtons.target1)
   end
  end
 end
end
love=oldLove
UI.scale,UI.big_text,UI.high_contrast=oldScale,oldBig,oldHigh
print('PASS V2 dialog text geometry: help, score table, reward, medals, normal/big text, no gameplay mutations at three viewports')
