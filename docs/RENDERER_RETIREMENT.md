# Project Folio — dismissione definitiva del painter CPU

**Stato: 31 ottobre 2026 — PR #38.** Il renderer 3D è esclusivamente
**g3d**. Questo documento sostituisce il precedente audit del
30 ottobre, nel quale il painter era mantenuto come fallback.

## Eliminato

- `src/engine3d/render.lua`: renderer CPU con z-buffer e texture dipinte.
- Il comando **F9** che alternava g3d e il painter; disabilitati i vecchi
  override `MANUSCRIPT_RENDERER=legacy` e
  `MANUSCRIPT_G3D_INGAME=0`.
- Pavimento, ombre, bordi, separatore, dadi e glow del vecchio painter
  nella pipeline `src/app/dice_runtime.lua`.
- Selezione del renderer sul bridge fra fisica e UI: non esistono
  più modalità di rendering alternative.
- `hud_minimal.lua`: floor/border CPU e la cattura dei dadi
  accantonati tramite `render.die`. Rimane soltanto la
  cattura g3d di `src/engine3d/g3d_portrait.lua`.
- Funzioni di pavimento e bordo 2D del F8 workshop ormai non richiamate;
  l'interruttore **F8** e le cinque varianti **book/current/A/B/C**
  restano gestiti tramite `g3d_scenery.lua`.
- Il laboratorio g3d conserva fisica e prove di camera/mesh, ma usa
  **solo g3d**, senza il secondo Canvas per confrontare il painter.

## Rimane

- **F10**: materiali e diagnostica degli shader g3d.
- **F11**: smusso grafico dei dadi g3d.
- Tutta la fisica e il flusso Farkle, senza cambiamenti a seed,
  lettura delle facce, RNG, picking, coordinate della camera o
  accantonamento.
- Interfaccia e miniature del manoscritto in **2D**; solo tray e dadi
  in **3D**.
- Laboratori FPS in `experiments/physics_lab`, non produzione.
- UI v2 sperimentale con F6: è una scelta di layout e composizione 2D,
  **non** un renderer fisico di fallback.

## Error handling

Il rendering g3d conserva il ripristino dello stato LÖVE tramite
`graphics.push('all')`/`pop()`, anche se fallisce. La gestione degli errori
**non** spegne più g3d per avviare il painter. Geometrie non supportate
e compilazioni fallite dello shader g3d ora producono un errore
esplicito, che deve essere diagnosticato anziché mascherato.

Questa scelta elimina la possibilità di continuare una run su GPU
non compatibili: è il compromesso richiesto dall'eliminazione dei fallback,
non un miglioramento verificato dell'affidabilità.

## Verifiche ancora necessarie

La CI verifica Lua 5.4, LuaJIT, geometria g3d, regole Farkle e
laboratorio FPS. **Non prova la compilazione dello shader OpenGL né
l'assenza di artefatti sulle GPU reali.** Su Windows LÖVE controllare:
1280×720 e 1920×1080, tutte le varianti F8, F10/F11, lancio fisico
manuale e automatico, Farkle, dadi accantonati e loro ritratti g3d,
HUD precedente e UI v2 con F6, schermate di ricompensa, sfida al Monaco
e notifiche Lovely Toasts. Se fallisce un pass 3D, annotare
errore, driver, LÖVE e impostazioni; non riattivare il painter.
