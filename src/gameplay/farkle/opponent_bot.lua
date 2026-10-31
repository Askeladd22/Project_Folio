-- Experimental adversary for a SAME-RULES Farkle duel.
-- Only the human player's dice are physical; the bot uses its own fair D6 RNG.
-- This module never reads or changes physical bodies, meshes or the player's
-- authoritative game. Exact combinations and limits belong to rules.lua.
local Rules=require('src.gameplay.farkle.rules')
local M={}
local Bot={}
Bot.__index=Bot

function M.new(random)
 assert(type(random)=='function','bot requires independent D6 RNG function')
 return setmetatable({game=Rules.new('control'),random=random,history={}},Bot)
end

local function best_option(state)
 local best
 for _,option in ipairs(Rules.options(state)) do
  -- Avoid converting random dice into privileged results. The bot sees only
  -- the same public scoring options that the player would see.
  if not best or option.points>best.points or
     (option.points==best.points and #option.ids> #best.ids) then
    best=option
  end
 end
 return best
end

function Bot:turn()
 local s=self.game
 if s.phase=='ended' then assert(Rules.next_turn(s)) end
 if s.phase~='fresh' then return nil end
 local before=s.bank
 local report={turn=s.turn,rolls=0,faces={},banked=0,loss=false}
 for attempt=1,64 do
  assert(Rules.start(s),'bot could not start a valid Farkle roll')
  local values={}
  for _,index in ipairs(s.active) do
   local value=self.random(1,6)
   assert(type(value)=='number' and value%1==0 and value>=1 and value<=6,
     'bot D6 generator returned an invalid value')
   values[index]=value
  end
  report.rolls=report.rolls+1
  report.faces[#report.faces+1]=values
  assert(Rules.settle(s,values),'bot failed to settle official Farkle dice')
  if s.phase=='ended' or s.phase=='lost' or s.phase=='rescue' then
   if s.phase=='rescue' then assert(Rules.fail(s)) end
   report.loss=true
   break
  end
  local option=assert(best_option(s),'ready bot must have a scoring option')
  for _,index in ipairs(option.ids) do assert(Rules.toggle(s,index)) end
  assert(Rules.take(s),'bot must use official take scoring')
  local bankable=Rules.bank_status(s)
  -- Readable fixed policy: stop if a healthy gain is safe, the next roll
  -- would be high-risk (two or fewer dice), or this was already a reroll.
  if bankable and
    (s.pot>=65 or Rules.count_free(s)<=2 or report.rolls>=2) then
   assert(Rules.bank_turn(s),'bot must bank via official rule')
   break
  end
 end
 -- The loop bound is defensive, not a free loss or a new Farkle rule.
 -- With a legal hand and a low minimum, bank at the first permitted turn.
 if s.phase=='ready' then
  local ok=Rules.bank_status(s)
  if ok then assert(Rules.bank_turn(s))
  else
   error('bot did not terminate a legal turn after 64 rolls')
  end
 end
 report.banked=s.bank-before
 report.total=s.bank
 report.phase=s.phase
 self.history[#self.history+1]=report
 return report
end

return M
