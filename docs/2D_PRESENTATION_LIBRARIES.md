# Project Folio — dipendenze 2D e criteri di integrazione

31 ottobre 2026. Ambito deliberatamente limitato: **figure animate,
miniature, glosse, ornamentazione e post-processing 2D**. I **sei dadi e
il tray restano 3D** tramite g3d. Nessuna libreria di questo elenco può
introdurre corpi rigidi, alterare il picking o modificare Farkle.

## Librerie vendorizzate, con versioni fissate

| Sorgente | Percorso locale | Riferimento upstream | Licenza e uso |
|---|---|---|---|
| [rxi/flux](https://github.com/rxi/flux) | `lib/flux.lua` | `bb330231b87eabf84fbd68322f13a6320db30a41` (`0.1.5`) | MIT: `third_party/LICENSE_flux` |
| [kikito/anim8](https://github.com/kikito/anim8) | `lib/anim8.lua` | `bd38defa844ab2dfa3bf416a10c45ce376ba4c50` (`2.3.1`) | MIT: `third_party/LICENSE_anim8` |
| [SYSL-Text](https://github.com/sysl-dev/SYSL-Text) | `lib/sysl_text.lua` | `6c9b95047cb8650344e90224cd56bd00c5132d97` (`2.2`) | MIT: `third_party/LICENSE_sysl_text` |
| [vrld/moonshine](https://github.com/vrld/moonshine) | `lib/moonshine/init.lua`, `vignette.lua` | `d39271e0c000e2fedbc2e3ad286b78b5a5146065` | Core MIT (copyright/licenza in `init.lua`); effetto vignette con avviso public-domain nel file |

Sono stati copiati gli originali upstream senza adattamenti o
ottimizzazioni al loro interno. Si adattano i **chiamanti**, non i sorgenti
di terze parti. Le licenze dei vendored non cambiano la licenza del codice
originale di Project Folio.

## Contratti degli adattatori

- `src/features/scriptorium/miniature_2d.lua`: sprite sheet 2D con
  `anim8.newGrid/newAnimation`; posa in pixel con un gruppo isolato
  `Flux.group()`; `move_to`, `return_to_page`, `update` e `draw`.
  Nessun import di g3d, dati dei dadi, Farkle o codice degli incontri.
- `src/features/scriptorium/folio_ink_text.lua`: SYSL-Text caricato
  **solo a richiesta** quando LÖVE Graphics è disponibile, con
  `update(dt)`, `draw(x,y)`, `show_all()`. Rispetta l'opzione
  reduced-motion evitando di far aspettare un testo decorativo.
- `src/features/scriptorium/dream_postfx_2d.lua`: un solo effetto
  `vignette`, disattivato all'avvio; accetta una funzione che disegna
  **solo contenuti 2D**. Non circondare `drawDeskOverlays`, g3d o il
  Render pass del tray con questa catena senza studio esplicito dei
  Canvas/depth attachments.
- `experiments/miniature_2d_lab/main.lua`: dimostrazione navigabile
  originale, avviata solo con `PROJECT_FOLIO_MINIATURE_LAB=1`.

## Esclusioni consapevoli

- **Nessun Menori o 3DreamEngine:** g3d resta l'unico renderer 3D del gioco.
- **lövector non vendorizzata:** utile a un eventuale esperimento su
  ornamenti SVG, ma non c'è ancora un asset vettoriale di produzione o
  un bisogno di tutti i suoi moduli. Evitare peso e API premature.
- **Moonshine non attivata globalmente:** i Canvas di post-processing
  potrebbero interagire con il depth test g3d; il default resta **OFF**.
- Non si aggiungono nuovi tasti, HP, avversari già attivi o meccaniche
  fuori dal Farkle. La figura del laboratorio è **soltanto un prototipo
  visivo**, non un boss giocabile.

## Verifica

`tests/miniature_2d_libraries_test.lua` esercita davvero le versioni
vendorizzate di Flux e anim8, i due adattatori (con falso renderer per
SYSL), la modalità movimento ridotto e la catena Moonshine come interfaccia
opzionale. Tutta la suite è eseguita dalla CI in Lua 5.4 e LuaJIT.

La CI headless **non** verifica i shader GLSL, il testo reale UTF-8 e
la resa in LÖVE 11.x. QA Windows e screenshot comparativi necessari
prima di integrare miniature e post-processing nella UI di produzione.

Vedere [README laboratorio](../experiments/miniature_2d_lab/README.md)
e [tracker UI](UI_V2_STATUS.md).
