# Promozione definitiva del Farkle e pulizia della documentazione

15 ottobre 2026. **Completata:** Manuscript parte da sorgenti con `love .` e `Avvia.cmd`; il Farkle è organizzato in `src/`, senza moduli di produzione o alias sotto `experiments/farkle_roguelite/`.

## Baseline e perimetro

La baseline è la versione corrente con il nuovo regolamento già implementato e verificato, non una vecchia copia del gioco. Prima della migrazione: 19/19 file della suite generale, test Farkle/HUD/spawn e 4 test Python del runtime; smoke reali di partial/A-B/integration, HUD 1280×720/1920×1080 e frontend tramite launcher superati. Evidenze in [validation.log](audits/farkle-official/validation.log).

La richiesta precedente sul regolamento viene documentata direttamente nei nuovi documenti canonici: [FARKLE_RULES.md](docs/FARKLE_RULES.md) consolida la consegna originariamente chiamata `NUOVO_REGOLAMENTO_FARKLE.md`; [GAME_DESIGN.md](docs/GAME_DESIGN.md) versione 0.4 sostituisce il vecchio `MANUSCRIPT_GAME_DESIGN (2).md`. Non vengono creati duplicati con i vecchi nomi.

Checkpoint completo **prima** dei trasferimenti: 6.882 file, 15.658.313.679 byte di contenuti, inclusi audit, backup e pacchetti storici già presenti. Archivio `audits/farkle-promotion/before.zip`, manifest [before.json](audits/farkle-promotion/before.json); ogni membro riletto e verificato SHA-256. La sola directory che contiene questo nuovo checkpoint è esclusa per evitare autoricorsione.

SHA-256 archivio: `dd6c7ec73ecccd8813b06ccae2d4a310210fe5d712f1a4a7e500ba1ac0b5f2d1`.

Nessun nuovo `.love` generato. Il checkpoint occupa circa 15,66 GB: è un backup completo, non un pacchetto di esecuzione.

## Trasferimenti canonici

Prima: entry point nella radice e runtime in `src/app/`, ma regole/controller/HUD sotto `experiments/farkle_roguelite/`. Dopo: stessa catena di callback e API, import aggiornati, responsabilità nelle directory ordinarie.

| Prima | Dopo |
|---|---|
| `experiments/farkle_roguelite/rules.lua` | `src/gameplay/farkle/rules.lua` |
| `experiments/farkle_roguelite/scoring.lua` | `src/gameplay/farkle/scoring.lua` |
| `experiments/farkle_roguelite/dice.lua` | `src/features/farkle/dice.lua` |
| `experiments/farkle_roguelite/ui.lua` | `src/features/farkle/controller.lua` |
| `experiments/farkle_roguelite/hud.lua` | `src/features/farkle/hud.lua` |
| `experiments/farkle_roguelite/hud_model.lua` | `src/features/farkle/hud_model.lua` |
| `experiments/farkle_roguelite/tray_view.lua` | `src/features/farkle/tray_view.lua` |
| `experiments/farkle_roguelite/test_hud.lua` | `tests/farkle_hud_test.lua` |
| `experiments/farkle_roguelite/hud_smoke.lua` | `tests/smoke/farkle_hud.lua` |
| `experiments/farkle_roguelite/tray_smoke.lua` | `tests/smoke/farkle_tray.lua` |
| `experiments/farkle_roguelite/analyse.lua` | `scripts/farkle_analysis.lua` |

Le copie correnti degli harness storici partial, face-gate, integrazione e frontend sono ora in `tests/smoke/`; il test spawn in `tests/spawn_clearance_test.lua`. Gli originali degli audit non sono stati modificati. Queste sono versioni di test, non copie parallele dei moduli di produzione.

`scripts/run_smoke.py` riunisce l'avvio dei test correnti e isola APPDATA/output. Il launcher root era già corretto e resta byte per byte invariato; il vecchio launcher delegante, il vecchio smoke generico e il piccolo wrapper `test.lua` sono archiviati con le evidenze rimaste del prototipo. L'analizzatore numerico trasferito aveva ancora due aspettative della vecchia tabella: aggiornate a 1080 Farkle su 46656 e 1850 punti sommati su 216 tiri di tre dadi. È una correzione delle aspettative del diagnostico, non del gioco.

Aggiornati import fra regole, controller, HUD, adattatore dadi, test, hook diagnostici di `main.lua`, percorsi di output e controlli di isolamento. Il divieto generico di importare qualsiasi `src.gameplay` nel vecchio test di confine è stato ristretto ai moduli cromatici realmente vietati. Nessuna risorsa è stata trasferita o modificata.

Gli ID `startup_splash`, `main_menu`, `settings`, `campaign_select`, `scriptorium` e l'identità `manuscript-farkle-roguelite` sono invariati. Settings e `runs.csv` restano nell'identità Farkle; Continue resta disabilitato. New Game/Choose Commission conserva Farkle e Back. I caricamenti dinamici del frontend e delle texture individuali restano operativi.

## Documentazione: pulizia effettiva

| Conteggio | Prima | Dopo |
|---|---:|---:|
| Markdown nel repository, file estratti | 63 | 43 |
| Di cui sotto `audits/`, protetti | 23 | 23 |
| Fuori dagli audit | 40 | 20 |
| Markdown nella radice | 20 | 2 |

**24 Markdown eliminati**, dopo confronto del loro hash con il checkpoint; **6 rapporti spostati**, **4 documenti creati** (tre canonici e questo rapporto richiesto). README e indice legacy aggiornati. I conteggi non includono file interni agli archivi ZIP/.love. Nessun rapporto Markdown aggiunto per i singoli passi: inventari, piano e manifest sono JSON nell'audit.

Documenti autorevoli: [README](README.md), [design](docs/GAME_DESIGN.md), [regole](docs/FARKLE_RULES.md), [tecnica](docs/TECHNICAL.md), [indice storico](legacy/README.md). Questo rapporto è l'eccezione richiesta per tracciare la migrazione.

Consolidati: regole e parametri attuali; soglie, opzioni e risultati numerici; identità/proposte/questioni aperte del GDD; pipeline e identità dei salvataggi; contratto A/B, D2 e spawn; mapping triangolato e texture; limiti fisici noti; contratto PNG/cache/fallback. Le vecchie coordinate del puzzle cromatico non sono presentate come HUD corrente. La bibliografia è riassunta nel GDD senza attribuire regole non approvate.

Rapporti conservati per le loro evidenze uniche:

- [audit-motore-3d.md](legacy/reports/audit-motore-3d.md).
- [correzione-renderer-dadi.md](legacy/reports/correzione-renderer-dadi.md).
- [consolidamento-finale-spawn.md](legacy/reports/consolidamento-finale-spawn.md).
- [verifica-fallback-spawn.md](legacy/reports/verifica-fallback-spawn.md).
- [reverse-kcd2-dice.md](legacy/reports/reverse-kcd2-dice.md).
- [reverse-scriptorium.md](legacy/reports/reverse-scriptorium.md).

Eliminazioni e destinazione delle informazioni ancora pertinenti:

- `audit-pulizia-refactor.md` → `docs/TECHNICAL.md`.
- `avvio-diretto-sorgenti.md` → `docs/TECHNICAL.md`.
- `consolidamento-motore-3d-fase2.md` → `docs/TECHNICAL.md`.
- `consolidamento-motore-3d.md` → `docs/TECHNICAL.md`.
- `esperimento-lancio-vassoio.md` → `docs/TECHNICAL.md`.
- `generazione-dadi-senza-overlap.md` → `docs/TECHNICAL.md`.
- `ottimizzazione-locale-motore-3d.md` → `docs/TECHNICAL.md`.
- `promozione-ab-diagnosi-fisica.md` → `docs/TECHNICAL.md`.
- `PULIZIA_REPOSITORY.md` → `docs/TECHNICAL.md`.
- `STATO-MOTORE-3D.md` → `docs/TECHNICAL.md`.
- `texture-dadi-temporanee.md` → `docs/TECHNICAL.md`.
- `MANUSCRIPT_GAME_DESIGN (2).md` → `docs/GAME_DESIGN.md`.
- `folio-progressivo-design.md` → `docs/GAME_DESIGN.md`.
- `docs/arte-del-rischio-design.md` → `legacy/prototypes/experiments/arte_del_rischio/README.md`.
- `docs/artwork-guide.md` → `docs/TECHNICAL.md`.
- `docs/desk-assets.md` → `docs/TECHNICAL.md`.
- `experiments/farkle_roguelite/README.md` → `docs/FARKLE_RULES.md`.
- `experiments/farkle_roguelite/PLAN.md` → `docs/FARKLE_RULES.md`.
- `legacy/prototypes/experiments/folio_roguelite/PLAN.md` → `legacy/prototypes/experiments/folio_roguelite/README.md`.
- `docs/superpowers/plans/2026-10-14-arte-del-rischio.md` → `legacy/prototypes/experiments/arte_del_rischio/README.md`.
- `docs/superpowers/plans/2026-10-15-engine-consolidation.md` → `docs/TECHNICAL.md`.
- `docs/superpowers/plans/2026-10-15-engine-phase2.md` → `docs/TECHNICAL.md`.
- `docs/superpowers/plans/2026-10-15-legacy-local.md` → `docs/TECHNICAL.md`.
- `docs/superpowers/plans/2026-10-15-promotion-launch.md` → `docs/TECHNICAL.md`.

I dettagli dei protocolli intermedi restano integralmente recuperabili nel checkpoint; i loro dati di audit non sono eliminati. I README dei prototipi archiviati e i risultati delle 54.000 simulazioni dell'Arte del rischio rimangono perché descrivono materiali diversi dal gioco corrente. Conservati anche licenza splash, documentazione bloom, licenze/attribuzioni non-Markdown e istruzioni di ripristino. Nessun AGENTS/CLAUDE presente è stato cancellato.

Censimento completo con percorso, contenuto, data filesystem, hash, titoli e candidati riferimenti: [markdown-before.json](audits/farkle-promotion/markdown-before.json). La data è quella del file, non una data di pubblicazione verificata. Decisioni per tutti i 63 documenti: [markdown-classification.json](audits/farkle-promotion/markdown-classification.json). Riferimenti per nome comune come README sono candidati, non prove di caricamento. Dettaglio delle rimozioni/archiviazioni: [cleanup.json](audits/farkle-promotion/cleanup.json).

Aggiornati 17 collegamenti nei documenti esistenti, oltre ai nuovi collegamenti dei documenti canonici; [link-edits.json](audits/farkle-promotion/link-edits.json). Zero link locali Markdown mancanti fuori da audit/backup nella verifica finale. I riferimenti testuali e comandi degli audit/checkpoint protetti restano storici: non sono alias attivi; riprodurli nel loro checkpoint. [document-paths.json](audits/farkle-promotion/document-paths.json) permette di risalire ai nuovi documenti.

## Verifiche dopo la migrazione

- **22/22 file Lua**, inclusi HUD/spawn ora nella suite ordinaria e nuovo test dei percorsi; **4/4 test Python** del runtime. [Log](audits/farkle-promotion/unit-validation.log).
- Enumerazione esatta e 923 multinsiemi: punteggi/rischi coerenti con il regolamento già approvato. Nessuna nuova campagna fisica o ritaratura.
- Rilanci fisici subset 1, 2/4/6, 1–5 e 1–6: accantonati esclusi e immutati, rollback su spawn esaurito, retry riuscito.
- A/B: posa ambigua rifiutata, recuperi limitati, retry manuale, stato Farkle invariato.
- Integrazione: normale/inciso/pesato sui seed 54083 e 87001, più copertura del rifiuto pesato; faccia geometrica e valore concordi. **Log prima/dopo identici**, compresi esiti e numero di passi; [confronto](audits/farkle-promotion/physical-comparison.json). Non è una certificazione cross-platform o statistica.
- Hot dice e Correttore avviano lanci fisici; 36 associazioni faccia-texture, background/banco/pergamena/font/shader caricati.
- HUD completo a **1280×720 e 1920×1080**: selezione mouse e tastiera, picking 6/6, accantonamento, rilanci, Farkle, hot, incasso, soglie, commissioni, ricompense e modali; anche alternative A/B/C e paginazione.
- Frontend tramite `Avvia.cmd`: splash completa e salto, menu, Continue disabilitato, Settings salvate/ricaricate su disco isolato, New Game, Choose Commission, Back, Farkle, testo grande e Quit.
- Nessun modulo `experiments.*` caricato nei censimenti runtime; zero vecchi riferimenti in entry point, sorgenti e strumenti correnti.
- **6.434 file protetti invariati**: audit precedenti, backup, motore, risorse/librerie/licenze, runtime, conf e launcher. I sette moduli di produzione trasferiti sono equivalenti byte per byte dopo la sola sostituzione degli import: [verification.json](audits/farkle-promotion/verification.json).

Screenshot controllati visivamente: [selezione reale 1920](audits/farkle-promotion/after/hud/hud-usability-1920-selected.png), [soglia e selezione 1280](audits/farkle-promotion/after/hud/hud-usability-1280-entry-selected.png), [Choose Commission 1280](audits/farkle-promotion/after/frontend/1280-commissions.png). La seconda usa una fixture numerica per l'HUD: i dadi 3D possono conservare le pose del tiro precedente, non è una discrepanza osservata nel flusso fisico reale. Tutti gli screenshot e log in `audits/farkle-promotion/after/`.

## Regressioni e differenze

Nessuna differenza funzionale introdotta nei sette moduli di produzione. Durante il primo smoke post-migrazione, una sostituzione di prefisso aveva indirizzato il test HUD a un modulo inesistente: il processo è andato in timeout prima di creare il log. Corretto soltanto il require diagnostico verso `tests.smoke.farkle_hud`, aggiunto controllo dei moduli dell'entry point e ripetuta con successo l'intera suite smoke.

Lo smoke generico storico è archiviato; usare i test correnti, non `MANUSCRIPT_FARKLE_SMOKE`. Gli audit storici mantengono volontariamente import vecchi e richiedono il loro checkpoint. La revisione indipendente tentata non è stata eseguita per limite del servizio: non viene conteggiata come test superato. Restano i controlli riproducibili e di equivalenza descritti sopra.

Persistono i limiti fisici già noti, e gli obiettivi/soglie del nuovo regolamento restano provvisori. La migrazione non è un intervento di bilanciamento né corregge compenetrazioni.

## Rollback

1. Chiudere LÖVE. Conservare l'attuale cartella senza sovrascriverla.
2. Verificare SHA-256 di `audits/farkle-promotion/before.zip` contro `checkpoint.sha256`.
3. Estrarre in una **directory nuova e vuota**, con spazio per almeno 16 GB, usando Python ZIP64:

```text
python -m zipfile -e audits/farkle-promotion/before.zip C:\Percorso\Manuscript-ripristinato
```

4. Confrontare i file estratti con `before.json`, poi avviare `love .` o `Avvia.cmd` da quella directory. Si recupera l'intero stato pre-migrazione, compresi nuovi punteggi già approvati, vecchi percorsi e documenti, audit e backup. Non sovrascrivere indiscriminatamente una directory con modifiche successive.

I salvataggi personali non sono nel checkpoint del repository e non sono stati modificati dai test: tutti gli smoke usano APPDATA isolati. La migrazione conserva la stessa identità, quindi una sessione normale usa le impostazioni Farkle esistenti.
