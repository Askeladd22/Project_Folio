-- EX-003: shared, PUBLIC, deterministic choice rules. Research only.
-- One set of canonical six-D6 Farkle rules drives both experimental arms.
local Rules=require('src.farkle.rules')
local E=require('experiments.encounter_ac_lab.engine')
local P={}
P.profiles={'prudent','balanced','daring','situational'}
P.stops={prudent=30,balanced=60,daring=110}

function P.stream_seed(seed,round,actor)
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and seed<1000000)
 assert(type(round)=='number' and round>=1 and round<=6 and round%1==0)
 assert(actor==1 or actor==2)
 return 1+((seed*1009+round*7919+actor*6151)%2147483646)
end

function P.best_option(turn,profile)
 assert(P.stops[profile] or profile=='situational','unknown EX-003 policy')
 local best,weight
 for _,o in ipairs(Rules.options(turn)) do
  local value=o.points+(profile=='prudent' and 2*#o.ids
    or profile=='daring' and -4*#o.ids or 0)
  if not best or value>weight or value==weight and o.mask<best.mask then
   best=o;weight=value
  end
 end
 return assert(best,'scoring turn without legal Farkle selection')
end

function P.threshold(arm,profile,context)
 assert(arm=='D' or arm=='C')
 assert(type(context)=='table' and context.round>=1 and context.round<=6)
 if profile~='situational' then return assert(P.stops[profile]) end
 if arm=='D' then
  local lead=assert(context.own_score)-assert(context.other_score)
  if lead>=40 then return 30 end
  if lead<=-40 or context.round>=5 and lead<0 then return 110 end
  return 60
 end
 local lanes=assert(context.lanes)
 for _,l in ipairs(lanes) do
  if not l.owner and l.rival>=3 and l.player<=1 then return 90 end
 end
 for _,l in ipairs(lanes) do
  if not l.owner and l.player>=2 then return 40 end
 end
 if context.round>=5 then return 90 end
 return 40
end

-- Never auto-bank less than what the actual current bank rules allow.
function P.wants_bank(arm,profile,context,potential,free_after)
 assert(type(potential)=='number' and potential>=0)
 assert(type(free_after)=='number' and free_after>=0 and free_after<=5)
 return potential>=P.threshold(arm,profile,context) or free_after<=1
end

function P.choose_claim(s,profile)
 assert(s.mode=='C' and s.phase=='claim')
 local first
 for id,l in ipairs(s.lanes) do
  if not l.owner then first=id;break end
 end
 assert(first)
 if profile~='situational' then return first,first,false end
 -- Reuse the frozen EX-002 oracle. Every alternative is applied to a
 -- discarded copy via the original E.claim; no rule is re-implemented.
 local probe=require('experiments.ex002_reactivity_lab.simulate').counterfactuals(s)
 local chosen,utility
 for _,row in ipairs(probe.rows) do
  if chosen==nil or row.utility>utility then
   chosen=row.lane;utility=row.utility
  end
 end
 assert(chosen)
 return chosen,first,chosen~=first
end

return P
