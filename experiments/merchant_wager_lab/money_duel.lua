-- V4: Venetian wagering layered over the EXISTING V3 Farkle / type-box duel.
-- This module never changes V3's approved scoring, 20 token composition or AI.
local Duel=require('experiments.merchant_wager_lab.duel')
local Box=require('experiments.merchant_wager_lab.box')
local Wager=require('experiments.merchant_wager_lab.wager')
local Currency=require('experiments.merchant_wager_lab.currency')
local M={}
local function note(m,actor,decision,reason)
 local entry={step=#m.policy_log+1,hand=m.base.hand.number,actor=actor,
  action=decision,reason=reason,offer=m.base.hand.offer,
  artist_wins=m.base.hands_won.artist,merchant_wins=m.base.hands_won.merchant,
  chance=Box.probability_to_exceed(m.base.box,60,m.base.hand.offer),
  artist_balance=m.wager.wallet.artist,merchant_balance=m.wager.wallet.merchant}
 m.policy_log[#m.policy_log+1]=entry
 m.message=reason
 return entry
end
local function merchant_policy(m,action)
 local b=m.base;local w=m.wager
 local chance=Box.probability_to_exceed(b.box,60,b.hand.offer)
 local critical=b.hands_won.merchant<b.hands_won.artist
 local solvent=w.wallet.artist>=Wager.RAISE and w.wallet.merchant>=Wager.RAISE
 if action=='propose' then
  local yes=m.raises_enabled and solvent and b.hand.offer>=40 and
    (chance>=0.45 or critical)
  local why=('Rialzo %s: offerta %d; probabilita pubblica contro 60 pt %.1f%%; %s; fondi %s.'):format(
   yes and 'proposto' or 'non proposto',b.hand.offer,100*chance,
   critical and 'inseguimento' or 'situazione ordinaria',
   solvent and 'sufficienti' or 'insufficienti')
  note(m,'merchant',yes and 'propose_raise' or 'hold',why)
  return yes
 end
 local yes=solvent and (b.hand.offer>=30 or chance>=0.60 or critical)
 note(m,'merchant',yes and 'accept_raise' or 'reject_raise',
  ('Risposta a rialzo: offerta %d; probabilita pubblica %.1f%%; %s.'):format(
   b.hand.offer,chance*100,yes and 'accetta' or 'non accetta'))
 return yes
end
local function sync(m)
 local b=m.base
 if b.hand.winner then
  if m.wager.phase~='hand_end' then
   assert(Wager.payout(m.wager,b.hand.winner,b.hand.end_reason),
    'One and only one payout per completed hand')
  end
  if b.phase=='over' then
   m.phase='over';m.winner=b.winner;m.end_reason=b.end_reason
  else
   m.phase='hand_end'
  end
 else
  assert(m.wager.phase=='playing','live dice require active matched wager')
  m.phase=b.phase
 end
end
local function open_hand(m,number)
 if Wager.insolvent(m.wager) then
  m.phase='over';m.winner=Wager.insolvent(m.wager)
  m.end_reason='insolvent'
  note(m,'table','insolvent','Un contendente non dispone di 2 soldi per la prossima mano.')
  return false
 end
 assert(Wager.start_hand(m.wager,number),'Could not collect the ante')
 if m.base.hand.winner then
  sync(m) -- opening X: the Artist wins without a dice turn or wager raise
  return true
 end
 m.phase='betting'
 if merchant_policy(m,'propose') then
  assert(Wager.propose(m.wager,'merchant','Policy based on current public offer'))
  m.phase='raise_pending'
 end
 return true
end
function M.new(seed,id,opts)
 opts=opts or {}
 -- The V4 default is the playtested equal-expectation 'tail' profile.
 -- Legacy scores remain available only for isolated historical comparisons.
 local b=Duel.new(seed,id,opts.box_profile or 'tail')
 local m={seed=seed,id=id or 1,base=b,
  wager=Wager.new(seed,id),raises_enabled=opts.raises_enabled~=false,
  policy_log={},phase=nil,message='',winner=nil,end_reason=nil,saved=false}
 open_hand(m,1)
 return m
end
function M.can_propose(m)
 return m.phase=='betting' and m.raises_enabled and
  Wager.can_raise(m.wager,'artist')
end
function M.propose(m)
 if not M.can_propose(m) then return false end
 assert(Wager.propose(m.wager,'artist','Player raises before first roll'))
 m.phase='raise_pending'
 if merchant_policy(m,'accept') then
  assert(Wager.accept(m.wager,'merchant','Merchant calls posted raise'))
  m.phase='betting'
 else
  assert(Wager.fold(m.wager,'merchant','Merchant declines the player raise'))
  assert(Duel.fold_merchant(m.base))
  sync(m)
 end
 return true
end
function M.accept(m)
 if m.phase~='raise_pending' or m.wager.pending~='merchant' then return false end
 if not Wager.accept(m.wager,'artist','Player accepts merchant raise') then return false end
 m.phase='betting'
 return true
end
function M.start_dice(m)
 if m.phase~='betting' or not Wager.begin_play(m.wager) then return false end
 m.phase='player'
 return true
end
function M.fold(m)
 if m.phase~='raise_pending' and m.phase~='betting' and m.phase~='player' then return false end
 if m.phase~='raise_pending' and m.wager.pending then return false end
 if not Wager.fold(m.wager,'artist','Player withdraws from this proof') then return false end
 assert(Duel.fold_artist(m.base))
 sync(m)
 return true
end
function M.roll(m)
 if m.phase~='player' then return false end
 if not Duel.roll(m.base) then return false end
 sync(m);return true
end
function M.toggle(m,id)
 return m.phase=='player' and Duel.toggle(m.base,id) or false
end
function M.take(m)
 return m.phase=='player' and Duel.take(m.base) or false
end
function M.bank(m)
 if m.phase~='player' or not Duel.bank(m.base) then return false end
 sync(m);return true
end
function M.advance_merchant(m)
 if m.phase~='merchant_decision' or not Duel.advance_merchant(m.base) then return false end
 sync(m);return true
end
function M.next_hand(m)
 if m.phase~='hand_end' then return false end
 if Wager.insolvent(m.wager) then
  m.phase='over';m.winner=Wager.insolvent(m.wager);m.end_reason='insolvent'
  note(m,'table','insolvent','Non ci sono denari sufficienti per una nuova posta.')
  return true
 end
 if not Duel.next_hand(m.base) then return false end
 open_hand(m,m.base.hand.number)
 return true
end
function M.can_roll(m) return m.phase=='player' and Duel.can_roll(m.base) end
function M.can_take(m) return m.phase=='player' and Duel.can_take(m.base) end
function M.can_bank(m) return m.phase=='player' and Duel.can_bank(m.base) end
function M.can_toggle(m,id) return m.phase=='player' and Duel.can_toggle(m.base,id) end
function M.can_advance(m) return m.phase=='merchant_decision' end
function M.record(m)
 assert(m.phase=='over')
 return {id=m.id,seed=m.seed,winner=m.winner,reason=m.end_reason,
  hands=#m.wager.hands,raises_enabled=m.raises_enabled and 'yes' or 'no',
  artist_hands=m.base.hands_won.artist,merchant_hands=m.base.hands_won.merchant,
  artist_denari=m.wager.wallet.artist,merchant_denari=m.wager.wallet.merchant,
  pot_denari=m.wager.pot,raises=(function()
   local n=0;for _,e in ipairs(m.wager.ledger) do if e.action=='RAISE' then n=n+1 end end;return n end)(),
  folds=(function()local n=0;for _,e in ipairs(m.wager.ledger) do if e.action=='FOLD' then n=n+1 end end;return n end)()}
end
M.Currency=Currency
M.Wager=Wager
return M
