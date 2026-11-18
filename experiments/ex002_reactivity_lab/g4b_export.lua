-- G4b: offline participant cards and facilitator answer key, separate files.
-- Invoke from repo root: lua5.4 experiments/ex002_reactivity_lab/g4b_export.lua /tmp/g4b
local B=require('experiments.ex002_reactivity_lab.g4b_stimuli')
local G=B.G
local out=assert(arg[1],'pass an existing output directory')
local trials=B.manifest()
assert(B.assert_manifest(trials))
local function csv(...)
 local t={...}
 for i,v in ipairs(t) do
  local s=tostring(v)
  if s:find('[,"\r\n]') then s='"'..s:gsub('"','""')..'"' end
  t[i]=s
 end
 return table.concat(t,',')..'\n'
end
local cards=assert(io.open(out..'/g4b_cards.md','w'))
local key=assert(io.open(out..'/g4b_answer_key.csv','w'))
cards:write('# Project Folio — G4b: comprendere il Rivale\n\n')
cards:write('Questa e una prova di comprensione, non una partita e non un test di talento.\n')
cards:write('2 esercitazioni con feedback seguite da 12 prove senza feedback.\n\n')
cards:write('Leggi per ogni prova la regola R oppure F. Scegli soltanto categorie APERTE.\n')
cards:write('Rispondi: (1) dove il Rivale rispondera dopo la mossa proposta; ')
cards:write('(2) in quale categoria collocheresti i sigilli per OTTENERE la ')
cards:write('risposta richiesta, oppure 0 se impossibile. La possibilita cambia ')
cards:write('da una prova all\'altra, anche dentro la stessa regola R o F.\n\n')
cards:write('La tua collocazione avviene PRIMA della sua risposta. ')
cards:write('Pareggio nei punteggi: precede la categoria con priorita maggiore.\n\n')
key:write(csv('order','stage','condition','mode','seed','round','marks',
 'board','proposed','prediction_target','request_target',
 'valid_claims','reactive_sensitive'))
for i,t in ipairs(trials) do
 cards:write(('## Caso %02d — %s\n\n'):format(i,
  t.stage=='practice' and 'Pratica' or 'Valutazione'))
 cards:write(G.rule(t.mode)..'\n\n')
 cards:write('**'..('Prova %d/6, sigilli tuoi da collocare: %d'):format(t.round,t.marks)..'**\n\n')
 cards:write('| Categoria | Tu | Rivale | Priorita | Stato |\n')
 cards:write('|---|---:|---:|---:|---|\n')
 for lane,l in ipairs(t.lanes) do
  cards:write(('| %d — %s | %d | %d | %d | %s |\n'):format(
   lane,l.name,l.player,l.rival,4-lane,
   l.owner and ('CHIUSA ('..l.owner..')') or 'aperta'))
 end
 cards:write(('\n1. Se collochi i sigilli nella categoria **%d**, '..
   'il Rivale risponde sulla categoria _____ (1/2/3).\n\n'):format(t.proposed))
 cards:write(('2. Vuoi OTTENERE che il Rivale risponda alla categoria **%d**. '..
   'Dove metti i sigilli? _____ (0=impossibile, oppure 1/2/3).\n\n'):
   format(t.request_target))
 if i==5 or i==12 then
  cards:write('3. In una frase, spiega la tua scelta: ____________________\n\n')
 end
 cards:write('---\n\n')
 key:write(csv(t.order,t.stage,t.condition,t.mode,t.seed,t.round,
  t.marks,G.signature(t),t.proposed,t.prediction_target,
  t.request_target,#t.control_choices>0 and
  table.concat(t.control_choices,'|') or '0',
  t.reactive_sensitive and 1 or 0))
end
assert(cards:close());assert(key:close())
print('PASS G4b balanced manifest: '..#trials..' cards, 2 practice + 12 tests')
print('Participant-only cards: '..out..'/g4b_cards.md')
print('Facilitator-private key: '..out..'/g4b_answer_key.csv')
