-- Active V2 Farkle modal visual regression; headless LÖVE graphics.
-- Tests presentation for all canonical dialog types without invoking
-- scoring, selection or reward callbacks.
local R=require('src.gameplay.farkle.rules')
local P=require('src.features.farkle.presentation')
local Res=require('src.core.resolution_manager')
local Layout=require('src.features.farkle.ui_v2.modal_layout')
local RuntimeUI=require('src.core.runtime_ui')
local valid,reason=Layout.validate()
assert(valid,reason)
unpack=unpack or table.unpack

local originalLove=love
local oldScale,oldBig,oldContrast=RuntimeUI.scale,
 RuntimeUI.big_text,RuntimeUI.high_contrast
local big,high=false,false
RuntimeUI.scale=function()return 1 end
RuntimeUI.big_text=function()return big end
RuntimeUI.high_contrast=function()return high end
local sw,sh=1920,1080
local mouseX,mouseY=nil,nil
local push,pop=0,0
local paint={}
local color={1,1,1,1}
local currentFont=nil
local function fakeFont(n)
 n=type(n)=='number' and n or 18
 return {
  getWidth=function(_,text)return #tostring(text)*n*.50 end,
  getHeight=function()return n*1.1 end,
  getWrap=function(_,text)return #tostring(text)*n*.50,{tostring(text)}end,
 }
end
local gfx=setmetatable({
 getWidth=function()return sw end,
 getHeight=function()return sh end,
 getDimensions=function()return sw,sh end,
 getFont=function()return fakeFont(20)end,
 newFont=function(a,b)return fakeFont(b or a)end,
 setFont=function(f)currentFont=f end,
 setColor=function(...)color={...}end,
 push=function()push=push+1 end,
 pop=function()pop=pop+1 end,
 rectangle=function(mode,x,y,w,h)
  paint[#paint+1]={mode=mode,x=x,y=y,w=w,h=h,color=color}
 end,
 printf=function(text,x,y,w)
  paint[#paint+1]={mode='text',text=tostring(text),x=x,y=y,
   w=w,tw=currentFont and currentFont:getWidth(text) or 0,
   h=currentFont and currentFont:getHeight() or 0}
 end,
 print=function(text,x,y)
  paint[#paint+1]={mode='text',text=tostring(text),x=x,y=y,
   tw=currentFont and currentFont:getWidth(text) or 0}
 end,
},{__index=function()return function()end end})
love={graphics=gfx,mouse={getPosition=function()return mouseX,mouseY end}}
local Dialogs=require('src.features.farkle.ui_v2.dialogs')

local function hasFill(r)
 for _,call in ipairs(paint) do
  if call.mode=='fill' and call.x==r.x and call.y==r.y and
   call.w==r.w and call.h==r.h then return true end
 end
 return false
end
local function hoverFill(r)
 for _,call in ipairs(paint) do
  if call.mode=='fill' and call.x==r.x and call.y==r.y and
   call.w==r.w and call.h==r.h then
   local c=call.color
   if math.abs((c[1] or 0)-.97)<.001 and
    math.abs((c[2] or 0)-.88)<.001 and
    math.abs((c[3] or 0)-.65)<.001 then return true end
  end
 end
 return false
end
local function readableButton(r)
 for _,call in ipairs(paint) do
  local exact=call.text==r.label
  local short=call.text and call.text:sub(-3)=='...' and
   r.label:sub(1,#call.text-3)==call.text:sub(1,-4)
  if call.mode=='text' and (exact or short) and
   math.abs(call.x-(r.x+14))<.01 and
   call.y>=r.y+6 and call.y+call.h<=r.y+r.h-5 and
   call.tw<=call.w+.5 then return true end
 end
 return false
end
local function state(mode)
 local s=R.new()
 if mode=='choices' or mode=='medaluse' then
  assert(R.start(s) and R.settle(s,{1,5,2,3,4,6}))
 end
 if mode=='medaluse' then s.medal='retry' end
 if mode=='upgrade' or mode=='reward-medal' then
  s.phase=mode=='upgrade' and 'upgrade' or 'medal'
 end
 return s
end
for _,screen in ipairs{{1280,720},{1920,1080},{2560,1440}} do
 sw,sh=screen[1],screen[2]
 Res.init(1920,1080);Res.refresh(sw,sh)
 for _,access in ipairs{{false,false},{true,true}} do
  big,high=access[1],access[2]
  for _,mode in ipairs{'help','choices','folio','run','medals',
                      'medaluse','upgrade','reward-medal'} do
   local s=state(mode)
   local reward=mode=='upgrade' or mode=='reward-medal'
   local modal=reward and nil or mode
   local buttons={saved={x=16,y=16,w=22,h=22,enabled=true}}
   local u={game=s,modal=modal,buttons=buttons,
    presentation=P.new(s),choicePage=1,helpTab=1,
    medalPage=1}
   local bank,pot,phase,turn=s.bank,s.pot,s.phase,s.turn
   paint={}
   mouseX,mouseY=Res.to_screen(1380,202)
   Dialogs.overlay(u,{})
   assert(push==pop,'dialog leaked graphics stack')
   if reward then
    assert(hasFill(Layout.reward_frame))
    assert(hasFill(Layout.reward_cards[1]))
    assert(hasFill(Layout.reward_cards[2]))
    local ids=mode=='upgrade' and {'weighted','engraved'}
     or {'medal','none'}
    for i,id in ipairs(ids) do
     local a,b=u.buttons[id],Layout.reward_buttons[i]
     assert(a and a.enabled and a.x==b.x and a.y==b.y and
      a.w==b.w and a.h==b.h,'reward input shifted: '..id)
     assert(readableButton(a),'reward label clipped: '..id)
    end
    assert(u.buttons.saved==nil,'reward must mask normal-game buttons')
   else
    assert(hasFill(Layout.frame),'missing parchment modal frame')
    assert(u.buttons==buttons,'modals must restore controller buttons')
    assert(u.modalButtons.close and u.modalButtons.close.enabled)
    local close=u.modalButtons.close
    assert(close.x==Layout.close.x and close.y==Layout.close.y and
     close.w==Layout.close.w and close.h==Layout.close.h)
    assert(hoverFill(Layout.close),'close hover must use scaled pointer')
    for id,a in pairs(u.modalButtons) do
     assert(readableButton(a),'button label escapes modal: '..id)
     assert(a.x>=Layout.frame.x and a.y>=Layout.frame.y and
      a.x+a.w<=Layout.frame.x+Layout.frame.w and
      a.y+a.h<=Layout.frame.y+Layout.frame.h,
      'modal button outside manuscript page: '..id)
    end
    if mode=='choices' then
     assert(u.modalButtons.option1 and u.modalButtons.prev)
     assert(not u.modalButtons.prev.enabled)
     assert(not hoverFill(u.modalButtons.prev),
      'disabled page action cannot show active hover')
    elseif mode=='help' then
     assert(u.modalButtons.helpTab1 and u.modalButtons.helpTab2
      and u.modalButtons.helpTab3)
    elseif mode=='run' then
     assert(u.modalButtons.restart and u.modalButtons.control)
    elseif mode=='medals' then
     assert(u.modalButtons.equip and u.modalButtons.inspect1)
    elseif mode=='medaluse' then
     assert(u.modalButtons.activate)
    end
   end
   assert(s.bank==bank and s.pot==pot and s.phase==phase and s.turn==turn,
    'modal painting changed Farkle state')
  end
 end
end
RuntimeUI.scale=oldScale
RuntimeUI.big_text=oldBig
RuntimeUI.high_contrast=oldContrast
love=originalLove
print('PASS UI V2 modal polish: frame/reward, actions, measured labels, hover, disabled paging and Farkle state at 720p/1080p/1440p')
