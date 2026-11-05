# Architettura e verifica tecnica di Project Folio

Stato dei percorsi verificato il 5 novembre 2026 sulla baseline 0.1.28.
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
- `resources/merchant/` contiene ritratto, legno del tavolo e intaglio.
- `resources/ui/menu_manuzio.png` è l'illustrazione prioritaria del menu;
  `menu.png` è ancora una risorsa di compatibilità del caricatore condiviso.
- `resources/ui/startup_splash/` e i relativi shader appartengono allo splash LÖVE.
- `resources/textures/wood.png` è condivisa con il laboratorio g3d.
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

Il rapporto della [QA del 3 novembre](WINDOWS_QA_CAPTURE_REVIEW_20261103.md)
descrive le acquisizioni presenti in `audits/ui-v2-review/`.
Gli output nuovi di audit e checkpoint sono esclusi da Git.

La [versione storica del documento tecnico](https://github.com/Askeladd22/Project_Folio/blob/c3ebf78c1314b5dd4587d7bf5ec2c537b044f4c0/docs/TECHNICAL.md)
conserva le note del 15 ottobre, comprese le verifiche e i percorsi
degli audit locali di quel periodo.
