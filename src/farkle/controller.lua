local R=require('src.farkle.rules')
local Medals=R.medals
local D=require('src.farkle.dice')
local H=require('src.farkle.presentation').hud_model
local Res=require('src.core.navigation').resolution
local Bridge=require('src.core.engine_bridge')
local Presentation=require('src.farkle.presentation')
local RuntimeUI=require('src.core.runtime_state').ui
local Audio=require('src.core.audio_manager')
local Interaction=require('src.farkle.interaction')
local MouseThrow=Interaction.single
local Marquee=Interaction.selection
local GroupThrow=Interaction.group
local Toasts=require('src.farkle.presentation').toast_messages
-- Production policy is intentionally self-contained. The independently
-- tested laboratory remains in its own directory; runtime must not import it.
local OpponentAI = {}
local outcome = {
 [1]={6,4,15}, [2]={36,16,180}, [3]={216,60,1850},
 [4]={1296,204,18310}, [5]={7776,600,197195},
 [6]={46656,1080,2399175},
}
function OpponentAI.best_option(options)
 local best
 for _,o in ipairs(options) do
  if not best or o.points>best.points
   or (o.points==best.points and o.remaining>best.remaining)
   or (o.points==best.points and o.remaining==best.remaining and o.mask<best.mask) then
   best=o
  end
 end
 return best
end
function OpponentAI.decide(s)
 if s.score.opponent+s.pot>=s.target then
  return 'bank','Raggiungo l’obiettivo.'
 end
 local available=0
 for i=1,6 do if not s.used[i] then available=available+1 end end
 if available==0 then available=6 end
 local o=outcome[available]
 if o[3]<=o[2]*s.pot then
  return 'bank',('Rischio %d/%d, meglio incassare.'):format(o[2],o[1])
 end
 return 'roll',('Rischio %d/%d, tento un rilancio.'):format(o[2],o[1])
end
-- The new folio interface is the only gameplay HUD.
-- No environment-controlled HUD variant and no F6 layout switch.
local U={state='waiting',buttons={},dice_results={}}
function U:getTrayRect()
 local t=require('src.farkle.ui').layout
    .build().tray
 local x,y=Res.to_screen(t.x,t.y);return {x=x,y=y,w=t.w*Res.get_scale(),h=t.h*Res.get_scale()}
end
function U:getTrayProjection(tray,view,extents)
 return require('src.farkle.tabletop').tray_view.fit(self,tray,view,extents)
end
function U:isDeskLayout() return true end
-- Visual identity alone: scores, physics, turn state and buttons are unchanged.
function U:setOpponentVisual(id)
 self.opponentId=require('src.farkle.ui').opponent_scene.validate_id(id)
end
function U:enter(params)
 if params and (params.opponent_id or params.new_run) then
  self:setOpponentVisual(params.opponent_id)
 end
 if not self.game or (params and params.new_run) then
  self:reset(params and params.mode or 'build')
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
 Audio.stop_dice('shake',.045)
 Toasts.clear()
 self.mouseThrow=nil
 self.manualRoll=nil
 self.marquee=nil
 self.dragSelected=nil
 self.game=R.new(mode)
 if mode=='duel' then self.game.duel_target=500 end
 self.duel=mode=='duel' and {actor='player',scores={player=0,opponent=0},target=self.game.duel_target,wait=0,intent='Il Opponent attende il tuo lancio.'} or nil
 self.pending={};self.retry=nil;self.activePhysical=nil;self.dice_results={};self.medalHeld=nil
 self.modal=nil;self.lastLoss=nil;self.lastBank=nil;self.physicalFailure=nil;self.physicalNotice=nil
 self.id=os.date('%Y%m%d-%H%M%S')..'-'..math.floor(love.timer.getTime()*1000)
 self.logicalRollId=0;self.physicalAttemptId=0
 D.install(self.game.build)
 D.stage_opening(dice)
 self:sync();self:log('new')
 self:log('session_seed',self.sessionSeed or 'unknown')
end
function U:duel_bank()
 local s=self.game
 if not self.duel or s.mode~='duel' or not R.bank_status(s) then return false end
 if next(s.selected) and not R.take(s) then return false end
 s.bank=s.bank+s.pot
 s.pot=0
 s.phase=s.bank>=self.duel.target and 'won' or 'ended'
 s.last='Punti incassati nel duello.'
 return true
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
  if self.duel and name=='bank' then
   local d=self.duel
   d.scores[d.actor]=self.game.bank
   d.wait=.95
   if self.game.phase=='won' then
    d.winner=d.actor
    d.intent=d.actor=='player' and 'Hai battuto il Opponent!' or 'Il Opponent ha vinto la sfida.'
   else d.intent=d.actor=='player' and 'Hai incassato. Tocca al Opponent.' or 'Il Opponent ha incassato.' end
  end
  if name=='bank' then Toasts.show('Punti incassati: +'..(self.lastBank or 0))
   elseif name=='accept_bust' then Toasts.show('Farkle: punti a rischio perduti') end
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
 Audio.stop_dice('shake',.045)
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
 Audio.stop_dice('shake',.045)
 self.manualRoll=nil
 self.mouseThrow=nil
 self.marquee=nil
 self.dragSelected=nil
 self.state='physics_error';self.physicalFailure=event and event.reason or 'Errore fisico: riprova il tiro';self:log('physical_failure',self.physicalFailure)
end
function U:retry_physical()
 if self.state~='physics_error' then return end
 local indices={}
 for i=1,#dice do if self.activePhysical and self.activePhysical[i] then indices[#indices+1]=i end end
 if #indices==0 then return false end
 self.physicalFailure=nil
 self:begin_physical(indices,true,nil,not self.duel or self.duel.actor=='player')
end
function U:update_duel(dt)
 local d,s=self.duel,self.game
 if not d or d.winner or self.modal or self.physicalFailure or self.retry or s.phase=='rolling' then return end
 d.wait=math.max(0,(d.wait or 0)-math.max(0,dt or 0))
 if d.wait>0 then return end
 if s.phase=='ended' then
  d.scores[d.actor]=s.bank
  assert(R.next_turn(s),'duel turn must close before actor swap')
  s.turn=1 -- do not import the solo four-turn limit into a symmetric duel
  d.actor=d.actor=='player' and 'opponent' or 'player'
  s.bank=d.scores[d.actor]
  s.entered=s.bank>0
  self.lastLoss=nil;self.lastBank=nil
  self.presentation=Presentation.new(s)
  D.stage_opening(dice)
  self:sync()
  d.intent=d.actor=='player' and 'Tocca a te: sfida il Opponent.' or 'Il Opponent prepara il lancio.'
  d.wait=.7
  self:log('duel_actor',d.actor)
  return
 end
 if d.actor~='opponent' then return end
 if s.phase=='fresh' then
  d.intent='Il Opponent lancia i dadi.'
  assert(self:request(),'opponent physical roll must start')
 elseif s.phase=='ready' and not s.scored then
  local option=OpponentAI.best_option(R.options(s))
  assert(option,'ready throw needs at least one legal option')
  for _,id in ipairs(option.ids) do assert(R.toggle(s,id)) end
  self:act('take',function() return R.take(s) end)
  d.intent=('Il Opponent accantona %d punti.'):format(option.points)
  d.wait=.95
 elseif s.phase=='ready' and s.scored then
  if not d.pending_action then
   local action,reason=OpponentAI.decide({phase='decision',pot=s.pot,
    actor='opponent',score={opponent=s.bank},target=d.target,used=s.used})
   d.pending_action=action
   d.intent=(action=='bank' and 'Il Opponent incassa. ' or 'Il Opponent rilancia. ')..reason
   d.wait=.95 -- reveal intention before the action, not afterwards
   return
  end
  local action=d.pending_action
  d.pending_action=nil
  if action=='bank' then
   self:act('bank',function() return self:duel_bank() end)
  else
   assert(self:request(),'opponent physical reroll must start')
  end
 end
end
function U:update(dt)
 if self.mouseThrow then
  if not self.game or self.modal then
   Audio.stop_dice('shake',.045)
   if self.mouseThrow.group then GroupThrow.cancel(self.mouseThrow)
   else MouseThrow.cancel(self.mouseThrow) end
   self.mouseThrow=nil
  else
   local held=self.mouseThrow
   held.motion_idle=(held.motion_idle or 0)+math.max(0,dt or 0)
   if held.sound_shaking and held.motion_idle>=.085 then
    Audio.stop_dice('shake',.045)
    held.sound_shaking=false
   end
   if held.group then GroupThrow.tick(held,dt)
   else MouseThrow.tick(self.mouseThrow,dt) end
  end
 end
 self:sync_presentation()
 if self.presentation then Presentation.update(self.presentation,dt,RuntimeUI.reduced_animations()) end
 Toasts.update(dt)
 self:update_duel(dt)
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
 if s.phase=='ended' or s.phase=='lost' then
  if self.duel then
   self.duel.intent=self.duel.actor=='opponent' and 'Il Opponent fa Farkle.' or 'Farkle: perdi i punti a rischio.'
   self.duel.wait=.9
  end
  Toasts.show('Farkle: turno concluso')
 end
 return true
end
function U:toggle(i) if R.toggle(self.game,i) then self:log('select',i) end end
function U:draw()
 require('src.farkle.ui').hud.draw(self)
end
function U:drawDeskOverlays(hits)
 require('src.farkle.ui').hud.overlay(self,hits)
 Toasts.draw(self.modal~=nil or H.reward_active(self.game))
end
-- Left-drag creates a *physical-grab selection*, never a Farkle score
-- selection. Right-drag a selected die throws all selected physical bodies.
-- Unselected dice can still be thrown individually, in the same logical roll.
local function can_grab(u)
 if not u.game or u.modal or H.reward_active(u.game) or
  u.state=='physics_error' then return false end
 if u.manualRoll then return u.manualRoll.count>0 end
 if u.duel and (u.duel.actor~='player' or u.duel.winner) then return false end
 return u.state~='rolling' and R.can_roll(u.game)
 
end

local function in_tray(x,y)
 local r=Bridge.getDiceTrayRect()
 return r and x>=r.x and x<=r.x+r.w and
   y>=r.y and y<=r.y+r.h
end

function U:mousepressed(x,y,b)
 if self.duel and (self.duel.actor=='opponent' or self.duel.winner) and not self.modal then
  if b==1 and self.state~='rolling' then
   local vx,vy=Res.to_virtual(x,y)
   for id,r in pairs(self.buttons) do
    if (id=='help' or id=='runmenu' or id=='retryphysical') and r.enabled and
     vx>=r.x and vx<=r.x+r.w and vy>=r.y and vy<=r.y+r.h then r.fn();return end
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
     require('src.data.dice_schema').scene.box,i,hx,hy)
  else
   self.mouseThrow=MouseThrow.begin(i,dice[i].body,x,y,love.timer.getTime())
  end
  -- One audible grab per successful gesture, even when 2–6 bodies are held.
  if self.mouseThrow then
   self.mouseThrow.motion_idle=0
   self.mouseThrow.sound_shaking=false
   Audio.play_dice('grab',{count=self.mouseThrow.group and #self.mouseThrow.held or 1})
  end
  return
 end

 if b~=1 or self.mouseThrow then return end
 -- The near wooden lip now sits behind the command plaque. Action hitboxes
 -- must win over drag-to-throw inside that small overlapping screen area.
 if not self.modal and not H.reward_active(self.game) and self.state~='rolling' then
  local vx,vy=Res.to_virtual(x,y)
  for _,button in pairs(self.buttons) do
   if button.enabled and type(button.x)=='number' and type(button.y)=='number' and
      type(button.w)=='number' and type(button.h)=='number' and
      vx>=button.x and vx<=button.x+button.w and
      vy>=button.y and vy<=button.y+button.h then button.fn();return end
  end
 end
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
  local held=self.mouseThrow
  -- Pointer jitter must not sustain the shake indefinitely.
  local dx,dy=x-(held.x or x),y-(held.y or y)
  if dx*dx+dy*dy>=4 then held.motion_idle=0 end
  local detector=held.group and held.shaker or held.shake
  local before=detector and detector.events or 0
  local move=held.group and GroupThrow.move or MouseThrow.move
  local moved=move(held,x,y,love.timer.getTime(),
    require('src.engine3d.view'),self.trayScale or 1,
    require('src.data.dice_schema').scene.box)
  -- Trigger only when the existing real shake detector certifies a
  -- new reversal event. Dragging, pointer jitter and physics ticks are silent.
  if moved and detector and detector.events>before then
   local strength=held.group and detector.detector.strength or detector.strength
   held.sound_shaking=Audio.play_dice('shake',{
     count=held.group and #held.held or 1,
     strength=strength
   })
  end
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
 Audio.stop_dice('shake',.045)
 if not self.manualRoll then
  if held.group then GroupThrow.cancel(held) else MouseThrow.cancel(held) end
  return
 end
 local view=require('src.engine3d.view')
 local scale=self.trayScale or 1
 local bounds=require('src.data.dice_schema').scene.box
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
   -- The physical runtime now consumes this very same pending/count table.
   local before=self.manualRoll.count
   assert(self.onManualRollRelease and self.onManualRollRelease(i),
    'manual physical release did not reach the runtime')
   assert(self.manualRoll.count==before-1 and not self.manualRoll.pending[i],
    'manual runtime did not consume exactly one queued die')
   if self.dragSelected then self.dragSelected[i]=nil end
   self:log('die_released',i)
   if self.manualRoll.count==0 then self.manualRoll=nil;self.dragSelected=nil end
  end
 end
 -- The actual physical impacts, not mouse release, own the throw audio.
end
function U:keypressed(k)
 if k=='escape' and self.mouseThrow then
  Audio.stop_dice('shake',.045)
  if self.mouseThrow.group then GroupThrow.cancel(self.mouseThrow)
  else MouseThrow.cancel(self.mouseThrow) end
  self.mouseThrow=nil;return
 end
 if k=='escape' and self.marquee then self.marquee=nil;return end
 if k=='escape' and self.dragSelected and next(self.dragSelected) then
  self.dragSelected=nil;return
 end
 if k=='f8' then require('src.farkle.tabletop').tray_workshop.cycle();return end
 if k=='tab' and self.presentation then Presentation.finish(self.presentation);return end
 if H.reward_active(self.game) then return end
 -- Esc never quits the application from an active run. A physical throw
 -- must settle before pause can open; no half-resolved roll is interrupted.
 if k=='escape' then
  if self.modal=='run_restart_confirm' or self.modal=='run_exit_confirm' then
   self.modal='run'
  elseif self.modal then self.modal=nil
  elseif self.state~='rolling' then self.modal='run' end
  return
 end
 if self.state=='rolling' then return end
 -- Keep the experimental medal laboratory for developers, but not in the
 -- normal pause menu. It remains separate from the selected game's mode.
 if k=='f7' and not self.modal and not self.duel then
  self.modal='medals';self.medalPage=1;self.medalPreview=nil
  return
 end
 if self.modal then
  if self.modal=='help' and (k=='left' or k=='right') then self.helpTab=((self.helpTab or 1)-1+(k=='right' and 1 or -1))%3+1 end
  return
 end
 if k=='?' or k=='/' or k=='slash' then self.modal='help';return end
 if self.duel and (self.duel.actor=='opponent' or self.duel.winner) then return end
 if k=='f' then self.modal='folio';return end
 local i=tonumber(k);if i and i>=1 and i<=6 then self:toggle(i);return end

 if k=='return' or k=='kpenter' then
  if self.buttons['bank'] and self.buttons['bank'].enabled then self.buttons['bank'].fn();return end
  if self.buttons['next'] and self.buttons['next'].enabled then self.buttons['next'].fn();return end
 end
 local id=({a='take',['return']='bank',n='next',r='restart',b='control',m='rescue'})[k]
 local bt=id and self.buttons[id];if bt and bt.enabled then bt.fn() end
end
return U
