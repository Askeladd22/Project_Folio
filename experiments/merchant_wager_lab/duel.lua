-- V3 asymmetrical best-of-three Merchant duel; the production Farkle module
-- remains the sole authority for the Artist's six-die turns.
local Rules=require('src.farkle.rules')
local Match=require('experiments.merchant_wager_lab.match')
local Box=require('experiments.merchant_wager_lab.box')
local M={}

local INITIAL_DRAW=2
local TARGET_HAND_WINS=2

local function selected_count(turn)
 local n=0;for _ in pairs(turn.selected) do n=n+1 end;return n
end
local function record_player(m,action,provisional,available,outcome)
 local row={hand=m.hand.number,player_score=m.score.player,merchant_score=m.score.merchant,
  score_diff=m.score.merchant-m.score.player,provisional=provisional or 0,
  dice_available=available or 0,action=action,outcome=outcome or '',
  offer=m.hand.offer,actor='artist',step=#m.decisions+1}
 m.hand.player_decisions[#m.hand.player_decisions+1]=row
 m.decisions[#m.decisions+1]=row
 return row
end

local function finish_match(m,winner,reason)
 m.winner=winner;m.end_reason=reason;m.phase='over';m.pot_at_end=m.pot
 m.reserve[winner]=m.reserve[winner]+m.pot;m.pot=0
end

local function finish_hand(m,winner,reason)
 local h=m.hand
 h.winner=winner;h.end_reason=reason
 if winner=='artist' then m.hands_won.artist=m.hands_won.artist+1
 else m.hands_won.merchant=m.hands_won.merchant+1 end
 m.completed_hands[#m.completed_hands+1]=h
 if m.hands_won.artist>=TARGET_HAND_WINS then finish_match(m,'artist','best_of_three')
 elseif m.hands_won.merchant>=TARGET_HAND_WINS then finish_match(m,'merchant','best_of_three')
 elseif h.number>=3 then
  if m.hands_won.artist>m.hands_won.merchant then finish_match(m,'artist','three_hands')
  else finish_match(m,'merchant','three_hands') end
 else m.phase='hand_end' end
end

local function begin_hand(m,number)
 m.hand={number=number,initial_symbols={},symbols={},initial_offer=0,offer=0,
  player_result=nil,player_farkle=false,player_rerolls=0,char_draws=0,
  counteroffers=0,x_count=0,merchant_decisions={},merchant_continues=0,
  merchant_withdrawals=0,player_decisions={}}
 for _=1,INITIAL_DRAW do
  local card=Box.draw(m.box)
  m.hand.initial_symbols[#m.hand.initial_symbols+1]=card.id
  m.hand.symbols[#m.hand.symbols+1]=card.id
  m.hand.char_draws=m.hand.char_draws+1
  if card.id=='X' then
   m.hand.x_count=m.hand.x_count+1;m.x_draws=m.x_draws+1
  else m.hand.initial_offer=m.hand.initial_offer+card.points end
 end
 m.hand.offer=m.hand.initial_offer
 m.turn=Rules.new('control')
 m.phase='player'
 if m.hand.x_count>0 then
  m.hand.player_result=0
  m.last_merchant_action='Offerta iniziale fallita: è uscito X.'
  finish_hand(m,'artist','initial_x')
 else
  m.last_merchant_action='Offerta iniziale: '..m.hand.offer..' punti ('..
   table.concat(m.hand.initial_symbols,' ')..').'
 end
end

function M.new(seed,id)
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and seed<2147483647,
  'seed must be integer 1..2147483646')
 local player_rng=Match.new_rng(seed)
 local merchant_seed=1+((seed*48271)%2147483646)
 local merchant_rng=Match.new_rng(merchant_seed)
 local m={id=id or 1,seed=seed,player_rng=player_rng,merchant_rng=merchant_rng,
  box=Box.new(merchant_rng),phase='player',round=1,score={player=0,merchant=0},
  hands_won={artist=0,merchant=0},reserve={artist=4,merchant=4},
  deposited={artist=1,merchant=1},pot=2,initial_pot=2,max_pot=2,
  completed_hands={},decisions={},counteroffers=0,merchant_withdrawals=0,x_draws=0,
  last_merchant_action='',saved=false}
 m.reserve.artist=m.reserve.artist-m.deposited.artist
 m.reserve.merchant=m.reserve.merchant-m.deposited.merchant
 begin_hand(m,1)
 return m
end

function M.can_roll(m) return m.phase=='player' and Rules.can_roll(m.turn) end
function M.can_toggle(m,id)
 return m.phase=='player' and m.turn.phase=='ready' and m.turn.hand[id]~=nil and not m.turn.used[id]
end
function M.can_take(m) return m.phase=='player' and Rules.selection(m.turn)~=nil end
function M.can_bank(m) if m.phase~='player' then return false end;local ok=Rules.bank_status(m.turn);return ok end

function M.roll(m)
 if not M.can_roll(m) then return false end
 local t=m.turn;local reroll=t.phase=='ready';local previous=t.pot
 assert(Rules.start(t),'production rules refused a legal V3 roll')
 local count=#t.active;local faces={}
 for _,id in ipairs(t.active) do faces[id]=m.player_rng(1,6) end
 m.hand.player_rerolls=m.hand.player_rerolls+(reroll and 1 or 0)
 assert(Rules.settle(t,faces),'production rules refused V3 dice')
 local values={};for _,id in ipairs(t.active) do values[#values+1]=faces[id] end
 local outcome
 if t.phase~='ready' then outcome='Farkle: '..table.concat(values,' ')
 else
  local best=0;for _,option in ipairs(Rules.options(t)) do best=math.max(best,option.points) end
  outcome='valido +'..best..': '..table.concat(values,' ')
 end
 record_player(m,reroll and 'rilancia' or 'lancia',previous,count,outcome)
 if t.phase~='ready' then
  m.hand.player_farkle=true;m.hand.player_result=0
  if m.hand.offer>0 then finish_hand(m,'merchant','artist_farkle')
  else finish_hand(m,'artist','tie_after_farkle') end
 end
 return true
end

function M.toggle(m,id)
 if not M.can_toggle(m,id) then return false end
 return Rules.toggle(m.turn,id)
end

function M.take(m)
 if not M.can_take(m) then return false end
 local points=Rules.selection(m.turn);local selected=selected_count(m.turn)
 record_player(m,'accantona',m.turn.pot+points,Rules.count_free(m.turn)-selected)
 assert(Rules.take(m.turn),'production Farkle rejected V3 selection')
 return true
end

function M.bank(m)
 if not M.can_bank(m) then return false end
 local turn=m.turn;local selected=selected_count(turn);local points=Rules.selection(turn)
 if points then record_player(m,'accantona',turn.pot+points,Rules.count_free(turn)-selected) end
 record_player(m,'incassa',turn.pot+(points or 0),Rules.count_free(turn)-(points and selected or 0))
 assert(Rules.bank_turn(turn),'production Farkle rejected V3 bank')
 m.hand.player_result=turn.bank
 m.score.player=m.score.player+turn.bank
 local result=m.hand.player_result
 if m.hand.offer>result then finish_hand(m,'merchant','offer_higher')
 elseif m.hand.offer==result then finish_hand(m,'artist','tie_goes_to_artist')
 else m.phase='merchant_decision' end
 return true
end

-- Exact chance of eventually beating the player's score before drawing X from
-- the remaining public box; the policy thresholds are fixed, not adaptive to
-- hidden cards or variant. A hand-score deficit makes the Merchant more willing
-- to risk the current offer.
function M.decision_threshold(m)
 if m.hands_won.merchant<m.hands_won.artist then return 0.30 end
 if m.hands_won.merchant>m.hands_won.artist then return 0.65 end
 return 0.50
end

function M.preview_decision(m)
 assert(m.phase=='merchant_decision','Merchant decision is not available')
 local chance=Box.probability_to_exceed(m.box,m.hand.player_result,m.hand.offer)
 local threshold=M.decision_threshold(m)
 return {chance=chance,threshold=threshold,
  action=chance>=threshold and 'continue' or 'withdraw',
  needed=m.hand.player_result-m.hand.offer}
end

function M.advance_merchant(m)
 if m.phase~='merchant_decision' then return false end
 local decision=M.preview_decision(m)
 local row={hand=m.hand.number,offer=m.hand.offer,player_result=m.hand.player_result,
  gap=m.hand.player_result-m.hand.offer,remaining=Box.remaining(m.box),
  probability=decision.chance,threshold=decision.threshold,action=decision.action,
  symbol='',added=0,actor='merchant',step=#m.decisions+1,
  player_score=m.score.player,merchant_score=m.score.merchant}
 m.hand.merchant_decisions[#m.hand.merchant_decisions+1]=row
 m.decisions[#m.decisions+1]=row
 if decision.action=='withdraw' then
  m.hand.merchant_withdrawals=m.hand.merchant_withdrawals+1
  m.merchant_withdrawals=m.merchant_withdrawals+1
  m.last_merchant_action=('Rinuncia: probabilità %.1f%% sotto soglia %.0f%%.'):format(
   decision.chance*100,decision.threshold*100)
  finish_hand(m,'artist','merchant_withdraws')
  return true
 end
 m.hand.merchant_continues=m.hand.merchant_continues+1
 local card=Box.draw(m.box)
 m.hand.symbols[#m.hand.symbols+1]=card.id
 m.hand.char_draws=m.hand.char_draws+1
 m.hand.counteroffers=m.hand.counteroffers+1
 m.counteroffers=m.counteroffers+1
 row.symbol=card.id;row.added=card.points
 if card.id=='X' then
  m.hand.x_count=m.hand.x_count+1;m.x_draws=m.x_draws+1
  m.last_merchant_action='Controfferta fallita: estratto X, mano dell’Artista.'
  finish_hand(m,'artist','counteroffer_x')
 elseif card.points>0 then
  m.hand.offer=m.hand.offer+card.points
  m.last_merchant_action=('Controfferta %s: +%d, offerta %d.'):format(card.id,card.points,m.hand.offer)
  if m.hand.offer>m.hand.player_result then finish_hand(m,'merchant','counteroffer_wins')
  elseif m.hand.offer==m.hand.player_result then m.phase='merchant_decision'
  else m.phase='merchant_decision' end
 end
 return true
end

function M.next_hand(m)
 if m.phase~='hand_end' then return false end
 begin_hand(m,#m.completed_hands+1)
 return true
end

function M.total_sheets(m) return m.reserve.artist+m.reserve.merchant+m.pot end
function M.record(m)
 assert(m.phase=='over','record only a completed V3 match')
 return {id=m.id,seed=m.seed,initial_pot=m.initial_pot,hands_played=#m.completed_hands,
  artist_hands=m.hands_won.artist,merchant_hands=m.hands_won.merchant,
  winner=m.winner,reason=m.end_reason,total_counteroffers=m.counteroffers,
  merchant_withdrawals=m.merchant_withdrawals,x_draws=m.x_draws,
  merchant_hand_win_pct=100*m.hands_won.merchant/#m.completed_hands,
  pot_awarded=m.pot_at_end,artist_sheets=m.reserve.artist,merchant_sheets=m.reserve.merchant}
end
return M
