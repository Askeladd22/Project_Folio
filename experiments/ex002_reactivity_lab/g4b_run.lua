-- G4b offline anonymous human test (NO CI-generated participant outcomes).
-- From repo root: lua5.4 experiments/ex002_reactivity_lab/g4b_run.lua P01 ./results
local B=require('experiments.ex002_reactivity_lab.g4b_stimuli')
local G=B.G
local participant=arg[1]
local out=arg[2] or '.'
assert(participant and participant:match('^[A-Za-z0-9_-]+$') and
 #participant<=24,'Provide pseudonym P01 (letters, digits, _ or -)')
local path=out..'/g4b_'..participant..'.csv'
local f=io.open(path,'r')
if f then f:close();error('Refusing overwrite: '..path) end
local trials=B.manifest();assert(B.assert_manifest(trials))
local function csv(...)
 local a={...}
 for i,v in ipairs(a) do
  local s=tostring(v)
  if s:find('[,"\r\n]') then s='"'..s:gsub('"','""')..'"' end
  a[i]=s
 end
 return table.concat(a,',')..'\n'
end
local function ask(label,allowed)
 while true do
  io.write(label);io.flush()
  local raw=io.read('*l')
  if not raw then error('EOF: no participant file written') end
  local n=tonumber(raw)
  if n and n%1==0 and allowed[n] then return n end
  print('Risposta non valida: usa i numeri indicati.')
 end
end
print('Project Folio G4b — studio offline di comprensione.')
print('Non inserire nomi, email o altre informazioni identificabili.')
print('Due esercitazioni con feedback, 12 prove senza feedback.')
io.write('Partecipi volontariamente? (s/n): ');io.flush()
local confirm=io.read('*l')
if confirm~='s' and confirm~='S' then
 print('Nessun dato scritto.');return
end
local rows={csv('participant','order','stage','mode','condition',
 'seed','round','marks','board','proposed','prediction',
 'prediction_true','prediction_ok','requested_target','chosen_lane',
 'correct_lanes','control_ok','explanation')}
local summary={}
local yn={[1]=true,[2]=true,[3]=true}
local zero={[0]=true,[1]=true,[2]=true,[3]=true}
for i,t in ipairs(trials) do
 print(('\n=== %02d/14 — %s ==='):format(i,
  t.stage=='practice' and 'PRATICA' or 'TEST'))
 print(G.rule(t.mode))
 print(G.display_board(t))
 local prediction=ask(('Se metti %d sigilli in categoria %d, '..
  'dove risponde il Rivale (1/2/3)? '):format(t.marks,t.proposed),yn)
 local chosen=ask(('Per OTTENERE una risposta in categoria %d, '..
  'dove metti i sigilli (0=impossibile, 1/2/3)? '):
  format(t.request_target),zero)
 local explanation=''
 if t.stage=='test' and (i==5 or i==12) then
  io.write('Spiega brevemente la tua scelta: ');io.flush()
  explanation=io.read('*l')
  if not explanation then error('EOF: no participant file written') end
 end
 local prediction_ok=prediction==t.prediction_target
 local control_ok=B.is_correct_control(t,chosen)
 rows[#rows+1]=csv(participant,t.order,t.stage,t.mode,t.condition,
  t.seed,t.round,t.marks,G.signature(t),t.proposed,prediction,
  t.prediction_target,prediction_ok and 1 or 0,t.request_target,
  chosen,#t.control_choices>0 and
   table.concat(t.control_choices,'|') or '0',control_ok and 1 or 0,
  explanation)
 if t.stage=='practice' then
  print('Feedback: il Rivale sceglierebbe '..t.prediction_target)
  print('Soluzioni seconda domanda: '..
   (#t.control_choices>0 and table.concat(t.control_choices,', ') or '0 (impossibile)'))
 else
  local k=t.condition
  summary[k]=summary[k] or {n=0,p=0,c=0}
  summary[k].n=summary[k].n+1
  summary[k].p=summary[k].p+(prediction_ok and 1 or 0)
  summary[k].c=summary[k].c+(control_ok and 1 or 0)
 end
end
local output=assert(io.open(path,'w'))
for _,line in ipairs(rows) do output:write(line) end
assert(output:close())
print('\nRisposte salvate SOLO in locale: '..path)
for _,k in ipairs({'R_yes','R_no','F_yes','F_no'}) do
 local s=assert(summary[k])
 print(('%s: previsione %d/%d; obiettivo %d/%d'):format(
  k,s.p,s.n,s.c,s.n))
end
print('Nessuna conclusione di mastery e nessun dato inviato in rete.')
