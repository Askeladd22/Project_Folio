-- Regressions for the unapproved, isolated Incontri e Segni A/B/C lab.
local Bag=require('experiments.signs_lab.bag')
local Encounter=require('experiments.signs_lab.encounter')
local Turn=require('experiments.signs_lab.farkle_turn')
local Sim=require('experiments.signs_lab.simulate')
local Rules=require('src.gameplay.farkle.rules')
local Fixture=require('experiments.signs_lab.fixture')

local function always_low(lo,hi)
 assert(lo and hi and hi>=lo)
 return lo
end

local bag=Bag.new(Fixture.signs,always_low)
local seen={}
for i=1,#Fixture.signs do
 local shown=bag:announce()
 assert(shown.category and shown.strength==nil and shown.id==nil,
  'bag announcement leaked the hidden force')
 local ok=pcall(function() bag:announce() end)
 assert(not ok,'sign must not be consumed twice by physical settling')
 local n=select(1,bag:count())
 assert(n==#Fixture.signs-i,'sign is removed only once on announcement')
 local resolved=bag:resolve()
 assert(not seen[resolved.id],'bag reinserted a sign before exhausting all')
 seen[resolved.id]=true
 assert(shown.category==resolved.category)
end
assert(bag:count()==0,'all six signs must be in discard')
local more=bag:announce()
assert(more.recycle_count==1,'bag must recycle only when empty')
assert(bag:resolve().id and bag.cycles==1)
assert(bag.draws==#Fixture.signs+1)
assert(not pcall(function() bag:resolve() end),
 'a sign cannot resolve more than once')

local function fresh(category,strength,overrides)
 local fixture={
  signs={{id=category,category=category,strength=strength}},
  target_wins=3,max_hands=6,occasion_margin=25,
  assault_farkle_enemy_marks=2,
 }
 if overrides then
  for k,v in pairs(overrides) do fixture[k]=v end
 end
 return Encounter.new(fixture,always_low)
end

local occasion=fresh('occasione',35)
assert(not pcall(function() occasion:resolve({banked=100,farkle=false}) end),
 'a physical settle event must not resolve an unannounced sign')
assert(occasion.hands==0 and occasion.bag.draws==0)
local announced=occasion:announce()
assert(announced.strength==nil and announced.category=='occasione')
assert(not pcall(function() occasion:resolve({banked=30,farkle=true}) end))
assert(occasion.hands==0 and occasion.bag.draws==1,
 'invalid Farkle bank must not consume pending sign')
local one=occasion:resolve({banked=60,farkle=false})
assert(one.player_marks==2 and one.marks==2,
 'occasione should award two marks only at fixture margin')
assert(not one.finished)
occasion:announce()
local two=occasion:resolve({banked=35,farkle=false})
assert(two.marks==1 and two.finished and two.winner=='player')
assert(occasion.bag.cycles==1)
assert(not pcall(function() occasion:announce() end),
 'ended experimental encounter cannot draw signs')

local assault=fresh('assalto',20)
assault:announce()
local bust=assault:resolve({banked=0,farkle=true})
assert(bust.marks==2 and bust.enemy_marks==2)
assault:announce()
local loss=assault:resolve({banked=10,farkle=false})
assert(loss.enemy_marks==3 and loss.winner=='enemy',
 'assault Farkle rule is specific to lab fixture')
local guard=fresh('guardia',40,{max_hands=2})
guard:announce()
assert(guard:resolve({banked=40,farkle=false}).marks==1)
guard:announce()
local tie=guard:resolve({banked=39,farkle=false})
assert(tie.finished and tie.winner=='tie','same success count must tie')

-- Source of truth remains production Farkle. No homegrown scoring tables.
local all_ones=Turn.play(function(a,b)
 assert(a==1 and b==6)
 return 1
end,'prudent','assalto')
assert(not all_ones.farkle and all_ones.banked==
 Rules.score({1,1,1,1,1,1}),
 'virtual experiment must take official 6x1 Farkle score')
local misses={2,3,4,6,2,3};local j=0
local farkle=Turn.play(function()
 j=j+1
 return misses[(j-1)%6+1]
end,'audace','guardia')
assert(farkle.farkle and farkle.banked==0 and farkle.rolls==1)

for _,strategy in ipairs(Sim.policies) do
 assert(Turn.decision(strategy,{points=0,can_bank=false,rolls=1,
  free_after=4,category='assalto'})=='roll',
  'no policy may override official Farkle banking requirements')
end
assert(Turn.decision('reattiva',{points=40,can_bank=true,
 rolls=1,free_after=3,category='assalto'})=='bank')
assert(Turn.decision('reattiva',{points=40,can_bank=true,
 rolls=1,free_after=3,category='occasione'})=='roll',
 'visible category must permit a different stop/reroll tradeoff')

local a=Sim.run('C','reattiva',20261031)
local b=Sim.run('C','reattiva',20261031)
for _,key in ipairs{'hands','rolls','banked','bust','winner',
 'player_marks','enemy_marks','disagreements'} do
 assert(a[key]==b[key],'same seed produced different '..key)
end
assert(a.hands>=1 and a.hands<=Fixture.max_hands)
assert(#a.sign_history==a.hands)
local totals=0
for _,entry in ipairs(a.sign_history) do
 assert(entry.strength>0 and entry.hand>0)
 totals=totals+entry.banked
end
assert(totals==a.banked,'sign effects must not replace or mutate banked Farkle points')

local rows=Sim.compare(3,30401)
assert(#rows==9,'three control modes by three risk policies required')
for _,row in ipairs(rows) do
 assert(row.samples==3 and row.hands>=3 and row.rolls>=row.hands)
 assert(row.bank_choices>=0 and row.roll_choices>=0)
 assert(row.success>=0 and row.success<=3)
end
local entry=assert(io.open('main.lua')):read('*a')
assert(not entry:find('experiments.signs_lab',1,true),
 'experimental encounter must never load into production entry')
local controller=assert(io.open('src/features/farkle/controller.lua')):read('*a')
assert(not controller:find('experiments.signs_lab',1,true),
 'experimental signs must not modify live Farkle controller')
print('PASS isolated signs lab: blind draw/resolve, no repeat, recycle, official Farkle, variants, paired-seed replay, no production hooks')
