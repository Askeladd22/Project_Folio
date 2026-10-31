# UI 2.0 — P0 / Inventario degli stati e delle interazioni esistenti

**Verificato sulla baseline:** `main@929e377fafde2b76a0d40681bf3c1e42ff655914`, 31 ottobre 2026.  
**Scopo:** descrivere **ciò che fa il codice oggi**, non aggiungere meccaniche né scegliere prematuramente il layout UI 2.0.  
**Test di inventario:** `tests/ui_v2_interaction_inventory_test.lua`.  
**Tracker:** [UI_V2_STATUS.md](UI_V2_STATUS.md); **piano:** [UI_V2_ROADMAP.md](UI_V2_ROADMAP.md).

## 1. Flusso reale di input e rendering

```text
Windows LÖVE input
 ├─ F9 / F10 / F11 → src/app/dice_runtime.lua (toggle renderer/materiale/bevel)
 └─ game_manager → src/features/farkle/controller.lua
      ├─ mouse: UI modal / ricompensa → pulsanti virtuali
      ├─ mouse: marquee fisico → src/features/farkle/marquee_selection.lua
      ├─ mouse: grab singolo/gruppo → mouse_throw.lua / group_throw.lua
      ├─ mouse: scoring dopo il tiro → R.toggle()
      ├─ keys: priorità di annullamento, modali, azioni contestuali
      └─ draw()
          ├─ hud_minimal.draw(): fondale, testata, folio, pulsanti, stato
          └─ hud_minimal.overlay(): selezioni/presa/shelf
               └─ hud.overlay(): ricompense e modali
                    └─ medal_panel.draw(): laboratorio/uso medaglie
```

**Coordinate:** `resolution_manager` riceve coordinate fisiche del mouse, trasforma hitbox UI in coordinate virtuali 1920×1080; il picking g3d usa `engine_bridge` e la proiezione del tray. La migrazione non deve creare un secondo sistema di coordinate o spostare la camera senza riallineare picking e gesti.

**Nota architetturale:** l'HUD attivo è `hud_minimal.lua`, ma `hud.lua` è **ancora necessario** per dialog/ricompense. `hud_model.lua` è riutilizzabile per derivare i dati; non è una schermata alternativa. Durante P2 la UI nuova dovrà registrare pulsanti e callback equivalenti senza chiamare due volte il controller o le azioni Farkle.

## 2. Matrice fasi Farkle → stato UI visibile

| Fase / sotto-stato | Cosa è cliccabile nella UI attuale | Regole e restrizioni da conservare |
|---|---|---|
| `fresh` | `roll` (Spazio), `help`, `runmenu`, `folio` | Non è ancora stato accettato alcun tiro; disponibilità di `roll` deriva da `R.can_roll` |
| `marquee` (stato transitorio del controller, non fase Farkle) | Trascinamento sinistro nel tray; nessun pulsante addizionale | Seleziona ID **fisici** in `u.dragSelected`, NON `s.selected`; non assegna punti né consuma un tiro ufficiale |
| `held` | Destro premuto su un dado o sul gruppo selezionato; Esc annulla | `u.mouseThrow` per 1+ dadi; ruota/insegue puntatore; i risultati **non** sono ancora conteggiabili |
| `manualRoll` parziale | Restanti dadi possono essere presi e lanciati | `u.manualRoll.pending/count`; un gruppo 2+4 è **un solo tiro Farkle**; non mostrare un secondo pulsante «turno» |
| `rolling` / assestamento | Nessuna selezione per punteggio; azioni disabilitate; alcuni overlay vengono comunque disegnati | `s.phase='rolling'`, `u.state='rolling'`; gli esiti vengono accettati solo da `onDiceSettled` |
| `ready`, nessun dado selezionato | `roll` se `R.can_roll`, `bank` se `R.bank_status`; `choices` se `R.options` non vuoto; `medaluse` quando disponibile | Se prima del tiro non si è accantonata una combinazione, `roll` non è abilitato. Il click sui dadi seleziona per il punteggio |
| `ready`, selezione valida | `take`, `bank` se consentito; `choices` | La selezione si valida con `R.selection`. Spazio attiva `take` se presente; A è scorciatoia per `take` |
| `ready`, selezione non valida | `take` disabilitato, `bank` disabilitato; `choices` | Nessun punto assegnato solo dall'evidenziazione. Stato deve essere comprensibile e reversibile |
| `hot dice` (`s.hot=true` e `ready`) | `roll` per tutti e 6, `bank` quando permesso | Il rischio del turno non viene cancellato automaticamente da «hot dice» |
| `rescue` | `rescue` (medaglia Correttore), `fail` (accetta Farkle) | `rescue` usa `R.rescue`; `fail` usa `R.fail`. Errore fisico e Farkle **non** sono la stessa cosa |
| `physics_error` (stato tecnico) | `retryphysical` | Non assegnare Farkle, non incassare né spendere un secondo turno: recupero tecnico dello stesso tiro |
| `ended` | `next` → turno successivo | Mostrare separatamente punti assicurati ed eventuali punti persi |
| `advance` | `next` → commissione successiva | Il contratto della commissione rimane la fonte di verità |
| `upgrade` | `weighted`, `engraved` | Scelta ricompensa obbligatoria della commissione, registrata da `hud.lua` |
| `medal` | `medal`, `none` | Scelta medaglia o nessuna; non confondere con il laboratorio medaglie opzionale |
| `won` / `lost` | Stato conclusivo | Il codice attuale non presenta un pulsante `next` per entrambe: non inventare avanzamenti o restart automatici |

I modelli della UI devono **derivare** abilità e numeri dalle regole (`R.can_roll`, `R.bank_status`, `R.selection`, `H.eligible`, `H.commission_closed`), non utilizzare una tabella di abilità indipendente e divergente.

## 3. Inventario degli ID dei pulsanti in produzione

| Contesto | ID reali | Inoltro semantico |
|---|---|---|
| Testata | `help`, `runmenu` | Apre i rispettivi dialog |
| Folio laterale | `folio` | Apre il dettaglio del manoscritto |
| Azioni principali | `roll`, `take`, `bank`, `next` | `u:request`, `u:act('take')`, `u:act('bank')`, `u:act('next')` |
| Farkle e recupero | `rescue`, `fail`, `retryphysical` | Rilancio con Correttore, fallimento logico, ritentativo tecnico |
| Consultazione | `choices`, `medaluse` | Pannelli contestuali disponibili solo in fasi appropriate |
| Ricompensa dado | `weighted`, `engraved` | `R.choose_build` e installazione modificatore |
| Ricompensa medaglia | `medal`, `none` | `R.choose_medal` |
| Dialog comune | `close` | Chiusura modale, non della partita |
| Menu run | `restart`, `control`, `medals` | Riavvio build/controllo, accesso laboratorio medaglie |
| Scelte punteggio | `option1` … `option7`, `prev`, `nextpage` | `u:select_option`, paginazione |
| Aiuto | `helpTab1` … `helpTab3` | Cambia sezione del regolamento |
| Laboratorio medaglie | `inspect1` … `inspect6`, `equip`, `medalprev`, `medalnext` | Anteprima e equipaggiamento **con restart della commissione** |
| Utilizzo medaglia | `target1` … `target6`, `activate` | Seleziona bersagli **separati dai dadi Farkle**, applica l'effetto |

Nota: `hud_minimal.draw()` aggiorna `u.buttons` ogni frame; `hud.overlay()` usa anche `u.modalButtons`. La UI 2.0 deve mantenere *una sola* fonte di interazioni attive, senza callback duplicati a ogni frame.

## 4. Mappa tastiera e priorità **effettive**, non auspicate

| Tasto | Azione attuale / priorità |
|---|---|
| Esc | Prima annulla `mouseThrow`, poi marquee, poi `dragSelected`; quindi chiude il modal oppure chiama `love.event.quit()`. **Non è attualmente una voce «torna al menu»** |
| Spazio | Prima `take` (se presente e abilitato), poi `roll`, `next`, `rescue`; non sempre significa lanciare |
| A | `take`, solo se registrato e abilitato |
| Invio / tastierino Invio | `bank` (se disponibile), altrimenti `next` |
| N | `next` (turno o commissione) quando presente |
| M | `rescue`, **non** apre sempre il pannello medaglie |
| 1–6 | `R.toggle` del dado per punteggio; bloccato fuori da `ready` per le regole Farkle |
| ? / / | Apre il dialog aiuto, quando i controlli del controller lo consentono |
| F | Apre il dettaglio folio, quando lo stato lo consente |
| ← / → | Paginazione delle schede aiuto quando `u.modal='help'`; altrimenti nessuna azione principale |
| Tab | Termina l'animazione di presentazione in corso |
| F8 | Ciclo dei layout workshop; nel controller è elaborato anche prima del blocco modal/ricompensa |
| F9 | Toggle renderer g3d/painter a livello `dice_runtime.lua` |
| F10 | Ciclo materiali/diagnostica dei dadi g3d a livello `dice_runtime.lua` |
| F11 | Toggle smussatura visiva dei D6 g3d a livello `dice_runtime.lua` |

**Ordine di dispatch attuale del click sinistro:** se una presa è attiva, nessun click; se è possibile selezionare con marquee e il punto è nel tray, il gesto inizia; successivamente sono filtrati rolling, ricompense, modali e pulsanti UI, poi il picking punteggio sul dado. In `mousereleased` il movimento sotto soglia del marquee viene interpretato come normale click sul dado, ma le regole impediscono di segnare punti prima dell'assestamento.

**Ordine del click destro:** non apre modali; in condizioni di roll manuale può iniziare/continuare una presa individuale o del gruppo selezionato, anche da pergamena vuota quando esiste una selezione multipla valida. Il rilascio genera eventi fisici separati, ma **un solo** `logicalRollId`.

**Punto d'attenzione per P3:** la selezione fisica `dragSelected`, la selezione punteggio `game.selected` e la scelta bersagli medaglia `u.medalDice` sono **tre mappe diverse**; il nuovo overlay dovrà mostrare una priorità visiva diversa per ciascuna.

## 5. Finestre e stati da conservare nella migrazione P4

| `u.modal` / stato | Contenuti e percorsi |
|---|---|
| `help` | 3 schede: gioco, combinazioni, regole speciali |
| `run` | Riavvia con build, run di controllo, laboratorio medaglie |
| `folio` | Dettaglio manoscritto e vincoli commissione |
| `choices` | Opzioni del tiro paginabili a blocchi di 7, selezione fisica degli ID |
| `medals` | Catalogo/laboratorio; **equipaggiare riavvia la commissione** |
| `medaluse` | Uso dell'effetto sul dado o moltiplicatore; bersagli separati |
| `upgrade` | Due modificatori dado dopo commissione |
| `medal` | Scelta Correttore/nessuna medaglia |
| `reward_active` | Oscura la scena e blocca il normale set di azioni |

Le medaglie non tutte disponibili richiedono testo di disabilitazione, conteggio degli usi e ragione del blocco; lo stato `reference_status` appartiene alle regole, non alla grafica.

## 6. Rischi concreti emersi dal codice (da verificare, non occultare)

1. **Bug folio confermato e corretto nella PR #29:** `hud.lua` chiamava `manuscript(s,...)` senza una funzione definita. La correzione usa direttamente `folio_view.draw`, già impiegato nella scena principale, ed è coperta da `tests/ui_v2_folio_modal_regression_test.lua`. Resta la verifica grafica con LÖVE Windows.
2. **Input dipendenti dal disegno:** `can_grab` controlla anche `u.buttons.roll.enabled`, creato durante `hud_minimal.draw`. La UI 2.0 non deve cambiare le regole perché un pulsante non è ancora stato disegnato nel frame iniziale.
3. **Conflitto fra gesture e overlay:** `hud_minimal.overlay` disegna cerchi azzurri per `dragSelected` persino mentre `mouseThrow` è attivo; dagli screenshot risultano invasivi.
4. **Possibili differenze Farkle/hint in modale:** i comandi dei pannelli provengono da `hud.lua` e da `medal_panel.lua`; un refactor parziale della sola `hud_minimal` perderebbe alcune funzioni.
5. **Focus/accessibilità:** `runtime_ui` ha impostazioni di scala/testo/contrasto/animazione; molte posizioni e dimensioni di pulsanti nel legacy sono numeri fissi. La geometria dei nuovi pulsanti deve rispondere alla scala senza differenze click/draw.
6. **Terminali:** `won`/`lost` non mostrano l'azione di uscita nella banda corrente; eventuale nuovo percorso va definito in P1, non considerato già disponibile.
7. **Debug renderer:** F8-F11 sono parte della QA e non devono essere rimossi con il nuovo HUD.

## 7. Criteri di baseline prima di P1

- [x] Verificare i sorgenti di controller, HUD, regole, modali, medaglie, marquee e dispatch LÖVE.
- [x] Elencare fasi, input, pulsanti, modali e separazione delle selezioni.
- [ ] Acquisire screenshot **reali e con versione identificata** almeno a 1920×1080 e 1280×720: `fresh`, `held` con gruppo, `ready` con selezione, `upgrade/medal` e `modal`.
- [ ] Testare manualmente il modale folio e i percorsi Esc/focus.
- [ ] Registrare il baseline FPS e l'impatto di big text, high contrast e reduced animations sul client Windows.
- [ ] Far passare CI del nuovo `tests/ui_v2_interaction_inventory_test.lua` più suite esistente.

Questo è un inventario **di ciò che deve restare accessibile**. P1 potrà cambiare la disposizione dei controlli, non il loro risultato senza una decisione esplicita sul gameplay.
