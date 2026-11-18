-- EX-002 / RQ-003: headless causal probe for Encounter C rival targeting.
-- Research only: use the production Farkle rules and existing encounter engine.
local E=require('experiments.encounter_ac_lab.engine')
local Rules=require('src.farkle.rules')
local M={}
M.dice_policies={'prudent','balanced','daring'}
M.claim_policies={'first','informed'}
M.rival_modes={'reactive','fixed'}
M.stops={prudent=30,balanced=60,daring=110}

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

-- No dice are rolled during a claim; the RNG function is deliberately shared.
-- Trials are discarded after exactly one claim and never advance to next_round.
local function deep_copy(v,seen)
 if type(v)~='table' then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local copy={}
 seen[v]=copy
 for k,value in pairs(v) do copy[deep_copy(k,seen)]=deep_copy(value,seen) end
 return copy
end

local function board_signature(s)
 local out={}
 for i,l in ipairs(s.lanes) do
  out[i]=i..':'..l.player..':'..l.rival..':'..(l.owner or '-')
 end
 return table.concat(out,'|')
end

local function public_utility(s)
 local total=0
 for _,l in ipairs(s.lanes) do
  total=total+4*(l.player-l.rival)
  if l.owner=='player' then total=total+50
  elseif l.owner=='rival' then total=total-50 end
 end
 if s.phase=='finished' then
  if s.winner=='player' then total=total+500
  elseif s.winner=='rival' then total=total-500 end
 end
 return total
end

-- Exhaustive one-action counterfactuals from the identical pre-claim board.
-- A "terminal status" change can be immediate win vs unfinished; it does
-- NOT claim that future dice or the eventual match outcome have changed.
function M.counterfactuals(s)
 assert(s.mode=='C' and s.phase=='claim','counterfactual requires a C claim')
 local fingerprint=board_signature(s)
 local original_events=#s.events
 local rows,targets,terminal_statuses={}, {}, {}
 local all_nonlocking=true
 for id,l in ipairs(s.lanes) do
  if not l.owner then
   if l.player+s.claim_marks>=E.C_SEAL_TARGET then all_nonlocking=false end
   local trial=deep_copy(s)
   assert(E.claim(trial,id),'legal counterfactual claim failed')
   local decision=trial.last_rival_decision
   local rival_target=decision and decision.target or 0
   local terminal=trial.phase=='finished' and trial.winner or 'unfinished'
   local summary=E.summary(trial)
   local row={lane=id,rival_target=rival_target,terminal_status=terminal,
     provisional_control=summary.winner,signature=board_signature(trial),
     utility=public_utility(trial),
     rule=decision and decision.rule or 'nessuna risposta: vittoria Incisore',
     candidate_scores=decision and decision.candidates or {},
     player_locked=trial.lanes[id].owner=='player'}
   rows[#rows+1]=row
   targets[rival_target]=true
   terminal_statuses[terminal]=true
  end
 end
 assert(board_signature(s)==fingerprint and #s.events==original_events,
  'counterfactual mutated the live game')
 local target_count,terminal_count=0,0
 for _ in pairs(targets) do target_count=target_count+1 end
 for _ in pairs(terminal_statuses) do terminal_count=terminal_count+1 end
 return {rows=rows,legal=#rows,target_sensitive=#rows>=2 and target_count>1,
   nonlocking=all_nonlocking,
   terminal_status_sensitive=#rows>=2 and terminal_count>1}
end

local function choose_claim(s,claim_policy,cf)
 if claim_policy=='first' then return assert(cf.rows[1]).lane end
 -- Post-pilot stress only: deliberately choose the last open category.
 -- Never included in the preregistered M.pilot sample.
 if claim_policy=='last' then return assert(cf.rows[#cf.rows]).lane end
 assert(claim_policy=='informed','unknown EX-002 claim policy')
 local best,best_utility
 for _,row in ipairs(cf.rows) do
  -- Equal utility keeps the smallest lane index (public stable tie break).
  if best==nil or row.utility>best_utility then
   best,best_utility=row.lane,row.utility
  end
 end
 return assert(best)
end

-- writer receives one counterfactual row for EVERY legal claim (selected or not).
function M.play(seed,mode,dice_policy,claim_policy,writer,observer)
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and seed<2147483647)
 assert(mode=='reactive' or mode=='fixed')
 assert(M.stops[dice_policy],'unknown dice policy')
 assert(claim_policy=='first' or claim_policy=='informed' or claim_policy=='last')
 local s=E.new('C',seed,{rival_target_mode=mode})
 local stats={choice_states=0,legal_claims=0,nonlocking_states=0,
  target_sensitive=0,nonlocking_target_sensitive=0,terminal_status_sensitive=0,
  total_counterfactuals=0,chosen_rival_replies=0}
 for step=1,200 do
  if s.phase=='finished' then return s,stats end
  if s.phase=='dice' then
   if E.can_roll(s) then assert(E.roll(s))
   else
    local o=assert(best_option(s.turn,dice_policy))
    for _,id in ipairs(o.ids) do assert(E.toggle(s,id)) end
    local potential=s.turn.pot+o.points
    if potential>=M.stops[dice_policy] or
       Rules.count_free(s.turn)-#o.ids<=1 then
     assert(E.bank(s))
    else assert(E.take(s)) end
   end
  elseif s.phase=='claim' then
   local cf=M.counterfactuals(s)
   local chosen=choose_claim(s,claim_policy,cf)
   -- G4 observation-only hook: inspect real pre-claim states, never modify.
   -- Existing callers omit the hook and retain identical behavior.
   if observer then observer(s,cf,chosen) end
   local round=s.round
   local amount=s.claim_marks
   stats.choice_states=stats.choice_states+1
   stats.legal_claims=stats.legal_claims+cf.legal
   stats.total_counterfactuals=stats.total_counterfactuals+#cf.rows
   if cf.nonlocking then stats.nonlocking_states=stats.nonlocking_states+1 end
   if cf.target_sensitive then
    stats.target_sensitive=stats.target_sensitive+1
    if cf.nonlocking then
     stats.nonlocking_target_sensitive=stats.nonlocking_target_sensitive+1
    end
   end
   if cf.terminal_status_sensitive then
    stats.terminal_status_sensitive=stats.terminal_status_sensitive+1
   end
   for _,row in ipairs(cf.rows) do
    if writer then writer(round,amount,cf,row,chosen) end
   end
   local selected_row
   for _,row in ipairs(cf.rows) do
    if row.lane==chosen then selected_row=row;break end
   end
   assert(E.claim(s,chosen))
   assert(board_signature(s)==selected_row.signature,
     'actual response diverges from pre-claim counterfactual')
   local actual=s.last_rival_decision
   assert((actual and actual.target or 0)==selected_row.rival_target,
     'actual rival target differs from counterfactual')
   if actual then stats.chosen_rival_replies=stats.chosen_rival_replies+1 end
  elseif s.phase=='round_end' then assert(E.next_round(s))
  else error('unknown EX-002 phase: '..tostring(s.phase)) end
 end
 error('EX-002 exceeded 200 transitions at seed '..seed..' / '..mode)
end

local function csv_line(...)
 local fields={...}
 for i,v in ipairs(fields) do
  local x=tostring(v)
  if x:find('[,"\r\n]') then x='"'..x:gsub('"','""')..'"' end
  fields[i]=x
 end
 return table.concat(fields,',')..'\n'
end

local function bucket()
 return {n=0,player=0,rival=0,draw=0,rounds=0,busts=0,banked=0,
  choice_states=0,legal_claims=0,nonlocking_states=0,target_sensitive=0,
  nonlocking_target_sensitive=0,terminal_status_sensitive=0,
  total_counterfactuals=0,chosen_rival_replies=0}
end
local function add(bucket_,s,stats)
 bucket_.n=bucket_.n+1
 bucket_[s.winner]=bucket_[s.winner]+1
 bucket_.rounds=bucket_.rounds+s.round
 bucket_.busts=bucket_.busts+s.busts
 bucket_.banked=bucket_.banked+s.banked
 for k,v in pairs(stats) do bucket_[k]=bucket_[k]+v end
end
local function fmt(x) return string.format('%.3f',x) end
local function rate(n,d) return d>0 and n/d or 0 end

-- Pilot 1000..1999. Confirmation 2000..6999 is reserved, not used here.
-- Twelve configurations: 3 dice policies x 2 claim policies x 2 target modes.
function M.pilot(first,last,dir)
 assert(type(first)=='number' and first%1==0 and first>=1)
 assert(type(last)=='number' and last%1==0 and last>=first)
 assert(last-first<5000 and last<2147483647)
 local mf,cf
 if dir then
  mf=assert(io.open(dir..'/ex002_matches.csv','w'))
  cf=assert(io.open(dir..'/ex002_counterfactuals.csv','w'))
  mf:write('seed,dice_policy,claim_policy,rival_mode,winner,rounds,busts,banked,choice_states,legal_claims,nonlocking_states,target_sensitive,nonlocking_target_sensitive,terminal_status_sensitive,rival_replies\n')
  cf:write('seed,dice_policy,claim_policy,rival_mode,round,marks,legal_claims,chosen_lane,candidate_lane,chosen,rival_target,board_after,provisional_control,terminal_status,public_utility,all_nonlocking,target_sensitive,terminal_status_sensitive,rule,candidate_scores\n')
 end
 local lines={'EX-002 Encounter C: public reactive R vs fixed F; seed '..first..'..'..last,
  'Pilot only; same canonical Farkle dice, rival seal budget and time; no UI or human test.',
  'Terminal-status counterfactual = immediate result or unfinished, NOT eventual win.',
  'dice | claim | mode | P/R/D | mean rounds | mean Farkles | choices | reactive target changes / choices | nonlocking changes / states | terminal-status changes'}
 local n=last-first+1
 for _,dice_policy in ipairs(M.dice_policies) do
  for _,claim_policy in ipairs(M.claim_policies) do
   local buckets={reactive=bucket(),fixed=bucket()}
   local delta_sum,delta_sq=0,0
   for seed=first,last do
    local won={}
    for _,mode in ipairs(M.rival_modes) do
     local writer
     if cf then
      writer=function(round,amount,probe,row,chosen)
       local scores={}
       for _,candidate in ipairs(row.candidate_scores) do
        scores[#scores+1]=candidate.lane..':'..candidate.score
       end
       cf:write(csv_line(seed,dice_policy,claim_policy,mode,round,amount,
         probe.legal,chosen,row.lane,row.lane==chosen and 1 or 0,
         row.rival_target,row.signature,row.provisional_control,
         row.terminal_status,row.utility,probe.nonlocking and 1 or 0,
         probe.target_sensitive and 1 or 0,
         probe.terminal_status_sensitive and 1 or 0,
         row.rule,table.concat(scores,'|')))
      end
     end
     local s,stats=M.play(seed,mode,dice_policy,claim_policy,writer)
     add(buckets[mode],s,stats)
     won[mode]=s.winner=='player' and 1 or 0
     if mf then
      mf:write(csv_line(seed,dice_policy,claim_policy,mode,s.winner,
       s.round,s.busts,s.banked,stats.choice_states,stats.legal_claims,
       stats.nonlocking_states,stats.target_sensitive,
       stats.nonlocking_target_sensitive,stats.terminal_status_sensitive,
       stats.chosen_rival_replies))
     end
    end
    local difference=won.reactive-won.fixed
    delta_sum=delta_sum+difference
    delta_sq=delta_sq+difference*difference
   end
   for _,mode in ipairs(M.rival_modes) do
    local b=buckets[mode]
    lines[#lines+1]=table.concat({dice_policy,claim_policy,mode,
      b.player..'/'..b.rival..'/'..b.draw,fmt(b.rounds/n),
      fmt(b.busts/n),b.choice_states,
      b.target_sensitive..'/'..b.choice_states,
      b.nonlocking_target_sensitive..'/'..b.nonlocking_states,
      b.terminal_status_sensitive},' | ')
   end
   local mean=delta_sum/n
   local var=n>1 and math.max(0,(delta_sq-delta_sum*delta_sum/n)/(n-1)) or 0
   local margin=1.96*math.sqrt(var/n)
   lines[#lines+1]=dice_policy..' / '..claim_policy..
     ' paired player win Δ(R-F) '..fmt(mean)..
     ' approx95 ['..fmt(mean-margin)..','..fmt(mean+margin)..']'
  end
 end
 if mf then mf:close();cf:close() end
 return table.concat(lines,'\n')
end
return M
