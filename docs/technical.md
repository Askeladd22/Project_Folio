# Architettura e verifica tecnica di Project Folio

Percorsi di produzione ricontrollati il 7 novembre 2026. Documento tecnico di riferimento, non cronologia delle singole milestone UI.
Questo documento descrive i componenti del prototipo corrente.
La [visione](project_vision.md) raccoglie la direzione narrativa e progettuale.

## Avvio e responsabilità

`love .` o `run_game.cmd` eseguono `main.lua`. Il controller Farkle viene
iniettato in `src/core/dice_runtime.lua`, che registra splash, menu,
selezione della partita e impostazioni. La navigazione apre prima
`startup_splash`. L'identificatore interno della partita è `scriptorium`.

| Percorso | Responsabilità |
|---|---|
| [`src/farkle/rules.lua`](../src/farkle/rules.lua) | Punteggio (`scoring`), medaglie (`medals`), commissioni (`progress`) e regole del turno |
| [`src/farkle/controller.lua`](../src/farkle/controller.lua) | Input, richieste fisiche, esiti accettati, transizioni e registrazione eventi |
| [`src/farkle/interaction.lua`](../src/farkle/interaction.lua) | Selezione (`selection`), presa singola (`single`), gruppo (`group`, `shaker`), scuotimento (`shake`) e proiezione (`projection`) |
| [`src/farkle/dice.lua`](../src/farkle/dice.lua) | Facce incise, filtro pesato e calcolo del rischio teorico |
| [`src/farkle/presentation.lua`](../src/farkle/presentation.lua) | Provenienza dei risultati, stato HUD (`hud_model`), folio (`folio_view`), medaglie (`medal_panel`) e notifiche (`toast_messages`) |
| [`src/farkle/ui.lua`](../src/farkle/ui.lua) | HUD (`hud`, con `actions` e `accepted`), geometria (`layout`), testo (`text_fit`), indicatori (`overlay`), finestre (`dialogs`) e avversario (`opponent_scene`) |
| [`src/farkle/tabletop.lua`](../src/farkle/tabletop.lua) | Inquadratura e zoom (`tray_view`), workshop diagnostico (`tray_workshop`) |
| [`src/screens/frontend.lua`](../src/screens/frontend.lua) | Menu principale (`main_menu`), selezione partita (`campaign_select`) e impostazioni (`settings`); registrazione tramite `modules` |
| [`src/screens/folio_surface.lua`](../src/screens/folio_surface.lua) | Superfici condivise (`menu_surface`), impaginazione (`page_layout`), testo animato (`folio_ink_text`), figure e post-effetti 2D |
| [`src/screens/startup_splash.lua`](../src/screens/startup_splash.lua) | Intro LÖVE e transizione al menu |
| [`src/core/dice_runtime.lua`](../src/core/dice_runtime.lua) | Bootstrap LÖVE, lancio, presa, simulazione e collegamento a g3d |
| [`src/engine3d/bounds.lua`](../src/engine3d/bounds.lua), [`roll_resolution.lua`](../src/engine3d/roll_resolution.lua) | Contenimento e spawn (`containment`, `fps`, `spawn`); lettura delle facce (`face_state`) e risoluzione del tiro |
| [`src/engine3d/physics.lua`](../src/engine3d/physics.lua) | Corpi, collisioni e solver a passo fisso |
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
| [`src/core/renderer_lab_boot.lua`](../src/core/renderer_lab_boot.lua) | Avvio esplicito dei laboratori, esclusi dal gioco ordinario |

La produzione contiene **esattamente 30 file Lua sotto `src`**:
9 in `core`, 3 in `data`, 8 in `engine3d` (di cui 3 in `g3d`),
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

Il Tavolo del Mercante usa il layout `table_minimal`, con selezione diretta
dei dadi. La prospettiva e il picking passano da
`src/farkle/tabletop.lua` (`tray_view`),
`src/farkle/interaction.lua` (`projection`) e
`src/engine3d/g3d/scene.lua` (`camera`). Per la geometria esatta
consultare quei sorgenti e i test di proiezione, che seguono l'evoluzione
dell'inquadratura. Lo studio P1 A/B `open_codex` e il relativo avvio con
`MANUSCRIPT_UI_V2_LAYOUT_STUDY` sono stati ritirati. Il codice del layout
`single_folio` resta per ora solo come riferimento di regressione, non
è selezionabile nel gameplay normale.

## Rendering e risorse

g3d disegna il vassoio e i dadi 3D. Interfaccia, ritratto del Mercante e
illustrazioni rimangono elementi 2D.

- `lib/g3d/`, `src/engine3d/g3d/` e
  `resources/shaders/dice_lit.glsl` forniscono il rendering.
- `resources/dice/1.png` … `6.png` forniscono le facce D6.
- `resources/scenes/printshop-room.png` è il fondale della bottega senza persone;
  `resources/opponents/merchant.png` è il PNG indipendente del Mercante.
- `resources/textures/wood.png` è la texture condivisa dal tavoliere 3D
  e dal laboratorio g3d. I vecchi JPEG del Mercante per legno e intaglio
  sono stati eliminati e non devono più essere caricati.
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

luajit experiments/signs_lab/run.lua 256 20261031
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

Ogni laboratorio dispone del proprio README e viene avviato esplicitamente.

| Laboratorio | Scopo |
|---|---|
| [g3d](../experiments/g3d_lab/README.md) | Geometria, camera, texture e misure CPU di disegno |
| [FPS](../experiments/physics_lab/README.md) | Confronti isolati fra solver, presa, supporto e handoff |
| [Miniature 2D](../experiments/miniature_2d_lab/README.md) | Animazione di figure, testo ed effetti 2D |
| [FX](../experiments/fx_lab/README.md) | Prototipi di effetti grafici |
| [Segni](../experiments/signs_lab/README.md) | Simulazioni numeriche di encounter |
| [Mercante e posta](../experiments/merchant_wager_lab/README.md) | Test giocabile A/B/C: punteggio iniziale o posta diversa |
| [Encounter Research A/C](../experiments/encounter_ac_lab/README.md) | Offerte divise A e prove contese C, prototipi isolati con Farkle canonico |

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

- **Spazio:** lancio o azione contestuale consentita dal Farkle.
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
`help`, `runmenu`, `folio`, `roll`, `take`,
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
