# Architettura e verifica tecnica di Project Folio

Percorsi di produzione ricontrollati il 18 novembre 2026. Documento tecnico di riferimento, non cronologia delle singole milestone UI.
Questo documento descrive i componenti del prototipo corrente.
La [visione](project_vision.md) raccoglie la direzione narrativa e progettuale.

## Modalità sperimentale: duello al Opponent (branch 0.1.98)

**Stato: proposta in PR, non ancora stabilizzata.** Dal selettore
partita, `mode='duel'` avvia una sfida a 500 punti assicurati con
turni alternati. `src/farkle/rules.lua` mantiene il punteggio canonico
e applica le sole eccezioni del duello (niente commissioni o limite
turni, vittoria immediata al target). Il controller usa una policy interna, ricavata e verificata nel
laboratorio `experiments/opponent_duel/ai.lua`, durante il turno avversario, ma
lancia sempre i medesimi dadi fisici tramite
`U:request → onRollRequest → dice.roll_accepted`, evitando un RNG
separato o facce artificiali. La semantica dei comandi di lancio manuale
rimane esclusiva del giocatore.

La scena viene proiettata con `pitch=0.90` radianti,
`tray=(8,505,1904,545)` nel viewport virtuale 1920×1080,
`rear_span=1740` e bordo posteriore vincolato al Opponent. Il cartiglio
si sovrappone agli ultimi 100 px della zona di gioco: il controller
testa le hitbox dei comandi prima dei gesti di presa del dado in quella
striscia. **Gate umano obbligatorio:** verificare che nessun dado
fisico rimanga occultato dal cartiglio in condizioni normali.

La UI mostra punteggi separati e intenzione del rivale; il simulatore
sperimentale precedente resta in `experiments/`. La qualità e
l'equità dell'IA non sono ancora misurate su lanci 3D reali.

## Avvio e responsabilità

`love .` o `run_game.cmd` eseguono `main.lua`. Il controller Farkle viene
iniettato in `src/core/dice_runtime.lua`, che registra splash, menu,
selezione della partita e impostazioni. La navigazione apre prima
`startup_splash`. L'identificatore interno della partita è `scriptorium`.

| Percorso | Responsabilità |
|---|---|
| [`src/farkle/rules.lua`](../src/farkle/rules.lua) | Punteggio (`scoring`), medaglie (`medals`), commissioni (`progress`) e regole del turno |
| [`src/farkle/controller.lua`](../src/farkle/controller.lua) | Input, richieste fisiche, esiti accettati, transizioni e registrazione eventi |
| [`src/farkle/interaction.lua`](../src/farkle/interaction.lua) | Selezione (`selection`), presa singola (`single`), gruppo (`group`, `shaker`) e scuotimento (`shake`) |
| [`src/farkle/dice.lua`](../src/farkle/dice.lua) | Facce incise, filtro pesato e calcolo del rischio teorico |
| [`src/farkle/presentation.lua`](../src/farkle/presentation.lua) | Provenienza dei risultati, stato HUD (`hud_model`), folio (`folio_view`), medaglie (`medal_panel`) e notifiche (`toast_messages`) |
| [`src/farkle/ui.lua`](../src/farkle/ui.lua) | HUD (`hud`, con `actions` e `accepted`), geometria (`layout`), testo (`text_fit`), indicatori (`overlay`), finestre (`dialogs`) e avversario (`opponent_scene`) |
| [`src/farkle/tabletop.lua`](../src/farkle/tabletop.lua) | Inquadratura prospettica fissa (`tray_view`), workshop diagnostico (`tray_workshop`) |
| [`src/screens/frontend.lua`](../src/screens/frontend.lua) | Menu principale (`main_menu`), selezione partita (`campaign_select`) e impostazioni (`settings`); registrazione tramite `modules` |
| [`src/screens/folio_surface.lua`](../src/screens/folio_surface.lua) | Superfici condivise (`menu_surface`), impaginazione (`page_layout`), testo animato (`folio_ink_text`), figure e post-effetti 2D |
| [`src/screens/startup_splash.lua`](../src/screens/startup_splash.lua) | Intro LÖVE e transizione al menu |
| [`src/core/dice_runtime.lua`](../src/core/dice_runtime.lua) | Bootstrap LÖVE, lancio, presa, simulazione e collegamento a g3d |
| [`src/engine3d/bounds.lua`](../src/engine3d/bounds.lua), [`roll_resolution.lua`](../src/engine3d/roll_resolution.lua) | Contenimento e spawn (`containment`, `fps`, `spawn`); lettura delle facce (`face_state`) e risoluzione del tiro |
| [`src/engine3d/physics.lua`](../src/engine3d/physics.lua) | Corpi, gravità, sponde, passo fisso e sottopassi angolari limitati |
| [`src/engine3d/die_collision.lua`](../src/engine3d/die_collision.lua) | Contatti D6–D6 (SAT orientato, sweep traslazionale, risposta impulsiva e stabilizzazione fra più dadi); non è un port FPS nativo |
| [`src/engine3d/geometry.lua`](../src/engine3d/geometry.lua), [`view.lua`](../src/engine3d/view.lua) | Geometrie D6/D8 e texture facce (`face_texture`); proiezione e sagome dei dadi (`projected_die`) |
| [`src/engine3d/g3d/scene.lua`](../src/engine3d/g3d/scene.lua) | Camera, mesh, materiali, smussi, scenografia e ombre |
| [`src/engine3d/g3d/live.lua`](../src/engine3d/g3d/live.lua), [`glb_loader.lua`](../src/engine3d/g3d/glb_loader.lua) | Renderer del tavolo e dei dadi, ritratti accantonati e caricamento GLB |
| [`src/data/dice_schema.lua`](../src/data/dice_schema.lua) | Configurazioni di lancio, scena, resa dei dadi e layout del vassoio (`tray`) |
| [`src/data/frontend_schema.lua`](../src/data/frontend_schema.lua), [`locale_en.lua`](../src/data/locale_en.lua) | Palette (`palette`), impostazioni (`settings`), menu (`menu`), campagne (`campaign`), splash (`splash`) e traduzioni |
| [`src/core/config.lua`](../src/core/config.lua) | Validazione condivisa (`schema`) e caricamento configurazione dadi (`dice`) |
| [`src/core/runtime_state.lua`](../src/core/runtime_state.lua) | Stato runtime, accessibilità (`ui`), preferenze (`settings`), persistenza e codec (`store.codec`) |
| [`src/core/presentation.lua`](../src/core/presentation.lua) | Traduzioni (`i18n`), font (`typography`), versione (`version`), illustrazioni e particelle menu (`menu_visuals`) |
| [`src/core/navigation.lua`](../src/core/navigation.lua) | Navigazione e coordinate virtuali (`resolution`) |
| [`src/core/game_manager.lua`](../src/core/game_manager.lua) | Ciclo di vita schermate e ordine degli hook (`execution_order`) |
| [`src/core/engine_bridge.lua`](../src/core/engine_bridge.lua) | Collegamento al runtime, eventi (`EventBus`, `roll_events`) e logging (`logger`) |
| [`src/core/audio_manager.lua`](../src/core/audio_manager.lua) | Musica, effetti UI, scuotimento e contatti fisici |

La produzione contiene **esattamente 29 file Lua sotto `src`**:
8 in `core`, 3 in `data`, 8 in `engine3d` (di cui 3 in `g3d`),
7 in `farkle` e 3 in `screens`. Librerie, test ed esperimenti non
rientrano nel conteggio.
Nei file accorpati, i nomi tra parentesi indicano le sezioni o sottotabelle
da cercare nel modulo. Non esistono alias dei vecchi percorsi.
Per esempio, `require('src.farkle.ui').dialogs` apre la sezione
dialoghi; `require('src.core.runtime_state').settings` gestisce le preferenze.
Il test `tests/repo/source_structure_test.lua` verifica l'elenco completo,
il conteggio, la mappa delle cartelle, le API condivise e il caricamento GPU
differito.

## Struttura delle cartelle

```text
main.lua, conf.lua      Entry point LÖVE (devono restare nella root)
src/core/               Bootstrap, servizi, stato, navigazione, audio
src/data/               Schemi dati e traduzioni (locale_<lingua>.lua)
src/engine3d/           Fisica, geometria, vista; g3d/ è il renderer 3D
src/farkle/             Regole, controller, input, tavolo e HUD della partita
src/screens/            Splash, menu, impostazioni e superfici del folio
lib/                    Librerie esterne, core.lua (vettori), licenses/
resources/              Immagini, modelli, font, suoni e shader
tests/<area>/           Test Lua: core, data, engine3d, farkle, hud, screens, repo, labs
tests/smoke/            Smoke grafici con LÖVE reale
scripts/                Strumenti; scripts/tests/ contiene i test Python
experiments/            Laboratori isolati, mai caricati dal gioco
docs/, audits/          Documentazione ed evidenze di revisione
```

Il tavolo da gioco usa il layout `table_minimal`, con selezione diretta
dei dadi. La prospettiva e il picking passano da
`src/farkle/tabletop.lua` (`tray_view`),
`src/farkle/interaction.lua` (presa fisica) e
`src/engine3d/g3d/scene.lua` (`camera`). Per la geometria esatta
consultare quei sorgenti e i test di proiezione, che seguono l'evoluzione
dell'inquadratura. Lo studio P1 A/B `open_codex` e il relativo avvio con
`MANUSCRIPT_UI_V2_LAYOUT_STUDY` sono stati ritirati. Il codice del layout
`single_folio` non fa più parte della geometria o del rendering della UI;
il Folio resta accessibile tramite [F] e le finestre di dialogo.

## Tavolo v0.1.96 — Old Wooden Table (laboratorio reversibile)

**Ipotesi:** un vecchio tavolo rustico con fascia leggera e sostegni
proporzionati rende il gioco più credibile rispetto al precedente
`wooden_compact`, senza cambiare il lancio dei sei dadi.

Il preset `old_wooden` viene proposto all'avvio. F8 ripristina
`wooden_compact` e le altre varianti, come confronto A/B. Il rendering
g3d usa il GLB `resources/models/old_wooden_table_game_ready_asset.glb`
quando presente (file originale fornito separatamente), e altrimenti
una **geometria sostitutiva esplicitamente originale e semplificata**
(`resources/models/old_wooden_table_fallback.lua`). Non confondere
la seconda con i triangoli/texture dell'asset dell'autore.

La differenza di proporzione è reale: il GLB è circa 1,60:1,
mentre il tavoliere fisico misura 28 × 12,1 (2,31:1).
La conversione `Scenery.keep_old_support_proportions` estende il
piano superiore ai confini già esistenti, ma impedisce che le
gambe vengano allargate nella stessa misura. Il fallback segue
lo stesso principio con una superficie ampia e un cavalletto
sottostante da ~1,7:1. L'import resta visivo e non definisce
collider o fattori RNG.

**Gate:** test stile F8, estensione del piano, normali, profondità,
proporzioni dei sostegni, CI Lua/Mesa e screenshot con sei dadi.
La prova diretta del GLB in Windows non è coperta dalla CI se
il file non è tracciato; installare l'asset dallo ZIP e verificare
texture, orientamento, collisioni percepite e leggibilità delle facce.
Non promuovere il nuovo modello a canonico prima del playtest.

## UI v0.1.95 — Variante B «Compatta» del tavolo

**Decisione utente:** selezionata la variante B in risposta allo screenshot
v0.1.94, nel quale la fascia anteriore, le gambe e i giunti del legno
occupavano troppo spazio rispetto ai dadi.

**Cambio isolato e reversibile:** il `tray_workshop` apre ora
`wooden_compact`, mentre premendo **F8** si può passare a `wooden`
(il modello grande originale), quindi alle altre varianti già esistenti.
Non viene creata una seconda camera, un renderer alternativo o una
configurazione fisica dei dadi.

- `Scenery.place_table` continua a dimensionare la stessa geometria
  derivata Pixel Life sul piano fisico. Solo dopo questo allineamento,
  `Scenery.compact_table(model,0.22)` comprime verticalmente la
  struttura grafica (fascia, gambe) sotto la superficie. Mantiene
  esattamente la quota superiore e ricalcola le normali per la trasformazione
  affine. Il valore 0.22 è un **parametro estetico**, non un coefficiente
  fisico.
- La superficie conserva il rettangolo fisico, con **sei** tavole
  visive invece di otto, giunzioni da 0.012 e UV continue. L'intenzione
  è ridurre l'effetto «strisce» senza cancellare il materiale.
- Il bordo grafico della variante compatta passa da 0.14 a **0.08**
  unità mondo; l'altezza della parete rimane quella fisica
  (`scene.box.border_height=0.74`) per non suggerire falsi confini.

**Limite della scelta:** il piano superiore non viene ristretto in X/Y.
Una riduzione indipendente renderebbe visivamente possibile lanciare
fuori da una collisione invisibile. L'intervento agisce sull'**ingombro
dell'arredo**, non sui limiti del campo da gioco né sulle dimensioni
dello screenshot.

**QA automatico:** `tests/engine3d/wooden_board_contract_test.lua`
controlla quota superiore, profondità di fascia, normale dei vertici,
continuità UV, altezza dei bordi e dimensioni della superficie;
`tests/farkle/tray_workshop_cycle_test.lua` protegge la reversibilità
F8; `tests/engine3d/g3d_live_test.lua` include la nuova skin.
L'esito della CI e delle catture Mesa deve essere riportato in PR.
Rimane aperto il test umano Windows con sei dadi in movimento e nella
zona posteriore del tavolo.

## Tavolo v0.1.94 — piano grafico e fisico allineati

La variante `wooden` di v0.1.93 portava il piano decorativo
a z=+0,24 sopra il piano fisico (z=0). Questo poteva produrre
intersezioni visive con i dadi. La correzione conserva le
coordinate fisiche e modifica esclusivamente il renderer:

- fallback incluso: silhouette a z=-0,018, otto assi
  sul ricevitore z=0 con altezza decorativa +0,006,
  e sottili giunzioni. Il depth buffer resta condiviso;
- GLB completo opzionale: piano superiore a z=+0,005
  con texture UV originale e ricevitore a z=-0,018
  che non copre il piano importato.

`tests/engine3d/wooden_board_contract_test.lua` ora
verifica i due percorsi e il bordo fisico invariato.
Il GLB ottimizzato allegato separatamente conserva UV
e 4538 triangoli, senza normal/roughness PBR che il
loader esistente non applica. Nessuna logica di punteggio
o collisione nuova. Il comfort Windows resta da verificare.

## Tavolo di legno game-ready, v0.1.93 (esperimento F8)

**Scelta visiva:** variante `wooden` selezionata come default nel
`tray_workshop`; `book` continua a mostrare il precedente tavolo
decorativo in marmo. Premere **F8** per confrontare le due varianti e
gli skin `current/A/B/C` senza riavviare, senza modificare il gameplay.

**Origine:** `wooden_table_game_ready_asset.glb` allegato dall'utente,
Pixel Life, CC BY 4.0. La sorgente completa da 12 MB non è inclusa
nella PR: una silhouette triangolare *derivata*, compressa e tracciata
in `resources/models/wooden_table_mesh.lua`, è utilizzata come
fallback autosufficiente. La superficie usa la texture `wood.png`
del progetto anziché l'atlante PBR originale. L'originale completo
può essere aggiunto localmente in
`resources/models/wooden_table_game_ready_asset.glb`, che verrà
caricato dal loader GLB esistente (senza nuovo renderer). Per
attribuzioni e modifiche vedere
`resources/models/WOODEN_TABLE_CREDITS.md`.

**Separazione di responsabilità:** `src/engine3d/g3d/live.lua`
gestisce soltanto la scelta dell'asset grafico. Il modello
decorativo ha un bordino rialzato (+0,24 unità mondo), mentre
il `floor_model` rimane sul piano fisico `z=0` per ombre e
contatto coerenti anche dove la mesh semplificata è aperta.
Rimangono attive le pareti fisiche e il loro bordo visivo
sottile. Nessuna variazione a `dice_schema`, contatti,
hitbox, proiezione, RNG o Farkle.

**Verifiche:** `tests/engine3d/wooden_board_contract_test.lua`
e `scripts/tests/test_wooden_table_asset.py`, oltre alla
suite F8 e agli screenshot Mesa. La compatibilità dei
materiali del modello originale completo, le licenze di
distribuzione e la leggibilità Windows sono ancora gate umani.

## UI 0.1.92 — Board centrata e Rivale davvero dietro il tavolo

**Diagnosi delle catture 1280×720:** le precedenti correzioni di
`pitch` lasciavano il tavolo nella fascia più bassa dello schermo
e una distanza vuota tra il bordo posteriore e il PNG dell'avversario.
La board sembrava un pannello sospeso davanti alla bottega.

**Geometria corretta:** in `src/engine3d/view.lua` la coordinata
verticale proiettata include `cos(pitch)*y - sin(pitch)*z`;
per un piano orizzontale, ridurre pitch verso 0 espande
la profondità visibile. La proposta passa da 1.16 a
`pitch=0.80`, con `distance=52`, `yaw=0` e camera bloccata.

**Composizione:** il bordo posteriore scende in termini di
quota numerica da 662 a **520** (sale sullo schermo). Il
Rivale ha un limite di altezza **470** e `portrait_lift=40`:
il suo bordo basso termina solo 5 unità virtuali sopra il
retro del tavolo, anziché fluttuare 61 unità sopra.
Nel modello proiettivo, la superficie passa da circa 319
a **403 unità virtuali di profondità**, mantenendo una scala
di circa **494** contro 503. Sono grandezze del proiettore,
**non** risultati di comfort o divertimento misurati.

**Viewport fisico:** il vecchio `tray=(60,538,1800,426)`
iniziava più in basso del nuovo bordo posteriore (520),
impedendo il picking dei dadi vicino al retro. Per questo
l'area di schermo, condivisa tra rendering 3D e selezione
mouse, è ora `(60,470,1800,494)`; la posizione del bordo
anteriore **non cambia** (y=964). Le collisioni e le
posizioni fisiche dei dadi nel mondo restano identiche.
Niente doppia proiezione o spostamento grafico scollegato
dall'input.

**Gate:** test Lua per scala, bordi del tray, dadi sul retro,
limiti ritratto, allineamento con comandi e stabilità del
lancio; smoke Mesa e confronto screenshot; UAT manuale
Windows per comodità dei gesti e chiarezza in movimento.
Questa composizione è un **esperimento**, non una scelta
canonica confermata dal playtest.

## UI 0.1.91 — Visualizzare la posta senza aumentare i controlli

La scorecard è ora un **unico pannello** con punteggio sicuro, provvisorio,
obiettivo, turni rimasti e una piccola barra proporzionale. La barra
mostra in **salvia** i punti **già incassati** (`game.bank`) e in
**cinabro** i punti **già accantonati ma a rischio** (`game.pot`),
con segmenti consecutivi limitati all'obiettivo della commissione.
La scelta corrente, se non confermata, **non** compare nella barra.

La barra e le etichette sono soltanto letture del modello autorevole;
non influenzano il tiro, le regole, le facce, le probabilità o le
condizioni di incasso. Le cifre restano visibili e complete anche quando
la somma supera l'obiettivo. L'elemento è interno alla scorecard e non
introduce un nuovo pannello, una valuta o un consiglio di gioco.

`tests/hud/ui_v2_wager_track_test.lua` verifica la barra a zero, con
posta sicura e a rischio, oltre l'obiettivo e con una selezione ancora
provvisoria; `tests/hud/ui_v2_minimal_table_test.lua` ne verifica
la geometria. Restano richiesti controllo screenshot 720p/1080p,
alto contrasto e playtest umano. La promessa che guida questa scelta
è descritta in [Fantasy del giocatore](player_fantasy.md).

## UI 0.1.90 — HUD leggibile e tavolo abbassato

**Problema osservato:** in un fermo immagine a 1654×930 il pannello
punteggi e le etichette Accantona/Incassa risultavano troppo piccoli;
la riga al di sotto dei pulsanti duplicava le conseguenze gia presenti
nelle azioni. Il bordo posteriore del tavolo era troppo vicino al
ritratto dell'avversario, facendo percepire il lancio come diretto verso
la sua figura.

**Intervento:** il layout resta `table_minimal`, senza sidebar.
La scorecard passa a 540×154 virtuali e le due cifre principali usano
una gerarchia maggiore. I controlli occupano una placca piu leggibile
(1140×110, sotto il campo dei dadi), con label da 34 punti nominali
e una riga superiore per *solo* stato e indicazioni non gia presenti
nelle action. La tipografia dei dati passa al leggibile Cardo;
Aldine Aetna rimane negli elementi editoriali. Lo status valido
non ripete le due anteprime Accantona/Incassa.

**Camera e presa:** il rettangolo fisico `tray` resta
`(60,538,1800,426)`, incluse coordinate di picking e selezione.
Solo la proiezione e cambiata: la quota del bordo posteriore passa
da **614 a 662** punti virtuali e il `pitch` canonico della camera
da **1.00 a 1.16 rad** (prima iterazione: **1.12**, poi regolato a **1.16** per una vista leggermente più dall'alto). `yaw=0.00`, `distance=52` e lock restano invariati. Il `portrait_lift` aumenta da 48 a 96:
il Rivale resta alla quota originale mentre il tavolo scende,
creando 61 punti virtuali di separazione invece di trascinare
in basso anche il ritratto. La combinazione mantiene la dimensione
proiettata dei dadi, altrimenti ridotta da un abbassamento puro, e
riduce la sensazione che il lancio avvenga sul ritratto. In
`src/farkle/tabletop.lua` resta un unico fit per mesh/picking;
nessuna traslazione scollegata del renderer o modifica alla fisica.

**QA:** `tests/hud/ui_v2_minimal_table_test.lua` protegge dimensioni,
riga status e nuova quota; `tests/hud/ui_v2_projection_comfort_test.lua`
controlla il fit comune, lo spazio utile e il pick rect invariato; ora vincola il preset 1.16, la profondità apparente del piano e la vicinanza del bordo frontale ai comandi.
Le prove headless non dimostrano il comfort del mouse o l'aspetto
finale sul monitor: serve QA visiva e lanci ripetuti su Windows, anche
con gesti che puntano al bordo posteriore.

## UI: anteprima delle decisioni (0.1.89)

Il Tavolo del Opponent presenta le conseguenze della selezione attraverso
`src/farkle/ui.lua`, senza introdurre una seconda fonte per il punteggio:
`hud.actions.build` legge soltanto `rules.selection_option` e
`rules.bank_status`. Sui dadi selezionati validi il comando **Accantona**
mostra punti a rischio dopo l'azione e dadi ancora liberi; **Incassa**
mostra i punti assicurabili e dichiara la fine del turno. Sotto le soglie,
il testo indica quanti punti mancano. L'HUD contestuale ripete in forma
compatta le due alternative, comprese le selezioni parziali o non valide.

La seconda iterazione rende visibile il controllo fisico già
supportato: nel tavolo il passaggio del puntatore su un dado realmente
afferrabile evidenzia la sagoma proiettata, mentre trascinare il tasto
sinistro distingue la **selezione fisica di gruppo** dalla selezione
di punteggio. Durante la presa col destro, il badge vicino al puntatore
mostra il numero di dadi trattenuti; mostra «SCOSSA RILEVATA» soltanto
quando il detector di inversioni ha registrato un evento recente
(finestra di 0,70 s). L'etichetta resta entro lo schermo e non altera
il picking. Lo stato contestuale spiega presa, scuotimento, rilascio
e annullamento con Esc.

Il badge è un resoconto del gesto reale, **non** un indicatore di
«faccia desiderata», probabilità migliorata o qualità predetta del
lancio. Lo stato di shake viene letto, non creato, dall'HUD.
Gli stati di selezione e le transizioni restano del controller;
la medesima UI non può spostare né assegnare una faccia ai dadi.

Le etichette sono **anteprime**: non eseguono `rules.take` o
`rules.bank_turn` durante il disegno, non modificano il lancio fisico e
non alterano le hitbox. I pulsanti eseguono le azioni esclusivamente
attraverso le callback già esistenti del controller. Il colore ocra sul
comando primario è un indizio visivo aggiuntivo, non l'unico mezzo per
distinguere le azioni; resta disponibile la modalità alto contrasto.

Regressioni interessate:
`tests/hud/ui_v2_decision_preview_test.lua` per soglie, incasso diretto
e hot dice; `tests/hud/ui_v2_minimal_table_test.lua` per la leggibilità
dei feedback e la geometria. Da verificare ancora con LÖVE reale su Windows:
etichette a 1280×720, testo grande, ultrawide, contrasto e picking fisico.

La proposta di fantasy-first è **ricerca**, non gameplay:
`research/RQ-002_FANTASY_FIRST_UI.md`.

## Rendering e risorse

g3d disegna il vassoio e i dadi 3D. Interfaccia, ritratto dell'avversario e
illustrazioni rimangono elementi 2D.

- `lib/g3d/`, `src/engine3d/g3d/` e
  `resources/shaders/dice_lit.glsl` forniscono il rendering.
- `resources/dice/1.png` … `6.png` forniscono le facce D6.
- `resources/scenes/printshop-room.png` è il fondale della bottega senza persone;
  `resources/opponents/opponent.png` è il PNG del personaggio Opponent, riutilizzato temporaneamente come illustrazione del default generico `rival` finché non esiste `resources/opponents/rival.png` (preferito automaticamente quando disponibile). L'ID `opponent` resta selezionabile solo esplicitamente.
- `resources/textures/wood.png` è la texture condivisa dal tavoliere 3D
  e dal laboratorio g3d. I vecchi JPEG del Opponent per legno e intaglio
  sono stati eliminati e non devono più essere caricati. Il PNG storico
  `resources/textures/wood_floor.png` non ha consumer individuati
  e rimane reperibile nel commit `d767b7c8`, non nel tree corrente.
- `resources/models/marble_topped_centre_table.glb` è il tavolo 3D
  caricato dal renderer, se disponibile; `old_wooden_table.glb`
  rimane come campione reale per il test headless del parser GLB.
  Il piccolo `doubloon.glb`, privo di consumer attuali identificati,
  resta nella cronologia Git (commit `33f8afea`).
  I tre scan non referenziati (libro alchemico, Fabrica e moneta romana)
  sono disponibili nella cronologia Git (commit `33f8afea35`), non
  nell'albero distribuito.
- `resources/ui/menu_manuzio.png` è l'illustrazione attuale del menu.
- `resources/ui/startup_splash/` e i relativi shader appartengono allo splash LÖVE.
- Licenze e attribuzioni si trovano in `lib/licenses/` e nelle librerie.

La texture delle facce è una sezione di `geometry.lua` (`face_texture`).
Le immagini vengono caricate solo al disegno, non durante gli import
dei modelli e dei test headless.

## Contratti fisici e risultati

Ogni dado conserva il proprio ID. La mappa individuale delle facce alimenta
sia la lettura del valore sia la rappresentazione. I dadi accantonati
vengono esclusi dalla simulazione attiva e ripristinati nella collezione
condivisa al termine dell'aggiornamento.

Il passo fisico usa un accumulatore a intervallo fisso. Spawn e contenimento
appartengono al runtime e ai rispettivi moduli in `src/engine3d/`.
Le pose ambigue passano attraverso il recupero fisico A/B.

La diagnostica distingue il tentativo meccanico dal risultato ludico
accettato. L'evento `dice.roll_accepted` viene pubblicato dopo l'accettazione
del controller. Il dado pesato può richiedere ulteriori lanci fisici
visibili per applicare il proprio filtro.

Le probabilità teoriche assumono le distribuzioni dichiarate nel
[regolamento](farkle_rules.md). La distribuzione della simulazione reale
richiede misure dedicate. La ripetibilità dei test numerici riguarda
i rispettivi modelli e semi.

## Audio e collisioni

Dalla v0.1.38 i rumori del contatto fisico provengono dai callback
di sola lettura del solver, filtrati e riprodotti da
`src/core/audio_manager.lua`. Il suono del
lancio **non** parte più da un effetto completo in corrispondenza
del rilascio del mouse. Le voci di scuotimento si attenuano
quando la mano rimane ferma; il runtime mantiene i D6 e le
regole Farkle invariati. Qualità dei campioni e tempi percepiti
richiedono ascolto reale su Windows.

## Impostazioni e dati utente

L'identità LÖVE è `manuscript-farkle-roguelite`. Su Windows i dati
si trovano normalmente in `%APPDATA%/LOVE/manuscript-farkle-roguelite`.

Le preferenze usano `settings_data.json`, con parser dati, limiti,
file temporaneo e backup. La migrazione legge il formato precedente
`settings_data.lua` attraverso il parser ristretto. Il registro delle
azioni è `runs.csv`. Il riavvio della partita riparte dall'inizio
e l'interfaccia chiede conferma.

## Verifiche riproducibili

La configurazione completa è in
[.github/workflows/lua_tests.yml](../.github/workflows/lua_tests.yml).
Dalla radice del repository, con i rispettivi runtime installati:

```sh
python3 scripts/tests/test_versioning.py
python3 scripts/check_versioning.py

for test in $(find tests -name '*_test.lua' | sort); do
  lua5.4 -e 'unpack=table.unpack' "$test" || exit 1
done

for test in $(find tests -name '*_test.lua' | sort); do
  luajit "$test" || exit 1
done

```

Su Windows `scripts/test.ps1` richiama la suite Lua;
`scripts/run_lua_tests.py` permette di usare la DLL LuaJIT di LÖVE.

Gli smoke grafici sono in `tests/smoke/`; `scripts/run_smoke.py` avvia
il runtime con una directory di dati isolata. Le variabili diagnostiche
`MANUSCRIPT_*_SMOKE` e `MANUSCRIPT_SOURCE_CASE` selezionano gli scenari.
I comandi di acquisizione Windows sono descritti in
[windows_technical_qa.md](windows_technical_qa.md).

La verifica visiva riguarda shader, prospettiva, picking, presa singola e
multipla, rilascio, collisioni, audio, dadi accantonati e ridimensionamento.

## Laboratori e archivio

I laboratori presenti sono isolati dal gioco e conservano ciascuno il proprio README. I vecchi studi FPS, g3d, FX, Miniature 2D e Segni non sono più nell'albero attuale: le loro versioni storiche restano recuperabili tramite Git.

| Laboratorio attuale | Scopo |
|---|---|
| [Battute Gemelle — archivio](../research/EX-BG-001.md) | Screening G3 negativo, codice ritirato dalla working tree |
| [Encounter Research A/C](../experiments/encounter_ac_lab/README.md) | Offerte divise e prove contese, senza modificare il Farkle canonico |
| [EX-001 Opponent X](../experiments/ex001_opponent_x_lab/README.md) | A/B del ridisegno iniziale X del Opponent |
| [Opponent e posta](../experiments/opponent_wager_lab/README.md) | Duello asimmetrico V4, isolato dalla produzione |
| [P4ND0RA](../experiments/p4ndora_1to1/README.md) | Confronto tra Farkle a sei D6 e sacchetto del rivale |
| [Tre Prove / Riserva — archivio](../research/EX-TP-001.md) | Screening negativo, implementazione ritirata |

Il rapporto della [QA del 3 novembre](https://github.com/Askeladd22/Project_Folio/blob/36ea51a283d82df5d53ddccb1791a978b38d8e89/docs/WINDOWS_QA_CAPTURE_REVIEW_20261103.md)
descrive le acquisizioni presenti in `audits/ui-v2-review/`.
Gli output nuovi di audit e checkpoint sono esclusi da Git.

La [versione storica del documento tecnico](https://github.com/Askeladd22/Project_Folio/blob/c3ebf78c1314b5dd4587d7bf5ec2c537b044f4c0/docs/TECHNICAL.md)
conserva le note del 15 ottobre, comprese le verifiche e i percorsi
degli audit locali di quel periodo.


---

## Controlli e stati dell'interfaccia

**Versione documentale:** 6 novembre 2026 · v0.1.40.
Questa è la descrizione sintetica della UI in uso, **non**
l'inventario della UI legacy o la roadmap F6.

### Gesti e tasti

- **Click sinistro:** selezione di dadi per punteggio; trascinamento
  sulla superficie per scegliere più dadi fisici (marquee).
- **Tasto destro:** presa e rilascio/lancio manuale di un dado o gruppo.
- **A:** Accantona; **Invio:** Incassa quando consentito.
- **1–6:** selezione dei dadi per punteggio dopo un lancio valido.
- **N:** passo successivo consentito; **M:** intervento medaglia quando disponibile.
- **Esc:** annulla prima la presa, poi la selezione fisica; chiude modali
  o apre/chiude il menu di pausa quando il lancio è stabile.
- **F:** consulta il Folio; **?** apre le regole.
- **F7:** laboratorio medaglie (diagnostico), **F8:** workshop del tavolo;
  **F10/F11:** diagnostica g3d.
- **F6 e F9:** *rimossi*; non ci sono HUD e painter di fallback.

### Controlli di partita gestiti dall'unico HUD

Gli identificatori sono parte del contratto di regressione e non
vanno confusi con nuove funzioni approvate:
`help`, `runmenu`, `folio`, `take`,
`bank`, `next`, `rescue`, `fail`, `retryphysical`,
`medaluse`.

Nel pannello delle ricompense e nella pausa:
`weighted`, `engraved`, `medal`, `none`, `close`,
`resume`, `settings`, `restart`, `mainmenu`, `cancel`,
`confirmrestart`, `confirmexit`, `helpTab1`.

Nel laboratorio delle medaglie:
`inspect1`, `equip`, `medalprev`, `medalnext`,
`target1`, `activate`. `inspect1`, `target1` e
`helpTab1` sono esempi di ID generati dinamicamente.

### Stati e precedenze

- `fresh`: si può iniziare il lancio; il punteggio non è selezionabile.
- `rolling`: nessun incasso o accantonamento fino all'accettazione
  del risultato fisico.
- `ready`: si selezionano combinazioni valide e poi si accantona,
  incassa o rilancia secondo le regole.
- `rescue`: Correttore o accettazione del Farkle.
- `physics_error`: ripetizione *tecnica* dello stesso tiro, senza
  consumare una seconda mano di gioco.
- `upgrade`/`medal`/`ended`: dialoghi, ricompense o chiusura,
  non una seconda implementazione di scoring.

La selezione **fisica** con marquee non produce punti; la selezione
**logica** degli ID dadi accetta solo i risultati riconosciuti
dal motore Farkle. Esc non deve mai terminare brutalmente LÖVE.

### Fonti autoritative

- `src/farkle/controller.lua`: precedenza degli input.
- `src/farkle/ui.lua` (`hud.actions`): comandi.
- `src/farkle/ui.lua` (`dialogs`): modali e conferme.
- `src/farkle/presentation.lua` (`medal_panel`): controlli medaglie.
- `src/farkle/rules.lua`: condizioni di gioco.
- `tests/hud/ui_v2_interaction_inventory_test.lua`: invarianti verificati.
- [Regole Farkle](farkle_rules.md) e [QA Windows](windows_technical_qa.md).

*Nuovi controlli e modifiche alle scorciatoie devono essere sincronizzati
con la UI effettiva e i test. Questo documento non prescrive nuove regole.*

## 0.1.99 — Lancio esclusivamente tramite presa fisica

Il giocatore non dispone più di pulsante né scorciatoia per avviare un lancio automatico.
Con il tasto destro afferra un dado e lo rilascia; per più dadi usa prima la selezione
multipla trascinando con il sinistro. Restano **A** (accantona), **Invio** (incassa),
**N** (prossimo turno), **Esc** (annulla/pause). Il lancio autonomo dell'Opponent AI
resta separato dall'input fisico umano. Un recupero fisico del giocatore permette
nuovamente la presa diretta, senza aggiungere un tasto di lancio rapido.

I laboratori a screening G3 negativo [Battute Gemelle](../research/EX-BG-001.md)
e [Tre Prove / Riserva](../research/EX-TP-001.md) restano tracciati nella ricerca;
i relativi sorgenti eseguibili, test e workflow sono archiviati nella cronologia Git.
