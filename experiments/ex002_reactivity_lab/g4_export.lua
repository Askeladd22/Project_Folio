-- Generate facilitator and participant handouts from the same human-test manifest.
-- Usage: lua5.4 experiments/ex002_reactivity_lab/g4_export.lua /tmp/g4
-- Keep g4_answer_key.csv PRIVATE; give participants ONLY g4_cards.md.
local G=require('experiments.ex002_reactivity_lab.g4_stimuli')
local dir=assert(arg[1],'output folder required (must already exist)')
local stimuli=G.manifest()
assert(G.assert_manifest(stimuli))
local function csv(...)
 local f={...}
 for i,v in ipairs(f) do
  local s=tostring(v)
  if s:find('[,"\r\n]') then s='"'..s:gsub('"','""')..'"' end
  f[i]=s
 end
 return table.concat(f,',')..'\n'
end
local cards=assert(io.open(dir..'/g4_cards.md','w'))
local key=assert(io.open(dir..'/g4_answer_key.csv','w'))
cards:write('# Project Folio — G4 schede per studio umano\n\n')
cards:write('**Versione sperimentale.** Non è il gameplay canonico. ')
cards:write('Partecipante anonimo: ______  Data: ______\n\n')
cards:write('Per ogni caso, leggi la regola, la situazione pubblica e scegli: ')
cards:write('(1) dove risponderà il Mercante se collochi i sigilli nella ')
cards:write('categoria indicata; (2) dove collocare i sigilli per farlo ')
cards:write('rispondere alla categoria obiettivo, oppure **0 = impossibile**.\n\n')
cards:write('La tua mossa avviene prima della risposta del Mercante. ')
cards:write('Ogni categoria è aperta; nessuna tua mossa la sigilla immediatamente. ')
cards:write('Con punteggi pari vince la priorità 3, poi 2, poi 1. ')
cards:write('Due casi di pratica con feedback a cura del facilitatore ')
cards:write('e dodici valutazioni senza feedback.\n\n')
key:write(csv('order','stage','mode','seed','round','marks','board',
 'proposed','prediction_target','request_target','valid_claims'))
for i,t in ipairs(stimuli) do
 cards:write(('### Caso %02d — %s\n\n'):format(i,
   t.stage=='practice' and 'Pratica' or 'Valutazione'))
 cards:write(G.rule(t.mode)..'\n\n')
 cards:write('Tempo: una sola assegnazione, poi il Mercante risponde.\n\n')
 cards:write('| Categoria | Tu | Mercante | Priorita |\n')
 cards:write('|---|---:|---:|---:|\n')
 for lane,l in ipairs(t.lanes) do
  cards:write(('| %d — %s | %d | %d | %d |\n'):format(
    lane,l.name,l.player,l.rival,4-lane))
 end
 cards:write(('\n**Prova %d/6.** Sigilli tuoi da assegnare: **%d**.\n\n'):
    format(t.round,t.marks))
 cards:write(('1. Se li assegni a **%d**, il Mercante risponde su: '..
  '_____ (1/2/3).\n\n'):format(t.proposed))
 cards:write(('2. Vuoi far rispondere il Mercante su **%d**. '..
  'Dove collochi i sigilli? _____ (0/1/2/3).\n\n'):format(
  t.request_target))
 if i==6 or i==13 then
  cards:write('3. Spiega brevemente la tua scelta: ___________________\n\n')
 end
 cards:write('---\n\n')
 key:write(csv(i,t.stage,t.mode,t.seed,t.round,t.marks,
  G.signature(t),t.proposed,t.prediction_target,t.request_target,
  #t.control_choices>0 and table.concat(t.control_choices,'|') or '0'))
end
assert(cards:close())
assert(key:close())
print('PASS G4 manifest: '..#stimuli..' unique cards (2 practice, 12 tests)')
print('Participant cards: '..dir..'/g4_cards.md')
print('Facilitator answer key: '..dir..'/g4_answer_key.csv')
