-- RQ-001 / EX-BG-001: reproducible scripted diagnostics, NOT human skill.
local E=require('experiments.battute_gemelle_lab.engine')
local Rules=require('src.farkle.rules')
local S={}
S.player_policies={'prudent','aggressive','random_legal','informed','informed_blind'}
S.rival_policies={'prudent','aggressive'}
local MOD=2147483647
local DEAD_BAND=0.10 -- preregistered Monte Carlo uncertainty guard, not a p-value

local function copy(t)
  local r={}
  for k,v in pairs(t) do r[k]=v end
  return r
end
local function clone_turn(t)
  local r=Rules.new('control')
  r.phase=t.phase;r.pot=t.pot;r.used=copy(t.used)
  r.hand=copy(t.hand);r.selected=copy(t.selected)
  r.hot=t.hot;r.scored=t.scored
  r.turnGroup=t.turnGroup;r.turnHot=t.turnHot
  return r
end
local function pick_option(t,policy,role,target,rolls,limit,random)
  local options=Rules.options(t)
  assert(#options>0,'canonical ready state has no scoring options')
  if policy=='random_legal' then return options[random(1,#options)] end
  local best,score
  for _,o in ipairs(options) do
    local remaining=Rules.count_free(t)-#o.ids
    if remaining==0 then remaining=6 end -- hot dice reset
    local value=o.points
    if rolls<limit and (policy=='aggressive' or
       policy=='informed' or policy=='informed_blind') then
      value=value+remaining*(policy=='aggressive' and 9 or 6)
    end
    if role=='follower' and t.pot+o.points>target then
      value=value+100000 -- win immediately; never continue pointlessly
    end
    if not best or value>score or (value==score and o.mask<best.mask) then
      best=o;score=value
    end
  end
  return best
end
local function should_bank_leader(s,policy,rival_policy,random)
  local a=s.actors[s.active]
  local t=a.turn
  if policy=='random_legal' then return random(1,2)==1 end
  local free=Rules.count_free(t)
  if t.hot then free=6 end
  local threshold
  if policy=='prudent' then threshold=40
  elseif policy=='aggressive' then threshold=120
  elseif policy=='informed' then
    threshold=rival_policy=='aggressive' and 85 or 60
  elseif policy=='informed_blind' then threshold=70
  else error('unknown policy '..tostring(policy)) end
  return t.pot>=threshold or (free<=1 and t.pot>=30)
end
function S.play(seed,player_policy,rival_policy,first_leader)
  assert(type(seed)=='number' and seed>=1 and seed%1==0 and seed<MOD)
  assert(player_policy=='prudent' or player_policy=='aggressive' or
    player_policy=='random_legal' or player_policy=='informed' or
    player_policy=='informed_blind')
  assert(rival_policy=='prudent' or rival_policy=='aggressive')
  local s=E.new(seed,first_leader or (seed%2==0 and 'player' or 'rival'))
  local decision_random={
    player=E.rng(E.stream_seed(seed,7,'player')),
    rival=E.rng(E.stream_seed(seed,7,'rival'))
  }
  local steps=0
  while s.phase~='finished' do
    steps=steps+1
    assert(steps<100,'scripted match exceeded step budget')
    if s.phase=='hand_end' then
      assert(E.next_hand(s))
    else
      local side=s.active
      local a=s.actors[side]
      local policy=side=='player' and player_policy or rival_policy
      local random=decision_random[side]
      if a.turn.phase=='fresh' then
        assert(E.roll(s))
      elseif a.turn.phase=='ready' and not a.turn.scored then
        local role=side==s.leader and 'leader' or 'follower'
        local option=pick_option(a.turn,policy,role,s.target,a.rolls,s.limit,random)
        assert(E.take(s,option.mask))
      elseif a.turn.phase=='ready' and a.turn.scored then
        if side==s.leader and
            should_bank_leader(s,policy,
              side=='player' and rival_policy or player_policy,random) then
          assert(E.bank(s))
        else assert(E.roll(s)) end
      else error('unexpected canonical phase '..tostring(a.turn.phase)) end
    end
  end
  assert(s.wins.player+s.wins.rival==#s.history)
  assert(#s.history>=2 and #s.history<=3)
  for _,h in ipairs(s.history) do
    assert(h.leader_rolls>=1 and h.leader_rolls<=E.MAX_ROLLS)
    assert(h.follower_rolls<=h.leader_rolls)
    if h.reason=='tie' then assert(h.winner==h.leader) end
  end
  return s
end
local function wilson(w,n)
  local z=1.959963984540054
  local p=w/n
  local d=1+z*z/n
  local c=(p+z*z/(2*n))/d
  local h=z*math.sqrt((p*(1-p)+z*z/(4*n))/n)/d
  return c-h,c+h
end
local function csv(...)
  local fields={...}
  for i,v in ipairs(fields) do
    local str=tostring(v)
    if str:find('[,"\r\n]') then str='"'..str:gsub('"','""')..'"' end
    fields[i]=str
  end
  return table.concat(fields,',')..'\n'
end
local function paired_delta(records,n)
  local sum,sumsq=0,0
  for _,row in pairs(records) do
    assert(row.informed~=nil and row.informed_blind~=nil)
    local d=row.informed-row.informed_blind
    sum=sum+d;sumsq=sumsq+d*d
  end
  local mean=sum/n
  local variance=n>1 and math.max(0,(sumsq-sum*sum/n)/(n-1)) or 0
  local half=1.96*math.sqrt(variance/n)
  return mean,mean-half,mean+half
end
function S.pilot(count,first,dir)
  assert(type(count)=='number' and count%1==0 and count>=1 and count<=5000)
  assert(type(first)=='number' and first%1==0 and first>=1 and
    first+count<MOD)
  local file
  if dir then
    file=assert(io.open(dir..'/bg_matches.csv','w'))
    file:write('seed,player_policy,rival_policy,first_leader,winner,hands,rolls,busts,hot,choices,leader_one,leader_two,leader_three\n')
  end
  local report={}
  local paired={prudent={},aggressive={}}
  for _,rival_policy in ipairs(S.rival_policies) do
    for _,player_policy in ipairs(S.player_policies) do
      local wins,hands,rolls,busts,hot,choices=0,0,0,0,0,0
      local k={0,0,0}
      for seed=first,first+count-1 do
        local s=S.play(seed,player_policy,rival_policy)
        local win=s.winner=='player' and 1 or 0
        wins=wins+win;hands=hands+#s.history
        rolls=rolls+s.metrics.rolls;busts=busts+s.metrics.busts
        hot=hot+s.metrics.hot;choices=choices+s.metrics.choices
        local per={0,0,0}
        for _,h in ipairs(s.history) do
          k[h.leader_rolls]=k[h.leader_rolls]+1
          per[h.leader_rolls]=per[h.leader_rolls]+1
        end
        if player_policy=='informed' or player_policy=='informed_blind' then
          local entry=paired[rival_policy][seed] or {}
          entry[player_policy]=win
          paired[rival_policy][seed]=entry
        end
        if file then file:write(csv(seed,player_policy,rival_policy,
          seed%2==0 and 'player' or 'rival',s.winner,#s.history,
          s.metrics.rolls,s.metrics.busts,s.metrics.hot,s.metrics.choices,
          per[1],per[2],per[3])) end
      end
      local lo,hi=wilson(wins,count)
      report[#report+1]=string.format(
        '%s vs %s | wins=%d/%d Wilson95=[%.3f,%.3f] | hands=%.2f | bust/hand=%.3f | leader k=1/2/3: %d/%d/%d',
        player_policy,rival_policy,wins,count,lo,hi,hands/count,
        busts/hands,k[1],k[2],k[3])
    end
    local d,lo,hi=paired_delta(paired[rival_policy],count)
    report[#report+1]=string.format(
      'informed minus blind vs %s | paired delta=%+.4f approx95=[%+.4f,%+.4f]',
      rival_policy,d,lo,hi)
  end
  if file then file:close() end
  return table.concat(report,'\n')
end

-- Same opponent die stream in STOP and CONTINUE. Different limits and scoring
-- choices can still cause divergent RNG consumption: pairing is not identity.
local function follower_beats(target,limit,policy,seed)
  local t=Rules.new('control')
  local random=E.rng(seed)
  for roll=1,limit do
    assert(Rules.start(t))
    local faces={}
    for _,id in ipairs(t.active) do faces[id]=random(1,6) end
    assert(Rules.settle(t,faces))
    if t.phase~='ready' then return false end
    local o=pick_option(t,policy,'follower',target,roll,limit,random)
    for _,id in ipairs(o.ids) do assert(Rules.toggle(t,id)) end
    assert(Rules.take(t))
    if t.pot>target then return true end
  end
  return false
end
local function one_more_score(turn,rolls,seed)
  local t=clone_turn(turn)
  assert(Rules.can_roll(t))
  assert(Rules.start(t))
  local random=E.rng(seed)
  local faces={}
  for _,id in ipairs(t.active) do faces[id]=random(1,6) end
  assert(Rules.settle(t,faces))
  if t.phase~='ready' then return nil end
  local o=pick_option(t,'prudent','leader',nil,rolls+1,E.MAX_ROLLS,random)
  for _,id in ipairs(o.ids) do assert(Rules.toggle(t,id)) end
  assert(Rules.take(t))
  return t.pot
end
function S.estimate(turn,rolls,opponent_policy,samples,seed)
  assert(rolls==1 or rolls==2)
  assert(opponent_policy=='prudent' or opponent_policy=='aggressive')
  assert(samples>=1 and samples%1==0)
  assert(turn.phase=='ready' and turn.scored and turn.pot>0)
  local stop_wins,continue_wins=0,0
  for i=1,samples do
    local sample_seed=seed+i*13
    local opponent_seed=E.stream_seed(sample_seed,9,'rival')
    local continuation_seed=E.stream_seed(sample_seed,9,'player')
    if not follower_beats(turn.pot,rolls,opponent_policy,opponent_seed) then
      stop_wins=stop_wins+1
    end
    local next_score=one_more_score(turn,rolls,continuation_seed)
    if next_score and not follower_beats(
        next_score,rolls+1,opponent_policy,opponent_seed) then
      continue_wins=continue_wins+1
    end
  end
  return stop_wins/samples,continue_wins/samples
end
local function category(delta)
  if delta>DEAD_BAND then return 'continue'
  elseif delta< -DEAD_BAND then return 'stop' end
  return 'uncertain'
end
function S.diagnostic(states_per_k,samples,dir)
  assert(states_per_k>=1 and states_per_k%1==0 and states_per_k<=80)
  assert(samples>=1 and samples%1==0 and samples<=256)
  local file
  if dir then
    file=assert(io.open(dir..'/bg_states.csv','w'))
    file:write('seed,rolls,score,free,opponent_policy,stop_win,continue_win,delta,classification\n')
  end
  local report={}
  local counts={[1]=0,[2]=0}
  local classes={
    [1]={prudent={stop=0,continue=0,uncertain=0},
      aggressive={stop=0,continue=0,uncertain=0},flips=0},
    [2]={prudent={stop=0,continue=0,uncertain=0},
      aggressive={stop=0,continue=0,uncertain=0},flips=0}
  }
  for seed=20001,20200 do
    if counts[1]>=states_per_k and counts[2]>=states_per_k then break end
    local s=E.new(seed,'player')
    assert(E.roll(s))
    if s.phase=='turn' then
      for k=1,2 do
        if s.phase~='turn' or s.active~='player' then break end
        local a=s.actors.player
        local o=pick_option(a.turn,'prudent','leader',nil,k,E.MAX_ROLLS,
          E.rng(E.stream_seed(seed,10,'player')))
        assert(E.take(s,o.mask))
        if counts[k]<states_per_k then
          counts[k]=counts[k]+1
          local by_policy={}
          for _,opponent in ipairs(S.rival_policies) do
            local stop,cont=S.estimate(a.turn,k,opponent,samples,
              seed*17+k*1000)
            local delta=cont-stop
            local label=category(delta)
            classes[k][opponent][label]=classes[k][opponent][label]+1
            by_policy[opponent]=label
            if file then file:write(csv(seed,k,a.turn.pot,
              a.turn.hot and 6 or Rules.count_free(a.turn),
              opponent,string.format('%.6f',stop),
              string.format('%.6f',cont),string.format('%+.6f',delta),
              label)) end
          end
          if (by_policy.prudent=='stop' and by_policy.aggressive=='continue') or
             (by_policy.prudent=='continue' and by_policy.aggressive=='stop') then
            classes[k].flips=classes[k].flips+1
          end
        end
        if k<2 then
          assert(E.roll(s))
          if s.phase~='turn' then break end
        end
      end
    end
  end
  if file then file:close() end
  for k=1,2 do
    assert(counts[k]==states_per_k,'not enough sampled states')
    for _,opponent in ipairs(S.rival_policies) do
      local c=classes[k][opponent]
      report[#report+1]=string.format(
        'after k=%d vs %s | states=%d stop=%d continue=%d uncertain=%d',
        k,opponent,counts[k],c.stop,c.continue,c.uncertain)
    end
    report[#report+1]=string.format(
      'after k=%d | decisive action flips between opponent policies=%d/%d',
      k,classes[k].flips,counts[k])
  end
  return table.concat(report,'\n')
end
function S.report(count,first,dir,states_per_k,samples)
  return table.concat({
    'EX-BG-001 Battute Gemelle; scripted diagnostics only, no human playtest',
    'canonical src/farkle/rules.lua; leader k=1..3; follower <=k; ties to leader',
    'Pilot: '..count..' paired seed labels starting '..first..
      '; opponent-policy and action-consumption can diverge despite common seed',
    S.pilot(count,first,dir),
    'Counterfactual: leader STOP vs ONE additional roll then bank (not optimal DP);'..
      ' follower prudent vs aggressive; MC dead band +/-'..DEAD_BAND,
    S.diagnostic(states_per_k or 80,samples or 96,dir),
    'Gates pending human playtest. No automatic promotion or claim of balance.'
  },'\n')
end
return S
