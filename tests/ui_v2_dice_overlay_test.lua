-- P3 UI v2: visual indicators never mutate Farkle, dice physics or clicks.
local R=require('src.gameplay.farkle.rules')
local Marquee=require('src.features.farkle.marquee_selection')
local Model=require('src.features.farkle.ui_v2.overlay_model')
local Overlay=require('src.features.farkle.ui_v2.overlay')
local Res=require('src.core.resolution_manager')
local UI=require('src.core.runtime_ui')

local function hits()
 local out={}
 for i=1,6 do out[i]={index=i,x=110+i*88,y=320,r=26} end
 return out
end
local function count_kind(projection,kind)
 local n=0
 for _,m in ipairs(projection.markers) do
  if m.kind==kind then n=n+1 end
 end
 return n
end
local game=R.new()
local u={game=game}
local physical=hits()
local fresh=Model.build(u,physical)
assert(#fresh.markers==0 and not fresh.hand and not fresh.marquee)
local marquee=Marquee.begin(100,240)
assert(Marquee.move(marquee,720,440))
u.marquee=marquee
local selection=Model.build(u,physical)
assert(selection.marquee and selection.marquee.w==620 and
       selection.marquee.h==200 and #selection.markers==0)
u.marquee=nil
u.dragSelected={[1]=true,[2]=true,[3]=true,
 [4]=true,[5]=true,[6]=true}
selection=Model.build(u,physical)
assert(selection.physicalCount==6 and
       count_kind(selection,'physical')==6)
u.mouseThrow={group=true,held={1,2,3,4,5,6},
 x0=120,y0=300,x=580,y=360}
local held=Model.build(u,physical)
assert(held.hand and held.hand.count==6 and
       #held.markers==0,'held group must NOT draw six rings or brackets')
u.mouseThrow={x0=150,y0=320,x=260,y=330}
held=Model.build(u,physical)
assert(held.hand.count==1 and #held.markers==0,
 'single-hand state should not show the physical group markers')
u.mouseThrow=nil
u.dragSelected=nil

assert(R.start(game))
local beforePot=game.pot
assert(R.settle(game,{1,1,1,1,1,1}) and game.phase=='ready')
local eligible=Model.build(u,physical)
assert(count_kind(eligible,'eligible')==6)
assert(R.toggle(game,1))
local scored=Model.build(u,physical)
assert(count_kind(scored,'score')==1 and
       count_kind(scored,'eligible')==5)
assert(game.pot==beforePot and game.selected[1],
 'visual model changed score or selection')
u.modal='folio'
assert(#Model.build(u,physical).markers==0)
u.modal=nil

local invalid=R.new()
assert(R.start(invalid) and R.settle(invalid,{2,2,2,3,4,6}))
assert(R.toggle(invalid,1))
local bad=Model.build({game=invalid},physical)
assert(count_kind(bad,'invalid')==1,
 'a lone non-scoring 2 must not look like valid scoring')
invalid.phase='rolling'
assert(#Model.build({game=invalid},physical).markers==0)
invalid.phase='upgrade'
assert(#Model.build({game=invalid},physical).markers==0)
assert(#Model.build({game=game},{{index=9,x=1,y=2},
 {index=1,x=math.huge,y=5},{index=2,x=0/0,y=6}}).markers==0,
 'malformed projected hits must not be displayed')

Res.init(1920,1080)
for _,size in ipairs({{1920,1080},{1280,720},{2560,1080},{3440,1440}}) do
 Res.refresh(size[1],size[2])
 local x,y=Res.to_screen(430,380)
 local candidate=Model.build(u,{{roll_index=3,x=x,y=y,r=19}})
 assert(#candidate.markers==1 and candidate.markers[1].x==x
   and candidate.markers[1].y==y,
  'P3 must reuse projected screen hit coordinates at every viewport')
end

-- Rendering mock checks that the P3 painter uses strokes, never circles,
-- and restores graphics state, even with contrast and large-text settings.
local prevLove=love
local prevScale,prevBig,prevContrast=UI.scale,UI.big_text,UI.high_contrast
local calls={push=0,pop=0,line=0,circle=0,print=0}
love={graphics={
 push=function() calls.push=calls.push+1 end,
 pop=function() calls.pop=calls.pop+1 end,
 setColor=function() end,
 setLineWidth=function() end,
 line=function() calls.line=calls.line+1 end,
 circle=function() calls.circle=calls.circle+1 end,
 rectangle=function() end,
 setFont=function() end,
 print=function() calls.print=calls.print+1 end,
 newFont=function(pt) return {getWidth=function(_,txt) return #txt*pt*.55 end} end
}}
UI.scale=function() return 1.25 end
UI.big_text=function() return true end
UI.high_contrast=function() return true end
Overlay.draw(u,physical)
assert(calls.line>0 and calls.circle==0 and calls.push==calls.pop,
 'V2 score brackets must not use giant rings or leak graphics state')
u.mouseThrow={group=true,held={1,2,3,4,5,6},x=500,y=380}
local previousLines=calls.line
Overlay.draw(u,physical)
assert(calls.print==1 and calls.line==previousLines+4
   and calls.circle==0 and calls.push==calls.pop,
 'group grip must have one badge and only four reticle strokes')
love=prevLove
UI.scale,UI.big_text,UI.high_contrast=prevScale,prevBig,prevContrast
print('PASS UI v2 P3: scoring/physical precedence, real-screen hits, held group one-badge feedback, graphics isolation and unchanged Farkle')
