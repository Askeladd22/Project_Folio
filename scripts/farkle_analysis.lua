local R=require('src.gameplay.farkle.rules')
local D=require('src.features.farkle.dice')
local expected={4,16,60,204,600,1080}
for n=1,6 do
 local hand={};local bad=0;local total=0
 local function visit(i)
  if i>n then total=total+1;if not R.has_points(hand) then bad=bad+1 end;return end
  for v=1,6 do hand[i]=v;visit(i+1) end
 end
 visit(1);assert(bad==expected[n] and total==6^n)
 local indices={};for i=1,n do indices[i]=i end
 assert(math.abs(D.risk('normal',indices)-bad/total)<1e-12)
 print(string.format('n=%d normal=%d/%d %.6f%% weighted=%.6f%% engraved=%.6f%%',n,bad,total,100*bad/total,100*D.risk('weighted',indices),100*D.risk('engraved',indices)))
end
-- All 924 multisets of six outcomes or fewer, tested for permutation invariance.
local tested=0
local function multisets(h,start)
 if #h>0 then
  local rev={};for i=#h,1,-1 do rev[#rev+1]=h[i] end
  assert(R.score(h)==R.score(rev));tested=tested+1
 end
 if #h==6 then return end
 for v=start,6 do h[#h+1]=v;multisets(h,v);h[#h]=nil end
end
multisets({},1);assert(tested==923)
-- Evaluate one reroll with three fair dice, take maximal valid subset then bank.
local sum,bad=0,0
for a=1,6 do for b=1,6 do for c=1,6 do
 local h={a,b,c};local best=0
 for mask=1,7 do local v={};for i=1,3 do if math.floor(mask/2^(i-1))%2==1 then v[#v+1]=h[i] end end;best=math.max(best,R.score(v) or 0) end
 sum=sum+best;if best==0 then bad=bad+1 end
end end end
assert(sum==1850 and bad==60)
print('3 dice: expected added score=1850/216; bank threshold for one-step policy=30.8333333333')
print('PASS 923 nonempty multisets, scoring permutation invariance; exact enumeration, not simulated runs')
