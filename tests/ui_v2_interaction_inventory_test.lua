-- P0: executable inventory of shipping Farkle UI interactions.
-- Intentional baseline test, not a new HUD / gameplay rules implementation.
-- Structural checks must be updated ONLY after equivalent functionality
-- migrates to UI v2; otherwise they detect accidentally lost controls.
local R=require('src.gameplay.farkle.rules')
local H=require('src.features.farkle.hud_model')
local Marquee=require('src.features.farkle.marquee_selection')
local Res=require('src.core.resolution_manager')

local function read(path)
 local file=assert(io.open(path,'r'),'baseline source missing: '..path)
 local data=file:read('*a');file:close();return data
end
local sources={
 hud=read('src/features/farkle/hud_minimal.lua'),
 modals=read('src/features/farkle/hud.lua'),
 medal=read('src/features/farkle/medal_panel.lua'),
 controller=read('src/features/farkle/controller.lua'),
 runtime=read('src/app/dice_runtime.lua'),
 doc=read('docs/UI_V2_INTERACTION_MATRIX.md')
}
local function exact(source,fragment,where)
 assert(source:find(fragment,1,true),where..' lost: '..fragment)
end
local buttons={
 hud={"'help'","'runmenu'","'folio'","'roll'","'take'",
      "'bank'","'next'","'rescue'","'fail'","'retryphysical'",
      "'choices'","'medaluse'"},
 modals={"'weighted'","'engraved'","'medal'","'none'","'close'",
         "'restart'","'control'","'medals'","'prev'",
         "'nextpage'","'helpTab'..i","'option'..row"},
 medal={"'inspect'..n","'equip'","'medalprev'","'medalnext'",
        "'target'..i","'activate'"}
}
for section,ids in pairs(buttons) do
 for _,id in ipairs(ids) do
  exact(sources[section],id,section..' button')
  local label=id:gsub("'",''):gsub("%.%.%a+",'')
  if label=='option' then label='option1'
  elseif label=='inspect' then label='inspect1'
  elseif label=='target' then label='target1'
  elseif label=='helpTab' then label='helpTab1' end
  exact(sources.doc,label,'documented UI v2 control')
 end
end
for _,fragment in ipairs({
 "function U:mousepressed(x,y,b)","function U:mousereleased(x,y,b)",
 "function U:mousemoved(x,y)","function U:keypressed(k)",
 "R.can_roll(self.game)","Bridge.pickTrayDie(x,y)",
 "Marquee.choose(selection,Bridge.getTrayDieHits()",
 "self.dragSelected","self.manualRoll.pending",
 "GroupThrow.begin(selected,dice","GroupThrow.release(held",
 "MouseThrow.release(held","self.logicalRollId",
 "H.reward_active(self.game)","self.modalButtons"
}) do exact(sources.controller,fragment,'controller input path') end

-- Preserve precedence when redesigning: Esc cancels grip and marquee
-- before closing modal/ending the application. Do not hijack scoring.
local c=sources.controller
local function pos(s) return assert(c:find(s,1,true),s..' missing') end
local escape_hold=pos("if k=='escape' and self.mouseThrow then")
local escape_marquee=pos("if k=='escape' and self.marquee then")
local escape_selection=pos("if k=='escape' and self.dragSelected")
local escape_modal=pos("if k=='escape' then if self.modal")
assert(escape_hold<escape_marquee and escape_marquee<escape_selection
 and escape_selection<escape_modal,'Esc priority changed from the P0 baseline')
local space=pos("if k=='space' then")
local take=pos("if self.buttons['take']")
local roll=pos("if self.buttons['roll']")
local next_turn=pos("if self.buttons['next']")
local rescue=pos("if self.buttons['rescue']")
assert(space<take and take<roll and roll<next_turn and next_turn<rescue,
 'Space must prioritize take/roll/next/rescue')
for _,key in ipairs({"if k=='f8'","if k=='tab'","if k=='f'",
                      "if k=='space'","if k=='return'",
                      "or k=='kpenter'","space='roll'","a='take'",
                      "n='next'","m='rescue'"}) do
 exact(c,key,'keyboard shortcut')
end
for _,key in ipairs({"'f10'","'f11'"}) do
 exact(sources.runtime,key,'renderer debug shortcut')
end
assert(not sources.runtime:find("key=='f9'",1,true),
 'F9 CPU painter shortcut was intentionally retired')
exact(sources.hud,'u.buttons = {}','single active HUD button table')
exact(sources.modals,'u.modalButtons={}','modal-specific active button table')
exact(sources.hud,'u.dragSelected[hit.index or hit.roll_index]',
 'group-grab highlight distinct from scoring selection')
exact(sources.hud,'s.selected[i] or eligible[i]',
 'scoring highlight distinct from physical grab')
exact(sources.medal,'u.medalDice','third independent selection for medal targets')

-- Actual rules, never guessed UI booleans: scoring must be unavailable
-- while a physical roll is unsettled and before a valid combination.
local s=R.new()
assert(s.phase=='fresh' and R.can_roll(s))
assert(not H.reward_active(s) and not H.commission_closed(s))
assert(not R.selection(s) and next(s.selected)==nil)
local rect=assert(Marquee.begin(100,110))
assert(Marquee.move(rect,290,250))
local physical=Marquee.choose(rect,{
 {index=1,x=150,y=140},{index=2,x=250,y=160},
 {index=3,x=350,y=180}},function(i) return i<=2 end)
assert(physical[1] and physical[2] and not physical[3])
assert(Marquee.count(physical)==2)
assert(s.phase=='fresh' and next(s.selected)==nil and s.turn==1,
 'marquee must not start a Farkle roll or select scoring dice')
assert(not Marquee.dragged({x0=100,y0=100,x=102,y=101}))
assert(R.start(s) and s.phase=='rolling')
assert(not R.can_roll(s) and not R.toggle(s,1))
local rollingEligible=H.eligible(s)
assert(#R.options(s)==0 and not rollingEligible[1])
assert(R.settle(s,{1,1,5,2,3,4}) and s.phase=='ready')
local eligible=H.eligible(s)
assert(eligible[1] and eligible[2] and eligible[3])
assert(not R.can_roll(s),'cannot reroll before scoring selection')
assert(R.toggle(s,1) and R.selection(s)==10)
assert(not R.can_roll(s),'pending score selection must not trigger roll')
assert(R.take(s) and s.pot==10 and s.used[1] and R.can_roll(s))
assert(next(s.selected)==nil,'take must clear scoring selection')
assert(H.selected_count(s)==0)
assert(type(R.bank_status(s))=='boolean')
assert(H.reward_active({phase='upgrade'}) and H.reward_active({phase='medal'}))
-- 'ended' is intentionally NOT commission_closed: the player must be
-- able to press 'next' and begin another turn in the same commission.
assert(not H.commission_closed({phase='ended'}),
 'ended is a turn boundary, not a finished commission')
for _,phase in ipairs({'advance','won','lost','upgrade','medal'}) do
 assert(H.commission_closed({phase=phase}),phase..' must close the commission')
end
local bust=R.new();assert(R.start(bust))
assert(R.settle(bust,{2,3,4,6,2,4}) and bust.phase=='ended')
assert(not R.can_roll(bust) and R.next_turn(bust) and bust.phase=='fresh')
local rescued=R.new();rescued.medal='retry'
assert(R.start(rescued))
assert(R.settle(rescued,{2,3,4,6,2,4}) and rescued.phase=='rescue')
assert(not R.can_roll(rescued) and R.rescue(rescued))
assert(rescued.phase=='rolling' and rescued.medalUsed)

-- Screen vs UI coordinates: current picking and HUD cannot be treated
-- as the same coordinate system, especially on ultrawide displays.
Res.init(1920,1080);Res.refresh(1280,720)
local vx,vy=Res.to_virtual(640,360)
assert(math.abs(vx-960)<1e-8 and math.abs(vy-540)<1e-8)
local sx,sy=Res.to_screen(vx,vy)
assert(math.abs(sx-640)<1e-8 and math.abs(sy-360)<1e-8)
Res.refresh(2560,1080)
local ex,ey=Res.to_screen(0,0)
assert(math.abs(ex-320)<1e-8 and math.abs(ey)<1e-8,
 'ultrawide letterbox must be included in UI hitboxes')
local ux,uy=Res.to_virtual(ex+720,ey+540)
assert(math.abs(ux-720)<1e-8 and math.abs(uy-540)<1e-8)
Res.refresh(1920,1080)

print('PASS UI v2 P0: legacy action inventory, modal IDs, shortcut precedence, physical/scoring split and viewport mapping')
