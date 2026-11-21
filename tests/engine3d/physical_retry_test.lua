local U=require('src.farkle.controller')
-- Headless unit test: the runner has no LÖVE filesystem or CSV output.
U.log=function() end
dice={};for i=1,6 do dice[i]={kept=true} end
local captured
U.onManualRollBegin=function(indices) captured=indices end
U.onManualRollRelease=function() return true end
U.onRollRequest=function() error('human recovery may not trigger automatic dice launch') end
U.game={active={1,2,3,4,5,6}}
U.pending={[2]=5,[3]=3}
U.state='physics_error';U.activePhysical={[1]=true}
U:retry_physical()
assert(#captured==1 and captured[1]==1 and U.manualRoll.count==1,
 'manual recovery must preserve the failed physical subset for direct pickup')
assert(dice[2].kept and U.pending[2]==5 and U.pending[3]==3)
U.state='physics_error';U.activePhysical={[3]=true,[5]=true}
U:retry_physical()
assert(#captured==2 and captured[1]==3 and captured[2]==5 and U.manualRoll.count==2)
assert(dice[1].kept and not dice[3].kept and not dice[5].kept)
print('physical retry subset: PASS')
