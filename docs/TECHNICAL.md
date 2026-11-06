# Architettura e verifica tecnica di Project Folio

Percorsi di produzione ricontrollati il 6 novembre 2026. Documento tecnico di riferimento, non cronologia delle singole milestone UI.
Questo documento descrive i componenti del prototipo corrente.
La [visione](PROJECT_VISION.md) raccoglie la direzione narrativa e progettuale.

## Avvio e responsabilità

`love .` o `Avvia.cmd` eseguono `main.lua`. Il controller Farkle viene
iniettato in `src/app/dice_runtime.lua`, che registra splash, menu,
selezione della partita e impostazioni. La navigazione apre prima
`startup_splash`. L'identificatore interno della partita è `scriptorium`.

| Percorso | Responsabilità |
|---|---|
| `src/gameplay/farkle/scoring.lua` | Combinazioni valide, punti e sottoinsiemi di ID disgiunti |
| `src/gameplay/farkle/rules.lua` | Selezione, accantonamento, incasso, Farkle, hot dice e medaglie |
| `src/gameplay/farkle/commission_progress.lua` | Obiettivi e ricompense delle tre commissioni provvisorie |
| `src/features/farkle/controller.lua` | Input, richieste fisiche, esiti accettati, transizioni e registrazione eventi |
| `src/features/farkle/dice.lua` | Facce incise, filtro pesato e calcolo del rischio teorico |
| `src/features/farkle/presentation.lua`, `ui_v2/accepted_dice.lua` | Accantonamenti, provenienza dei risultati e registro dei dadi |
| `src/features/farkle/ui_v2/`, `hud_model.lua`, `folio_view.lua` | HUD, azioni, finestre, regole e folio |
| `src/app/dice_runtime.lua` | Bootstrap LÖVE, lancio, presa, simulazione e collegamento a g3d |
| `src/engine3d/` | Corpi, collisioni, lettura delle facce, contenimento, camera e rendering |
| `src/core/`, `src/data/` | Servizi condivisi, navigazione, risoluzione, impostazioni e schemi |

Il Tavolo del Mercante usa il layout `table_minimal`, con selezione diretta
dei dadi. La prospettiva e il picking passano da `tray_view.lua`,
`group_hold_projection.lua` e `g3d_camera.lua`. Per la geometria esatta
consultare quei sorgenti e i test di proiezione, che seguono l'evoluzione
dell'inquadratura.

## Rendering e risorse

g3d disegna il vassoio e i dadi 3D. Interfaccia, ritratto del Mercante e
illustrazioni rimangono elementi 2D.

- `lib/g3d/` e `resources/shaders/dice_lit.glsl` forniscono il rendering.
- `resources/dice/1.png` … `6.png` forniscono le facce D6.
- `resources/scenes/printshop-room.png` è il fondale della bottega senza persone;
  `resources/opponents/merchant.png` è il PNG indipendente del Mercante.
- `resources/textures/wood.png` è la texture condivisa dal tavoliere 3D
  e dal laboratorio g3d. I vecchi JPEG del Mercante per legno e intaglio
  sono stati eliminati e non devono più essere caricati.
- `resources/ui/menu_manuzio.png` è l'illustrazione attuale del menu.
- `resources/ui/startup_splash/` e i relativi shader appartengono allo splash LÖVE.
- Licenze e attribuzioni si trovano in `third_party/` e nelle librerie.

`geometry.lua` e `face_texture.lua` appartengono ancora alla catena
di importazione delle geometrie. I nomi storici dei componenti vanno
valutati insieme ai chiamanti prima di rimuoverli.

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
[regolamento](FARKLE_RULES.md). La distribuzione della simulazione reale
richiede misure dedicate. La ripetibilità dei test numerici riguarda
i rispettivi modelli e semi.

## Audio e collisioni

Dalla v0.1.38 i rumori del contatto fisico provengono dai callback
di sola lettura del solver, filtrati con `src/core/dice_impact_audio.lua`
e riprodotti tramite `src/core/audio_manager.lua`. Il suono del
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
[.github/workflows/lua-tests.yml](../.github/workflows/lua-tests.yml).
Dalla radice del repository, con i rispettivi runtime installati:

```sh
python3 scripts/test_versioning.py
python3 scripts/check_versioning.py

for test in tests/*_test.lua; do
  lua5.4 -e 'unpack=table.unpack' "$test" || exit 1
done

for test in tests/*_test.lua; do
  luajit "$test" || exit 1
done

luajit experiments/signs_lab/run.lua 256 20261031
```

Su Windows `scripts/test.ps1` richiama la suite Lua;
`scripts/test_luajit.py` permette di usare la DLL LuaJIT di LÖVE.

Gli smoke grafici sono in `tests/smoke/`; `scripts/run_smoke.py` avvia
il runtime con una directory di dati isolata. Le variabili diagnostiche
`MANUSCRIPT_*_SMOKE` e `MANUSCRIPT_SOURCE_CASE` selezionano gli scenari.
I comandi di acquisizione Windows sono descritti in
[WINDOWS_TECHNICAL_QA.md](WINDOWS_TECHNICAL_QA.md).

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

- `src/features/farkle/controller.lua`: precedenza degli input.
- `src/features/farkle/ui_v2/hud.lua` e `actions.lua`: comandi.
- `src/features/farkle/ui_v2/dialogs.lua`: modali e conferme.
- `src/features/farkle/medal_panel.lua`: controlli medaglie.
- `src/gameplay/farkle/rules.lua`: condizioni di gioco.
- `tests/ui_v2_interaction_inventory_test.lua`: invarianti verificati.
- [Regole Farkle](FARKLE_RULES.md) e [QA Windows](WINDOWS_TECHNICAL_QA.md).

*Nuovi controlli e modifiche alle scorciatoie devono essere sincronizzati
con la UI effettiva e i test. Questo documento non prescrive nuove regole.*
