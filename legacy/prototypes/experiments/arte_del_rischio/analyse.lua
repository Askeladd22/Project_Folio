local R=require('experiments.arte_del_rischio.rules')
local A=require('experiments.arte_del_rischio.agents')
local f=assert(io.open('experiments/arte_del_rischio/exact-analysis.txt','w'))
local function say(s) print(s); f:write(s..'\n') end
local cache={}
local function success(hand,p,remaining)
 if R.score(p,hand)>0 then return 1 end
 if remaining==0 then return 0 end
 local id=table.concat(hand)..':'..p..':'..remaining
 if cache[id] then return cache[id] end
 local best=0; local seen={}
 for mask=1,15 do
  local held={}; for i=1,4 do if not R.has(mask,i) then held[#held+1]=hand[i] end end
  local key=table.concat(held)
  if not seen[key] then
   seen[key]=true; local ev=0
   for _,o in ipairs(A.outcomes[4-#held]) do
    local h={unpack(held)}; for _,v in ipairs(o.h) do h[#h+1]=v end
    table.sort(h); ev=ev+o.p*success(h,p,remaining-1)
   end
   best=math.max(best,ev)
  end
 end
 cache[id]=best; return best
end
for p=1,3 do
 local initial,three,ev=0,0,0
 local stop,roll,tie=0,0,0; local maxgap=-math.huge
 for _,o in ipairs(A.outcomes[4]) do
  local value=R.score(p,o.h)
  if value>0 then initial=initial+o.p end
  ev=ev+o.p*value; three=three+o.p*success(o.h,p,2)
  if value>0 then
   for discount=0,2,2 do
    local s=R.new('A'); s.project=p; s.hand=o.h; s.rerolls=2; s.counts={1,1,1}
    local v=A.evaluate(s,p,'planner',discount,true)
    local gap=v.roll-v.bank; maxgap=math.max(maxgap,gap)
    if gap>1e-9 then roll=roll+1 elseif gap< -1e-9 then stop=stop+1 else tie=tie+1 end
   end
  end
 end
 say(string.format('project=%d initial_success=%.9f success_with_2_optimal_rerolls=%.9f initial_gross_EV=%.9f complete_states_stop=%d risk=%d tie=%d max_risk_minus_stop=%.9f',p,initial,three,ev,stop,roll,tie,maxgap))
end
-- Check the exact enumerator against an independent ordered enumeration.
for p=1,3 do
 local n,total=0,0
 for a=1,6 do for b=1,6 do for c=1,6 do for d=1,6 do
  local v=R.score(p,{a,b,c,d}); if v>0 then n=n+1 end; total=total+v
 end end end end
 assert(n==({171,58,24})[p]); assert(total==({557,368,240})[p])
end
say('PASS ordered 1296-outcome enumeration agrees with recipe counts and reward totals')
-- An incomplete preparation with two reds missing vs one red missing has
-- different useful holds. These are real conditional decisions, not risk of a bank.
local s=R.new('A'); s.project=1; s.hand={1,1,2,3}; s.rerolls=1; s.counts={1,1,1}
local v=A.evaluate(s,1,'opportunist',0,true)
assert(math.abs(v.roll-57/36)<1e-10 and v.kind=='bank')
say('Capolettera base 3: best last reroll EV=57/36=1.583333; bank=3; failure=25/36')
s.hand={1,1,1,2}; v=A.evaluate(s,1,'opportunist',0,true)
assert(math.abs(v.roll-7/6)<1e-10)
say('Capolettera finished 5: best last reroll EV=7/6; bank=5')
s.project=2; s.hand={4,4,3,5}; v=A.evaluate(s,2,'opportunist',0,true)
assert(math.abs(v.roll-8/3)<1e-10)
say('Fregio base 6: best last reroll EV=8/3; bank=6; failure=2/3')
s=R.new('A'); s.turn=8; s.score=21; s.counts={1,1,1}; s.project=1; s.hand={1,1,2,3}; s.rerolls=1
v=A.evaluate(s,1,'threshold_planner',0,true)
assert(v.kind=='roll')
say('Counterexample to global stop dominance: turn8 score21, all categories present, RRBY. Bank3 loses at24; reroll BY wins with11/36. Threshold-aware policy rolls.')
s.score=22; v=A.evaluate(s,1,'threshold_planner',0,true); assert(v.kind=='bank')
say('Same hand at score22: bank3 wins certainly; threshold-aware policy stops.')
f:close()
