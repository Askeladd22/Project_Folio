-- EX-003 D: real, symmetric Farkle scoring duel (research only).
-- Both competitors play 6 own Farkle turns with six D6.
-- All score/select/bank/bust behavior delegates to src.farkle.rules.
local Rules=require('src.farkle.rules')
local RNG=require('experiments.opponent_wager_lab.rng')
local Policy=require('experiments.ex003_duel_lab.policy')
local D={}
D.rounds=6

-- A turn uses an independent dice stream keyed by seed, round and actor.
-- 'own'/'other' are public banked scores BEFORE this actor starts the turn.
function D.turn(seed,round,actor,profile,own,other)
 local rng=RNG.new_rng(Policy.stream_seed(seed,round,actor))
 local turn=Rules.new('control')
 local stats={points=0,bust=0,rolls=0,choices=0,stop_differences=0}
 for step=1,100 do
  if turn.phase=='fresh' or turn.phase=='ready' and Rules.can_roll(turn) then
   assert(Rules.start(turn))
   local faces={}
   for _,id in ipairs(turn.active) do faces[id]=rng(1,6) end
   assert(Rules.settle(turn,faces))
   stats.rolls=stats.rolls+1
   if turn.phase=='ended' or turn.phase=='lost' then
    stats.bust=1
    assert(turn.bank==0 and turn.pot==0,'bust retained provisional points')
    return stats
   end
  elseif turn.phase=='ready' then
   local option=Policy.best_option(turn,profile)
   local potential=turn.pot+option.points
   local free_after=Rules.count_free(turn)-#option.ids
   local context={round=round,own_score=own,other_score=other}
   local bank=Policy.wants_bank('D',profile,context,potential,free_after)
   local baseline=Policy.wants_bank('D','balanced',context,potential,free_after)
   stats.choices=stats.choices+1
   if bank~=baseline then stats.stop_differences=stats.stop_differences+1 end
   for _,id in ipairs(option.ids) do assert(Rules.toggle(turn,id)) end
   if bank then
    assert(Rules.bank_status(turn),'bank choice rejected by Farkle rules')
    assert(Rules.bank_turn(turn))
    stats.points=turn.bank
    assert(stats.points==potential,'banked points disagree with selected dice')
    return stats
   end
   assert(Rules.take(turn),'continue choice rejected by Farkle rules')
  else
   error('EX-003 unexpected Farkle phase '..tostring(turn.phase))
  end
 end
 error('EX-003 D exceeded 100 transitions')
end

-- The rival has a transparent situational strategy and a real six-D6
-- turn (not a passive timer or automatic conversion to victory points).
function D.play(seed,player_policy)
 local totals={player=0,rival=0}
 local result={model='D',seed=seed,policy=player_policy,
  winner=nil,rounds=0,player_banked=0,rival_banked=0,
  player_busts=0,rival_busts=0,player_rolls=0,rival_rolls=0,
  bank_choices=0,stop_differences=0,claim_choices=0,
  claim_differences=0,trace={}}
 for round=1,D.rounds do
  local a=D.turn(seed,round,1,player_policy,totals.player,totals.rival)
  totals.player=totals.player+a.points
  result.player_busts=result.player_busts+a.bust
  result.player_rolls=result.player_rolls+a.rolls
  result.bank_choices=result.bank_choices+a.choices
  result.stop_differences=result.stop_differences+a.stop_differences
  -- Rival sees the current public score before deciding its own
  -- conservative/balanced/aggressive threshold for this round.
  local b=D.turn(seed,round,2,'situational',totals.rival,totals.player)
  totals.rival=totals.rival+b.points
  result.rival_busts=result.rival_busts+b.bust
  result.rival_rolls=result.rival_rolls+b.rolls
  result.trace[round]={player=a.points,rival=b.points,
    player_bust=a.bust,rival_bust=b.bust,
    player_total=totals.player,rival_total=totals.rival}
 end
 result.rounds=D.rounds
 result.player_banked=totals.player
 result.rival_banked=totals.rival
 result.winner=totals.player>totals.rival and 'player' or
  totals.rival>totals.player and 'rival' or 'draw'
 return result
end

return D
