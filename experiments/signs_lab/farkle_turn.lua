-- Virtual-only experimental Farkle turn. All selections, scoring, roll
-- settlement, banking, Farkle and hot dice use the actual production Rules.
-- This cannot affect g3d/physics or become a game mode by importing a view.
local Rules=require('src.gameplay.farkle.rules')
local M={}
local function best(state)
 local winner
 for _,option in ipairs(Rules.options(state)) do
  if not winner or option.points>winner.points or
    (option.points==winner.points and #option.ids<#winner.ids) then
   winner=option
  end
 end
 return winner
end
function M.new_rng(seed)
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and
   seed<2147483647,'seed must be integer 1..2147483646')
 local value=seed
 return function(min,max)
  assert(type(min)=='number' and type(max)=='number' and min<=max
   and min%1==0 and max%1==0,'RNG expects integer range')
  value=(value*16807)%2147483647
  local answer=min+math.floor((value/2147483647)*(max-min+1))
  return math.min(answer,max)
 end
end

-- Stateless per-roll/per-physical-ID stream used by the paired benchmark.
-- Same (seed, hand, roll index, D6 ID) => same die face even if other
-- policies previously consumed a different number of virtual dice.
-- Not a cryptographic RNG and not suitable as a production physics source.
-- Lua 5.1/5.4 portable 31-bit XOR: index mixing needs an avalanche,
-- not just a linear congruential offset (which gives highly correlated dice).
local function xor31(a,b)
 local out,place=0,1
 for _=1,31 do
  if a%2~=b%2 then out=out+place end
  a=math.floor(a/2)
  b=math.floor(b/2)
  place=place*2
 end
 return out
end

function M.matched_rolls(seed,hand)
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and
  seed<2147483647,'seed must be integer 1..2147483646')
 assert(type(hand)=='number' and hand%1==0 and hand>=1 and hand<=100,
  'benchmark hand must be 1..100')
 return function(min,max,roll,id)
  assert(min==1 and max==6,'matched rolls represent fair virtual D6')
  assert(type(roll)=='number' and roll%1==0 and roll>=1 and roll<=64,
   'valid roll index required')
  assert(type(id)=='number' and id%1==0 and id>=1 and id<=6,
   'physical die ID required')
  local value=(seed+hand*104729+roll*13007+id*8191)%2147483646+1
  value=xor31(value,math.floor(value/32768))
  value=(value*48271)%2147483647
  value=xor31(value,math.floor(value/4096))
  value=(value*16807)%2147483647
  value=xor31(value,math.floor(value/256))
  return 1+math.floor((value/2147483647)*6)
 end
end

function M.decision(strategy,state)
 assert(strategy=='prudent' or strategy=='audace' or
  strategy=='reattiva','unknown benchmark policy')
 -- C sees only a Sign CATEGORY, not the unrevealed strength.
 -- These thresholds are exploratory, not approved enemy balance.
 local stop=strategy=='prudent' and 25 or
  strategy=='audace' and 85 or
  ({assalto=35,guardia=55,occasione=65})[state.category] or 40
 local free=state.free_after>0 and state.free_after or 6 -- hot dice
 return state.can_bank and
  (state.points>=stop or (free<=1 and state.points>=10) or
   (state.rolls>=3 and state.points>=10)) and 'bank' or 'roll'
end

function M.play(random,strategy,category,observer)
 assert(type(random)=='function','independent D6 random needed')
 local state=Rules.new('control') -- First-commission entry_min=0.
 local rolls,decisions=0,0
 for _=1,64 do
  assert(Rules.start(state),'official Farkle roll was not permitted')
  local faces={}
  for _,index in ipairs(state.active) do faces[index]=random(1,6,rolls+1,index) end
  rolls=rolls+1
  assert(Rules.settle(state,faces),'official Farkle settle failed')
  if state.phase=='ended' or state.phase=='lost' then
   return {banked=0,farkle=true,rolls=rolls,decisions=decisions}
  end
  assert(state.phase=='ready','unexpected Farkle phase in experiment')
  local option=assert(best(state),'valid scoring roll has no option')
  for _,id in ipairs(option.ids) do assert(Rules.toggle(state,id)) end
  local can,points=Rules.bank_status(state)
  local remaining=Rules.count_free(state)-#option.ids
  local public={points=points,free_after=remaining,rolls=rolls,
   can_bank=can,category=category}
  local choice=M.decision(strategy,public)
  decisions=decisions+1
  if observer then observer(public,choice) end
  if choice=='bank' then
   assert(Rules.bank_turn(state),'banking must use production Rules')
   return {banked=state.bank,farkle=false,
    rolls=rolls,decisions=decisions}
  end
  assert(Rules.take(state),'reroll must first set aside official scoring dice')
 end
 error('Farkle turn exceeded 64 rolls; fixture invalid, never treat as loss')
end
return M
