-- G4b: balanced comprehension stimuli, REUSING the proven Encounter C engine.
-- Not a rule change. These are real, reachable, nonlocking states.
-- Holdout 2000..6999 is strictly excluded.
local G=require('experiments.ex002_reactivity_lab.g4_stimuli')
local X=require('experiments.ex002_reactivity_lab.simulate')
local RNG=require('experiments.opponent_wager_lab.rng')
local B={}
B.practice_count=2
B.test_count=12
B.first_extra_seed=14000
B.last_extra_seed=15999
local quotas={R_yes=4,R_no=3,F_yes=3,F_no=4}
local names={'R_yes','R_no','F_yes','F_no'}

local function snapshot(s)
 local out={seed=s.seed,round=s.round,marks=s.claim_marks or s.marks,lanes={}}
 for i,l in ipairs(s.lanes) do
  out.lanes[i]={name=l.name,player=l.player,rival=l.rival,owner=l.owner}
 end
 return out
end
local function public_signature(t) return G.signature(t) end

local function choices(t,mode,target)
 return G.legal_targets(t,mode,target)
end
local function analyze(t)
 local open={}
 for id,l in ipairs(t.lanes) do
  if not l.owner then
   if l.player+t.marks>=4 then return nil end -- no immediate locks
   open[#open+1]=id
  end
 end
 if #open<2 then return nil end
 local r,f={},{}
 local reachable_r,reachable_f={},{}
 for _,id in ipairs(open) do
  r[id]=G.oracle(t,'reactive',id)
  f[id]=G.oracle(t,'fixed',id)
  reachable_r[r[id]]=true
  reachable_f[f[id]]=true
 end
 local proposed=open[((t.seed+t.round+t.marks)%#open)+1]
 local ryes,rno,fyes,fno
 for _,id in ipairs(open) do
  if reachable_r[id] and id~=r[proposed] and not ryes then ryes=id end
  if not reachable_r[id] and not rno then rno=id end
  if reachable_f[id] and not fyes then fyes=id end
  if not reachable_f[id] and not fno then fno=id end
 end
 return {open=open,proposed=proposed,R_yes=ryes,R_no=rno,
  F_yes=fyes,F_no=fno,sensitive=ryes~=nil}
end

local function new_pools()
 return {R_yes={},R_no={},F_yes={},F_no={}}
end
local function pool_has(pool,key)
 for _,v in ipairs(pool) do if v.signature==key then return true end end
 return false
end
local function consider(pools,t)
 local a=analyze(t)
 if not a then return end
 local sig=public_signature(t)
 for _,name in ipairs(names) do
  local goal=a[name]
  local p=pools[name]
  if goal and #p<28 and not pool_has(p,sig) then
   local mode=name:sub(1,1)=='R' and 'reactive' or 'fixed'
   local correct=choices(t,mode,goal)
   local yes=name:sub(-3)=='yes'
   assert((#correct>0)==yes,'G4b classification disagrees with engine')
   p[#p+1]={snapshot=snapshot(t),signature=sig,mode=mode,
     condition=name,proposed=a.proposed,request_target=goal,
     prediction_target=G.oracle(t,mode,a.proposed),
     control_choices=correct,reactive_sensitive=a.sensitive}
  end
 end
end
local function enough(pools)
 for _,name in ipairs(names) do
  if #pools[name]<quotas[name]+3 then return false end
 end
 return true
end

function B.manifest()
 local pools=new_pools()
 -- First use the proven G4 manifest, but do NOT reuse its target goals.
 for _,t in ipairs(G.manifest()) do consider(pools,t) end
 if not enough(pools) then
  for _,claim in ipairs({'sample_seeded','last','first'}) do
   for _,dice in ipairs({'balanced','prudent','daring'}) do
    for seed=B.first_extra_seed,B.last_extra_seed do
     X.play(seed,'reactive',dice,claim,nil,function(s,cf)
      if cf.legal>=2 and cf.nonlocking and s.round<=5 then
       consider(pools,snapshot(s))
      end
     end)
     if enough(pools) then break end
    end
    if enough(pools) then break end
   end
   if enough(pools) then break end
  end
 end
 for _,name in ipairs(names) do
  assert(#pools[name]>=quotas[name],
   ('G4b missing real states for %s (%d/%d)'):format(name,
      #pools[name],quotas[name]))
 end
 local seen,layout_counts={},{},{}
 local selected={}
 local schedule={'R_yes','F_no',
  'R_no','F_yes','R_yes','F_no',
  'F_yes','R_no','F_no','R_yes',
  'R_no','F_yes','R_yes','F_no'}
 for i,name in ipairs(schedule) do
  local chosen
  for pass=1,2 do
   for _,candidate in ipairs(pools[name]) do
    local board=G.board_key(candidate.snapshot)
    if not seen[candidate.signature] and
       (layout_counts[board] or 0)<2 and
       (pass==2 or not layout_counts[board]) then
     chosen=candidate;break
    end
   end
   if chosen then break end
  end
  assert(chosen,'not enough distinct reachable G4b boards for '..name)
  local t=chosen.snapshot
  t.condition=name
  t.mode=chosen.mode
  t.stage=i<=2 and 'practice' or 'test'
  t.proposed=chosen.proposed
  t.prediction_target=chosen.prediction_target
  t.request_target=chosen.request_target
  t.control_choices=chosen.control_choices
  t.reactive_sensitive=chosen.reactive_sensitive
  t.id=i
  selected[#selected+1]=t
  seen[chosen.signature]=true
  local board=G.board_key(t)
  layout_counts[board]=(layout_counts[board] or 0)+1
 end
 local random=RNG.new_rng(21737)
 for i=#selected,4,-1 do
  local j=random(3,i)
  selected[i],selected[j]=selected[j],selected[i]
 end
 for i,t in ipairs(selected) do t.order=i end
 return selected
end

function B.is_correct_control(t,lane)
 return G.is_correct_control(t,lane)
end

function B.assert_manifest(items)
 assert(#items==B.practice_count+B.test_count,'G4b wrong manifest length')
 local seen,layouts,counts={}, {},{R_yes=0,R_no=0,F_yes=0,F_no=0}
 for i,t in ipairs(items) do
  assert(t.order==i,'incorrect trial order')
  assert(t.seed>=10000 and t.seed<=B.last_extra_seed and
    not (t.seed>=2000 and t.seed<=6999),'invalid research seed')
  local key=G.signature(t)
  assert(not seen[key],'duplicate public scenario')
  seen[key]=true
  local board=G.board_key(t)
  layouts[board]=(layouts[board] or 0)+1
  assert(layouts[board]<=2,'too many duplicate public boards')
  local open=0
  for _,lane in ipairs(t.lanes) do
   if not lane.owner then
    open=open+1
    assert(lane.player+t.marks<4,'G4b immediate player lock')
   end
  end
  assert(open>=2 and t.round<=5)
  assert(t.prediction_target==G.oracle(t,t.mode,t.proposed))
  assert(not t.lanes[t.request_target].owner,'requested lane closed')
  local actual=choices(t,t.mode,t.request_target)
  assert(#actual==#t.control_choices)
  for k,v in ipairs(actual) do assert(v==t.control_choices[k]) end
  local yes=t.condition:sub(-3)=='yes'
  assert((#actual>0)==yes,'target feasibility not balanced')
  assert((t.mode=='reactive')==(t.condition:sub(1,1)=='R'))
  if t.stage=='test' then counts[t.condition]=counts[t.condition]+1 end
 end
 for _,name in ipairs(names) do assert(counts[name]==3,
    'G4b 3 per cell failed: '..name..'='..counts[name]) end
 local distinct=0
 for _ in pairs(layouts) do distinct=distinct+1 end
 assert(distinct>=8,'G4b too few distinct public boards')
 return true
end

B.G=G
return B
