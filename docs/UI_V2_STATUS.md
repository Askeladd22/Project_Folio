# UI 2.0 — Registro operativo / unica fonte di avanzamento

> **Aggiornare questo file dopo ogni sessione che modifica il redesign.**
> Non dedurre «DONE» dal fatto che esiste una PR: servono gate e test.
> Roadmap completa e prompt: [UI_V2_ROADMAP.md](UI_V2_ROADMAP.md).

## Stato corrente — 31 ottobre 2026

- **FASE ATTIVA:** `P0 — baseline e audit completo`.
- **CONDIZIONE:** `IN CORSO` (matrice completa e test automatico di inventario aggiunti; resta QA grafica e manuale della baseline).
- **BASELINE DI DOCUMENTAZIONE:** `main@929e377fafde2b76a0d40681bf3c1e42ff655914`.
- **BRANCH DI DOCUMENTAZIONE:** `docs/ui-v2-execution-plan-20261031`.
- **PR DI DOCUMENTAZIONE:** [#27 — UI 2.0 roadmap e tracker](https://github.com/Askeladd22/manuscript/pull/27) (aperta; attendere verifica CI/review).
- **PR DI P0 (inventario e test):** [#28](https://github.com/Askeladd22/manuscript/pull/28), branch `docs/ui-v2-p0-interaction-baseline-20261031` (stacked su PR #27). Nessuna modifica al gioco né alla UI visuale.
- **UI 2.0 NEL GIOCO:** non esiste ancora; l'HUD attuale resta quello predefinito.
- **CI per la baseline P0:** [run 41188657689](https://github.com/Askeladd22/manuscript/actions/runs/41188657689) **SUCCESS** (Lua 5.4, LuaJIT, laboratori FPS, test Python); il primo run 41188566125 falliva per un'errata aspettativa del test su `ended`, corretta nella PR #28.
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

**Non ancora verificato:** screenshot baseline, benchmark FPS, matrice completa di tutti gli input e di tutti i modali, simulazione con testo grande/contrasto alto, tutte le varianti F8/F9 in Windows.

## Prossima azione concreta (una sola)

**Chiudere la baseline P0 con screenshot e test reali su Windows a commit noto, senza toccare fisica o gameplay.**

1. Verificare `main` e PR aperte e far passare la CI della PR P0.
2. Acquisire almeno 1920×1080 e 1280×720 in `fresh`, `held` multiplo, `ready` con combinazione, `modal` e `upgrade/medal` con HUD attuale. Registrare commit, modalità F9, F10, F11 e impostazioni.
3. Riprodurre il modale `folio` e annotare stack trace se fallisce; controllare Esc e focus.
4. Verificare `big_text`, `high_contrast` e `reduced_animations` e gli FPS della stessa schermata.
5. Annotare i risultati e passare a P1 **solo** quando il gate P0 è completo.

## Inventario P0 aggiunto — 31 ottobre 2026

- [UI_V2_INTERACTION_MATRIX.md](UI_V2_INTERACTION_MATRIX.md): tabella delle fasi Farkle/controller, ID dei pulsanti, modali, scorciatoie e priorità input reali; distinzione fra `dragSelected`, `game.selected` e `medalDice`.
- `tests/ui_v2_interaction_inventory_test.lua`: verifica che le azioni e le scorciatoie del legacy restino raggiungibili; testa le regole di autorizzazione in `fresh/rolling/ready/rescue/ended`, l'indipendenza del marquee e la trasformazione della viewport.
- **Possibile bug esistente:** in `src/features/farkle/hud.lua` il modal `folio` invoca `manuscript(...)` senza una definizione visibile nel modulo. Richiede verifica Windows; non corretto in P0.
- Questo passaggio **non implementa ancora la UI 2.0** e non rende P0 completata; il gate manuale resta aperto.

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
| 2026-10-31 | P0 | Matrice di interazione e test headless introdotti; produzione intatta. Corretto test: `ended` termina il turno, non la commissione | [PR #28](https://github.com/Askeladd22/manuscript/pull/28); [CI 41188657689](https://github.com/Askeladd22/manuscript/actions/runs/41188657689) **successo** | Screenshot Windows, folio modal, accessibilità e FPS baseline |

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
