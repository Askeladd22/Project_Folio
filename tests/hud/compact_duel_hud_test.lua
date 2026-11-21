-- Compact duel HUD. The screenshot showed paper masking the printshop
-- and a tiny, low-contrast instruction strip. Validate the visual fix
-- against the same production layout and Farkle states.
local UI=require('src.farkle.ui')
local L=UI.layout.build()
local Res=require('src.core.navigation').resolution
local R=require('src.farkle.rules')
local P=require('src.farkle.presentation')
local Layout=UI.layout
assert(Layout.validate(L))
assert(L.score_panel.h==154 and L.opponent_panel.h==164,
 'the two ledgers must remain deliberately compact')
assert((L.score_panel.h+L.opponent_panel.h)<335,
 'paper would again dominate the printshop room')
assert(Layout.overlap(L.score_panel,L.opponent_panel)==0 and
 L.opponent_panel.x>L.score_panel.x+L.score_panel.w and
 L.opponent_panel.y+L.opponent_panel.h<L.tray.y,
 'player and rival rails must flank the character, clear of physical D6')
for _,r in ipairs{
 L.secured_caption,L.secured_value,L.risk_caption,L.risk_value,
 L.objective_caption,L.objective_value,L.turns_caption,L.turns_value,
 L.stakes_caption,L.stakes_track
} do assert(Layout.contains(L.score_panel,r),'player metric escaped the paper') end
assert(L.secured_value.h>=48 and L.risk_value.h>=48)
assert(L.message.h>=24 and Layout.contains(L.footer,L.message))
assert(Layout.overlap(L.message,L.primary)==0 and
 Layout.overlap(L.message,L.secondary)==0,
 'legible instructions must not cover real decisions')
for _,screen in ipairs{{1280,720},{1920,1080},{2560,1440},{3440,1440}} do
 Res.init(1920,1080)
 Res.refresh(screen[1],screen[2])
 local view=Res.get_viewport()
 for _,r in ipairs{L.score_panel,L.opponent_panel,L.message,L.help,L.runmenu} do
  local p=Layout.screen_rect(r,{x=view.x,y=view.y,scale=Res.get_scale()})
  assert(p.x>=0 and p.y>=0 and
   p.x+p.w<=screen[1]+1 and p.y+p.h<=screen[2]+1,
   'compact HUD escaped screen bounds')
 end
end
Res.refresh(1920,1080)
local saved=love
local lines={}
local function font(px)
 return {
  getWidth=function(_,s) return #tostring(s)*px*.52 end,
  getHeight=function() return px*1.12 end,
  getWrap=function(_,s) return #tostring(s)*px*.52,{tostring(s)} end
 }
end
love={filesystem={getInfo=function(path)
 return path=='resources/scenes/printshop-room.png' and {type='file'} or nil
end},mouse={getPosition=function() return 0,0 end},
graphics=setmetatable({
 getDimensions=function() return 1920,1080 end,
 getWidth=function()return 1920 end,getHeight=function()return 1080 end,
 newFont=function(a,b)return font(tonumber(b or a) or 20) end,
 getFont=function()return font(20) end,
 newImage=function() return {
  getWidth=function()return 1920 end,getHeight=function()return 1080 end} end,
 printf=function(value)lines[#lines+1]=tostring(value)end,
}, {__index=function()return function()end end})}
local s=R.new('duel')
local u={game=s,presentation=P.new(s),duel={
 actor='player',target=500,scores={player=45,opponent=125}
}}
local function paints(str)
 return table.concat(lines,' | '):find(str,1,true)~=nil
end
UI.hud.draw(u)
assert(paints('45 pt') and paints('125 pt') and paints('500 pt'),
 'the smaller sheets lost the true duel values')
assert(paints('Rival plays after your turn'),
 'opponent waiting state must be understandable')
assert(paints('Right-click: grab & throw'),
 'physical throw instruction disappeared')
assert(u.buttons.help and u.buttons.runmenu and not u.buttons.roll,
 'HUD changed the game input contract')
lines={}
u.duel.actor='opponent'
u.duel.move='BANK'
u.duel.intent='Secures the points'
u.duel.last_take=25
u.duel.last_count=2
UI.hud.draw(u)
assert(paints('OPPONENT · PLAYING') and paints('BANK') and
 paints('Secures the points') and paints('Set aside: +25 pt'),
 'rival action or rationale disappeared during its own turn')
lines={}
u.duel.move=string.rep('RIVAL_ACTION_',30)
u.duel.intent=string.rep('Explanation ',30)
UI.hud.draw(u)
assert(u.buttons.help and u.buttons.runmenu,
 'extreme opponent data broke controls')
love=saved
print('PASS compact duel HUD: less paper, readable instruction, rival decisions, screen scaling')
