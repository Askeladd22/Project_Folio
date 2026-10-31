-- Headless integration test for Tabletop-style box selection and group release.
-- No graphics context, no FPS physics vendor dependency.
require('core')
local U=require('src.features.farkle.controller')
local R=require('src.gameplay.farkle.rules')
local Bridge=require('src.core.engine_bridge')
local M=require('src.features.farkle.marquee_selection')
local Group=require('src.features.farkle.group_throw')

local centers={}
for i=1,6 do centers[i]={index=i,x=100+40*i,y=140,r=15} end
local function pick(x,y)
 for _,h in ipairs(centers) do
  if math.abs(x-h.x)<18 and math.abs(y-h.y)<18 then return h.index end
 end
end
Bridge.configure({
 get_dice_tray_rect=function() return {x=90,y=90,w=320,h=200} end,
 get_tray_die_hits=function() return centers end,
 pick_scriptorium_tray_die=pick
})
local now=0
love={timer={getTime=function()return now end}}
local function body(i)
 local b={position=vector{-3+i,0,1},velocity=vector{0,0,0},
  angular=vector{0,0,0},asleep=true,sleep_timer=0,
  {1,1,1},{-1,-1,-1}}
 function b:update(dt) for _,v in ipairs(self) do v[1]=v[1]+dt*self.angular[2] end end
 return b
end
local starts,ends
local function fresh()
 dice={}
 for i=1,6 do dice[i]={body=body(i),kept=false} end
 U.game=R.new('build')
 U.state='waiting';U.buttons={roll={enabled=true}}
 U.mouseThrow=nil;U.manualRoll=nil;U.marquee=nil;U.dragSelected=nil;U.presentation=nil
 U.logicalRollId=0;U.physicalAttemptId=0;U.trayScale=25
 U.sync_presentation=function()end
 U.log=function()end
 starts,ends=0,{}
 U.onRollRequest=function() error('group selection must not call automatic launch') end
 U.onManualRollBegin=function(indices)
  starts=starts+1
  for _,i in ipairs(indices) do
   dice[i].body._manual_pending=true
   dice[i].body.asleep=true
  end
 end
 U.onManualRollRelease=function(index)
  assert(not dice[index].body._manual_pending)
  ends[#ends+1]=index
  return true
 end
end
local function marquee(x0,x1)
 U:mousepressed(x0,110,1)
 assert(U.marquee,'must start box selection from tray')
 now=now+.05;U:mousemoved(x1,170)
 U:mousereleased(x1,170,1)
end
local function fling(i)
 now=now+.2
 U:mousepressed(centers[i].x,centers[i].y,2)
 assert(U.mouseThrow,'selected die must be physically grabbed')
 now=now+.04;U:mousemoved(centers[i].x+75,centers[i].y-30)
 U:update(.03)
 now=now+.04;U:mousereleased(centers[i].x+110,centers[i].y-45,2)
end

assert(M.count(M.choose({x0=10,y0=10,x=50,y=50},
 {{index=1,x=20,y=20},{index=2,x=55,y=20},{index=3,x=40,y=40}},
 function(i)return i~=3 end))==1,'marquee geometry must respect gate and bounds')
local reversed=M.choose({x0=390,y0=170,x=110,y=110},centers)
assert(M.count(reversed)==6,'rectangle must work when dragged backwards')
assert(not M.dragged({x0=10,y0=10,x=12,y=12}),'tiny click is not a marquee')

fresh()
marquee(110,390)
assert(M.count(U.dragSelected)==6,'must select all six dice with one rectangle')
assert(U.logicalRollId==0 and U.game.phase=='fresh','selecting cannot start Farkle roll')
now=now+.2;U:mousepressed(centers[1].x,centers[1].y,2)
assert(U.mouseThrow and U.mouseThrow.group and #U.mouseThrow.held==6,
 'right grabbing one selected die must pick up the entire selected group')
local originalX=dice[1].body.position[1]
now=now+.05;U:mousemoved(centers[1].x+45,centers[1].y+30)
U:update(.03)
assert(dice[1].body.position[1]~=originalX,'group bodies must physically move')
assert(dice[2].body._grabbed and dice[6].body._grabbed,'entire group must be in hand')
-- Dice converge toward the right-clicked anchor, not their old
-- scattered positions; merely holding without moving keeps gathering them.
local grip=U.mouseThrow
assert(grip.targets and #grip.targets==6)
assert(math.abs(grip.anchor_x-dice[1].body.position[1])<5,
 'anchor should be derived from the clicked physical die')
for i=1,30 do U:update(.03) end
for j,member in ipairs(grip.held) do
 local pos,target=member.body.position,grip.targets[j]
 assert(math.abs(pos[1]-target.x)<.01 and math.abs(pos[2]-target.y)<.01,
  'all held physical dice must converge under the cursor')
end
local compactX=math.abs(dice[6].body.position[1]-dice[1].body.position[1])
assert(compactX<4,'selected six must be a compact group, not their original 5-unit spread')
-- Group boundaries clamp the constellation as a whole, never compress it.
now=now+.02;U:mousemoved(centers[1].x+5000,centers[1].y+30)
local t=U.mouseThrow.targets
local step=U.mouseThrow.offsets
assert(math.abs((t[6].x-t[1].x)-(step[6].x-step[1].x))<1e-9,
 'clamped group motion must preserve non-overlapping formation offsets')
for _,target in ipairs(t) do
 assert(target.x<=9.2 and target.x>=-9.2 and
        target.y<=3.8 and target.y>=-3.8,
  'all grouped dice targets must stay inside the physical board')
end
now=now+.02;U:mousemoved(centers[1].x+45,centers[1].y+30)
now=now+.06;U:mousereleased(centers[1].x+90,centers[1].y+35,2)
assert(#ends==6 and starts==1 and U.logicalRollId==1,
 'six released dice must be exactly one official Farkle roll')
for i=1,6 do
 local body=dice[i].body
 assert(body.position[1]>=-9.2 and body.position[1]<=9.2 and
        body.position[2]>=-3.8 and body.position[2]<=3.8,
  'release must preserve valid world-space die positions')
end
assert(U.manualRoll==nil and U.game.phase=='rolling' and U.game.pot==0,
 'no face scoring until full physical settlement')
for i=1,6 do assert(not dice[i].body._manual_pending and not dice[i].body.asleep) end

fresh()
marquee(110,210)
assert(M.count(U.dragSelected)==2,'partial selection should select two dice')
fling(1)
assert(#ends==2 and U.manualRoll and U.manualRoll.count==4,
 'a selected pair is thrown together while four remain queued')
marquee(215,390)
assert(M.count(U.dragSelected)==4,'marquee must exclude released dice')
fling(3)
assert(#ends==6 and U.manualRoll==nil and starts==1,
 'a second selected group completes the same logical roll')
assert(U.game.phase=='rolling' and U.game.pot==0)
fresh()
-- A normal click should still be routed to the original Farkle toggle,
-- not silently become a physical group selection.
local clicked=false
local originalToggle=U.toggle
U.toggle=function(_,i) clicked=(i==2) end
U:mousepressed(centers[2].x,140,1)
U:mousereleased(centers[2].x,140,1)
assert(clicked and not U.dragSelected,'plain left-click remains a scoring click')
U.toggle=originalToggle

fresh()
marquee(110,210)
now=now+.1;U:mousepressed(centers[1].x,140,2)
assert(U.mouseThrow.group)
local saved=dice[1].body.position[1]
U:keypressed('escape')
assert(U.mouseThrow==nil and dice[1].body._manual_pending and
 dice[1].body.position[1]==saved,'Esc must cancel all held dice without releasing them')
assert(U.manualRoll and U.manualRoll.count==6)
assert(M.count(U.dragSelected)==2,'cancel must preserve group selection for retry')
print('PASS marquee/group physics: 6-die selection, simultaneous real launch, partial groups, Esc and original left-click')
