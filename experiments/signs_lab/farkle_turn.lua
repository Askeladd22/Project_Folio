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
  for _,index in ipairs(state.active) do faces[index]=random(1,6) end
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
