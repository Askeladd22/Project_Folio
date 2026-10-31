-- Visual-only legibility gate. All scoring and hitbox ownership remain
-- in Farkle rules/controller. Runs with Lua 5.4 and LuaJIT without LÖVE.
local Fit=require('src.features.farkle.ui_v2.label_fit')
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local Surface=require('src.features.ui_v2.menu_surface')
local R=require('src.gameplay.farkle.rules')
local P=require('src.features.farkle.presentation')
local Res=require('src.core.resolution_manager')

local function mock_width(str,px)
 return #tostring(str)*px*.57,px*1.16
end
local plain,px,cut=Fit.fit('Incassa 100 pt',mock_width,24,12,610,34)
assert(plain=='Incassa 100 pt' and not cut and px<=24)
local shrunk,small,cut2=Fit.fit('Prossima commissione [N]',
 mock_width,48,12,390,34)
assert(not cut2 and shrunk=='Prossima commissione [N]' and small<48)
local accented,_,shortened=Fit.fit(string.rep('è',40),
 mock_width,20,14,130,24)
assert(shortened and accented:sub(-3)=='...')
-- Truncation must preserve both bytes in each original accented glyph.
local prefix=accented:sub(1,#accented-3)
assert(#prefix%2==0 and not prefix:find('[^\195\168]'),
 'UTF-8 abbreviation split a multi-byte character')
assert(Fit.fit('Oversize',mock_width,30,20,0,0)=='',
 'zero-size cells must never draw outside their bounds')

local layout=Layout.build('single_folio')
assert(Layout.validate(layout))
local readout=layout.header_readout
assert(readout and #readout.metrics==4)
local all={readout.commission_tag,readout.commission_name,
 readout.help,readout.runmenu}
for _,metric in ipairs(readout.metrics) do
 all[#all+1]=metric.caption
 all[#all+1]=metric.value
 assert(Layout.contains(layout.header,metric.caption))
 assert(Layout.contains(layout.header,metric.value))
end
for _,rect in ipairs(all) do
 assert(Surface.within(rect,1920,1080))
 assert(Layout.contains(layout.header,rect),
   'readout moved outside unchanged header')
 assert(Layout.overlap(layout.tray,rect)==0,
   'readout obscures 3D dice')
end
for i,a in ipairs(readout.metrics) do
 if i>1 then
  local previous=readout.metrics[i-1]
  assert(Layout.overlap(previous.caption,a.caption)==0)
  assert(Layout.overlap(previous.value,a.value)==0)
 end
 assert(Layout.overlap(a.value,readout.help)==0)
 assert(Layout.overlap(a.value,readout.runmenu)==0)
end

local oldLove=love
local width,height=1920,1080
local paint={}
local lastColor={}
local currentFont
local pushes,pops=0,0
local function font(size)
 size=type(size)=='number' and size or 18
 return {
  getWidth=function(_,s)return mock_width(s,size)end,
  getHeight=function()return size*1.16 end,
  getWrap=function(_,s)return mock_width(s,size),{tostring(s)} end
 }
end
local graphics=setmetatable({
 getWidth=function()return width end,
 getHeight=function()return height end,
 getDimensions=function()return width,height end,
 newFont=function(a,b)return font(b or a)end,
 getFont=function()return font(18)end,
 setFont=function(face)currentFont=face end,
 setColor=function(...)lastColor={...}end,
 push=function()pushes=pushes+1 end,
 pop=function()pops=pops+1 end,
 rectangle=function(mode,x,y,w,h)
  paint[#paint+1]={kind='rect',mode=mode,x=x,y=y,w=w,h=h}
 end,
 printf=function(label,x,y,w,align)
  paint[#paint+1]={kind='text',label=tostring(label),
   x=x,y=y,w=w,width=currentFont and currentFont:getWidth(label) or 0,
   height=currentFont and currentFont:getHeight() or 0}
 end,
},{__index=function()return function()end end})
love={graphics=graphics}
local Hud=require('src.features.farkle.ui_v2.hud')
local function rect_drawn(rect)
 for _,r in ipairs(paint) do
  if r.kind=='rect' and r.mode=='fill'
   and r.x==rect.x and r.y==rect.y and
   r.w==rect.w and r.h==rect.h then return true end
 end
 return false
end
local function find_line(fragment,rect)
 for _,r in ipairs(paint) do
  if r.kind=='text' and r.label:find(fragment,1,true)
   and r.x>=rect.x and r.x+r.w<=rect.x+rect.w+1
   and r.y>=rect.y and r.y+r.height<=rect.y+rect.h+1 then
   assert(r.width<=r.w+1,'wrapped text escaped '..fragment)
   return true
  end
 end
 return false
end
for _,screen in ipairs{{1280,720},{1920,1080},{2560,1440}} do
 width,height=screen[1],screen[2]
 Res.init(1920,1080);Res.refresh(width,height)
 paint={}
 local game=R.new()
 local u={game=game,presentation=P.new(game)}
 local bank,pot,phase,turn=game.bank,game.pot,game.phase,game.turn
 Hud.draw(u)
 assert(pushes==pops,'graphics stack unbalanced')
 assert(rect_drawn(layout.message),'status text needs a readable surface')
 assert(find_line('COMMISSIONE',readout.commission_tag))
 assert(find_line('OBIETTIVO',readout.metrics[1].caption))
 assert(find_line('ASSICURATI',readout.metrics[2].caption))
 assert(find_line('A RISCHIO',readout.metrics[3].caption))
 assert(find_line('TURNI',readout.metrics[4].caption))
 assert(u.buttons.roll and u.buttons.bank and u.buttons.help)
 assert(u.buttons.roll.x==layout.primary.x and
  u.buttons.roll.y==layout.primary.y and
  u.buttons.roll.w==layout.primary.w and
  u.buttons.roll.h==layout.primary.h)
 assert(game.bank==bank and game.pot==pot and
  game.phase==phase and game.turn==turn,
  'HUD rendering changed the actual game')
end
love=oldLove
print('PASS UI V2 legibility: UTF-8 text fitting, header readouts, status strip and unchanged hitboxes at three viewports')
