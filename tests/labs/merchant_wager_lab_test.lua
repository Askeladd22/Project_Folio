-- Regressions for the isolated "Il Mercante e la posta" lab.
local Rules=require('src.farkle.rules')
local Match=require('experiments.merchant_wager_lab.match')
local Merchant=require('experiments.merchant_wager_lab.merchant')
local Simulate=require('experiments.merchant_wager_lab.simulate')
local Log=require('experiments.merchant_wager_lab.log')
local Config=require('experiments.merchant_wager_lab.config')
local Analysis=require('experiments.merchant_wager_lab.analysis')

local function deep_copy(v)
 if type(v)~='table' then return v end
 local out={};for k,x in pairs(v) do out[k]=deep_copy(x) end;return out
end
local function same(a,b)
 if type(a)~='table' or type(b)~='table' then return a==b end
 for k,v in pairs(a) do if not same(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
local points_before=deep_copy(Rules.points)
local functions_before={};for k,v in pairs(Rules) do if type(v)=='function' then functions_before[k]=v end end

-- Scripted dice: the match draws values in order from this queue.
local function script(m,faces)
 local queue={};for i,v in ipairs(faces) do queue[i]=v end
 local function next_value(lo,hi) local v=assert(table.remove(queue,1),'script exhausted');assert(v>=lo and v<=hi);return v end
 m.random=next_value;m.random_player=next_value;m.random_merchant=next_value
end
local function select(m,ids) for _,i in ipairs(ids) do assert(Match.toggle(m,i)) end end
local function farkle_player(m) script(m,{2,3,4,6,2,3});assert(Match.roll(m));assert(m.phase=='merchant') end

-- Configuration is isolated and matches the brief.
assert(Config.starting_sheets==4 and Config.opening_stake==1 and Config.win_threshold==80 and Config.max_rounds==3)
assert(Config.merchant_dice==3 and Config.merchant_rerolls==1 and Config.raise_threshold==30)
assert(Config.variants.A.player_start==0 and Config.variants.A.merchant_start==0 and Config.variants.A.opening_stake==1)
assert(Config.variants.B.player_start==0 and Config.variants.B.merchant_start==30 and Config.variants.B.opening_stake==1)
assert(Config.variants.C.player_start==0 and Config.variants.C.merchant_start==0 and Config.variants.C.opening_stake==2)

-- Opening stake and sheet tokens.
local m=Match.new(7)
assert(m.reserve.player==3 and m.reserve.merchant==3 and m.pot==2 and m.max_pot==2 and Match.total_sheets(m)==8)
assert(m.deposited.player==1 and m.deposited.merchant==1 and m.round==1 and m.phase=='player')
assert(not Match.can_bank(m) and not Match.can_take(m) and not Match.can_see(m) and not Match.can_pass(m) and Match.can_roll(m))
local bmatch=Match.new(7,'B')
assert(bmatch.score.player==0 and bmatch.score.merchant==30 and bmatch.config.initial_merchant_score==30)
assert(bmatch.reserve.player==3 and bmatch.reserve.merchant==3 and bmatch.pot==2 and Match.total_sheets(bmatch)==8)
local cmatch=Match.new(7,'C')
assert(cmatch.score.player==0 and cmatch.score.merchant==0)
assert(cmatch.deposited.player==2 and cmatch.deposited.merchant==2 and cmatch.reserve.player==2 and cmatch.reserve.merchant==2)
assert(cmatch.pot==4 and cmatch.initial_pot==4 and Match.total_sheets(cmatch)==8,'C has four total sheets per contender')
farkle_player(cmatch);script(cmatch,{1,1,1});assert(Match.play_merchant(cmatch))
assert(cmatch.phase=='raise' and cmatch.pot==5 and Match.total_sheets(cmatch)==8)
assert(Match.see(cmatch) and cmatch.pot==6 and Match.total_sheets(cmatch)==8,
 'C raise and see only move existing sheets')
local b_round=Match.new(8,'B')
assert(b_round.score.merchant==30 and #b_round.player_decisions==0,'B score is initial data, not a fake turn')
farkle_player(b_round);script(b_round,{2,3,4});assert(Match.play_merchant(b_round))
assert(b_round.phase=='player' and b_round.round==2 and b_round.score.merchant==30,
 'initial lead does not skip the full-round finish check')

-- Player and Merchant have independent streams; extra draws by one do not shift the other.
local r1=Match.new_rng(177);local r2=Match.new_rng(177)
local merchant1=Match.new_rng(1+((177*48271)%2147483646))
local merchant2=Match.new_rng(1+((177*48271)%2147483646))
for _=1,20 do r1(1,6) end
assert(merchant1(1,6)==merchant2(1,6))
local player1=Match.new_rng(177);local player2=Match.new_rng(177)
for _=1,20 do merchant1(1,6) end
assert(player1(1,6)==player2(1,6))

-- Player score integrity: production combinations, set aside, then bank.
script(m,{1,1,1,2,3,4})
assert(Match.roll(m) and m.phase=='player' and m.turn.phase=='ready')
assert(not Match.can_roll(m),'must set aside before rerolling')
select(m,{1,2,3});assert(Match.selection_points(m)==Rules.score({1,1,1}) and Match.selection_points(m)==75)
assert(Match.take(m) and m.turn.pot==75 and Rules.count_free(m.turn)==3)
script(m,{5,2,3});assert(Match.roll(m) and m.stats.player_rerolls==1 and m.stats.player_rolls==2)
select(m,{4});assert(Match.can_bank(m));assert(Match.bank(m))
assert(m.score.player==80 and m.phase=='merchant','bank adds turn points to match score only')
assert(not Match.can_roll(m) and not Match.can_bank(m),'no player commands during Merchant turn')

-- Reaching the threshold waits for the end of the full round.
script(m,{2,3,4});assert(Match.play_merchant(m))
assert(m.phase=='over' and m.end_reason=='threshold' and m.rounds_played==1 and m.winner=='player')
assert(m.reserve.player==5 and m.reserve.merchant==3 and m.pot==0 and m.stats.merchant_farkles==1)

-- Player Farkle after a reroll loses only the provisional turn total.
m=Match.new(7)
script(m,{1,2,3,4,6,6});assert(Match.roll(m));select(m,{1});assert(Match.take(m) and m.turn.pot==10)
script(m,{2,3,4,6,6});assert(Match.roll(m))
assert(m.phase=='merchant' and m.score.player==0 and m.stats.player_farkles==1)

-- Merchant: best valid selection, one reroll at most, Farkle on reroll.
local r=Merchant.play((function() local q={1,2,3,5,2} return function() return table.remove(q,1) end end)(),Config)
assert(not r.farkle and r.banked==15 and r.rerolls==1 and #r.steps==2,'single 1, then single 5; stop with one free die')
r=Merchant.play((function() local q={1,2,3,2,3} return function() return table.remove(q,1) end end)(),Config)
assert(r.farkle and r.banked==0 and r.lost==10)
r=Merchant.play((function() local q={2,3,4} return function() return table.remove(q,1) end end)(),Config)
assert(r.farkle and #r.steps==1)
r=Merchant.play((function() local q={1,1,1} return function() return table.remove(q,1) end end)(),Config)
assert(not r.farkle and r.banked==75 and r.rerolls==0,'no free dice, no reroll')
assert(Merchant.best({5,5,5}).points==50 and Merchant.best({1,5,6}).points==15 and Merchant.best({2,2,6})==nil)
local limited={};for k,v in pairs(Config) do limited[k]=v end;limited.merchant_rerolls=0
r=Merchant.play((function() local q={1,2,3} return function() return table.remove(q,1) end end)(),limited)
assert(r.banked==10 and #r.steps==1 and r.rerolls==0,'reroll limit is configurable and respected')

-- Raise, see, then pass on a second raise.
m=Match.new(11)
farkle_player(m);script(m,{1,1,1});assert(Match.play_merchant(m))
assert(m.phase=='raise' and m.score.merchant==75 and m.stats.raises==1)
assert(m.pot==3 and m.reserve.merchant==2 and m.deposited.merchant==2 and m.max_pot==3)
assert(not Match.can_roll(m) and Match.can_see(m) and Match.can_pass(m))
assert(Match.see(m) and m.pot==4 and m.reserve.player==2 and m.round==2 and m.phase=='player' and m.stats.accepted==1)
farkle_player(m);script(m,{1,1,1});assert(Match.play_merchant(m))
assert(m.phase=='over' and m.end_reason=='threshold','150 ends after round 2: no raise without a next player turn')
assert(m.stats.raises==1 and m.stats.raise_blocked_end==1 and m.winner=='merchant' and m.reserve.merchant==6)

m=Match.new(11)
farkle_player(m);script(m,{1,1,1});assert(Match.play_merchant(m) and m.phase=='raise')
assert(Match.pass(m) and m.phase=='over' and m.winner=='merchant' and m.end_reason=='pass')
assert(m.reserve.merchant==5 and m.reserve.player==3 and m.pot==0 and m.stats.declined==1 and Match.total_sheets(m)==8)
assert(not Match.can_see(m) and not Match.can_roll(m))

-- Below the raise threshold the Merchant holds.
m=Match.new(11)
farkle_player(m);script(m,{1,2,3,5,2});assert(Match.play_merchant(m))
assert(m.phase=='player' and m.round==2 and m.pot==2 and m.stats.raises==0)

-- No raise when a contender has no free sheet.
m=Match.new(11,{starting_sheets=1})
farkle_player(m);script(m,{1,1,1});assert(Match.play_merchant(m))
assert(m.phase=='player' and m.stats.raises==0 and m.stats.raise_blocked_sheets==1)

-- Three full rounds, tie, raised stakes returned to their depositors.
m=Match.new(13)
farkle_player(m);script(m,{4,4,4});assert(Match.play_merchant(m) and m.phase=='raise');assert(Match.see(m))
script(m,{4,4,4,2,3,6});assert(Match.roll(m));select(m,{1,2,3});assert(Match.bank(m) and m.score.player==40)
script(m,{2,3,4});assert(Match.play_merchant(m) and m.phase=='player' and m.round==3)
farkle_player(m);script(m,{2,3,4});assert(Match.play_merchant(m))
assert(m.phase=='over' and m.end_reason=='max_rounds' and m.rounds_played==3 and m.winner=='tie')
assert(m.reserve.player==4 and m.reserve.merchant==4 and m.pot==0 and m.max_pot==4)

-- Many seeded matches: conservation, full rounds, termination and reproducibility.
for seed=1,300 do
 for _,policy in ipairs(Simulate.policies) do
  local a=Simulate.play(seed,policy,'passo_se_dietro')
  assert(a.phase=='over' and Match.total_sheets(a)==8 and a.pot==0)
  assert(a.reserve.player>=0 and a.reserve.merchant>=0)
  assert(a.end_reason=='pass' or a.rounds_played==a.config.max_rounds or
   a.score.player>=80 or a.score.merchant>=80,'early end only by threshold or pass')
  assert(a.stats.accepted+a.stats.declined==a.stats.raises)
  assert(a.stats.raises<=a.config.max_rounds-1)
  assert(a.stats.merchant_rerolls<=a.rounds_played*a.config.merchant_rerolls,'Merchant reroll limit')
 end
end
local a=Simulate.play(4242,Simulate.policies[2],'vedo_sempre')
local b=Simulate.play(4242,Simulate.policies[2],'vedo_sempre')
assert(same(a.decisions,b.decisions) and same(Match.record(a,1),Match.record(b,1)),'same seed, same match')
assert(#a.player_decisions>0 and a.player_decisions[1].action=='lancia')
assert(a.player_decisions[1].score_diff==a.player_decisions[1].merchant_score-a.player_decisions[1].player_score)
local found_roll_outcome=false
for _,d in ipairs(a.player_decisions) do
 if d.action=='rilancia' then assert(d.roll_outcome~='');found_roll_outcome=true end
end
assert(found_roll_outcome,'reroll decision includes the following roll result')
local rng1,rng2=Match.new_rng(99),Match.new_rng(99)
for _=1,50 do assert(rng1(1,6)==rng2(1,6)) end
local seeded1,seeded2=Match.new(123,'A'),Match.new(123,'A')
for _=1,50 do assert(seeded1.random_player(1,6)==seeded2.random_player(1,6)) end
local merchant_a,merchant_b=Match.new(456,'A'),Match.new(456,'B')
for _=1,50 do assert(merchant_a.random_merchant(1,6)==merchant_b.random_merchant(1,6),
 'variant changes must not perturb the Merchant dice stream') end
local mixed_a,mixed_b=Match.new(789,'A'),Match.new(789,'C')
for _=1,15 do mixed_a.random_player(1,6) end
for _=1,20 do assert(mixed_a.random_merchant(1,6)==mixed_b.random_merchant(1,6),
 'player draws cannot shift Merchant stream') end
local mixed_c,mixed_d=Match.new(987,'A'),Match.new(987,'C')
for _=1,15 do mixed_c.random_merchant(1,6) end
for _=1,20 do assert(mixed_c.random_player(1,6)==mixed_d.random_player(1,6),
 'Merchant draws cannot shift player stream') end

-- CSV log: escaping, header once, separate files, next id.
assert(Log.line({1,'a,b','q"x'})=='1,"a,b","q""x"\n')
local files={}
local fs={getInfo=function(f) return files[f] and {} or nil end,read=function(f) return files[f] end,
 write=function(f,s) files[f]=s;return true end,append=function(f,s) files[f]=files[f]..s;return true end}
assert(Log.next_id(fs)==1)
Log.save(fs,a,Match.record(a,1));Log.save(fs,b,Match.record(b,2))
assert(Log.next_id(fs)==3 and Log.MATCH_FILE~='runs.csv' and Log.DECISION_FILE~='runs.csv')
assert(files[Log.MATCH_FILE]:sub(1,#'id,seed,rounds')=='id,seed,rounds')
local _,headers=files[Log.DECISION_FILE]:gsub('id,seed,step,round','')
assert(headers==1,'header written once')
local legacy_matches_before=files[Log.MATCH_FILE]
assert(Log.next_id_v2(fs)==1)
local v2=Match.record(a,1);v2.variant='A';v2.initial_pot=2;v2.merchant_initial_score=0
Log.save_v2(fs,a,v2)
assert(Log.next_id_v2(fs)==2 and Log.MATCH_FILE_V2~='runs.csv' and Log.DECISION_FILE_V2~='runs.csv')
Log.save_feedback(fs,{id=1,variant='A',seed=4242,pressure='moderate',banking_influenced='yes',
 main_influence='score_lead',notes='test, note'})
assert(files[Log.FEEDBACK_FILE]:find('1,A,4242,moderate,yes,score_lead,"test, note"',1,true))
assert(files[Log.MATCH_FILE]:find('id,seed,rounds',1,true) and files[Log.MATCH_FILE_V2]:find('id,variant,seed',1,true))
assert(files[Log.DECISION_FILE_V2]:find('score_diff_merchant_minus_player',1,true))
assert(files[Log.DECISION_FILE_V2]:find('valido',1,true) or files[Log.DECISION_FILE_V2]:find('Farkle',1,true))
assert(files[Log.MATCH_FILE]==legacy_matches_before,'versioned logging leaves existing CSV data untouched')
local report,analyzed=Analysis.run(fs)
assert(report:find('A: partite',1,true) and analyzed[1].games==1 and analyzed[1].feedback_count==1)
assert(files[Log.SUMMARY_FILE]:find('variant,games,player_wins',1,true))
local summary=Analysis.summarize({
 {id='1',variant='A',winner='player',player_score='50',merchant_score='20',player_rerolls='2',player_farkles='1',merchant_farkles='0',raises='1'},
 {id='2',variant='A',winner='merchant',player_score='10',merchant_score='40',player_rerolls='4',player_farkles='2',merchant_farkles='1',raises='0'},
 {id='3',variant='B',winner='tie',player_score='30',merchant_score='30',player_rerolls='1',player_farkles='0',merchant_farkles='2',raises='2'},
},{{id='1',variant='A',pressure='strong',banking_influenced='yes'},
 {id='2',variant='A',pressure='none',banking_influenced='no'}})
assert(summary[1].games==2 and summary[1].player_wins==1 and summary[1].player_losses==1)
assert(summary[1].player_win_pct==50 and summary[1].avg_player_score==30 and summary[1].avg_merchant_score==30)
assert(summary[1].avg_player_rerolls==3 and summary[1].avg_player_farkles==1.5 and summary[1].avg_merchant_farkles==0.5)
assert(summary[1].banking_yes_pct==50 and summary[1].pressure_none==1 and summary[1].pressure_strong==1)
assert(summary[2].games==1 and summary[2].ties==1)

-- Production rules untouched; lab never hooked into production or its run log.
assert(same(points_before,Rules.points),'lab must not alter production scoring table')
for k,v in pairs(functions_before) do assert(Rules[k]==v,'lab replaced production rule '..k) end
local function read(path) local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
for _,file in ipairs({'main.lua','conf.lua','match.lua','merchant.lua','log.lua','simulate.lua','config.lua'}) do
 local src=read('experiments/merchant_wager_lab/'..file)
 assert(not src:find('runs.csv',1,true),file..' must not write the production run log')
 assert(not src:find('Rules%.[%w_]+%s*=[^=]'),file..' must not reassign production rules')
end
assert(read('experiments/merchant_wager_lab/conf.lua'):find("t.identity='project-folio-merchant-wager-lab'",1,true))
for _,file in ipairs({'main.lua','src/farkle/rules.lua','src/farkle/controller.lua','src/core/renderer_lab_boot.lua'}) do
 assert(not read(file):find('merchant_wager_lab',1,true),file..' must not load the experiment')
end
print('PASS merchant wager lab: scoring, Farkle, reroll limit, sheets, raise/see/pass, full rounds, tie refund, seed replay, CSV, production rules untouched')
