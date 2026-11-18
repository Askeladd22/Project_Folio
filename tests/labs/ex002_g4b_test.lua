-- G4b deterministic technical tests. Never count synthetic input as human data.
local B=require('experiments.ex002_reactivity_lab.g4b_stimuli')
local G=B.G
local E=require('experiments.encounter_ac_lab.engine')
local X=require('experiments.ex002_reactivity_lab.simulate')
local n=0
local function check(name,fn)
 fn();n=n+1;print('PASS EX-002 G4b '..name)
end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end

check('balanced manifest and zero R/F label shortcut',function()
 local t=B.manifest()
 assert(B.assert_manifest(t))
 eq(#t,14)
 local counts={R_yes=0,R_no=0,F_yes=0,F_no=0}
 for i,item in ipairs(t) do
  assert(item.stage==(i<=2 and 'practice' or 'test'))
  if i>2 then counts[item.condition]=counts[item.condition]+1 end
 end
 eq(t[1].condition,'R_yes')
 eq(t[2].condition,'F_no')
 for k,v in pairs(counts) do eq(v,3) end
end)

check('oracle all alternatives, not one answer per policy',function()
 for _,t in ipairs(B.manifest()) do
  local possible={}
  local open=0
  local proposal_s=G.restore(t,t.mode)
  assert(proposal_s.phase=='claim')
  local p=E.preview_rival_target(proposal_s)
  assert(p and p.target and p.marks)
  for lane,l in ipairs(t.lanes) do
   if not l.owner then
    open=open+1
    local target=G.oracle(t,t.mode,lane)
    possible[target]=true
    local trial=G.restore(t,t.mode)
    assert(E.claim(trial,lane))
    local actual=trial.last_rival_decision and
     trial.last_rival_decision.target or 0
    eq(actual,target)
   end
  end
  assert(open>=2)
  local truth=possible[t.request_target] and true or false
  eq(truth,#t.control_choices>0)
  for _,id in ipairs(t.control_choices) do
   eq(G.oracle(t,t.mode,id),t.request_target)
  end
  assert(B.is_correct_control(t,0)==not truth)
  if t.condition=='R_yes' then
   assert(t.prediction_target~=t.request_target,
    'positive R must alter proposed rival destination')
  elseif t.condition=='F_yes' then
   assert(#t.control_choices==open,'F reachable must accept ANY open placement')
  end
 end
end)

check('same manifest always; public board diversity',function()
 local a,b=B.manifest(),B.manifest()
 local seen={}
 for i=1,#a do
  eq(a[i].order,b[i].order)
  eq(G.signature(a[i]),G.signature(b[i]))
  eq(a[i].condition,b[i].condition)
  eq(a[i].mode,b[i].mode)
  eq(a[i].request_target,b[i].request_target)
  eq(a[i].prediction_target,b[i].prediction_target)
  local signature=G.signature(a[i])
  assert(not seen[signature])
  seen[signature]=true
 end
end)

check('G4 original study preserved',function()
 local original=G.manifest()
 assert(G.assert_manifest(original))
 eq(#original,14)
 local b=B.manifest()
 eq(b[1].mode,'reactive')
 eq(b[2].mode,'fixed')
end)

check('no changes to Farkle or matching dice source',function()
 local Rules=require('src.farkle.rules')
 eq(Rules.points.single[1],10)
 local r=X.play(14001,'reactive','balanced','first')
 local f=X.play(14001,'fixed','balanced','first')
 eq(r.banked,f.banked)
 eq(r.busts,f.busts)
 assert(r.winner and f.winner)
end)

print('PASS EX-002 G4b suite: '..n..' scenarios')
