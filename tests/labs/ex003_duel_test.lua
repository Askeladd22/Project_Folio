-- EX-003 research-only, executable in Lua 5.4 and LuaJIT.
-- Invariants, legal Farkle, opponent genuine turns, paired streams.
local Rules=require('src.farkle.rules')
local E=require('experiments.encounter_ac_lab.engine')
local RNG=require('experiments.merchant_wager_lab.rng')
local P=require('experiments.ex003_duel_lab.policy')
local D=require('experiments.ex003_duel_lab.direct')
local S=require('experiments.ex003_duel_lab.simulate')
local checks=0
local function check(label,fn)
 fn();checks=checks+1;print('PASS EX-003 '..label)
end
local function equal(a,b)
 assert(a==b,tostring(a)..' ~= '..tostring(b))
end

check('original Farkle score, six D6 and risk rules',function()
 equal(Rules.points.single[1],10)
 equal(Rules.points.single[5],5)
 equal(Rules.points.kind[3][1],75)
 equal(Rules.points.kind[6][6],750)
 local t=Rules.new('control')
 equal(Rules.count_free(t),6)
end)

check('public situational rule can change the STOP decision in both arms',function()
 local d={round=3,own_score=120,other_score=50}
 equal(P.threshold('D','situational',d),30)
 assert(P.wants_bank('D','situational',d,50,3))
 assert(not P.wants_bank('D','balanced',d,50,3))
 d={round=5,own_score=30,other_score=75}
 equal(P.threshold('D','situational',d),110)
 assert(not P.wants_bank('D','situational',d,65,3))
 assert(P.wants_bank('D','balanced',d,65,3))
 local c={round=2,lanes={{player=2,rival=0},{player=0,rival=0},
  {player=0,rival=0}}}
 equal(P.threshold('C','situational',c),40)
 assert(P.wants_bank('C','situational',c,50,3))
 assert(not P.wants_bank('C','balanced',c,50,3))
 c.lanes[2].rival=3
 equal(P.threshold('C','situational',c),90)
 assert(not P.wants_bank('C','situational',c,65,3))
 assert(P.wants_bank('C','balanced',c,65,3))
end)

check('D and C reuse same player dice at start of same round',function()
 local seed=16004
 local c=E.new('C',seed)
 c.random=RNG.new_rng(P.stream_seed(seed,1,1))
 assert(E.roll(c))
 local turn=Rules.new('control')
 local rng=RNG.new_rng(P.stream_seed(seed,1,1))
 assert(Rules.start(turn))
 local faces={}
 for _,id in ipairs(turn.active) do faces[id]=rng(1,6) end
 assert(Rules.settle(turn,faces))
 for i=1,6 do equal(c.turn.hand[i],turn.hand[i]) end
end)

check('D rival really rolls, scores, busts and can finish a duel',function()
 local won={player=false,rival=false}
 for seed=16000,16045 do
  local match=D.play(seed,'balanced')
  equal(match.model,'D')
  equal(match.rounds,6)
  equal(#match.trace,6)
  assert(match.player_rolls>=6 and match.rival_rolls>=6)
  local a,b=0,0
  for _,t in ipairs(match.trace) do
   assert(t.player>=0 and t.rival>=0)
   if t.player_bust==1 then equal(t.player,0) end
   if t.rival_bust==1 then equal(t.rival,0) end
   a=a+t.player;b=b+t.rival
   equal(t.player_total,a);equal(t.rival_total,b)
  end
  equal(match.player_banked,a);equal(match.rival_banked,b)
  equal(match.winner,a>b and 'player' or b>a and 'rival' or 'draw')
  won[match.winner]=true
 end
 assert(won.player and won.rival,
  'both Incisore and Rivale must have a real chance to win')
end)

check('no mutation of C public board when evaluating choices',function()
 local s=E.new('C',16009)
 s.phase='claim';s.claim_marks=2
 s.lanes[1].rival=2
 s.lanes[2].player=1
 local signature={}
 for i,l in ipairs(s.lanes) do
  signature[i]=l.player..':'..l.rival..':'..tostring(l.owner)
 end
 local events=#s.events
 local chosen,first=P.choose_claim(s,'situational')
 assert(chosen>=1 and chosen<=3 and first==1)
 equal(#s.events,events)
 for i,l in ipairs(s.lanes) do
  equal(l.player..':'..l.rival..':'..tostring(l.owner),signature[i])
 end
 assert(E.claim(s,chosen))
end)

check('repeatability: all 4 profiles, both arms and seed',function()
 for _,model in ipairs(S.models) do
  for _,profile in ipairs(S.policies) do
   for seed=16011,16015 do
    local a=S.play(model,seed,profile)
    local b=S.play(model,seed,profile)
    for _,field in ipairs({'winner','rounds','player_banked',
     'player_busts','player_rolls','bank_choices',
     'stop_differences','claim_choices','claim_differences'}) do
     equal(a[field],b[field])
    end
    assert(a.winner=='player' or a.winner=='rival' or a.winner=='draw')
    assert(a.rounds<=6 and a.player_banked>=0)
    assert(a.stop_differences<=a.bank_choices)
    assert(a.claim_differences<=a.claim_choices)
    if model=='C' then
     equal(a.rival_rolls,0)
     assert(a.claim_choices<=a.rounds)
    else
     equal(a.rounds,6)
     equal(a.claim_choices,0)
     assert(a.rival_rolls>=6)
    end
   end
  end
 end
end)

check('pilot only uses preregistered seed range and reports 8 cells',function()
 local report=S.pilot(16000,16001)
 assert(report:find('16000..16001',1,true))
 assert(report:find('D within-arm',1,true))
 assert(report:find('C within-arm',1,true))
 assert(report:find('D | situational',1,true))
 assert(report:find('C | situational',1,true))
 assert(not pcall(S.pilot,2000,2001))
 assert(not pcall(S.pilot,16000,16200))
 assert(not pcall(S.play,'C',2000000,'balanced'))
end)

print('PASS EX-003 suite: '..checks..' groups')
