# FPS-FIX-003 — PAUL UNIFY / SEED gate (18 novembre 2026)

**Baseline letta e verificata:** `main@7f65a0ca45681f93f8998bce641e6a8ce9623878`, versione 0.1.79. `#136` era già stata integrata al momento dell'audit.
**Branch:** `fix/physics-cap-repo-hygiene-20261118`; **PR #137 draft**; versione proposta 0.1.80. Nessun merge su main da questa sessione.

## PLAN → APPLY → verifica

| Task / AC | Modifica concreta | Risultato |
| --- | --- | --- |
| T1 / AC-1: spin angolare estremo | `src/engine3d/physics.lua` applica un limite `max_rotation_per_substep / sub_dt` alla velocità prima dell'integrazione, conservando direzione e registrando `angular_velocity_clamps` | **PASS tecnico**: caso 3000 rad/s riportato nel test all'angolo per sottopasso consentito; spin ordinario 10 rad/s non modificato |
| T2 / AC-2: repository hygiene | README 29→30 moduli, mappa `die_collision.lua` in `docs/technical.md`, duplicati rimossi da `repo_cleanup_boundary_test.lua`, rimosso solo `/audits/` generico da `.gitignore` preservando gli ignore specifici | **PASS**: `repository_housekeeping_test.lua`, `source_structure_test.lua` e suite generale |
| T3 / AC-3: versione e test | `version.txt` 0.1.80, nuova prima voce di `CHANGELOG.md`, piano e report di ricerca, CI PR | **PASS tecnico** in CI |
| QA Windows — 50 lanci e frametime | Nessun controllo GUI/driver Windows disponibile da questa sessione | **NOT RUN** |

## Prove realmente eseguite

- [CI fisica dedicata #44391931547](https://github.com/Askeladd22/Project_Folio/actions/runs/44391931547): **PASS** per Lua 5.4 e LuaJIT. Include `die_collision_sat_ccd_test.lua` (7 casi), `die_collision_refinement_test.lua` (6 gruppi, compreso il nuovo clamp), più regressioni tempo fisico, presa e suoni dei dadi.
- [CI generale #44391931589](https://github.com/Askeladd22/Project_Folio/actions/runs/44391931589): **PASS** per versioning, lint, sintassi Lua, test headless 5.4/LuaJIT, g3d/Mesa, Python e test del repository. Questi test verificano il codice PR prima del commit documentale UNIFY.
- Confronto con `main`: nessun file `experiments/`, `resources/`, `lib/licenses/`, `audits/` o test storici eliminato. I PNG di QA già versionati rimangono tracciati e accessibili.
- Il problema non era un'incoerenza del clock: il contatore `angular_substep_cap_hits` misurava l'overflow, ma non impediva di ruotare oltre la soglia in ciascuna sottosezione. Il clamp modifica deliberatamente **solo** lo stato ad energia estrema per privilegiare la stabilità del contatto.

## Red team e limiti

1. **Non dichiarare risolto il manifold FPS:** `die_collision.lua` continua a stimare un unico punto di contatto. Non è emerso un controesempio gameplay verificato che giustifichi oggi una seconda implementazione complessa di clipping/impulsi distribuiti.
2. **Non dichiarare completo il CCD analitico:** il campionamento angolare è limitato a 12 slices e la velocità oltre tale capacità viene tagliata; questo introduce **dissipazione** in casi estremi, non vera rotazione fisica illimitata. Per spin normali il test conferma assenza di clamp.
3. **Niente performance reali:** non esistono nuove misure FPS o lanci Windows per questa PR. Il test di 50 lanci e le misure di frametime 720p/1080p in `docs/windows_technical_qa.md` restano **da eseguire**.

## SEED: WARN, non FAIL né PASS di gameplay

- **Deciso:** preservare sei D6, Farkle, g3d, artwork, meccanica del Rivale e storia delle ricerche.
- **Verificato:** la correzione estrema ha un test osservabile e i metadati del repository sono più coerenti.
- **Aperto:** QA Windows e beneficio percepito del solver; la disponibilità di pass Lua non sostituisce un giocatore.
- **Opzione scartata:** riscrittura completa di FPS, introdurre nuovo manifold o eliminare archivio audit senza prova di ridondanza.

**Prossimo gate singolo:** collaudare in Windows i 50 lanci (15 auto, 10 singoli, 10 multipli, 10 shake, 5 parziali) confrontando CPU/frametime e clipping, registrando l'esito nel protocollo QA prima di approvare il merge della PR #137.
