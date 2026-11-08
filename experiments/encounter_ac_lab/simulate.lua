-- Deterministic headless, paired-seed diagnostic comparison. Not a skill model.
local E=require('experiments.encounter_ac_lab.engine')
local Rules=require('src.farkle.rules')
local S={}
S.policies={prudent=30,balanced=60,daring=110}
local function best_option(turn,policy)
 local best
 for _,o in ipairs(Rules.options(turn)) do
  local value=o.points+(policy=='daring' and #o.ids*-4 or
    policy=='prudent' and #o.ids*2 or 0)
  if not best or value>best.value or
     (value==best.value and o.mask<best.option.mask) then
   best={value=value,option=o}
  end
 end
 return best and best.option
end
local function preferred_lane(s,policy)
 local best,best_score
 for id,lane in ipairs(s.lanes) do
  if not lane.owner then
   local score
   if policy=='prudent' then score=lane.player*5-lane.rival
   elseif policy=='daring' then score=-lane.rival*3+lane.player
   else score=lane.player*4-lane.rival*2 end
   if not best or score>best_score then best=id;best_score=score end
  end
 end
 return best
end
function S.play(mode,seed,policy)
 assert(S.policies[policy])
 local s=E.new(mode,seed)
 local steps=0
 while s.phase~='finished' do
  steps=steps+1
  assert(steps<200,'diagnostic strategy exceeded step budget')
  if s.phase=='dice' then
   if E.can_roll(s) then assert(E.roll(s))
   else
    local o=assert(best_option(s.turn,policy),'ready turn without scoring option')
    for _,id in ipairs(o.ids) do assert(E.toggle(s,id)) end
    local potential=s.turn.pot+o.points
    if potential>=S.policies[policy] or
       Rules.count_free(s.turn)-#o.ids<=1 then
     assert(E.bank(s))
    else assert(E.take(s)) end
   end
  elseif s.phase=='offer' then
   -- Evaluate all visible splits. A good player anticipates the rival pick.
   local best,best_score
   for pair=1,3 do
    for left=1,s.offered_marks-1 do
     local o=assert(E.preview_offer(s,pair,left))
     local player_lane=s.lanes[o.player_id]
     local rival_lane=s.lanes[o.rival_id]
     local before_player=player_lane.player-player_lane.rival
     local after_player=before_player+o.player_marks
     local before_rival=rival_lane.player-rival_lane.rival
     local after_rival=before_rival-o.rival_marks
     local score=(after_player>=1 and 12 or 0)+
       (before_player<1 and after_player>=1 and 8 or 0)+
       (after_rival>=0 and 5 or 0)+
       (before_rival>=0 and after_rival<0 and -8 or 0)+
       o.player_marks*2-o.rival_marks
     if policy=='prudent' then score=score+o.player_marks*2
     elseif policy=='daring' then score=score+math.max(0,after_player)*2 end
     if not best or score>best_score then
      best={pair=pair,left=left};best_score=score
     end
    end
   end
   while s.pair~=best.pair do assert(E.pair_next(s)) end
   while s.left<best.left do assert(E.split(s,1)) end
   while s.left>best.left do assert(E.split(s,-1)) end
   assert(E.resolve_offer(s))
  elseif s.phase=='claim' then
   assert(E.claim(s,assert(preferred_lane(s,policy))))
  elseif s.phase=='round_end' then assert(E.next_round(s))
  else error('unexpected phase '..tostring(s.phase)) end
 end
 return s
end
function S.compare(count,first)
 assert(type(count)=='number' and count>=1 and count<=500 and count%1==0)
 assert(type(first)=='number' and first>=1 and first+count<2147483647)
 local out={}
 for _,policy in ipairs({'prudent','balanced','daring'}) do
  local row={policy=policy,A={player=0,rival=0,draw=0,banked=0,busts=0},
   C={player=0,rival=0,draw=0,banked=0,busts=0}}
  for offset=0,count-1 do
   for _,mode in ipairs({'A','C'}) do
    local match=S.play(mode,first+offset,policy)
    local bucket=row[mode]
    bucket[match.winner]=bucket[match.winner]+1
    bucket.banked=bucket.banked+match.banked
    bucket.busts=bucket.busts+match.busts
   end
  end
  out[#out+1]=row
 end
 return out
end
function S.report(count,first)
 local rows={('Encounter A/C | paired seeds=%d from %d | diagnostics, not playtests'):format(count,first),
  'policy mode player rival draw mean_bank mean_busts'}
 for _,r in ipairs(S.compare(count,first)) do
  for _,mode in ipairs({'A','C'}) do
   local b=r[mode]
   rows[#rows+1]=('%s %s %d %d %d %.1f %.2f'):format(
    r.policy,mode,b.player,b.rival,b.draw,b.banked/count,b.busts/count)
  end
 end
 return table.concat(rows,'\n')
end
return S
