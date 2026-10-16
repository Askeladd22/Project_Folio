-- Exhaustive local outcomes only: no simulated runs or physics changes.
local R=require('experiments.folio_roguelite.rules')
local function check(slots,used,expected,total)
 local s=R.new(); s.slots=slots; s.used=used
 local indices={}; for i=1,4 do if not used[i] then indices[#indices+1]=i end end
 local bad,n=0,0
 local function visit(j)
  if j>#indices then n=n+1; if not R.advance_possible(s) then bad=bad+1 end; return end
  for c=1,6 do s.hand[indices[j]]=c; visit(j+1) end
 end
 visit(1); assert(n==total and bad==expected)
 assert(math.abs(bad/n-R.bust_probability(s))<1e-12)
 print('Exact bust '..bad..'/'..n)
end
check({}, {},1,1296)
check({[1]='fixed',[2]='fixed',[3]='wet',[4]='wet'}, {[1]=true,[2]=true},16,36)
check({[1]='fixed',[2]='fixed',[3]='fixed',[4]='wet',[5]='wet'}, {[1]=true,[2]=true},25,36)
check({[1]='fixed',[2]='fixed',[3]='wet',[4]='wet',[5]='wet'}, {[1]=true,[2]=true,[3]=true},5,6)

-- Two wet applications, two remaining colors and two dice. Reroll once,
-- assign maximal compatible pigments, bank. Compare fixed progress to bank now.
local sum,fixsum,bust=0,0,0
for a=1,6 do for b=1,6 do
 local gain=(a==2 or b==2) and 1 or 0
 gain=gain+((a==6 or b==6) and 1 or 0)
 if gain==0 then bust=bust+1; fixsum=fixsum+1
 else sum=sum+2+gain; fixsum=fixsum+2+gain end
end end
assert(bust==16 and sum==62 and fixsum==78)
print('Bank=2; reroll then bank=62/36; with fixative=78/36 (new fixed applications)')

-- A compatible transfer preserves the entire multiset of missing pigments,
-- including repeated requirements, not just the number of useful colors.
for mask=0,63 do
 local s=R.new(); s.phase='choice'; R.choose(s,'model'); s.phase='ready'
 for i=1,6 do if math.floor(mask/2^(i-1))%2==1 then s.slots[i]='fixed' end end
 if s.slots[2] and not s.slots[3] then
  local function missing()
   local counts={0,0,0,0,0,0}; for i,c in ipairs(R.recipes[2]) do if not s.slots[i] then counts[c]=counts[c]+1 end end
   return table.concat(counts,',')
  end
  local before=missing(); assert(R.transfer(s,2,3)); assert(missing()==before)
 end
end
print('PASS transfer invariant across compatible fixed-slot configurations')
