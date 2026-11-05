-- A genuine player HUD smoke test, distinct from the historical Monk beta.
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local R=require('src.gameplay.farkle.rules')
local P=require('src.features.farkle.presentation')
local Res=require('src.core.resolution_manager')
local A=require('src.features.farkle.ui_v2.actions')
local Accepted=require('src.features.farkle.ui_v2.accepted_dice')
local layout=Layout.build('table_minimal')
assert(Layout.validate(layout))
assert(layout.tray.w>Layout.build('single_folio').tray.w,
 'normal physical playing field must reclaim old sidebar area')
assert(layout.folio==nil and layout.context==nil and layout.sidebar_frame==nil)
local buttons={}
local game=R.new()
local u={game=game,presentation=P.new(game),minimalHud=true}
local actions=A.build(u)
for _,a in ipairs(actions) do buttons[a.id]=a end
assert(buttons.roll and buttons.bank and buttons.help and buttons.runmenu)
assert(not buttons.folio,'no always-visible folio panel in player mode')

local savedLove=love
local width,height=1920,1080
local textDrawn,rectangles={},{}
local push,pop=0,0
local currentFont=nil
local function mock_font(pt)
 pt=type(pt)=='number' and pt or 18
 return {
  getWidth=function(_,s)return #tostring(s)*pt*.48 end,
  getHeight=function()return pt*1.15 end,
  getWrap=function(_,s)return #tostring(s)*pt*.48,{tostring(s)}end,
 }
end
love={graphics=setmetatable({
 getDimensions=function()return width,height end,
 getWidth=function()return width end,
 getHeight=function()return height end,
 newImage=function()return {getWidth=function()return 944 end,getHeight=function()return 229 end}end,
 newFont=function(a,b)return mock_font(b or a) end,
 getFont=function()return mock_font(18)end,
 setFont=function(f)currentFont=f end,
 push=function()push=push+1 end,pop=function()pop=pop+1 end,
 printf=function(s,x,y,w)
  textDrawn[#textDrawn+1]=tostring(s)
 end,
 rectangle=function(mode,x,y,w,h)
  rectangles[#rectangles+1]={mode=mode,x=x,y=y,w=w,h=h}
 end,
},{__index=function()return function()end end}),
 mouse={getPosition=function()return 0,0 end}}
local Hud=require('src.features.farkle.ui_v2.hud')
for _,size in ipairs{{1920,1080},{1280,720},{2560,1440}} do
 width,height=size[1],size[2]
 Res.init(1920,1080);Res.refresh(width,height)
 textDrawn,rectangles={},{}
 Hud.draw(u)
 assert(push==pop,'compact table leaks graphics state')
 assert(u.buttons.roll and not u.buttons.bank and u.buttons.help
  and u.buttons.runmenu and not u.buttons.folio)
 assert(u.buttons.roll.x==layout.single_action.x and
        u.buttons.roll.y==layout.single_action.y)
 local launchCount=0
 for _,label in ipairs(textDrawn) do if label=='Lancia i sei dadi' then launchCount=launchCount+1 end end
 assert(launchCount==1,'opening instruction should appear once')
 for _,a in pairs(u.buttons) do
  assert(Layout.overlap(a,layout.tray)==0,
   'active minimal button obstructs real 3D dice: '..a.label)
 end
 local labels=table.concat(textDrawn,' | ')
 assert(labels:find('ASSICURATI',1,true) and
   labels:find('A RISCHIO',1,true))
 for _,obsolete in ipairs{'COMMISSIONE','OBIETTIVO','TURNI',
                           'MANOSCRITTO','STRUMENTI','FOLIO 1'} do
  assert(not labels:find(obsolete,1,true),
   'obsolete panel visible on player table: '..obsolete)
 end
 local before=#rectangles
 Accepted.draw(u)
 assert(#rectangles==before,
  'six empty accepted-dice boxes must not be permanently drawn')
end
assert(R.start(game))
assert(R.settle(game,{1,5,2,3,4,6}))
game.medal='retry'
u.buttons={}
textDrawn,rectangles={},{}
Hud.draw(u)
assert(not u.buttons.choices and u.buttons.medaluse and not u.buttons.roll)
assert(not u.buttons.folio)
for _,id in ipairs{'medaluse'} do
 local b=u.buttons[id]
 assert(Layout.overlap(b,layout.tray)==0)
end
assert(R.toggle(game,1))
assert(R.take(game))
textDrawn,rectangles={},{}
Accepted.draw(u)
assert(#rectangles>0,'accepted die needs a visible register token')
assert(game.pot==10 and game.used[1],
 'minimal presentation must preserve authoritative Farkle decisions')
-- Two dice set aside for 15, then a single five among four physical dice.
assert(R.toggle(game,2) and R.take(game) and game.pot==15)
assert(R.start(game) and R.settle(game,{[3]=5,[4]=2,[5]=3,[6]=4}))
Hud.draw(u)
assert(not u.buttons.roll and not u.buttons.take and not u.buttons.choices)
assert(R.toggle(game,3))
Hud.draw(u)
assert(u.buttons.take.enabled and u.buttons.take.label:find('+5 pt',1,true))
assert(R.take(game) and game.pot==20)
Hud.draw(u)
assert(u.buttons.roll.enabled and u.buttons.roll.label=='Rilancia 3 dadi')
local hand=R.new()
assert(R.start(hand) and R.settle(hand,{1,1,3,3,3,6}))
u.game=hand
for i=1,5 do assert(R.toggle(hand,i)) end
local function check_selection(points)
 textDrawn={}
 Hud.draw(u)
 assert(table.concat(textDrawn,' '):find('Selezione: '..points..' pt',1,true))
end
check_selection(50)
assert(u.buttons.bank and u.buttons.bank.enabled)
assert(R.toggle(hand,1) and R.toggle(hand,2))
check_selection(30)
assert(Layout.overlap(layout.host,layout.tray)==0)
assert(Layout.overlap(layout.host,layout.shelf)==0)
love=savedLove
print('PASS compact player table: real hitboxes, statuses, contextual actions, accepted dice and three viewport sizes')
