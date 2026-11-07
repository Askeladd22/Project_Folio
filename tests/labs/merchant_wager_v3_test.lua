-- V3 type-box, probability policy, best-of-three duel and telemetry regressions.
local Box=require('experiments.merchant_wager_lab.box')
local Duel=require('experiments.merchant_wager_lab.duel')
local Match=require('experiments.merchant_wager_lab.match')
local Rules=require('src.farkle.rules')
local Log=require('experiments.merchant_wager_lab.log')
local Presentation=require('experiments.merchant_wager_lab.presentation')

local function counts_match(actual,expected)
 for i=1,5 do assert(actual[i]==expected[i],'unexpected type count '..i) end
end
local rng=Match.new_rng(71)
local box=Box.new(rng)
assert(Box.total(box)==20)
counts_match(Box.remaining(box),{6,5,4,2,3})
for _=1,20 do Box.draw(box);assert(Box.total(box)==20) end
assert(#box.draw_pile==0 and #box.discard==20)
Box.draw(box)
assert(Box.total(box)==20 and #box.draw_pile==19 and #box.discard==1 and box.reshuffles==1)
local remaining,discarded=Box.remaining(box),Box.discarded(box)
for i,count in ipairs({6,5,4,2,3}) do assert(remaining[i]+discarded[i]==count) end

local function card(kind)
 local symbols=Box.symbols
 return {id=symbols[kind].id,kind=kind,points=symbols[kind].points}
end
local pbox={draw_pile={card(4),card(5)},discard={},drawn={},random=Match.new_rng(1)}
assert(math.abs(Box.probability_to_exceed(pbox,30,0)-0.5)<1e-12,
 'V40 beats 30 on half of two possible first draws; X fails the other half')
pbox.draw_pile={card(1),card(2),card(5)}
assert(math.abs(Box.probability_to_exceed(pbox,20,0)-1/3)<1e-12,
 '10 and 20 must both precede X to strictly beat 20')
local before=table.concat((function() local t={};for _,c in ipairs(pbox.draw_pile) do t[#t+1]=c.id end;return t end)(),' ')
local chance_a=Box.probability_to_exceed(pbox,20,0)
local chance_b=Box.probability_to_exceed(pbox,20,0)
assert(chance_a==chance_b and before==table.concat((function() local t={};for _,c in ipairs(pbox.draw_pile) do t[#t+1]=c.id end;return t end)(),' '),
 'probability preview reads public composition without consuming or peeking')
pbox.draw_pile={card(1),card(2)}
assert(Box.probability_to_exceed(pbox,30,0)>0,'empty numeric-only box is followed by the documented discard refill')

local function clean_duel(seed)
 for candidate=seed,seed+100 do
  local d=Duel.new(candidate)
  if d.phase=='player' then return d end
 end
 error('unable to find a seed with a safe opening offer')
end
local d=clean_duel(1)
assert(d.reserve.artist==3 and d.reserve.merchant==3 and d.pot==2 and Duel.total_sheets(d)==8)
assert(d.hands_won.artist==0 and d.hands_won.merchant==0)
local opening_actions=Presentation.actions(d)
assert(#opening_actions==1 and opening_actions[1].id=='v3_roll' and opening_actions[1].primary)
assert(Presentation.keyboard_action(d,'space')=='v3_roll')
assert(Presentation.keyboard_action(d,'a')==nil and Presentation.keyboard_action(d,'c')==nil)
assert(Presentation.keyboard_action(d,'r')=='replay_v3' and Presentation.keyboard_action(d,'escape')=='back_mode')
assert(Presentation.keyboard_action(d,'e')=='box_details')
assert(Presentation.phase_name(d)=='Offerta iniziale')
assert(Presentation.event_message(d):find('Lancia i sei dadi',1,true))
local original_phase=d.phase
d.phase='merchant_decision'
local merchant_actions=Presentation.actions(d)
assert(#merchant_actions==1 and merchant_actions[1].id=='v3_advance')
assert(Presentation.keyboard_action(d,'c')=='v3_advance')
assert(Presentation.keyboard_action(d,'space')==nil)
assert(Presentation.phase_name(d)=='Controfferta del Mercante')
d.phase='hand_end'
local next_actions=Presentation.actions(d)
assert(#next_actions==1 and next_actions[1].id=='v3_next')
assert(Presentation.keyboard_action(d,'n')=='v3_next')
d.phase=original_phase
assert(Presentation.keyboard_action(d,'space',true)==nil)
assert(Presentation.keyboard_action(d,'escape',true)=='box_details')
assert(Presentation.keyboard_action(d,'r',true)=='replay_v3')
local input_duel=clean_duel(1)
local input_faces={1,2,3,4,6,6};local input_index=0
input_duel.player_rng=function() input_index=input_index+1;return input_faces[input_index] end
assert(Duel.roll(input_duel))
local die_action,die_id=Presentation.keyboard_action(input_duel,'1')
assert(die_action=='toggle_die' and die_id==1)
assert(Duel.toggle(input_duel,die_id))
assert(Presentation.keyboard_action(input_duel,'a')=='v3_take')
assert(Presentation.keyboard_action(input_duel,'i')=='v3_bank')
assert(Duel.take(input_duel))
assert(Presentation.keyboard_action(input_duel,'space')=='v3_reroll')
for _,size in ipairs({{1280,720},{1600,900},{1920,1080}}) do
 local viewport=Presentation.viewport(size[1],size[2],1280,720)
 assert(viewport.scale>0 and viewport.x>=0 and viewport.y>=0)
 assert(viewport.x+1280*viewport.scale<=size[1] and viewport.y+720*viewport.scale<=size[2])
end
local seeded_a,seeded_b=Duel.new(177),Duel.new(177)
for _=1,20 do
 assert(seeded_a.player_rng(1,6)==seeded_b.player_rng(1,6))
 assert(Box.draw(seeded_a.box).id==Box.draw(seeded_b.box).id)
end
local independent_a,independent_b=Duel.new(789),Duel.new(789)
for _=1,20 do independent_a.player_rng(1,6) end
for _=1,10 do assert(Box.draw(independent_a.box).id==Box.draw(independent_b.box).id) end
local independent_c,independent_d=Duel.new(987),Duel.new(987)
for _=1,20 do Box.draw(independent_c.box) end
for _=1,20 do assert(independent_c.player_rng(1,6)==independent_d.player_rng(1,6)) end
local opening_seed
for seed=1,200 do
 local candidate=clean_duel(seed)
 candidate.phase='hand_end';candidate.completed_hands[1]={number=1}
 assert(Duel.next_hand(candidate))
 if candidate.phase=='player' then opening_seed=seed;break end
end
assert(opening_seed,'second hand should be reproducible without an initial X')

local function bank_result(match,faces,selected)
 match.phase='player';match.turn=Rules.new('control')
 local queue={};for i,v in ipairs(faces) do queue[i]=v end
 match.player_rng=function(lo,hi) local v=assert(table.remove(queue,1),'scripted D6 exhausted');assert(v>=lo and v<=hi);return v end
 assert(Duel.roll(match) and match.phase=='player' and match.turn.phase=='ready')
 for _,id in ipairs(selected) do assert(Duel.toggle(match,id)) end
 assert(Duel.can_bank(match) and Duel.bank(match))
end

-- A tie on hand score is awarded to the Artist.
d=clean_duel(opening_seed);d.hand.offer=10
bank_result(d,{1,2,3,4,6,6},{1})
assert(d.phase=='hand_end' and d.hand.winner=='artist' and d.hand.end_reason=='tie_goes_to_artist')

-- A positive offer defeats a zero-point Farkle without a counteroffer.
d=clean_duel(opening_seed);d.hand.offer=10
d.turn=Rules.new('control')
local farkle={2,3,4,6,2,3};local q={};for i,v in ipairs(farkle) do q[i]=v end
d.player_rng=function() return table.remove(q,1) end
assert(Duel.roll(d) and d.phase=='hand_end' and d.hand.player_farkle)
assert(d.hand.player_result==0 and d.hand.winner=='merchant' and #d.hand.merchant_decisions==0)

-- Probability threshold responds only to visible hand-win situation.
d=clean_duel(opening_seed);d.phase='merchant_decision';d.hand.offer=10;d.hand.player_result=20
d.box.draw_pile={card(5),card(4)}
d.hands_won={artist=1,merchant=0}
local preview=Duel.preview_decision(d)
assert(preview.chance==0.5 and preview.threshold==0.30 and preview.action=='continue')
d.hands_won={artist=0,merchant=0};preview=Duel.preview_decision(d)
assert(preview.threshold==0.50 and preview.action=='continue')
d.hands_won={artist=0,merchant=1};preview=Duel.preview_decision(d)
assert(preview.threshold==0.65 and preview.action=='withdraw')

-- The Merchant may withdraw; a continued offer can win or fail on X.
d=clean_duel(opening_seed);d.phase='merchant_decision';d.hand.offer=10;d.hand.player_result=20
d.box.draw_pile={card(5)};assert(Duel.preview_decision(d).action=='withdraw')
assert(Duel.advance_merchant(d) and d.phase=='hand_end' and d.hand.winner=='artist')
assert(d.hand.merchant_withdrawals==1 and d.merchant_withdrawals==1)

d=clean_duel(opening_seed);d.phase='merchant_decision';d.hand.offer=10;d.hand.player_result=20
d.hands_won={artist=1,merchant=0};d.box.draw_pile={card(4),card(5)}
assert(Duel.advance_merchant(d) and d.phase=='over')
assert(d.hand.symbols[#d.hand.symbols]=='X' and d.hand.winner=='artist' and d.x_draws==1)

d=clean_duel(opening_seed);d.phase='merchant_decision';d.hand.offer=10;d.hand.player_result=20
d.box.draw_pile={card(5),card(4)}
assert(Duel.advance_merchant(d) and d.phase=='hand_end')
assert(d.hand.offer==50 and d.hand.winner=='merchant' and d.counteroffers==1)

-- Best-of-three ends when one contender wins two hands and transfers the pot.
d=clean_duel(opening_seed);d.hand.offer=10
bank_result(d,{1,2,3,4,6,6},{1})
assert(d.hands_won.artist==1 and d.phase=='hand_end')
assert(Duel.next_hand(d))
d.hand.offer=10;bank_result(d,{1,2,3,4,6,6},{1})
assert(d.phase=='over' and d.winner=='artist' and d.hands_won.artist==2)
assert(d.reserve.artist==5 and d.reserve.merchant==3 and d.pot==0 and Duel.total_sheets(d)==8)
assert(Duel.record(d).merchant_hand_win_pct==0)

d=clean_duel(opening_seed);d.hand.offer=20
bank_result(d,{1,2,3,4,6,6},{1})
assert(d.hands_won.merchant==1 and d.phase=='hand_end')
assert(Duel.next_hand(d))
d.hand.offer=20;bank_result(d,{1,2,3,4,6,6},{1})
assert(d.phase=='over' and d.winner=='merchant' and d.hands_won.merchant==2)
assert(d.reserve.merchant==5 and d.reserve.artist==3 and Duel.total_sheets(d)==8)
local completed=d

local function equal(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
local function autoplay(seed)
 local match=Duel.new(seed)
 for _=1,100 do
  if match.phase=='over' then break
  elseif match.phase=='player' then
   assert(Duel.roll(match))
   if match.phase=='player' then
    local best
    for _,option in ipairs(Rules.options(match.turn)) do
     if not best or option.points>best.points then best=option end
    end
    assert(best,'a non-Farkle roll must expose at least one valid selection')
    for _,id in ipairs(best.ids) do assert(Duel.toggle(match,id)) end
    assert(Duel.bank(match))
   end
  elseif match.phase=='merchant_decision' then assert(Duel.advance_merchant(match))
  elseif match.phase=='hand_end' then assert(Duel.next_hand(match))
  else error('unexpected V3 phase '..tostring(match.phase)) end
  assert(Duel.total_sheets(match)==8,'V3 cannot create or lose sheets during a match')
  assert(#match.completed_hands<=3,'V3 cannot play beyond three hands')
 end
 assert(match.phase=='over','seeded V3 match must terminate within 100 decisions')
 return match
end
for seed=1,20 do
 local auto=autoplay(seed)
 assert(auto.winner=='artist' or auto.winner=='merchant')
 assert(#auto.completed_hands>=2 and #auto.completed_hands<=3)
end
local replay_a,replay_b=autoplay(4242),autoplay(4242)
assert(equal(Duel.record(replay_a),Duel.record(replay_b)))
assert(equal(replay_a.decisions,replay_b.decisions),'same seed and same policy must reproduce the complete match log')

-- Initial X awards the hand immediately; all 20 characters remain accounted for.
local initial_x
for seed=1,200 do
 local candidate=Duel.new(seed)
 if candidate.hand.x_count>0 then initial_x=candidate;break end
end
assert(initial_x and initial_x.phase=='hand_end' and initial_x.hand.winner=='artist')
assert(initial_x.hand.end_reason=='initial_x' and initial_x.hand.char_draws==2 and Box.total(initial_x.box)==20)
assert(Presentation.phase_name(initial_x)=='Mano conclusa')
assert(Presentation.hand_heading(initial_x)=='MANO VINTA — ARTISTA')
assert(Presentation.event_message(initial_x):find('X nell’offerta iniziale',1,true))
assert(not Presentation.end_details(initial_x):find('initial_x',1,true))
initial_x.phase='over';initial_x.winner='artist';initial_x.end_reason='new_unknown_reason'
initial_x.hand.end_reason='new_unknown_reason'
local unknown_message=Presentation.event_message(initial_x)
assert(unknown_message:find('New unknown reason',1,true) and not unknown_message:find('_',1,true))
assert(#Presentation.actions(initial_x)==1 and Presentation.actions(initial_x)[1].id=='open_v3_feedback')
assert(#completed.decisions>0 and completed.decisions[1].actor=='artist')

-- Versioned V3 CSVs are separate and preserve complete hand/match/feedback rows.
local files={}
local fs={getInfo=function(path) return files[path] and {} or nil end,
 read=function(path) return files[path] end,
 write=function(path,contents) files[path]=contents;return true end,
 append=function(path,contents) files[path]=files[path]..contents;return true end}
assert(Log.next_id_v3(fs)==1)
Log.save_v3(fs,completed,Duel.record(completed))
assert(Log.next_id_v3(fs)==2)
assert(files[Log.V3_MATCH_FILE]:find('id,seed,initial_pot',1,true))
assert(files[Log.V3_HAND_FILE]:find('initial_symbols',1,true) and files[Log.V3_HAND_FILE]:find('merchant_symbols',1,true))
assert(files[Log.V3_DECISION_FILE]:find('score_difference',1,true) and files[Log.V3_DECISION_FILE]:find('incassa',1,true))
Log.save_v3_feedback(fs,{id=completed.id,seed=completed.seed,counteroffer_rerolls='yes',
 banked_below_estimate='no',merchant_decisions_clear='yes',felt_competitive='yes',
 loss_cause='luck',notes='test, note'})
assert(files[Log.V3_FEEDBACK_FILE]:find('test, note',1,true))
assert(Log.MATCH_FILE_V2~='runs.csv' and Log.V3_MATCH_FILE~=Log.MATCH_FILE_V2)

print('PASS merchant wager V3: box composition/refill, exact visible risk, no future peek, withdrawal, X, counteroffers, tie, best-of-three, sheet conservation, versioned CSV')
