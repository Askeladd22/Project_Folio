# FPS-FIX-003 / Repository Hygiene — PAUL PLAN (18 novembre 2026)

**Approvazione di scopo:** richiesta esplicita dell'utente di risolvere i limiti fisici e pulire il repository con PAUL e SEED.
**Baseline verificata:** `main@7f65a0ca45681f93f8998bce641e6a8ce9623878`, versione `0.1.79`; PR #136 già merged. **Branch:** `fix/physics-cap-repo-hygiene-20261118`.
**NO MERGE** e nessuna modifica alla logica Farkle, al tavoliere o al renderer g3d. Salvaguardare `research/`, `experiments/`, asset e storici delle prove, senza eliminazioni speculative.

## Evidenza del problema

- `physics.lua` usa fino a 12 sottopassi per rotazioni forti, ma registra `angular_substep_cap_hits` senza **limitare la rotazione effettiva**. Con `|ω|=3000 rad/s` e `dt=.01`, ogni sottopasso può ruotare di 2.5 rad, ben oltre la soglia configurata 0.12: il rilevamento della collisione puramente rotazionale può saltare il contatto.
- I normali input di lancio e shake in `src/farkle/interaction.lua` sono già contenuti intorno a 10–14 rad/s; il caso estremo riguarda input anomali o impulsi estremi, non un nuovo comportamento di gameplay.
- `README.md` riferisce ancora **29** moduli Lua, mentre `tests/repo/source_structure_test.lua` ne richiede **30**; `docs/technical.md` non indica separatamente `src/engine3d/die_collision.lua`.
- `tests/repo/repo_cleanup_boundary_test.lua` elenca due volte `src/farkle/ui.lua` e `src/screens/frontend.lua`; `.gitignore` ha pattern `/audits/` che rende superflui i tre pattern più specifici nello stesso file. Le immagini QA già tracciate non vengono cancellate: un ignore non rimuove i file versionati.

## Task e criteri di accettazione

**T1 / AC-1 — clamp di sicurezza angolare, non nuovi sottopassi**
- File: `src/engine3d/physics.lua`, `tests/engine3d/die_collision_refinement_test.lua`.
- Given `max_rotation_per_substep=0.12`, `max_angular_substeps=12`, `dt=.01`;
  When la velocità angolare richiederebbe >12 sottopassi;
  Then il solver limita la velocità angolare **prima di integrare l'orientamento**, preservando la direzione, in modo che ogni sottopasso non superi la soglia; conta `angular_velocity_clamps`, oltre a `angular_substep_cap_hits`.
- Given una rotazione normale, un dado in mano o una simulazione senza rotazioni;
  When il passo fisso avanza;
  Then nessun clamp extra, stessi tempi e semantica dei callback, nessun effetto sullo scoring.
- La verifica esegue anche i vecchi 7 + 6 gruppi di prova e test Lua5.4/LuaJIT; riportare se il clipping della rotazione massima comporta perdita energetica (sì, deliberata).

**T2 / AC-2 — housekeeping certo e tracciabile**
- File: `README.md`, `docs/technical.md`, `.gitignore`,
  `tests/repo/repo_cleanup_boundary_test.lua` ed eventuale regressione minima.
- Given la topologia attuale; When il repository viene verificato;
  Then documentazione e test concordano su 30 moduli; i controlli sui moduli obsoleti non duplicano percorsi; ignore di audit rimane efficace; asset e ricerche restano intatti.
- **Non eliminare** audit storici tracciati, PNG, font, workflow CI, esperimenti o directory solo in base a nomi o dimensioni. Nessun cleanup distruttivo per assenza di prove.

**T3 / AC-3 — regressioni, versionamento e UNIFY**
- `version.txt` >0.1.79, nuova sezione `CHANGELOG.md`, dossier
  `research/FPS-FIX-003-SUMMARY.md` e verifica GitHub Actions
  sul commit finale; no merge in `main`.
- QA con 50 lanci reali Windows resta **NOT RUN**. Framerate reale e fisica assoluta di ogni contatto non sono dimostrabili con test headless.

## Red team / SEED
Il punto di contatto rimane una stima dai supporti del cubo: **nessun bug riproducibile del manifold** è attualmente documentato. Non sviluppare un solver manifold completo soltanto per somigliare a FPS C. Lo switch a manifold richiederebbe un esperimento isolato, confronto qualitativo/quantitativo e UAT, non è parte di questo fix. Nessun cambiamento a dadi canonici e mastery. **Gate SEED:** WARN finché manca collaudo Windows.
