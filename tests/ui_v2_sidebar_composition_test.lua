-- The sidebar is presentation-only. No new controller click regions,
-- gameplay mutations, dice renderer changes or fallback HUDs.
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local Shelf=require('src.features.farkle.ui_v2.accepted_dice')
local R=require('src.gameplay.farkle.rules')
local Presentation=require('src.features.farkle.presentation')
local Res=require('src.core.resolution_manager')

local layout=Layout.build('single_folio')
assert(Layout.validate(layout))
assert(layout.tray.x==68 and layout.tray.y==216
 and layout.tray.w==1402 and layout.tray.h==666,
 'do not move the 3D surface to achieve visual polish')
assert(layout.folio.x==1512 and layout.folio.y==128
 and layout.folio.w==352 and layout.folio.h==562,
 'folio location doubles as an authoritative hitbox')
assert(layout.context.x==1512 and layout.context.y==724
 and layout.context.w==352 and layout.context.h==152)
assert(Layout.contains(layout.sidebar_frame,layout.folio))
assert(Layout.contains(layout.sidebar_frame,layout.context))
assert(Layout.overlap(layout.sidebar_frame,layout.tray)==0)
assert(Layout.overlap(layout.sidebar_divider,layout.folio)==0)
assert(Layout.overlap(layout.sidebar_divider,layout.context)==0)
assert(Layout.overlap(layout.shelf_caption,layout.shelf)==0)
assert(Layout.overlap(layout.shelf_caption,layout.tray)==0)
assert(Layout.overlap(layout.shelf_divider,layout.tray)==0)
local slots=Shelf.slots(layout)
assert(#slots==6)
for _,slot in ipairs(slots) do
 assert(Layout.contains(layout.shelf,slot))
 assert(Layout.overlap(slot,layout.shelf_caption)==0)
 assert(Layout.overlap(slot,layout.shelf_divider)==0)
 assert(Layout.overlap(slot,layout.tray)==0)
end
for i,rect in ipairs(layout.context_actions) do
 assert(rect.x==layout.context.x+12)
 assert(rect.y==layout.context.y+31+(i-1)*59)
 assert(rect.w==layout.context.w-24 and rect.h==52)
 assert(Layout.contains(layout.context,rect))
end
assert(#layout.context_actions==2)
assert(Layout.validate(Layout.build('open_codex')),
 'the experimental alternative layout must remain valid')

local originalLove=love
local realW,realH=1920,1080
local stack,unstack=0,0
local paint={}
local fontCurrent=nil
local function fake_font(px)
 px=type(px)=='number' and px or 18
 return {
  getWidth=function(_,txt)return #tostring(txt)*px*.49 end,
  getHeight=function()return px*1.16 end,
  getWrap=function(_,txt)return #tostring(txt)*px*.49,{tostring(txt)}end,
 }
end
love={graphics=setmetatable({
 getDimensions=function()return realW,realH end,
 getWidth=function()return realW end,
 getHeight=function()return realH end,
 getFont=function()return fake_font(18)end,
 newFont=function(a,b)return fake_font(b or a)end,
 setFont=function(f)fontCurrent=f end,
 push=function()stack=stack+1 end,
 pop=function()unstack=unstack+1 end,
 rectangle=function(mode,x,y,w,h)
  paint[#paint+1]={mode=mode,x=x,y=y,w=w,h=h}
 end,
 printf=function(txt,x,y,w)
  paint[#paint+1]={mode='text',text=tostring(txt),x=x,y=y,w=w,
   h=fontCurrent and fontCurrent:getHeight() or 20}
 end,
},{__index=function()return function()end end})}
local Hud=require('src.features.farkle.ui_v2.hud')
local function rect_drawn(r)
 for _,v in ipairs(paint) do
  if v.mode=='fill' and v.x==r.x and v.y==r.y
    and v.w==r.w and v.h==r.h then return true end
 end
 return false
end
local function caption_visible(label,rect)
 for _,v in ipairs(paint) do
  if v.mode=='text' and v.text==label and
    v.x>=rect.x and v.x+v.w<=rect.x+rect.w+1
    and v.y>=rect.y and v.y+v.h<=rect.y+rect.h+1 then
   return true
  end
 end
 return false
end
for _,size in ipairs{{1280,720},{1920,1080},{2560,1440}} do
 realW,realH=size[1],size[2]
 Res.init(1920,1080)
 Res.refresh(realW,realH)
 for _,duel in ipairs{false,true} do
  paint={}
  local s=R.new()
  s.medal='retry'
  assert(R.start(s))
  assert(R.settle(s,{1,5,2,3,4,6}))
  local bank,pot,phase,turn=s.bank,s.pot,s.phase,s.turn
  local u={game=s,presentation=Presentation.new(s),botDuel=duel}
  Hud.draw(u)
  assert(stack==unstack,'sidebar painting left a graphics transform open')
  assert(rect_drawn(layout.sidebar_frame),'folio needs a unified outer binding')
  assert(rect_drawn(layout.context),'tools card must remain inside the sidebar')
  assert(rect_drawn(layout.shelf_caption),'rubric must sit on an illuminated ribbon')
  assert(caption_visible('REGISTRO DEI DADI ACCANTONATI',layout.shelf_caption),
   'accepted-dice title is obscured by slot drawings')
  assert(not duel or not caption_visible('MANOSCRITTO',layout.sidebar_caption),
   'monk status takes precedence over normal sidebar heading')
  assert(duel or caption_visible('MANOSCRITTO',layout.sidebar_caption))
  assert(u.buttons.choices and u.buttons.medaluse,
   'all contextual actions must survive visual composition')
  for i,id in ipairs{'choices','medaluse'} do
   local a,b=u.buttons[id],layout.context_actions[i]
   assert(a.x==b.x and a.y==b.y and a.w==b.w and a.h==b.h,
    'redrawn side button has drifted away from controller hitbox')
  end
  local expectedFolio=duel and {x=1512,y=320,w=352,h=370} or layout.folio
  local actual=u.buttons.folio
  assert(actual.x==expectedFolio.x and actual.y==expectedFolio.y
   and actual.w==expectedFolio.w and actual.h==expectedFolio.h,
   'folio input rectangle changed during decorative work')
  assert(s.bank==bank and s.pot==pot and s.phase==phase and s.turn==turn)
 end
end
love=originalLove
print('PASS sidebar and six-slot composition, monk exception, unchanged 3D tray and real hitboxes at 720p/1080p/1440p')
