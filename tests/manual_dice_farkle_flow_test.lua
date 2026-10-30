-- Headless Farkle controller integration: six separate mouse releases,
-- only one official logical roll, no early scoring/acceptance.
require('core')
local U=require('src.features.farkle.controller')
local R=require('src.gameplay.farkle.rules')
local Bridge=require('src.core.engine_bridge')
local clock=0
love={timer={getTime=function() return clock end}}
local pick=1
Bridge.configure({pick_scriptorium_tray_die=function() return pick end})
local function body()
 local b={position=vector{0,0,1},velocity=vector{0,0,0},
  angular=vector{0,0,0},asleep=true,
  {1,1,1},{-1,-1,-1}}
 function b:update(dt) for _,v in ipairs(self) do v[1]=v[1]+dt*self.angular[2] end end
 return b
end
dice={}
for i=1,6 do dice[i]={body=body(),kept=false} end
U.game=R.new('build')
U.state='waiting';U.buttons={roll={enabled=true}}
U.mouseThrow=nil;U.manualRoll=nil;U.presentation=nil
U.logicalRollId=0;U.physicalAttemptId=0
U.sync_presentation=function()end
U.log=function()end
local starts,ends=0,0
U.onRollRequest=function() error('mouse must not trigger automatic six-die throw') end
U.onManualRollBegin=function(indices)
 starts=starts+1
 assert(#indices==6)
 for _,i in ipairs(indices) do
  dice[i].body._manual_pending=true
  dice[i].body.asleep=true
 end
end
U.onManualRollRelease=function(index)
 ends=ends+1
 assert(not dice[index].body._manual_pending)
 return true
end
for i=1,6 do
 pick=i
 clock=clock+.3
 U:mousepressed(100+i*4,100,2)
 assert(U.mouseThrow and U.mouseThrow.index==i,'single die was not grabbed')
 clock=clock+.04
 U:mousemoved(130+i*4,120)
 U:update(.02)
 clock=clock+.04
 U:mousereleased(150+i*4,130,2)
 assert(ends==i,'each die should be released exactly once')
 assert(starts==1,'only one Farkle logical roll should start')
 assert(U.game.phase=='rolling' and U.game.pot==0,
  'no Farkle points are assigned until entire group settles')
 if i<6 then assert(U.manualRoll and U.manualRoll.count==6-i)
 else assert(U.manualRoll==nil)end
end
assert(U.logicalRollId==1 and U.physicalAttemptId==1)
assert(not U.mouseThrow)
assert(U.game.phase=='rolling','physics settlement must remain authoritative')
print('PASS tabletop Farkle controller: six separate held dice, one official roll, zero early scoring')
