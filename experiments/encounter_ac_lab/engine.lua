-- Project Folio: A (divide-and-choose) and C (contested proofs).
-- Research-only. Production Farkle rules are imported, never forked.
local Rules=require('src.farkle.rules')
local RNG=require('experiments.opponent_wager_lab.rng')
local E={}
E.LANES={'Capilettera','Miniatura','Marca tipografica'}
E.PAIRS={{1,2},{1,3},{2,3}}
E.C_SEAL_TARGET=4
local function log(s,action,detail)
 s.events[#s.events+1]={round=s.round,action=action,detail=detail}
end
local function active_lanes(s)
 local count=0
 for _,lane in ipairs(s.lanes) do if lane.owner==nil then count=count+1 end end
 return count
end
local function totals(s)
 local result={player=0,rival=0}
 for _,lane in ipairs(s.lanes) do
  result.player=result.player+lane.player
  result.rival=result.rival+lane.rival
 end
 return result
end
local function owner_counts(s)
 local count={player=0,rival=0}
 for _,lane in ipairs(s.lanes) do
  if lane.owner then count[lane.owner]=count[lane.owner]+1 end
 end
 return count
end
local function result_for(s)
 local count={player=0,rival=0}
 for _,lane in ipairs(s.lanes) do
  local winner=lane.owner
  if winner==nil and lane.player~=lane.rival then
   winner=lane.player>lane.rival and 'player' or 'rival'
  end
  if winner then count[winner]=count[winner]+1 end
 end
 if count.player>count.rival then return 'player' end
 if count.rival>count.player then return 'rival' end
 -- Tied control is a genuine draw; raw seals never become hidden tie breakers.
 return 'draw'
end
local function end_round(s,message)
 s.last=message
 if s.mode=='C' then
  local owned=owner_counts(s)
  if owned.player>=2 or owned.rival>=2 then
   s.winner=owned.player>=2 and 'player' or 'rival'
   s.phase='finished'
   log(s,'finished',s.winner)
   return
  end
 end
 if s.round>=s.max_rounds then
  s.winner=result_for(s);s.phase='finished'
  log(s,'finished',s.winner)
 else s.phase='round_end' end
end
-- A: rival utility is transparent, static and depends on the public board.
-- No dice or additional push-your-luck system for the rival.
local function offer_utility(s,lane_id,amount)
 local l=s.lanes[lane_id]
 local priority=({3,2,1})[lane_id]
 local close=math.min(2,math.max(0,3-l.rival))
 local contest=(l.player>=l.rival) and 2 or 0
 return amount*5+priority+close+contest
end
local function rival_spare(s)
 local best,best_score
 for id,l in ipairs(s.lanes) do
  local score=offer_utility(s,id,1)
  if best==nil or score>best_score then best=id;best_score=score end
 end
 return best
end
local function c_seal(s,actor,lane_id,amount)
 local l=s.lanes[lane_id]
 if l.owner then return false end
 l[actor]=math.min(E.C_SEAL_TARGET,l[actor]+amount)
 if l[actor]>=E.C_SEAL_TARGET then
  l.owner=actor;log(s,'sealed',actor..':'..lane_id)
 end
 return true
end
-- EX-002: the only experimental switch is which open lane the rival targets.
-- All candidate scores use public information. This function never mutates s.
function E.preview_rival_target(s)
 if s.mode~='C' then return nil end
 local mode=s.rival_target_mode or 'reactive'
 local best,best_score
 local candidates={}
 for id,l in ipairs(s.lanes) do
  if not l.owner then
   local priority=({3,2,1})[id]
   local score=priority
   if mode=='reactive' then score=score+l.rival*5+l.player*2 end
   candidates[#candidates+1]={lane=id,score=score,player=l.player,
     rival=l.rival,priority=priority}
   if not best or score>best_score then best=id;best_score=score end
  end
 end
 if not best then return nil end
 local marks=s.round%3==0 and 2 or 1
 return {target=best,name=s.lanes[best].name,mode=mode,score=best_score,
  marks=marks,candidates=candidates,
  rule=mode=='reactive' and '5×sigilli Rivale + 2×sigilli Incisore + priorità'
    or 'priorità fissa 3,2,1 (solo categorie aperte)'}
end
local function rival_c_action(s)
 if active_lanes(s)==0 then return end
 local decision=E.preview_rival_target(s)
 if not decision then return end
 local target,marks=decision.target,decision.marks
 c_seal(s,'rival',target,marks)
 -- Diagnostic only; the existing event sequence and descriptions stay unchanged.
 s.last_rival_decision=decision
 log(s,'rival_claim',target..':'..marks)
end
function E.new(mode,seed,opts)
 assert(mode=='A' or mode=='C','unknown encounter prototype')
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and seed<2147483647,'invalid seed')
 opts=opts or {}
 assert(type(opts)=='table','invalid Encounter options')
 local target_mode=opts.rival_target_mode or 'reactive'
 assert(target_mode=='reactive' or target_mode=='fixed','invalid EX-002 rival mode')
 assert(mode=='C' or target_mode=='reactive','EX-002 applies only to C')
 local s={mode=mode,seed=seed,round=1,max_rounds=mode=='A' and 5 or 6,
  rival_target_mode=target_mode,
  lanes={},phase='dice',turn=Rules.new('control'),random=RNG.new_rng(seed),
  banked=0,busts=0,events={},winner=nil,
  offered_marks=0,pair=1,left=1,
  last='Tira i sei D6; accantona e decidi quando incassare.'}
 for _,name in ipairs(E.LANES) do
  s.lanes[#s.lanes+1]={name=name,player=0,rival=0,owner=nil}
 end
 return s
end
function E.can_roll(s) return s.phase=='dice' and Rules.can_roll(s.turn) end
function E.roll(s)
 if not E.can_roll(s) then return false end
 assert(Rules.start(s.turn))
 local faces={}
 for _,id in ipairs(s.turn.active) do faces[id]=s.random(1,6) end
 assert(Rules.settle(s.turn,faces))
 log(s,'roll',table.concat((function()
  local values={};for _,id in ipairs(s.turn.active) do values[#values+1]=faces[id] end
  return values
 end)(),','))
 if s.turn.phase~='ready' then
  s.busts=s.busts+1
  log(s,'farkle','provisional score lost')
  if s.mode=='A' then
   local target=rival_spare(s);s.lanes[target].rival=s.lanes[target].rival+1
   log(s,'rival_spare',target..':1')
  else rival_c_action(s) end
  end_round(s,'Farkle: provvisorio perso. Il rivale avanza.')
 else
  s.last='Scegli una combinazione; incassa o accantona per rilanciare.'
 end
 return true
end
function E.toggle(s,id)
 if s.phase~='dice' then return false end
 return Rules.toggle(s.turn,id)
end
function E.take(s)
 if s.phase~='dice' then return false end
 return Rules.take(s.turn)
end
function E.can_bank(s)
 if s.phase~='dice' then return false end
 return Rules.bank_status(s.turn)
end
function E.bank(s)
 if not E.can_bank(s) then return false end
 local points=s.turn.pot+(Rules.selection(s.turn) or 0)
 assert(Rules.bank_turn(s.turn))
 s.banked=s.banked+points
 log(s,'bank',points)
 if s.mode=='A' then
  -- Open brackets, experimental, not a conversion into enemy damage.
  s.offered_marks=math.min(5,2+math.floor(points/50))
  s.pair=1;s.left=math.floor(s.offered_marks/2)
  s.phase='offer'
  s.last='Dividi i sigilli fra due prove. Il rivale sceglie per primo.'
 else
  s.claim_marks=points<40 and 1 or points<90 and 2 or 3
  s.phase='claim'
  s.last='Scegli una prova sulla quale incidere i tuoi sigilli.'
 end
 return true
end
function E.pair_next(s)
 if s.mode~='A' or s.phase~='offer' then return false end
 s.pair=s.pair%#E.PAIRS+1
 return true
end
function E.split(s,delta)
 if s.mode~='A' or s.phase~='offer' or (delta~=1 and delta~=-1) then return false end
 local amount=s.left+delta
 if amount<1 or amount>=s.offered_marks then return false end
 s.left=amount
 return true
end
-- Public preview: the rival always chooses the better offer according
-- to visible priorities. The proposer receives +1 fixed initiative seal
-- for surrendering the first pick. Not a comeback or skill-based modifier.
function E.preview_offer(s,pair_id,left)
 if s.mode~='A' or s.phase~='offer' then return nil end
 pair_id=pair_id or s.pair;left=left or s.left
 local pair=E.PAIRS[pair_id]
 if not pair or left<1 or left>=s.offered_marks then return nil end
 local right=s.offered_marks-left
 local first=offer_utility(s,pair[1],left)
 local second=offer_utility(s,pair[2],right)
 local chosen=first>=second and 1 or 2
 return {rival_id=pair[chosen],player_id=pair[3-chosen],
  rival_marks=chosen==1 and left or right,
  player_marks=(chosen==1 and right or left)+1,
  base_player_marks=chosen==1 and right or left}
end
function E.resolve_offer(s)
 local preview=E.preview_offer(s)
 if not preview then return false end
 local r,p=preview.rival_id,preview.player_id
 s.lanes[r].rival=s.lanes[r].rival+preview.rival_marks
 s.lanes[p].player=s.lanes[p].player+preview.player_marks
 local pair=E.PAIRS[s.pair]
 log(s,'offer',('pair=%d,%d; split=%d,%d; rival=%d; player=%d; initiative=1'):format(
  pair[1],pair[2],s.left,s.offered_marks-s.left,r,p))
 end_round(s,('Il rivale sceglie %s (+%d); tu %s (+%d, inclusa iniziativa).'):format(
  s.lanes[r].name,preview.rival_marks,s.lanes[p].name,preview.player_marks))
 return true
end

function E.claim(s,lane_id)
 if s.mode~='C' or s.phase~='claim' or type(lane_id)~='number' or
   lane_id%1~=0 or lane_id<1 or lane_id>3 or s.lanes[lane_id].owner then return false end
 s.last_rival_decision=nil
 assert(c_seal(s,'player',lane_id,s.claim_marks))
 log(s,'player_claim',lane_id..':'..s.claim_marks)
 local owned=owner_counts(s)
 if owned.player<2 then rival_c_action(s) end
 end_round(s,('Hai destinato %d sigilli a %s.'):format(
  s.claim_marks,s.lanes[lane_id].name))
 return true
end
function E.next_round(s)
 if s.phase~='round_end' then return false end
 s.round=s.round+1
 s.turn=Rules.new('control')
 s.last_rival_decision=nil
 s.phase='dice'
 s.last='Nuova prova: incassa o rischia con i dadi.'
 return true
end
function E.summary(s)
 local counts={player=0,rival=0,neutral=0}
 for _,lane in ipairs(s.lanes) do
  local owner=lane.owner or (lane.player>lane.rival and 'player' or
    lane.rival>lane.player and 'rival' or 'neutral')
  counts[owner]=counts[owner]+1
 end
 local all=totals(s)
 return {winner=s.winner or result_for(s),control=counts,
  seals=all,banked=s.banked,busts=s.busts,rounds=s.round}
end
return E
