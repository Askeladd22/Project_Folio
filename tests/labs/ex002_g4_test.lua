-- Technical verification for EX-002 G4 stimuli/answers. NOT human results.
local G=require('experiments.ex002_reactivity_lab.g4_stimuli')
local X=require('experiments.ex002_reactivity_lab.simulate')
local E=require('experiments.encounter_ac_lab.engine')
local count=0
local function check(name,fn) fn();count=count+1;print('PASS EX-002 G4 '..name) end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end

check('14 reproducible, distinct reachable states outside reserved seeds',function()
 local a=G.manifest()
 local b=G.manifest()
 assert(G.assert_manifest(a) and G.assert_manifest(b))
 eq(#a,14)
 for i=1,#a do
  local u,v=a[i],b[i]
  eq(G.signature(u),G.signature(v))
  eq(u.seed,v.seed);eq(u.mode,v.mode)
  eq(u.proposed,v.proposed)
  eq(u.prediction_target,v.prediction_target)
  eq(u.request_target,v.request_target)
  assert(u.seed>=10000 and u.seed<=13000)
  assert(u.seed<2000 or u.seed>6999)
 end
end)

check('all G4 boards have three open lanes and no immediate artist lock',function()
 for _,t in ipairs(G.manifest()) do
  for _,l in ipairs(t.lanes) do
   assert(not l.owner and l.player+t.marks<4)
   assert(l.player>=0 and l.rival>=0)
  end
  local r=G.restore(t,'reactive')
  local f=G.restore(t,'fixed')
  assert(r.phase=='claim' and f.phase=='claim')
  local cr=X.counterfactuals(r)
  local cf=X.counterfactuals(f)
  assert(cr.nonlocking and cf.nonlocking)
  assert(cr.target_sensitive and not cf.target_sensitive)
  eq(cr.legal,3);eq(cf.legal,3)
 end
end)

check('correct answers derive from actual E.claim, not an invented table',function()
 local seenR,seenF=0,0
 for _,t in ipairs(G.manifest()) do
  local s=G.restore(t,t.mode)
  local sig=G.signature(t)
  local target=G.oracle(t,t.mode,t.proposed)
  eq(target,t.prediction_target)
  local choices=G.legal_targets(t,t.mode,t.request_target)
  eq(#choices,#t.control_choices)
  for i,v in ipairs(choices) do eq(v,t.control_choices[i]) end
  for i=1,3 do
   local valid=false
   for _,v in ipairs(choices) do if v==i then valid=true end end
   eq(G.is_correct_control(t,i),valid)
  end
  eq(G.is_correct_control(t,0),#choices==0)
  eq(s.phase,'claim')
  for i=1,3 do
   eq(s.lanes[i].player,t.lanes[i].player)
   eq(s.lanes[i].rival,t.lanes[i].rival)
  end
  eq(sig,G.signature(t))
  if t.stage=='test' then
   if t.mode=='reactive' then
    seenR=seenR+1
    assert(#choices>=1)
   else
    seenF=seenF+1
    eq(#choices,0)
   end
  end
 end
 eq(seenR,8);eq(seenF,4)
end)

check('optional observation hook leaves existing simulation deterministic',function()
 for seed=180,190 do
  local observed=0
  local x=X.play(seed,'reactive','balanced','last')
  local y=X.play(seed,'reactive','balanced','last',nil,function(s,cf)
   observed=observed+1
   assert(s.mode=='C' and s.phase=='claim')
   assert(cf.legal>=1)
  end)
  eq(x.winner,y.winner)
  eq(x.banked,y.banked);eq(x.busts,y.busts)
  eq(#x.events,#y.events)
  for i=1,#x.events do
   eq(x.events[i].action,y.events[i].action)
   eq(x.events[i].detail,y.events[i].detail)
  end
  assert(observed>=0)
 end
end)

print('PASS EX-002 G4 deterministic suite: '..count..' scenarios')
