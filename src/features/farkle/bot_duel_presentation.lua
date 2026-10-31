-- 2D-only presentation model for the optional same-rules Farkle duel.
-- Reads the bot's already resolved public turn report; never generates rolls,
-- decides scores, moves a die, or mutates the authoritative Rules state.
local Rules=require('src.gameplay.farkle.rules')
local M={}

local function dice_line(values)
 if type(values)~='table' then return 'nessun tiro' end
 local out={}
 for i=1,6 do
  local v=values[i]
  out[i]=(type(v)=='number' and v>=1 and v<=6) and tostring(v) or '-'
 end
 return table.concat(out,' ')
end

function M.new()
 local contract=assert(Rules.contracts[1])
 return {
  round=0,player=0,bot=0,limit=contract.limit,target=contract.target,
  status='Il monaco attende il tuo lancio.',
  last_roll='- - - - - -',rolls=0,finished=false,
  winner=nil,return_to_page=false,
 }
end

function M.observe(state,event)
 assert(type(state)=='table','duel presentation state required')
 if not event or type(event.report)~='table' then return false end
 local turn=assert(event.report.turn,'bot turn number required')
 if turn<=state.round then return false end
 state.round=turn
 state.player=assert(event.player,'player bank missing')
 state.bot=assert(event.bot,'bot bank missing')
 state.rolls=event.report.rolls or 0
 local faces=event.report.faces or {}
 state.last_roll=dice_line(faces[#faces])
 local amount=event.report.banked or 0
 if event.report.loss then
  state.status='FARKLE: il monaco perde la mano.'
 else
  state.status='Il monaco incassa +'..amount..' punti.'
 end
 state.finished=event.finished==true
 state.winner=event.winner
 state.return_to_page=state.finished and state.winner=='player'
 if state.finished then
  if state.winner=='player' then
   state.status='Sconfitto: il monaco torna nel folio.'
  elseif state.winner=='bot' then
   state.status='Il monaco conserva la sua posizione.'
  else
   state.status='Parita: la miniatura resta sul folio.'
  end
 end
 return true
end

return M
