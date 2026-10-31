-- Project Folio duel: official Farkle scoring and turn progression, 2D-only UI.
-- Run in both Lua 5.4 and LuaJIT; no physics or LÖVE graphical runtime needed.
local R=require('src.gameplay.farkle.rules')
local Bot=require('src.gameplay.farkle.opponent_bot')
local Duel=require('src.gameplay.farkle.bot_duel')

local no_scoring={2,3,4,6,2,3}
local i=0
local function farkle_rng()
 i=i+1
 return no_scoring[(i-1)%#no_scoring+1]
end

local loser=Bot.new(farkle_rng)
local t=assert(loser:turn())
assert(t.turn==1 and t.rolls==1 and t.banked==0 and t.loss)
assert(loser.game.phase=='ended' and loser.game.bank==0)
local second=assert(loser:turn())
assert(second.turn==2 and loser.game.turn==2 and loser.game.bank==0)
assert(loser.game.stage==1 and #loser.history==2)

local winner=Bot.new(function(lo,hi)
 assert(lo==1 and hi==6)
 return 1
end)
local winTurn=assert(winner:turn())
assert(winTurn.rolls==1 and winTurn.banked==R.score({1,1,1,1,1,1}),
 'bot must use same scoring table as player')
assert(winTurn.phase=='advance', 'bot should complete only commission 1')
assert(winner:turn()==nil,'bot cannot take a second turn after finishing')

local function player_bank(values,selected)
 local p=R.new('control')
 assert(R.start(p))
 assert(R.settle(p,values))
 for _,index in ipairs(selected) do assert(R.toggle(p,index)) end
 assert(R.bank_turn(p))
 return p
end

-- A player with a real 3D roll result beats a no-scoring bot. Bot must not
-- overwrite a single field of the human's authoritative Farkle game.
local human=player_bank({1,1,1,1,1,1},{1,2,3,4,5,6})
assert(human.bank==625 and human.phase=='advance')
local duel=Duel.new(farkle_rng)
local snapshot={bank=human.bank,stage=human.stage,turn=human.turn,phase=human.phase}
local result=assert(duel:after_player_turn(human))
assert(result.finished and result.winner=='player')
assert(duel.finished and duel.bot.game.bank==0)
assert(duel:after_player_turn(human)==nil,'never repeat a bot turn after completion')
for k,v in pairs(snapshot) do assert(human[k]==v,'bot changed player state '..k) end

-- A low-risk human bank does not win instantly; a higher official bot total
-- reaches the same first-commission target and ends the optional duel.
local starter=player_bank({1,2,3,4,6,2},{1})
assert(starter.bank==10 and starter.phase=='ended')
local strong=Duel.new(function() return 1 end)
local r=assert(strong:after_player_turn(starter))
assert(r.finished and r.winner=='bot' and r.bot==625 and r.player==10)
assert(starter.bank==10 and starter.phase=='ended',
 'bot's virtual dice must not update physical human state')
assert(strong:after_player_turn(starter)==nil)

local source=assert(io.open('src/features/farkle/controller.lua')):read('*a')
assert(source:find('bot_duel',1,true))
assert(source:find('after_duel_turn',1,true))
assert(source:find('Toasts.draw',1,true))
assert(not source:find('require(\'src.engine3d.bot',1,true),
 'new opponent must not instantiate 3D mesh/physics')
local schema=require('src.data.main_menu_schema')
local found=0
for _,m in ipairs(schema.menu_items) do if m.id=='bot-duel' then
  found=found+1;assert(m.enabled and not m.primary) end end
assert(found==1,'duel must be a separate opt-in menu action')
print('PASS official-rule bot: real scoring/turn state, isolated D6, fair phase/race, no duplicate rounds or player mutations, reachable menu')
