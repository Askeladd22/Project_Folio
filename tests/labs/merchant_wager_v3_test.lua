-- Regression coverage for the retained V3 offer/counteroffer core.
-- V2 and Correttore UI experiments have been removed from Merchant Wager Lab.
local Rules=require('src.farkle.rules')
local Duel=require('experiments.merchant_wager_lab.duel')
local Box=require('experiments.merchant_wager_lab.box')
local RNG=require('experiments.merchant_wager_lab.rng')
local function count_kind(box)
 local stock=Box.remaining(box)
 local discard=Box.discarded(box)
 for i,n in ipairs({6,5,4,2,3}) do
  assert(stock[i]+discard[i]==n,'20-token box composition drifted')
 end
end
local function card(kind)
 local s=Box.symbols[kind]
 return {kind=kind,id=s.id,points=s.points}
end
local box=Box.new(RNG.new_rng(101))
assert(Box.total(box)==20)
count_kind(box)
for _=1,20 do Box.draw(box);assert(Box.total(box)==20) end
Box.draw(box)
assert(box.reshuffles==1 and Box.total(box)==20)
count_kind(box)
local sample={draw_pile={card(4),card(5)},discard={},
 random=RNG.new_rng(1)}
assert(Box.probability_to_exceed(sample,30,0)==0.5)
assert(Box.probability_to_exceed(sample,30,0)==0.5)
local function fresh()
 for seed=1,150 do
  local duel=Duel.new(seed)
  if duel.phase=='player' then return duel end
 end
 error('No playable seed')
end
local d=fresh()
assert(Duel.total_sheets(d)==8)
assert(d.phase=='player' and Duel.can_roll(d))
-- Canonical Farkle roll: one isolated 1 scores ten points.
local faces={1,2,3,4,6,6}
local index=0
d.player_rng=function()
 index=index+1
 return assert(faces[index])
end
d.hand.offer=10
assert(Duel.roll(d))
assert(Duel.toggle(d,1))
assert(Duel.bank(d))
assert(d.hand.player_result==10 and d.hand.winner=='artist')
assert(d.hand.end_reason=='tie_goes_to_artist')
assert(d.phase=='hand_end')
assert(Duel.next_hand(d))
-- Merchant's special X is not a playable player card.
local initial_x
for seed=1,200 do
 local trial=Duel.new(seed)
 if trial.hand.x_count>0 then initial_x=trial;break end
end
assert(initial_x and initial_x.hand.winner=='artist')
assert(initial_x.hand.end_reason=='initial_x')
local force=fresh()
force.phase='merchant_decision'
force.hand.offer=10
force.hand.player_result=20
force.box.draw_pile={card(5),card(4)}
local p=Duel.preview_decision(force)
assert(p.chance==1 and p.action=='continue')
assert(Duel.advance_merchant(force))
assert(force.hand.winner=='merchant' and force.hand.offer==50)
local decline=fresh()
assert(Duel.fold_artist(decline) and decline.hand.winner=='merchant')
assert(not Duel.fold_artist(decline))
local resignation=fresh()
assert(Duel.fold_merchant(resignation) and resignation.hand.winner=='artist')
local a,b=RNG.new_rng(1234),RNG.new_rng(1234)
for _=1,30 do assert(a(1,6)==b(1,6)) end
print('PASS Merchant V3 retained core: canonical Farkle, box conservation, X, exact odds, counteroffer, folds and seeded RNG')
