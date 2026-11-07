-- A genuine player HUD smoke test, distinct from the historical Monk beta.
local Layout=require('src.farkle.ui').layout
local R=require('src.farkle.rules')
local P=require('src.farkle.presentation')
local Res=require('src.core.navigation').resolution
local A=require('src.farkle.ui').hud.actions
local Accepted=require('src.farkle.ui').hud.accepted
local layout=Layout.build('table_minimal')
assert(Layout.validate(layout))
assert(layout.tray.w>Layout.build('single_folio').tray.w,
 'normal physical playing field must reclaim old sidebar area')
assert(layout.folio==nil and layout.context==nil and layout.sidebar_frame==nil)
assert(Layout.contains(layout.score_panel,layout.risk_caption))
assert(Layout.contains(layout.score_panel,layout.risk_value))
assert(Layout.contains(layout.score_panel,layout.secured_value))
assert(Layout.contains(layout.score_panel,layout.objective_caption))
assert(Layout.contains(layout.score_panel,layout.objective_value))
assert(Layout.contains(layout.score_panel,layout.turns_caption))
assert(Layout.contains(layout.score_panel,layout.turns_value))
assert(layout.risk_caption.y==layout.secured_caption.y)
assert(layout.risk_value.y==layout.secured_value.y)
assert(layout.footer.y>=layout.tray.y+layout.tray.h
 and layout.footer.h<=110 and layout.footer.w<=1160,
 'the plaque must be compact and must not overlap 3D dice')
local center=layout.tray.x+layout.tray.w/2
for _,r in ipairs{layout.footer,layout.footer_trim,layout.single_action,
                  layout.idle_message,layout.message} do
 assert(math.abs(r.x+r.w/2-center)<=3,
  'merchant table element does not share tray central axis')
end
assert(math.abs((layout.context_actions[1].x+
 layout.secondary.x+layout.secondary.w)/2-center)<=3,
 'the multi-action row must also be balanced around the tray')
assert(Layout.overlap(layout.shelf,layout.footer)==0,
 'accepted-die register must not cross into command plaque')
assert(layout.message.y>=layout.primary.y+layout.primary.h,
 'status must stay below the main actions')
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
local footerNotice
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
  if y>=layout.message.y and y<layout.message.y+layout.message.h then footerNotice=tostring(s) end
 end,
 rectangle=function(mode,x,y,w,h)
  rectangles[#rectangles+1]={mode=mode,x=x,y=y,w=w,h=h}
 end,
},{__index=function()return function()end end}),
 mouse={getPosition=function()return 0,0 end}}
local Hud=require('src.farkle.ui').hud
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
   labels:find('A RISCHIO',1,true) and
   labels:find('OBIETTIVO',1,true) and
   labels:find('100 pt',1,true) and
   labels:find('TURNI RIMASTI',1,true) and
   labels:find('4',1,true))
 local function painted(target)
  for _,r in ipairs(rectangles) do
   if r.mode=='fill' and r.x==target.x and r.y==target.y and
      r.w==target.w and r.h==target.h then return true end
  end
  return false
 end
 assert(painted(layout.score_panel),'shared scorecard not drawn')
 assert(painted(layout.footer),'compact command plaque not drawn')
 assert(painted(layout.footer_trim),'command plaque trim not drawn')
 for _,obsolete in ipairs{'COMMISSIONE','MANOSCRITTO','STRUMENTI','FOLIO 1'} do
  assert(not labels:find(obsolete,1,true),
   'obsolete panel visible on player table: '..obsolete)
 end
 local before=#rectangles
 Accepted.draw(u)
 assert(#rectangles==before,
  'six empty accepted-dice boxes must not be permanently drawn')
end
game.stage=2
game.turn=2
textDrawn={}
Hud.draw(u)
local progress=table.concat(textDrawn,' | ')
assert(progress:find('150 pt',1,true) and progress:find('4',1,true),
 'scorecard must follow the active commission and remaining turns')
game.stage=1
game.turn=1
assert(R.start(game))
-- A rolling turn must NOT retain a blank brown control panel.
textDrawn,rectangles={},{}
Hud.draw(u)
local footerInFlight=false
for _,r in ipairs(rectangles) do
 if r.mode=='fill' and r.x==layout.footer.x and r.y==layout.footer.y
   and r.w==layout.footer.w and r.h==layout.footer.h then
  footerInFlight=true
 end
end
assert(not footerInFlight,'empty command plaque visible while six D6 roll')
assert(table.concat(textDrawn,' '):find('I dadi stanno rotolando',1,true),
 'roll status must remain readable without a panel')
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
local bankEntry
for _,a in ipairs(A.build(u)) do if a.id=='bank' then bankEntry=a end end
assert(bankEntry and bankEntry.enabled and
 not bankEntry.detail:find('minimo 0 pt',1,true),
 'remove meaningless zero minimum while preserving direct banking')
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
assert(u.buttons.take.enabled and u.buttons.take.label=='Accantona · 5 pt')
assert(R.take(game) and game.pot==20)
Hud.draw(u)
assert(u.buttons.roll.enabled and u.buttons.roll.label=='Rilancia 3 dadi')
local hand=R.new()
assert(R.start(hand) and R.settle(hand,{1,1,3,3,3,6}))
u.game=hand
textDrawn={}
Hud.draw(u)
local hints=table.concat(textDrawn,' ')
assert(hints:find('[1] [2] [3] [4] [5]',1,true) and not hints:find('[6]',1,true),
 'keyboard users need the IDs of dice that can contribute, including the triple')
assert(R.toggle(hand,3))
footerNotice=nil
Hud.draw(u)
assert(u.buttons.take and not u.buttons.bank)
assert(u.buttons.take.x+u.buttons.take.w/2==center,'a lone scoring control must be centered')
assert(footerNotice and footerNotice:find('completano',1,true),'partial group needs a next step')
assert(R.toggle(hand,6))
footerNotice=nil
Hud.draw(u)
assert(footerNotice and footerNotice:find('Deseleziona',1,true),'impossible set needs a correction')
assert(R.toggle(hand,6) and R.toggle(hand,3))
for i=1,5 do assert(R.toggle(hand,i)) end
local function check_selection(points)
 textDrawn={};footerNotice=nil
 Hud.draw(u)
 assert(u.buttons.take.label=='Accantona · '..points..' pt',
   'the primary action must quote the exact uncommitted group score')
 assert(hand.pot==0,'preview changed the amount at risk')
 assert(math.abs((u.buttons.take.x+u.buttons.bank.x+u.buttons.bank.w)/2-center)<1,
   'the actual visible action pair must be centered without a medal')
 assert(not footerNotice,'a valid selection already gives its instructions on the two buttons')
end
check_selection(50)
assert(u.buttons.bank and u.buttons.bank.enabled)
assert(R.toggle(hand,1) and R.toggle(hand,2))
check_selection(30)
hand.medal='retry'
Hud.draw(u)
assert(u.buttons.medaluse.x==layout.context_actions[1].x and u.buttons.take.x==layout.primary.x
 and u.buttons.bank.x==layout.secondary.x,'three visible controls must retain the contextual slots')
assert(R.take(hand))
textDrawn={};footerNotice=nil
Hud.draw(u)
assert(u.buttons.roll.enabled and u.buttons.bank.enabled)
assert(not footerNotice or not footerNotice:find('Scegli i dadi',1,true),
 'additional scoring dice are optional once the player may roll or bank')
-- Keep pick headroom above the rear seam for physical dice in flight.
assert(layout.host.y+layout.host.h-layout.tray.y==76)
assert(Layout.overlap(layout.host,layout.shelf)==0)
love=savedLove
print('PASS compact player table: real hitboxes, statuses, contextual actions, accepted dice and three viewport sizes')
