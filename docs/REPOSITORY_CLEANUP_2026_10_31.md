# Project Folio — pulizia conservativa del repository (2026-10-31)

## Perimetro verificato

Audit condotto su `main@7f5b1ace269546a8036fdf599ff326bd69f1de2c`:
339 file tracciati; 86 moduli Lua in `src/`. PR #36 (Lovely
Toasts / Monaco) era separata, **aperta e non ancora in main** al
momento dell'inventario. Non riscrivere la cronologia Git per questa
pulizia. I file eliminati restano recuperabili dai commit precedenti.

Controllati gli import diretti dei moduli `src/`, i riferimenti
letterali alle risorse in schema, HUD e renderer, il perimetro di
`tests/`, gli script del repository e i launcher/laboratori.

## Eliminazioni

| Gruppo | File | Perché |
|---|---:|---|
| Codice cromatico morto | 3 | `scriptorium/desk_view.lua`, `data/colors.lua`, `data/scriptorium_module_config.lua`: vecchia UI a celle/inchiostri non raggiungibile nel Farkle attuale; l'import in `hud_minimal.lua` era inutilizzato |
| Presentazione duplicata | 1 | `farkle/presentation_view.lua`: implementazione legacy autonoma, non importata dai runtime attivi; il vassoio dei dadi accantonati è disegnato in `hud_minimal.lua` |
| Test del sistema eliminato | 2 | `desk_assets_test.lua` e `retired_desk_assets_test.lua`: testavano esclusivamente la gestione di PNG della vecchia UI, rimpiazzati da un controllo strutturale di regressione |
| PNG non utilizzati | 4 | `resources/ui/game.png`, `resources/ui/splash.png`, `resources/textures/marble.png`, `resources/textures/marble2.png` |
| Font e licenza relativi a UI rimossa | 2 | `resources/font/UnifrakturMaguntia-Regular.ttf` e `third_party/OFL_UnifrakturMaguntia.txt` (nessun uso da runtime, dopo la rimozione dello schema cromatico) |
| Screenshot di audit rigenerabili | 20 | `experiments/fx_lab/audit/effect-*-{1280x720,1920x1080}-{animated,disabled}.png` |

**Totale: 32 file, 4.725.213 byte (~4,73 MB decimali) di
contenuti tracciati rimossi.** Questa è una riduzione della
dimensione della *working tree*, **non** della dimensione totale
dell'archivio Git: gli oggetti restano nella storia. Se servisse
ridurre le dimensioni di clone dell'intero progetto, valutare una
migrazione Git LFS o un rewrite separato con consenso esplicito.

Modificati anche:
- `hud_minimal.lua`: import morto eliminato.
- `tests/schema_usage_test.lua` e `tests/legacy_boundary_test.lua`:
  rimosso il solo riferimento a file cancellato, mantenuti i controlli.
- `tests/smoke/integration.lua`: ora verifica che la vecchia UI
  non sia importata; il test precedente pretendeva PNG da un
  dizionario `desk_assets={}` ormai permanentemente vuoto.
- `tray_workshop.lua`: commento aggiornato con il vero proprietario
  delle miniature dei dadi accantonati.
- `.gitignore`: impedisce che i PNG dell'audit tornino tracciati.
- `docs/FX_PROTOTYPES.md` e `experiments/fx_lab/README.md`:
  link riparati e istruzioni per ricreare le immagini, evitando link rotti.
- `tests/repo_cleanup_boundary_test.lua`: controllo automatico che
  i file eliminati non ricompaiano per errore.

## Materiale volutamente conservato

- **`resources/textures/tray/walnut.png` (81.056.842 byte):
  texture 4K RGBA16 ancora usata.** Non sostituire né eliminare senza
  verificare UV/qualità a 720p e 1080p e tutti i layout F8/F9. È di
  gran lunga il maggior candidato di *ottimizzazione*; proporre
  eventualmente un PNG RGBA8/texture compressa e comparazione visiva
  dedicata, ma non sacrificare il tray per ridurre statistiche.
- **`src/engine3d/render.lua`**: renderer F9/fallback e supporto
  alla comparazione A/B; è ancora una dipendenza reale.
- **`src/engine3d/physics.lua`**, `lib/g3d` e texture dei sei D6:
  imprescindibili. Nessun cambio a RNG, scoring, collisioni o picking.
- **`experiments/physics_lab`**: FPS non è produzione, ma i laboratori
  di confronto restano riproducibili e testati in CI.
- **`experiments/g3d_lab`**, `experiments/miniature_2d_lab`,
  `experiments/fx_lab` (codice, script e report storici): valore
  diagnostico e per la QA dell'interfaccia 2D/3D.
- `docs/artwork/layout-guide-1920x1080.png` e il relativo overlay:
  evidenze della P0/P1 non equivalenti agli screenshot temporanei FX.
- `lib/anim8.lua`, `lib/flux.lua`, `lib/sysl_text.lua`,
  `lib/moonshine` e le rispettive licenze: tutte già usate
  nel laboratorio 2D; PR #36 introduce Lovely Toasts separatamente.

## Gate

1. CI headless Lua 5.4 / LuaJIT e Python, laboratorio FPS.
2. Smoke con `MANUSCRIPT_SOURCE_CASE=integration` su Windows LÖVE
   dopo aver fornito `MANUSCRIPT_AUDIT_OUT`.
3. Avvio normale, nuova partita, F6 UI sperimentale, F8/F9,
   tiro di sei D6, accantonamento, Farkle, salvataggio impostazioni.
4. Confronto visivo 720p / 1080p e verifica della PR #36 dopo merge.

**Non dichiarare la QA grafica completata sulla base della sola CI.**
