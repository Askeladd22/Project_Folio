local U=require('src.features.farkle.controller')
local R=require('src.gameplay.farkle.rules')
local M=require('src.gameplay.farkle.medals')
assert(type(U.activate_reference)=='function','medal physical adapter missing')
dice={};for i=1,6 do dice[i]={kept=false} end
U.log=function() end
local calls={};U.onRollRequest=function(_,ids) calls[#calls+1]=ids end
U.game=R.new();assert(R.equip_reference(U.game,'reroll_gold'))
assert(R.start(U.game));assert(R.settle(U.game,{1,5,2,3,4,6}));U:sync()
R.toggle(U.game,1);R.take(U.game);U:sync()
assert(U:activate_reference({3,4}));assert(#calls==1 and #calls[1]==2)
assert(dice[1].kept and dice[2].kept and not dice[3].kept and dice[6].kept)
assert(not U:activate_reference({2}));assert(#calls==1)
U.state='physics_error';U:retry_physical();assert(#calls==2 and M.remaining(U.game)==0)
U:onDiceSettled({{index=3,value=2},{index=4,value=3}})
assert(U.game.hand[2]==5 and U.game.used[1] and U.game.phase=='ready' and U.game.pot==10)
assert(U.state=='placing' and dice[2].kept and dice[1].kept,'retained dice must stay excluded after settlement')
U:sync();assert(dice[2].kept,'later sync must not release retained bodies')
assert(R.toggle(U.game,2),'physically held result remains selectable');assert(R.take(U.game));U:sync()
assert(U:request());assert(not dice[3].kept and not dice[4].kept and dice[1].kept and dice[2].kept)
-- Controlled adapter inputs (not a physical run): rejection filter must retain
-- the other accepted medal die and spend no second charge.
love={math={random=function() return .99 end}}
U.game=R.new();U.game.build='weighted';assert(R.equip_reference(U.game,'reroll_gold'))
assert(R.start(U.game));assert(R.settle(U.game,{1,5,2,3,4,6}));U.state='placing';U.medalHeld=nil;U:sync()
assert(U:activate_reference({1,3}))
U:onDiceSettled({{index=1,value=2},{index=3,value=5}})
assert(U.retry and U.pending[1]==nil and U.pending[3]==5 and M.remaining(U.game)==0)
U:update(1);assert(#calls[#calls]==1 and calls[#calls][1]==1)
U:onDiceSettled({{index=1,value=1}})
assert(U.game.phase=='ready' and U.game.hand[1]==1 and U.game.hand[3]==5 and U.game.hand[2]==5)
assert(M.remaining(U.game)==0 and dice[2].kept and not U.game.used[2])
print('PASS physical medal adapter, no double charges, technical retry, preserved unrerolled dice')
