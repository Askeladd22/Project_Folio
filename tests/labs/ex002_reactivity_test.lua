-- EX-002 tests: no production modifications, all checks deterministic.
local E=require('experiments.encounter_ac_lab.engine')
local X=require('experiments.ex002_reactivity_lab.simulate')
local Existing=require('experiments.encounter_ac_lab.simulate')
local Rules=require('src.farkle.rules')
local n=0
local function test(name,fn) fn();n=n+1;print('PASS EX-002 '..name) end
local function equal(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end

local function scenario(mode)
 local s=E.new('C',110,{rival_target_mode=mode})
 s.phase='claim';s.claim_marks=1
 s.lanes[1].rival=1;s.lanes[2].rival=1
 return s
end

test('default C remains explicitly reactive, A unaffected',function()
 for seed=101,130 do
  local a=E.new('C',seed)
  local b=E.new('C',seed,{rival_target_mode='reactive'})
  equal(a.phase,b.phase)
  equal(E.preview_rival_target(a).target,E.preview_rival_target(b).target)
  equal(a.turn.phase,b.turn.phase)
  assert(E.roll(a) and E.roll(b))
  for id=1,6 do equal(a.turn.hand[id],b.turn.hand[id]) end
 end
 assert(E.new('A',101).rival_target_mode=='reactive')
 assert(not pcall(E.new,'A',101,{rival_target_mode='fixed'}))
 assert(not pcall(E.new,'C',101,{rival_target_mode='unexpected'}))
end)

test('fixed and reactive have the same budget and different target',function()
 local r=E.new('C',1,{rival_target_mode='reactive'})
 local f=E.new('C',1,{rival_target_mode='fixed'})
 r.lanes[2].rival=2;f.lanes[2].rival=2
 local rd=assert(E.preview_rival_target(r))
 local fd=assert(E.preview_rival_target(f))
 equal(rd.target,2)
 equal(fd.target,1)
 equal(rd.marks,fd.marks)
 equal(rd.marks,1)
 assert(rd.rule:find('sigilli',1,true))
 assert(fd.rule:find('priorità',1,true))
 r.round=3;f.round=3
 equal(E.preview_rival_target(r).marks,2)
 equal(E.preview_rival_target(f).marks,2)
end)

test('same preclaim board, all legal claims, no source mutation',function()
 local r=scenario('reactive')
 local f=scenario('fixed')
 local original=#r.events
 local cr=X.counterfactuals(r)
 local cf=X.counterfactuals(f)
 equal(cr.legal,3)
 equal(#cr.rows,3)
 equal(cr.legal,cf.legal)
 assert(cr.target_sensitive)
 assert(cr.nonlocking)
 assert(cr.terminal_status_sensitive==false)
 assert(not cf.target_sensitive)
 assert(cf.nonlocking)
 equal(r.phase,'claim')
 equal(#r.events,original)
 equal(r.lanes[1].rival,1)
 equal(r.lanes[2].rival,1)
 local distinct={}
 for _,row in ipairs(cr.rows) do
  distinct[row.rival_target]=true
  assert(row.signature and row.rule and row.candidate_scores)
  assert(row.terminal_status=='unfinished')
 end
 assert(distinct[1] and distinct[2])
end)

test('locking claims classified separately',function()
 local r=scenario('reactive')
 r.lanes[3].player=3
 local cf=X.counterfactuals(r)
 assert(not cf.nonlocking)
 for _,row in ipairs(cf.rows) do
  if row.lane==3 then assert(row.player_locked) end
 end
end)

test('all four strategy/target pairings terminate deterministically',function()
 for seed=101,116 do
  for _,dice in ipairs(X.dice_policies) do
   for _,claims in ipairs(X.claim_policies) do
    for _,mode in ipairs(X.rival_modes) do
     local s,m=X.play(seed,mode,dice,claims)
     local t,u=X.play(seed,mode,dice,claims)
     equal(s.winner,t.winner)
     equal(s.round,t.round)
     equal(s.banked,t.banked)
     equal(s.busts,t.busts)
     equal(m.choice_states,u.choice_states)
     equal(m.target_sensitive,u.target_sensitive)
     assert(s.phase=='finished' and s.round<=6)
     assert(m.legal_claims>=m.choice_states)
     assert(m.nonlocking_target_sensitive<=m.target_sensitive)
     for _,lane in ipairs(s.lanes) do
      assert(lane.player>=0 and lane.rival>=0)
      if lane.owner then
       assert(lane.owner=='player' or lane.owner=='rival')
      end
     end
    end
   end
  end
 end
end)

test('seeded headless writer emits all alternative rows',function()
 local seen,total=0,0
 for seed=201,206 do
  local s,stats=X.play(seed,'reactive','balanced','informed',
   function(round,amount,probe,row,chosen)
    seen=seen+1
    assert(round>=1 and round<=6)
    assert(amount>=1 and amount<=3)
    assert(probe.legal>=1 and probe.legal<=3)
    assert(row.lane>=1 and row.lane<=3)
    assert(chosen>=1 and chosen<=3)
   end)
  assert(s.winner)
  total=total+stats.total_counterfactuals
 end
 equal(seen,total)
end)

test('pilot smoke produces both modes and reports paired difference',function()
 local report=X.pilot(1000,1003)
 assert(report:find('prudent | first | reactive',1,true))
 assert(report:find('balanced | informed | fixed',1,true))
 assert(report:find('paired player win',1,true))
end)

test('existing A/C driver remains callable',function()
 local c=Existing.play('C',333,'balanced')
 local a=Existing.play('A',333,'balanced')
 assert(c.phase=='finished' and a.phase=='finished')
 assert(c.winner and a.winner)
end)
test('EX-002b off-policy stress runs only outside reserved holdout',function()
 local Stress=require('experiments.ex002_reactivity_lab.stress')
 local s,stats=X.play(7000,'reactive','balanced','last')
 assert(s.phase=='finished' and stats.choice_states>=0)
 assert(not pcall(Stress.report,2000,2001))
 local out=Stress.report(7000,7001)
 assert(out:find('EX-002b POST-PILOT',1,true))
 assert(out:find('paired win delta',1,true))
end)
print('PASS EX-002 suite: '..n..' scenarios')
