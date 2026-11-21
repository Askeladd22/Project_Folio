-- Decision-preview contract: copy follows the authoritative Farkle rules.
-- No graphics runtime is required; the UI must not alter game state.
local R=require('src.farkle.rules')
local Actions=require('src.farkle.ui').hud.actions

local function action(game,id)
 local u={game=game}
 for _,a in ipairs(Actions.build(u)) do
  if a.id==id then return a end
 end
 return nil
end

local low=R.new()
low.stage=2 -- The Book of Hours has a 40-point entry threshold.
assert(R.start(low))
assert(R.settle(low,{1,5,2,3,4,6}))
assert(R.toggle(low,1))
local take=assert(action(low,'take'))
local bank=assert(action(low,'bank'))
assert(take.enabled and take.label=='Set Aside · 10 pt')
assert(take.detail:find('10 at risk',1,true)
 and take.detail:find('5 dice left',1,true))
assert(not bank.enabled and bank.label=='Bank 10 pt')
assert(bank.detail:find('Minimum 40 pt',1,true)
 and bank.detail:find('short by 30',1,true))
assert(low.pot==0 and next(low.used)==nil,
 'preview must not commit a selected die or points')

local valid=R.new()
assert(R.start(valid))
assert(R.settle(valid,{1,5,2,3,4,6}))
assert(R.toggle(valid,1))
local direct=assert(action(valid,'bank'))
assert(direct.enabled and direct.label=='Bank 10 pt')
assert(direct.detail:find('Secures points',1,true)
 and direct.detail:find('ends turn',1,true))
assert(valid.pot==0 and valid.bank==0,
 'banking preview must not perform a banking action')
direct.fn=function()end -- no input invocation; the preview is read-only

local hot=R.new()
assert(R.start(hot))
assert(R.settle(hot,{1,1,1,1,1,1}))
for i=1,6 do assert(R.toggle(hot,i)) end
local hot_take=assert(action(hot,'take'))
assert(hot_take.enabled and hot_take.detail:find('6 hot dice',1,true))
assert(hot.pot==0 and not hot.hot,
 'hot-dice preview must not activate the actual hot-dice state')

print('PASS decision preview: low threshold, direct banking, hot dice and unchanged Farkle state')
