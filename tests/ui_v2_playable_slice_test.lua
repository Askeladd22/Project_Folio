-- P2 experimental HUD action contract: pure rules, real callbacks, no LOVE.
local R=require('src.gameplay.farkle.rules')
local H=require('src.features.farkle.hud_model')
local A=require('src.features.farkle.ui_v2.actions')
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local Res=require('src.core.resolution_manager')

local function owner(game)
 return {game=game,events={},act=function(self,name,fn)
   self.events[#self.events+1]=name
   return fn()
 end,request=function(self,technical)
   self.events[#self.events+1]=technical and 'rescue' or 'roll'
 end,retry_physical=function(self)
   self.events[#self.events+1]='physical'
 end}
end
local function items(u)
 local result={}
 for _,a in ipairs(A.build(u)) do
  assert(not result[a.id],'duplicate UI action '..a.id)
  assert(type(a.fn)=='function' and type(a.enabled)=='boolean'
    and a.slot~=nil,'malformed action '..a.id)
  result[a.id]=a
 end
 return result
end
local function check_region(id,layout)
 return id=='help' or id=='runmenu' and layout.header or
        id=='folio' and layout.folio
end

local fresh=R.new()
local u=owner(fresh)
local a=items(u)
assert(a.help.enabled and a.runmenu.enabled and a.folio.enabled)
assert(a.roll and a.roll.enabled and a.roll.slot=='primary')
assert(a.bank and not a.bank.enabled and a.bank.slot=='secondary')
assert(not a.take and not a.next and not a.retryphysical)
a.roll.fn()
assert(u.events[#u.events]=='roll' and fresh.phase=='fresh',
 'UI dispatch must call controller request, NOT roll/scoring engine directly')
assert(R.start(fresh))
local rolling=items(u)
assert(not rolling.roll or not rolling.roll.enabled)
assert(not rolling.bank or not rolling.bank.enabled)
assert(not rolling.folio.enabled and not rolling.help.enabled)
assert(R.settle(fresh,{1,1,1,1,1,1}) and fresh.phase=='ready')
local ready=items(u)
assert(ready.choices and ready.choices.enabled and
       ready.roll and not ready.roll.enabled)
for i=1,6 do assert(R.toggle(fresh,i)) end
local selected=items(u)
assert(selected.take and selected.take.enabled)
assert(selected.bank and selected.bank.enabled,
 'direct banking of a VALID selection must remain available')
assert(not selected.roll)
assert(R.selection(fresh))
selected.bank.fn()
assert(u.events[#u.events]=='bank' and fresh.pot==0 and fresh.bank>0,
 'banking must delegate to unchanged R.bank_turn through controller')

local pending=owner(R.new())
pending.manualRoll={count=3}
local p=items(pending)
assert(p.roll and not p.roll.enabled,
 'P2 must not allow the automatic roll during physical partial release')
assert(A.state(pending):find('3 dadi',1,true),
 'manual physical release needs a dedicated status')
pending.mouseThrow={held={1,2,3},group=true}
assert(A.state(pending):find('GRUPPO DI 3',1,true),
 'physical selection state must not be confused with scoring')
local errorOwner=owner(R.new())
errorOwner.physicalFailure='Invalid physical faces'
local e=items(errorOwner)
assert(e.retryphysical and e.retryphysical.enabled and not e.roll)
e.retryphysical.fn()
assert(errorOwner.events[#errorOwner.events]=='physical',
 'technical retry is separate from Farkle reroll')

local bad=R.new()
assert(R.start(bad) and R.settle(bad,{2,3,4,6,2,4}) and bad.phase=='ended')
local ended=items(owner(bad))
assert(ended.next and ended.next.enabled and not ended.roll)
local rescueGame=R.new()
rescueGame.medal='retry'
assert(R.start(rescueGame))
assert(R.settle(rescueGame,{2,3,4,6,2,4}) and rescueGame.phase=='rescue')
local resc=owner(rescueGame)
local opts=items(resc)
assert(opts.rescue and opts.fail and opts.rescue.enabled and opts.fail.enabled)
opts.fail.fn()
assert(rescueGame.phase=='ended')
assert(resc.events[#resc.events]=='accept_bust')

for _,phase in ipairs({'upgrade','medal'}) do
 local reward=R.new()
 reward.phase=phase
 assert(H.reward_active(reward))
 assert(#A.build(owner(reward))==0,
  'existing legacy reward overlay owns its own actions during P2')
end
for _,phase in ipairs({'won','lost'}) do
 local done=R.new()
 done.phase=phase
 local buttons=items(owner(done))
 assert(not buttons.roll and not buttons.next and not buttons.bank)
end
local advancing=R.new()
advancing.phase='advance'
assert(items(owner(advancing)).next)

local layout=Layout.build('single_folio')
assert(Layout.validate(layout))
local regions={}
regions.primary=layout.primary
regions.secondary=layout.secondary
regions.context=layout.context
regions.folio=layout.folio
for _,r in pairs(regions) do assert(not Layout.overlap(r,layout.tray) or
                                 Layout.overlap(r,layout.tray)==0) end
Res.init(1920,1080)
for _,wh in ipairs({{1920,1080},{1280,720},{2560,1440}}) do
 Res.refresh(wh[1],wh[2])
 for _,r in pairs(regions) do
  local sx,sy=Res.to_screen(r.x+r.w/2,r.y+r.h/2)
  local vx,vy=Res.to_virtual(sx,sy)
  assert(math.abs(vx-(r.x+r.w/2))<1e-7)
  assert(math.abs(vy-(r.y+r.h/2))<1e-7)
 end
end
Res.refresh(1920,1080)
local function source(path)
 local f=assert(io.open(path));local s=f:read('*a');f:close();return s
end
local c=source('src/features/farkle/controller.lua')
assert(not c:find('hud_minimal',1,true),
 'retired frontend must have no production fallback')
assert(not c:find('MANUSCRIPT_UI_V2_EXPERIMENT',1,true))
assert(not c:find("if k=='f6'",1,true),
 'F6 must not switch back to deleted HUD')
assert(c:find("require('src.features.farkle.ui_v2.hud').draw(self)",1,true),
 'the V2 HUD must be the default display')
local v=source('src/features/farkle/ui_v2/hud.lua')
assert(v:find('Indicators.draw(u,hits)',1,true))
assert(v:find('Accepted.draw(u)',1,true))
assert(v:find('Dialogs.overlay(u,hits)',1,true))
assert(not v:find('hud_minimal',1,true))
assert(v:find('Folio.draw(s,u.presentation',1,true),
 'P2 folio must use current Farkle state')
assert(v:find('u.buttons[a.id]',1,true),
 'P2 must register input in original controller hitbox table')
print('PASS UI v2 default: Farkle actions, grip, reward/dialogs, no legacy fallback and hitbox projection')
