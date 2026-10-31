# UI 2.0 — Registro operativo / unica fonte di avanzamento

> **Aggiornare questo file dopo ogni sessione che modifica il redesign.**
> Non dedurre «DONE» dal fatto che esiste una PR: servono gate e test.
> Roadmap completa e prompt: [UI_V2_ROADMAP.md](UI_V2_ROADMAP.md).

## Stato corrente — 31 ottobre 2026

- **FASE ATTIVA:** `P0 — baseline e audit completo`.
- **CONDIZIONE:** `IN CORSO` (matrice completa e test automatico di inventario aggiunti; resta QA grafica e manuale della baseline).
- **BASELINE VERIFICATA:** `main@74ee2b32ef3383924bb239305e26bde521487f68` (PR #30 già integrata e CI verde).
- **BRANCH CORRENTE:** `experiment/ui-v2-p1-layout-study-20261031` (studio geometrie P1, senza promuovere P0).
- **PR DI DOCUMENTAZIONE:** [#27](https://github.com/Askeladd22/manuscript/pull/27) **integrata in main**.
- **PR DI P0:** [#27](https://github.com/Askeladd22/manuscript/pull/27), [#28](https://github.com/Askeladd22/manuscript/pull/28), [#29](https://github.com/Askeladd22/manuscript/pull/29) e [#30](https://github.com/Askeladd22/manuscript/pull/30) **integrate**; [#31](https://github.com/Askeladd22/manuscript/pull/31) **bozza aperta** per studio P1.
- **UI 2.0 NEL GIOCO:** non esiste ancora; l'HUD attuale resta quello predefinito.
- **CI baseline P0:** [main 41190871754](https://github.com/Askeladd22/manuscript/actions/runs/41190871754) **SUCCESS**; [PR #31 CI 41191467268](https://github.com/Askeladd22/manuscript/actions/runs/41191467268) **SUCCESS** (test candidati P1, Lua5.4/LuaJIT, lab FPS e Python).
- **QA WINDOWS / SCREENSHOT:** **non ancora effettuata** sulla build di questa PR. Lo script ora acquisisce in automatico anche il gruppo fisico dei sei D6 e i flag accessibilità in entrambe le risoluzioni, ma servono esecuzione Windows, confronto visivo e dati FPS.

## Fasi e gate

| Fase | Stato | Cosa serve per segnare DONE |
|---|---|---|
| P0 — Baseline e audit | **IN CORSO** | Inventario interazioni, screenshot correnti, matrice stati, baseline test |
| P1 — Layout/UX | STUDIO PRELIMINARE (gate P0 aperto) | Confronto A/B, screenshot Windows, layout scelto, matrice azioni/hitbox approvata |
| P2 — Fondamenta e slice giocabile | NON INIZIATA | Flag/rollback, UI v2 principale, Farkle ancora giocabile |
| P3 — Presa/scoring/overlay | NON INIZIATA | Mouse singolo/gruppo, punteggi, F8/F9, nessun evento duplicato |
| P4 — Folio/modali/ricompense | NON INIZIATA | Run a 3 commissioni e tutti i percorsi preservati |
| P5 — QA/accessibilità/performance | NON INIZIATA | CI, screenshot Windows, risoluzioni, 50 tiri, nessun bloccante |
| P6 — Cutover/cleanup controllati | NON INIZIATA | UI v2 default, rollback, file legacy ritirati soltanto se non usati |
| P7 — Polish visivo | NON INIZIATA | Fine tuning senza perdere leggibilità o introdurre meccaniche |

## Audit verificato fino a oggi (non equivale al gate P0)

- `src/features/farkle/controller.lua`: `U:draw` invoca `hud_minimal.draw`; `U:drawDeskOverlays` invoca `hud_minimal.overlay`. Mouse e shortcut passano dal controller, che dispone anche dei pulsanti registrati dall'HUD.
- `src/features/farkle/hud_minimal.lua`: disegna fondale, barra punteggio, folio separato sulla destra, shelf, pulsanti principali e secondari; registra `u.buttons`; evidenzia marquee e combinazioni; delega i modali a `hud.lua`.
- `src/features/farkle/hud.lua`: ricompense, menu run, consultazione folio, opzioni di punteggio, regole e medaglie. La migrazione deve essere completa, non solo il pannello del turno.
- `src/features/farkle/hud_model.lua`: fornisce eligibility, testo stato, gruppi/combinazioni e altre funzioni pure da riutilizzare.
- `src/features/farkle/folio_view.lua`: presenta valori assicurati/provvisori e progressione visiva del manoscritto. Non duplicare un secondo contatore fittizio.
- `src/core/resolution_manager.lua`: viewport virtuale 1920×1080 con scala/letterbox; `src/core/runtime_ui.lua` espone UI scale, big text, high contrast, reduced animations.
- `src/app/dice_runtime.lua`: rendering 3D e dispatch LÖVE; `src/features/farkle/tray_view.lua` coordina la proiezione. La UI non può adottare una camera indipendente dalla fisica del mouse.
- `docs/GAME_DESIGN.md`: codice-libro/folio come vera superficie giocabile; sistema Incontri e Segni ancora non implementato e non completamente definito.
- `docs/RENDERER_RETIREMENT.md`: il vecchio painter `src/engine3d/render.lua` è tuttora necessario per percorsi di fallback/esperimenti.

**Non ancora verificato:** screenshot baseline Windows a commit identificato, benchmark FPS, comportamento con testo grande/contrasto alto, manipolazione di gruppo e varianti F8/F9 in un'istanza reale LÖVE. Matrice input/modali verificata nel sorgente e coperta da test headless.

## Prossima azione concreta (una sola)

**Eseguire su Windows lo script P0 aggiornato e verificare screenshot, input e tempi di rendering, prima di scegliere un layout P1.**

1. Verificare `main` e PR aperte e far passare la CI della PR P0.
2. Su Windows eseguire `python scripts/capture_ui_v2_baseline.py` dalla radice del repository (vedi [UI_V2_BASELINE_CAPTURE.md](UI_V2_BASELINE_CAPTURE.md)). Lo script genera screenshot reali a 1920×1080 e 1280×720, inclusi `marquee-six`, `physical-group-held`, `accessibility-on`, `folio` e `upgrade`, più manifest SHA e log.
3. Verificare su Windows che `F` apra il folio riparato nella PR #29, con valori corretti e chiusura Esc; il nuovo test headless verifica già il dispatch ma non la resa GPU.
4. Verificare `big_text`, `high_contrast` e `reduced_animations` e gli FPS della stessa schermata.
5. Annotare i risultati e passare a P1 **solo** quando il gate P0 è completo.

## Inventario P0 aggiunto — 31 ottobre 2026

- [UI_V2_INTERACTION_MATRIX.md](UI_V2_INTERACTION_MATRIX.md): tabella delle fasi Farkle/controller, ID dei pulsanti, modali, scorciatoie e priorità input reali; distinzione fra `dragSelected`, `game.selected` e `medalDice`.
- `tests/ui_v2_interaction_inventory_test.lua`: verifica che le azioni e le scorciatoie del legacy restino raggiungibili; testa le regole di autorizzazione in `fresh/rolling/ready/rescue/ended`, l'indipendenza del marquee e la trasformazione della viewport.
- **Bug confermato e corretto in PR #29:** in `src/features/farkle/hud.lua` il modal `folio` invocava `manuscript(...)` inesistente; ora usa il renderer condiviso `folio_view.draw`. Aggiunto test del modal `tests/ui_v2_folio_modal_regression_test.lua`; resta la verifica Windows.
- Questo passaggio **non implementa ancora la UI 2.0** e non rende P0 completata; il gate manuale resta aperto.

## Intervento P0 — PR #29

- `src/features/farkle/hud.lua`: fix crash modale folio con `FolioView.draw`; conserva target/valori Farkle e allineamento del testo.
- `tests/ui_v2_folio_modal_regression_test.lua`: test modale `folio` su vista virtuale 720p/1080p/ultrawide e controllo dei dialog esistenti.
- `scripts/capture_ui_v2_baseline.py` e [UI_V2_BASELINE_CAPTURE.md](UI_V2_BASELINE_CAPTURE.md): procedura riproducibile per screenshot LÖVE e manifest per commit.
- Nessun redesign ancora effettuato; **P0 rimane IN CORSO**, in attesa di screenshot veri e FPS misurati sul PC Windows.

## Intervento P0 corrente — screenshot della presa dei sei dadi

- `tests/smoke/farkle_hud.lua`: percorso opt-in `MANUSCRIPT_UI_V2_P0_CAPTURE` che usa **il controller originale** per marquee, presa destra di sei dadi, frame con gruppo afferrato ed Esc cancel; registra un frame con le tre impostazioni di accessibilità attivate e ripristinate.
- `scripts/run_smoke.py`: nuovo flag `--ui-v2-baseline` solo per `hud`, senza cambiare i normali smoke di altri sistemi.
- `scripts/capture_ui_v2_baseline.py`: richiede screenshot `fresh-pre-grip`, `marquee-six`, `physical-group-held`, `accessibility-on`, `fresh-after-cancel`, `folio`, `upgrade` a entrambe le risoluzioni, oppure fallisce. Scrive manifest dei frame reali.
- `tests/ui_v2_capture_wiring_test.lua`: test headless della presenza di trigger, gesti reali, nomi e informazioni di tracciabilità.
- [Procedura Windows aggiornata](UI_V2_BASELINE_CAPTURE.md). **La QA grafica non è stata ancora eseguita.**

## Studio anticipato P1 — non equivale ad approvazione

- [UI_V2_LAYOUT_STUDY.md](UI_V2_LAYOUT_STUDY.md): confronto numerico e wireframe di **folio singolo** (tray 1402×666) e **codice aperto** (tray 1136×598); il codice aperto mantiene solo circa il 72,8% della superficie del primo.
- `src/features/farkle/ui_v2/layout_candidates.lua`: geometrie pure e controlli di sovrapposizione, nessuna modifica al renderer 3D, gameplay, fisica, input e scoring.
- `tests/ui_v2_layout_candidates_test.lua`: invarianti e coordinate screen/virtual per cinque risoluzioni (incluso ultrawide).
- `tests/smoke/ui_v2_layout_preview.lua`: wireframe LÖVE opt-in con **F6** per confronto e **F7** per PNG; `scripts/run_ui_v2_layout_study.py` avvia la scena senza cambiare il normale gameplay.
- **Ipotesi tecnica provvisoria:** folio singolo preferibile perché preserva più area ai D6. **Non approvata** senza screenshot veri della baseline P0 e confronto F6.
- **Nessuna promozione di fase:** P0 resta attiva fino a QA Windows; P1 non può essere marcata DONE sulla base di sole misure di rettangoli.

## Rischi e decisioni sospese

- **Layout a una o due pagine:** da confrontare in P1, non considerato approvato.
- **Dadi durante presa multipla:** l'overlay di sei cerchi azzurri oggi oscura parte delle facce; P3 deve rimuovere l'ingombro, senza perdere la comunicazione dello stato.
- **Miniature/Segni:** nessun combattimento nuovo inventato nella UI; lasciare un'estensione futura.
- **FPS grip:** i laboratori fisici sono separati. L'attuale design UI non deve dipendere dal successo di un nuovo solver.
- **Legacy rollback:** mantenere `hud_minimal.lua` e `hud.lua` attivi fino al gate P5 e un periodo di cutover. Il painter `render.lua` ha un ciclo di pensionamento separato.
- **Accessibilità:** esiste già un modulo centrale; non introdurre pulsanti con hitbox non scalate.

## Registro delle sessioni

| Data | Fase | Risultato reale | Link/CI | Prossimo passo |
|---|---|---|---|---|
| 2026-10-31 | P0 | Roadmap e tracker iniziali | [PR #27](https://github.com/Askeladd22/manuscript/pull/27); CI riuscita | Matrice e baseline verificabile |
| 2026-10-31 | P0 | Matrice e test integrazione degli input, PR #28 integrata | [PR #28](https://github.com/Askeladd22/manuscript/pull/28); [main CI 41188977393](https://github.com/Askeladd22/manuscript/actions/runs/41188977393) **successo** | Baseline Windows |
| 2026-10-31 | P0 | Fix folio, test modali e utility screenshot riproducibile; P0 non completata | [PR #29](https://github.com/Askeladd22/manuscript/pull/29); [CI 41189472532](https://github.com/Askeladd22/manuscript/actions/runs/41189472532) **SUCCESS** | Windows: screenshot 720p/1080p, folio, gruppo in mano, accessibilità/FPS |

| 2026-10-31 | P0 | Smoke opt-in di presa multipla e accessibilità, PNG richiesti alle due risoluzioni; gameplay invariato | [PR #30](https://github.com/Askeladd22/manuscript/pull/30); [CI prima versione 41190597513](https://github.com/Askeladd22/manuscript/actions/runs/41190597513) PASS, ultima testa in attesa | Eseguire baseline su LÖVE Windows, confrontare immagini e annotare FPS prima di P1 |\n\n| 2026-10-31 | P0 aperta + studio P1 | Geometrie A/B pure, test di hitbox, wireframe F6/F7; HUD produzione invariato | [PR #31](https://github.com/Askeladd22/manuscript/pull/31) **draft**; [CI 41191467268](https://github.com/Askeladd22/manuscript/actions/runs/41191467268) **SUCCESS** | Cattura P0 Windows, screenshot A/B, valutazione leggibilità dei D6 |\n\n### Mini-template di aggiornamento (duplicare a fine sessione)

```text
DATA:
FASE E STATO:
MAIN SHA:
BRANCH / PR / COMMIT:
FILE MODIFICATI:
COMPORTAMENTO VERIFICATO:
TEST AUTOMATICI E CI (con link):
QA WINDOWS (eseguita / non eseguita):
REGRESSIONI / BLOCCHI:
PROSSIMA AZIONE UNICA:
```

*Regola:* la data/commit riportati qui sono uno **snapshot storico**; prima di agire consultare sempre GitHub per la versione più recente.
