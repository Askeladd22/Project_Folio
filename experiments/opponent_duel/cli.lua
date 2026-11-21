-- Terminal-playable experiment. Run from repository root:
--   lua5.4 experiments/opponent_duel/cli.lua [seed] [target]
-- Not connected to 3D dice: use this to playtest decisions before integration.
local Duel=require('experiments.opponent_duel.duel')
local AI=require('experiments.opponent_duel.ai')
local seed=tonumber(arg and arg[1]) or os.time()
local target=tonumber(arg and arg[2]) or 500
local state=Duel.new(target)
local x=math.floor(seed)%2147483647
if x<=0 then x=1 end
local function next_die()
 x=(x*48271)%2147483647
 return (x%6)+1
end
print(('Folio: sfida al Opponent | seed %d | obiettivo %d'):format(seed,target))
print('Punti FOLIO: 1=10, 5=5. Non si applica il punteggio di KCD2.')
while not state.winner do
 local actor=state.actor
 if state.phase=='roll' then
  if actor=='player' then
   print(('\nTU %d | OPPONENT %d | a rischio %d'):format(
    state.score.player,state.score.opponent,state.pot))
   io.write('Premi Invio per lanciare (q per uscire): ')
   local answer=io.read()
   if answer==nil or answer=='q' then break end
  else
   print(('\nIl Opponent lancia (%d pt a rischio).'):format(state.pot))
  end
  local ids={}
  for id=1,6 do if not state.used[id] then ids[#ids+1]=id end end
  local faces={}
  for i=1,#ids do faces[i]=next_die() end
  local summary={}
  for i,id in ipairs(ids) do summary[#summary+1]='#'..id..'='..faces[i] end
  print(table.concat(summary,'  '))
  assert(Duel.roll(state,faces))
  if state.phase=='roll' then print(actor=='player' and 'FARKLE! Passi il turno.' or 'Il Opponent fa FARKLE.') end
 elseif state.phase=='select' then
  if actor=='opponent' then
   local option=assert(AI.best_option(state.options))
   assert(Duel.select(state,option.mask))
   print(('Il Opponent accantona %d pt (%d dadi).'):format(option.points,#option.ids))
  else
   local best=assert(AI.best_option(state.options))
   io.write(('Scelta suggerita: %s (%d pt). Inserisci ID dadi separati da virgola, o Invio per suggerimento: '):format(
    table.concat(best.ids,','),best.points))
   local answer=io.read()
   if answer==nil or answer=='q' then break end
   local mask
   if answer=='' then mask=best.mask
   else
    local ids={}
    for text in answer:gmatch('%d+') do ids[#ids+1]=tonumber(text) end
    mask=Duel.mask_from_ids(ids)
   end
   if not Duel.select(state,mask) then print('Selezione non valida: usa soltanto una combinazione Farkle.') end
  end
 elseif state.phase=='decision' then
  if actor=='opponent' then
   local action,reason=AI.decide(state)
   print(('Opponent: %s | %s'):format(action=='bank' and 'INCASSA' or 'RILANCIA',reason))
   assert(action=='bank' and Duel.bank(state) or Duel.continue(state))
  else
   io.write(('Hai %d pt a rischio. [i]ncassa o [r]ilancia? '):format(state.pot))
   local answer=io.read()
   if answer==nil or answer=='q' then break end
   if answer=='i' then assert(Duel.bank(state))
   elseif answer=='r' then assert(Duel.continue(state))
   else print('Comando non riconosciuto.') end
  end
 end
end
if state.winner then
 print(('\n%s VINCE! Tu: %d | Opponent: %d'):format(
  state.winner=='player' and 'GIOCATORE' or 'OPPONENT',
  state.score.player,state.score.opponent))
end
