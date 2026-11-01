local M={}
function M.install(U)
 local R=require('src.gameplay.farkle.rules')
 local H=require('src.features.farkle.hud_model')
 local Res=require('src.core.resolution_manager')
 local Bridge=require('src.core.engine_bridge')
 local root=assert(os.getenv('MANUSCRIPT_AUDIT_OUT'))..'/'
 local log=assert(io.open(root..'hud-smoke.log','w'))
 local function record(s) log:write(s..'\n');log:flush() end
 function love.errorhandler(e) record('FAIL '..tostring(e)..'\n'..debug.traceback());log:close();return function() return 1 end end
 local load,update,draw=love.load,love.update,love.draw
 local elapsed,frames=0,0;local pending,co
 local function click(id)
  U:draw();if U.modal or H.reward_active(U.game) then U:drawDeskOverlays(U.hits) end
  local b=assert((U.modal and U.modalButtons or U.buttons)[id],id..' phase='..tostring(U.game.phase)..' modal='..tostring(U.modal)..' physical='..tostring(U.physicalFailure));assert(b.enabled,'disabled '..id)
  local x,y=Res.to_screen(b.x+b.w/2,b.y+b.h/2);U:mousepressed(x,y,1)
 end
 local function shot(name) coroutine.yield({shot=name}) end
 local function wait() coroutine.yield({wait=true}) end
 local function feed(h)
  assert(R.start(U.game));U.state='rolling';U.pending={};U.observed={}
  local a={};for i,v in pairs(h) do a[#a+1]={index=i,value=v} end;U:onDiceSettled(a)
 end
 local function bounds()
  local t=H.tray
  if H.reward_active(U.game) then
   U:drawDeskOverlays(U.hits)
   local allowed=U.game.phase=='upgrade' and {weighted=true,engraved=true} or {medal=true,none=true}
   for id in pairs(U.buttons) do assert(allowed[id],'gameplay control during reward: '..id) end
   local phase=U.game.phase;U:keypressed('escape');U:keypressed('space');U:keypressed('1');assert(U.game.phase==phase)
   return
  end
  for id,b in pairs(U.buttons) do
   assert(b.x>=0 and b.y>=0 and b.x+b.w<=1920 and b.y+b.h<=1080,'out of screen '..id)
   assert(b.x+b.w<=t.x or b.x>=t.x+t.w or b.y+b.h<=t.y or b.y>=t.y+t.h,'overlaps tray '..id)
  end
  if H.commission_closed(U.game) then
   assert(not U.buttons.roll and not U.buttons.bank and not U.buttons.take,'terminal gameplay buttons remain')
  end
 end
 -- P0 diagnostic only: actually grab all six PHYSICAL bodies with the
 -- production controller and capture the held state. No mocked dice or
 -- synthetic score, and never used in ordinary gameplay.
 local function physical_grip_baseline(prefix)
  U:draw()
  local hits=Bridge.getTrayDieHits()
  assert(#hits==6,'P0 group baseline requires six projected physical dice')
  local tray=assert(Bridge.getDiceTrayRect(),'P0 tray bounds missing')
  local minx,miny,maxx,maxy=math.huge,math.huge,-math.huge,-math.huge
  for _,hit in ipairs(hits) do
   minx=math.min(minx,hit.x);miny=math.min(miny,hit.y)
   maxx=math.max(maxx,hit.x);maxy=math.max(maxy,hit.y)
  end
  local x0=math.max(tray.x+4,minx-12)
  local y0=math.max(tray.y+4,miny-12)
  local x1=math.min(tray.x+tray.w-4,maxx+12)
  local y1=math.min(tray.y+tray.h-4,maxy+12)
  assert(x1>x0+9 and y1>y0+9,'P0 selected dice do not fit tray bounds')
  U:mousepressed(x0,y0,1)
  assert(U.marquee,'P0 physical marquee did not start')
  U:mousemoved(x1,y1)
  U:mousereleased(x1,y1,1)
  local count=require('src.features.farkle.marquee_selection').count
  assert(count(U.dragSelected)==6,'P0 marquee failed to select every real D6')
  assert(U.game.phase=='fresh','P0 physical select must not spend a roll')
  shot(prefix..'marquee-six')
  local first=hits[1]
  U:mousepressed(first.x,first.y,2)
  assert(U.mouseThrow and U.mouseThrow.group and #U.mouseThrow.held==6,
    'P0 real right-click group grip not engaged')
  assert(U.manualRoll and U.manualRoll.count==6,
    'P0 grip must not register any physical release yet')
  U:mousemoved(first.x+48,first.y-24)
  for i=1,25 do U:update(.03) end
  shot(prefix..'physical-group-held')
  U:keypressed('escape')
  assert(not U.mouseThrow and U.manualRoll and U.manualRoll.count==6,
    'P0 Esc should cancel grip without fake Farkle release')
  -- Esc releases the grip but intentionally leaves the manual throw
  -- in flight. Only the SMOKE fixture forces a reset for its next
  -- screenshot; the shipping controller is not changed.
  U.state='waiting'
  U:reset('build')
  assert(U.game.phase=='fresh' and not U.manualRoll,
   'P0 smoke cleanup left a pending physical throw')
  record('PASS '..prefix..' physically grabbed 6 D6 and cancelled without scoring')
 end
 local function accessibility_baseline(prefix)
  local state=require('src.core.runtime_state')
  local settings=state.get_game_settings() or {}
  local extended={}
  for k,v in pairs(settings) do extended[k]=v end
  extended.accessibility={
    big_text=true,high_contrast=true,reduced_animations=true
  }
  state.apply_settings(extended)
  local UI=require('src.core.runtime_ui')
  assert(UI.big_text() and UI.high_contrast() and
         UI.reduced_animations() and UI.scale()>1,
         'P0 accessibility test settings were not activated')
  shot(prefix..'accessibility-on')
  state.apply_settings(settings)
  assert(not UI.big_text() or (settings.accessibility and settings.accessibility.big_text),
         'P0 accessibility settings not restored')
  record('PASS '..prefix..' accessibility flags exercised and restored')
 end
 -- P7 visual review of the ACTUAL current UI V2, independent of the
 -- retired legacy HUD button IDs/coordinates still present in old P0 smoke.
 -- The six-die grip is performed through the production mouse controller.
 -- Explicitly named *fixture frames* use the real Farkle rules/presenter but
 -- programmatic dice results: they are NOT evidence of physical roll fidelity.
 local function review_scenario(w,h)
  love.window.setMode(w,h,{resizable=true})
  love.resize(w,h)
  U.duelActive=false
  U:reset('build')
  local prefix='hud-usability-'..w..'-'
  shot(prefix..'fresh')
  physical_grip_baseline(prefix)
  shot(prefix..'fresh-after-cancel')
  -- Isolate settings changes; this capture must not permanently alter
  -- accessibility options or pretend their GPU result was already reviewed.
  local settingsState=require('src.core.runtime_state')
  local original=settingsState.get_game_settings() or {}
  local copy={}
  for k,v in pairs(original) do copy[k]=v end
  copy.accessibility={
   big_text=true,high_contrast=true,reduced_animations=true
  }
  settingsState.apply_settings(copy)
  local ui=require('src.core.runtime_ui')
  assert(ui.big_text() and ui.high_contrast() and ui.reduced_animations(),
   'UI V2 review accessibility flags did not apply')
  shot(prefix..'accessibility-on')
  settingsState.apply_settings(original)
  record('PASS '..prefix..' UI V2 accessibility flags restored')
  U:keypressed('?')
  assert(U.modal=='help')
  shot(prefix..'help')
  U:keypressed('right')
  assert(U.helpTab==2)
  shot(prefix..'help-scores')
  U:keypressed('escape')
  U:keypressed('f')
  assert(U.modal=='folio')
  shot(prefix..'folio')
  U:keypressed('escape')
  click('runmenu')
  assert(U.modal=='run')
  shot(prefix..'run-menu')
  click('close')
  assert(not U.modal)
  -- UI-only fixture; no fake physical release is generated.
  feed({1,1,1,1,1,1})
  assert(U.game.phase=='ready','review score fixture not ready')
  shot(prefix..'ready-fixture')
  click('choices')
  assert(U.modal=='choices')
  shot(prefix..'choices-fixture')
  click('close')
  U:keypressed('1')
  assert(R.selection(U.game),'score selection fixture not valid')
  shot(prefix..'selected-fixture')
  U:reset('build')
  feed({1,1,1,1,1,1})
  for i=1,6 do U:keypressed(tostring(i)) end
  click('bank')
  assert(U.game.phase=='upgrade','real rules did not reach first reward')
  shot(prefix..'upgrade-fixture')
  click('engraved')
  assert(U.game.stage==2,'reward did not advance stage')
  feed({1,1,1,1,1,1})
  for i=1,6 do U:keypressed(tostring(i)) end
  click('bank')
  assert(U.game.phase=='medal','real rules did not reach second reward')
  shot(prefix..'medal-fixture')
  click('medal')
  click('runmenu')
  click('medals')
  assert(U.modal=='medals')
  shot(prefix..'reference-catalog')
  click('close')
  U.duelActive=true
  U:reset('control')
  assert(U.botDuel,'Monk visual review must use optional real duel')
  shot(prefix..'monk-live')
  U.duelActive=false
  U:reset('build')
  record('PASS '..prefix..' current V2 layout/modals, real grip and rule-based reward paths')
 end
 local function scenario(w,h)
  love.window.setMode(w,h,{resizable=true});love.resize(w,h);U.hud_variant='standard';U:reset('build')
  local prefix='hud-usability-'..w..'-'
  if os.getenv('MANUSCRIPT_UI_V2_P0_CAPTURE')=='1' then
   -- Extra P0 frames before the existing full HUD smoke scenarios.
   -- Reset after the held/cancel test so fixture state is unchanged.
   shot(prefix..'fresh-pre-grip')
   physical_grip_baseline(prefix)
   accessibility_baseline(prefix)
   shot(prefix..'fresh-after-cancel')
  end
    if os.getenv('UI_DREAM_TABLE') then
     U.hud_variant='minimal'
     shot(prefix..'normal');click('roll');wait()
     for attempt=1,8 do
        if U.game.phase=='ready' then break end
        U:reset('build');click('roll');wait()
     end
     assert(#U.hits==6,'six dice missing')
     for _,hit in ipairs(U.hits) do assert(Bridge.pickTrayDie(hit.x,hit.y)==hit.index,'picking mismatch') end
     local chosen
     for _,option in ipairs(R.options(U.game)) do if #option.ids<6 then chosen=option.ids;break end end
     assert(chosen,'partial scoring fixture missing')
     for _,index in ipairs(chosen) do U:keypressed(tostring(index)) end
     click('take');shot(prefix..'transfer');U:keypressed('tab');shot(prefix..'held')
     local held=chosen[1];local position={unpack(dice[held].body.position)}
     local origin=U.presentation.shelf[held].roll
     if os.getenv('UI_DREAM_TABLE')~='before' then
      assert(U.upperShelf and U.upperShelf.y>76 and U.upperShelf.y+U.upperShelf.h<390,'upper shelf layout')
     end
     click('roll');wait()
     for axis=1,3 do assert(dice[held].body.position[axis]==position[axis],'held body moved') end
     assert(U.presentation.shelf[held].roll==origin,'held origin changed')
     for _,hit in ipairs(U.hits) do assert(not U.game.used[hit.index],'held die remains pickable') end
     record('PASS '..w..' physical six dice, picking, transfer and partial reroll')
     U:reset('build');feed({1,1,1,1,1,1})
     for index=1,6 do U:keypressed(tostring(index)) end
     click('take');U:keypressed('tab');shot(prefix..'six-held')
     local pot=U.game.pot;assert(U.game.hot);click('roll')
     assert(U.game.pot==pot and not next(U.presentation.shelf),'hot dice lost confirmed work')
     wait();record('PASS '..w..' hot dice preserves points and releases shelf')
   U:reset('build');feed({3,3,3,1,2,4})
   for index=1,3 do U:keypressed(tostring(index)) end
   click('take');click('bank');click('next');feed({5,5,5,1,2,4})
   for index=1,3 do U:keypressed(tostring(index)) end
   click('take');U:keypressed('tab')
     assert(U.game.bank>0 and U.game.pot>0);shot(prefix..'mixed')
     U:keypressed('f');shot(prefix..'folio');U:keypressed('escape')
   if os.getenv('UI_DREAM_TABLE')=='b' then
    U.game.medal='retry'
    feed({[4]=2,[5]=3,[6]=4})
    assert(U.game.phase=='rescue' and U.game.pot==50)
    local bank,pot=require('src.features.farkle.presentation').folio_values(U.presentation,U.game)
    assert(bank==30 and pot==50,'rescue must preserve provisional folio')
    shot(prefix..'rescue');click('fail');U:keypressed('tab')
    bank,pot=require('src.features.farkle.presentation').folio_values(U.presentation,U.game)
    assert(bank==30 and pot==0,'definitive loss must preserve banked work')
    shot(prefix..'loss')
    U:reset('build');assert(U:equip_reference('bank_multiplier_gold'))
    feed({1,1,1,2,3,4});for index=1,3 do U:keypressed(tostring(index)) end
    assert(U:activate_reference());U:keypressed('tab')
    bank,pot=require('src.features.farkle.presentation').folio_values(U.presentation,U.game)
    assert(bank==150 and pot==0 and U.game.phase=='upgrade','folio must reflect resolved medal bonus')
    shot(prefix..'bonus');record('PASS '..w..' folio rescue, definitive loss and resolved medal bonus')
   end
     U:reset('build');feed({1,1,1,1,1,1})
     for index=1,6 do U:keypressed(tostring(index)) end
     click('bank');U:drawDeskOverlays(U.hits)
     for id in pairs(U.buttons) do assert(id=='weighted' or id=='engraved','gameplay control during reward') end
     shot(prefix..'reward');record('PASS '..w..' mixed bank/pot, folio and isolated rewards')
     return
    end
  if os.getenv('UI_RULES_ONLY')=='1' then
   U:keypressed('?')
   for i=1,3 do click('helpTab'..i);shot(prefix..'rules-final-'..i) end
   U:keypressed('escape');assert(not U.modal)
   feed({1,2,3,4,5,6});for i=1,6 do click('die'..i) end;click('take')
   shot(prefix..'final-hot');bounds()
   U:reset('build');feed({2,2,3,3,4,6});shot(prefix..'final-farkle');bounds()
   U:reset('build');feed({1,5,2,3,4,6});click('die1');click('die2');shot(prefix..'layout-selected');click('take')
   assert(require('src.features.farkle.presentation').contributing_dice(U.presentation)[1])
   shot(prefix..'causal-groups');U:keypressed('tab')
   assert(not next(require('src.features.farkle.presentation').contributing_dice(U.presentation)))
   U:reset('build');assert(U:equip_reference('bank_multiplier_gold'));feed({1,1,1,2,3,4})
   for i=1,3 do click('die'..i) end
   assert(U:activate_reference());assert(U.presentation.bonus==75 and U.game.bank==150)
   shot(prefix..'causal-medal');bounds();U:keypressed('tab');shot(prefix..'causal-medal-skipped')
   record('PASS '..w..' three rules tabs and Escape');return
  end
  shot(prefix..'fresh');bounds();click('roll');local same=U.game;U:keypressed('r');U:keypressed('?');assert(U.game==same and not U.modal)
  shot(prefix..'rolling');wait()
  while U.game.phase~='ready' do U:reset('build');click('roll');wait() end
  shot(prefix..'result');bounds();assert(#H.options(U.game)>0)
  assert(#U.hits==6,'missing projected die')
  for _,hit in ipairs(U.hits) do assert(Bridge.pickTrayDie(hit.x,hit.y)==hit.index,'projection and mouse picking disagree') end
  record('PASS '..w..' six projected dice remain individually selectable')
  local chosen
  for attempt=1,12 do
   for _,o in ipairs(R.options(U.game)) do if #o.ids<6 then chosen=o.ids;break end end
   if chosen then break end
   -- Three pairs may be the only scoring option. Seek a partial-roll fixture
   -- with another real throw, never overwrite an observed physical result.
   record('No partial scoring subset; requesting another physical fixture')
   U:reset('build');click('roll');wait()
  end
  assert(chosen,'no physical partial-roll fixture in 12 attempts')
  for _,i in ipairs(chosen) do
   local hit;for _,v in ipairs(U.hits) do if v.index==i and Bridge.pickTrayDie(v.x,v.y)==i then hit=v end end
   if hit then U:mousepressed(hit.x,hit.y,1) else U:keypressed(tostring(i)) end
  end
  assert(R.selection(U.game));shot(prefix..'selected');click('take');assert(U.game.pot>0);shot(prefix..'held')
  for _,hit in ipairs(U.hits) do assert(not U.game.used[hit.index],'held die remains pickable in tray') end
  for _,i in ipairs(chosen) do assert(U.presentation.shelf[i].value==U.game.hand[i] and U.presentation.shelf[i].roll>0) end
  local held=chosen[1];local p={unpack(dice[held].body.position)};click('roll');shot(prefix..'reroll');wait()
  for k=1,3 do assert(math.abs(dice[held].body.position[k]-p[k])<1e-8,'held die moved') end
  record('PASS '..w..' physical throw, selection, held dice, reroll and input lock')
  for n=1,6 do
   U:reset('build');feed({1,1,1,1,1,1})
   for i=1,n do click('die'..i) end;click('take')
   require('src.features.farkle.presentation').finish(U.presentation)
   shot(prefix..'shelf-'..n)
   assert(#U.hits==6-n,'wrong visible dice count')
   for i=1,n do assert(U.presentation.shelf[i].id==i and U.presentation.shelf[i].value==1) end
  end
  record('PASS '..w..' shelf 1-6 identities, values and non-pickable held dice')
  U:reset('build');feed({1,1,5,5,2,3});local eligible,count=H.eligible(U.game)
  assert(count==4 and not eligible[5] and not eligible[6]);shot(prefix..'duplicates')
  click('die1');click('die2');assert(R.selection(U.game)==20);shot(prefix..'duplicates-selected')
  assert(U.buttons.take.label:find('2 dice') and U.buttons.take.label:find('20'));assert(U.buttons.take.x==64)
  click('take');assert(U.game.pot==20);shot(prefix..'duplicates-held');click('bank')
  U:reset('build');feed({1,1,1,1,1,1});shot(prefix..'many-options');click('choices');shot(prefix..'choices-many');click('nextpage');assert(U.choicePage==2);click('prev');click('close')
  U:reset('build');U.game.stage=2;feed({1,3,3,3,4,6});click('choices');shot(prefix..'choices-abc')
  click('option1');assert(R.selection(U.game)==10);shot(prefix..'below-entry');U:draw();assert(not U.buttons.bank.enabled)
  click('choices');click('option2');assert(R.selection(U.game)==30)
  click('choices');click('option3');assert(R.selection(U.game)==40);shot(prefix..'entry-selected')
  U:draw();assert(U.buttons.bank.enabled);click('bank');assert(U.game.entered and U.game.bank==40)
  record('PASS '..w..' selectable A/B/C physical-ID alternatives, pagination and entry threshold')
  U:reset('build');feed({1,5,2,3,4,6});click('die1');click('take');assert(R.start(U.game));U.state='rolling';U.pending={};U.observed={}
  U:onDiceSettled({{index=2,value=2},{index=3,value=2},{index=4,value=3},{index=5,value=4},{index=6,value=6}})
  assert(U.lastLoss==10 and U.game.phase=='ended');shot(prefix..'farkle');click('next');assert(U.game.turn==2)
  feed({1,5,2,3,4,6});click('die1');click('bank');assert(U.lastBank==10 and U.game.bank==10);shot(prefix..'bank')
  U:keypressed('?');shot(prefix..'help');local bank=U.game.bank;U:keypressed('n');assert(U.game.bank==bank and U.game.phase=='ended');U:keypressed('escape');assert(not U.modal)
  U:keypressed('?');click('helpTab2');assert(U.helpTab==2);shot(prefix..'rules-scores')
  U:keypressed('right');assert(U.helpTab==3);shot(prefix..'rules-special')
  U:keypressed('left');assert(U.helpTab==2);click('helpTab1');assert(U.helpTab==1)
  U:keypressed('escape');assert(not U.modal)
  U:keypressed('f');shot(prefix..'folio');U:keypressed('escape');assert(not U.modal)
  U:reset('build');feed({1,2,3,4,5,6});for i=1,6 do click('die'..i) end;click('take');assert(U.game.hot);shot(prefix..'hot');click('bank');assert(U.game.phase=='upgrade');shot(prefix..'upgrade');bounds()
  click('engraved');assert(U.game.stage==2 and U.game.build=='engraved')
  feed({1,1,1,5,5,5});for i=1,6 do click('die'..i) end;click('bank');assert(U.game.phase=='medal');shot(prefix..'medal');click('medal');shot(prefix..'build')
  feed({2,2,3,3,4,6});assert(U.game.phase=='rescue');shot(prefix..'rescue');click('fail');assert(U.game.phase=='ended')
  U:reset('build');U.game.turn=4;feed({2,2,3,3,4,6});assert(U.game.phase=='lost');shot(prefix..'lost');bounds()
  U:reset('build');U.game.stage=3;feed({1,1,1,5,5,5});for i=1,6 do click('die'..i) end;click('take');assert(R.start(U.game));assert(R.settle(U.game,{1,1,1,2,3,4}));U:sync()
  for i=1,3 do click('die'..i) end;click('bank');assert(U.game.phase=='won');shot(prefix..'won')
  click('runmenu');shot(prefix..'run-menu');local old=U.game;U:keypressed('r');assert(U.game==old)
  U:keypressed('escape');assert(not U.modal and U.game==old);click('runmenu');click('control')
  assert(U.game.mode=='control');record('PASS '..w..' Farkle loss, bank, hot dice, commissions, upgrades, medals, modals, duplicate hints and run menu')
  click('runmenu');click('medals');shot(prefix..'reference-catalog')
  click('inspect2');shot(prefix..'reference-pending');U:drawDeskOverlays(U.hits);assert(not U.modalButtons.equip.enabled)
  click('inspect1');click('equip');assert(U.game.medal=='reroll_tin' and U.game.turn==1 and U.game.bank==0)
  shot(prefix..'reference-equipped');click('roll');wait()
  while U.game.phase=='ended' do click('next');click('roll');wait() end
  assert(U.game.phase=='ready','no valid throw within reference commission')
  click('medaluse');shot(prefix..'reference-select');click('target1');shot(prefix..'reference-activation')
  local old={};for i=2,6 do old[i]={unpack(dice[i].body.position)} end
  click('activate');shot(prefix..'reference-rolling');wait()
  for i=2,6 do for k=1,3 do assert(dice[i].body.position[k]==old[i][k],'excluded die moved during medal roll') end end
  assert(require('src.gameplay.farkle.medals').remaining(U.game)==0)
  shot(prefix..'reference-result');click('medaluse');shot(prefix..'reference-spent');click('close')
  U:reset('build');assert(U:equip_reference('bank_multiplier_gold'));feed({1,1,1,2,3,4})
  for i=1,3 do click('die'..i) end;click('medaluse');shot(prefix..'reference-bank-preview');click('activate')
  assert(U.game.bank==150 and U.game.phase=='upgrade');shot(prefix..'reference-bank-result')
  record('PASS '..w..' reference catalog, blocked entry, equipment, real selective roll and multiplier bank')
 end
 function love.load()
  load()
  co=coroutine.create(function()
   if os.getenv('MANUSCRIPT_UI_V2_REVIEW_CAPTURE')=='1' then
    review_scenario(1920,1080)
    review_scenario(1280,720)
    record('PASS current UI V2 visual review at both resolutions')
   else
    scenario(1920,1080)
    scenario(1280,720)
    record('PASS all HUD scenarios at both resolutions')
   end
   log:close()
   love.event.quit(0)
  end)
 end
 function love.update(dt) elapsed=elapsed+dt;assert(elapsed<180,'HUD smoke timeout');update(dt) end
 -- Audit-only hitbox snapshot, taken during the SAME rendered frame
 -- as the PNG. All coordinates below are real SCREEN pixels, calculated
 -- through the authoritative resolution manager. No production input edits.
 local function write_review_hitboxes(name)
  if os.getenv('MANUSCRIPT_UI_V2_REVIEW_CAPTURE')~='1' then return end
  local file=assert(io.open(root..name..'.hitboxes.tsv','wb'))
  file:write('id\tx\ty\tw\th\tenabled\tsource\n')
  local function emit(id,r,enabled,source)
   if not r or type(r.x)~='number' or type(r.y)~='number'
    or type(r.w)~='number' or type(r.h)~='number' then return end
   local x,y=Res.to_screen(r.x,r.y)
   local scale=Res.get_scale()
   -- All screen-space coordinates are finite and within the output image.
   assert(x==x and y==y and scale>0 and r.w>0 and r.h>0,
    'invalid review click rectangle')
   file:write(string.format('%s\t%.4f\t%.4f\t%.4f\t%.4f\t%s\t%s\n',
    id,x,y,r.w*scale,r.h*scale,enabled and '1' or '0',source))
  end
  local active=U.modal and U.modalButtons or U.buttons
  local ids={}
  for id in pairs(active or {}) do ids[#ids+1]=id end
  table.sort(ids)
  for _,id in ipairs(ids) do
   local b=active[id]
   emit(id,b,b.enabled,U.modal and 'modal'
    or H.reward_active(U.game) and 'reward' or 'game')
  end
  -- Physical tray bounds are already in screen pixels. It is drawn in
  -- blue in the review gallery, never mistaken for a button hitbox.
  local tray=Bridge.getDiceTrayRect()
  if tray then
   file:write(string.format('__tray__\t%.4f\t%.4f\t%.4f\t%.4f\t0\ttray\n',
    tray.x,tray.y,tray.w,tray.h))
  end
  file:close()
 end
 function love.draw()
  draw();frames=frames+1
  local p=U.trayProjection
  if p then
   for _,v in ipairs(p.points) do
    local x,y=p.cx+v[1]*p.scale,p.cy+v[2]*p.scale
    assert(x>=p.rect.x and x<=p.rect.x+p.rect.w and y>=p.rect.y and y<=p.rect.y+p.rect.h,'projected geometry clipped')
   end
  end
  if frames%10~=0 then return end
  if pending then
   if pending.wait and U.game.phase=='rolling' then return end
   if pending.shot then
    local name=pending.shot;write_review_hitboxes(name)
    love.graphics.captureScreenshot(function(data)
     local f=assert(io.open(root..name..'.png','wb'));f:write(data:encode('png'):getString());f:close()
    end);record('SCREENSHOT '..name);pending=nil;return
   end
  end
  if coroutine.status(co)~='dead' then local ok,value=coroutine.resume(co);assert(ok,value);pending=value end
 end
end
return M
