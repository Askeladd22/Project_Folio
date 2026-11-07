local Corrector=require('experiments.merchant_wager_lab.corrector')
local Match=require('experiments.merchant_wager_lab.match')
local Rules=require('src.farkle.rules')
local Log=require('experiments.merchant_wager_lab.log')

local function score(values)
 local ids={};for i=1,#values do ids[i]=i end
 local selection=Corrector.corrector_score(values,ids)
 return selection and selection.points
end
assert(score({1,2,3})==nil)
assert(score({4})==50 and score({5,6})==100)
assert(score({4,4,4})==300)
assert(score({5,5,5,5})==600)
assert(score({6,6,6,6,6})==1000)
assert(score({4,4,4,4,4,4})==1500)
assert(score({4,4,4,5,6,2})==400,
 'the Corrector must set aside useful dice and leave 1/2/3 available')

local match=Corrector.new(123)
assert(match.pot==3 and match.sheets.player==0 and match.sheets.corrector==0)
assert(Corrector.can_roll(match))
assert(not Corrector.can_buy(match) and not Corrector.can_advance_corrector(match))

local player_farkle=Corrector.new(8)
local farkle_faces={2,3,4,6,2,4}
local face_index=0
player_farkle.player_rng=function()
 face_index=face_index+1
 return farkle_faces[face_index]
end
assert(Corrector.roll_player(player_farkle))
assert(player_farkle.phase=='after_player' and player_farkle.player_farkles==1,
 'player Farkle state was '..tostring(player_farkle.phase)..' / '..player_farkle.player_farkles)
assert(player_farkle.turn.pot==0,'player Farkle must discard the provisional turn score')

local function scripted_corrector(values)
 local m=Corrector.new(9)
 local index=0
 m.corrector_rng=function(minimum,maximum)
  index=index+1
  local value=values[index]
  assert(value,'unexpected extra Corrector random request')
  assert(value>=minimum and value<=maximum)
  return value
 end
 m.phase='after_player'
 assert(Corrector.advance_corrector(m))
 return m
end
local banks=scripted_corrector({4,2,2,2,2,2,4,4,4,2,2,1})
assert(banks.points.corrector==350 and banks.corrector_farkles==0)
local forced,decision_seen=false,false
for _,event in ipairs(banks.events) do
 if event.action=='corrector_must_reroll' then forced=true end
 if event.action=='corrector_bank_decision' and event.detail:find('incassa',1,true) then decision_seen=true end
end
assert(forced and decision_seen,'below 300 must reroll; D6 1-3 must bank')
local bust=scripted_corrector({4,2,2,2,2,2,4,4,4,2,2,4,2,2})
assert(bust.corrector_farkles==1 and bust.points.corrector==0 and bust.pot==2)
assert(bust.sheets_stolen==1,'theft telemetry must include sheets stolen from the center')
local reroll_seen=false
for _,event in ipairs(bust.events) do
 if event.action=='corrector_bank_decision' and event.detail:find('rilancia',1,true) then reroll_seen=true end
end
assert(reroll_seen,'D6 4-6 must trigger the additional roll')

local function play_to_opponent(m)
 if Corrector.can_roll(m) then Corrector.roll_player(m) end
 if m.phase=='player' then
  local best
  for _,option in ipairs(Rules.options(m.turn)) do
   if not best or option.points>best.points then best=option end
  end
  if best then
   for _,id in ipairs(best.ids) do assert(Corrector.toggle_player_die(m,id)) end
   assert(Corrector.take_player_dice(m))
   assert(Corrector.bank_player(m))
  else
   assert(m.phase=='after_player')
  end
 end
end

local function auto(seed)
 local m=Corrector.new(seed)
 for _=1,20 do
  if m.phase=='over' then break end
  if m.phase=='player' then play_to_opponent(m)
  elseif m.phase=='after_player' then
   while Corrector.can_buy(m) do assert(Corrector.buy_sheet(m)) end
   if m.phase~='over' then assert(Corrector.advance_corrector(m)) end
  end
  assert(m.sheets.player+m.sheets.corrector+m.pot==3,'sheets must be conserved')
 end
 if m.phase~='over' then assert(Corrector.close(m)) end
 return m
end
local a,b=auto(4242),auto(4242)
assert(a.phase=='over' and b.phase=='over')
assert(a.winner==b.winner and a.sheets.player==b.sheets.player and
 a.sheets.corrector==b.sheets.corrector and a.points.player==b.points.player and
 a.points.corrector==b.points.corrector)
assert(#a.events==#b.events)
for i,event in ipairs(a.events) do
 assert(event.action==b.events[i].action and event.faces==b.events[i].faces,
  'same seed and same decisions must reproduce events')
end

local independent_a=Corrector.new(987)
local independent_b=Corrector.new(987)
for _=1,200 do independent_a.player_rng(1,6) end
independent_a.phase='after_player';independent_b.phase='after_player'
assert(Corrector.advance_corrector(independent_a))
assert(Corrector.advance_corrector(independent_b))
local function corrector_rolls(m)
 local result={}
 for _,event in ipairs(m.events) do
  if event.actor=='corrector' and (event.action=='corrector_scored' or event.action=='corrector_farkle') then
   result[#result+1]=event.faces
  end
 end
 return table.concat(result,'|')
end
assert(corrector_rolls(independent_a)==corrector_rolls(independent_b),
 'player random consumption must not change Corrector rolls')

local thief=Corrector.new(1)
thief.phase='after_player';thief.pot=0;thief.sheets.player=1
thief.corrector_rng=function() return 1 end
assert(Corrector.advance_corrector(thief))
assert(thief.corrector_farkles==1 and thief.sheets_stolen==1)
assert(thief.sheets.player==0 and thief.sheets.corrector==1 and thief.phase=='over')
assert(thief.winner=='corrector')

local buyer=Corrector.new(2)
buyer.phase='after_player';buyer.points.player=500
assert(Corrector.can_buy(buyer) and Corrector.buy_sheet(buyer))
assert(buyer.points.player==0 and buyer.sheets.player==1 and buyer.pot==2)
assert(buyer.sheets.player+buyer.sheets.corrector+buyer.pot==3)

local tie=Corrector.new(3)
assert(Corrector.close(tie) and tie.winner=='tie' and tie.pot==3)
local sheet_winner=Corrector.new(4)
sheet_winner.sheets.player=2;sheet_winner.sheets.corrector=1
sheet_winner.points.corrector=999
assert(Corrector.close(sheet_winner) and sheet_winner.winner=='player',
 'sheet count decides before unspent points')
local point_tie=Corrector.new(5)
point_tie.sheets.player=1;point_tie.sheets.corrector=1;point_tie.points.corrector=1
assert(Corrector.close(point_tie) and point_tie.winner=='corrector')

local files={}
local fs={
 getInfo=function(path) return files[path] and {} or nil end,
 read=function(path) return files[path] end,
 write=function(path,data) files[path]=data;return true end,
 append=function(path,data) files[path]=(files[path] or '')..data;return true end,
}
local record=Corrector.record(a)
Log.save_corrector(fs,a,record)
assert(files[Log.CORRECTOR_MATCH_FILE]:find('id,seed,turns',1,true))
assert(files[Log.CORRECTOR_EVENT_FILE]:find('corrector_turn_started',1,true))
Log.save_corrector_feedback(fs,{id=record.id,seed=record.seed,
 decision_changes=2,threat_perceived='partial',notes='test'})
assert(files[Log.CORRECTOR_FEEDBACK_FILE]:find('partial',1,true))
assert(Log.next_id_corrector(fs)==2)

print('Corrector prototype tests passed.')
