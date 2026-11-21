-- Pure Lua tests: lua5.4 tests/labs/merchant_duel_ai_test.lua
local Duel=require('experiments.merchant_duel.duel')
local AI=require('experiments.merchant_duel.ai')
local Scoring=require('src.farkle.rules').scoring
local function eq(a,b,msg) assert(a==b,(msg or 'mismatch')..' | '..tostring(a)..' ~= '..tostring(b)) end

local s=Duel.new(15)
eq(s.phase,'roll')
assert(not Duel.roll(s,{1,2,3})) -- incomplete roll rejected
eq(s.phase,'roll')
assert(Duel.roll(s,{1,2,3,4,6,6}))
eq(s.phase,'select')
assert(not Duel.select(s,0))
eq(s.pot,0)
assert(Duel.select(s,Duel.mask_from_ids({1})))
eq(s.pot,10)
eq(s.phase,'decision')
assert(not Duel.select(s,Duel.mask_from_ids({1})))
assert(Duel.bank(s))
eq(s.score.player,10)
eq(s.actor,'merchant')
assert(Duel.roll(s,{2,2,3,3,4,6})) -- no 1, no 5, no triple/pairs/straight
eq(s.actor,'player')
eq(s.phase,'roll')
assert(Duel.roll(s,{5,2,2,3,4,6}))
assert(Duel.select(s,Duel.mask_from_ids({1})))
assert(Duel.bank(s))
eq(s.winner,'player')
eq(s.score.player,15)
eq(s.phase,'finished')
assert(not Duel.roll(s,{1,1,1,1,1,1}))

-- One-roll policy has no special win-probability manipulation.
local state={phase='decision',pot=20,actor='merchant',
 score={merchant=0,player=0},target=500,
 used={[1]=true,[2]=true,[3]=true,[4]=true,[5]=true}}
eq(AI.decide(state),'bank')
state.used={} -- six dice remain (hot) => cheap additional-roll risk
eq(AI.decide(state),'roll')
state.score.merchant=490
eq(AI.decide(state),'bank')
local winnerOption=AI.best_option(Scoring.options({1,5,2,3,4,6},{1,2,3,4,5,6}))
assert(winnerOption and winnerOption.points>0 and winnerOption.mask>0)
local hot=Duel.new(1000)
assert(Duel.roll(hot,{1,2,3,4,5,6}))
local option=AI.best_option(hot.options)
eq(option.points,200)
eq(#option.ids,6)
assert(Duel.select(hot,option.mask))
eq(Duel.available(hot),6)
assert(Duel.continue(hot))
eq(Duel.available(hot),6)
assert(Duel.roll(hot,{2,2,3,3,4,6}))
eq(hot.score.player,0) -- losing unbanked hot points
eq(hot.actor,'merchant')

-- Canonical three-die distribution spot-check: 60 busts / 216,
-- sum of best selectable points 1850. No other scoring table is used.
local bust,gain=0,0
for a=1,6 do for b=1,6 do for c=1,6 do
 local options=Scoring.options({a,b,c},{1,2,3})
 local best=AI.best_option(options)
 if not best then bust=bust+1 else gain=gain+best.points end
end end end
eq(bust,AI.distribution[3][2])
eq(gain,AI.distribution[3][3])

local function replay(seed)
 local state=Duel.new(200)
 local n=math.floor(seed)%2147483647
 local function next_die()
  n=(n*48271)%2147483647
  return (n%6)+1
 end
 local steps=0
 while not state.winner and steps<12000 do
  steps=steps+1
  if state.phase=='roll' then
   local faces={}
   for i=1,Duel.available(state) do faces[i]=next_die() end
   assert(Duel.roll(state,faces))
  elseif state.phase=='select' then
   local option=assert(AI.best_option(state.options))
   assert(Duel.select(state,option.mask))
  elseif state.phase=='decision' then
   local action
   if state.actor=='merchant' then action=AI.decide(state)
   else action=(state.pot>=45 or Duel.available(state)<=2) and 'bank' or 'roll' end
   if action=='bank' then assert(Duel.bank(state))
   else assert(Duel.continue(state)) end
  else error('Unexpected phase '..tostring(state.phase)) end
 end
 assert(state.winner and steps<12000,'match must terminate')
 assert(state.score[state.winner]>=state.target)
 return state.winner..':'..state.score.player..':'..state.score.merchant..':'..steps
end
for seed=1,50 do eq(replay(seed),replay(seed),'seeded replay') end
print('merchant_duel_ai_test: PASS')
