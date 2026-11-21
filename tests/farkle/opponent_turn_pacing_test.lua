local R=require('src.farkle.rules')
local U=require('src.farkle.controller')
local game=R.new('duel')
assert(R.start(game))
local values={1,2,3,4,5,6}
assert(R.settle(game,values) and game.phase=='ready')
local duel={actor='opponent',scores={player=0,opponent=0},target=500,wait=0}
local u=setmetatable({game=game,duel=duel,
 act=function(_,name,fn) assert(name=='take' and fn());return true end}, {__index=U})
u:update_duel(0)
assert(duel.pending_take and duel.selected_points and next(game.selected),
 'AI must highlight a scoring combination before committing it')
assert(not game.scored and duel.wait>=1.5)
u:update_duel(0.75)
assert(not game.scored and duel.pending_take,'selection must stay visible')
u:update_duel(1.2)
assert(game.scored and game.pot>0 and duel.last_take>0 and not duel.pending_take,
 'AI must visibly set aside a scoring combination')
assert(duel.wait>=1.5 and duel.last_count>0)
u:update_duel(2.1)
assert(duel.pending_action and duel.move:find('DECISION',1,true) and duel.wait>=1.5,
 'AI must announce a bank/reroll decision before carrying it out')
print('PASS AI selection, set-aside gain, readable pauses and decision preview')
