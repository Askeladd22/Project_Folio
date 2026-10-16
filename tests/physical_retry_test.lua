local U=require('src.features.farkle.controller')
dice={};for i=1,6 do dice[i]={kept=true} end
local captured
U.onRollRequest=function(_,indices) captured=indices end
U.game={active={1,2,3,4,5,6}}
U.pending={[2]=5,[3]=3}
U.state='physics_error';U.activePhysical={[1]=true}
U:retry_physical()
assert(#captured==1 and captured[1]==1,'manual recovery must preserve the failed physical subset')
assert(dice[2].kept and U.pending[2]==5 and U.pending[3]==3)
U.state='physics_error';U.activePhysical={[3]=true,[5]=true}
U:retry_physical()
assert(#captured==2 and captured[1]==3 and captured[2]==5)
assert(dice[1].kept and not dice[3].kept and not dice[5].kept)
print('physical retry subset: PASS')
