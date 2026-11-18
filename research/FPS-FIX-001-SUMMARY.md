# FPS-FIX-001 — PAUL Apply/Unify tecnico (18 novembre 2026)

**Base verificata:** `main@6189aa860ab85b2f233c14f13723c5b927a3027b`
(0.1.77). **Branch:** `fix/dice-obb-ccd-angular-20261118`,
PR #135 **draft** (nessun merge, proposta 0.1.78).
L'utente ha autorizzato di correggere i tre gap dell'audit.

## Piano vs realizzato

| AC | Implementato | Evidenza | Qualifica |
| --- | --- | --- | --- |
| AC-1 — niente respinte premature | SAT su facce e assi incrociati di D6 ruotati | caso centri 1.2 separati e 0.83 sovrapposti | PASS tecnico |
| AC-2 — CCD, urti decentrati | swept SAT anche con endpoint separati; impulso con leva | caso +250/-250, off-center spin, pending | PASS tecnico |
| AC-3 — test e preservazione | nuove regressioni, versione/changelog, workflow dedicato | Lua 5.4 e LuaJIT entrambi PASS, suite generale da verificare | PARZIALE |

## Esecuzione, fallimento e correzione documentati

- La prima implementazione rilevava il contatto ad alta velocità,
  ma il `dv_max=50` di `body:push` limitava il delta di
  velocità: due dadi potevano ancora oltrepassarsi in CCD.
  Il fallimento è stato **realmente osservato** nella CI dedicata
  [#44366568810](https://github.com/Askeladd22/Project_Folio/actions/runs/44366568810),
  su `9304c1f6`, `die_collision_sat_ccd_test.lua:64`.
- **Fix minimo:** soltanto quando una collisione *swept* rimane
  in avvicinamento dopo l'impulso limitato, eliminare la
  componente relativa entrante dalla traslazione conservando
  la quantità di moto normale. Il contatto estremo diventa
  più inelastico; registrato in `world.ccd_safety_stops`.
- Suite dedicata finale
  [#44366963087](https://github.com/Askeladd22/Project_Folio/actions/runs/44366963087),
  commit `39a15423cfd53b8c9a953ceb79685ec319ffab26`,
  **PASS** (Lua 5.4 e LuaJIT, 6/6 nuovi controlli + vecchi test
  physics_time, manual_dice_physics, dice_physics_audio_callbacks).
- La revisione `5414e5f2` aggiunge il caso **end-step overlap
  con centri già scambiati**: [CI dedicata #44368346259](https://github.com/Askeladd22/Project_Folio/actions/runs/44368346259)
  **PASS** su Lua 5.4 e LuaJIT per **7/7 prove**.
- Durante la regressione generale, `mouse_throw_test.lua`
  cercava un frammento del solver rimosso (`goto continue_pair`);
  aggiornata l'asserzione alla garanzia sui dadi pending nel
  modulo nuovo, senza eliminare il test comportamentale.
- `source_structure_test.lua` manteneva una allowlist esatta
  dei 29 moduli della versione precedente. Aggiornata in
  modo tracciato a 30 per registrare il nuovo modulo D6.
  La [CI generale #44368076075](https://github.com/Askeladd22/Project_Folio/actions/runs/44368076075)
  è **PASS** sulla revisione precedente `18392263`; la CI
  completa sulla HEAD finale è **da verificare**.
- Test Windows reali (minimo 50 lanci, 720p/1080p,
  single, group, shake, partial, hot dice) **NOT RUN**;
  nessuna misurazione di frametime, contatti o facce in Windows.

## Verdetto Red Team e SEED

Non chiamiamo questo codice «FPS 1.2.5 integrato».
L'upstream C usa collisione fra volumi convessi e manifold
fisico. Il fix utilizza SAT OBB in Lua su D6, una stima
del punto di contatto dai vertici di supporto, e CCD
solo traslazionale con orientamento congelato a fine step.
**Residuo tecnico:** rotazione estrema nel singolo
substep e contatti multipli fra 3+ dadi non coperti da
un confronto nativo FPS o da test manuali estesi.
Gli `_manual_pending` restano esclusi dalle collisioni
coerentemente con la presa esistente.

**PAUL:** T1/T2 implementati e test mirati PASS;
T3 CI generale/QA umano rimangono gates separati.
**SEED:** WARN finché non c'è evidenza reale
di feeling, clipping e stabilità sul PC Windows.
**Nessuna promozione G5**, nessun cambiamento
Farkle, carte, HP o struttura della run.

**Prossimo gate unico:** verificare la CI generale
sulla HEAD della PR #135, poi 50 lanci UAT Windows
prima del merge. Nessuna integrazione automatica.
