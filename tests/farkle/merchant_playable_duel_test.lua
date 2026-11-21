-- Symmetric duel must reuse the production Farkle scorer and D6 state.
local R=require('src.farkle.rules')
local UI=require('src.farkle.ui')
local AI=require('experiments.merchant_duel.ai')
local Controller=require('src.farkle.controller')
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local solo=R.new('build')
eq(solo.mode,'build')
eq(solo.stage,1)
local s=R.new('duel')
eq(s.mode,'duel')
s.duel_target=500
eq(s.bank,0)
local user={game=s,duel={actor='player',scores={player=0,merchant=0},target=500}}
local actions=UI.hud.actions.build(user)
local map={}
for _,a in ipairs(actions) do map[a.id]=a end
assert(map.roll and map.help and map.runmenu,'player can throw physical dice')
assert(R.start(s))
local faces={1,2,3,4,5,6}
assert(R.settle(s,faces))
local straight
for _,o in ipairs(R.options(s)) do if o.points==200 and #o.ids==6 then straight=o end end
assert(straight)
for _,id in ipairs(straight.ids) do assert(R.toggle(s,id)) end
local ok,total,minimum=R.bank_status(s)
assert(ok and total==200 and minimum==0)
assert(Controller.duel_bank(user))
eq(s.bank,200)
eq(s.phase,'ended')
user.duel.actor='merchant'
actions=UI.hud.actions.build(user)
for _,a in ipairs(actions) do assert(a.slot=='header','merchant must not get player buttons') end
assert(R.next_turn(s))
s.bank=0
assert(R.start(s))
assert(R.settle(s,{1,1,1,1,3,3}))
assert(R.has_points({1,1,1,1,3,3}),'full house with singles scores in production')
local pair
for _,o in ipairs(R.options(s)) do if o.points==200 and #o.ids==6 then pair=o end end
assert(pair,'full house must use canonical 200 point scoring')
for _,id in ipairs(pair.ids) do assert(R.toggle(s,id)) end
assert(Controller.duel_bank(user))
eq(s.bank,200)
eq(s.phase,'ended')
assert(R.next_turn(s))
s.bank=450
assert(R.start(s))
assert(R.settle(s,{1,5,2,3,4,6}))
assert(R.toggle(s,1) and R.toggle(s,2))
assert(Controller.duel_bank(user))
eq(s.bank,465)
eq(s.phase,'ended')
assert(R.next_turn(s))
s.bank=495
assert(R.start(s))
assert(R.settle(s,{1,2,3,4,5,6}))
assert(R.toggle(s,5))
assert(Controller.duel_bank(user))
eq(s.bank,500)
eq(s.phase,'won')
assert(not R.next_turn(s),'winner cannot keep playing')
user.duel.winner='merchant'
for _,a in ipairs(UI.hud.actions.build(user)) do
 assert(a.slot=='header','finished duel accepts only non-gameplay controls')
end

local loser=R.new('duel')
assert(R.start(loser))
assert(R.settle(loser,{2,2,3,3,4,6}) and loser.phase=='ended')
assert(loser.phase~='lost','duel has no solo commission turn limit')
eq(loser.bank,0)
local stakes=R.new('duel')
assert(R.start(stakes) and R.settle(stakes,{1,2,3,4,5,6}))
for i=1,6 do assert(R.toggle(stakes,i)) end
assert(R.take(stakes))
eq(stakes.pot,200)
assert(stakes.hot)
assert(R.start(stakes),'hot dice must allow physical reroll of all six')
assert(R.settle(stakes,{2,2,3,3,4,6}))
eq(stakes.pot,0)
eq(stakes.phase,'ended')

local ai_state={phase='decision',actor='merchant',pot=30,score={merchant=490},target=500,used={[1]=true}}
eq(AI.decide(ai_state),'bank')
ai_state.score.merchant=0
assert(AI.decide(ai_state)=='bank' or AI.decide(ai_state)=='roll')
local layout=UI.layout.build()
assert(UI.layout.validate(layout))
assert(layout.tray.x<20 and layout.tray.w>1900 and layout.tray.y+layout.tray.h>1000,
 'camera needs full-width immersive physical playfield')
assert(layout.merchant_panel and layout.duel_turn)
print('PASS symmetric Farkle duel: scoring, hot dice, winner, input guards and immersive HUD contract')
