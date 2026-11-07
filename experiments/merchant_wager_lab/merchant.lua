-- The Merchant's intentionally elementary, reproducible turn.
-- Scores come from the production Farkle evaluator; no medals, no adaptation.
local Rules=require('src.farkle.rules')
local M={}

-- Highest-scoring valid subset of the thrown dice; ties keep more dice free,
-- then prefer the lowest positions, so the choice is fully deterministic.
function M.best(faces)
 local n=#faces;local best
 for mask=1,2^n-1 do
  local values,positions={},{}
  for i=1,n do
   if math.floor(mask/2^(i-1))%2==1 then values[#values+1]=faces[i];positions[#positions+1]=i end
  end
  local points=Rules.score(values)
  if points and (not best or points>best.points or points==best.points and #positions<#best.positions) then
   best={points=points,positions=positions}
  end
 end
 return best
end

local function text(faces) return table.concat(faces,' ') end

-- random(min,max) must be the match RNG. Returns the full turn trace.
function M.play(random,config)
 local free,provisional,rerolls=config.merchant_dice,0,0
 local steps={}
 while true do
  local faces={}
  for i=1,free do faces[i]=random(1,6) end
  local best=M.best(faces)
  local step={faces=faces,available=free,provisional=provisional,reroll=#steps>0}
  steps[#steps+1]=step
  if not best then
   step.action='farkle';step.detail='provisional '..provisional..' lost'
   return {steps=steps,farkle=true,banked=0,lost=provisional,rerolls=rerolls}
  end
  local kept={};for _,p in ipairs(best.positions) do kept[#kept+1]=faces[p] end
  step.kept=best.positions;step.points=best.points
  provisional=provisional+best.points;free=free-#best.positions
  step.action='set_aside';step.detail='kept '..text(kept)..' = '..best.points
  if free>0 and rerolls<config.merchant_rerolls then
   rerolls=rerolls+1
  else
   return {steps=steps,farkle=false,banked=provisional,rerolls=rerolls}
  end
 end
end
return M
