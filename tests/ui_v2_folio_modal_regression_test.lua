-- P0 graphics-headless UI regression: render the real legacy modal
-- dispatcher with a small LÖVE graphics mock, never fake Farkle rules.
local R=require('src.gameplay.farkle.rules')
local P=require('src.features.farkle.presentation')
local Res=require('src.core.resolution_manager')
local Hud=require('src.features.farkle.hud')

unpack=unpack or table.unpack
local displayed={}
local pushes,pops=0,0
local function noop() end
local font={
 getWidth=function(_,label) return #tostring(label)*10 end,
 getHeight=function()return 23 end,
 getWrap=function(_,label) return 120,{tostring(label)} end
}
local gfx=setmetatable({
 newFont=function(...) return font end,
 printf=function(label,...) displayed[#displayed+1]=tostring(label) end,
 print=function(label,...) displayed[#displayed+1]=tostring(label) end,
 push=function() pushes=pushes+1 end,
 pop=function() pops=pops+1 end,
}, {__index=function(_,key)
 return noop
end})
love={graphics=gfx}

local function check_modal(state,w,h)
 Res.init(1920,1080)
 Res.refresh(w,h)
 local u={game=state,modal='folio',buttons={bank={enabled=false}},
   presentation=P.new(state)}
 local saved=u.buttons
 local bank,pot,stage,turn,phase=state.bank,state.pot,state.stage,state.turn,state.phase
 local depth=pushes-pops
 displayed={}
 Hud.overlay(u,{})
 assert(pushes==pops and pushes-pops==depth,
  'folio must balance the LÖVE UI transform stack')
 assert(u.buttons==saved,
  'modal must not replace/steal the normal Farkle action table')
 assert(u.modalButtons and u.modalButtons.close and u.modalButtons.close.enabled,
  'folio modal must preserve Close [Esc]')
 assert(u.modal=='folio' and u.game==state,
  'opening a read-only folio must not end the session')
 assert(state.bank==bank and state.pot==pot and state.stage==stage
     and state.turn==turn and state.phase==phase,
  'displaying the folio may not alter Farkle score or phase')
 local sawFolio,sawBank,sawPot=false,false,false
 for _,label in ipairs(displayed) do
  if label:find('FOLIO',1,true) then sawFolio=true end
  if label:find('assicurati',1,true) then sawBank=true end
  if label:find('a rischio',1,true) then sawPot=true end
 end
 assert(sawFolio and sawBank and sawPot,
  'folio modal must use the actual folio renderer and show both score types')
 u.modalButtons.close.fn()
 assert(u.modal==nil,'Close must leave score/game intact')
end
local fresh=R.new()
local ready=R.new()
assert(R.start(ready))
assert(R.settle(ready,{1,5,2,3,4,6}))
ready.bank=30;ready.pot=15
local advanced=R.new()
advanced.stage=2;advanced.bank=75;advanced.pot=40
local scenarios={{fresh,1920,1080},{fresh,1280,720},
 {ready,1920,1080},{ready,1280,720},{advanced,2560,1080}}
for _,scenario in ipairs(scenarios) do check_modal(unpack(scenario)) end

-- Existing modal dispatch also must not regressed by the folio repair.
Res.refresh(1920,1080)
for _,mode in ipairs({'run','help','choices','medals'}) do
 local state=R.new()
 local u={game=state,modal=mode,buttons={roll={enabled=true}},presentation=P.new(state)}
 displayed={}
 Hud.overlay(u,{})
 assert(u.buttons.roll and u.modalButtons and u.modalButtons.close,
  'folio repair must not remove '..mode..' dialog commands')
 assert(pushes==pops,'dialog stack unbalanced: '..mode)
end

print('PASS P0 folio: real modal rendering, score preservation, viewport alignment and unchanged other dialogs')
