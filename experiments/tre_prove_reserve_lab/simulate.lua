-- EX-TP-001. Screening policies are scripted, transparent proxies, not expert players.
local E=require('experiments.tre_prove_reserve_lab.engine')
local Rules=require('src.farkle.rules')
local S={}
S.players={'commit','aware','blind'}
S.rivals={'aggressive','conserve','balanced'}
S.configs={{6,1},{8,1},{10,1},{6,2},{8,2},{10,2}}
local function valid_policy(p,list)
  for _,v in ipairs(list) do if p==v then return true end end
  return false
end
local function pick(s)
  local best,bval
  for _,o in ipairs(Rules.options(s.turn)) do
    local remaining=Rules.count_free(s.turn)-#o.ids
    if remaining==0 then remaining=6 end
    local value=o.points+5*remaining
    if not best or value>bval or (value==bval and o.mask<best.mask) then
      best,bval=o,value
    end
  end
  assert(best,'ready state without selectable combination')
  return best.mask
end
local function assumed_reserve(s,policy)
  return policy=='blind' and 8 or s.reserve
end
function S.bank_now(s,policy)
  if policy=='commit' then
    return s.turn.pot>=40 or Rules.count_free(s.turn)<=1 and not s.turn.hot
  end
  local reserve=assumed_reserve(s,policy)
  local near=false
  for _,l in ipairs(s.lanes) do
    if not l.owner and l.player>=3 then near=true;break end
  end
  local threshold
  if near then threshold=20
  elseif reserve==0 then threshold=40
  elseif reserve<=2 then threshold=50
  elseif reserve>=6 then threshold=90
  else threshold=65 end
  return s.turn.pot>=threshold or
    (Rules.count_free(s.turn)<=1 and not s.turn.hot)
end
local function clone_board(s,observed_reserve)
  local board={round=s.round,reserve=observed_reserve,cap=s.cap,lanes={}}
  for i,l in ipairs(s.lanes) do
    board.lanes[i]={player=l.player,rival=l.rival,owner=l.owner}
  end
  return board
end
local function board_value(board)
  local value=0
  for _,l in ipairs(board.lanes) do
    if l.owner=='player' then value=value+35
    elseif l.owner=='rival' then value=value-35
    else
      value=value+5*(l.player-l.rival)
      if l.player==3 then value=value+7 end
      if l.rival==3 then value=value-7 end
    end
  end
  return value
end
function S.choose_lane(s,policy,rival_policy)
  assert(valid_policy(policy,S.players),'unknown player policy')
  assert(valid_policy(rival_policy,S.rivals),'unknown rival policy')
  local best,bval
  for id,l in ipairs(s.lanes) do
    if not l.owner then
      local value
      if policy=='commit' then
        value=7*l.player-1.5*l.rival+
          ((l.player+s.marks)>=4 and 18 or 0)
      else
        local state=clone_board(s,assumed_reserve(s,policy))
        local this=state.lanes[id]
        this.player=math.min(4,this.player+s.marks)
        if this.player==4 then this.owner='player' end
        local player_owned=0
        for _,v in ipairs(state.lanes) do
          if v.owner=='player' then player_owned=player_owned+1 end
        end
        if player_owned<2 then
          local response=E.rival_move(state,rival_policy)
          if response.amount>0 then
            local target=state.lanes[response.lane]
            target.rival=target.rival+response.amount
            if target.rival==4 then target.owner='rival' end
          end
        end
        value=board_value(state)
      end
      if not best or value>bval then best,bval=id,value end
    end
  end
  return best
end
function S.play(seed,reserve,cap,player_policy,rival_policy)
  assert(valid_policy(player_policy,S.players))
  assert(valid_policy(rival_policy,S.rivals))
  local s=E.new(seed,reserve,cap)
  local steps=0
  while s.phase~='finished' do
    steps=steps+1
    assert(steps<=200,'scripted encounter stuck at '..s.phase)
    if s.phase=='round_end' then
      assert(E.next_round(s))
    elseif s.phase=='rival' then
      assert(E.rival(s,rival_policy))
    elseif s.phase=='claim' then
      assert(E.claim(s,assert(S.choose_lane(s,player_policy,rival_policy))))
    elseif s.phase=='dice' then
      if s.turn.phase=='fresh' then
        assert(E.roll(s))
      elseif s.turn.phase=='ready' and not s.turn.scored then
        assert(E.take(s,pick(s)))
      elseif s.turn.phase=='ready' and s.turn.scored then
        if S.bank_now(s,player_policy) then assert(E.bank(s))
        else assert(E.roll(s)) end
      else error('unexpected phase '..tostring(s.turn.phase)) end
    else error('invalid encounter phase '..tostring(s.phase)) end
  end
  assert(s.round<=E.MAX_ROUNDS and s.reserve>=0 and s.reserve<=reserve)
  local p,r=E.owners(s)
  assert(p<=2 and r<=2,'proof count invalid')
  return s
end
local function wilson(w,n)
  if n==0 then return 0,1 end
  local z=1.959963984540054
  local p=w/n
  local d=1+z*z/n
  local c=(p+z*z/(2*n))/d
  local h=z*math.sqrt((p*(1-p)+z*z/(4*n))/n)/d
  return c-h,c+h
end
local function utility(w)
  return w=='player' and 1 or w=='draw' and 0.5 or 0
end
local function csv(...)
  local parts={...}
  for i,x in ipairs(parts) do
    local v=tostring(x)
    if v:find('[,"\r\n]') then v='"'..v:gsub('"','""')..'"' end
    parts[i]=v
  end
  return table.concat(parts,',')..'\n'
end
function S.pilot(first,count,dir)
  assert(type(first)=='number' and first%1==0 and first>=1)
  assert(type(count)=='number' and count%1==0 and count>=1 and count<=5000)
  assert(first+count-1<2147483647)
  local f
  if dir then
    f=assert(io.open(dir..'/tp_matches.csv','w'))
    f:write('seed,reserve,cap,player_policy,rival_policy,winner,rounds,rolls,busts,banks,eligible,eligible_spend,eligible_pass,spent,reserve_left,exhausted,lane_switches,voluntary_switches,bait_patterns\n')
  end
  local out={}
  for _,conf in ipairs(S.configs) do
    local reserve,cap=conf[1],conf[2]
    for _,rival in ipairs(S.rivals) do
      local paired={}
      for _,player in ipairs(S.players) do
        local w,d,l,spent,eligible,passes,used,switched,baits=0,0,0,0,0,0,0,0,0
        for seed=first,first+count-1 do
          local s=S.play(seed,reserve,cap,player,rival)
          local m=s.metrics
          if s.winner=='player' then w=w+1
          elseif s.winner=='draw' then d=d+1
          else l=l+1 end
          spent=spent+m.spent
          eligible=eligible+m.eligible
          passes=passes+m.eligible_pass
          if s.reserve==0 then used=used+1 end
          switched=switched+m.voluntary_switches
          baits=baits+m.bait_patterns
          if player=='aware' or player=='blind' then
            local a=paired[seed] or {}
            a[player]=utility(s.winner)
            paired[seed]=a
          end
          if f then f:write(csv(seed,reserve,cap,player,rival,
            s.winner,s.round,m.rolls,m.busts,m.banks,m.eligible,
            m.eligible_spend,m.eligible_pass,m.spent,s.reserve,
            s.reserve==0 and 1 or 0,m.lane_switches,
            m.voluntary_switches,m.bait_patterns)) end
        end
        local lo,hi=wilson(w,count)
        local spend_rate=eligible>0 and (eligible-passes)/eligible or 0
        out[#out+1]=string.format(
          'R=%d cap=%d | %s vs %s | W/D/L=%d/%d/%d Wilson95win=[%.3f,%.3f] | spend_eligible=%.3f | exhaust=%.3f | spent/match=%.2f | voluntary_switch/match=%.3f | bait/match=%.3f',
          reserve,cap,player,rival,w,d,l,lo,hi,spend_rate,
          used/count,spent/count,switched/count,baits/count)
      end
      local sum,sumsq=0,0
      for seed=first,first+count-1 do
        local row=paired[seed]
        assert(row and row.aware~=nil and row.blind~=nil)
        local x=row.aware-row.blind
        sum=sum+x;sumsq=sumsq+x*x
      end
      local mean=sum/count
      local variance=count>1 and math.max(0,(sumsq-sum*sum/count)/(count-1)) or 0
      local half=1.96*math.sqrt(variance/count)
      out[#out+1]=string.format(
        'PAIRED R=%d cap=%d rival=%s | aware-blind utility=%+.4f approx95=[%+.4f,%+.4f]',
        reserve,cap,rival,mean,mean-half,mean+half)
    end
  end
  if f then f:close() end
  return table.concat(out,'\n')
end
return S
