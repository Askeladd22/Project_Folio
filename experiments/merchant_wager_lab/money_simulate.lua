-- Paired experimental simulations: with and without pre-roll raises.
-- Two independent seeded streams remain owned by the existing V3 Duel.
-- These player policies are diagnostic, NOT a claim about human behavior.
local Rules=require('src.farkle.rules')
local Money=require('experiments.merchant_wager_lab.money_duel')
local M={}
M.policies={
 prudent={stop=30,high_pot_stop=45},
 balanced={stop=50,high_pot_stop=65},
 daring={stop=80,high_pot_stop=110},
}
local function best(turn)
 local found
 for _,option in ipairs(Rules.options(turn)) do
  if not found or option.points>found.points or
   (option.points==found.points and #option.ids<#found.ids) then
   found=option
  end
 end
 return found
end
local function play(seed,raises,policy,box_profile)
 local m=Money.new(seed,seed,{raises_enabled=raises,box_profile=box_profile})
 local actions=0
 local raised_by_player=false
 for _=1,300 do
  if m.phase=='over' then return m end
  actions=actions+1
  if m.phase=='raise_pending' then
   -- A fixed public heuristic, not an oracle or prediction of future dice.
   if m.base.hand.offer>=80 then assert(Money.fold(m))
   else assert(Money.accept(m)) end
  elseif m.phase=='betting' then
   if raises and Money.can_propose(m) and m.base.hand.offer<=30
       and not raised_by_player then
    raised_by_player=true
    assert(Money.propose(m))
   else assert(Money.start_dice(m)) end
  elseif m.phase=='player' then
   local t=m.base.turn
   if Rules.can_roll(t) then
    assert(Money.roll(m))
   elseif t.phase=='ready' then
    local chosen=assert(best(t))
    for _,id in ipairs(chosen.ids) do assert(Money.toggle(m,id)) end
    local free=Rules.count_free(t)-#chosen.ids
    local potential=t.pot+chosen.points
    local stop=m.wager.hands and (m.wager.pot>=96 and policy.high_pot_stop or policy.stop)
    if potential>=stop or free<=1 then
     assert(Money.bank(m))
    else
     assert(Money.take(m))
    end
   else
    error('unexpected Farkle phase: '..t.phase)
   end
  elseif m.phase=='merchant_decision' then
   assert(Money.advance_merchant(m))
  elseif m.phase=='hand_end' then
   raised_by_player=false
   assert(Money.next_hand(m))
  else error('unknown phase '..tostring(m.phase)) end
  Money.Wager.assert_conservation(m.wager)
 end
 error('V4 diagnostic match exceeded 300 decisions')
end
M.play=play

local function bucket()
 return {matches=0,artist_wins=0,merchant_wins=0,player_money=0,
  merchant_money=0,hands=0,raises=0,folds=0,banks=0,rerolls=0,
  merchant_reversals=0,insolvent=0,player_proposals=0,merchant_proposals=0,
  declined_raises=0}
end
local function add(summary,m)
 local r=Money.record(m)
 summary.matches=summary.matches+1
 if r.winner=='artist' then summary.artist_wins=summary.artist_wins+1
 else summary.merchant_wins=summary.merchant_wins+1 end
 summary.player_money=summary.player_money+r.artist_denari
 summary.merchant_money=summary.merchant_money+r.merchant_denari
 summary.hands=summary.hands+r.hands
 summary.raises=summary.raises+r.raises
 summary.folds=summary.folds+r.folds
 if r.reason=='insolvent' then summary.insolvent=summary.insolvent+1 end
 for _,event in ipairs(m.wager.ledger) do
  if event.action=='RAISE' then
   if event.actor=='artist' then summary.player_proposals=summary.player_proposals+1
   else summary.merchant_proposals=summary.merchant_proposals+1 end
  elseif event.action=='REFUND' then summary.declined_raises=summary.declined_raises+1 end
 end
 for _,h in ipairs(m.base.completed_hands) do
  summary.rerolls=summary.rerolls+(h.player_rerolls or 0)
  if h.winner=='merchant' and h.counteroffers>0 and
   (h.player_result or 0)>=h.initial_offer then
   summary.merchant_reversals=summary.merchant_reversals+1
  end
 end
 for _,event in ipairs(m.base.decisions) do
  if event.actor=='artist' and event.action=='incassa' then summary.banks=summary.banks+1 end
 end
end
function M.compare(count,seed)
 assert(type(count)=='number' and count%1==0 and count>=1 and count<=5000)
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and seed+count-1<2147483647)
 local result={}
 for _,policy_name in ipairs({'prudent','balanced','daring'}) do
  local policy=M.policies[policy_name]
  local without,with=bucket(),bucket()
  for index=0,count-1 do
   local current_seed=seed+index
   add(without,play(current_seed,false,policy))
   add(with,play(current_seed,true,policy))
  end
  result[#result+1]={policy=policy_name,without=without,with=with}
 end
 return result
end
function M.report(count,seed)
 local data=M.compare(count,seed)
 local result={('Merchant Duel V4 — %d seed accoppiati da %d per politica'):format(count,seed),
  'Una simulazione diagnostica non misura le decisioni dei giocatori umani.',
  'policy | rialzi | vittorie A/M | denari finali medi A/M | mani medie | rialzi medi | ritiri | sorpassi'}
 for _,item in ipairs(data) do
  for _,flag in ipairs({'without','with'}) do
   local a=item[flag]
   local n=a.matches
   result[#result+1]=('%s | %s | %d/%d | %.1f/%.1f | %.2f | %.2f | %d | %d'):format(
    item.policy,flag=='with' and 'SI' or 'NO',a.artist_wins,a.merchant_wins,
    a.player_money/n,a.merchant_money/n,a.hands/n,a.raises/n,
    a.folds,a.merchant_reversals)
  end
 end
 return table.concat(result,'\n'),data
end
-- Paired Merchant-offer research with the same dice/box RNG stream per seed.
-- Profile comparisons are diagnostic; none is activated by this function.
function M.calibration_report(count,seed)
 assert(type(count)=='number' and count%1==0 and count>=1 and count<=1500)
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and seed+count-1<2147483647)
 local profiles={'legacy','mid','high','spread','swing','tail','tail_plus','tail_strong'}
 local out={('20-token calibration | %d matched seeds from %d'):format(count,seed),
  'Profile | Player policy | Raises | Artist wins | Merchant wins | Artist win % | Merchant avg opening bid | X openings'}
 for _,profile in ipairs(profiles) do
  for _,policy_name in ipairs({'prudent','balanced','daring'}) do
   local policy=M.policies[policy_name]
   for _,with_raise in ipairs({false,true}) do
    local wins={artist=0,merchant=0}
    local opening_total,n_opening,initial_x=0,0,0
    for offset=0,count-1 do
     local match=play(seed+offset,with_raise,policy,profile)
     wins[match.winner]=wins[match.winner]+1
     for _,h in ipairs(match.base.completed_hands) do
      if h.x_count>0 and h.end_reason=='initial_x' then
       initial_x=initial_x+1
      else
       opening_total=opening_total+h.initial_offer
       n_opening=n_opening+1
      end
     end
    end
    out[#out+1]=('%s | %s | %s | %d | %d | %.1f | %.1f | %d'):format(
     profile,policy_name,with_raise and 'yes' or 'no',
     wins.artist,wins.merchant,100*wins.artist/count,
     n_opening>0 and opening_total/n_opening or 0,initial_x)
   end
  end
 end
 return table.concat(out,'\n')
end

return M
