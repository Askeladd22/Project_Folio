-- One isolated "Il Mercante e la posta" match. Pure Lua, seeded, no LÖVE.
-- Player turns run the production Farkle rules unchanged through
-- Rules.new('control'): first-commission thresholds are zero, and each turn
-- gets a fresh state, so commission targets and limits never apply here.
local Rules=require('src.farkle.rules')
local Defaults=require('experiments.merchant_wager_lab.config')
local Merchant=require('experiments.merchant_wager_lab.merchant')
local M={}

-- Park-Miller minimal standard generator: identical sequence in Lua 5.1/5.4/LuaJIT.
function M.new_rng(seed)
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and seed<2147483647,'seed must be integer 1..2147483646')
 local value=seed
 return function(min,max)
  value=(value*16807)%2147483647
  return math.min(min+math.floor(value/2147483647*(max-min+1)),max)
 end
end

local function settings(overrides,variant)
 local c={};for k,v in pairs(Defaults) do c[k]=v end
 for k,v in pairs(overrides or {}) do
  assert(Defaults[k]~=nil and k~='variants' and k~='seeds','unknown setting '..tostring(k))
  c[k]=v
 end
 variant=variant or 'A'
 local v=assert(Defaults.variants[variant],'unknown variant '..tostring(variant))
 c.variant=variant;c.variant_label=v.label
 c.initial_player_score=v.player_start;c.initial_merchant_score=v.merchant_start
 c.opening_stake=v.opening_stake
 assert(c.opening_stake>=1 and c.starting_sheets>=c.opening_stake,'invalid sheets')
 assert(c.merchant_dice>=1 and c.merchant_dice<=6,'merchant dice must be 1..6')
 return c
end

local function free_dice(t) return t.hot and 6 or Rules.count_free(t) end
local function selected_count(t) local n=0;for _ in pairs(t.selected) do n=n+1 end;return n end
local function hand_text(t,ids)
 local out={};for _,i in ipairs(ids) do out[#out+1]=t.hand[i] end;return table.concat(out,' ')
end

local function log(m,actor,action,provisional,available,faces,detail)
 m.decisions[#m.decisions+1]={round=m.round,actor=actor,action=action,
  provisional=provisional or 0,available=available or 0,faces=faces or '',detail=detail or '',
  player_score=m.score.player,merchant_score=m.score.merchant,pot=m.pot,
  player_sheets=m.reserve.player,merchant_sheets=m.reserve.merchant}
 m.last_event=actor..': '..action..(detail and detail~='' and (' ('..detail..')') or '')
end

local function decision(m,action,provisional,available)
 local player=m.score.player
 local merchant=m.score.merchant
 local d={round=m.round,player_score=player,merchant_score=merchant,
  score_diff=merchant-player,provisional=provisional or 0,
  dice_available=available or 0,action=action,roll_outcome=''}
 m.player_decisions[#m.player_decisions+1]=d
 return d
end

local function deposit(m,who,n)
 assert(m.reserve[who]>=n,'not enough sheets')
 m.reserve[who]=m.reserve[who]-n;m.deposited[who]=m.deposited[who]+n
 m.pot=m.pot+n;m.max_pot=math.max(m.max_pot,m.pot)
end

function M.new(seed,variant_or_overrides,overrides)
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and seed<2147483647,
  'seed must be integer 1..2147483646')
 local variant,custom
 if type(variant_or_overrides)=='string' then variant=variant_or_overrides;custom=overrides
 else variant='A';custom=variant_or_overrides end
 local c=settings(custom,variant)
 local merchant_seed=1+((seed*48271)%2147483646)
 local player_rng=M.new_rng(seed)
 local m={seed=seed,config=c,random=player_rng,random_player=player_rng,
  random_merchant=M.new_rng(merchant_seed),round=1,rounds_played=0,phase='player',
  score={player=c.initial_player_score,merchant=c.initial_merchant_score},
  reserve={player=c.starting_sheets,merchant=c.starting_sheets},
  deposited={player=0,merchant=0},pot=0,max_pot=0,decisions={},
  player_decisions={},
  merchant_last=nil,merchant_action='In attesa del primo turno.',
  stats={raises=0,accepted=0,declined=0,player_farkles=0,player_rolls=0,player_rerolls=0,
   merchant_farkles=0,merchant_rerolls=0,raise_blocked_end=0,raise_blocked_sheets=0}}
 deposit(m,'player',c.opening_stake);deposit(m,'merchant',c.opening_stake)
 m.turn=Rules.new('control')
 m.initial_pot=m.pot
 log(m,'table','open',0,0,'',variant..': each contender stakes '..c.opening_stake)
 return m
end

function M.total_sheets(m) return m.reserve.player+m.reserve.merchant+m.pot end

-- Commands available in the current state; the UI disables everything else.
function M.can_roll(m) return m.phase=='player' and Rules.can_roll(m.turn) end
function M.can_toggle(m,i) local t=m.turn;return m.phase=='player' and t.phase=='ready' and t.hand[i]~=nil and not t.used[i] end
function M.can_take(m) return m.phase=='player' and Rules.selection(m.turn)~=nil end
function M.can_bank(m) if m.phase~='player' then return false end;local ok=Rules.bank_status(m.turn);return ok end
function M.can_see(m) return m.phase=='raise' and m.reserve.player>=m.config.raise_sheets end
function M.can_pass(m) return m.phase=='raise' end
function M.selection_points(m) return m.phase=='player' and Rules.selection(m.turn) or nil end

local function end_player_turn(m) m.phase='merchant' end

local function finish(m,reason)
 local winner
 if reason=='pass' then winner='merchant'
 elseif m.score.player>m.score.merchant then winner='player'
 elseif m.score.merchant>m.score.player then winner='merchant'
 else winner='tie' end
 m.pot_at_end=m.pot
 if winner=='tie' then
  -- No tie-break: each contender takes back exactly what it staked.
  m.reserve.player=m.reserve.player+m.deposited.player
  m.reserve.merchant=m.reserve.merchant+m.deposited.merchant
 else m.reserve[winner]=m.reserve[winner]+m.pot end
 m.pot=0;m.phase='over';m.winner=winner;m.end_reason=reason
 log(m,'table','end',0,0,'',reason..', winner '..winner..', pot '..m.pot_at_end)
end

local function next_round(m)
 m.round=m.round+1;m.turn=Rules.new('control');m.phase='player'
end

function M.toggle(m,i)
 if not M.can_toggle(m,i) then return false end
 return Rules.toggle(m.turn,i)
end

function M.roll(m)
 if not M.can_roll(m) then return false end
 local t=m.turn;local reroll=t.phase=='ready';local provisional=t.pot
 assert(Rules.start(t),'production rules refused a legal roll')
 local available=#t.active
 local choice=decision(m,reroll and 'rilancia' or 'lancia',provisional,available)
 local faces={};for _,i in ipairs(t.active) do faces[i]=m.random_player(1,6) end
 m.stats.player_rolls=m.stats.player_rolls+1
 if reroll then m.stats.player_rerolls=m.stats.player_rerolls+1 end
 assert(Rules.settle(t,faces),'production rules refused virtual dice')
 local shown={};for _,i in ipairs(t.active) do shown[#shown+1]=faces[i] end
 local outcome
 if t.phase~='ready' then outcome='Farkle: '..table.concat(shown,' ')
 else
  local best=0
  for _,o in ipairs(Rules.options(t)) do if o.points>best then best=o.points end end
  outcome='valido +'..best..': '..table.concat(shown,' ')
 end
 choice.roll_outcome=outcome
 log(m,'player',reroll and 'reroll' or 'roll',provisional,available,hand_text(t,t.active))
 if t.phase~='ready' then
  m.stats.player_farkles=m.stats.player_farkles+1
  log(m,'player','farkle',provisional,available,hand_text(t,t.active),'provisional '..provisional..' lost')
  end_player_turn(m)
 end
 return true
end

function M.take(m)
 if not M.can_take(m) then return false end
 local points=Rules.selection(m.turn)
 local selected=selected_count(m.turn)
 decision(m,'accantona',m.turn.pot+points,Rules.count_free(m.turn)-selected)
 assert(Rules.take(m.turn))
 log(m,'player','set_aside',m.turn.pot,free_dice(m.turn),'','+'..points)
 return true
end

function M.bank(m)
 if not M.can_bank(m) then return false end
 local t=m.turn;local before=t.bank
 local points=Rules.selection(t)
 if points then
  local selected=selected_count(t)
  decision(m,'accantona',t.pot+points,Rules.count_free(t)-selected)
 end
 decision(m,'incassa',t.pot+(points or 0),Rules.count_free(t)-(points and selected_count(t) or 0))
 assert(Rules.bank_turn(t),'production rules refused a legal bank')
 local gained=t.bank-before
 m.score.player=m.score.player+gained
 log(m,'player','bank',gained,free_dice(t),'','+'..gained)
 end_player_turn(m)
 return true
end

function M.play_merchant(m)
 if m.phase~='merchant' then return false end
 local c=m.config;local r=Merchant.play(m.random_merchant,c)
 m.merchant_last=r
 for _,s in ipairs(r.steps) do
  log(m,'merchant',(s.reroll and 'reroll_' or 'roll_')..s.action,s.provisional,s.available,table.concat(s.faces,' '),s.detail)
 end
 m.stats.merchant_rerolls=m.stats.merchant_rerolls+r.rerolls
 if r.farkle then
  m.stats.merchant_farkles=m.stats.merchant_farkles+1
  m.merchant_action='Farkle: perde '..r.lost..' punti provvisori.'
 else
  m.score.merchant=m.score.merchant+r.banked
  log(m,'merchant','bank',r.banked,0,'','+'..r.banked)
  m.merchant_action='Incassa '..r.banked..' punti.'
 end
 m.rounds_played=m.round
 local p,mm=m.score.player,m.score.merchant
 local threshold=p>=c.win_threshold or mm>=c.win_threshold
 local ends=threshold or m.round>=c.max_rounds
 local wants=not r.farkle and r.banked>=c.raise_threshold
 if wants and ends then
  m.stats.raise_blocked_end=m.stats.raise_blocked_end+1
  log(m,'merchant','raise_blocked','',0,'','match ends after this round')
  m.merchant_action=m.merchant_action..' Vorrebbe alzare, ma l\'incontro finisce.'
 end
 if ends then finish(m,threshold and 'threshold' or 'max_rounds');return true end
 if wants and m.reserve.merchant>=c.raise_sheets and m.reserve.player>=c.raise_sheets then
  deposit(m,'merchant',c.raise_sheets)
  m.stats.raises=m.stats.raises+1;m.phase='raise'
  log(m,'merchant','raise',r.banked,0,'','adds '..c.raise_sheets..' sheet')
  m.merchant_action=m.merchant_action..' «Alzo»: aggiunge un foglio al piatto.'
  return true
 end
 if wants then
  m.stats.raise_blocked_sheets=m.stats.raise_blocked_sheets+1
  log(m,'merchant','raise_blocked','',0,'','not enough sheets')
 end
 if not r.farkle then
  log(m,'merchant','hold',r.banked,0,'','stake unchanged')
  if not wants then m.merchant_action=m.merchant_action..' «Tengo».' end
 end
 next_round(m)
 return true
end

function M.see(m)
 if not M.can_see(m) then return false end
 decision(m,'vede',0,0)
 deposit(m,'player',m.config.raise_sheets)
 m.stats.accepted=m.stats.accepted+1
 log(m,'player','see',0,0,'','adds '..m.config.raise_sheets..' sheet')
 next_round(m);return true
end

function M.pass(m)
 if not M.can_pass(m) then return false end
 decision(m,'passa',0,0)
 m.stats.declined=m.stats.declined+1
 log(m,'player','pass',0,0,'','Merchant takes the pot')
 finish(m,'pass');return true
end

-- Summary row for the playtest CSV.
function M.record(m,id)
 assert(m.phase=='over','record only completed matches')
 local s=m.stats
 return {id=id,variant=m.config.variant,seed=m.seed,
  merchant_initial_score=m.config.initial_merchant_score,initial_pot=m.initial_pot,
  rounds=m.rounds_played,player_score=m.score.player,
  merchant_score=m.score.merchant,winner=m.winner,end_reason=m.end_reason,
  raises=s.raises,accepted=s.accepted,declined=s.declined,
  player_farkles=s.player_farkles,player_rerolls=s.player_rerolls,
  merchant_farkles=s.merchant_farkles,raise_blocked_end=s.raise_blocked_end,
  player_sheets=m.reserve.player,merchant_sheets=m.reserve.merchant,max_pot=m.max_pot,
  player_initial_score=m.config.initial_player_score}
end
return M
