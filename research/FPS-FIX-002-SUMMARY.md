# FPS-FIX-002 — PAUL Apply → Unify (18 novembre 2026)

**PLAN approvato** nella conversazione: risolvere i residui di
[FPS-FIX-001](FPS-FIX-001-SUMMARY.md).
**Base reale:** `main@61a5626ba45215bbc547ffa9dee36395e0817553`
(`0.1.78`; PR #135 già integrata prima del nuovo lavoro).
**Branch:** `fix/die-angular-substeps-multicontact-20261118`,
**PR #136 draft**. Proposta `0.1.79`, **non in main**.

## PLAN → APPLY

| Task / criteri | Esecuzione | Verifica | Qualifica |
| --- | --- | --- | --- |
| T1 / AC-1: collisione solo durante rotazione rapida | `physics.lua` usa da 1 a max 12 sottopassi con soglia angolare 0.12 rad | D6 a 0°/90° inizialmente/finalmente separato; colpisce durante la rotazione | **PASS tecnico** |
| T1 / AC-1b: integrità tempo | gravità, attenuazione, callback per tick stabile; contatori `angular_substeps` e `angular_substep_cap_hits` | callback una volta, `simulated_time`, clock 20/30/60/144 Hz | **PASS tecnico** |
| T2 / AC-2: stabilizzazione 3–6 dadi | `die_collision.lua`: sei passaggi SAT limitati; first pass swept e successivi statici | confronto 1 vs 4 passaggi su tre dadi e 1 vs 6 su sei; soglia 6 dadi < 0.025 | **PASS tecnico** |
| T2 / AC-2b: niente doppio suono | dedup per coppia per passo fisso condiviso fra sottopassi | callback audio, presa manuale, rotazioni e iterazioni | **PASS tecnico** |
| T3 / AC-3: non regressione | test nuovo + test vecchi + CI generale | Lua 5.4/LuaJIT, Farkle, LÖVE/Mesa, Python, repository | **PASS tecnico** |
| UAT Windows / 50 lanci | Non abbiamo controllo diretto della GPU/input Windows dell'utente | nessuna evidenza raccolta | **NOT RUN** |

## Prove e imprevisti realmente osservati

1. La prima versione usava quattro passaggi SAT. Il
   test sei-dadi ha misurato **0.035323** di penetrazione
   massima, fallendo la soglia predefinita **0.025** nella
   [CI #44386742323](https://github.com/Askeladd22/Project_Folio/actions/runs/44386742323).
   Anziché allargare la soglia, abbiamo aumentato il default
   a **sei passaggi**. Gli stessi test hanno così superato la
   soglia; questo è un raffinamento della policy iterativa,
   non un nuovo manifold FPS.
2. Il test `mouse_throw_test.lua` conteneva un controllo
   *testuale* sulla vecchia chiamata a `C.solve` con
   `self.dt`. Il runtime ora usa correttamente
   `sub_dt` e la guardia audio `emitted_pairs`. Aggiornato
   soltanto il contratto statico; mantenute le verifiche
   funzionali di presa/ritiro.
3. [**CI mirata #44387298729**](https://github.com/Askeladd22/Project_Folio/actions/runs/44387298729):
   PASS in **Lua 5.4 e LuaJIT**, comprende sette test precedenti,
   sei gruppi nuovi, physics_time, manual_dice_physics,
   dice_physics_audio_callbacks, mouse_throw, fps_wall_bounds.
4. [**CI generale #44387298518**](https://github.com/Askeladd22/Project_Folio/actions/runs/44387298518):
   PASS, compresi controlli versionamento, sintassi, headless Lua,
   smoke LÖVE/Mesa e test Python.
5. Le CI sono state eseguite sul commit comportamentale
   `e8a76ea82308a57690780fba310dac94813d8337`
   contenente la correzione al test statico; le modifiche
   successive previste sono **solo di documentazione**.

## Red team e limiti

- Non è FPS nativo e non abbiamo implementato clipping
  manifold multipunto: il punto di contatto viene tuttora
  stimato. La stabilità 3–6 dadi è un **miglioramento
  verificato nei casi testati**, non garanzia per ogni
  geometria, materiale e distribuzione di urti.
- Il metodo per la rotazione è **sottocampionamento limitato**,
  non CCD rotazionale analitico; rotazioni che richiedano
  oltre 12 sotto-step per tick sono registrate nel contatore
  `angular_substep_cap_hits` ma non garantite perfette.
- La spesa CPU può aumentare fino a 12× il passo solo
  durante rotazioni elevate e fino a sei passaggi su coppie
  in contatto; **frametime Windows reale NON MISURATO**.
- Farkle, sei D6 canonici, logica Rivale, renderer g3d,
  scelte di world structure e gameplay canonico non cambiano.
- Per la QA Windows rimane valida la procedura da 50 lanci
  in `docs/windows_technical_qa.md`; non simulare
  risposte, screenshot o benchmark PC dell'utente.

## UNIFY e gate

**PAUL:** PLAN ✓, APPLY tecnicamente PASS, UNIFY
documentato; QA Windows ancora **OPEN**. **PR #136 draft**,
nessun merge e nessuna nuova decisione di design canonica.

**Prossimo gate unico:** dopo checkout della PR #136,
eseguire 50 lanci Windows reali (automatici, manuali,
multipli, shake, parziali) e raccogliere FPS/frametime
720p/1080p più eventuali errori riproducibili. Solo allora
rivalutare l'approvazione del merge.
