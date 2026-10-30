# Architettura e contratti tecnici

Stato: 15 ottobre 2026. Lua/LuaJIT e LÖVE2D 11.x, rendering e simulazione 3D personalizzati. Il motore è **congelato per sviluppare il gameplay**, non certificato come simulazione perfetta.

## Percorso di esecuzione

`love .` → `conf.lua` e `main.lua` → controller Farkle iniettato in `src/app/dice_runtime.lua` → registrazione frontend → `startup_splash` → `main_menu` → `campaign_select` → schermata `scriptorium` associata al controller Farkle.

L'ID storico `scriptorium` non significa che venga caricato il vecchio gameplay cromatico. Gli ID delle schermate e l'identità dei salvataggi restano invariati. Il runtime registra dinamicamente `src.features.<nome>.module` per le schermate originali; il gameplay viene iniettato, non recuperato da copie assemblate.

| Percorso | Responsabilità |
|---|---|
| `src/gameplay/farkle/scoring.lua` | Tabella e partizione di gruppi disgiunti, opzioni per ID, nessun accesso a LÖVE/RNG |
| `src/gameplay/farkle/rules.lua` | Stato turno/run, soglie, commissioni, medaglia, selezione/incasso |
| `src/features/farkle/controller.lua` | Input, log, richieste fisiche, accettazione dei risultati, sincronizzazione HUD |
| `src/features/farkle/dice.lua` | Mappe per dado, filtro pesato, modello ideale di rischio, collegamento texture |
| `src/features/farkle/hud_model.lua`, `hud.lua` | Presentazione dello stato e disegno, consultazione delle selezioni e regole |
| `src/features/farkle/tray_view.lua` | Inquadratura esistente adattata al rettangolo HUD |
| `src/app/dice_runtime.lua` | Integrazione originaria: bootstrap, lancio, lettura facce, contenimento, rendering e callback |
| `src/engine3d/` | Geometria, proiezione, luce, collisioni e aggiornamento fisico |
| `src/core/`, `src/data/` | Navigazione, risoluzione, impostazioni, schemi e servizi condivisi |
| `tests/`, `tests/smoke/`, `scripts/` | Test Lua, diagnostica LÖVE e strumenti di sviluppo correnti |
| `resources/`, `lib/` | Risorse attive e librerie esistenti |

Nessun modulo di produzione dipende da `experiments/` o `legacy/`. Non ci sono alias nei percorsi vecchi. `main.lua` carica i moduli `tests.smoke.*` soltanto se richiesto dalle variabili diagnostiche; nessun audit viene caricato durante il gioco normale. Le API del controller e del bridge sono conservate, senza nuovo sistema di eventi o ECS.

## Confini fisici da preservare

`main.lua` esclude temporaneamente da `box` i corpi accantonati durante ogni update e poi ripristina la lista. Il controller conserva gli esiti degli altri dadi durante rilanci parziali, recuperi tecnici e proposte rifiutate del dado pesato. Non rimuovere questo adattamento come «duplicazione».

Calendario D2: passo fisso con accumulatore, vincoli nello stesso passo; `update(0)` non deve spostare i corpi. Recupero del backlog limitato per evitare spirali. Test in `physics_time_test.lua`, anche 20/30/60/144 Hz. Non è garantita identità deterministica fra piattaforme.

Spawn consolidato in `rollAllDice` e `spawn_clearance.lua`: quattro regioni originarie, dimensioni e dinamica mantenute; SAT usato **solo prima del primo passo**, margine 0,01. Ricerca limitata a 32 tentativi sul lato originale, 96 sui quattro lati, poi 64 punti per lato. Esaurimento: rollback atomico e recupero tecnico, non cicli infiniti. I corpi accantonati sono esclusi dalla ricerca. Quando il fallback cambia lato, si inverte soltanto la componente orizzontale uscente: modulo della velocità conservato. Non sostituire il solver attivo con SAT.

Validazione A/B: arresto meccanico distinto da faccia superiore geometricamente valida; accettazione esplicita. Pose ambigue richiedono rilancio fisico, non numero casuale assegnato. Al massimo due recuperi automatici; dopo tre tentativi irrisolti si attende retry manuale/menu senza consumare il turno né assegnare punti. Il filtro pesato ha invece una propria sequenza di accettazione/rifiuto: non confondere i due meccanismi.

## Rendering, facce e asset

`face_texture.lua` usa due triangoli ancorati ai quattro vertici proiettati; non ripristinare il vecchio mapping affine a tre vertici. Mappa geometrica base `{1,6,3,5,4,2}`; `faceValueMap` e `pipMap` individuali, percorso `resources/dice/<valore>.png`. Il dado inciso usa la stessa mappa per lettura e texture. Le sei texture argentate restano provvisorie, con i loro bordi incorporati; nessuna riscalatura o ritocco nella promozione strutturale.

La presentazione Farkle usa una camera ortografica con pitch 0,48 radianti, yaw e distanza della configurazione esistente. `tray_view.lua` adatta al rettangolo HUD un volume fisso: estensioni del vassoio +0,85 lateralmente, quota 0–9; il margine UI è 18 px virtuali. Non include i dadi nel calcolo del fit, ma continua a raccoglierne i vertici per i controlli di clipping. La precedente scala dinamica dipendente dai dadi in volo causava l'apparente scomparsa/ricomparsa del vassoio. Questa modifica di camera/proiezione è stata autorizzata esplicitamente; non cambia il volume fisico.

`view.to_camera` restituisce una direzione parallela per il culling ortografico; il renderer include tipo di proiezione e focus nella chiave della cache. Mapping triangolato, geometria, materiali e ordinamento restano invariati. Pitch/proiezione vengono ripristinati dopo il disegno del vassoio. Il picking usa gli stessi punti proiettati del disegno; gli indicatori 1–6 permettono selezione anche in caso di occlusione. Vassoio HUD virtuale `(40,226,1370,565)` su canvas 1920×1080: coordinate di presentazione, non dimensioni fisiche.

## Ripiano e conclusione del turno

`presentation.lua` osserva lo stato Farkle senza modificarlo: conserva snapshot di ID, valore, turno, commissione e progressivo del lancio accettato. Un recupero tecnico o una proposta pesata rifiutata non crea un nuovo lancio accettato. Nei rilanci selettivi delle medaglie solo gli ID effettivamente rilanciati cambiano provenienza. `presentation_view.lua` disegna il ripiano da sei posti e la faccia numerica usando le texture correnti, con trasferimento di 0,24 s. Le selezioni modificabili non sono accantonamenti.

Il runtime filtra disegno, ombra e hit dei soli dadi `game.used`; non usa `kept`, che comprende anche dadi temporaneamente esclusi da rilanci di medaglie. Nessuna posizione del corpo viene modificata per creare il ripiano. Hot dice e cambio turno/commissione liberano le rappresentazioni; i recuperi mantengono gli accantonamenti esistenti.

Incasso/Farkle producono un riepilogo persistente e un impulso grafico di 0,45 s, con suoni UI esistenti `confirm`/`back`; l'accantonamento usa `toggle`. La pergamena continua a rappresentare il punteggio mediante il percorso precedente. Non sono introdotte attese: il comando successivo interrompe il feedback. L'opzione `reduced_animations` completa immediatamente le animazioni, senza sopprimere il riepilogo. Volume e disattivazione audio restano gestiti dal servizio esistente.

Checkpoint precedente: `audits/turn-feel/before.zip`, manifest SHA-256 e hash dell'archivio nella stessa directory. Per rollback estrarre in una cartella separata e avviarla con `love .`; per ripristino in sede confrontare il manifest e ripristinare esclusivamente i file modificati, rimuovendo i nuovi moduli di presentazione/test solo dopo backup. Non sovrascrivere audit o lavoro successivo. Nessun pacchetto `.love` è stato generato.

Verifica del 15 ottobre 2026: baseline 24 suite Lua; dopo l'intervento 26 suite Lua e 4 test Python. Smoke completi `partial`, `face-gate`, `integration`, `hud`, `frontend` in `audits/turn-feel/after-verified/`: rilanci normali/incisi/pesati, hot dice, recuperi tecnici, medaglie selettive, soglie, fine turno/commissione, navigazione e salvataggio impostazioni. HUD a 1280×720 e 1920×1080, ripiano 1–6 e picking degli altri dadi. Gli stati rari del test HUD usano fixture logiche: le loro texture 3D non sono una misura della corrispondenza fisica; quest'ultima è verificata separatamente dagli smoke con lanci reali.

Il primo smoke HUD si è fermato su un presupposto errato del test: tre coppie possono essere l'unica scelta valida e non permettere accantonamento parziale. Il test ora cerca un'altra fixture tramite un nuovo lancio fisico, entro 12 tentativi; non forza valori né modifica seed. La suite completa successiva è passata.

Video silenziosi e fotogrammi: `audits/turn-feel/before-video/` e `after-video/`, acquisiti da LÖVE e codificati con i timestamp reali. Prima: 146 campioni in 22,02 s, acquisizione interrotta al limite durante il secondo tiro. Dopo: 161 campioni in 29,66 s, sequenza conclusa. La cattura PNG è onerosa (circa 5–7 campioni/s): conserva i tempi reali, ma non certifica fluidità o prestazioni del gioco senza registrazione. Non è un confronto delle traiettorie a parità di dt.

Nel video a 720p il centro precedente variava fra x=414,92–487,84 e y=330,68–418,13; scala 68,09–129,35. Dopo: x=483,33, y=405,17 e scala=89,80 costanti. Questo verifica la stabilità della presentazione, non la qualità del solver. Ispezionati screenshot di selezione, ripiano, hot dice e incasso. Gli stessi limiti noti di compenetrazione/occlusione al bordo restano fuori dall'intervento. Audio collegato ai suoni esistenti, senza registrazione audio di confronto.

File di produzione interessati: `controller.lua`, `hud.lua`, `tray_view.lua`, nuovi `presentation.lua` e `presentation_view.lua` in `src/features/farkle/`; solo filtro grafico e ripristino camera in `src/app/dice_runtime.lua`; solo proiezione/culling/cache in `src/engine3d/view.lua` e `render.lua`. Aggiunti test camera/presentazione, esteso smoke HUD e driver, aggiunti `tests/smoke/turn_feel.lua` e `scripts/capture_turn_feel.py`; aggiornati README e questo documento. Confronto byte per byte di 83 file protetti (regole, dati, asset, fisica, geometria, spawn, A/B, mapping, texture e wrapper): invariati. Diff normalizzato dei punti d'integrazione in `audits/turn-feel/production.diff`. Revisione indipendente del codice: nessun problema concreto rilevato; non sostituisce le prove grafiche.

Banco e pergamena condividono `src/features/scriptorium/desk_view.lua`, `page_layout.lua`, `src/data/scriptorium_module_config.lua`. Non eliminare questi moduli per il loro nome storico. Il Farkle disegna sfondo `(0,0,1920,1080)`, banco `(0,155,1920,925)` e anteprima pergamena `(1450,210,430,390)`; la vecchia griglia cromatica non è il layout attivo.

Contratto degli asset: PNG RGB/RGBA, alpha non premoltiplicato, origine alto-sinistra, dimensioni/aspect ratio coerenti con la destinazione, senza testi o comandi dipinti. Ogni livello viene scalato al proprio rettangolo, con filtro lineare e ripristino dello stato grafico; caricamenti riusciti e falliti sono in cache. Fallback indipendente per file mancante/corrotto; riavvio o `desk_view.reload_assets()` dopo sostituzioni. Conservare canvas e margini trasparenti; il DPI non influisce. Il banco 2D non genera collisioni o occlusioni fisiche.

README dei pacchetti grafici conservati in `resources/ui/desk/*.txt`; licenze in `third_party/` e nelle rispettive librerie. Font, audio e shader restano ai percorsi correnti. I caricamenti dinamici delle facce D8 restano raggiungibili dal costruttore condiviso: non implicano una modalità giocabile e non autorizzano eliminazioni di asset.

## Salvataggi e strumenti

Identità LÖVE **`manuscript-farkle-roguelite`**. Impostazioni in `settings_data.lua`, registro azioni in `runs.csv`, normalmente sotto `%APPDATA%/LOVE/manuscript-farkle-roguelite`. Nessuna run riprendibile; nessuna lettura/scrittura del vecchio `scriptorium_save.lua`. Le impostazioni video vengono applicate dal bootstrap e rispettate dal root entry.

`Avvia.cmd` usa `LOVE_EXE`, installazioni Windows note o PATH. Non genera pacchetti e non richiede Python. Per i test, `scripts/test_luajit.py` usa la DLL LuaJIT distribuita con LÖVE (`LOVE_LUA_DLL` permette di specificarla). `scripts/run_smoke.py` invoca l'applicazione corrente, isola APPDATA e scrive evidenze nell'audit indicato da `--out`. Non lasciare variabili `MANUSCRIPT_*_SMOKE`/`MANUSCRIPT_SOURCE_CASE` impostate nel gioco normale.

I vecchi harness degli audit sono fotografie storiche, con percorsi originali: per riprodurli usare il checkpoint corrispondente in una cartella separata. Le versioni correnti in `tests/smoke/` aggiornano i percorsi e non richiedono copie del gioco o alias di produzione. Nessun `.love` viene generato.

## Limiti e politica di modifica

- Collisioni fra dadi approssimate: contatti anticipati e compenetrazioni restano possibili.
- Contenimento di sicurezza e volume delle pareti visibili non coincidono perfettamente; possibili intersezioni con il bordo dopo lo spawn.
- Spawn senza overlap non implica assenza di penetrazioni finali: l'ultima promozione fisica registrava 3 casi su 39 lanci mirati, non una stima generale.
- Distribuzioni normali non certificate uniformi/indipendenti; alcuni protocolli precedenti mostravano scostamenti, senza attribuzione causale definitiva.
- Interpolazione interna dei triangoli affine, non perfettamente prospettica; correzione della sagoma non corregge una penetrazione fisica.
- Dado pesato emulato tramite rilanci, non massa fisicamente decentrata.

Non modificare autonomamente fisica, collisioni, spawn, contenimento, dimensioni, gravità/attrito/restituzione/inerzia, calendario o A/B. Servono un bug riproducibile che comprometta la giocabilità, autorizzazione specifica e confronto prima/dopo. Nessuna migrazione di framework, solver SAT completo o uso di `love.physics` (2D) per sostituire il motore 3D.

Evidenze storiche e checkpoint sono indicizzati in [legacy/README.md](../legacy/README.md); verifica della sola migrazione in [PROMOZIONE_FARKLE.md](../PROMOZIONE_FARKLE.md). Le statistiche teoriche del regolamento sono separate dai test fisici.

## Stabilizzazione del runtime (ottobre 2026)

- I tentativi meccanici e i lanci ludici sono distinti. `dice.physical_attempt` e `dice.physical_settled` descrivono la simulazione, mentre `dice.roll_accepted` viene emesso **soltanto** dopo la conferma del controller Farkle. L'evento storico `dice.roll_settled` continua a esistere, ma segnala un lancio accettato: i listener che vogliono contare le mani devono usare `dice.roll_accepted`. I ritentativi fisici e i risultati respinti dal dado pesato non vengono conteggiati come nuovi lanci.
- Il modulo `src/gameplay/farkle/commission_progress.lua` possiede gli obiettivi e le transizioni delle commissioni, senza cambiare il motore del punteggio. L'eventuale sistema di avversari deve consumare eventi ludici accettati, senza introdurre logica di combattimento nella fisica o nel valutatore Farkle.
- `settings_data.json` è ora il file delle preferenze: la lettura usa un decoder **solo dati** con limiti di dimensione/profondità, senza eseguire codice. Se manca, `settings_data.lua` è interpretato tramite un parser ristretto di tabelle letterali e migrato, senza eseguirlo né cancellarlo. `settings_data.json.bak` serve al recupero da una scrittura primaria corrotta. LÖVE non garantisce una rinomina atomica cross-platform; la verifica del file temporaneo più backup riduce il rischio ma non garantisce atomicità.
- Il motore fisico resta a passo fisso ma non accumula lavoro durante menu/splash inattivi. Il filtro di utilizzabilità dell'HUD riusa le opzioni Farkle già cache-izzate. Nessuna costante fisica, faccia del dado o punteggio è stata ribilanciata.
- All'avvio si registra il seed RNG nella diagnostica della run. Gli ID di lancio ludico e tentativo fisico consentono di distinguere rilanci ordinari e tentativi tecnici. Questo aiuta il debug, **non garantisce** la riproduzione bit per bit della simulazione grafica o fisica.
- I test puramente Lua vengono eseguiti in CI con Lua 5.4 e LuaJIT. I test che necessitano di una finestra LÖVE2D o dell'hardware reale restano da eseguire su Windows con il gioco.

