local R=require('src.gameplay.farkle.rules')
local Medals=require('src.gameplay.farkle.medals')
local D=require('src.features.farkle.dice')
local H=require('src.features.farkle.hud_model')
local Res=require('src.core.resolution_manager')
local Bridge=require('src.core.engine_bridge')
local Presentation=require('src.features.farkle.presentation')
local RuntimeUI=require('src.core.runtime_ui')
local Audio=require('src.core.audio_manager')
local MouseThrow=require('src.features.farkle.mouse_throw')
local Marquee=require('src.features.farkle.marquee_selection')
local GroupThrow=require('src.features.farkle.group_throw')
local BotDuel=require('src.gameplay.farkle.bot_duel')
local Toasts=require('src.features.farkle.toast_messages')
-- The new folio interface is the only gameplay HUD.
-- The MANUSCRIPT_UI_V2_EXPERIMENT opt-in/F6 legacy switch is retired.
local U={state='waiting',buttons={},dice_results={}}
function U:getTrayRect()
 local t=require('src.features.farkle.ui_v2.layout_candidates')
    .build('single_folio').tray
 local x,y=Res.to_screen(t.x,t.y);return {x=x,y=y,w=t.w*Res.get_scale(),h=t.h*Res.get_scale()}
end
function U:getTrayProjection(tray,view,extents)
 return require('src.features.farkle.tray_view').fit(self,tray,view,extents)
end
function U:isDeskLayout() return true end
function U:enter(params)
 if not self.game or (params and params.new_run) then
  self.duelActive=params and params.bot_duel==true or false
  self:reset(self.duelActive and 'control' or 'build')
 end
end
function U:log(event,detail)
 local s=self.game
 if not love.filesystem.getInfo('runs.csv') then love.filesystem.write('runs.csv','run,mode,commission,turn,build,medal,event,bank,pot,detail\n') end
 love.filesystem.append('runs.csv',table.concat({self.id,s.mode,s.stage,s.turn,s.build,s.medal,event,s.bank,s.pot,tostring(detail or '')},',')..'\n')
end
function U:sync()
 for i,d in ipairs(dice or {}) do d.kept=self.game.used[i] or (self.medalHeld and self.medalHeld[i]) or false end
 if self.game.phase~='rolling' then self.state=self.game.phase=='fresh' and 'waiting' or 'placing' end
 self:sync_presentation()
end
function U:sync_presentation()
 if not self.game or not self.game.used then return end
 self.presentation=self.presentation or Presentation.new(self.game)
 local event=Presentation.observe(self.presentation,self.game,self.hits,RuntimeUI.reduced_animations())
 if event then Audio.play_farkle(event) end
end
function U:shouldDrawTrayDie(index) return not (self.game and self.game.used[index]) end
function U:reset(mode)
 if self.state=='rolling' then return end
 Toasts.clear()
 if self.duelActive then
  -- A separate LÖVE generator keeps the opponent's virtual rolls independent
  -- of the player's physical physics RNG and accepted face gate.
  local seed=os.time()+math.floor(love.timer.getTime()*1000)
  local rng=love.math.newRandomGenerator(seed)
  self.botDuel=BotDuel.new(function(a,b) return rng:random(a,b) end)
  require('src.features.farkle.bot_duel_view').reset()
 else
  self.botDuel=nil
 end
 self.mouseThrow=nil
 self.manualRoll=nil
 self.marquee=nil
 self.dragSelected=nil
 self.game=R.new(self.duelActive and 'control' or mode);self.pending={};self.retry=nil;self.activePhysical=nil;self.dice_results={};self.medalHeld=nil
 self.modal=nil;self.lastLoss=nil;self.lastBank=nil;self.physicalFailure=nil;self.physicalNotice=nil
 self.id=os.date('%Y%m%d-%H%M%S')..'-'..math.floor(love.timer.getTime()*1000)
 self.logicalRollId=0;self.physicalAttemptId=0
 D.install(self.game.build);self:sync();self:log('new')
 self:log('session_seed',self.sessionSeed or 'unknown')
end
function U:after_duel_turn()
 if not self.botDuel then return end
 local event=self.botDuel:after_player_turn(self.game)
 if not event then return end
 require('src.features.farkle.bot_duel_view').on_turn(event)
 self:log('bot_turn',
   tostring(event.report.turn)..'/'..tostring(event.report.rolls)..
   '/'..tostring(event.report.banked))
 if event.finished then
  local label=event.winner=='player' and 'Hai vinto la sfida!' or
    event.winner=='bot' and 'Il monaco ha vinto la sfida.' or
    'Parita nella sfida.'
  Toasts.show(label)
 elseif event.report.loss then
  Toasts.show('Il monaco ha fatto Farkle!')
 else
  Toasts.show('Il monaco incassa +'..event.report.banked..' punti.')
 end
end
function U:act(name,fn)
 local pot=self.game.pot;local bank=self.game.bank
 self:sync_presentation()
 local before=Presentation.prepare(self.presentation,self.game)
 if fn() then
  if name=='take' or name=='bank' then Presentation.commit(self.presentation,self.game,before,name,RuntimeUI.reduced_animations()) end
  if name=='accept_bust' then self.lastLoss=pot end
  if name=='bank' then self.lastBank=self.game.bank-bank;self.lastLoss=nil end
  if name=='next' then self.lastLoss=nil;self.lastBank=nil end
  self:sync();self:log(name)
  local duel_event=self.botDuel and
    (name=='bank' or name=='accept_bust' or name=='next')
  if duel_event then self:after_duel_turn()
  elseif not self.botDuel then
   if name=='bank' then Toasts.show('Punti incassati: +'..(self.lastBank or 0))
   elseif name=='accept_bust' then Toasts.show('Farkle: punti a rischio perduti') end
  end
 end
end
function U:begin_physical(indices,technical,gesture,manual)
 self.physicalAttemptId=(self.physicalAttemptId or 0)+1
 self:log('physical_attempt',tostring(self.logicalRollId or 0)..'/'..tostring(self.physicalAttemptId))
 self:sync_presentation()
 if self.presentation then Presentation.finish(self.presentation) end
 self.activePhysical={};for _,i in ipairs(indices) do self.activePhysical[i]=true end
 for i,d in ipairs(dice) do d.kept=not self.activePhysical[i] end
 self.state='rolling'
 if not manual then self.dragSelected=nil;self.marquee=nil end
 if manual then
  local pending={}
  for _,i in ipairs(indices) do pending[i]=true end
  self.manualRoll={pending=pending,count=#indices}
  assert(type(self.onManualRollBegin)=='function','manual runtime unavailable')
  self.onManualRollBegin(indices)
 else
  self.manualRoll=nil
  self.onRollRequest(nil,indices,technical == true,gesture)
 end
end
function U:request(rescue,gesture,manual)
 local s=self.game
 if not (rescue and R.rescue(s) or not rescue and R.start(s)) then return false end
 if rescue then Audio.play_farkle('medal') end
 self.medalHeld=nil
 self.logicalRollId=(self.logicalRollId or 0)+1
 self.pending={};self.observed={};self.retry=nil;self:log(rescue and 'medal_retry' or 'roll',self.logicalRollId)
 self.lastLoss=nil;self.lastBank=nil
 self.mouseThrow=nil
 if not manual then self.dragSelected=nil end
 self:begin_physical(s.active,nil,gesture,manual);return true
end
function U:equip_reference(id)
 if self.state=='rolling' or self.state=='physics_error' then return false end
 local d=Medals.get(id);if not d or not d.enabled then return false end
 local build,stage=self.game.build,self.game.stage
 self:reset('build');self.game.build=build;self.game.stage=stage
 assert(R.equip_reference(self.game,id));D.install(build);self:sync();self:log('reference_equipped',id)
 return true
end
function U:activate_reference(indices)
 if self.state=='rolling' or self.state=='physics_error' then return false end
 local bank=self.game.bank
 self:sync_presentation()
 local before=Presentation.prepare(self.presentation,self.game)
 if not R.use_reference(self.game,indices) then return false end
 Audio.play_farkle('medal')
 if self.game.bank>bank then Presentation.commit(self.presentation,self.game,before,'medal',RuntimeUI.reduced_animations()) end
 self.modal=nil;self:log('reference_used',self.game.medal)
 if self.game.phase=='rolling' then
  -- Retained dice remain selectable but excluded from physics until the next
  -- ordinary throw. Otherwise the idle solver could move an accepted result.
  self.medalHeld={};for i=1,6 do self.medalHeld[i]=true end
  for _,i in ipairs(self.game.active) do self.medalHeld[i]=nil end
  self.logicalRollId=(self.logicalRollId or 0)+1
  self.pending={};self.observed={};self.retry=nil;self.lastLoss=nil;self.lastBank=nil
  self:begin_physical(self.game.active)
 else self.lastBank=self.game.bank-bank;self.lastLoss=nil;self:sync() end
 return true
end
function U:onPhysicalFailure(event)
 self.manualRoll=nil
 self.mouseThrow=nil
 self.marquee=nil
 self.dragSelected=nil
 self.state='physics_error';self:log('physical_failure',event.reason)
end
function U:retry_physical()
 if self.state~='physics_error' then return end
 local indices={}
 for i=1,#dice do if self.activePhysical and self.activePhysical[i] then indices[#indices+1]=i end end
 if #indices==0 then return false end
 self:begin_physical(indices,true)
end
function U:update(dt)
 if self.mouseThrow then
  if not self.game or self.modal then
   if self.mouseThrow.group then GroupThrow.cancel(self.mouseThrow)
   else MouseThrow.cancel(self.mouseThrow) end
   self.mouseThrow=nil
  else
   if self.mouseThrow.group then GroupThrow.tick(self.mouseThrow,dt)
   else MouseThrow.tick(self.mouseThrow,dt) end
  end
 end
 self:sync_presentation()
 if self.presentation then Presentation.update(self.presentation,dt,RuntimeUI.reduced_animations()) end
 Toasts.update(dt)
 if self.botDuel then require('src.features.farkle.bot_duel_view').update(dt) end
 if self.retry then
  self.retry=self.retry-dt
  if self.retry<=0 then self.retry=nil;self:begin_physical({1},true) end
 end
end
function U:onDiceSettled(values)
 local s=self.game
 if not s or s.phase~='rolling' then return false end
 local rejected=false
 for _,v in ipairs(values) do
  self.pending[v.index]=v.value;self.observed[v.index]=v.value
  if s.build=='weighted' and v.index==1 then
   local accepted=D.accept(v.value,love.math.random())
   self:log('weighted_proposal',v.value..'/'..(accepted and 'accepted' or 'retry'))
   if not accepted then rejected=true;self.pending[1]=nil end
  end
 end
 if rejected then
  -- Defer: main.lua clears last_roll_indices after this callback returns.
  self.retry=.65;s.last='Weighted die: automatically rerolling die 1 physically.'
  self.activePhysical={};for _,d in ipairs(dice) do d.kept=true end
  return false
 end
 local pot=s.pot
 -- Only accepted gameplay throws get an origin ID. Technical retries and
 -- rejected weighted proposals never create a second logical throw.
 local accepted={};for _,i in ipairs(s.active) do accepted[#accepted+1]=i end
 assert(R.settle(s,self.pending),'Invalid physical face callback')
 self.presentation=self.presentation or Presentation.new(s)
 Presentation.accepted(self.presentation,accepted)
 if s.phase=='ended' or s.phase=='lost' then self.lastLoss=pot end
 self.activePhysical=nil;self.manualRoll=nil;self.marquee=nil;self.dragSelected=nil;self.dice_results={};self:sync();self:log('settled',table.concat(s.hand,'/'))
 if self.botDuel then self:after_duel_turn()
 elseif s.phase=='ended' or s.phase=='lost' then
  Toasts.show('Farkle: turno concluso')
 end
 return true
end
function U:toggle(i) if R.toggle(self.game,i) then self:log('select',i) end end
function U:select_option(mask)
 for _,o in ipairs(R.options(self.game)) do if o.mask==mask then
  self.game.selected={};for _,id in ipairs(o.ids) do self.game.selected[id]=true end
  self:log('select_option',mask);return true
 end end
 return false
end
function U:draw()
 require('src.features.farkle.ui_v2.hud').draw(self)
end
function U:drawDeskOverlays(hits)
 require('src.features.farkle.ui_v2.hud').overlay(self,hits)
 if self.botDuel and not self.modal then
  require('src.features.farkle.bot_duel_view').draw(self.botDuel)
 end
 Toasts.draw(self.modal~=nil or H.reward_active(self.game))
end
-- Left-drag creates a *physical-grab selection*, never a Farkle score
-- selection. Right-drag a selected die throws all selected physical bodies.
-- Unselected dice can still be thrown individually, in the same logical roll.
local function can_grab(u)
 if not u.game or u.modal or H.reward_active(u.game) or
  u.state=='physics_error' then return false end
 if u.manualRoll then return u.manualRoll.count>0 end
 return u.state~='rolling' and R.can_roll(u.game)
  and u.buttons.roll and u.buttons.roll.enabled
end

local function in_tray(x,y)
 local r=Bridge.getDiceTrayRect()
 return r and x>=r.x and x<=r.x+r.w and
   y>=r.y and y<=r.y+r.h
end

function U:mousepressed(x,y,b)
 if self.botDuel and self.botDuel.finished then
  if b==1 then
   local vx,vy=Res.to_virtual(x,y)
   if vx>=780 and vx<=1130 and vy>=540 and vy<=585 then
    self:reset('control')
   end
  end
  return
 end
 if b==2 then
  if self.mouseThrow or self.marquee or not can_grab(self) then return end
  local clicked=Bridge.pickTrayDie(x,y)
  local selected={}
  if self.dragSelected then
   for k in pairs(self.dragSelected) do
    if dice and dice[k] and not dice[k].kept and
       (not self.manualRoll or self.manualRoll.pending[k]) then
     selected[#selected+1]=k
    end
   end
   table.sort(selected)
  end
  -- A selected group can be gathered even by pressing right on an EMPTY
  -- patch of parchment. Right clicking a nonselected die still grabs only it.
  local use_group=#selected>1 and in_tray(x,y) and
      (not clicked or self.dragSelected[clicked])
  local i=use_group and (clicked or selected[1]) or clicked
  if not i or not dice or not dice[i] or dice[i].kept then return end
  if not self.manualRoll and not self:request(false,nil,true) then return end
  if not (self.manualRoll and self.manualRoll.pending[i]) then return end

  if use_group then
   local hx,hy=nil,nil
   for _,hit in ipairs(Bridge.getTrayDieHits()) do
    if hit.index==i then hx,hy=hit.x,hit.y;break end
   end
   -- In a blank-area grab, the cursor is offset from the anchor die's
   -- projected center, so the constellation still converges at the pointer.
   self.mouseThrow=GroupThrow.begin(selected,dice,x,y,love.timer.getTime(),
     require('src.engine3d.view'),self.trayScale or 1,
     require('src.data.dice_scene_schema').box,i,hx,hy)
  else
   self.mouseThrow=MouseThrow.begin(i,dice[i].body,x,y,love.timer.getTime())
  end
  return
 end

 if b~=1 or self.mouseThrow then return end
 -- A click on the tray is handled on release so that clicking still selects
 -- Farkle scoring dice, whereas an actual drag creates a group marquee.
 if can_grab(self) and in_tray(x,y) then
  self.marquee=Marquee.begin(x,y)
  return
 end
 if self.state=='rolling' then return end
 local vx,vy=Res.to_virtual(x,y)
 if H.reward_active(self.game) then
  local allowed=self.game.phase=='upgrade' and {weighted=true,engraved=true} or {medal=true,none=true}
  for id,r in pairs(self.buttons) do if allowed[id] and r.enabled and vx>=r.x and vx<=r.x+r.w and vy>=r.y and vy<=r.y+r.h then r.fn();return end end
  return
 end
 if self.modal then
  for _,r in pairs(self.modalButtons or {}) do if r.enabled and vx>=r.x and vx<=r.x+r.w and vy>=r.y and vy<=r.y+r.h then r.fn();return end end
  return
 end
 for _,r in pairs(self.buttons) do if r.enabled and vx>=r.x and vx<=r.x+r.w and vy>=r.y and vy<=r.y+r.h then r.fn();return end end
 local i=Bridge.pickTrayDie(x,y);if i then self:toggle(i) end
end
function U:mousemoved(x,y)
 if self.marquee then Marquee.move(self.marquee,x,y) end
 if self.mouseThrow then
  local move=self.mouseThrow.group and GroupThrow.move or MouseThrow.move
  move(self.mouseThrow,x,y,love.timer.getTime(),
    require('src.engine3d.view'),self.trayScale or 1,
    require('src.data.dice_scene_schema').box)
 end
end
function U:mousereleased(x,y,b)
 if b==1 and self.marquee then
  local selection=self.marquee
  self.marquee=nil
  Marquee.move(selection,x,y)
  if Marquee.dragged(selection) then
   self.dragSelected=Marquee.choose(selection,Bridge.getTrayDieHits(),function(i)
    if not dice or not dice[i] or dice[i].kept then return false end
    if self.manualRoll then return self.manualRoll.pending[i]==true end
    return R.can_roll(self.game)
   end)
   return
  end
  -- Preserve the existing ordinary left click for Farkle scoring.
  if self.state~='rolling' then
   local i=Bridge.pickTrayDie(selection.x0,selection.y0)
   if i then self:toggle(i) end
  end
  return
 end
 if b~=2 or not self.mouseThrow then return end
 local held=self.mouseThrow
 self.mouseThrow=nil
 if not self.manualRoll then
  if held.group then GroupThrow.cancel(held) else MouseThrow.cancel(held) end
  return
 end
 local view=require('src.engine3d.view')
 local scale=self.trayScale or 1
 local bounds=require('src.data.dice_scene_schema').box
 local releases={}
 if held.group then
  releases=GroupThrow.release(held,x,y,love.timer.getTime(),view,scale,bounds) or {}
 else
  local one=MouseThrow.release(held,x,y,love.timer.getTime(),view,scale,bounds)
  if one then releases={one} end
 end
 for _,released in ipairs(releases) do
  local i=released.index
  if self.manualRoll and self.manualRoll.pending[i] then
   self.manualRoll.pending[i]=nil
   self.manualRoll.count=self.manualRoll.count-1
   assert(self.onManualRollRelease and self.onManualRollRelease(i),
    'manual physical release did not reach the runtime')
   if self.dragSelected then self.dragSelected[i]=nil end
   self:log('die_released',i)
   if self.manualRoll.count==0 then self.manualRoll=nil;self.dragSelected=nil end
  end
 end
end
function U:keypressed(k)
 if self.botDuel and self.botDuel.finished then
  if k=='r' then self:reset('control')
  elseif k=='escape' then require('src.core.navigation').go('main_menu') end
  return
 end
 if k=='escape' and self.mouseThrow then
  if self.mouseThrow.group then GroupThrow.cancel(self.mouseThrow)
  else MouseThrow.cancel(self.mouseThrow) end
  self.mouseThrow=nil;return
 end
 if k=='escape' and self.marquee then self.marquee=nil;return end
 if k=='escape' and self.dragSelected and next(self.dragSelected) then
  self.dragSelected=nil;return
 end
 if k=='f8' then require('src.features.farkle.tray_workshop').cycle();return end
 if k=='tab' and self.presentation then Presentation.finish(self.presentation);return end
 if H.reward_active(self.game) then return end
 if k=='escape' then if self.modal then self.modal=nil else love.event.quit() end;return end
 if self.state=='rolling' then return end
 if self.modal then
  if self.modal=='help' and (k=='left' or k=='right') then self.helpTab=((self.helpTab or 1)-1+(k=='right' and 1 or -1))%3+1 end
  return
 end
 if k=='?' or k=='/' or k=='slash' then self.modal='help';return end
 if k=='f' then self.modal='folio';return end
 local i=tonumber(k);if i and i>=1 and i<=6 then self:toggle(i);return end
 if k=='space' then
   if self.buttons['take'] and self.buttons['take'].enabled then self.buttons['take'].fn();return end
   if self.buttons['roll'] and self.buttons['roll'].enabled then self.buttons['roll'].fn();return end
   if self.buttons['next'] and self.buttons['next'].enabled then self.buttons['next'].fn();return end
   if self.buttons['rescue'] and self.buttons['rescue'].enabled then self.buttons['rescue'].fn();return end
  end
 if k=='return' or k=='kpenter' then
  if self.buttons['bank'] and self.buttons['bank'].enabled then self.buttons['bank'].fn();return end
  if self.buttons['next'] and self.buttons['next'].enabled then self.buttons['next'].fn();return end
 end
 local id=({space='roll',a='take',['return']='bank',n='next',r='restart',b='control',m='rescue'})[k]
 local bt=id and self.buttons[id];if bt and bt.enabled then bt.fn() end
end
return U
