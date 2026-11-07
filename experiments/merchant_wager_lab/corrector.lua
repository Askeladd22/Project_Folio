local Rules=require('src.farkle.rules')
local Match=require('experiments.merchant_wager_lab.match')

local M={}
local PRICE=500
local INITIAL_POT=3

local function record(m,actor,action,data)
 data=data or {}
 local row={step=#m.events+1,turn=m.turn_number,actor=actor,action=action,
  player_points=m.points.player,corrector_points=m.points.corrector,
  player_sheets=m.sheets.player,corrector_sheets=m.sheets.corrector,pot=m.pot,
  provisional=data.provisional or 0,dice_available=data.dice_available or 0,
  faces=data.faces or '',kept=data.kept or '',points=data.points or 0,
  detail=data.detail or ''}
 m.events[#m.events+1]=row
 m.last_event=row
 return row
end

local function finish(m,reason)
 if m.phase=='over' then return end
 m.end_reason=reason
 if m.sheets.player>m.sheets.corrector then m.winner='player'
 elseif m.sheets.corrector>m.sheets.player then m.winner='corrector'
 elseif m.points.player>m.points.corrector then m.winner='player'
 elseif m.points.corrector>m.points.player then m.winner='corrector'
 else m.winner='tie' end
 m.phase='over'
 record(m,'table','encounter_ended',{detail=reason..'; winner='..m.winner})
end

local function check_sheets_end(m)
 if m.pot==0 and (m.sheets.player==0 or m.sheets.corrector==0) then
  finish(m,'all_sheets_claimed')
  return true
 end
 return false
end

local function new_turn(m)
 m.turn_number=m.turn_number+1
 m.turn=Rules.new('control')
 m.phase='player'
end

local function take_sheet(m,owner,source)
 if source=='pot' then
  assert(m.pot>0,'no sheets in the center')
  m.pot=m.pot-1
 else
  assert(owner=='corrector' and m.sheets.player>0,'no player sheet to steal')
  m.sheets.player=m.sheets.player-1
 end
 m.sheets[owner]=m.sheets[owner]+1
end

function M.new(seed,id)
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and seed<2147483647,
  'seed must be integer 1..2147483646')
 local corrector_seed=1+((seed*48271)%2147483646)
 local m={id=id or 1,seed=seed,player_rng=Match.new_rng(seed),
  corrector_rng=Match.new_rng(corrector_seed),phase='player',turn_number=1,
  turn=Rules.new('control'),
  points={player=0,corrector=0},sheets={player=0,corrector=0},pot=INITIAL_POT,
  initial_pot=INITIAL_POT,events={},last_event=nil,
  player_farkles=0,corrector_farkles=0,corrector_rerolls=0,
  corrector_banked_turns=0,corrector_sheets_bought=0,sheets_stolen=0,
  player_banked_turns=0,player_rolls_this_turn=0,player_decision_changes=0,
  player_decision_opportunities=0,
  threat_perception='',notes=''}
 record(m,'table','encounter_started',{detail='seed='..seed..'; center=3'})
 record(m,'table','corrector_offer',{detail='Corrector uses 6 dice; 500 points per sheet'})
 return m
end

function M.corrector_score(values,ids)
 if #values==0 or #values~=#ids then return nil end
 local counts={0,0,0,0,0,0}
 local selected={}
 for _,value in ipairs(values) do
  assert(type(value)=='number' and value%1==0 and value>=1 and value<=6,
   'Corrector die value must be an integer from 1 to 6')
 end
 for i,value in ipairs(values) do
  if value>=4 then counts[value]=counts[value]+1;selected[#selected+1]=ids[i] end
 end
 if #selected==0 then return nil end
 local points=0
 local group_points={[3]={300,300,300},[4]={600,600,600},
  [5]={1000,1000,1000},[6]={1500,1500,1500}}
 for value=4,6 do
  local count=counts[value]
  if count>=3 then points=points+group_points[count][1]
  else points=points+count*50 end
 end
 table.sort(selected)
 return {points=points,ids=selected}
end

function M.can_roll(m) return m.phase=='player' and Rules.can_roll(m.turn) end
function M.can_toggle(m,id)
 return m.phase=='player' and m.turn.phase=='ready' and m.turn.hand[id]~=nil and not m.turn.used[id]
end
function M.can_take(m) return m.phase=='player' and Rules.selection(m.turn)~=nil end
function M.can_bank(m)
 if m.phase~='player' then return false end
 local ok=Rules.bank_status(m.turn)
 return ok
end
function M.can_buy(m)
 return m.phase=='after_player' and m.pot>0 and m.points.player>=PRICE
end
function M.can_close(m)
 return (m.phase=='player' and m.turn.phase=='fresh') or m.phase=='after_player'
end
function M.can_advance_corrector(m) return m.phase=='after_player' end

function M.roll_player(m)
 if not M.can_roll(m) then return false end
 local t=m.turn
 local previous_provisional=t.pot
 assert(Rules.start(t),'Farkle rules refused a legal player roll')
 local faces={}
 for _,id in ipairs(t.active) do faces[id]=m.player_rng(1,6) end
 assert(Rules.settle(t,faces),'Farkle rules refused player dice')
 local rolled={}
 for _,id in ipairs(t.active) do rolled[#rolled+1]=faces[id] end
 local valid=t.phase=='ready'
 if valid then m.player_decision_opportunities=m.player_decision_opportunities+1 end
 m.player_rolls_this_turn=m.player_rolls_this_turn+1
 record(m,'player',valid and (m.player_rolls_this_turn==1 and 'player_roll' or 'player_reroll') or 'player_farkle',
  {provisional=valid and t.pot or previous_provisional,dice_available=#t.active,faces=table.concat(rolled,' '),
   detail=valid and 'Lancio valido' or 'Farkle'})
 if not valid then
  m.player_farkles=m.player_farkles+1
  m.last_player_turn_points=0
  t.pot=0
  m.phase='after_player'
  m.player_rolls_this_turn=0
 end
 return true
end

function M.toggle_player_die(m,id)
 if not M.can_toggle(m,id) then return false end
 return Rules.toggle(m.turn,id)
end

function M.take_player_dice(m)
 if not M.can_take(m) then return false end
 local points=Rules.selection(m.turn)
 local ids={};for id in pairs(m.turn.selected) do ids[#ids+1]=id end
 table.sort(ids)
 record(m,'player','player_set_aside',{provisional=m.turn.pot+points,
  dice_available=Rules.count_free(m.turn)-#ids,kept=table.concat(ids,' '),points=points})
 return Rules.take(m.turn)
end

local function end_player_turn(m,banked)
 m.last_player_turn_points=banked or 0
 m.player_banked_turns=m.player_banked_turns+(banked and banked>0 and 1 or 0)
 m.phase='after_player'
 m.player_rolls_this_turn=0
end

function M.bank_player(m)
 if not M.can_bank(m) then return false end
 local selected=Rules.selection(m.turn)
 local amount=m.turn.pot+(selected or 0)
 assert(Rules.bank_turn(m.turn),'Farkle rules refused a legal bank')
 m.points.player=m.points.player+amount
 record(m,'player','player_banked',{provisional=amount,points=amount,
  detail='Spendable points '..m.points.player})
 end_player_turn(m,amount)
 return true
end

function M.buy_sheet(m)
 if not M.can_buy(m) then return false end
 m.points.player=m.points.player-PRICE
 take_sheet(m,'player','pot')
 record(m,'player','player_bought_sheet',{points=PRICE,detail='500 points'})
 check_sheets_end(m)
 return true
end

function M.close(m)
 if not M.can_close(m) then return false end
 finish(m,'player_closed')
 return true
end

local function buy_corrector_sheets(m)
 while m.pot>0 and m.points.corrector>=PRICE do
  m.points.corrector=m.points.corrector-PRICE
  m.corrector_sheets_bought=m.corrector_sheets_bought+1
  take_sheet(m,'corrector','pot')
  record(m,'corrector','corrector_bought_sheet',{points=PRICE,detail='500 points'})
  if check_sheets_end(m) then return end
 end
end

function M.advance_corrector(m)
 if not M.can_advance_corrector(m) then return false end
 local provisional=0
 local rerolls=0
 local used={}
 local active={1,2,3,4,5,6}
 local faces={}
 local attempts=0
 m.corrector_dice=faces
 m.corrector_kept=used
 record(m,'corrector','corrector_turn_started',{detail='6 dice; minimum bank 300'})
 while true do
  attempts=attempts+1
  if attempts>10000 then error('Corrector exceeded the deterministic roll safety limit') end
  for _,id in ipairs(active) do faces[id]=m.corrector_rng(1,6) end
  local rolled={};local values={}
  for _,id in ipairs(active) do
   rolled[#rolled+1]=faces[id]
   values[#values+1]=faces[id]
  end
  local selection=M.corrector_score(values,active)
  if not selection then
   m.corrector_farkles=m.corrector_farkles+1
   record(m,'corrector','corrector_farkle',{provisional=provisional,
    dice_available=#active,faces=table.concat(rolled,' '),
    detail=provisional>0 and 'Provvisorio perso' or 'Nessun punto'})
   if m.pot>0 then
    m.sheets_stolen=m.sheets_stolen+1
    take_sheet(m,'corrector','pot')
    record(m,'corrector','sheet_stolen_from_center',{detail='Farkle; +1 foglio'})
    check_sheets_end(m)
   elseif m.sheets.player>0 then
    m.sheets_stolen=m.sheets_stolen+1
    take_sheet(m,'corrector','player')
    record(m,'corrector','sheet_stolen_from_player',{detail='Farkle; +1 foglio'})
    check_sheets_end(m)
   else
    record(m,'corrector','no_sheet_to_steal',{detail='Nessun foglio disponibile'})
   end
   break
  end
  assert(selection.points>0,'valid Corrector throw must score')
  provisional=provisional+selection.points
  for _,id in ipairs(selection.ids) do used[id]=true end
  local free=#active-#selection.ids
  if free==0 then
   used={};m.corrector_kept=used
   active={1,2,3,4,5,6}
   free=6
  else
   active={}
   for id=1,6 do if not used[id] then active[#active+1]=id end end
  end
  record(m,'corrector','corrector_scored',{provisional=provisional,dice_available=free,
   faces=table.concat(rolled,' '),kept=table.concat(selection.ids,' '),points=selection.points})
  if provisional<300 then
   rerolls=rerolls+1;m.corrector_rerolls=m.corrector_rerolls+1
   record(m,'corrector','corrector_must_reroll',{provisional=provisional,
    dice_available=free,detail='Provvisorio inferiore a 300'})
  else
   local decision=m.corrector_rng(1,6)
   record(m,'corrector','corrector_bank_decision',{provisional=provisional,
    dice_available=free,detail=('D6 decisionale %d: %s'):format(decision,
     decision<=3 and 'incassa' or 'rilancia')})
   if decision<=3 then
    m.points.corrector=m.points.corrector+provisional
    m.corrector_banked_turns=m.corrector_banked_turns+1
    record(m,'corrector','corrector_banked',{provisional=provisional,
     points=provisional,detail='Punti spendibili '..m.points.corrector})
    buy_corrector_sheets(m)
    break
   end
   rerolls=rerolls+1;m.corrector_rerolls=m.corrector_rerolls+1
  end
 end
 if m.phase~='over' then
  if not check_sheets_end(m) then new_turn(m) end
 end
 return true
end

function M.record(m)
 assert(m.phase=='over','record only a completed Corrector encounter')
 return {id=m.id,seed=m.seed,turns=m.turn_number,player_sheets=m.sheets.player,
  corrector_sheets=m.sheets.corrector,center_sheets=m.pot,
  player_points=m.points.player,corrector_points=m.points.corrector,
  winner=m.winner,end_reason=m.end_reason,player_farkles=m.player_farkles,
  corrector_farkles=m.corrector_farkles,corrector_rerolls=m.corrector_rerolls,
  corrector_banked_turns=m.corrector_banked_turns,
  corrector_sheets_bought=m.corrector_sheets_bought,
  sheets_stolen=m.sheets_stolen,player_banked_turns=m.player_banked_turns,
  player_decision_opportunities=m.player_decision_opportunities}
end

function M.price() return PRICE end
function M.initial_pot() return INITIAL_POT end
return M
