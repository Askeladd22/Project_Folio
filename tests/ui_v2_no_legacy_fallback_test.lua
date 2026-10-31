-- After the V2 cutover there is one gameplay HUD, not a selectable
-- fallback. Exercise the accepted-dice register with real geometry and
-- graphics stubs at all supported display scales.
local R=require('src.gameplay.farkle.rules')
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local Shelf=require('src.features.farkle.ui_v2.accepted_dice')
local Res=require('src.core.resolution_manager')
local P=require('src.features.farkle.presentation')
local function source(path)
 local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s
end

for _,path in ipairs{'src/features/farkle/hud_minimal.lua',
 'src/features/farkle/hud.lua','tests/smoke/compare_huds.lua'} do
 local f=io.open(path,'rb')
 assert(not f,'retired UI fallback must not be in the repository: '..path)
end
local controller=source('src/features/farkle/controller.lua')
local hud=source('src/features/farkle/ui_v2/hud.lua')
assert(controller:find("require('src.features.farkle.ui_v2.hud').draw(self)",1,true))
assert(controller:find("require('src.features.farkle.ui_v2.hud').overlay(self,hits)",1,true))
assert(not controller:find("require('src.features.farkle.hud_minimal')",1,true))
assert(not controller:find("MANUSCRIPT_UI_V2_EXPERIMENT",1,true),
 'retired developer env fallback should be completely deleted')
assert(not controller:find("k=='f6'",1,true))
assert(not hud:find("hud_minimal",1,true))
assert(hud:find("Dialogs.overlay(u,hits)",1,true))
assert(hud:find("Accepted.draw(u)",1,true))
assert(hud:find("Indicators.draw(u,hits)",1,true))
assert(not hud:find("F6: torna",1,true))

local base=Layout.build('single_folio')
local slots=Shelf.slots(base)
assert(#slots==6)
for i=1,6 do
 local rect=slots[i]
 assert(Layout.contains(base.shelf,rect),'accepted slot outside V2 shelf')
 assert(Layout.overlap(rect,base.tray)==0,'accepted slot covers physical dice')
 if i>1 then assert(Layout.overlap(rect,slots[i-1])==0) end
end

local previousLove=love
local previousDice=dice
local strokes={push=0,pop=0,rect=0,text=0}
local fakeFont={getHeight=function()return 16 end,
 getWidth=function(_,s)return #tostring(s)*9 end}
love={graphics=setmetatable({
 push=function() strokes.push=strokes.push+1 end,
 pop=function() strokes.pop=strokes.pop+1 end,
 newFont=function()return fakeFont end,
 rectangle=function() strokes.rect=strokes.rect+1 end,
 printf=function() strokes.text=strokes.text+1 end,
}, {__index=function()return function()end end})}
dice=nil
local state=R.new()
state.used[1]=true
state.hand[1]=5
local current={game=state,presentation=P.new(state)}
for _,size in ipairs{{1920,1080},{1280,720},{2560,1080}} do
 Res.init(1920,1080)
 Res.refresh(size[1],size[2])
 local original=state.hand[1]
 Shelf.draw(current)
 assert(state.hand[1]==original and state.used[1])
 assert(strokes.push==strokes.pop,'shelf graphics stack leaked')
end
assert(strokes.rect>=36 and strokes.text>=18,
 'six shelf slots must render at each resolution')
love=previousLove
dice=previousDice
print('PASS V2 sole HUD: removed fallback, aligned six-die register, no scorer mutation and viewport graphics stack')
