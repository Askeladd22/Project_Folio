# UI 2.0 — Registro operativo / unica fonte di avanzamento

> **Aggiornare questo file dopo ogni sessione che modifica il redesign.**
> Non dedurre «DONE» dal fatto che esiste una PR: servono gate e test.
> Roadmap completa e prompt: [UI_V2_ROADMAP.md](UI_V2_ROADMAP.md).

## Stato corrente — 31 ottobre 2026

- **FASE ATTIVA:** `P0 — baseline e audit completo`.
- **CONDIZIONE:** `IN CORSO` (matrice completa e test automatico di inventario aggiunti; resta QA grafica e manuale della baseline).
- **BASELINE DI DOCUMENTAZIONE:** `main@c3c0fc6e88bb3ed6c3e188f8457a04708d53af92` (verificato prima di PR #29).
- **BRANCH DI DOCUMENTAZIONE:** `fix/ui-v2-p0-folio-baseline-20261031` (intervento P0 corrente).
- **PR DI DOCUMENTAZIONE:** [#27](https://github.com/Askeladd22/manuscript/pull/27) **integrata in main**.
- **PR DI P0:** [#28](https://github.com/Askeladd22/manuscript/pull/28) **integrata** (matrice/test) e [#29](https://github.com/Askeladd22/manuscript/pull/29) **aperta** (correzione folio + cattura baseline riproducibile).
- **UI 2.0 NEL GIOCO:** non esiste ancora; l'HUD attuale resta quello predefinito.
- **CI per la baseline P0:** [main 41188977393](https://github.com/Askeladd22/manuscript/actions/runs/41188977393) **SUCCESS**; [PR #29 run 41189472532](https://github.com/Askeladd22/manuscript/actions/runs/41189472532) **SUCCESS** (nuovo test modali, Lua 5.4/LuaJIT, lab FPS e regressioni).
- **QA WINDOWS / SCREENSHOT:** non ancora completata per una baseline identificata con commit; servono 1920×1080 e 1280×720 (fresh, held gruppo, ready con combinazione, modale, ricompensa).

## Fasi e gate

| Fase | Stato | Cosa serve per segnare DONE |
|---|---|---|
| P0 — Baseline e audit | **IN CORSO** | Inventario interazioni, screenshot correnti, matrice stati, baseline test |
| P1 — Layout/UX | NON INIZIATA | Confronto 1 vs 2 pagine, layout scelto, matrice azioni/hitbox |
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

**Chiudere la baseline P0 con screenshot e test reali su Windows a commit noto, senza toccare fisica o gameplay.**

1. Verificare `main` e PR aperte e far passare la CI della PR P0.
2. Su Windows eseguire `python scripts/capture_ui_v2_baseline.py` dalla radice del repository (vedi [UI_V2_BASELINE_CAPTURE.md](UI_V2_BASELINE_CAPTURE.md)); genera screenshot reali a 1920×1080 e 1280×720, manifest SHA e log. Il gruppo in mano richiede ancora una cattura manuale.
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
- Nessun redesign ancora effettuato; **P0 rimane IN CORSO**, in attesa di immagini e FPS realmente misurati sul PC Windows.

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

### Mini-template di aggiornamento (duplicare a fine sessione)

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
