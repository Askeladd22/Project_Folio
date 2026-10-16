local R=require('src.gameplay.farkle.rules')
assert(type(R.equip_reference)=='function','experimental medal equipment is missing')
local M=require('src.gameplay.farkle.medals')
local function fresh(id) local s=R.new();assert(R.equip_reference(s,id));return s end
local function roll(s,h) assert(R.start(s));assert(R.settle(s,h)) end
local bust={2,2,3,3,4,6}
for n,tier in ipairs{'tin','silver','gold'} do
 assert(M.get('bust_retry_'..tier).max_uses==n and not M.get('bust_retry_'..tier).enabled)
 assert(M.get('extra_die_'..tier).max_uses==n and not M.get('extra_die_'..tier).enabled)
 assert(M.get('transform_'..tier).parameters.value==({3,5,1})[n] and not M.get('transform_'..tier).enabled)
end
assert(#M.list==34)
for _,id in ipairs{'reroll_tin','reroll_silver','reroll_gold','reroll_wedding','exchange_silver','exchange_gold'} do
 local s=fresh(id);local d=M.get(id)
 assert(not R.use_reference(s,{1}),'cannot use before rolling')
 roll(s,{1,2,2,3,4,6});local ids=d.same_value and {2,3} or {2}
 assert(not R.use_reference(s,{}));assert(not R.use_reference(s,{2,2}));assert(not R.use_reference(s,{7}))
 if d.same_value then assert(not R.use_reference(s,{1,2})) end
 assert(M.remaining(s)==1)
 assert(R.use_reference(s,ids));assert(s.phase=='rolling' and M.remaining(s)==0)
 assert(#s.active==#ids and not s.used[1])
 local h={};for _,i in ipairs(ids) do h[i]=4 end
 assert(R.settle(s,h));assert(s.hand[1]==1 and s.phase=='ready','retain unrerolled scoring dice')
 assert(not R.use_reference(s,ids));assert(R.toggle(s,1));assert(R.bank_turn(s));assert(s.bank==10)
 assert(R.next_turn(s));assert(M.remaining(s)==0,'next turn must not refill medal')
end
local s=fresh('reroll_gold');roll(s,{1,5,2,3,4,6});assert(R.toggle(s,1));assert(R.take(s))
assert(not R.use_reference(s,{1}),'cannot reroll banked die')
assert(R.use_reference(s,{3,4,6}));assert(R.settle(s,{[3]=2,[4]=3,[6]=4}));assert(s.pot==10 and s.used[1] and s.hand[2]==5)
assert(R.toggle(s,2));assert(R.take(s));assert(R.start(s));assert(R.settle(s,{[3]=2,[4]=3,[5]=4,[6]=6}));assert(s.phase=='ended')
s=fresh('bank_multiplier_gold');roll(s,{1,1,1,2,3,4});for i=1,3 do R.toggle(s,i) end
assert(R.reference_status(s));assert(R.use_reference(s));assert(s.bank==150 and s.phase=='upgrade' and M.remaining(s)==0)
assert(not R.use_reference(s));assert(R.choose_build(s,'normal'));assert(M.remaining(s)==1 and s.bank==0)
s=fresh('bank_multiplier_gold');s.stage=2;roll(s,{1,2,3,4,6,6});R.toggle(s,1)
assert(not R.use_reference(s),'bonus cannot bypass Manuscript entry threshold');assert(M.remaining(s)==1 and s.pot==0)
s=fresh('reroll_tin');roll(s,{1,2,3,4,5,6});for i=1,6 do R.toggle(s,i) end;assert(R.take(s));assert(s.hot)
assert(not R.use_reference(s,{1}));assert(R.start(s));assert(#s.active==6);assert(R.settle(s,{1,2,3,4,5,6}));assert(R.use_reference(s,{1}))
for _,d in ipairs(M.list) do
 assert(d.id and d.reference and d.effect and d.trigger and d.duration and d.verification)
 if not d.enabled then local x=R.new();assert(not R.equip_reference(x,d.id));assert(x.medal=='none') end
end
s=fresh('reroll_tin');assert(R.start(s));assert(not R.equip_reference(s,'reroll_gold'))
assert(R.settle(s,bust));assert(s.phase=='ended' and not R.use_reference(s,{1}),'unverified post-bust activation unavailable')
s=fresh('reroll_tin');roll(s,{1,5,2,3,4,6});assert(not R.use_reference(s,{1,2}));assert(M.remaining(s)==1)
assert(R.toggle(s,1));assert(R.take(s));assert(R.toggle(s,2));assert(R.take(s));assert(R.start(s))
assert(R.settle(s,{[3]=2,[4]=3,[5]=4,[6]=6}));assert(s.phase=='ended' and s.pot==0)
for _,phase in ipairs{'rolling','fresh','ended','lost','won','upgrade','medal','advance','rescue'} do
 s=fresh('bank_multiplier_gold');s.phase=phase;s.pot=75;assert(not R.use_reference(s));assert(M.remaining(s)==1)
end
print('PASS medal tiers, charges, invalid states, physical subsets, retained faces, hot dice, thresholds and commission reset')
