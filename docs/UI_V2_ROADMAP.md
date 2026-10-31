# MANUSCRIPT / SCRIPTORIUM — UI 2.0
## Roadmap esecutiva e contratto operativo per ChatGPT

**Stato:** P0 — audit da completare; nessun redesign implementato da questa roadmap.  
**Baseline:** `main` al commit `929e377fafde2b76a0d40681bf3c1e42ff655914` (31/10/2026).  
**Tracker obbligatorio:** [UI_V2_STATUS.md](UI_V2_STATUS.md).  
**Documento di design vincolante:** [GAME_DESIGN.md](GAME_DESIGN.md).  
**Regole e rischi:** [FARKLE_RULES.md](FARKLE_RULES.md), [RENDERER_RETIREMENT.md](RENDERER_RETIREMENT.md).

> **Missione.** Sostituire gradualmente la vecchia interfaccia Farkle con una UI leggibile, coerente con il **libro-folio giocabile**, i dadi 3D g3d e la manipolazione fisica in stile tabletop. Non è un restyling indiscriminato: riprogettiamo gerarchia, flussi, stati, layout e input mantenendo un loop Farkle completo e affidabile.

### Regole che NON possono essere violate

1. **Farkle rimane il gameplay autoritativo.** Non cambiare punteggi, RNG, riconoscimento delle facce, turni, combinazioni, hot dice, banca/incasso, Farkle, ricompense, logica delle commissioni e salvataggi solo per accomodare una UI.
2. **g3d resta il renderer 3D di riferimento.** UI e tooltip possono continuare a essere **2D** in LÖVE: non confondere «eliminare un HUD legacy» con «rendere tutto 3D». La fisica corrente `src/engine3d/physics.lua` non si sostituisce con FPS durante questo redesign. FPS Labs 1–5 restano sperimentali.
3. **Il renderer painter `src/engine3d/render.lua` non si elimina per analogia col vecchio HUD.** È ancora usato per recovery/F9, F8 e alcune presentazioni. Leggere l'audit in `RENDERER_RETIREMENT.md` prima di qualunque rimozione.
4. **Il 3D è il protagonista.** Durante lanci, prese, scuotimenti e selezioni non coprire il folio con testo o elementi decorativi. Gli stati interattivi hanno la precedenza sulle animazioni.
5. **L'interfaccia distingue due concetti diversi:** selezione *fisica* di dadi per una presa multipla (marquee) e selezione *logica* delle combinazioni da accantonare/incassare (solo dopo il tiro valido). Non mescolarli.
6. **Non anticipare feature di game design non ancora implementate.** Incontri con miniature e «Segni» sono una direzione approvata da esplorare, **non** un combattimento già specificato; nessun HP/danno/negozio inventato nel nuovo HUD. Predisporre spazi/composizione, non pulsanti fasulli.
7. **Accessibilità e prestazioni sono requisiti:** UI scale, testo grande, contrasto elevato, animazioni ridotte, tastiera e layout non deformati.
8. **Niente cancellazioni premature** di `hud_minimal.lua`, `hud.lua`, file `resources/ui/`, menu e vecchio renderer. Valutare i chiamanti reali, mantenere rollback per almeno una fase di QA.
9. **Modifiche in PR piccole e verificabili**, mai direttamente in `main` senza un'esplicita richiesta. Ogni PR deve indicare esattamente cosa sostituisce, cosa conserva, test automatici eseguiti, QA Windows ancora necessaria.
10. **Ogni fase aggiorna `UI_V2_STATUS.md` prima di dichiararsi completata.** I dati verificati (PR/commit, test, screenshot) sostituiscono le impressioni.

---

## A. Architettura attuale verificata (punto di partenza)

| Responsabilità | Moduli attuali | Trattamento previsto |
|---|---|---|
| HUD attivo della partita | `src/features/farkle/hud_minimal.lua` | Migrare **per componenti**; oggi gestisce fondo, header, folio laterale, azioni, evidenziazioni, shelf e richiama i modali |
| Stato/semantica presentazione | `hud_model.lua`, `presentation.lua` | Riutilizzare e separare **stato derivato** dalla geometria dei pulsanti |
| Modali, regole, scelta ricompense | `hud.lua`, `medal_panel.lua` | Portare a dialog comuni senza perdere nessun flusso |
| Folio e progressione visiva | `folio_view.lua`, `presentation_view.lua` | Mantenere il progresso autentico, ridisegnare il posizionamento; non renderlo soltanto una barra da riempire nel game design futuro |
| Tiro/presa/marquee/scoring | `controller.lua`, `mouse_throw.lua`, `group_throw.lua`, `marquee_selection.lua`, `shake_detector.lua` | **Non** riscrivere la fisica. Stabilire una priorità input coerente e hitbox affidabili |
| Rendering/camera/tray | `src/app/dice_runtime.lua`, `tray_view.lua`, `src/core/engine_bridge.lua` | Coordinate di proiezione uniche per g3d, HUD overlay, picking e controllo mouse |
| Risoluzioni e accessibilità | `resolution_manager.lua`, `runtime_ui.lua`, settings correnti | Rispettare viewport virtuale 1920×1080, letterboxing, `big_text`, `high_contrast`, `reduced_animations`, scala UI |
| Test | `tests/farkle_hud_test.lua`, `tests/marquee_group_throw_test.lua`, `tests/frontend_flow_test.lua`, `tests/g3d_clean_tray_test.lua`, `tests/folio_test.lua`, CI | Proteggere gli invarianti e aggiungere test per UI 2.0; QA grafica in Windows LÖVE resta indispensabile |

**Problema tecnico principale:** il vecchio `hud_minimal.lua` mescola calcoli del layout, rendering LÖVE, creazione di `u.buttons`/callback e dipendenze da presentazione. Il redesign deve separare **cosa mostrare**, **dove mostrarlo**, **come disegnarlo**, **quale comando inviare**.

---

## B. Contratto UX e nuova gerarchia

**Tavolo centrale / libro:** libro-folio fisicamente giocabile, ampio e non coperto dall'HUD. Sopra il piano i sei D6 3D, ombre e possibilità di presa fisica. La parte superiore del libro custodisce segni/dadi accantonati leggibili; niente decorazioni che nascondano le facce.

**Testata molto leggera:** commissione / obiettivo / assicurati / a rischio / turni. Un solo livello gerarchico, numeri prima dei dettagli. Regole e menu come comandi secondari.

**Banda contestuale inferiore:** al massimo 1–2 azioni principali realmente disponibili per lo stato corrente (lancia, accantona, incassa, prosegui, errore fisico). Un messaggio di stato breve e contestuale, niente istruzioni permanenti a due righe durante ogni tiro.

**Area laterale o seconda facciata:** riservata alla progressione del manoscritto e, solo quando esisteranno, agli incontri. Per il prototipo confrontare **due layout** (folio singolo giocabile con pannello a lato vs libro aperto a due pagine); NON decidere che il vecchio rettangolo a destra sia la forma finale del codice.

**Overlay sui dadi:** indicazione minima e distinguibile di *selezionabile per punteggio*, *selezionato per punteggio*, *selezionato fisicamente*, *in mano*, *accantonato*. Durante una presa multipla attenuare/nascondere i sei cerchi ciano che oggi si sovrappongono alle facce; mantenere solo un segnale di gruppo/puntatore leggibile. Nessun overlay impatta `body` o esito dei dadi.

**Modali:** regole, combinazioni, folio, medaglie, ricompense, menu run e messaggi di errore condividono lo stesso sistema di focus/chiusura; non si aprono mentre i dadi sono in movimento o tenuti salvo percorsi esplicitamente consentiti.

### Stati che la UI deve distinguere esplicitamente

- `fresh / ready-to-throw`: lancia tutti o inizia presa fisica.
- `marquee`: selezione geometrica prima della presa, **non** punti.
- `held`: uno/più dadi in mano, nessun punteggio; Esc annulla la presa.
- `partially released`: alcuni dadi ancora da lanciare nello stesso tiro ufficiale.
- `rolling / settling`: risultati non ancora accettati, nessuna selezione di punteggio.
- `ready / scoring`: selezione di una combinazione valida, tasto A, Incassa se autorizzato.
- `hot dice`: rilancio di sei, punti provvisori ancora a rischio.
- `bust / rescue / physical error`: feedback non ambiguo, retry tecnico distinto da rilancio Farkle.
- `ended / advance / won / lost`: prossima azione evidente.
- `upgrade / medal / modal`: scelta con focus, senza perdere lo stato della partita.

**Priorità input di riferimento:** modale/ricompensa → presa in corso/Esc cancel → marquee sul piano → picking 3D → pulsanti HUD → shortcut contestuali. Va verificata contro la dispatch reale del controller, non dedotta a priori.

---

## C. Fasi eseguibili (una PR per fase quando appropriato)

### P0 — Baseline e audit completo
**Obiettivo:** inventario documentato, screenshot confrontabili, matrice di input e stati.

- [ ] Controllare `main` e PR aperte; registrare commit reale in STATUS.
- [ ] Mappare `controller.draw()` / `drawDeskOverlays()` → HUD → modali → registrazione `u.buttons` → mouse/tastiera.
- [ ] Elencare tutte le azioni attuali e i casi speciali: scelta, validazione, hot dice, rescue, medaglie, folio, menu.
- [ ] Fotografare **1920×1080 e 1280×720**, normale, selezione multipla, presa, dopo tiro, ricompensa.
- [ ] Inventariare hitbox/proiezione, F8/F9, impostazioni accessibilità e asset UI effettivamente usati.
- [ ] Definire baseline test con tutti i `tests/*_test.lua`, smoke e screenshot.
**Gate:** nessuna funzione dimenticata; elenco regressioni e baseline pronta. Non rifattorizzare ancora.

### P1 — Layout e UX specification
**Obiettivo:** nuovo wireframe e contratti di spazio/interazione, prima della grafica ricca.

- [ ] Confrontare **layout a una pagina** e **a due pagine**; scegliere in base a spazio di lancio, leggibilità delle facce e tema del libro, senza duplicare meccaniche.
- [ ] Definire griglia virtuale responsive: testata, centro 3D, shelf, folio, azioni, messaggi.
- [ ] Scrivere matrice `fase di gioco → azione primaria/secondaria → scorciatoia → stato disabled`.
- [ ] Definire comportamento overlay durante marquee, presa singola/multipla, tiro e punteggio.
- [ ] Fissare criteri misurabili: testo non tagliato, pulsanti visibili, niente elementi dentro i punti di collisione/lettura.
**Gate:** wireframe e matrice approvati; non serve ancora arte definitiva.

### P2 — Fondamenta UI 2.0 affiancate (vertical slice)
**Obiettivo:** renderizzare la schermata principale nuova **senza rompere quella vecchia**.

- [ ] Creare moduli dedicati, indicativamente `src/features/farkle/ui_v2/{layout,theme,view_model,widgets,hud,overlay}.lua` (nomi adattabili, responsabilità da mantenere).
- [ ] Introdurre scelta **developer opt-in** della UI v2; il legacy rimane default e ripristinabile.
- [ ] Separare view model puro (senza `love.graphics` né mutazioni Farkle), layout/hitbox, draw, dispatch azioni.
- [ ] Riutilizzare `resolution_manager` e `runtime_ui`, compresi high contrast, testo grande e reduced animations.
- [ ] Portare testata, libro/tray e banda azioni `fresh → roll → ready → bank` come prima slice.
- [ ] Evitare doppi handler, doppi pulsanti e doppia chiamata logica al tiro.
**Gate:** una commissione giocabile con flag v2 e senza modifiche a fisica/scoring; test CI verdi e rollback efficace.

### P3 — Interazione tabletop, overlays e stati critici
**Obiettivo:** la UI aiuta presa e scoring senza sovrapporre feedback diversi.

- [ ] Portare marquee, selezione fisica, indicatore di gruppo e cancel; rimuovere i cerchi di selezione invasivi **solo nel nuovo overlay**, quando un gruppo è in mano.
- [ ] Portare i messaggi `held`, lancio in più riprese, assestamento, fallimento fisico.
- [ ] Portare scoring, preview punti, selezione valida/non valida, accantonamento e hot dice.
- [ ] Provare F8, F9, F10, F11; nessun disallineamento con camera/picking g3d.
- [ ] Verificare che UI v2 non interpreti il mouse per conto proprio prima del controller.
**Gate:** un tiro completo singolo e multi-dado, con punteggi identici e input senza ambiguità.

### P4 — Folio, progressione, modali e ricompense
**Obiettivo:** migrare tutte le schermate secondarie, non soltanto il layout principale.

- [ ] Visualizzazione del folio coerente con il libro giocabile (non due sistemi di avanzamento concorrenti).
- [ ] Regole, combinazioni, menu run, scelta upgrade e medaglia, Correttore, conferme, errori.
- [ ] Gestire focus e gerarchia `modal > game > tray`; Esc chiude correttamente, salvo presa attiva.
- [ ] Preparare un **slot narrativo neutro** per future miniature/Segni, ma nessun HP o pulsante di combattimento fittizio.
- [ ] Accantonamento: preservare ID e traccia leggibile dei dadi già usati.
**Gate:** mini-run attuale completa, incluse le ricompense tra commissioni, via UI 2.0.

### P5 — Accessibilità, prestazioni e QA
**Obiettivo:** verificare sistematicamente, non per impressione.

- [ ] Test a **1280×720, 1920×1080, 2560×1440** e rapporto ultrawide, con letterbox/hitbox corretti.
- [ ] Test `big_text`, `high_contrast`, `reduced_animations`, scala UI, mouse e tastiera.
- [ ] Ripetere gli stati: fresh, held, rolling, scoring, hot, bust, rescue, bank, upgrade, medal, advance, modal.
- [ ] Validare una run completa e almeno **50 lanci** tra singoli e gruppi, senza turni/punti fantasma.
- [ ] Misurare FPS/frame time sugli stessi scenari della UI legacy e evitare regressioni sproporzionate.
- [ ] Automatizzare view-model, hitbox, focus, enablement e regressioni Farkle in `tests/`; gli screenshot reali non sono sostituibili dal CI headless.
**Gate:** prove allegate, regressioni bloccanti risolte, nessuna funzione legacy mancante.

### P6 — Cutover controllato e pulizia
**Obiettivo:** promuovere la nuova UI come default **solo dopo P5**.

- [ ] Spostare il default a UI 2.0 mantenendo un rollback temporaneo.
- [ ] Cercare i caller di `hud_minimal.lua`, `hud.lua` e asset obsoleti; eliminare **solo** ciò che è dimostrabilmente inutilizzato.
- [ ] Tenere separata la decisione di ritiro del renderer painter (`RENDERER_RETIREMENT.md`).
- [ ] Aggiornare README IT/EN, controlli, screenshot, documentazione dei layout.
- [ ] In una PR successiva rimuovere il rollback soltanto dopo ulteriori test reali.
**Gate:** nessuna dipendenza nascosta, avvio Splash → Menu → Commissione → Run → Fine invariato.

### P7 — Finitura artistica (non blocca P2–P5)
**Obiettivo:** qualità visiva, non nuove meccaniche.

- [ ] Pergamena, cartigli, cornici leggere, tipografia coerente XV sec., micro-animazioni e audio tattile.
- [ ] Contrasto e leggibilità prima di decorazione e texture.
- [ ] Riduzione animazioni rispettata e nessuna perdita di FPS o di visibilità dei D6.
- [ ] Se futuro design incontri cambia, evolvere solo i componenti interessati, non riscrivere l'intera UI.

---

## D. Protocollo anti-perdita del contesto (OBBLIGATORIO)

**All'inizio di ogni nuova sessione o dopo un messaggio «continua»:**

1. Aprire su GitHub `docs/UI_V2_ROADMAP.md` e **poi** `docs/UI_V2_STATUS.md` nella versione più recente; consultare `docs/GAME_DESIGN.md` e `docs/RENDERER_RETIREMENT.md` quando rilevanti.
2. Verificare SHA di `main`, branch/PR aperte, CI recente e file realmente modificati; non riutilizzare un branch già eliminato o sostituito.
3. Leggere l'**unica fase ATTIVA** nel tracker, verificare i gate precedenti e individuare il **prossimo passo piccolo** non spuntato.
4. Implementare quel passo direttamente nel repo in una PR isolata; non mescolare refactor UI con fisica FPS, nuovi sistemi di combattimento e renderer 3D.
5. Eseguire/verificare test di sintassi, Lua 5.4 + LuaJIT e QA pertinente. Non scrivere «test passati» se CI è ancora in coda; non inventare screenshot.
6. Prima di fermarsi, aggiornare `UI_V2_STATUS.md` con: fase, completato, PR e commit, test effettivi, rischi, prossimo passo preciso. Se una funzione cambia, aggiornare roadmap e test.
7. In risposta all'utente riportare progressi reali e link della PR, non solo cosa si vorrebbe fare. **Nessuna fase è DONE senza gate documentato.**

**Formato checkpoint per ogni sessione:**

```text
FASE: Pn
BASELINE MAIN: <SHA verificato>
BRANCH / PR: <link, commit>
FATTO: <file, feature e comportamento osservabile>
TEST: <comando / run CI / risultato, oppure NON VERIFICATO>
DA VERIFICARE SU WINDOWS: <prove manuali precise>
RISCHI: <bug noti o dipendenze>
PROSSIMA AZIONE: <un unico passo tecnico concreto>
```

### Prompt di ripresa (da copiare in una futura chat)

> Stiamo sviluppando **Manuscript / Scriptorium** nel repository `https://github.com/Askeladd22/manuscript`. Riprendi il **redesign funzionale UI 2.0**. Prima leggi `docs/UI_V2_ROADMAP.md`, `docs/UI_V2_STATUS.md`, `docs/GAME_DESIGN.md` e verifica stato reale di main/PR/CI. Individua la fase attiva e realizza il prossimo passo **in codice**, in una PR piccola, senza modificare gameplay Farkle o fisica. g3d resta renderer dei dadi; il vecchio painter rimane finché indispensabile. Mantieni vecchio HUD come rollback fino a QA completa. Rispetta il libro-folio come superficie giocabile, la distinzione fra selezione fisica e scoring, l'accessibilità e i modali. Esegui i test disponibili, segnala la QA Windows che manca e **aggiorna il tracker** con commit, test, rischi e prossimo passo. Non dichiarare completate fasi senza gate verificati.

---

## E. Definizione di completamento dell'intero progetto UI 2.0

UI 2.0 è «completata» soltanto quando:
- una **run Farkle corrente intera** si può giocare senza il vecchio HUD;
- tutte le azioni esistenti, stati, combinazioni, fallback e ricompense sono ancora disponibili;
- i dadi g3d sono il centro visivo, il folio è integrato nel linguaggio del libro e non c'è sovrapposizione fra overlay di presa/scoring;
- keyboard, mouse, varie risoluzioni e accessibilità sono stati effettivamente verificati;
- suite automatica **e** QA grafica Windows sono documentate;
- il vecchio HUD può essere ritirato senza lasciare dipendenze o togliere la possibilità di recupero da errori del renderer.

**Una roadmap non è una PR di implementazione.** La prima PR di codice sarà P0/P1 oppure la slice P2 dopo i rispettivi gate.
