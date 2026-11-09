-- EX-001 deterministic smoke and invariants for A/B without changing src/.
local Money=require('experiments.merchant_wager_lab.money_duel')
local Box=require('experiments.merchant_wager_lab.box')
local Sim=require('experiments.ex001_merchant_x_lab.simulate')
local n=0
local function test(name,fn) fn();n=n+1;print('PASS EX-001 '..name) end
local function eq(a,b) assert(a==b,tostring(a)..' != '..tostring(b)) end
local x,clean
for seed=1,300 do
 local m=Money.new(seed,seed,{raises_enabled=false})
 if m.base.hand.x_count>0 and not x then x=seed end
 if m.base.hand.x_count==0 and not clean then clean=seed end
 if x and clean then break end
end
test('both opening classes available',function() assert(x and clean) end)
test('default exactly equals explicitly specified A',function()
 for seed=1,50 do
  local a=Money.new(seed,1,{raises_enabled=false})
  local b=Money.new(seed,1,{raises_enabled=false,opening_x_mode='baseline'})
  eq(a.phase,b.phase)
  eq(a.base.hand.initial_offer,b.base.hand.initial_offer)
  eq(table.concat(a.base.hand.initial_symbols,','),table.concat(b.base.hand.initial_symbols,','))
 end
end)
test('A opening X immediately pays only once',function()
 local a=Money.new(x,1,{raises_enabled=false})
 assert(a.phase=='hand_end' or a.phase=='over')
 eq(a.base.hand.end_reason,'initial_x')
 eq(#a.wager.hands,1)
 eq(a.wager.wallet.artist,264)
 Money.Wager.assert_conservation(a.wager)
end)
test('B opening X redraws TWO numerical symbols and no immediate payout',function()
 local a=Money.new(x,1,{raises_enabled=false})
 local b=Money.new(x,1,{raises_enabled=false,opening_x_mode='redraw'})
 eq(b.phase,'betting')
 eq(#b.wager.hands,0)
 eq(b.base.hand.initial_symbols[1],a.base.hand.initial_symbols[1])
 eq(b.base.hand.initial_symbols[2],a.base.hand.initial_symbols[2])
 assert(b.base.hand.opening_x_discarded>0)
 eq(b.base.hand.opening_draw_count,2+b.base.hand.opening_x_discarded)
 eq(#b.base.hand.opening_numeric_symbols,2)
 assert(b.base.hand.initial_offer>0)
 Money.Wager.assert_conservation(b.wager)
end)
test('no-X baseline and B state are identical',function()
 local a=Money.new(clean,1,{raises_enabled=false})
 local b=Money.new(clean,1,{raises_enabled=false,opening_x_mode='redraw'})
 eq(a.phase,b.phase)
 eq(a.base.hand.offer,b.base.hand.offer)
 eq(table.concat(a.base.hand.initial_symbols,','),table.concat(b.base.hand.initial_symbols,','))
end)
test('invalid opening mode rejected',function()
 assert(not pcall(Money.new,10,1,{opening_x_mode='other'}))
end)
test('seeded full-game reproduction and money conservation',function()
 for seed=80,98 do
  for _,mode in ipairs({'baseline','redraw'}) do
   local m1=Sim.play(seed,mode,'balanced')
   local m2=Sim.play(seed,mode,'balanced')
   eq(m1.winner,m2.winner)
   eq(m1.wager.wallet.artist,m2.wager.wallet.artist)
   eq(#m1.base.completed_hands,#m2.base.completed_hands)
   local remain,discard=Box.remaining(m1.base.box),Box.discarded(m1.base.box)
   for i,k in ipairs({6,5,4,2,3}) do eq(remain[i]+discard[i],k) end
   for i,h in ipairs(m1.base.completed_hands) do
    eq(h.end_reason,m2.base.completed_hands[i].end_reason)
    if mode=='redraw' then assert(h.end_reason~='initial_x') end
   end
  end
 end
end)
test('all four policies complete both arms',function()
 for _,p in ipairs(Sim.policies) do
  for seed=101,104 do
   local a=Sim.play(seed,'baseline',p)
   local b=Sim.play(seed,'redraw',p)
   assert(a.winner and b.winner)
   eq(a.wager.wallet.artist+a.wager.wallet.merchant,480)
   eq(b.wager.wallet.artist+b.wager.wallet.merchant,480)
  end
 end
end)
test('counteroffer X still busts the Merchant',function()
 local seen=false
 for seed=1,350 do
  local m=Sim.play(seed,'redraw','balanced')
  for _,h in ipairs(m.base.completed_hands) do
   if h.end_reason=='counteroffer_x' then
    eq(h.winner,'artist')
    seen=true
   end
  end
  if seen then break end
 end
 assert(seen)
end)
print('PASS EX-001 deterministic suite: '..n..' scenarios')
