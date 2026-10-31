-- Official duel results -> presentation only: no fake dice or scoring side effects.
local P=require('src.features.farkle.bot_duel_presentation')
local R=require('src.gameplay.farkle.rules')
local state=P.new()
assert(state.target==R.contracts[1].target)
assert(state.limit==R.contracts[1].limit)
assert(state.round==0 and not state.finished and not state.return_to_page)

local first={
 report={turn=1,rolls=2,banked=35,loss=false,
  faces={{1,2,3,4,5,6},{[2]=5,[4]=1}}},
 player=25,bot=35,finished=false,
}
assert(P.observe(state,first))
assert(state.round==1 and state.player==25 and state.bot==35)
assert(state.rolls==2 and state.last_roll=='- 5 - 1 - -')
assert(state.status=='Il monaco incassa +35 punti.')
assert(not state.return_to_page)
assert(not P.observe(state,first),'repeated event must not double-render turn')
assert(state.round==1 and state.bot==35,'duplicates changed displayed scores')

local farkle={
 report={turn=2,rolls=1,loss=true,banked=0,faces={{2,3,4,6,2,3}}},
 player=65,bot=35,finished=false,
}
assert(P.observe(state,farkle))
assert(state.last_roll=='2 3 4 6 2 3')
assert(state.status:find('FARKLE',1,true))
assert(not state.return_to_page)

-- The animation is driven by the already verified win condition,
-- not by scores guessed in the presentation layer.
local win={
 report={turn=3,rolls=1,banked=0,loss=true,faces={{2,3,4,6,2,3}}},
 player=110,bot=35,finished=true,winner='player',
}
local snapshot=win.report.faces[1][1]
assert(P.observe(state,win))
assert(state.finished and state.return_to_page and state.winner=='player')
assert(state.status:find('torna nel folio',1,true))
assert(win.report.faces[1][1]==snapshot,'presentation mutated bot dice')
assert(win.player==110 and win.bot==35)

local replay=P.new()
assert(replay.round==0 and replay.player==0 and replay.bot==0
 and not replay.return_to_page and replay.winner==nil,
 'retry must remove all old duel presentation data')
local defeated={
 report={turn=1,rolls=1,banked=625,loss=false,faces={{1,1,1,1,1,1}}},
 player=10,bot=625,finished=true,winner='bot',
}
assert(P.observe(replay,defeated))
assert(replay.finished and not replay.return_to_page)
assert(replay.status:find('conserva',1,true))
local tie=P.new()
assert(P.observe(tie,{
 report={turn=1,rolls=1,banked=0,loss=true,faces={{2,3,4,6,2,3}}},
 player=0,bot=0,finished=true,winner='tie',
}))
assert(tie.finished and not tie.return_to_page)
assert(not P.observe(tie,nil))

-- Wiring guards: no stage win can be fabricated by drawing a sprite,
-- and every new battle starts with a reset figure.
local function src(path)
 local f=assert(io.open(path,'rb'));local v=f:read('*a');f:close();return v
end
local view=src('src/features/farkle/bot_duel_view.lua')
assert(view:find('status.return_to_page',1,true))
assert(view:find('monk:return_to_page',1,true))
assert(view:find('function M.reset()',1,true))
assert(view:find('Res.begin_ui()',1,true))
assert(not view:find('src.engine3d.render',1,true))
local ctl=src('src/features/farkle/controller.lua')
assert(ctl:find("bot_duel_view').reset()",1,true))
assert(ctl:find("bot_duel_view').on_turn(event)",1,true))
print('PASS Monk 2D folio return: accepted turn ledger, sparse physical-free dice, win-only return, replay and accessibility wiring')
