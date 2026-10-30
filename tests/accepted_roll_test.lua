package.path="./?.lua;./?/init.lua;"..package.path
local U=require('src.features.farkle.controller')
local R=require('src.gameplay.farkle.rules')
local D=require('src.features.farkle.dice')
local emitted={}
love={math={random=function() return .9 end},filesystem={getInfo=function()return true end,
 append=function()return true end,write=function()return true end}}
dice={};for i=1,6 do dice[i]={kept=false} end
U.log=function(self,name,detail) emitted[#emitted+1]={name,detail} end
U.game=R.new()
U.state='waiting'
U.onRollRequest=function(_,indices,technical)
 emitted[#emitted+1]={'physical',technical==true}
end
assert(U:request(false));assert(U.game.phase=='rolling')
U.game.build='weighted'
local ok=U:onDiceSettled({{index=1,value=2},{index=2,value=5},
 {index=3,value=3},{index=4,value=3},{index=5,value=3},{index=6,value=6}})
assert(ok==false and U.game.phase=='rolling' and U.retry and U.pending[1]==nil)
U:update(.7)
assert(emitted[#emitted][1]=='physical' and emitted[#emitted][2]==true)
love.math.random=function()return .1 end
ok=U:onDiceSettled({{index=1,value=2}})
assert(ok==true and U.game.phase=='ready' and U.game.hand[1]==2 and U.game.hand[2]==5)
assert(U:onDiceSettled({{index=1,value=1}})==false)
-- A selective medal physical throw is accepted without discarding retained dice.
U.game=R.new();U.game.medal='none';U.pending={};U.observed={}
assert(R.start(U.game))
assert(U:onDiceSettled({{index=1,value=1},{index=2,value=2},{index=3,value=3},
{index=4,value=4},{index=5,value=5},{index=6,value=6}}))
assert(U.game.hand[5]==5)
-- A physical failure is recoverable without changing a Farkle state.
U.state='rolling';U:onPhysicalFailure({reason='timeout'})
assert(U.state=='physics_error' and U.game.phase=='ready')
print('PASS accepted and rejected physical throws, weighted retry, duplicate callback guard')
