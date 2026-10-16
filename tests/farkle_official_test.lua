local R=require('src.gameplay.farkle.rules')
local function eq(a,b,why) assert(a==b,(why or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function roll(s,h) assert(R.start(s));assert(R.settle(s,h)) end
local function pick(s,ids) for _,i in ipairs(ids) do assert(R.toggle(s,i)) end end
eq(R.score({1}),10,'single 1');eq(R.score({5}),5,'single 5')
local triples={75,20,30,40,50,60}
for v=1,6 do
 for n=1,6 do local h={};for i=1,n do h[i]=v end
  local want
  if n<3 then if v==1 then want=10*n elseif v==5 then want=5*n end
  elseif n==3 then want=triples[v] elseif n==4 then want=100+10*v elseif n==5 then want=300+20*v else want=600+25*v end
  eq(R.score(h),want,'kind '..v..' count '..n)
 end
end
for _,h in ipairs{{1,2,3,4,5},{2,3,4,5,6}} do eq(R.score(h),100,'small straight') end
eq(R.score({1,2,3,4,5,6}),200);eq(R.score({2,2,3,3,4,4}),150)
eq(R.score({2,2,2,2,3,3}),200);eq(R.score({2,2,2,3,3,3}),250)
eq(R.score({1,1,2,3,4,5}),110,'straight plus disjoint 1')
eq(R.score({1,2}),nil);eq(R.score({0}),nil);eq(R.score({7}),nil);eq(R.score({}),nil)
assert(R.has_points({2,2,3,3,4,4}),'three pairs are not a Farkle')
local s=R.new();roll(s,{1,3,3,3,4,6})
local options=R.options(s);local masks={}
for _,o in ipairs(options) do
 assert(not masks[o.mask],'duplicate physical subset');masks[o.mask]=o
 local seen={};local sum=0
 for _,g in ipairs(o.groups) do sum=sum+g.points;for _,id in ipairs(g.ids) do assert(not seen[id],'double counting');seen[id]=true end end
 eq(sum,o.points);for _,id in ipairs(o.ids) do assert(seen[id]) end
end
eq(masks[1].points,10);eq(masks[1].remaining,5)
eq(masks[14].points,30);eq(masks[14].remaining,3)
eq(masks[15].points,40);eq(masks[15].remaining,2)
eq(#options,3,'all meaningful physical subsets')
for _,choice in ipairs{{1},{2,3,4},{1,2,3,4}} do
 local t=R.new();roll(t,{1,3,3,3,4,6});pick(t,choice);assert(R.take(t));eq(R.count_free(t),6-#choice);assert(R.start(t))
end
-- Previously held 1 must never join two new 1s to make a triple.
s=R.new();roll(s,{1,2,2,4,4,6});pick(s,{1});assert(R.take(s));eq(s.pot,10)
roll(s,{[2]=1,[3]=1,[4]=3,[5]=3,[6]=4});pick(s,{2,3});eq(R.selection(s),20);assert(R.take(s));eq(s.pot,30)
-- Threshold failure must not commit the selected dice or mark entry.
local c=R.contracts[1];local entry,bank=c.entry_min,c.bank_min;c.entry_min=40;c.bank_min=20
s=R.new();roll(s,{1,3,3,3,4,6});pick(s,{1});assert(not R.bank_turn(s));eq(s.pot,0);assert(not s.used[1] and s.selected[1] and not s.entered)
pick(s,{2,3,4});assert(R.bank_turn(s));eq(s.bank,40);assert(s.entered and s.group)
assert(R.next_turn(s));roll(s,{1,2,2,3,4,6});pick(s,{1});assert(not R.bank_turn(s));assert(R.take(s));eq(s.pot,10)
roll(s,{[2]=1,[3]=2,[4]=3,[5]=4,[6]=6});assert(not R.bank_turn(s),'cannot ignore a new valid roll')
pick(s,{2});assert(R.bank_turn(s));eq(s.bank,60)
c.entry_min=0;c.bank_min=0
s=R.new();assert(not R.bank_turn(s));roll(s,{1,2,2,3,4,6});pick(s,{1});assert(R.bank_turn(s));assert(s.entered)
c.entry_min=entry;c.bank_min=bank
-- Hot obtained but lost does not satisfy the banked hot condition.
s=R.new();s.stage=3;roll(s,{1,2,3,4,5,6});pick(s,{1,2,3,4,5,6});assert(R.take(s));assert(s.hot and s.turnHot and not s.hotBank)
roll(s,{2,2,3,3,4,6});eq(s.pot,0);assert(not s.hotBank and not s.turnHot)
-- Every physical identity stays available, even for equal values.
s=R.new();roll(s,{1,1,1,1,1,1});eq(#R.options(s),63);pick(s,{6});eq(R.selection(s),10)
print('PASS official table, disjoint physical-ID options, freedom, per-roll isolation, atomic thresholds and entry, hot banking')
