-- EX-TP-001 deterministic headless smoke and invariant checks.
local E=require('experiments.tre_prove_reserve_lab.engine')
local S=require('experiments.tre_prove_reserve_lab.simulate')
local Rules=require('src.farkle.rules')
local tests={}
local function test(name,fn) tests[#tests+1]={name,fn} end
test('public state and three zeroed lanes',function()
  local s=E.new(2026,8,2)
  assert(#s.lanes==3 and s.reserve==8 and s.round==1 and s.phase=='dice')
  assert(s.lanes[1].player==0 and s.lanes[2].rival==0)
end)
test('configuration validation',function()
  assert(not pcall(E.new,0,8,2))
  assert(not pcall(E.new,1,11,2))
  assert(not pcall(E.new,1,8,3))
end)
test('proof closes at four and cannot be rewritten',function()
  local s=E.new(1,8,2)
  assert(E.place(s,'player',1,3))
  assert(E.place(s,'player',1,2)) -- legal overshoot is clamped
  assert(s.lanes[1].player==4 and s.lanes[1].owner=='player')
  assert(not E.place(s,'rival',1,1))
  assert(not E.place(s,'player',1,1))
end)
test('cannot spend beyond cap through placement',function()
  local s=E.new(1,8,1)
  assert(not E.place(s,'rival',1,2))
  assert(E.place(s,'rival',1,1))
end)
test('canonical Farkle causes rival reply',function()
  local s=E.new(121,8,2)
  assert(E.roll(s,{2,3,4,6,2,3}))
  assert(s.phase=='rival' and s.metrics.busts==1)
  assert(E.rival(s,'aggressive'))
  assert(s.metrics.spent>=1 and s.reserve<8)
end)
test('canonical 40 points banks exactly 2 seals',function()
  local s=E.new(132,8,2)
  assert(E.roll(s,{1,3,3,3,4,6}))
  assert(E.take(s,15)) -- 1 + 3 threes = 10+30
  assert(s.turn.pot==40)
  assert(E.bank(s) and s.marks==2 and s.phase=='claim')
  assert(E.claim(s,2))
  assert(s.lanes[2].player==2 and s.phase=='rival')
end)
test('canonical hot dice can reroll',function()
  local s=E.new(144,8,2)
  assert(E.roll(s,{1,1,1,1,1,1}))
  assert(E.take(s,63))
  assert(s.turn.hot and Rules.can_roll(s.turn) and s.metrics.hot==1)
end)
test('no illegal claim or double reply',function()
  local s=E.new(222,8,2)
  assert(not E.claim(s,1))
  assert(not E.rival(s,'balanced'))
  s.phase='claim';s.marks=2
  assert(not E.claim(s,0) and not E.claim(s,4))
  assert(E.claim(s,1))
  assert(not E.claim(s,2))
  assert(E.rival(s,'balanced'))
  assert(not E.rival(s,'balanced'))
end)
test('rival cannot spend negative or beyond reserve',function()
  for _,policy in ipairs(S.rivals) do
    local s=E.new(1,1,2);s.phase='rival'
    assert(E.rival(s,policy))
    assert(s.reserve>=0 and s.reserve<=1 and s.metrics.spent<=1)
  end
end)
test('zero reserve forces pass even after Farkle',function()
  local s=E.new(1,0,2);s.phase='rival'
  assert(E.rival(s,'aggressive'))
  assert(s.reserve==0 and s.metrics.spent==0)
  assert(s.metrics.rival_actions==1 and s.metrics.eligible==0)
end)
test('local majorities and ties at expiry',function()
  local s=E.new(1,8,2)
  assert(E.result(s)=='draw')
  assert(E.place(s,'player',1,2))
  assert(E.result(s)=='player')
  assert(E.place(s,'rival',2,2))
  assert(E.result(s)=='draw')
end)
test('two closed proofs win immediately with no extra rival action',function()
  local s=E.new(1,8,2)
  assert(E.place(s,'player',1,3))
  assert(E.place(s,'player',2,3))
  s.phase='claim';s.marks=1
  assert(E.claim(s,1));assert(s.phase=='rival')
  assert(E.rival(s,'conserve'))
  if s.phase=='round_end' then assert(E.next_round(s)) end
  s.phase='claim';s.marks=1
  assert(E.claim(s,2))
  assert(s.phase=='finished' and s.winner=='player')
end)
test('player policy decisions choose legal open lanes',function()
  local s=E.new(2,8,2);s.marks=3;s.phase='claim'
  for _,p in ipairs(S.players) do
    for _,r in ipairs(S.rivals) do
      local id=S.choose_lane(s,p,r)
      assert(id and id>=1 and id<=3)
    end
  end
end)
test('same seed reproduces exact trace and winner',function()
  local a=S.play(2026,8,2,'aware','balanced')
  local b=S.play(2026,8,2,'aware','balanced')
  assert(a.winner==b.winner and a.reserve==b.reserve and a.round==b.round)
  assert(#a.events==#b.events)
  for i=1,#a.events do
    local x,y=a.events[i],b.events[i]
    assert(x.action==y.action and x.round==y.round and x.lane==y.lane and x.amount==y.amount)
  end
end)
test('every paired cell runs within five rounds',function()
  for _,conf in ipairs(S.configs) do
    for _,p in ipairs(S.players) do for _,r in ipairs(S.rivals) do
      local s=S.play(1001,conf[1],conf[2],p,r)
      assert(s.round<=5 and s.reserve>=0 and s.winner)
    end end
  end
end)
local passed=0
for _,pair in ipairs(tests) do
  local ok,err=pcall(pair[2])
  if not ok then error('FAIL '..pair[1]..': '..tostring(err)) end
  passed=passed+1
  print('PASS '..pair[1])
end
print(string.format('EX-TP-001: %d/%d tests PASS',passed,#tests))
