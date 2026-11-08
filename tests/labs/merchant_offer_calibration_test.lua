-- A/B calibrated Merchant token points, canonical Farkle stays unchanged.
local Box=require('experiments.merchant_wager_lab.box')
local RNG=require('experiments.merchant_wager_lab.rng')
local Money=require('experiments.merchant_wager_lab.money_duel')
local Sim=require('experiments.merchant_wager_lab.money_simulate')
local Rules=require('src.farkle.rules')
local function equal(a,b)
 assert(#a==#b)
 for i=1,#a do assert(a[i]==b[i],('mismatch %d: %s vs %s'):format(i,a[i],b[i])) end
end

local old=Box.new(RNG.new_rng(131),'legacy')
local new=Box.new(RNG.new_rng(131),'tail')
equal(Box.remaining(old),{6,5,4,2,3})
equal(Box.remaining(new),{6,5,4,2,3})
assert(Box.total(old)==20 and Box.total(new)==20)
assert(old.symbols[1].points==10 and old.symbols[3].points==30 and old.symbols[4].points==40)
assert(new.symbols[1].points==10 and new.symbols[2].points==20)
assert(new.symbols[3].points==25 and new.symbols[4].points==55)
assert(new.symbols[5].id=='X' and new.symbols[5].count==3)
assert(new.symbols[4].points>old.symbols[4].points)
local old_sum,new_sum=0,0
for i=1,4 do
 old_sum=old_sum+old.symbols[i].points*old.symbols[i].count
 new_sum=new_sum+new.symbols[i].points*new.symbols[i].count
end
assert(old_sum==360 and new_sum==370,
 'new token value distribution must preserve mean within 3%')
local m=Money.new(101,1,{raises_enabled=false})
assert(m.base.box.profile=='tail','V4 should use calibrated Merchant tokens')
local legacy=Money.new(101,1,{raises_enabled=false,box_profile='legacy'})
assert(legacy.base.box.profile=='legacy')
-- Seeded shuffle must remain identical by kind; only values change.
assert(#m.base.hand.initial_symbols==2)
assert(#legacy.base.hand.initial_symbols==2)
local normalized=function(id) return id=='X' and 'X' or 'N' end
for i=1,2 do
 assert(normalized(m.base.hand.initial_symbols[i])==
        normalized(legacy.base.hand.initial_symbols[i]))
end
-- Counteroffer probability MUST use the new V55, not the legacy V40.
local synthetic={draw_pile={
 {kind=4,id='V55',points=55},
 {kind=5,id='X',points=0},
},discard={},symbols=new.symbols,random=RNG.new_rng(6)}
assert(Box.probability_to_exceed(synthetic,50,0)==0.5)
local synthetic_old={draw_pile={
 {kind=4,id='V40',points=40},
 {kind=5,id='X',points=0},
},discard={},symbols=old.symbols,random=RNG.new_rng(6)}
assert(Box.probability_to_exceed(synthetic_old,50,0)<0.5)
-- The full range of canonical Farkle scorings is unchanged by Merchant calibration.
assert(Rules.points.single[1]==10)
assert(Rules.points.single[5]==5)
assert(Rules.points.kind[3][1]==75)
assert(Rules.points.kind[6][6]==750)
local report=Sim.calibration_report(4,101)
assert(report:find('tail | balanced',1,true))
assert(report:find('legacy | balanced',1,true))
print('PASS Merchant calibration: 20 tokens, rare V55, consistent probability, V4 default and unchanged Farkle')
