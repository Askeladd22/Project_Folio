-- Local, anonymous human test. No network, no production gameplay edits.
-- From repository root: lua5.4 experiments/ex002_reactivity_lab/g4_run.lua P01 .
local G=require('experiments.ex002_reactivity_lab.g4_stimuli')
local id=arg[1]
local dir=arg[2] or '.'
assert(id and id:match('^[A-Za-z0-9_-]+$') and #id<=24,
 'pass anonymous ID: P01 (letters/digits/-/_ only; no personal details)')
local path=dir..'/g4_'..id..'.csv'
local existing=io.open(path,'r')
if existing then existing:close();error('file already exists: '..path) end

local function prompt(msg,choices)
 while true do
  io.write(msg);io.flush()
  local answer=io.read('*l')
  if answer==nil then error('session ended; no result file written') end
  local n=tonumber(answer)
  if n and n%1==0 and choices[n] then return n end
  print('Opzione non valida. Riprova.')
 end
end
local function text_prompt(msg)
 io.write(msg);io.flush()
 local a=io.read('*l')
 if a==nil then error('session ended; no result file written') end
 return a
end
local function csv(...)
 local fields={...}
 for i,v in ipairs(fields) do
  local s=tostring(v)
  if s:find('[,"\r\n]') then s='"'..s:gsub('"','""')..'"' end
  fields[i]=s
 end
 return table.concat(fields,',')..'\n'
end
local trials=G.manifest()
assert(G.assert_manifest(trials))
local headers=csv('participant','order','stage','mode','seed','round','marks',
 'board','proposed','prediction','prediction_true','prediction_ok',
 'requested_target','chosen_lane','correct_lanes','control_ok','explanation')
local lines={headers}
local scored={total=0,r_predict=0,r_steer=0,r_n=0,f_predict=0,f_steer=0,f_n=0}
print('Project Folio — G4: lettura del Rivale (studio anonimo e offline).')
print('Non inserire nomi o dati personali. Puoi interrompere con EOF senza salvare.')
print('Ogni prova parte da uno stato reale del prototipo C, NON dal gioco finale.')
print('Alcune prove possono essere CHIUSE: non sono opzioni legali.')
print('Aggiungi i tuoi sigilli a una prova APERTA PRIMA della risposta.')
print('Il Rivale colloca i suoi sigilli sulla prova con il punteggio maggiore.')
print('In caso di pareggio la priorita e 3 > 2 > 1 (Capilettera prima).')
print('Sono previste 2 esercitazioni con feedback + 12 valutazioni senza feedback.')
io.write('Confermi di partecipare volontariamente, senza inserire dati personali? (s/n): ')
io.flush()
local consent=io.read('*l')
if consent~='s' and consent~='S' then print('Sessione annullata, nessun dato salvato.');return end
print('Lo studio verifica comprensione, non la bravura reale nelle partite.')
local lane_names={'Capilettera','Miniatura','Marca tipografica'}
local predict_choices={[1]=true,[2]=true,[3]=true}
local steer_choices={[0]=true,[1]=true,[2]=true,[3]=true}
for i,t in ipairs(trials) do
 print(('\n=== Caso %d/%d (%s) ==='):format(i,#trials,
    t.stage=='practice' and 'esercitazione' or 'valutazione'))
 print(G.rule(t.mode))
 print(G.display_board(t))
 local prediction=prompt(('Se assegni %d sigilli a %d (%s), il Rivale scegliera 1, 2 o 3? '):
   format(t.marks,t.proposed,lane_names[t.proposed]),predict_choices)
 local choice=prompt(('Scegli dove collocare i sigilli per far puntare il Rivale a %d (%s). '..
   'Digita 0 se impossibile, altrimenti 1, 2 o 3: '):
   format(t.request_target,lane_names[t.request_target]),steer_choices)
 local rationale=''
 if t.stage=='test' and (i==6 or i==13) then
  rationale=text_prompt('In una frase, perche il Rivale dovrebbe fare quella scelta? ')
 end
 local predict_ok=prediction==t.prediction_target
 local steer_ok=G.is_correct_control(t,choice)
 local correct={}
 for _,x in ipairs(t.control_choices) do correct[#correct+1]=x end
 lines[#lines+1]=csv(id,t.order,t.stage,t.mode,t.seed,t.round,t.marks,
    G.signature(t),t.proposed,prediction,t.prediction_target,
    predict_ok and 1 or 0,t.request_target,choice,
    table.concat(correct,'|'),steer_ok and 1 or 0,rationale)
 if t.stage=='practice' then
  print(('Feedback: il Rivale sceglierebbe %d (%s).'):format(
   t.prediction_target,lane_names[t.prediction_target]))
  if #correct==0 then
   print('Per il secondo obiettivo non esiste una scelta valida su questo tavolo.')
  else print('Scelte valide per il secondo obiettivo: '..table.concat(correct,', ')) end
 else
  scored.total=scored.total+1
  if t.mode=='reactive' then
   scored.r_n=scored.r_n+1
   scored.r_predict=scored.r_predict+(predict_ok and 1 or 0)
   scored.r_steer=scored.r_steer+(steer_ok and 1 or 0)
  else
   scored.f_n=scored.f_n+1
   scored.f_predict=scored.f_predict+(predict_ok and 1 or 0)
   scored.f_steer=scored.f_steer+(steer_ok and 1 or 0)
  end
 end
end
local out=assert(io.open(path,'w'))
for _,line in ipairs(lines) do out:write(line) end
assert(out:close())
print('\nTest concluso. File locale: '..path)
print(('R previsioni corrette: %d/%d, influenza mirata: %d/%d'):format(
  scored.r_predict,scored.r_n,scored.r_steer,scored.r_n))
print(('F previsioni corrette: %d/%d, riconoscimento impossibilita: %d/%d'):format(
  scored.f_predict,scored.f_n,scored.f_steer,scored.f_n))
print('Questi punteggi NON certificano un incontro interessante o G4 PASS.')
print('Conservare i CSV anonimi per la revisione UAT; nessun invio automatico.')
