-- G4 human study stimuli from REACHABLE C-encounter pre-claim boards.
-- This is an observation experiment, not a new rule or rendered game.
-- No use of the reserved EX-002 confirmation seeds 2000..6999.
local E=require('experiments.encounter_ac_lab.engine')
local X=require('experiments.ex002_reactivity_lab.simulate')
local RNG=require('experiments.opponent_wager_lab.rng')
local M={}
M.first_seed=10000
M.last_seed=13000
M.practice_count=2
M.test_count=12

local function snapshot(s)
 local lanes={}
 for i,l in ipairs(s.lanes) do
  lanes[i]={name=l.name,player=l.player,rival=l.rival,owner=l.owner}
 end
 return {seed=s.seed,round=s.round,marks=s.claim_marks,lanes=lanes}
end
local function signature(t)
 local parts={t.round..':'..t.marks}
 for i,l in ipairs(t.lanes) do
  parts[#parts+1]=i..':'..l.player..':'..l.rival..':'..(l.owner or '-')
 end
 return table.concat(parts,'|')
end
M.signature=signature
-- Board diversity is stricter than full trial signature (round/marks).
function M.board_key(t)
 local parts={}
 for i,l in ipairs(t.lanes) do
  parts[#parts+1]=i..':'..l.player..':'..l.rival..':'..(l.owner or '-')
 end
 return table.concat(parts,'|')
end

function M.restore(t,mode)
 assert(mode=='reactive' or mode=='fixed','invalid G4 mode')
 local s=E.new('C',t.seed,{rival_target_mode=mode})
 s.round=t.round;s.phase='claim';s.claim_marks=t.marks
 for i,l in ipairs(t.lanes) do
  local lane=s.lanes[i]
  lane.player=l.player;lane.rival=l.rival;lane.owner=l.owner
 end
 return s
end

-- The same encounter engine provides the oracle, without dice or RNG changes.
function M.oracle(t,mode,lane)
 local s=M.restore(t,mode)
 assert(E.claim(s,lane),'G4 oracle requires legal claim')
 return s.last_rival_decision and s.last_rival_decision.target or 0
end

function M.legal_targets(t,mode,target)
 local out={}
 for i,l in ipairs(t.lanes) do
  if not l.owner and M.oracle(t,mode,i)==target then
   out[#out+1]=i
  end
 end
 return out
end

local function changed_target(cf)
 local first=assert(cf.rows[1]).rival_target
 for _,row in ipairs(cf.rows) do
  if row.rival_target~=first and row.rival_target~=0 then
   return row.rival_target
  end
 end
end

function M.manifest()
 local pool,seen,board_counts={},{},{}
 -- Mix diagnostic player allocation routes. Every board still comes from
 -- the EXISTING encounter engine with real six-D6 decisions. Discard
 -- near-duplicates: max two scenarios may share the same public board.
 for _,claim_policy in ipairs({'sample_seeded','last','first'}) do
  for _,dice_policy in ipairs({'balanced','prudent','daring'}) do
   for seed=M.first_seed,M.last_seed do
    X.play(seed,'reactive',dice_policy,claim_policy,nil,function(s,cf)
     if #pool>=M.practice_count+M.test_count then return end
     if cf.legal>=2 and cf.nonlocking and cf.target_sensitive and
        s.round>=1 and s.round<=5 then
      local target=changed_target(cf)
      if target then
       local t=snapshot(s)
       local key=signature(t)
       local board=M.board_key(t)
       if not seen[key] and (board_counts[board] or 0)<2 then
        local fixed=M.restore(t,'fixed')
        local check=X.counterfactuals(fixed)
        if not check.target_sensitive and check.legal==cf.legal and
           check.nonlocking then
         seen[key]=true
         board_counts[board]=(board_counts[board] or 0)+1
         t.changed_target=target
         pool[#pool+1]=t
        end
       end
      end
     end
    end)
    if #pool>=M.practice_count+M.test_count then break end
   end
   if #pool>=M.practice_count+M.test_count then break end
  end
  if #pool>=M.practice_count+M.test_count then break end
 end
 assert(#pool>=M.practice_count+M.test_count,
  'not enough DIVERSE reachable G4 boards: '..#pool)
 -- Two practice tasks (R then F), then eight R and four F scored tasks.
 local modes={'reactive','fixed','reactive','fixed','reactive',
  'reactive','fixed','reactive','reactive','fixed','reactive',
  'reactive','fixed','reactive'}
 local trials={}
 for i=1,M.practice_count+M.test_count do
  local t=pool[i]
  t.id=i
  t.stage=i<=M.practice_count and 'practice' or 'test'
  t.mode=assert(modes[i])
  local open={}
  for lane,l in ipairs(t.lanes) do
   if not l.owner then open[#open+1]=lane end
  end
  assert(#open>=2)
  t.proposed=open[((t.seed+t.round+i)%#open)+1]
  t.prediction_target=M.oracle(t,t.mode,t.proposed)
  assert(t.prediction_target>=1 and t.prediction_target<=3)
  if t.mode=='reactive' then
   t.request_target=t.changed_target
  else
   -- Fixed control must request a DIFFERENT, but still OPEN, target.
   for _,lane in ipairs(open) do
    if lane~=t.prediction_target then
     t.request_target=lane;break
    end
   end
  end
  assert(t.request_target and not t.lanes[t.request_target].owner)
  t.control_choices=M.legal_targets(t,t.mode,t.request_target)
  if t.mode=='reactive' then
   assert(#t.control_choices>=1,'G4 R claim target not achievable')
  else assert(#t.control_choices==0,'G4 F target must be unreachable') end
  trials[#trials+1]=t
 end
 -- Stable counterbalanced order for scored items: no seed-dependent
 -- participant differences. Randomize only presentation, not the stimuli.
 local random=RNG.new_rng(11737)
 for i=#trials,M.practice_count+2,-1 do
  local j=random(M.practice_count+1,i)
  trials[i],trials[j]=trials[j],trials[i]
 end
 for i,t in ipairs(trials) do t.order=i end
 return trials
end

function M.is_correct_control(t,lane)
 if lane==0 then return #t.control_choices==0 end
 for _,choice in ipairs(t.control_choices) do
  if choice==lane then return true end
 end
 return false
end

function M.display_board(t)
 local lines={}
 lines[#lines+1]=('Prova %d/6; sigilli da collocare: %d'):format(t.round,t.marks)
 lines[#lines+1]='  Categoria                  Tu   Rivale  Priorita  Stato'
 for i,l in ipairs(t.lanes) do
  lines[#lines+1]=string.format('  %d %-24s %d      %d        %d       %s',
   i,l.name,l.player,l.rival,4-i,
   l.owner and ('CHIUSA ('..l.owner..')') or 'aperta')
 end
 return table.concat(lines,'\n')
end

function M.rule(mode)
 if mode=='reactive' then
  return 'R — Rivale: 5×propri sigilli + 2×tuoi sigilli + priorita; vince il massimo.'
 end
 return 'F — controllo: sceglie la priorita massima (3/2/1) fra prove aperte.'
end

function M.assert_manifest(trials)
 assert(#trials==14,'wrong manifest size')
 local seen,counts,layout_counts={}, {reactive=0,fixed=0}, {}
 local test_count=0
 for i,t in ipairs(trials) do
  local key=signature(t)
  assert(not seen[key],'repeated board in G4')
  seen[key]=true
  local board=M.board_key(t)
  layout_counts[board]=(layout_counts[board] or 0)+1
  assert(layout_counts[board]<=2,'G4 near-duplicate board overrepresented')
  assert(t.order==i and t.proposed>=1 and t.proposed<=3)
  assert(t.prediction_target==M.oracle(t,t.mode,t.proposed))
  assert(M.is_correct_control(t,t.control_choices[1] or 0))
  assert(t.round>=1 and t.round<=5 and t.marks>=1 and t.marks<=3)
  if t.stage=='test' then
   test_count=test_count+1;counts[t.mode]=counts[t.mode]+1
  end
 end
 assert(test_count==12 and counts.reactive==8 and counts.fixed==4)
 local layouts=0
 for _ in pairs(layout_counts) do layouts=layouts+1 end
 assert(layouts>=7,'G4 has too few distinct public board layouts')
 return true
end
return M
