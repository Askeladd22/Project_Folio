local R=require('src.gameplay.farkle.rules')
local Medals=require('src.gameplay.farkle.medals')
local D=require('src.features.farkle.dice')
local H=require('src.features.farkle.hud_model')
local Res=require('src.core.resolution_manager')
local Bridge=require('src.core.engine_bridge')
local Presentation=require('src.features.farkle.presentation')
local RuntimeUI=require('src.core.runtime_ui')
local Audio=require('src.core.audio_manager')
-- Single in-game HUD: the manuscript view.
local U={state='waiting',buttons={},dice_results={}}
function U:getTrayRect()
 local t = require('src.features.farkle.hud_minimal').tray
 local x,y=Res.to_screen(t.x,t.y);return {x=x,y=y,w=t.w*Res.get_scale(),h=t.h*Res.get_scale()}
end
function U:getTrayProjection(tray,view,extents)
 return require('src.features.farkle.tray_view').fit(self,tray,view,extents)
end
function U:isDeskLayout() return true end
function U:enter(params) if not self.game or (params and params.new_run) then self:reset('build') end end
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
 self.game=R.new(mode);self.pending={};self.retry=nil;self.activePhysical=nil;self.dice_results={};self.medalHeld=nil
 self.modal=nil;self.lastLoss=nil;self.lastBank=nil;self.physicalFailure=nil;self.physicalNotice=nil
 self.id=os.date('%Y%m%d-%H%M%S')..'-'..math.floor(love.timer.getTime()*1000)
 D.install(self.game.build);self:sync();self:log('new')
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
 end
end
function U:begin_physical(indices)
 self:sync_presentation()
 if self.presentation then Presentation.finish(self.presentation) end
 self.activePhysical={};for _,i in ipairs(indices) do self.activePhysical[i]=true end
 for i,d in ipairs(dice) do d.kept=not self.activePhysical[i] end
 self.state='rolling';self.onRollRequest(nil,indices)
end
function U:request(rescue)
 local s=self.game
 if not (rescue and R.rescue(s) or not rescue and R.start(s)) then return false end
 if rescue then Audio.play_farkle('medal') end
 self.medalHeld=nil
 self.pending={};self.observed={};self.retry=nil;self:log(rescue and 'medal_retry' or 'roll')
 self.lastLoss=nil;self.lastBank=nil
 self:begin_physical(s.active);return true
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
  self.pending={};self.observed={};self.retry=nil;self.lastLoss=nil;self.lastBank=nil
  self:begin_physical(self.game.active)
 else self.lastBank=self.game.bank-bank;self.lastLoss=nil;self:sync() end
 return true
end
function U:onPhysicalFailure(event)
 self.state='physics_error';self:log('physical_failure',event.reason)
end
function U:retry_physical()
 if self.state~='physics_error' then return end
 local indices={}
 for i=1,#dice do if self.activePhysical and self.activePhysical[i] then indices[#indices+1]=i end end
 if #indices==0 then return false end
 self:begin_physical(indices)
end
function U:update(dt)
 self:sync_presentation()
 if self.presentation then Presentation.update(self.presentation,dt,RuntimeUI.reduced_animations()) end
 if self.retry then
  self.retry=self.retry-dt
  if self.retry<=0 then self.retry=nil;self:begin_physical({1}) end
 end
end
function U:onDiceSettled(values)
 local s=self.game;local rejected=false
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
  return
 end
 local pot=s.pot
 -- Only accepted gameplay throws get an origin ID. Technical retries and
 -- rejected weighted proposals never create a second logical throw.
 local accepted={};for _,i in ipairs(s.active) do accepted[#accepted+1]=i end
 assert(R.settle(s,self.pending),'Invalid physical face callback')
 self.presentation=self.presentation or Presentation.new(s)
 Presentation.accepted(self.presentation,accepted)
 if s.phase=='ended' or s.phase=='lost' then self.lastLoss=pot end
 self.activePhysical=nil;self.dice_results={};self:sync();self:log('settled',table.concat(s.hand,'/'))
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
 require('src.features.farkle.hud_minimal').draw(self)
end
function U:drawDeskOverlays(hits)
 require('src.features.farkle.hud_minimal').overlay(self,hits)
end
function U:mousepressed(x,y,b)
 if b~=1 or self.state=='rolling' then return end
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
function U:keypressed(k)
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
