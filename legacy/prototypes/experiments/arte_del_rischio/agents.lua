local R=require('experiments.arte_del_rischio.rules')
local A={}
-- Enumerate unordered outcomes with their exact multiplicities, not Monte Carlo.
local outcomes={}; local factorial={1,1,2,6,24}
for n=0,4 do
 outcomes[n]={}
 local function gen(a,lo)
  if #a==n then
   local h,c={},{}; for i,v in ipairs(a) do h[i]=v; c[v]=(c[v] or 0)+1 end
   local mult=factorial[n+1]; for _,v in pairs(c) do mult=mult/factorial[v+1] end
   outcomes[n][#outcomes[n]+1]={h=h,p=mult/6^n}; return
  end
  for v=lo,6 do a[#a+1]=v; gen(a,v); a[#a]=nil end
 end
 gen({},1)
end
A.outcomes=outcomes
local hands,trans={},{}
for _,o in ipairs(outcomes[4]) do
 local h=o.h; local key=table.concat(h); hands[key]=h; trans[key]={}
 local seen={}
 for mask=1,15 do
  local kept={}; for i=1,4 do if not R.has(mask,i) then kept[#kept+1]=h[i] end end
  local signature=table.concat(kept)
  if not seen[signature] then
   seen[signature]=true; local entries={}
   for _,nexto in ipairs(outcomes[4-#kept]) do
    local nh={}; for _,v in ipairs(kept) do nh[#nh+1]=v end
    for _,v in ipairs(nexto.h) do nh[#nh+1]=v end
    table.sort(nh); entries[#entries+1]={key=table.concat(nh),prob=nexto.p}
   end
   trans[key][#trans[key]+1]={kept=kept,entries=entries}
  end
 end
end
local scores={}; for p=1,3 do scores[p]={}; for k,h in pairs(hands) do scores[p][k]=R.score(p,h) end end
local memo={}
-- Planner: exact continuation for a committed recipe within this turn.
-- Missing-category bonus is a disclosed heuristic for the remaining game.
-- Future changes of project in C are NOT anticipated in this value function.
local function solve(key,p,r,extra,cost,discount,bonus,depth,goal)
 local id=table.concat({key,p,r,extra and 1 or 0,cost,discount,bonus,depth,goal or -999},':')
 if memo[id] then return memo[id] end
 local score=scores[p][key]
 local bank=score>0 and math.max(0,score-discount)+bonus or 0
 if score>0 and goal and math.max(0,score-discount)>=goal then bank=bank+1000 end
 local best={value=bank,kind=score>0 and 'bank' or 'abandon',bank=bank,roll=-math.huge}
 if depth>0 and (r>0 or extra) then
  local tempting=r==0; local fee=tempting and cost or 0
  for _,move in ipairs(trans[key]) do
   local ev=-fee
   for _,e in ipairs(move.entries) do
    local ns=scores[p][e.key]
    if score==0 or ns>score then
     local nextv
     local nextgoal=goal and goal+fee
     if depth==1 then
      nextv=ns>0 and math.max(0,ns-discount)+bonus or 0
      if ns>0 and nextgoal and math.max(0,ns-discount)>=nextgoal then nextv=nextv+1000 end
     else nextv=solve(e.key,p,math.max(0,r-1),extra and not tempting,cost,discount,bonus,depth-1,nextgoal).value end
     ev=ev+e.prob*nextv
    end
   end
   if ev>best.roll then best.roll=ev end
   if ev>best.value+1e-9 then best.value=ev; best.kind='roll'; best.kept=move.kept; best.tempt=tempting end
  end
 end
 memo[id]=best; return best
end
local function bonus(s,p,policy) return policy~='opportunist' and s.counts[p]==0 and 4 or 0 end
local function goal(s,p,policy)
 if policy~='threshold_planner' or s.turn~=8 then return nil end
 for q=1,3 do if q~=p and s.counts[q]==0 then return nil end end
 return 25-s.score
end
function A.evaluate(s,p,policy,discount,no_tempt)
 local h={unpack(s.hand)}; table.sort(h)
 return solve(table.concat(h),p,s.rerolls,not no_tempt and not s.tempted,
 s.temptations+1,discount or 0,bonus(s,p,policy),policy~='opportunist' and 3 or 1,goal(s,p,policy))
end
function A.initial(s,policy,fixed,no_tempt)
 if fixed then return fixed end
 local bestp,bestv=1,-math.huge
 for p=1,3 do
  local ev=0
  for _,o in ipairs(outcomes[4]) do
   ev=ev+o.p*solve(table.concat(o.h),p,2,not no_tempt,s.temptations+1,0,bonus(s,p,policy),policy~='opportunist' and 3 or 1,goal(s,p,policy)).value
  end
  if ev>bestv then bestv,bestp=ev,p end
 end
 return bestp
end
function A.choose(s,policy,fixed,no_tempt)
 local candidates={s.project}
 if not s.project or (s.variant=='C' and not s.changed) then candidates={1,2,3} end
 local bestp,best= s.project,nil
 for _,p in ipairs(candidates) do
  if not fixed or p==fixed then
   local discount=(s.changed or (s.project and p~=s.project)) and 2 or 0
   local v=A.evaluate(s,p,policy,discount,no_tempt)
   if not best or v.value>best.value+1e-9 or (v.value==best.value and p==s.project) then bestp,best=p,v end
  end
 end
 if not best then bestp=s.project; best=A.evaluate(s,bestp,policy,s.changed and 2 or 0,no_tempt) end
 return bestp,best
end
function A.mask(hand,kept)
 local counts={}; for _,v in ipairs(kept or {}) do counts[v]=(counts[v] or 0)+1 end
 local mask=0
 for i,v in ipairs(hand) do
  if (counts[v] or 0)>0 then counts[v]=counts[v]-1 else mask=mask+2^(i-1) end
 end
 return mask
end
return A
