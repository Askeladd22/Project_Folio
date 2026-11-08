-- Money-only state machine. It never sees the dice or the type-box RNG.
-- Every public operation is phase-gated and idempotent against double clicks.
local Currency=require('experiments.merchant_wager_lab.currency')
local M={}
M.ANTE=Currency.from_units(0,2,0)
M.RAISE=Currency.from_units(0,2,0)
M.START_BALANCE=Currency.from_units(1,0,0)
local function other(who) assert(who=='artist' or who=='merchant');return who=='artist' and 'merchant' or 'artist' end
local function emit(s,actor,kind,amount,reason,previous,pot_before)
 local row={step=#s.ledger+1,match=s.id,seed=s.seed,hand=s.hand,
  actor=actor,action=kind,amount=amount,balance_before=previous or (s.wallet[actor] or 0),
  balance_after=s.wallet[actor] or 0,pot_before=pot_before or s.pot,
  pot_after=s.pot,reason=reason or ''}
 s.ledger[#s.ledger+1]=row
 return row
end
function M.total(s) return s.wallet.artist+s.wallet.merchant+s.pot end
function M.assert_conservation(s)
 assert(M.total(s)==s.initial_total,'money conservation violation')
 for _,who in ipairs({'artist','merchant'}) do
  assert(Currency.is_valid(s.wallet[who]),'invalid wallet balance')
 end
 assert(Currency.is_valid(s.pot),'invalid pot')
end
function M.new(seed,id,options)
 options=options or {}
 local initial=options.starting_balance or M.START_BALANCE
 assert(Currency.is_valid(initial),'invalid initial balance')
 local s={seed=seed,id=id or 1,hand=0,wallet={artist=initial,merchant=initial},
  pot=0,initial_total=initial*2,ledger={},hands={},
  phase='unstarted',raised=false,pending=nil,winner=nil,reason=nil}
 M.assert_conservation(s)
 return s
end
local function transfer_to_pot(s,who,kind,amount,reason)
 local old=s.wallet[who];local pot=s.pot
 assert(old>=amount,'insufficient funds')
 s.wallet[who]=old-amount;s.pot=pot+amount
 emit(s,who,kind,amount,reason,old,pot)
 M.assert_conservation(s)
end
local function refund(s,who,amount,reason)
 local old=s.wallet[who];local pot=s.pot
 assert(pot>=amount,'cannot refund more than the pot')
 s.wallet[who]=old+amount;s.pot=pot-amount
 emit(s,who,'REFUND',amount,reason,old,pot)
 M.assert_conservation(s)
end
function M.can_start(s)
 return s.phase=='unstarted' or s.phase=='hand_end'
end
function M.insolvent(s)
 if s.wallet.artist<M.ANTE then return 'merchant' end
 if s.wallet.merchant<M.ANTE then return 'artist' end
 return nil
end
function M.start_hand(s,number)
 if not M.can_start(s) or s.pending or s.pot~=0 then return false end
 if M.insolvent(s) then return false end
 assert(number==s.hand+1 and number<=3,'hands must be sequential')
 s.hand=number;s.raised=false;s.pending=nil;s.winner=nil;s.reason=nil
 s.phase='betting'
 transfer_to_pot(s,'artist','ANTE',M.ANTE,'Initial two soldi ante')
 transfer_to_pot(s,'merchant','ANTE',M.ANTE,'Initial two soldi ante')
 return true
end
function M.can_raise(s,who)
 return s.phase=='betting' and not s.raised and s.pending==nil and
  (who=='artist' or who=='merchant') and
  s.wallet.artist>=M.RAISE and s.wallet.merchant>=M.RAISE
end
function M.propose(s,who,reason)
 if not M.can_raise(s,who) then return false end
 s.raised=true;s.pending=who;s.phase='raise_pending'
 transfer_to_pot(s,who,'RAISE',M.RAISE,reason or 'Proposed equal raise')
 return true
end
function M.accept(s,who,reason)
 if s.phase~='raise_pending' or not s.pending or other(s.pending)~=who then return false end
 transfer_to_pot(s,who,'CALL',M.RAISE,reason or 'Accepted equal raise')
 s.pending=nil;s.phase='betting'
 return true
end
function M.can_play(s) return s.phase=='betting' and s.pending==nil end
function M.begin_play(s)
 if not M.can_play(s) then return false end
 s.phase='playing'
 return true
end
function M.payout(s,winner,reason)
 if (s.phase~='betting' and s.phase~='playing') or s.pending then return false end
 if winner~='artist' and winner~='merchant' then return false end
 local award=s.pot;local old=s.wallet[winner];local pot=s.pot
 s.wallet[winner]=old+award;s.pot=0;s.phase='hand_end'
 s.winner=winner;s.reason=reason or 'score'
 emit(s,winner,'PAYOUT',award,s.reason,old,pot)
 s.hands[#s.hands+1]={hand=s.hand,winner=winner,reason=s.reason,award=award,
  balances={artist=s.wallet.artist,merchant=s.wallet.merchant},raised=s.raised}
 M.assert_conservation(s)
 return true
end
function M.fold(s,who,reason)
 if s.phase~='betting' and s.phase~='playing' and s.phase~='raise_pending' then return false end
 if who~='artist' and who~='merchant' then return false end
 if s.pending then
  if s.pending==who then return false end -- proposer cannot retract an unmatched raise
  refund(s,s.pending,M.RAISE,'Uncalled raise returned')
  s.pending=nil;s.phase='betting'
 end
 emit(s,who,'FOLD',0,reason or 'Concedes the printing proof')
 return M.payout(s,other(who),reason or 'fold')
end
function M.balance(s,who) return s.wallet[who] end
function M.last_event(s) return s.ledger[#s.ledger] end
return M
