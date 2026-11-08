local E=require('experiments.encounter_ac_lab.engine')
local S=require('experiments.encounter_ac_lab.simulate')
local Rules=require('src.farkle.rules')
local count=0
local function check(name,fn) fn();count=count+1;print('PASS A/C '..name) end
local function ready(mode,seed)
 for n=seed,seed+50 do
  local s=E.new(mode,n)
  if E.roll(s) and s.phase=='dice' then return s end
 end
 error('unable to find valid first roll')
end
local function first_bank(mode)
 local s=ready(mode,111)
 local o=assert(Rules.options(s.turn)[1])
 for _,id in ipairs(o.ids) do assert(E.toggle(s,id)) end
 assert(E.can_bank(s))
 assert(E.bank(s))
 return s
end
check('no change to canonical Farkle points',function()
 assert(Rules.points.single[1]==10)
 assert(Rules.points.kind[3][1]==75)
 assert(Rules.points.kind[6][6]==750)
end)
check('identical seeded physical face stream for A and C',function()
 local a,c=E.new('A',123),E.new('C',123)
 E.roll(a);E.roll(c)
 for id=1,6 do assert(a.turn.hand[id]==c.turn.hand[id]) end
end)
check('Farkle selection obeys production evaluator',function()
 local s=ready('A',111)
 local option=Rules.options(s.turn)[1]
 for _,id in ipairs(option.ids) do assert(E.toggle(s,id)) end
 assert(Rules.selection(s.turn)==option.points)
 assert(E.bank(s))
 assert(not E.roll(s),'dice disabled during offer')
end)
check('A: split and opponent chooses exactly one competing offer',function()
 local s=first_bank('A')
 assert(s.phase=='offer')
 local pair=E.PAIRS[s.pair]
 local total=s.offered_marks
 assert(total>=2 and total<=5)
 assert(not E.split(s,-100))
 while s.left>1 do assert(E.split(s,-1)) end
 assert(not E.split(s,-1))
 local left=s.left
 assert(E.resolve_offer(s))
 local player=s.lanes[pair[1]].player+s.lanes[pair[2]].player
 local rival=s.lanes[pair[1]].rival+s.lanes[pair[2]].rival
 assert(player+rival==total)
 assert(player>0 and rival>0)
 assert(left==1)
 assert(not E.resolve_offer(s))
 assert(s.phase=='round_end' or s.phase=='finished')
end)
check('A: each offer includes two different proofs',function()
 local s=first_bank('A')
 local seen={}
 for _=1,3 do
  local p=E.PAIRS[s.pair]
  assert(p[1]~=p[2])
  seen[p[1]..':'..p[2]]=true
  assert(E.pair_next(s))
 end
 assert(seen['1:2'] and seen['1:3'] and seen['2:3'])
end)
check('C: claims lock at four marks and cannot be overwritten',function()
 local s=first_bank('C')
 assert(s.phase=='claim' and s.claim_marks>=1 and s.claim_marks<=3)
 assert(not E.claim(s,0))
 local before=s.claim_marks
 assert(E.claim(s,1))
 assert(s.lanes[1].player==before)
 assert(s.phase=='round_end' or s.phase=='finished')
 assert(not E.claim(s,1))
 local x=E.new('C',1)
 x.lanes[2].player=3
 x.phase='claim';x.claim_marks=2
 assert(E.claim(x,2))
 assert(x.lanes[2].owner=='player')
 assert(not E.claim(x,2))
end)
check('invalid inputs never advance state',function()
 local s=E.new('A',100)
 assert(not E.bank(s))
 assert(not E.resolve_offer(s))
 assert(not E.next_round(s))
 assert(not E.claim(s,1))
 assert(not E.split(s,1))
 assert(not E.pair_next(s))
end)
check('both experiments terminate, preserve same seed and avoid phantom phases',function()
 for _,mode in ipairs({'A','C'}) do
  for _,policy in ipairs({'prudent','balanced','daring'}) do
   for seed=101,115 do
    local s=S.play(mode,seed,policy)
    assert(s.phase=='finished')
    assert(s.winner=='player' or s.winner=='rival' or s.winner=='draw')
    assert(s.round<=s.max_rounds)
    for _,l in ipairs(s.lanes) do
     assert(l.player>=0 and l.rival>=0)
     assert(l.owner==nil or mode=='C')
    end
    local b=S.play(mode,seed,policy)
    assert(s.winner==b.winner and s.banked==b.banked and s.busts==b.busts)
    assert(#s.events==#b.events)
    for i=1,#s.events do
     local a,c=s.events[i],b.events[i]
     assert(a.action==c.action and a.detail==c.detail and a.round==c.round)
    end
   end
  end
 end
end)
check('paired simulations report all six configurations',function()
 local rows=S.compare(5,1100)
 assert(#rows==3)
 for _,r in ipairs(rows) do
  for _,mode in ipairs({'A','C'}) do
   local b=r[mode]
   assert(b.player+b.rival+b.draw==5)
  end
 end
 assert(S.report(3,101):find('prudent A',1,true))
end)
print('PASS Encounter A/C: '..count..' cases')
