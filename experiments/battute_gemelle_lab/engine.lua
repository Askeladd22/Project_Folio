-- RQ-001 / EX-BG-001. Isolated headless duel; canonical scoring is never copied.
-- Run from repository root. No LÖVE, UI, HP, money or changes to src/.
local Rules = require('src.farkle.rules')
local M = { MAX_ROLLS = 3, WIN_HANDS = 2 }
local MOD = 2147483647

local function valid_seed(seed)
  return type(seed)=='number' and seed%1==0 and seed>=1 and seed<MOD
end
local function rng(seed)
  assert(valid_seed(seed), 'invalid RNG seed')
  local value=seed
  return function(low,high)
    value=(value*16807)%MOD
    return low+math.floor(value/MOD*(high-low+1))
  end
end
local function stream_seed(seed,hand,side)
  local side_id=side=='player' and 1 or 2
  return 1+((seed*48271+hand*69621+side_id*1277)%(MOD-1))
end
local function other(side) return side=='player' and 'rival' or 'player' end
local function log(s,kind,side,detail)
  s.events[#s.events+1]={hand=s.hand,kind=kind,side=side,detail=detail}
end
local function begin_hand(s)
  s.phase='turn'
  s.active=s.leader
  s.target=nil
  s.limit=M.MAX_ROLLS
  s.actors={}
  for _,side in ipairs({'player','rival'}) do
    s.actors[side]={turn=Rules.new('control'),rolls=0,
      random=rng(stream_seed(s.seed,s.hand,side))}
  end
  log(s,'begin',s.leader,'leader')
end
local function finish_hand(s,winner,reason)
  assert(s.phase=='turn' and (winner=='player' or winner=='rival'))
  local leader=s.leader
  local follower=other(leader)
  local a,b=s.actors[leader],s.actors[follower]
  s.wins[winner]=s.wins[winner]+1
  s.history[#s.history+1]={
    number=s.hand,leader=leader,winner=winner,reason=reason,
    leader_rolls=a.rolls,follower_rolls=b.rolls,
    target=s.target,leader_score=a.turn.pot,follower_score=b.turn.pot,
    limit=s.limit
  }
  log(s,'finish',winner,reason)
  if s.wins[winner]>=M.WIN_HANDS or s.hand>=3 then
    s.phase='finished'
    s.winner=winner
  else s.phase='hand_end' end
end
function M.new(seed,first_leader)
  assert(valid_seed(seed),'seed must be 1..2147483646')
  first_leader=first_leader or 'player'
  assert(first_leader=='player' or first_leader=='rival')
  local s={seed=seed,hand=1,leader=first_leader,
    wins={player=0,rival=0},history={},events={},
    metrics={rolls=0,busts=0,hot=0,choices=0}}
  begin_hand(s)
  return s
end
function M.can_roll(s)
  if s.phase~='turn' then return false end
  local a=s.actors[s.active]
  return a.rolls<s.limit and Rules.can_roll(a.turn)
end
-- forced_faces is for deterministic tests only, indexed by physical die ID.
function M.roll(s,forced_faces)
  if not M.can_roll(s) then return false end
  local side=s.active
  local a=s.actors[side]
  assert(Rules.start(a.turn))
  local faces={}
  for _,id in ipairs(a.turn.active) do
    local face=forced_faces and forced_faces[id] or a.random(1,6)
    if type(face)~='number' or face%1~=0 or face<1 or face>6 then
      error('invalid die face for physical ID '..id)
    end
    faces[id]=face
  end
  assert(Rules.settle(a.turn,faces))
  a.rolls=a.rolls+1
  s.metrics.rolls=s.metrics.rolls+1
  log(s,'roll',side,a.rolls)
  if a.turn.phase~='ready' then
    assert(a.turn.phase=='ended','unexpected canonical Farkle phase')
    s.metrics.busts=s.metrics.busts+1
    finish_hand(s,other(side),'farkle')
  end
  return true
end
function M.bank(s)
  if s.phase~='turn' then return false end
  local side=s.active
  local a=s.actors[side]
  if a.turn.phase~='ready' or not a.turn.scored or
      next(a.turn.selected)~=nil or a.turn.pot<=0 then return false end
  if side==s.leader then
    s.target=a.turn.pot
    s.limit=a.rolls
    s.active=other(side)
    log(s,'leader_bank',side,s.target)
  else
    local won=a.turn.pot>s.target
    finish_hand(s,won and side or s.leader,
      won and 'exceeded' or (a.turn.pot==s.target and 'tie' or 'short'))
  end
  return true
end
function M.take(s,mask)
  if s.phase~='turn' or type(mask)~='number' or mask%1~=0 then return false end
  local a=s.actors[s.active]
  if a.turn.phase~='ready' or a.turn.scored then return false end
  local chosen
  for _,o in ipairs(Rules.options(a.turn)) do
    if o.mask==mask then chosen=o;break end
  end
  if not chosen then return false end
  for _,id in ipairs(chosen.ids) do assert(Rules.toggle(a.turn,id)) end
  assert(Rules.take(a.turn))
  s.metrics.choices=s.metrics.choices+1
  if a.turn.hot then s.metrics.hot=s.metrics.hot+1 end
  log(s,'take',s.active,chosen.points)
  -- No strategically meaningless extra roll after already beating the target.
  if s.active~=s.leader and a.turn.pot>s.target then
    assert(M.bank(s))
  elseif a.rolls>=s.limit then
    assert(M.bank(s))
  end
  return true
end
function M.next_hand(s)
  if s.phase~='hand_end' then return false end
  s.hand=s.hand+1
  s.leader=other(s.leader)
  begin_hand(s)
  return true
end
M.rng=rng
M.stream_seed=stream_seed
return M
