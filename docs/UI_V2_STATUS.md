# UI 2.0 — Registro operativo / unica fonte di avanzamento

> **Aggiornare questo file dopo ogni sessione che modifica il redesign.**
> Non dedurre «DONE» dal fatto che esiste una PR: servono gate e test.
> Roadmap completa e prompt: [UI_V2_ROADMAP.md](UI_V2_ROADMAP.md).

## Stato corrente — 31 ottobre 2026

- **FASE ATTIVA:** `P0 — baseline e audit completo`.
- **CONDIZIONE:** `IN CORSO` (mappatura iniziale verificata, test e screenshot di baseline ancora da fare).
- **BASELINE DI DOCUMENTAZIONE:** `main@929e377fafde2b76a0d40681bf3c1e42ff655914`.
- **BRANCH DI DOCUMENTAZIONE:** `docs/ui-v2-execution-plan-20261031`.
- **PR DI DOCUMENTAZIONE:** da registrare dopo la creazione.
- **PR DI IMPLEMENTAZIONE UI 2.0:** nessuna.
- **UI 2.0 NEL GIOCO:** non esiste ancora; l'HUD attuale resta quello predefinito.
- **CI per questa modifica:** da verificare; non esistono test UI 2.0 nuovi in questa fase documentale.
- **QA WINDOWS / SCREENSHOT:** non ancora eseguita per il redesign.

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

**Completare P0 con un inventario eseguibile delle interazioni e una matrice `stato → pulsanti/shortcut`, senza toccare ancora fisica o grafica di produzione.**

Ordine consigliato nella prossima sessione:
1. Verificare SHA/PR e leggere roadmap + questo tracker.
2. Estrarre da `controller.lua`, `hud_minimal.lua`, `hud.lua`, `medal_panel.lua` i callback e i comandi abilitati in ciascuna fase.
3. Aggiungere `docs/UI_V2_INTERACTION_MATRIX.md` e un test puro per garantire che la futura view-model non dimentichi stati e azioni.
4. Eseguire sintassi e CI; registrare l'esito qui.
5. Chiedere soltanto gli screenshot Windows indispensabili per il gate grafico P0, senza confondere CI e verifica visiva.

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
| 2026-10-31 | P0 | Verificato lo scheletro del runtime e creati roadmap + tracker; **nessuna modifica al gioco** | PR documentale da registrare | Matrice interazioni; screenshot baseline |

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
