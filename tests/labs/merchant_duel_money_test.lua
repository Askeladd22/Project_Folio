-- V4 Venetian economy and V3 Farkle/type-box integration.
local Currency=require('experiments.merchant_wager_lab.currency')
local Wager=require('experiments.merchant_wager_lab.wager')
local Money=require('experiments.merchant_wager_lab.money_duel')
local Log=require('experiments.merchant_wager_lab.money_log')
local Sim=require('experiments.merchant_wager_lab.money_simulate')
local Rules=require('src.farkle.rules')
local Box=require('experiments.merchant_wager_lab.box')
local count=0
local function test(name,run) run();count=count+1;print('PASS V4 '..name) end
local function contains(list,name)
 for _,row in ipairs(list) do if row.action==name then return true end end
 return false
end

test('lira di piccoli conversion and formatting',function()
 assert(Currency.from_units(1,0,0)==240)
 assert(Currency.from_units(0,1,0)==12)
 assert(Currency.from_units(1,3,6)==282)
 local l,s,d=Currency.split(282)
 assert(l==1 and s==3 and d==6)
 assert(Currency.format(282)=='1 lira · 3 soldi · 6 denari')
 assert(Currency.format(480)=='2 lire')
 assert(Currency.format(0)=='0 denari')
end)
test('reject fractional, negative and non-canonical money',function()
 for _,bad in ipairs({-1,0.5,math.huge}) do assert(not Currency.is_valid(bad)) end
 assert(not pcall(Currency.from_units,1,20,0))
 assert(not pcall(Currency.from_units,1,0,12))
end)
test('exact initial ante and two independent wallets',function()
 local w=Wager.new(101,1)
 assert(Wager.start_hand(w,1))
 assert(w.wallet.artist==216 and w.wallet.merchant==216 and w.pot==48)
 assert(Wager.total(w)==480)
 assert(not Wager.start_hand(w,1),'double ANTE must not charge again')
 assert(#w.ledger==2)
end)
test('matched raise and call yield eight soldi pot',function()
 local w=Wager.new(102,2);assert(Wager.start_hand(w,1))
 assert(Wager.propose(w,'artist'))
 assert(w.pot==72 and w.wallet.artist==192)
 assert(not Wager.propose(w,'merchant'))
 assert(Wager.accept(w,'merchant'))
 assert(w.pot==96 and w.wallet.merchant==192)
 assert(not Wager.accept(w,'merchant'),'double call')
 assert(Wager.begin_play(w))
 assert(Wager.payout(w,'artist','score'))
 assert(w.wallet.artist==288 and w.wallet.merchant==192 and w.pot==0)
 assert(not Wager.payout(w,'artist'),'double payout')
 assert(Wager.total(w)==480 and #w.hands==1)
end)
test('rejected raise is refunded and ante pot awarded once',function()
 local w=Wager.new(103,3);assert(Wager.start_hand(w,1))
 assert(Wager.propose(w,'merchant'))
 assert(Wager.fold(w,'artist','declined raise'))
 assert(w.wallet.artist==216 and w.wallet.merchant==264 and w.pot==0)
 assert(contains(w.ledger,'RAISE') and contains(w.ledger,'REFUND'))
 assert(contains(w.ledger,'FOLD') and contains(w.ledger,'PAYOUT'))
 assert(not Wager.fold(w,'artist'),'cannot fold twice')
 Wager.assert_conservation(w)
end)
test('ordinary voluntary fold awards only committed pot',function()
 local w=Wager.new(104);assert(Wager.start_hand(w,1))
 assert(Wager.begin_play(w))
 assert(Wager.fold(w,'merchant'))
 assert(w.wallet.artist==264 and w.wallet.merchant==216 and w.pot==0)
end)
test('insufficient funds cannot start or raise; no credit/all-in',function()
 local w=Wager.new(105,1,{starting_balance=24})
 assert(Wager.start_hand(w,1))
 assert(not Wager.can_raise(w,'artist'))
 assert(Wager.payout(w,'merchant'))
 assert(Wager.insolvent(w)=='merchant')
 assert(not Wager.start_hand(w,2))
 Wager.assert_conservation(w)
end)
test('wallets persist across 3 separate hands',function()
 local w=Wager.new(106);assert(Wager.start_hand(w,1))
 assert(Wager.payout(w,'artist'))
 assert(Wager.start_hand(w,2));assert(Wager.payout(w,'merchant'))
 assert(Wager.start_hand(w,3));assert(Wager.payout(w,'artist'))
 assert(w.wallet.artist==264 and w.wallet.merchant==216)
 assert(Wager.total(w)==480 and #w.hands==3)
 assert(not Wager.start_hand(w,4))
end)
local function active(seed,option)
 for n=seed,seed+500 do
  local m=Money.new(n,1,option)
  if m.phase=='betting' then return m end
 end
 error('no seed with non-X and no merchant pre-raise')
end
test('V4 uses the unchanged V3 20-symbol type box',function()
 local m=Money.new(222,1,{raises_enabled=false})
 assert(Box.total(m.base.box)==20)
 local c=Box.remaining(m.base.box)
 local disc=Box.discarded(m.base.box)
 for i,expected in ipairs({6,5,4,2,3}) do assert(c[i]+disc[i]==expected) end
 assert(type(Rules.bank_turn)=='function')
end)
test('opening X ends hand automatically after collecting ante',function()
 local m
 for seed=1,200 do
  local candidate=Money.new(seed,1,{raises_enabled=false})
  if candidate.base.hand.x_count>0 then m=candidate;break end
 end
 assert(m and (m.phase=='hand_end' or m.phase=='over'))
 assert(m.wager.hands[1].winner=='artist')
 assert(m.wager.hands[1].award==48 and m.wager.pot==0)
 assert(m.wager.wallet.artist==264)
 assert(not Money.bank(m))
end)
test('merchant policy only sees public offer, box composition and history',function()
 local m=Money.new(101,1,{raises_enabled=true})
 assert(#m.policy_log>=0)
 for _,row in ipairs(m.policy_log) do
  assert(type(row.offer)=='number')
  assert(row.chance>=0 and row.chance<=1)
 end
end)
test('player can raise before dice, merchant may call or fold',function()
 local m=active(101,{raises_enabled=false})
 m.raises_enabled=true
 assert(Money.can_propose(m))
 assert(Money.propose(m))
 assert(m.phase=='betting' or m.phase=='hand_end' or m.phase=='over')
 assert(contains(m.wager.ledger,'RAISE'))
 assert(not Money.propose(m),'duplicate raise impossible')
 Wager.assert_conservation(m.wager)
 if m.phase=='betting' then
  assert(contains(m.wager.ledger,'CALL'))
  assert(m.wager.pot==96)
 else
  assert(contains(m.wager.ledger,'REFUND'))
  assert(m.wager.pot==0)
 end
end)
test('merchant can make pre-roll raise; artist can decline',function()
 local found
 for seed=1,700 do
  local m=Money.new(seed,1,{raises_enabled=true})
  if m.phase=='raise_pending' then found=m;break end
 end
 assert(found)
 assert(found.wager.pending=='merchant')
 assert(Money.fold(found))
 assert(found.wager.pot==0 and found.wager.hands[1].winner=='merchant')
 assert(contains(found.wager.ledger,'REFUND'))
 assert(not Money.fold(found))
end)
test('accepting a merchant raise consumes exactly one CALL',function()
 local found
 for seed=1,700 do
  local m=Money.new(seed,1,{raises_enabled=true})
  if m.phase=='raise_pending' then found=m;break end
 end
 assert(found and Money.accept(found))
 assert(found.phase=='betting' and found.wager.pot==96)
 assert(not Money.accept(found))
 assert(Money.start_dice(found))
 assert(found.phase=='player')
end)
test('normal Farkle banking determines hand winner, not denari conversion',function()
 local m=active(101,{raises_enabled=false})
 assert(Money.start_dice(m))
 assert(Money.roll(m))
 if m.phase=='player' then
  local best
  for _,o in ipairs(Rules.options(m.base.turn)) do
   if not best or o.points>best.points then best=o end
  end
  assert(best)
  for _,die in ipairs(best.ids) do assert(Money.toggle(m,die)) end
  assert(Money.bank(m))
 end
 assert(m.wager.initial_total==480)
 Wager.assert_conservation(m.wager)
end)
local function autoplay(seed,raises)
 local m=Money.new(seed,seed,{raises_enabled=raises})
 for step=1,240 do
  if m.phase=='over' then break
  elseif m.phase=='raise_pending' then assert(Money.accept(m))
  elseif m.phase=='betting' then assert(Money.start_dice(m))
  elseif m.phase=='player' then
   assert(Money.roll(m))
   if m.phase=='player' then
    local best
    for _,o in ipairs(Rules.options(m.base.turn)) do
     if not best or o.points>best.points then best=o end
    end
    assert(best)
    for _,die in ipairs(best.ids) do assert(Money.toggle(m,die)) end
    assert(Money.bank(m))
   end
  elseif m.phase=='merchant_decision' then
   assert(Money.advance_merchant(m))
  elseif m.phase=='hand_end' then
   assert(Money.next_hand(m))
  else error('unexpected money duel phase '..tostring(m.phase)) end
  Wager.assert_conservation(m.wager)
 end
 assert(m.phase=='over','duel must terminate')
 assert(#m.wager.hands>=1 and #m.wager.hands<=3)
 return m
end
test('best-of-three: winner and conservation across 30 seeds',function()
 for seed=1,30 do
  local m=autoplay(seed,true)
  assert(m.winner=='artist' or m.winner=='merchant')
  assert(m.wager.pot==0)
  assert(m.wager.wallet.artist+m.wager.wallet.merchant==480)
  assert(#m.wager.hands==#m.base.completed_hands)
 end
end)
test('same seed and same decisions repeat bank balances and full ledgers',function()
 local a,b=autoplay(219,true),autoplay(219,true)
 local function digest(m)
  local t={}
  for _,e in ipairs(m.wager.ledger) do
   t[#t+1]=table.concat({e.hand,e.actor,e.action,e.amount,e.balance_after,e.pot_after},':')
  end
  return table.concat(t,'|')
 end
 assert(digest(a)==digest(b))
 assert(Money.record(a).winner==Money.record(b).winner)
end)
test('raises disabled: all 3 hands settle with exactly one ante per player',function()
 local m=autoplay(919,false)
 assert(not contains(m.wager.ledger,'RAISE'))
 assert(not contains(m.wager.ledger,'CALL'))
 assert(Money.record(m).raises==0)
end)
test('V4 versioned CSVs save once, with transaction records and no V3 overwrite',function()
 local files={}
 local fs={getInfo=function(path) return files[path] and {} or nil end,
  read=function(path) return files[path] end,
  write=function(path,value) files[path]=value;return true end,
  append=function(path,value) files[path]=files[path]..value;return true end}
 assert(Log.next_id(fs)==1)
 local m=autoplay(434,true)
 assert(Log.save(fs,m))
 assert(m.saved)
 assert(Log.next_id(fs)==2)
 assert(files[Log.LEDGER]:find('ANTE',1,true))
 assert(files[Log.MATCHES]:find('artist_denari',1,true))
 assert(files[Log.HANDS]:find('initial_offer',1,true))
 assert(files[Log.POLICY]:find('chance',1,true))
 assert(files[Log.DECISIONS]:find('provisional',1,true))
 assert(not pcall(Log.save,fs,m),'must not duplicate saved transactions')
end)
test('paired raise/no-raise simulations conserve funds and repeat',function()
 local a=Sim.compare(15,77)
 local b=Sim.compare(15,77)
 assert(#a==3 and #b==3)
 for i=1,#a do
  assert(a[i].policy==b[i].policy)
  assert(a[i].without.matches==15 and a[i].with.matches==15)
  assert(a[i].without.raises==0)
  assert(a[i].without.player_money+a[i].without.merchant_money==480*15)
  assert(a[i].with.player_money+a[i].with.merchant_money==480*15)
  assert(a[i].with.raises==b[i].with.raises)
  assert(a[i].with.artist_wins==b[i].with.artist_wins)
 end
 local report=Sim.report(3,101)
 assert(report:find('Merchant Duel V4',1,true))
end)
print('PASS Merchant Duel V4 money: '..count..' scenarios')
