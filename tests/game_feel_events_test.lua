local U=require('src.features.farkle.controller')
local R=require('src.gameplay.farkle.rules')
local Audio=require('src.core.audio_manager')
local events={}
Audio.play_farkle=function(e) events[#events+1]=e end
U.log=function() end
dice={};for i=1,6 do dice[i]={kept=false} end
U.game=R.new();U.presentation=nil;U:sync()
assert(R.start(U.game));U:sync();assert(R.settle(U.game,{1,5,3,3,3,6}));U:sync()
R.toggle(U.game,1);U:act('take',function() return R.take(U.game) end)
assert(#events==1 and events[1]=='take')
for i=1,10 do U:update(.01);U:sync() end
assert(#events==1)
U:act('take',function() return R.take(U.game) end);assert(#events==1)
U:act('bank',function() return R.bank_turn(U.game) end)
assert(#events==2 and events[2]=='bank')
U:sync();U:update(1);assert(#events==2)
U:act('next',function() return R.next_turn(U.game) end)
assert(R.start(U.game));U:sync();assert(R.settle(U.game,{2,2,3,3,4,6}));U:sync()
assert(events[3]=='loss');U:sync();assert(#events==3 and not U.presentation.score)
U.game=R.new();U.presentation=nil;U:sync();assert(R.equip_reference(U.game,'bank_multiplier_gold'))
assert(R.start(U.game));U:sync();assert(R.settle(U.game,{1,5,2,3,4,6}));U:sync();R.toggle(U.game,1)
assert(U:activate_reference());assert(events[4]=='medal' and events[5]=='bank')
assert(U.presentation.bonus==10 and U.presentation.score.to==20)
assert(U.presentation.bonusLabel==require('src.gameplay.farkle.medals').get(U.game.medal).label)
U:keypressed('tab');assert(U.game.bank==20 and #events==5 and U.game.medalCharges==0)
assert(not U:activate_reference());U:sync();assert(#events==5 and U.game.medalCharges==0)
print('PASS controller emits each semantic sound once; illegal/repeated callbacks silent, medal and bank distinct')
