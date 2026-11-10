-- EX-TP-001 (research-only). Canonical Farkle imported in read-only mode.
-- Experimental three contested proofs, public finite rival reserve. No src/UI changes.
local Rules=require('src.farkle.rules')
local M={NAMES={'Capilettera','Miniatura','Marca'}, TARGET=4, MAX_ROUNDS=5}
local MOD=2147483647

local function rng(seed)
  assert(type(seed)=='number' and seed%1==0 and seed>=1 and seed<MOD)
  local x=seed
  return function(low,high)
    x=(x*16807)%MOD
    return low+math.floor(x/MOD*(high-low+1))
  end
end
M.rng=rng
function M.round_seed(seed,round)
  return 1+((seed*48271+round*69621+1277)%(MOD-1))
end
local function valid_int(n,a,b)
  return type(n)=='number' and n%1==0 and n>=a and n<=b
end
local function log(s,action,lane,amount)
  s.events[#s.events+1]={round=s.round,action=action,lane=lane,amount=amount}
end
function M.owners(s)
  local p,r=0,0
  for _,l in ipairs(s.lanes) do
    if l.owner=='player' then p=p+1
    elseif l.owner=='rival' then r=r+1 end
  end
  return p,r
end
function M.result(s)
  local p,r=0,0
  for _,l in ipairs(s.lanes) do
    local owner=l.owner
    if not owner then
      if l.player>l.rival then owner='player'
      elseif l.rival>l.player then owner='rival' end
    end
    if owner=='player' then p=p+1 elseif owner=='rival' then r=r+1 end
  end
  if p>r then return 'player' elseif r>p then return 'rival' end
  return 'draw'
end
function M.new(seed,reserve,cap)
  assert(valid_int(seed,1,MOD-1),'invalid seed')
  assert(valid_int(reserve,0,10),'reserve outside laboratory range')
  assert(valid_int(cap,1,2),'cap outside laboratory range')
  local s={seed=seed,initial_reserve=reserve,reserve=reserve,cap=cap,
    round=1,phase='dice',winner=nil,turn=Rules.new('control'),
    dice_rng=rng(M.round_seed(seed,1)),lanes={},events={},
    marks=nil,last_player_lane=nil,last_rival_lane=nil,
    metrics={rolls=0,busts=0,banks=0,hot=0,rival_actions=0,
      eligible=0,eligible_spend=0,eligible_pass=0,spent=0,
      lane_switches=0,voluntary_switches=0,bait_patterns=0}}
  for i,name in ipairs(M.NAMES) do
    s.lanes[i]={name=name,player=0,rival=0,owner=nil}
  end
  return s
end
function M.place(s,actor,id,amount)
  if actor~='player' and actor~='rival' then return false end
  if not valid_int(id,1,3) or not valid_int(amount,1,3) then return false end
  local l=s.lanes[id]
  if l.owner then return false end
  if actor=='rival' and amount>s.cap then return false end
  l[actor]=math.min(M.TARGET,l[actor]+amount)
  if l[actor]==M.TARGET then l.owner=actor;log(s,'close_'..actor,id,amount) end
  return true
end
local function resolve_round(s)
  local p,r=M.owners(s)
  if p>=2 or r>=2 then
    s.phase='finished';s.winner=p>=2 and 'player' or 'rival'
  elseif s.round>=M.MAX_ROUNDS then
    s.phase='finished';s.winner=M.result(s)
  else s.phase='round_end' end
  if s.phase=='finished' then log(s,'finish',0,0) end
end
function M.can_roll(s)
  return s.phase=='dice' and Rules.can_roll(s.turn)
end
-- forced_faces is an indexed physical-die fixture, accepted only by test callers.
function M.roll(s,forced_faces)
  if not M.can_roll(s) then return false end
  assert(Rules.start(s.turn))
  local faces={}
  for _,id in ipairs(s.turn.active) do
    local v=forced_faces and forced_faces[id] or s.dice_rng(1,6)
    assert(valid_int(v,1,6),'bad physical die '..id)
    faces[id]=v
  end
  assert(Rules.settle(s.turn,faces))
  s.metrics.rolls=s.metrics.rolls+1
  log(s,'roll',nil,s.turn.pot)
  if s.turn.phase~='ready' then
    assert(s.turn.phase=='ended','unexpected canonical turn state')
    s.metrics.busts=s.metrics.busts+1
    s.phase='rival'
    log(s,'farkle',nil,0)
  end
  return true
end
function M.take(s,mask)
  if s.phase~='dice' or s.turn.phase~='ready' or s.turn.scored then return false end
  if not valid_int(mask,1,63) then return false end
  local choice=nil
  for _,o in ipairs(Rules.options(s.turn)) do
    if o.mask==mask then choice=o;break end
  end
  if not choice then return false end
  for _,id in ipairs(choice.ids) do assert(Rules.toggle(s.turn,id)) end
  assert(Rules.take(s.turn))
  if s.turn.hot then s.metrics.hot=s.metrics.hot+1 end
  log(s,'take',nil,choice.points)
  return true
end
function M.can_bank(s)
  if s.phase~='dice' then return false end
  return Rules.bank_status(s.turn)
end
function M.bank(s)
  if not M.can_bank(s) then return false end
  local points=s.turn.pot+(Rules.selection(s.turn) or 0)
  assert(Rules.bank_turn(s.turn))
  s.marks=points<40 and 1 or points<90 and 2 or 3
  s.phase='claim';s.metrics.banks=s.metrics.banks+1
  log(s,'bank',nil,points)
  return true
end
local function rival_score(s,policy,id,amount)
  local l=s.lanes[id]
  local close=(l.rival+amount>=M.TARGET) and 1 or 0
  local scarcity=1/(s.reserve+1)
  if policy=='aggressive' then
    return 14*close+4*amount+2*l.rival+1.8*l.player-0.1*amount
  elseif policy=='conserve' then
    return 20*close+3*l.player+1.5*l.rival+1.0*amount-9*amount+\n      (l.player>=3 and 12 or 0)
  elseif policy=='balanced' then
    return 16*close+3*amount+1.2*l.player+0.8*l.rival-
      amount*(3.8+12*scarcity+0.3*(M.MAX_ROUNDS-s.round))
  end
  error('unknown rival policy '..tostring(policy))
end
-- Pure, public rival policy: evaluates PASS (utility 0) against legal spend.
function M.rival_move(s,policy)
  assert(policy=='aggressive' or policy=='conserve' or policy=='balanced')
  local best={lane=nil,amount=0,score=0}
  if s.reserve<=0 then return best end
  for id,l in ipairs(s.lanes) do
    if not l.owner then
      for amount=1,math.min(s.cap,s.reserve,M.TARGET-l.rival) do
        local value=rival_score(s,policy,id,amount)
        if value>best.score+1e-8 then
          best={lane=id,amount=amount,score=value}
        end
      end
    end
  end
  return best
end
function M.rival(s,policy)
  if s.phase~='rival' then return false end
  s.metrics.rival_actions=s.metrics.rival_actions+1
  local eligible=s.reserve>0
  local move=M.rival_move(s,policy)
  if eligible then s.metrics.eligible=s.metrics.eligible+1 end
  if move.amount>0 then
    assert(move.amount<=s.reserve and move.amount<=s.cap)
    assert(M.place(s,'rival',move.lane,move.amount))
    s.reserve=s.reserve-move.amount
    s.metrics.spent=s.metrics.spent+move.amount
    if eligible then s.metrics.eligible_spend=s.metrics.eligible_spend+1 end
    s.last_rival_lane=move.lane
    log(s,'rival_spend',move.lane,move.amount)
  else
    if eligible then s.metrics.eligible_pass=s.metrics.eligible_pass+1 end
    s.last_rival_lane=nil
    log(s,'rival_pass',nil,0)
  end
  resolve_round(s)
  return true
end
function M.claim(s,id)
  if s.phase~='claim' or not valid_int(id,1,3) or s.lanes[id].owner then return false end
  local previous=s.last_player_lane
  if previous and previous~=id then
    s.metrics.lane_switches=s.metrics.lane_switches+1
    if not s.lanes[previous].owner then
      s.metrics.voluntary_switches=s.metrics.voluntary_switches+1
      if s.last_rival_lane==previous then
        s.metrics.bait_patterns=s.metrics.bait_patterns+1
      end
    end
  end
  assert(M.place(s,'player',id,s.marks))
  s.last_player_lane=id
  log(s,'player_claim',id,s.marks)
  s.marks=nil
  local p=M.owners(s)
  if p>=2 then resolve_round(s)
  else s.phase='rival' end
  return true
end
function M.next_round(s)
  if s.phase~='round_end' then return false end
  s.round=s.round+1
  assert(s.round<=M.MAX_ROUNDS)
  s.turn=Rules.new('control')
  s.dice_rng=rng(M.round_seed(s.seed,s.round))
  s.phase='dice' -- retain previous rival response for next-round bait diagnostic
  return true
end
return M
