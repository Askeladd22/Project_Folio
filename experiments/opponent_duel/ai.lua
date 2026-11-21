-- Experimental Farkle opponent, not wired into the 3D production scene.
-- The exact one-roll distribution is for SIX ORDINARY D6 under Folio scoring.
-- A reroll decision compares an immediate bank with rolling once and banking
-- the best scoring subset. It is an interpretable heuristic, not optimal play.
local AI = {}

-- Enumerated over all 6^n uniformly distributed outcomes using the
-- canonical scoring combinations; gain_sum includes zero-point busts.
-- Fields: outcomes, bust outcomes, sum of the best selectable scores.
AI.distribution = {
 [1]={6,4,15}, [2]={36,16,180}, [3]={216,60,1850},
 [4]={1296,204,18310}, [5]={7776,600,197195},
 [6]={46656,1080,2399175},
}

-- Known baseline: choose the maximum currently legal scoring subset.
-- In ties keep more dice available; remaining ties use stable physical IDs.
function AI.best_option(options)
 local best
 for _,o in ipairs(options or {}) do
  if not best or o.points>best.points
   or (o.points==best.points and o.remaining>best.remaining)
   or (o.points==best.points and o.remaining==best.remaining and o.mask<best.mask) then
   best=o
  end
 end
 return best
end

function AI.decide(state)
 assert(state.phase=='decision', 'AI needs a committed scoring selection')
 local pot=assert(state.pot)
 local score=assert(state.score[state.actor])
 local target=assert(state.target)
 if score+pot>=target then
  return 'bank','Incassando raggiungo l\'obiettivo.'
 end
 local available=0
 for i=1,6 do if not state.used[i] then available=available+1 end end
 if available==0 then available=6 end -- hot dice
 local d=assert(AI.distribution[available])
 -- E[bank after one additional throw] - bank now =
 -- (sum_of_best_scores - bust_count * pot) / total_outcomes.
 -- A positive value justifies one more throw under this one-step model.
 if d[3] <= d[2]*pot then
  return 'bank',string.format('Rischio Farkle: %d/%d; con %d pt conviene incassare.',
   d[2],d[1],pot)
 end
 return 'roll',string.format('Rischio Farkle: %d/%d; il rilancio vale il rischio.',
  d[2],d[1])
end

return AI
