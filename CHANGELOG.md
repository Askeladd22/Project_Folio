# Registro modifiche — Project Folio

Questo file è il **registro ufficiale e cumulativo** degli aggiornamenti del gioco.
Ogni PR deve aggiungere una nuova sezione, collegata alla versione scritta in
[`version.txt`](version.txt). La CI verifica che versione e changelog siano
aggiornati insieme; le istruzioni sono in [`docs/versioning.md`](docs/versioning.md).

> Le versioni precedenti al 31 ottobre 2026 non avevano un registro versionato
> unico: gli interventi già integrati sono qui riepilogati come **baseline
> retrospettiva** tramite PR verificabili, **non** come release pubblicate.
> La versione del documento di game design è indipendente da quella del software.

## [0.1.67] - 2026-11-13

**Stato:** fix immediato della regressione di identità del layout introdotta durante la rimozione del selettore nella PR #123.

### Corretto
- `layout.build()` produce nuovamente `name='table_minimal'`, richiesto dalla validazione ufficiale.
- Un controllo dedicato impedisce che l'identificatore del layout rimanga non inizializzato.

### Verifiche
- Baseline prima della correzione: CI PR #123 fallita nel gate `tests/hud/ui_v2_layout_contract_test.lua:6` (`shipping Merchant table layout is invalid`).
- Test Lua 5.4 e LuaJIT, smoke GPU LÖVE, test Python e Windows: in attesa di verifica su questa nuova revisione.
- Nessun cambiamento a Farkle, lancio fisico o g3d.

## [0.1.66] - 2026-11-13

**Stato:** consolidamento della UI del Mercante sul solo percorso visuale `table_minimal`.

### Rimosso
- Il layout geometrico e il rendering alternativi `single_folio`, il vecchio pannello laterale e le relative verifiche di una variante non selezionabile.
- Biforcazioni di azione e registro dei dadi accantonati dipendenti dalla modalità di HUD.

### Conservato
- Folio con tasto [F], dialoghi, ricompense, contatti fisici, pulsanti e medaglie: sempre gestiti dai moduli di produzione.
- Il controller e la camera non cambiano comportamento; gli ulteriori residui del flag `minimalHud` nella proiezione 3D saranno trattati come gate distinto.

### Verifiche
- Migrati test di geometria, palette, hover, leggibilità, azioni e registro al solo layout corrente; ritirato il test del pannello laterale dismesso, con Folio e ricompense coperti dai test modali e del Mercante.
- Revisione statica dei consumatori; CI e smoke GPU del nuovo branch ancora da eseguire.
- Nessuna modifica ai punteggi Farkle, ai sei D6, ai salvataggi o alla fisica.

## [0.1.65] - 2026-11-13

**Stato:** eliminazione dei contratti orfani verso laboratori grafici/fisici già assenti dal repository; nessuna nuova meccanica o modifica ai solver di produzione.
**PR:** [#122](https://github.com/Askeladd22/Project_Folio/pull/122).

### Rimosso
- Bootstrap opzionale di `experiments.g3d_lab` / `experiments.miniature_2d_lab`, che faceva riferimento a file non più presenti.
- Quattro test headless dipendenti esclusivamente da laboratori rimossi (FPS handoff, metriche FPS, g3d performance e Segni) e test del bootstrap ritirato.
- Step CI per il benchmark Segni e la compilazione del vecchio FPS Lab, che non potevano più essere eseguiti.
- Configurazione e controlli di repository basati su file di laboratorio scomparsi.

### Modificato
- La sintassi Lua viene verificata per `src/`, `tests/` e per i sei laboratori attualmente presenti in `experiments/`.
- L'inventario dei sorgenti di produzione passa da 30 a 29 file; il test di struttura protegge ora direttamente l'isolamento dello startup.
- Documentazione tecnica aggiornata ai laboratori effettivamente presenti, con storia conservata in Git.

### Corretto
- Ripristinata la licenza MIT originaria (Copyright 2024 Dice) del codice FPS-derived rimasto in `src/engine3d/bounds.lua`, copiandola dal commit storico `5a4e60a3` in `lib/licenses/LICENSE_fps`; corretto il riferimento al file scomparso e aggiunto un gate di regressione.

### Verifiche
- Verificata via albero Git la non esistenza dei laboratori ritirati e censiti i relativi consumatori statici.
- Prima della modifica, `main@99d0e33` falliva in `tests/engine3d/physics_handoff_test.lua` per il modulo assente `experiments.physics_lab.old`.
- **CI Linux PASS** sulla revisione `0305a9aa56a4d77f80565324f8364cb2f4874881`: versionamento, lint Lua, sintassi sorgenti/test/laboratori attivi, gate geometrico, suite complete Lua 5.4 e LuaJIT, smoke GPU dei dadi, interazione/composizione Tavolo del Mercante, acquisizione frame e test Python ([run 43457355719](https://github.com/Askeladd22/Project_Folio/actions/runs/43457355719)).
- Collaudo manuale Windows/LÖVE non eseguito; non sostituito da Mesa. I benchmark dei laboratori rimossi non sono stati eseguiti perché i loro sorgenti non esistono più.
- Preservati la fisica del gioco, g3d, sei D6 e i laboratori di ricerca ancora presenti.

## [0.1.64] - 2026-11-13

**Stato:** simplification del laboratorio grafico P1, senza cambiamenti al Tavolo del Mercante in produzione.

### Rimosso
- Layout alternativo sperimentale `open_codex` e API di confronto `layout.comparison()` / `layout.variants`, privi di consumatori gameplay attivi.
- Overlay A/B di wireframe P1, relativo flag `MANUSCRIPT_UI_V2_LAYOUT_STUDY` e script di lancio.
- Test del confronto visivo scartato e riferimento Python alla sua utilità dismessa.

### Modificato
- Il test di geometria verifica ora l'attuale layout `table_minimal` alle risoluzioni supportate e la non selezionabilità di `open_codex`.
- Il test del vecchio `single_folio` non dipende più dall'alternativa `open_codex`; rimane temporaneamente per proteggere contratti ancora presenti.
- Aggiornata la descrizione tecnica dello stato dei layout.

### Verifica e limiti
- Verifiche statiche completate: nomi rimossi, riferimenti residui e mantenimento del ramo `table_minimal`.
- Gate CI mirato per il contratto geometrico in Lua 5.4 e LuaJIT, prima della suite generale (che aveva già un errore di baseline nel test fisico `physics_handoff_test.lua`).
- Test Lua/LuaJIT, smoke g3d Windows e verifica CI: non eseguiti localmente; attendono esecuzione nella pipeline e collaudo umano.
- Farkle, medaglie, Folio accessibile, interazioni dadi, g3d, salvataggi e regolamento non modificati.

## [0.1.63] - 2026-11-13

**Stato:** semplificazione interna della UI di produzione; nessuna modifica al gameplay Farkle, ai dadi fisici o al rendering g3d.

### Modificato
- Tre implementazioni duplicate del caricamento font in menu, selezione della partita e impostazioni sono state consolidate in un unico helper privato di `src/screens/frontend.lua`, senza introdurre una nuova interfaccia pubblica.
- Mantenuti ordine dei font Aldine Aetna/Cardo, recupero tramite font predefinito LÖVE e comportamento delle schermate.
- Aggiunto un controllo statico di regressione per garantire un solo proprietario del loader.

### Verifica
- Verificati staticamente i tre punti d'uso, l'unicità del loader e la conservazione dei riferimenti esistenti.
- Test Lua, avvio LÖVE e collaudo grafico Windows: non eseguiti in questa sessione; verifica CI e umana in attesa.
- Nessuna modifica alla main né integrazione di laboratori.


## [0.1.62] - 2026-11-09

Status: EX-001 standalone Merchant V4 research. No shipping Farkle, physics, assets, or UI changes.

### Added
- Opt-in initial X redraw variant, separate seeded 4-policy pilot and raw CSV reports under experiments/.
- Deterministic EX-001 regression checks and a branch-only CI pilot workflow.
- Frozen EX-001 experimental protocol; no champion was selected.

### Modified
- Merchant lab now accepts an opt-in opening_x_mode; default remains original V4.

### Verification
- Prior exact enumeration: 27/95 opening auto-win on the full box.
- New Lua/CI pilot test results: pending branch push and workflow execution.
- Human playtests, confirmatory holdout and gameplay integration: not performed.

## [0.1.61] - 2026-11-09

**Stato:** istituzione del laboratorio R&D documentale; nessuna modifica
a gameplay, fisica, asset o codice eseguibile.

### Aggiunto

- Cartella research/ con indice, protocollo di ricerca e gate di revisione;
  inventario comparativo dei prototipi, prima domanda RQ-001 e registro decisioni.
- Brief Deep research, istruzioni per Progetto ChatGPT, protocollo simulazioni
  e schede per fonti, esperimenti e playtest.
- Distinzione esplicita tra dati simulati, playtest umani e risultati
  precedenti non replicati; niente promozione automatica di prototipi.

### Modificato

- docs/README.md indirizza al nuovo indice di ricerca e segnala
  che il precedente corpus non è presente in main.

### Corretto

- CI: il test del loader GLB (dipendente da LuaJIT FFI) viene eseguito
  nel blocco LuaJIT, non nel blocco incompatibile Lua 5.4; loader e
  gameplay non sono modificati.

### Verifiche

- Esaminati README, documenti canonici, script simulazioni, test e workflow
  esistenti sul commit di base 2239cd55; non sono state eseguite
  simulazioni, regressioni o playtest per questa PR.
- Da verificare: GitHub Actions della PR e prima esecuzione del baseline RQ-001.

## [0.1.60] - 2026-11-08

**Stato:** ricerca isolata per un sistema di encounter; gameplay e
fisica del gioco principale non modificati.

### Aggiunto

- Laboratorio A: offerte divise fra due prove, scelta del Rivale,
  distribuzione della posta e maggioranze su tre obiettivi.
- Laboratorio C: tre prove contese, sigilli progressivi, risposta
  strategica del Rivale e due obiettivi necessari per vincere.
- Interfaccia LÖVE 2D navigabile A/C, uso del Farkle canonico,
  seed ripetibili, test, simulazioni A/C e workflow di regressione.
- Ribilanciata la regola A: il proponente ottiene 1 sigillo fisso di
  iniziativa e una previsione pubblica della scelta del Rivale;

### Verifiche

- Test Lua 5.4, LuaJIT, simulazioni e smoke grafico affidati alla CI.
- Da valutare playtest umani, strategie dominanti e bilanciamento.

## [0.1.59] - 2026-11-08

**Stato:** semplificazione della posta nel Merchant Duel Lab V4;
nessuna modifica al Farkle principale né alla fisica del gioco.

### Modificato

- Eliminate le scelte obbligate «Accetta / Rifiuta» e i rialzi
  imposti dal Mercante prima del lancio.
- Il giocatore può aumentare la posta da 4 a 8 soldi a sua scelta;
  il Mercante pareggia immediatamente e non blocca la mano.
- Aggiornati interfaccia, logica, simulazione, test e registro monetario;
  non esistono più rialzi in sospeso o restituzioni per rifiuto.
- Risultati di bilanciamento con la vecchia meccanica da ricalibrare.

### Verifica

- Test Lua 5.4, LuaJIT, calibrazione e smoke LÖVE da eseguire in CI.

## [0.1.58] - 2026-11-08

### Ricerca

- Avviato confronto di bilanciamento tra punteggi Farkle e valori dei token
  del Mercante, senza cambiare le regole dei dadi né la posta monetaria.
- Confrontati profili iniziali e varianti a elevata dispersione dei
  valori, mantenendo venti token totali e tre X.
- Selezionato per la V4 il profilo tail: V10×6, V20×5, V25×4,
  V55×2 e X×3. Il punteggio medio dell'offerta iniziale resta vicino
  all'originale, mentre la massima offerta iniziale passa da 80 a 110.
- Nella simulazione preliminare a 200 seed, la policy balanced ha
  registrato 50% vittorie Incisore senza rialzi e 51,5% con rialzi.
  I valori sono diagnostici, non un giudizio definitivo sul bilanciamento.
- Aggiunta simulazione a seed appaiati per tre policy Farkle e
  con/senza rialzi, senza selezione del profilo dal menu di gioco.

## [0.1.57] - 2026-11-08

### Corretto

- Test della nuova plancia Merchant Duel V4: selezione del seed 202
  mediante il centro del pulsante anziché lo spazio fra i pulsanti.
- Nessuna modifica a gameplay, asset, valuta, cassa o controlli.

## [0.1.56] - 2026-11-08

**Stato:** redesign del Merchant Duel Lab e rimozione prototipi scartati.
Nessuna modifica al gameplay principale.

### Cambiato

- Laboratorio avvia direttamente l'unica modalità giocabile V4. Rimossa la
  selezione dei prototipi V2, V3 standalone e Il Correttore.
- Ridisegnata la plancia LÖVE riutilizzando gli asset Project Folio:
  printshop-room.png, merchant.png, Aldine Aetna e Cardo.
- Separata la gerarchia di offerta in punti e piatto in soldi: spiegazione
  del rialzo non ancora chiamato (6 soldi, 8 dopo accettazione).
- Dadi e patrimonio più evidenti; cassa dettagliata e libro mastro sono
  pannelli opzionali richiamabili durante la partita.

### Rimosso

- Codice V2/Correttore, UI e registri V3 come modalità autonoma, insieme
  ai test dei prototipi ritirati. L'offerta, la cassa e la policy V3 restano
  nel motore perché sono utilizzate dalla V4.
- Comandi CLI --simulate e --analyze dei prototipi scartati.

### Verifica

- Generatore deterministico estratto in rng.lua senza alterarne la sequenza.
- Nuovo test di scena e mantenimento dei test monetari e del motore V3.
- Smoke LÖVE e controlli Lua 5.4/LuaJIT dedicati.

## [0.1.55] - 2026-11-08

**Stato:** prototipo opt-in Merchant Duel V4: valuta veneziana e puntate.
Non attivo nel gioco principale.

### Aggiunto

- V4 del Merchant Wager Lab basata sulla V3, con Farkle canonico a sei D6
  e cassa del Mercante invariata (20 token).
- Lira di piccoli come moneta di conto: 1 lira = 20 soldi = 240 denari;
  tutti i valori monetari memorizzati in denari interi.
- Patrimonio iniziale di 1 lira per contendente, ante di 2 soldi a testa per
  mano e unico rialzo opzionale di 2 soldi per contendente prima del primo tiro.
- Decisione autonoma e documentata del Mercante su proposta, chiamata
  e rifiuto del rialzo, basata su offerta e cassa pubbliche.
- Piatto liquidato dopo ogni mano, ritiri, restituzione del rialzo
  non chiamato, blocchi contro doppi trasferimenti e controllo di conservazione.
- UI e libro mastro dedicati, CSV V4 separati e confronto con/senza rialzi.
- Test isolati, verifica della V3 originale e LÖVE smoke.
- Simulatore A/B accoppiato con tre policy Farkle, report headless, CSV
  delle decisioni sui dadi e delle controfferte della V4.
- Corretto un duplicato preesistente del titolo 0.1.49 nel changelog:
  la nota storica sul Merchant Wager non viene più conteggiata come release autonoma.

### Invariato

- Punteggi e RNG Farkle di produzione, fisica 3D, regole e composizione
  della cassa V3, tutte le altre modalità sperimentali.
- Nessun acquisto, prestito, all-in o economia permanente.

## [0.1.54] - 2026-11-07

**Stato:** prototipo asimmetrico P4ND0RA contro Farkle; solo laboratorio,
non integrato nel gioco principale.

### Corretto

- Sostituite le carte di prova del giocatore con **sei D6 Farkle**,
  accantonamento, rilancio, hot dice, Farkle e incasso.
- Rimossi il deck sperimentale e i comandi di Combat senza dadi;
  conservato il motore originale P4ND0RA per i test headless.
- Corretto il pannello del sacchetto: conteggi ora riferiti
  ai token effettivamente rimasti disponibili.

### Aggiunto

- Adattamento dichiarato: **5 punti Farkle incassati = 1 Combat**,
  con possibilità di spendere 20/30 punti per neutralizzare/scartare
  un token e EMP che riduce i dadi al tiro iniziale successivo.
- Modulo Farkle basato sullo snapshot **identico byte per byte**
  a `src/farkle/rules.lua`; controllo `cmp` in CI.
- Test dedicati per seed, banking, Farkle, contromisure,
  EMP, sincronizzazione e smoke del rendering LÖVE.

### Limiti

- La riproduzione 1:1 riguarda il comportamento del boss, non
  le azioni del giocatore: il collegamento al Farkle è una
  **nuova meccanica sperimentale** con dadi virtuali 2D.
  Nessuna variazione intenzionale al gameplay di produzione.

## [0.1.53] - 2026-11-07

**Stato:** prototipo opt-in “Il Correttore” nel Merchant Wager Lab; non attivo nel gioco.

### Aggiunto

- Aggiunta una modalità autonoma con rivale a sei dadi, punteggio 4/5/6,
  decisione forzata sotto 300 punti e decisione D6 da 300 punti.
- Aggiunti acquisto di fogli a 500 punti, furti su Farkle, chiusura
  dell'incontro, spareggio sui punti non spesi, feedback soggettivo e conteggio
  delle opportunità decisive per confrontare la percezione con la soglia del 40%.
- Aggiunti registri CSV versionati separati per partite, eventi e feedback,
  oltre a test isolati del prototipo.

### Verifiche

- Passati i test isolati Correttore (logica e UI), V2 e V3 con il LuaJIT
  incluso in LÖVE.
- Suite Lua completa: 105/106 test file passati. L'unico fallimento è il
  preesistente `fps_wall_bounds_test.lua`, che richiede la globale `arg`
  assente nel runner standalone.
- Il controllo visuale manuale con finestra LÖVE non è stato eseguito.

## [0.1.52] - 2026-11-07

**Stato:** redesign della UI opt-in V3 del Merchant Wager Lab; non attivo nel gioco.

### Modificato

- Ridisegnata la schermata V3 per rendere evidenti fase, mani vinte, offerta,
  risultato da battere, rischio Farkle e dadi selezionati/accantonati.
- Resi contestuali i comandi di gameplay; aggiunti riepiloghi leggibili per
  mano/incontro, cronologia sintetica, dettagli espandibili della cassa e
  scorciatoie per navigare la V3.

### Corretto

- Il click sul campo seed non viene più interpretato come una selezione di seed;
  ora è possibile modificare manualmente il valore nel setup V2 e V3.

### Verifiche

- Passati i test mirati V2/V3, inclusi messaggi, azioni contestuali e viewport
  per 1280×720, 1600×900 e 1920×1080.
- Passato uno smoke test del ciclo di disegno LÖVE con backend grafico simulato
  per setup, turno, controfferta, riepiloghi e dettagli cassa.
- Passato il controllo sintattico Lua, `git diff --check` e il controllo
  versione/changelog.
- Non eseguito un test visivo manuale con finestra LÖVE; la suite completa ha
  un test estraneo al laboratorio che richiede `arg` nel runner standalone.


## [0.1.51] - 2026-11-07

**Stato:** esperimento opt-in nel Merchant Wager Lab; non attivo nel gioco.

### Aggiunto

- Aggiunta la modalità V3 "cassa tipografica", separata dalle partite A/B/C,
  con Farkle di produzione per l'Artista, cassa pubblica, controfferte e
  incontro al meglio di tre mani.
- Aggiunti CSV V3 indipendenti per incontro, mani, sequenza di decisioni e
  feedback; i registri V2 e `runs.csv` restano separati.
- Aggiunti test V3 per cassa, probabilità, flussi casuali indipendenti,
  controfferte, tie-break, assegnazione dei fogli e registrazione.

### Corretto

- Resa esplicita nella UI la probabilità di sorpasso e la soglia deterministica
  del Mercante prima di ogni controfferta.
- Registrata la sequenza ordinata delle decisioni dell'Artista e del Mercante
  invece di mantenere le decisioni soltanto in memoria.

### Verifiche

- Passati i test mirati V2 e V3 con la LuaJIT inclusa in LÖVE.
- Passato il controllo sintattico dei file Lua V3 e `git diff --check`.
- Suite completa Lua: 103/104 file; `fps_wall_bounds_test.lua` non passa nel
  runner standalone perché si aspetta la globale `arg`. Lua 5.4 non è
  disponibile; il runtime LuaJIT standalone non è installato.


## [0.1.50] - 2026-11-07

### Aggiunto

- Esteso il Merchant Wager Lab con le condizioni A (controllo), B (30 punti
  iniziali al Mercante) e C (4 fogli totali a testa), selezione di seed,
  flussi casuali indipendenti, feedback soggettivo e analisi CSV per variante.
- I nuovi risultati usano CSV versionati, senza sovrascrivere i registri
  storici del laboratorio o il registro della modalità principale.

### Corretto

- Registrate in Git le rinomine che cambiavano solo maiuscole/minuscole
  (`docs/*.md`, `lab*.md`, `results_2026_10_31.md`): su file system
  sensibili alle maiuscole la CI vedeva ancora i vecchi nomi.

### Nota retrospettiva non versionata — Merchant Wager Lab (2026-11-08)

### Aggiunto

- Laboratorio isolato `experiments/merchant_wager_lab/` ("Il Mercante e la
  posta"): incontro sperimentale Artista contro Mercante con posta di fogli
  di prova, rialzo Alzo/Vedo/Passo, tre round, registro CSV dei playtest,
  simulazione automatica e modello di feedback. Riusa senza modifiche il
  regolamento Farkle di produzione; nessun modulo di `src` cambia.
- Test `tests/labs/merchant_wager_lab_test.lua`.

## [0.1.49] - 2026-11-07

### Aggiunto

- Laboratorio isolato `experiments/p4ndora_1to1/`: simulazione
  del boss P4ND0RA con venti token, difficoltà originali, quattro fasi,
  abilità speciali, Authority/HP/scudi, contromisure, escalation e seed.
- Interfaccia sperimentale LÖVE 11.x per avanzare manualmente le azioni
  e risolvere il costo dei missili; nessuna modifica al Farkle di produzione.
- Test di regressione headless per difficoltà, token, casualità riproducibile,
  attacchi, EMP, missili, CQC, nucleare, upgrade ed esaurimento del sacchetto.

### Limiti

- Non è il client completo di Star Realms/Tabletop Simulator: gli effetti delle
  carte e i conteggi delle basi restano input manuali. Le normalizzazioni
  rispetto allo script originale sono documentate nel README del laboratorio.

## [0.1.48] - 2026-11-07

### Modificato

- Uniformati i nomi dei file di documentazione e dei laboratori in
  `snake_case` inglese; rinominati i launcher in `run_game.cmd`,
  `run_lab.cmd` e `run_in_game.cmd`.
- Il workflow CI usa `lua_tests.yml`; gli script di build FPS sono
  `build_linux.sh` e `build_windows.ps1`.
- Aggiornati tutti i riferimenti interni, i link Markdown, i test, i runner
  e la mappa tecnica. I nomi richiesti da LÖVE, gli asset e i file vendor
  restano invariati.

## [0.1.47] - 2026-11-07

### Modificato

- Riorganizzate cartelle e sottocartelle per area, senza alias dei vecchi
  percorsi. In `src` le cartelle passano da 11 a 6 (`core`, `data`,
  `engine3d`, `engine3d/g3d`, `farkle`, `screens`): tutto il codice Farkle,
  dalle regole all'HUD, sta in `src/farkle`; splash, menu e superfici del
  folio in `src/screens`; il bootstrap `dice_runtime.lua` in `src/core`;
  la traduzione inglese è `src/data/locale_en.lua`. Restano 30 file Lua.
- I 102 test Lua sono divisi in `tests/<area>/` (core, data, engine3d,
  farkle, hud, screens, repo, labs); i test Python stanno in `scripts/tests/`
  e il runner LuaJIT si chiama `scripts/run_lua_tests.py`.
- `core.lua` (vettori e prototipi) è passato in `lib/core.lua`, le licenze di
  terzi in `lib/licenses/`, la shader `dice_glow.glsl` in `resources/shaders/`.
- Aggiornati import, CI, runner, checkpoint, esperimenti e documentazione;
  la mappa delle cartelle è in `docs/TECHNICAL.md` ed è verificata dal test
  strutturale. Nessuna modifica intenzionale a gameplay, fisica o asset.

### Rimosso

- `probe_tmp.lua`, sonda temporanea non più funzionante che puntava a moduli
  eliminati.

## [0.1.46] - 2026-11-07

### Modificato

- Consolidati da **60 a 30** i file Lua di produzione sotto `src`, senza
  alias di compatibilità: menu e impostazioni, superfici del folio, UI Farkle,
  presentazione, tavolo e servizi condivisi sono raccolti per responsabilità.
- Aggiornati import, registrazione dinamica delle schermate, test,
  esperimenti, lint CI e documentazione. Rimosse le cartelle rimaste vuote.
- Aggiunto un controllo dell'elenco esatto dei 30 sorgenti, delle API esportate
  e del riuso della stessa superficie tra menu e folio.
- Aggiornata la mappa tecnica con tutti i moduli e le rispettive sezioni.
  Nessuna modifica intenzionale a gameplay, fisica, asset o salvataggi.

### Corretto

- Il caricamento delle texture delle geometrie avviene al disegno, evitando
  di inizializzare la grafica negli import headless dei nuovi moduli accorpati.
- Riallineati mock e controlli testuali alle sezioni consolidate; le verifiche
  del menu restano limitate al menu, senza confonderlo con le impostazioni.

### Verifiche

- Sintassi LuaJIT verificata su **161/161** file di produzione, test e laboratori.
- Luacheck 1.1.2 sui tre moduli previsti dalla CI: nessun avviso o errore.
- Suite LuaJIT: **102/102** test con `arg` inizializzato come nel runtime CLI.
  Il runner DLL del repository continua a dare **101/102** perché non
  inizializza `arg` nel test preesistente `fps_wall_bounds_test`.
- Passati gli smoke LÖVE del frontend, del lancio fisico dei sei dadi e della
  UI V2 a **1920x1080 e 1280x720**, inclusi presa, annullamento, accessibilità,
  pausa, folio e ricompense.
- Il conteggio esclude librerie, test ed esperimenti. Restano aperti i tre
  smoke diagnostici già documentati nella v0.1.45 (`partial`, `face-gate`,
  `integration`); non sono stati rieseguiti in questo aggiornamento.

## [0.1.45] - 2026-11-07

### Modificato

- Ridotti i sorgenti Lua di produzione da **89 a 60**, unificando moduli
  affini di regole, interazioni, renderer, HUD, configurazioni e servizi.
- Aggiornati chiamanti, test, laboratorio g3d, lint della CI e documentazione.
  Le sezioni restano nominate e separate; regole, asset e formato dei
  salvataggi non sono stati intenzionalmente modificati.
- Resa accessibile dal README la mappa del codice, con collegamenti diretti
  ai moduli principali e indicazioni sulle rispettive sezioni.

### Corretto

- Corretto l'accesso a `dice_schema.roll.pool` nel bootstrap; i test controllano
  ora anche la compilazione del punto di avvio e i percorsi dei moduli nella CI.

### Verifiche

- Sintassi verificata su **191/191** file con LuaJIT e Lua 5.4.6; lint dei
  moduli consolidati con Luacheck 1.1.2 senza avvisi o errori.
- Suite LuaJIT: **100/102** test passati. I due fallimenti sono preesistenti:
  il runner DLL non inizializza `arg` per `fps_wall_bounds_test` e il confronto
  testuale di `ui_v2_visual_review_wiring_test` dipende dai terminatori LF.
  Entrambi passano correggendo rispettivamente l'ambiente e i terminatori.
- Suite Lua 5.4: **100/102** test passati. La baseline presenta gli stessi
  problemi: il test GLB richiede `ffi` di LuaJIT, mentre il test della review
  UI dipende dai terminatori LF. Il test GLB passa con LuaJIT.
- Passati gli smoke LÖVE del frontend, del lancio sul vassoio, della UI V2 a
  1920x1080 e 1280x720, dello shader GPU e dei sei ritratti dei dadi.
  Identiche le 32 mappe hitbox confrontate; le immagini possono differire
  per animazione e FPS.
- Confrontati con la baseline **55.986** mani ordinate e **1.554** insiemi di
  opzioni per ID fisici, senza differenze nei risultati.
- Gli smoke diagnostici `partial`, `face-gate` e `integration` continuano a
  fallire esattamente come sulla baseline isolata, rispettivamente per
  `kept body changed`, `Technical failure has no usable actions` e
  `love.graphics.getImage` assente.

## [0.1.44] - 2026-11-07

### Modificato

- Ridotti di **7** i file di produzione unendo le particelle al loader dei
  fondali, il filtro dei contatti all'audio manager, i dati campagne al loro
  schema e le configurazioni di dadi e impostazioni in un unico schema per area.
- Aggiornati chiamanti, test e laboratorio; valori, comportamento runtime,
  salvataggi e asset sono rimasti invariati.

### Verifiche

- Passati 99/102 test LuaJIT: i tre fallimenti coincidono con la baseline
  (`fps_wall_bounds_test`, `merchant_refinement_test`,
  `ui_v2_visual_review_wiring_test`); 10 test mirati passano.
- Passati gli scenari smoke LÖVE del frontend, del lancio fisico sul vassoio
  e della UI V2 con presa reale a 1920x1080 e 1280x720. Una ripetizione del
  frontend ha completato tutti gli scenari ma ha richiesto la chiusura manuale
  della finestra di test rimasta aperta.

## [0.1.43] - 2026-11-07

### Aggiunto

- Controllo strutturale delle nuove posizioni dei moduli e dell'assenza
  di copie nei vecchi percorsi.

### Modificato

- Raggruppati il renderer g3d e i suoi componenti in `src/engine3d/g3d/`
  e le interazioni fisiche dei dadi in `src/features/farkle/interaction/`.
- Aggiornati import, test, laboratorio g3d e documentazione tecnica;
  nessuna modifica a regole, fisica, resa grafica, asset o salvataggi.

### Verifiche

- Suite LuaJIT: 99/102 file superati; restano i tre fallimenti già presenti
  prima del riordino (`fps_wall_bounds_test`, `merchant_refinement_test`,
  `ui_v2_visual_review_wiring_test`). Il test FPS passa inizializzando
  `arg`, assente nel runner basato sulla DLL.
- Passati gli smoke LÖVE del frontend, della UI V2 a due risoluzioni,
  della presa fisica, del vassoio e del renderer GPU; il laboratorio g3d
  si avvia e si chiude correttamente.
- Lo smoke HUD storico fallisce su `H.tray` assente anche sulla copia isolata
  del commit precedente; la review della UI V2 corrente passa.

## [0.1.42] - 2026-11-06

### Unificazione dei documenti: 12 → 7 file

- Unificati `PROJECT_VISION.md` e brainstorming fondativo v0.3:
  visione aggiornata, protagonista ispirato a Dürer, tre pilastri,
  Folio, poste, incontri e riferimenti studiati. Fonte originale
  reperibile tramite permalink Git, senza documento concorrente.
- Accorpati `TYPOGRAPHY.md` e `OPPONENT_PORTRAIT_PIPELINE.md`
  in `ART_DIRECTION.md`, preservando font, licenze, asset e contratti.
- Accorpati `CONTROLS.md` in `TECHNICAL.md` e
  `UI_V2_VISUAL_REVIEW.md` in `WINDOWS_TECHNICAL_QA.md`.
- Rimossi i cinque duplicati dopo la fusione; aggiornati indice,
  riferimenti del versionamento e i due test che verificano
  i documenti con asserzioni dirette.
- Rimangono indipendenti regolamento Farkle, versionamento e
  le fonti storiche in `research/`. Nessuna modifica al motore,
  al gameplay, al rendering, all'audio o agli asset.

## [0.1.41] - 2026-11-06

### Documentazione essenziale: 41 → 12 file in docs/

- `docs/` ridotta da **41 a 12 file**: mantenuti soltanto visione,
  brainstorming, regolamento Farkle, controlli, architettura,
  arte, tipografia, pipeline PNG avversari, versionamento e due
  guide per il collaudo Windows.
- **29 file rimossi da `docs/`**: nove spostati in `research/`
  (cinque studi e quattro PDF di giochi storici), gli altri 20
  documenti/asset superati ritirati dalla working tree e recuperabili
  dalla cronologia Git, senza cancellare commit passati.
- Riscritti indice `docs/README.md`, guida artistica e pipeline PNG
  per descrivere la scena Mercante effettiva, non procedure e fondali
  del 2026-10-31; aggiunto riferimento al protagonista originale
  ispirato ad Albrecht Dürer nella visione di progetto.
- Aggiornati i riferimenti fra regolamento Farkle, visione, studi
  di encounter e laboratorio Segni; aggiornato il documento di
  versionamento e una descrizione tecnica dell'audio fisico.
- PDF storici trasferiti per identificatore Git senza ricodifica;
  nessuna licenza, asset runtime o screenshot QA attivi rimossi.
- Nessuna modifica a regole, score, Farkle, bot, UI runtime,
  fisica, renderer g3d, input, audio, asset binari del gioco
  o impostazioni. Controllare Lua 5.4/LuaJIT, smoke e test versione.



### Pulizia conservativa della documentazione storica

- Eliminati **13 documenti Markdown obsoleti** dalla working tree
  (roadmap UI P0/P1 e F6/F9, vecchia matrice degli input, vecchi
  rapporti di pulizia, snapshot incompleto QA, beta Monaco rimossa,
  promozione Farkle superata, istruzioni di installazione del vecchio
  menu e note g3d anteriori alla dismissione del painter).
- Nessun documento di regole Farkle, visione, storia editoriale,
  ricerca su Segni, medaglie, direction art, licenze o diagnostica
  attiva è stato rimosso; i vecchi documenti rimangono recuperabili
  dai commit precedenti della cronologia Git.
- Aggiunto `docs/CONTROLS.md`: piccolo inventario aggiornato dei
  comandi che sostituisce la matrice legata all'HUD pre-cutover.
  Il test dei controlli punta al nuovo documento, mantenendo
  invariate tutte le asserzioni sui pulsanti e sugli input attivi.
- Riscritto l'indice `docs/README.md` per separare contratti
  correnti, QA e ricerca; corretti i link storici nei documenti
  rimasti usando permalink a commit immutabile.
- **Solo documentazione e verifica statica:** nessuna modifica a
  gameplay, fisica, mesh, g3d, HUD di produzione, dati o asset.

## [0.1.39] - 2026-11-06

### Migliorata la leggibilità del tavolo
- Spostato il badge FPS opzionale sotto la scheda punteggio, evitando la sovrapposizione con assicurati e rischio.
- Aumentate le dimensioni richieste per etichette e valori della scheda; il fitting esistente continua ad adattare il testo alle risoluzioni e alle impostazioni di accessibilità.
- Riallineati i controlli dello smoke HUD al flusso attuale (catalogo medaglie F7, persistenza della scheda regole e cleanup delle prese fisiche); corretto il controllo geometrico per confrontare i dadi proiettati con la finestra, non con il solo piano del tavolo.
- Passati `tests/ui_v2_minimal_table_test.lua` e `tests/merchant_table_composition_test.lua` via LuaJIT LÖVE; cattura LÖVE completata con 32 frame a 1920×1080 e 1280×720, inclusi FPS attivi e presa fisica.
- Le catture aggiornate sono state controllate visivamente; checklist QA complessiva e sessione manuale di 50 lanci restano aperte. Nessuna modifica a dimensioni dei dadi, mesh, collisioni o regole.

## [0.1.38] - 2026-11-06

### Audio dei dadi sincronizzato alla fisica
- I contatti reali del solver (pavimento, bordi e coppie di dadi)
  espongono callback di sola lettura, senza variare impulsi o geometria.
- Un filtro per dado/superficie sopprime il crepitio da micro-urti;
  il volume degli impatti dipende dalla velocità di avvicinamento.
- La riproduzione di un lancio completo al rilascio del mouse o al
  comando automatico è eliminata: brevi frammenti OGG partono
  quando il dado colpisce davvero il tavolo.
- Un unico suono di scuotimento per volta, con dissolvenza al mouse
  fermo, su rilascio e annullamento; code degli impatti accorciate.
- Varianti audio deterministiche separate dal RNG di gioco e limite
  invariato di voci simultanee; conservati mute e volumi esistenti.
- Aggiunti test headless per cooldown, attenuazione, fine scuotimento,
  eventi di collisione e invarianza della fisica dei D6.
- Nessuna modifica a regole Farkle, risultati, input, g3d o asset binari.

## [0.1.37] - 2026-11-06

### Refinement del tavolo del Mercante
- Eliminati i piccoli glifi e trattini sotto i dadi: l'eleggibilità
  è evidenziata sulle superfici g3d; hover e selezione seguono la
  sagoma proiettata, senza toccare picking e punteggi.
- Tavoliere visivamente meno invadente e spostato 44 px più in basso
  nel riferimento 1920×1080; superficie fisica, collisori e coordinate
  dei dadi sono rimasti identici.
- Bordo anteriore e sponde decorative più sottili, senza alterare le pareti
  di collisione della fisica.
- PNG avversario più grande (circa +16%), ancorato dietro il tavolo
  con logica condivisa e proporzioni native; il Mercante resta separato
  dal fondale, sostituibile con altri avversari.
- Fondo leggermente più caldo, attenuazione localizzata del torchio a
  destra e due pannelli superiori meno dominanti; scorcio a sinistra conservato.
- Aggiornati e aggiunti test della prospettiva, della gerarchia dei marker,
  del posizionamento avversario e delle risoluzioni 720p, 1080p e ultrawide.
- Immutati regole Farkle, fisica, input, accantonamento, dadi, renderer g3d,
  salvataggi e font Aldine Aetna/Cardo.

## [0.1.36] - 2026-11-06

### Fix crash: caricamento di texture Merchant eliminate
- Eliminato il caricamento di `resources/merchant/wood-floor.jpg`,
  rimosso durante la separazione degli asset grafici. Il tavolo g3d
  ora usa la texture esistente `resources/textures/wood.png`.
- Eliminato il secondo riferimento obsoleto a
  `resources/merchant/carving.jpg`, il modello di intaglio 3D
  associato e la sua geometria ormai priva di chiamanti.
- Aggiornate le protezioni degli asset del repository in funzione della
  scena moderna a livelli: `resources/scenes/printshop-room.png`
  e `resources/opponents/merchant.png`. Rimosso dal test il
  vecchio `resources/ui/menu.png` anch'esso eliminato in precedenza.
- Aggiunta regressione specifica sul renderer per assicurare che
  nessuna delle immagini JPG rimosse possa causare nuovamente un crash.
  Immutati gameplay Farkle, fisica, camera, dadi, punteggi e input.

## [0.1.35] - 2026-11-06

### Aldine Aetna + Cardo: facsimile e fallback per glifo
- Introdotto **Aldine Aetna Regular**, facsimile Source Library (2026) dei caratteri
  romani di Francesco Griffo per il `De Aetna` stampato da Aldo Manuzio (1496).
  Font e attestazione CC0 inclusi nei file del progetto.
- **Cardo Regular**, carattere romano di supporto, e relativa licenza SIL OFL 1.1:
  `Font:setFallbacks()` interviene sui glifi non coperti da Aetna, senza
  sostituire interamente titoli, pulsanti o stringhe miste.
- Centralizzato il caricamento in `src/core/typography.lua`; adeguati schema
  menu, selezione campagna, impostazioni, splash e presentazione Farkle,
  con verifica headless dei font e del fallback.
- Nessuna modifica a Farkle, fisica, renderer dei dadi, HUD hitbox o salvataggi.
- Da verificare otticamente su Windows soprattutto le maiuscole, gli accenti
  italiani, i simboli e l'interlinea nei testi lunghi.

## [0.1.34] - 2026-11-06

### Carattere Antiqua e asset modulari per il Mercante
- Sostituito l'uso del gotico nelle schermate di menu, selezione della commissione e impostazioni con **Goudy Bookletter 1911**, una romana Antiqua moderna di ispirazione umanistica (SIL OFL 1.1). Aggiornati anche splash, HUD, dialoghi, dadi accantonati e notifiche al medesimo font: non e' un carattere storico autentico di Griffo.
- Ricalibrato il busto degli avversari come strato visivo 2D centrato sull'asse del tavolo, con la base parzialmente nascosta dal tavolo g3d.
- Preparati `resources/scenes/printshop-room.png` e `resources/opponents/merchant.png` come **pacchetto grafico separato**, da estrarre nei percorsi gia' previsti dalla PR #97. Il codice passa automaticamente ai due strati se entrambi i file sono presenti; altrimenti resta la scena originale per il solo Mercante. I PNG **non** sono inclusi nella PR.
- Aggiunti test per l'adozione uniforme di Antiqua e per l'ancoraggio della figura. Regole Farkle, dadi fisici, telecamera, input e salvataggi invariati.

## [0.1.33] - 2026-11-06

### Avversari con PNG intercambiabili
- Architettura visiva a due livelli: fondale pulito `resources/scenes/printshop-room.png` e ritaglio trasparente `resources/opponents/<id>.png`, caricati separatamente e riutilizzabili senza modifiche alla scena.
- Il controller accetta `params.opponent_id` o `setOpponentVisual(id)`; il ritaglio condivide scala, posizione e ancoraggio con ogni futuro avversario.
- L'immagine attuale `table-host.jpg` ha il Mercante incorporato e rimane solo come compatibilità per lui. Gli altri personaggi richiedono entrambi i nuovi asset: in loro assenza il loader segnala l'errore, senza sovrapporre il nuovo avversario al vecchio Mercante.
- Aggiunti documentazione dell'asset pipeline e test di isolamento, swapping, limiti geometrici, caricamento cache e ID sicuri. Nessuna nuova illustrazione è stata inserita.
- Nessun intervento su regole Farkle, dadi 3D/g3d, fisica, hitbox o salvataggi.

## [0.1.32] - 2026-11-05

### Selezione sul tavolo del Mercante

- Un segno sotto i dadi indica quali possono contribuire al punteggio. Il
  contorno segue il dado sotto il puntatore. Il pulsante Accantona mostra
  i punti della selezione e distingue un gruppo incompleto da uno impossibile.
- Il Mercante e il pavimento della stanza riempiono l'inquadratura. La nuova
  illustrazione lascia visibile il berretto ed elimina il dado rosso dipinto.
  Il tavolo 3D si raccorda alla stanza e i comandi sono vicini al suo bordo.
- Verifica di selezione, contorni e composizione con le suite Lua e con
  catture LÖVE/Mesa in formato 16:9 e ultrawide.

## [0.1.31] - 2026-11-05

### Ombre dei dadi sul tavolo
- Ombra proiettata sul legno dalla luce principale. La posa del dado determina
  il contorno, mentre la distanza dal piano regola intensità e sfumatura.
- Lo smoke GPU confronta i pixel del tavolo vuoto con quelli di un dado
  appoggiato e di uno sollevato.

## [0.1.30] - 2026-11-05

### Dadi in osso inciso
- Materiale color osso invecchiato con patina deterministica per dado,
  porosità tenue e punti incavati circondati da anelli.
- Il renderer usa il valore effettivo di ogni faccia, inclusa l'incisione
  2 → 1 della build. Il modello base segue le coppie opposte 1/6, 2/5 e 3/4.
- Miniature dei dadi accantonati allineate al materiale e allo smusso del tavolo.
- Verifica headless di mappa e configurazione del materiale, più smoke GPU
  con LÖVE e Mesa per shader, facce e miniature.
- Aspetto finale da confrontare con il riferimento fotografico su Windows.

## [0.1.29] - 2026-11-05

### Pulizia del repository
- Rimossi il modulo di illuminazione CPU inutilizzato `src/engine3d/light.lua`
  e la texture senza utilizzatori `resources/textures/felt.png`.
- Il laboratorio g3d riutilizza `resources/textures/wood.png` per piano e bordi.
  Rimossi la texture dedicata `walnut.png` da 81.056.842 byte e il relativo
  file di provenienza. Il cambio di materiale riguarda il laboratorio isolato.
- Aggiornati i controlli di conservazione delle risorse per proteggere
  il legno condiviso e quello del Tavolo del Mercante.
- La regola `/audits/` esclude nuovi checkpoint e catture locali.

### Documentazione
- Aggiunto l'indice `docs/README.md` e collegato dal README principale.
- Allineato il regolamento alla selezione diretta introdotta nella 0.1.23.
- Riscritto `TECHNICAL.md` sui percorsi correnti, con collegamento allo
  snapshot storico del documento.
- Corretti i collegamenti relativi risolvibili. Le citazioni di evidenze
  locali assenti sono conservate come percorsi testuali nei rapporti.

### Verifiche
- Ricontrollati import, percorsi delle risorse e collegamenti Markdown.
- Verifica headless demandata alla CI GitHub per indisponibilità
  dell'ambiente locale di esecuzione.
- La nuova venatura del laboratorio richiede controllo visivo in LÖVE.

## [0.1.28] - 2026-11-05

### Allineamento tavolo del Mercante
- Corretta la traslazione verso destra della placca inferiore e del
  pulsante singolo: il loro centro ora coincide con l'asse del tray
  fisico (x=960 nelle coordinate virtuali 1920×1080).
- Ricentrata la composizione completa quando sono presenti
  più azioni; spostato il registro dei dadi accantonati per
  evitare che tocchi la placca.
- Messaggio contestuale ricentrato. Non cambiano la scena, il
  fondale del Mercante, la camera g3d, la scala dei dadi, il
  picking o le hitbox dei dadi: cambiano soltanto le coordinate
  UI dei comandi con le rispettive hitbox.
- Aggiunti vincoli geometrici e test del centro anche dopo il
  mapping 720p/1080p/1440p/ultrawide.

### Limiti
- La CI completa resta soggetta al problema preesistente
  nel laboratorio FPS isolato; nessuna correzione fittizia del
  solver è inclusa in questo intervento.
- Verifica visiva su Windows ancora necessaria.

## [0.1.27] - 2026-11-05

### Feedback Farkle e compattezza del tavolo
- Rimossa la grande fascia inferiore marrone: i comandi sono ospitati
  in una piccola traversa di legno, nascosta quando non esistono
  azioni utilizzabili (es. durante il lancio). I messaggi di stato
  restano leggibili senza un pannello vuoto.
- Il punteggio dei dadi selezionati è dichiarato esplicitamente
  **non ancora accantonato**; i punti assicurati e a rischio
  continuano a essere calcolati dal motore Farkle senza modifiche.
- Rimosso il testo ridondante `minimo 0 pt` dal pulsante Incassa.
  Accantona comunica che aggiunge punti alla posta a rischio.
- Selezione dei dadi più aderente alle mesh proiettate: due piccole
  sottolineature dorate per i selezionati, una sottolineatura rossa
  per le selezioni invalide e una tacca tenue per i dadi che
  possono segnare punti. La presa fisica rimane distinta in ciano.
- Nessun cambiamento a fisica, scala dei dadi, camera g3d o
  distribuzione casuale: da valutare con il collaudo dei lanci.

### Verifiche e limiti
- Aggiornati test di layout, pittura del pannello, selezioni e
  corrispondenza dei pulsanti con le hitbox a risoluzioni diverse.
- QA visiva e fisica Windows ancora necessaria; il laboratorio
  nativo FPS isolato aveva già un test di supporto instabile.

## [0.1.26] - 2026-11-05

### Tavolo del Mercante
- `Assicurati` e `A rischio` ora condividono un'unica scheda
  leggibile nella parte superiore, anziché essere separati fra angoli.
- Sostituita la vasta zona nera sotto il tavolo con una traversa
  color legno per comandi, stato e dadi accantonati.
- D6 un poco più presenti: fattore dimensione fisica
  `TABLE_DIE_SCALE` da 0.85 a 0.94; mesh g3d e collisioni
  sono ricavate dallo stesso corpo, senza zoom grafico fittizio.
- Lasciati invariati inquadratura del Mercante, coordinate del
  vassoio, regole Farkle e comandi di gioco.

### Collaudo e limiti
- Aggiornati test headless di pannelli, pulsanti e ridimensionamento
  a 720p/1080p/1440p e ultrawide.
- Le modifiche alla scala fisica dei dadi richiedono collaudo
  su Windows con 50 lanci, collisioni, presa singola/gruppo e picking.
  La CI non certifica la resa visiva.

## [0.1.25] - 2026-11-05

- Ridotta del 15% la dimensione lineare dei dadi sul tavolo, inclusa la geometria delle collisioni. Le miniature dei dadi accantonati conservano la dimensione precedente.

## [0.1.24] - 2026-11-05

- I contatti con le sponde usano gli estremi dei vertici ruotati, con il calcolo di `fps_part_boundary_update` di FPS 1.2.5 adattato a Lua. Il frontale del Tavolo del Mercante scende sotto il piano per lasciare visibili i dadi a riposo.

## [0.1.23] - 2026-11-05

- Rimossi il pulsante Combinazioni e il selettore paginato. I dadi si
  scelgono direttamente sul tavolo con il mouse o con i tasti 1–6.
- Il punteggio a rischio è accanto al registro dei dadi accantonati.
  Il comando di rilancio appare quando disponibile; la selezione mostra
  i punti scelti e il totale che si otterrebbe accantonandoli.

## [0.1.22] - 2026-11-05

- La partita apre con sei dadi raccolti sul lato del giocatore. Il comando
  di lancio iniziale è centrato; Incassa compare quando consentito.
- Comandi avvicinati al tavolo; intaglio sul frontale 3D, venatura sui
  listelli e ombra di contatto più marcata per i dadi a riposo.
- Verifiche headless del pannello e del renderer; collaudo visivo Windows aperto.

## [0.1.21] - 2026-11-05

- README abbreviato con presentazione del gioco, avvio e comandi essenziali.

## [0.1.20] - 2026-11-05

- Il piano del Mercante usa una texture di legno ricavata dall'illustrazione,
  raccordata al colore del bordo posteriore. Le sponde salgono gradualmente
  dal piano nel punto in cui si uniscono all'immagine.
- Riflessi più tenui sull'avorio e ombre più raccolte a contatto. Durante
  il lancio la distanza del vertice più basso dal piano guida intensità,
  apertura e spostamento dell'ombra.
- Verifiche headless di geometria, materiali e proiezione. Resta la prova
  visiva in LÖVE su Windows.

## [0.1.19] - 2026-11-05

- Prospettiva fissa del Mercante: il piano si allarga verso il giocatore,
  e la dimensione apparente dei dadi segue la distanza. Presa e rilascio
  usano la stessa inquadratura del tavolo. I segni dei dadi validi lungo
  il bordo anteriore si spostano sopra al dado.
- Test geometrici di proiezione, trascinamento e stabilità della presa.
  Collaudo visivo su Windows da effettuare.

## [0.1.18] - 2026-11-05

- Corretta la presa di gruppo sul Tavolo del Mercante: inquadratura e
  bordi restano allineati all'illustrazione durante presa e rilascio.
  Regressione verificata su 120 frame a 720p, 1080p e 1440p.

## [0.1.17] - 2026-11-05

- Il bordo posteriore del tavolo fisico raggiunge la base del ritratto
  del Mercante. La scena illustrata si estende ai lati; il tavolo occupa
  circa il 78% della larghezza a 16:9. Spazio di volo e inquadratura del
  mobile sono separati. La zona di presa segue la proiezione g3d.
- Ampliate le dimensioni fisiche della superficie; cornice continua,
  registro dei dadi sotto il piano e targhette separate per i comandi.
- Test di proiezione a 720p, 1080p e 1440p; collaudo grafico Windows aperto.

## [0.1.16] - 2026-11-05

- Rimossa la Sfida il Monaco (beta) dal menu e dal ciclo di gioco, inclusi
  il bot dedicato, il pannello del duello e la rivincita.
- Il collaudo del menu e la cattura di revisione seguono il tavolo del
  Mercante. La cronologia della beta resta consultabile nel registro.

## [0.1.15] - 2026-11-05

- Prova visiva del Tavolo del Mercante nella partita normale: ritratto,
  bicchiere e posta illustrati sopra il vassoio fisico g3d color miele.
  Il dado rosso del Mercante è un riferimento visivo fisso.
- Il messaggio di selezione mostra il punteggio calcolato dalle regole.
  Test headless per la mano da 50 punti e il passaggio a 30.
  Collaudo interattivo in LÖVE su Windows ancora da effettuare.

## [0.1.14] - 2026-11-04

**Tipo:** primo passaggio verso il tavolo Farkle essenziale, senza nuove
meccaniche di scommessa o encounter.

### Interfaccia
- La nuova partita normale utilizza il layout `table_minimal`: superficie
  fisica più larga e senza pannelli permanenti di commissione,
  folio e strumenti. I punteggi assicurati e a rischio rimangono
  visibili; il folio è ancora accessibile con **F** e le regole con **?**.
- I sei riquadri vuoti dei dadi accantonati non sono più disegnati
  permanentemente nella partita normale; compaiono soltanto i
  dadi effettivamente accantonati.
- Lancia/Accantona e Incassa occupano controlli inferiori più
  compatti; messaggi contestuali in italiano senza una grande barra.
- I pulsanti di combinazioni e medaglie mantengono hitbox e callback
  effettivi in una riga contestuale, senza un pannello `Strumenti`.
- Il duello separato **Sfida il Monaco (beta)** conserva temporaneamente
  il proprio layout precedente, la visualizzazione della miniatura e
  i controlli. Non è ancora un encounter asimmetrico.

### Test e limiti
- Aggiunto controllo headless dei nuovi confini del tavolo,
  dei pulsanti, del registro dinamico e dei viewport 720p/1080p/1440p.
- Farkle, RNG, commissioni sottostanti, fisica e g3d non sono cambiati.
  Lo spazio del tray è cambiato: occorre verificare su LÖVE Windows
  proiezione, selezione fisica, ridimensionamento e resa visiva.

## [0.1.13] - 2026-11-04

**Tipo:** repository housekeeping conservativo, senza modifiche al gioco.

### Pulizia e manutenzione
- Rimossi 36 vecchi file di acquisizione UI del 1 novembre (18 PNG e 18
  TSV; 2.047.031 byte), superati da una cattura più recente e mai
  richiamati dai sorgenti attivi. Recuperabili dalla storia Git.
- Gli output QA futuri, le build locali dei laboratori e i bundle di
  distribuzione non vengono più aggiunti accidentalmente al repository.
- README sintetizzato: stato della build, avvio, controlli, test e licenze.
  Le note di sviluppo pregresse rimangono in questo changelog.
- Nuova visione del brainstorming con setting veneziano, protagonista
  muto, tre pilastri di design e distinzione fra feature esistenti
  e incontri ancora da definire; vecchie proposte etichettate come tali.
- Aggiunto un test di regressione per proteggere g3d, fisica, dadi e
  risorse attive da successive cancellazioni accidentali.

### Verifiche e limitazioni
- Nessuna modifica a gameplay, scoring, RNG, fisica, renderer, input,
  UI runtime o medaglie. Conservato lo snapshot QA del 3 novembre e
  l'asset `walnut.png` ancora in uso.
- Le verifiche CI sono headless e non equivalgono al collaudo grafico
  e fisico su Windows. La storia Git non è stata riscritta.

## [0.1.12] - 2026-11-03

**Tipo:** semplificazione del menu in partita e navigazione sicura.
Le regole Farkle, la fisica dei sei D6, g3d, l'interazione fisica e
la modalità Sfida il Monaco non sono stati modificati.

### Pausa per il giocatore
- Il vecchio `RUN MENU` sperimentale viene sostituito da un pannello
  compatto con **Riprendi**, **Impostazioni**, **Ricomincia la partita**
  e **Torna al menu principale**.
- Riavvio e ritorno al menu richiedono conferma esplicita e avvisano
  dell'assenza di salvataggi automatici. Il riavvio conserva la modalità
  originaria: build normale o sfida al Monaco (control).
- La pagina Impostazioni raggiunta dal gioco ritorna alla stessa
  sessione attiva e `Esc` funziona per tornare indietro.
- `Esc` dentro la partita apre/chiude la pausa invece di chiamare
  `love.event.quit()`: mantiene prima la precedenza per annullare
  la presa fisica e la selezione di gruppo. Durante il lancio in
  assestamento non interrompe la fisica né apre la pausa.
- Il laboratorio delle medaglie non è più nel menu del giocatore;
  rimane richiamabile con **F7** come strumento di sviluppo.

### Test e limiti
- Aggiornato l'inventario delle interazioni e il test delle modali
  a 720p, 1080p e 1440p; aggiunta una regressione headless per
  i callback di ripresa/impostazioni/riavvio/uscita e la modalità Monaco.
- Verifica grafica e percorso di ritorno su LÖVE Windows ancora
  da confermare con un'esecuzione reale; non si dichiara completato
  il gate visivo P5.

## [0.1.11] - 2026-11-03

**Tipo:** formalizzazione narrativa e visiva del prossimo fondale:
**officina alla Manuzio + pulsione del gioco dei dadi + sogno**.
Modifiche di sola documentazione, senza nuovo PNG o codice runtime.

### Nuovo brief di produzione
- `docs/MANUZIO_DREAM_DICE_ART_BRIEF.md`: la componente
  ludica viene resa leggibile con **sei D6** e la tensione
  della mano prima del rilancio; l'onirico nasce
  dalla continuità quasi impercettibile di carta,
  caratteri mobili, inchiostro e piano da gioco.
- Definiti tre strati (storico, rischio, sogno),
  composizione 1920×1080 in zone, priorità del
  primo piano, palette e un'unica anomalia
  onirica principale, più al massimo un indizio.
- Distinto l'azzardo come **metafora narrativa** da
  ogni pretesa storica su Manuzio o sul Farkle
  moderno: nessuna valuta, meccanica o casino
  aggiunti al gameplay.
- Aggiunta checklist di collaudo dell'artwork e
  requisiti anti-`AI slop`, leggibilità a 25%,
  safe area sinistra 32,5% e crop 4:3.
- Collegamenti aggiornati a `MANUZIO_REFERENCE_SYNTHESIS.md`,
  `MANUZIO_PRINTSHOP_ART_DIRECTION.md`, `ART_DIRECTION.md`
  e README. Il file
  `resources/ui/menu_manuzio.png` **non cambia**:
  servirà revisione visiva separata della futura V2.

## [0.1.10] - 2026-11-03

**Tipo:** sintesi delle nuove reference e precisazione storica
della direzione artistica della bottega alla Manuzio. **Solo
documentazione e versionamento**, nessuna modifica agli asset,
al rendering o al gameplay.

### Direzione artistica
- `docs/MANUZIO_REFERENCE_SYNTHESIS.md`: due reference distinte;
  miniatura tipografica per gesti/strumenti/colori, Flameng
  per luce/finestra/spazio; prompt di produzione definitivo,
  distribuzione del frame e checklist visiva 720p/1080p/4:3.
- Precisato l'anacronismo nella datazione «1840» di François
  Flameng (nato nel 1856); il Grolier Club attribuisce uno
  studio a circa 1894 e documenta la licenza artistica
  dell'incontro Grolier–Manuzio a Venezia.
- Conservata la bottega reale del gioco come scena anonima
  ispirata all'officina editoriale, non rappresentazione
  dell'incontro storico: nessuna copia di opere terze.
- Aggiornate le guide `ART_DIRECTION.md`,
  `MANUZIO_PRINTSHOP_ART_DIRECTION.md` e i link README.
- Rimane **`resources/ui/menu_manuzio.png` della 0.1.9**:
  nessun nuovo PNG è dichiarato installato. Il prossimo
  aggiornamento dell'immagine richiederà revisione visiva
  separata e test LÖVE su Windows.

## [0.1.9] - 2026-11-03

**Tipo:** correzione del caricamento del nuovo fondale approvato
e ripristino del gate CI dopo l'upload manuale.

### Fondale Manuzio effettivamente distribuito
- Il file approvato `ProjectFolio_Manuzio_Bottega_1920x1080.png`
  era stato committato sotto un **nome non usato dal runtime**:
  il gioco continuava a visualizzare il fallback.
- Riutilizzato lo **stesso blob Git** (stesso SHA-256 e pixel),
  collocandolo finalmente in
  `resources/ui/menu_manuzio.png` ed eliminando il nome
  di esportazione ridondante, senza conversione o ricompressione.
- Nessun pacchetto ZIP o installazione separata è più necessario:
  `git pull` include il fondale principale. La vecchia immagine
  monastica era già stata rimossa dall'ultimo upload del team e
  non viene ripristinata. `menu.png` resta fallback e il
  codice tollera `menu_illustrated.png` solo se presente in una
  precedente installazione locale.
- Nuovo test Python di regressione: richiede il PNG sul percorso
  realmente letto dal loader e valida firma, chunk, dimensioni
  **1920×1080** e hash dell'illustrazione approvata.
- README e guide allineate alla distribuzione reale; preservati
  pulsanti, hitbox, scene, gameplay, audio, g3d e fisica.

### CI e QA
- Aggiornati `version.txt` e changelog come richiesto dalla CI:
  il commit diretto precedente falliva perché non li modificava.
- La CI Linux verifica esistenza/integrità dell'asset e regressioni
  Lua/Python; **la resa visiva e il click test su Windows restano
  da certificare sul client LÖVE**.

## [0.1.8] - 2026-11-03

**Tipo:** nuova direzione artistica per il fondale principale:
**bottega tipografica veneziana ispirata ad Aldo Manuzio**, non
scriptorium monastico.

### Fondale e integrazione
- Preparata un'illustrazione originale 1920×1080 senza elementi UI:
  compositore di caratteri mobili, correttore umanista, stampatore
  al torchio e bozze in asciugatura. Disponibile separatamente come
  `ProjectFolio_Bottega_Manuzio.zip`.
- Introdotto il percorso opzionale `resources/ui/menu_manuzio.png`,
  con fallback ordinato su `menu_illustrated.png` già caricato sul
  repository e quindi su `menu.png`.
- Main Menu, Settings e scelta commissioni usano la stessa precedenza
  e mantengono il crop responsivo e la UI interattiva separata.
- Esteso `scripts/install_menu_art.py` con `--manuzio`: verifica
  ZIP/PNG e installazione atomica del nuovo asset senza sovrascrivere
  i due fondali precedenti. Aggiornati test Lua/Python per la
  precedenza, il fallback e la conservazione degli originali.
- Nuova specifica `docs/MANUZIO_PRINTSHOP_ART_DIRECTION.md`,
  README, guida artistica e istruzioni di installazione aggiornati.
- **Il nuovo PNG non è ancora nel repository GitHub**: va installato
  localmente dal pacchetto allegato; il gioco resta funzionante
  con i due fondali esistenti.

### Limiti
- Nessuna modifica a gameplay, dadi, fisica, g3d, audio o salvataggi.
- L'esito dei test CI non certifica la resa su GPU Windows né la
  qualità finale dell'illustrazione; collaudo visuale ancora aperto.

## [0.1.7] - 2026-11-03

**Tipo:** correzione compositiva del fondale illustrato e installazione
locale verificata. Nessuna modifica al sistema di dadi, Farkle,
fisica, audio, salvataggi o renderer g3d.

### Composizione e leggibilità
- `src/core/menu_background.lua` centralizza il ritaglio *cover*:
  con l'illustrazione opzionale, i viewport 4:3 e 5:4 sono ancorati
  a sinistra e non eliminano lo spazio riservato al pannello.
- Il pannello del Main Menu si restringe **solo se**
  `menu_illustrated.png` è realmente caricata, rispettando il
  primo 32,5% della composizione. Il layout del fondo legacy non
  viene cambiato. Nuove verifiche pure Lua a 720p/1080p/1440p,
  4:3 e ultrawide.
- Rimossa la tinta grigio-pietra che scuriva i pigmenti del
  nuovo fondale. La vignettatura viene ridotta soltanto per
  la nuova illustrazione; alto contrasto rimane intatto.
- Menù, Settings e commissioni condividono la stessa logica
  di composizione, senza cambiare click, hitbox o navigazione.

### Installazione e distribuzione
- `scripts/install_menu_art.py` valida lo ZIP o PNG
  originale, CRC dei chunk, dimensioni native 1920×1080,
  SHA-256 dell'archivio e scrive atomicamente soltanto il
  file `resources/ui/menu_illustrated.png`.
- Nessuna sovrascrittura implicita di una variante già
  installata; test Python aggiunti e integrati nella CI.
- Nuova guida `docs/MENU_ART_INSTALLATION.md` con checklist
  di leggibilità per Windows, comando di installazione
  e hash del pacchetto fornito in conversazione.
- **Il PNG resta separato dal repository** fino al
  caricamento esplicito del file binario da parte del team:
  il fallback a `resources/ui/menu.png` rimane attivo.
- La CI non certifica la qualità visiva reale: il controllo
  LÖVE su Windows resta da completare.

## [0.1.6] - 2026-11-03

**Tipo:** integrazione tecnica dello sfondo illustrato, senza intervenire
su gameplay, fisica, navigazione, input o materiali 3D.

### Fondale editoriale
- Nuovo `src/core/menu_background.lua`: scelta ordinata dell'asset
  `resources/ui/menu_illustrated.png`, se presente e leggibile,
  con fallback sicuro al precedente `resources/ui/menu.png`.
  Nessun crash se un file manca o `newImage` fallisce.
- Main Menu, scelta commissione e Settings usano la stessa logica:
  evitando il salto stilistico fra schermate, senza duplicare il
  nuovo fondale o sostituire elementi della UI interattiva.
- `src/data/*_schema.lua` distingue esplicitamente sfondo
  illustrato opzionale e sfondo shipping. La UI, il titolo,
  la versione e i pulsanti restano disegnati in Lua: **vietato
  incorporare testo o bottoni nel nuovo PNG**.
- Nuova regressione headless `tests/menu_background_loader_test.lua`
  per precedenza, fallback su file corrotto, assenza API e
  consistenza dei tre schemi.

### Distribuzione dell'illustrazione
- Preparato a parte un asset originale `1920×1080` (senza testo UI),
  con relativo ZIP `resources/ui/menu_illustrated.png` da estrarre
  localmente nella root del repository. **Il binario non viene
  committato con questa PR**, poiché il connettore GitHub di questa
  sessione gestisce i contenuti testuali, non i PNG locali.
- Il gioco su GitHub continua quindi a funzionare con `menu.png`
  fino alla presenza del nuovo PNG. Nessun falso cambio grafico
  dichiarato per gli utenti che clonano `main`.

### Verifiche
- CI Linux Lua 5.4, LuaJIT, test Python e laboratorio FPS.
- Da collaudare su Windows in LÖVE con l'illustrazione installata:
  1280×720, 1920×1080, big text, high contrast e continuità
  Menu → Settings → Commissioni → Menu.

## [0.1.5] - 2026-11-03

**Tipo:** prima integrazione della direzione artistica pittorica di Project Folio.

### Palette unificata
- Aggiunto `src/data/art_palette.lua`: vocabolario HEX di 26 pigmenti
  coerenti con le reference (pergamena, calce, salvia, oliva, coccio,
  cinabro, ardesia, ocra e inchiostro), ruoli UI semantici e conversione
  RGB/RGBA in puro Lua. Non richiede un renderer o un asset.
- Applicata la palette alle superfici condivise del frontend
  (`menu_surface.lua`) mantenendo le varianti di stile esistenti:
  impaginazione/editorial del menu, pulsanti, stati, bordi, fondi,
  selezioni e pannelli.
- Applicata al testo e agli accenti del menu principale e agli
  elementi bidimensionali di HUD Farkle e dialoghi/ricompense.
  Indicatori ad alto contrasto e materiali/mesh dei dadi 3D intatti;
  **nessuna modifica alle regole, shader, luci o fisica**.
- In `docs/ART_DIRECTION.md` codificati i valori, le gerarchie
  percettive, gli usi dei pigmenti e la prossima fase dedicata
  agli asset originali: non viene applicato un filtro indiscriminato
  alle texture o sostituito il fondale con arte automatica.

### Verifiche
- Nuovi test Lua `tests/art_palette_test.lua` per HEX e ruoli,
  valori normalizzati, copie indipendenti, contrasto del testo,
  gestione delle opacità e presenza del wiring nelle schermate.
- CI e changelog incrementati; **la resa percettiva Windows
  deve essere verificata con screenshot reali** prima di una revisione
  degli asset pittorici.

## [0.1.4] - 2026-11-03

**Tipo:** rifinitura visiva del menu principale, meno ornamenti
generici e migliore leggibilità. Nessuna modifica a Farkle, dadi 3D,
fisica, audio, menu di gioco, salvataggi o navigazione.

### Design del menu principale
- Titolo gotico conservato come **unico accento** tipografico e
  spostato all'interno del margine del folio; sottotitolo
  allineato a sinistra, più contenuto.
- Azioni in IM Fell English SC più leggibile, con gerarchia
  tipografica chiara: `New Game` prevale; `Continue` disabilitato
  non si presenta come pulsante principale operativo.
- Riquadri beige ripetuti, doppie cornici arrotondate e
  piccoli rombi dorati sostituiti da un **indice editoriale**:
  righe sottili e segno laterale di selezione, carta naturale
  squadrata. Le schermate Settings, commissioni e le finestre
  condivise conservano il proprio stile attuale.
- Sfondo della bottega meno saturo, copertura cromatica
  più quieta e pulviscolo decorativo ridotto; non vengono
  sostituiti gli asset originali.
- Footer compatto con sola versione canonica (`v0.1.4`) e
  icona audio; rimossa la dicitura `alpha` dal menu, senza
  alterare il sistema di versionamento.
- Etichetta commerciale `Wishlist Now!` semplificata in
  `Wishlist` nelle stringhe inglesi; azione e URL invariati.

### Verifica
- Estesi test headless dei margini di menu, dei sei pulsanti,
  dello stile opt-in senza ornamenti e del mantenimento
  delle altre schermate.
- CI Lua 5.4/LuaJIT e test Python richiesti prima del merge.
  **QA visiva Windows ancora necessaria** per proporzioni,
  resa dei font e gusto estetico.

## [0.1.3] - 2026-11-03

**Tipo:** affidabilità della raccolta prove UI Windows, nessuna
modifica al gameplay, fisica 3D, audio o renderer g3d.

### Acquisizioni QA
- Nuovo `scripts/package_ui_v2_review.py`: controlla la presenza
  dei 32 PNG reali, 32 TSV delle hitbox, manifesto, gallery, checklist
  e log; confronta gli SHA-256, dimensioni e stato dei frame con il
  manifest di origine. Rifiuta pacchetti incompleti o modificati.
- `scripts/capture_ui_v2_review.py` crea automaticamente uno ZIP
  portabile, **esterno** alla cartella della cattura, dopo avere
  superato i controlli; l'archivio include soltanto i file di
  evidenza e un indice SHA-256. Non vengono impacchettati APPDATA
  o dati di salvataggio.
- `--check-only` verifica acquisizioni già esistenti senza
  generare file; il comando senza opzioni confeziona lo ZIP,
  impedendo una selezione manuale parziale su GitHub.
- Nuovi test Python per pacchetti completi, acquisizioni 18/32,
  mancanza di log, mancata corrispondenza manifesto e integrità
  dell'archivio; integrati in GitHub Actions.
- Guida Windows e tracker UI aggiornati. **La QA visuale
  Windows non viene marcata PASS dai test sintetici.**

## [0.1.2] - 2026-11-03

**Tipo:** ripristino del gate CI per upload di screenshot e inventario del primo
collaudo Windows allegato al repository. Nessuna modifica a gameplay,
fisica, renderer, suoni, test o file PNG/TSV già caricati.

### Documentazione e QA
- Aggiunto `docs/WINDOWS_QA_CAPTURE_REVIEW_20261103.md` con inventario
  del commit `c2b2f74a`: 18 screenshot e 18 file hitbox (16 scenari a
  1920×1080, due a 1280×720), 14 scenari 1280 mancanti, assenza nel tree
  di manifest, checklist compilata e log smoke.
- Controllate tutte le 18 mappe TSV: nessuna hitbox fuori dal viewport
  e nessuna sovrapposizione fra controlli abilitati; nelle due scene
  comuni le coordinate 1280 sono esattamente 2/3 delle 1920.
  **Non** si dichiara approvata la qualità visiva dei PNG, né il
  comportamento del mouse, né la fisica o gli FPS reali.
- Aggiornato lo stato del gate P5 e il collegamento al report.
- Versione incrementata da `0.1.1` a `0.1.2`, con changelog,
  per sanare l'errore CI del commit di sola acquisizione
  (`main` run 41606048617: missing `version.txt` e
  `CHANGELOG.md`). La suite CI verrà rieseguita dalla PR.

### Limiti
- Non è dimostrato che il generatore non abbia prodotto i 14 PNG mancanti:
  potrebbero non essere stati inclusi nel commit. Nessun dato viene
  inventato o rigenerato da fixture.
- Gate Windows P5 ancora **APERTO** fino alla verifica di 32 PNG,
  manifesto, checklist, smoke e test manuali dei 50 lanci.

## [0.1.1] - 2026-11-03

**Tipo:** audit del repository, preparazione del collaudo tecnico Windows e
allineamento documentale; **nessuna modifica al gameplay, alla fisica,
al renderer o agli asset del gioco.**

### Aggiunto
- `docs/WINDOWS_TECHNICAL_QA.md`: procedura Windows riproducibile,
  preflight, comandi di test esistenti, 32 frame LÖVE UI V2,
  prova fisica di almeno 50 lanci, hitbox, score, g3d, accessibilità,
  audio, prestazioni e checklist PASS/FAIL con manifest, screenshot e log.
- Inventario dell'esito CI main `41603525911`: test Lua 5.4/LuaJIT,
  benchmark Segni e FPS isolati, test Python **superati su Ubuntu**.
  Nessuna attestazione di esecuzione dei test manuali Windows.

### Corretto nei documenti
- README: URL e directory corretti `Askeladd22/Project_Folio`
  per il clone; aggiunto percorso di QA corrente, senza modificare
  identificatori compatibili del runtime.
- `UI_V2_STATUS.md`: stato verificato corrente separato dagli snapshot
  storici del 31 ottobre, cutover V2 già eseguito e QA Windows P5 aperta.
- `UI_V2_ROADMAP.md`: marcata come roadmap di migrazione storica,
  non istruzioni per ripristinare vecchi flag, F6 o renderer CPU.
- `UI_V2_VISUAL_REVIEW.md`, `RENDERER_RETIREMENT.md` e
  `GAME_DESIGN.md`: corretta terminologia corrente e collegati i
  documenti di collaudo, senza riscrivere la ricerca precedente.

### Verifiche e limiti
- Gate CI e versionamento richiesti alla presente PR.
- Screenshot, ascolto audio, movimenti del mouse, hitbox su GPU e
  FPS su Windows **ancora da eseguire manualmente**.

## [0.1.0] - 2026-11-03

**Tipo:** bilanciamento musica principale e passaggio al versionamento senza suffisso `-dev`.

### Audio
- Il tema `maintitle.ogg` ha ora un livello di mix dedicato del **25% rispetto al volume Musica selezionato** (circa -12 dB), tramite `main_theme_mix_gain` nel file di schema del menu. I volumi master/SFX e quelli dei suoni dei dadi restano indipendenti e invariati.
- Registrazione del volume nel manager Audio prima dell'avvio della musica, evitando picchi iniziali alla precedente intensità.
- All'uscita dal menu principale, il brano viene messo in pausa e rimosso dalle sorgenti musica attive; tornando al menu può riprendere, senza accompagnare il gameplay dei dadi.

### Versionamento
- Eliminato il suffisso di sviluppo dalla versione corrente: `0.1.0-dev.21` → **`0.1.0`** (menu: `v0.1.0`).
- I nuovi aggiornamenti useranno numeri semplici `0.1.1`, `0.1.2`, ecc.; README, guida di versionamento e regressioni aggiornati.
- La cronologia originaria `0.1.0-dev.1`–`0.1.0-dev.21` rimane invariata e verificabile. Il gioco resta un prototipo e questo non certifica una release commerciale.

### Verifiche
- Nuovo test `tests/menu_music_mix_test.lua` sul livello relativo del tema, music mute, volume master separato e sicurezza della transizione di menu.
- Esteso il test della versione canonica per il formato X.Y.Z e la precedenza SemVer rispetto alla vecchia prerelease.
- CI Lua/LuaJIT, laboratorio fisico e test Python da verificare prima del merge; ascolto reale LÖVE su Windows ancora necessario.

## [0.1.0-dev.21] - 2026-11-03

**Tipo:** integrazione dei nuovi effetti OGG di interazione fisica dei dadi.

### Aggiunto
- Riproduzione dei suoni `dice-grab-1/2.ogg` all'avvio effettivo di una presa.
- Riproduzione di `dice-shake-1/2/3.ogg` esclusivamente quando il rilevatore fisico conferma un nuovo scuotimento, con intensità proporzionale alla forza del gesto.
- Suoni `die-throw-1..4.ogg` per il lancio di un singolo dado e `dice-throw-1..3.ogg` per il lancio multiplo, riprodotti una sola volta per gesto; i lanci automatici/da tastiera usano gli stessi OGG.

### Integrazione
- Gli asset esistenti sono caricati in modo lazy da `src/core/audio_manager.lua`, con sorgenti prototipo in cache e voci clonate in un pool limitato a 16 per garantire il completamento del playback.
- Varianti in rotazione deterministica senza consumare lo stato random delle combinazioni Farkle. Volume, master e mute SFX già presenti nelle impostazioni vengono rispettati.
- Quando il file OGG non è disponibile, l'auto-throw mantiene il precedente cue UI come fallback; la presa e lo shake rimangono silenziosi senza bloccare la fisica.
- Nessuna modifica alle traiettorie 3D, al rilevatore di shake, alla risoluzione dei risultati o al rendering g3d.

### Verifiche
- Nuovo test headless `tests/dice_interaction_audio_test.lua` su varianti, file, mute, moltiplicatore di volume, isolamento RNG e limite polifonico.
- Da verificare la resa uditiva, bilanciamento e latenza con LÖVE su Windows e un dispositivo audio reale; la CI Lua è richiesta prima del merge.

## [0.1.0-dev.20] - 2026-11-01

**Tipo:** fix rotazione indebita dei dadi durante trascinamento multiplo, dopo confronto con studio del bytecode Tabletop Simulator.

### Corretto
- Durante una presa di gruppo, `Single.track` non applica più
  la formula di spin `dx/dt` e `dy/dt` ai singoli D6.
  Il trascinamento muove i corpi verso il bersaglio della mano,
  senza farli rotolare tutti nella sua stessa direzione.
- I gesti del gruppo iniziano con velocità angolare nulla;
  scuotimento e impulsi individuali rimangono attivi
  soltanto quando il rilevatore riconosce rapidi cambi di direzione.
- Lo spin residuo del gruppo si attenua più rapidamente
  quando si ferma il mouse; comportamento della presa singola,
  rilascio fisico e regole Farkle invariati.
- Nuovo test `group_grip_drag_spin_decoupling_test.lua`
  per 2–6 dadi, trascinamento unidirezionale, shake
  autentico, quiete e regressione della presa singola.
- Documentata la differenza fra `UpdateGrabbedNPO`,
  `ShakeDetector.FixedUpdate` di TTS e le responsabilità
  prima sovrapposte del codice Lua in
  [TTS_GRIP_DRAG_SHAKE_DIAGNOSIS.md](docs/TTS_GRIP_DRAG_SHAKE_DIAGNOSIS.md).

### Limiti
- La DLL TTS non è stata ridisassemblata in questa modifica:
  confronto con l'analisi statica verificata e già archiviata.
- Non è una replica esatta della fisica di TTS;
  il gate dinamico su Windows resta necessario.

## [0.1.0-dev.19] - 2026-11-01

**Tipo:** scuotimento fisico dei dadi mentre sono afferrati insieme, ispirato a uno shaker/bossolo virtuale di Tabletop Simulator.

### Nuove funzioni
- Durante la presa multipla con tasto destro, **due rapide inversioni**
  della direzione del mouse attivano il nuovo comportamento dello shaker;
  un lancio in un'unica direzione o piccoli movimenti non lo attivano.
- `group_shaker.lua` applica energia temporanea, impulsi inerziali,
  turbolenza e rotazioni individuali ai **veri corpi fisici**
  afferrati; i dadi continuano a scontrarsi in una zona di presa.
- Contenimento temporaneo in un **bossolo virtuale invisibile**:
  bordo laterale e limiti verticali elastici, con raggio che si
  restringe progressivamente per evitare teletrasporti
  durante la raccolta; collisioni originali durante il volo.
- L'energia dello shaker si spegne gradualmente quando la mano
  smette di scuotere. Al rilascio si conservano le pose reali
  di ogni dado e parte della velocità relativa accumulata,
  mantenendo il lancio fisico normale.

### Compatibilità e test
- Riutilizzato `shake_detector.lua` già presente:
  gli impulsi avvengono solo dopo inversioni confermate;
  nessuna nuova dipendenza, RNG di gameplay o dado fittizio.
- Nuovo `tests/group_grip_shaker_test.lua` per attivazione,
  movimento unidirezionale, jitter, rotazione individuale,
  contatti e limiti, arresto e rilascio dal punto reale.
- `GroupThrow` conserva le regole di selezione, tiro
  parziale, annullamento Esc e identità del lancio Farkle.
- Lo shaker è un effetto fisico della fase **presa multipla**,
  non il rendering di un oggetto bossolo 3D, né una
  sostituzione di g3d, del solver di volo o delle regole.
- QA dinamica Windows necessaria per regolare il realismo
  di accelerazione, collisioni e inerzia; la CI non
  sostituisce l'osservazione del movimento reale.

## [0.1.0-dev.18] - 2026-11-01

**Tipo:** correzione del raggruppamento fisico dei dadi durante la presa multipla, ispirata al comportamento di Free Physics Solver.

### Corretto
- Rimossa la formazione artificiale dei sei dadi in pila 3+3
  e abbandonata la successiva griglia rigida come soluzione finale.
- Tutti i corpi fisici reali inseguono lo **stesso punto mano**
  con un'attrazione elastica smorzata; durante la presa
  ricevono separazione di contatto temporanea a coppie,
  così non collassano in un unico punto.
- Anche senza spostare il puntatore la presa si raccoglie
  dinamicamente; muovendo la mano, i dadi la inseguono
  senza essere incollati ad una formazione predefinita.
- Il rilascio restituisce ciascun corpo al solver di volo
  **dalla sua posizione effettiva**; non lo teletrasporta
  nella disposizione del tiro singolo o su una griglia.
- Conservati selezione multipla, inclusione/esclusione
  dei D6, parametri della fisica libera e tiro ufficiale
  con valori Farkle calcolati dopo l'assestamento.

### Test e limiti
- Test `tests/group_grip_open_formation_test.lua` aggiornato
  per movimento elastico, contatti fra 2–6 corpi,
  limiti del vassoio, Esc, rilascio senza scatti
  e centri inizialmente coincidenti.
- Test `tests/marquee_group_throw_test.lua` aggiornato
  dal vecchio target fisso ai corpi realmente in movimento.
- Test storico `tests/tabletop_pile_zoom_test.lua`
  non impone più la pila 3+3 e verifica invece
  l'integrazione della nuova presa con lo zoom.
- I risultati di `experiments/physics_lab/` restano un
  riferimento, **senza importare il solver nativo FPS**
  sperimentale in produzione. Il movimento di presa è
  una dinamica compatibile in Lua, non una sostituzione
  integrale della fisica del gioco.
- La prova visiva/dinamica su Windows deve essere ripetuta:
  CI/headless non possono confermare ancora la resa finale.

## [0.1.0-dev.17] - 2026-11-01

**Tipo:** diagnostica visiva delle vere hitbox UI V2 (solo test/report), successiva al polish dei testi dev.16.

### Modificato
- Ogni screenshot Windows LÖVE della revisione V2 salva un TSV
  con le hitbox **effettive** di pulsanti normali, modali e
  ricompense, prelevate nello stesso frame di rendering.
- Coordinate trasformate in pixel schermo dal resolution manager.
  Il rettangolo fisico del tavolo dei sei D6 è incluso ma non
  viene interpretato come pulsante.
- La galleria HTML ha il controllo reversibile **Mostra hitbox reali**,
  con oro per azioni abilitate, grigio per disabilitate e
  azzurro per il tavolo g3d; i PNG non vengono alterati.
- Manifest e test Python verificano TSV mancanti/malformati,
  ID duplicati, numeri non finiti e controlli fuori schermo.
  Test Lua aggiunti al wiring dell'acquisizione.
- Aggiornata la documentazione Windows per il controllo
  manuale della geometria delle interazioni.

### Limiti
- La QA grafica Windows richiede la reale esecuzione e revisione
  degli screenshot; CI verde non equivale ad approvazione visiva.
- Nessuna modifica a gameplay, Farkle, g3d, sei dadi, fisica,
  camera, salvataggi, bot o splash originale LÖVE.

## [0.1.0-dev.16] - 2026-11-01

**Tipo:** leggibilità e contenimento del testo delle finestre UI V2, solo presentazione.

### Modificato
- Paragrafi di aiuto, condizioni del folio, descrizioni dei dadi
  premio e medaglie adattati allo spazio disponibile usando le
  misure reali di `Font:getWrap` e l'altezza delle righe.
- Testi su più righe e a capo espliciti rispettati; la dimensione
  si adatta al flag `big_text`, riducendosi se lo spazio è
  insufficiente. Solo in ultima istanza è applicata un'ellissi
  che non spezza i caratteri UTF-8.
- La tabella delle combinazioni usa celle misurate per titoli e
  valori invece di righe lasciate al wrapping automatico.
- Le descrizioni del laboratorio delle medaglie e delle
  condizioni di attivazione sono contenute in riquadri di
  altezza nota, senza spostare pulsanti o cambiare le regole.

### Test e limitazioni
- Nuovi test puri `tests/ui_v2_paragraph_fit_test.lua` e
  render test `tests/ui_v2_dialog_text_geometry_test.lua`:
  UTF-8, righe esplicite, risoluzioni 720p/1080p/1440p,
  testo grande, schede punteggio/ricompense/medaglie e
  immutabilità dello stato Farkle.
- Le hitbox e le callback delle modali rimangono invariate.
- Nessuna modifica a g3d, sei dadi, Farkle, fisica, Monaco,
  salvataggi, splash originale LÖVE.
- Test CI da verificare; la QA grafica Windows e il controllo
  di font reali rimangono da eseguire.

## [0.1.0-dev.15] - 2026-11-01

**Tipo:** infrastruttura di revisione grafica riproducibile della UI V2 attiva (solo test e documentazione).

### Modificato
- Percorso `--ui-v2-review` separato dalla vecchia smoke HUD:
  acquisisce i pannelli realmente in produzione senza usare ID
  o coordinate legacy ritirate nel cutover.
- Script Windows `scripts/capture_ui_v2_review.py` per 32 frame LÖVE
  a 1920×1080 e 1280×720, organizzati in cartelle datate
  con hash SHA-256, controlli di integrità PNG e versione Git.
- Report locale `gallery.html`, manifesto JSON e checklist manuale
  da compilare per contrasto, clipping, input e g3d.
- Distinzione esplicita tra la vera presa fisica dei sei D6
  e i frame diagnostici dei punteggi/ricompense, basati
  sulle regole Farkle ma senza simulare un rilascio fisico.
- Sistemata la pulizia del test dopo l'annullamento
  della presa manuale, senza cambiare il controller.
- Unit test Python e test Lua del wiring; aggiunti in CI.
- Guida `docs/UI_V2_VISUAL_REVIEW.md` per esecuzione Windows.

### Invarianti e limitazioni
- Nessuna modifica alle funzioni di gameplay, renderer g3d,
  regole Farkle, dadi 3D, fisica, splash originale LÖVE
  o alle hitbox di produzione.
- Una CI verde prova solo integrità e wiring del percorso;
  la QA GPU/Windows richiede di eseguire il nuovo script
  e **valutare realmente** gli screenshot generati.
- La vecchia procedura P0 resta disponibile come archivio
  storico, ma non è il percorso indicato per l'interfaccia V2.

## [0.1.0-dev.14] - 2026-11-01

**Tipo:** finitura visiva delle finestre Farkle UI V2, senza modifiche alle meccaniche.

### Modificato
- Dialoghi di aiuto, combinazioni, folio, menu partita e
  medaglie: tipografia coerente con il manoscritto, sottile
  separatore ornamentale sotto l'intestazione e stato hover
  sensibile alla risoluzione e al letterboxing.
- Etichette dei comandi misurate sui font, con riduzione
  della dimensione e abbreviazione UTF-8 sicura quando necessario
  (compresi testi grandi e pulsanti lunghi delle combinazioni).
- Pannello ricompense: due schede illuminate indipendenti per
  le due scelte di dado o medaglia e separatore decorativo.
- Nessun cambio degli ID delle azioni, delle funzioni dei pulsanti,
  degli stati delle opzioni disabilitate, della modalità di
  selezione o delle geometrie cliccabili.
- Geometrie statiche del dialogo e delle due ricompense
  verificate in un nuovo modulo indipendente dal rendering.

### Test e limiti
- `tests/ui_v2_modal_polish_test.lua`: otto percorsi di
  rendering (help, choices, folio, run, medals, medaluse,
  upgrade e reward-medal), ciascuno a 720p/1080p/1440p
  con testo normale/grande e contrasto alto; controllo
  dell'immutabilità del Farkle e delle hitbox.
- Nessuna modifica a scoring, sei D6, g3d, bot, fisica,
  salvataggi o splash originale LÖVE.
- CI e verifica in gioco su Windows LÖVE da completare;
  test headless non equivalgono a screenshot GPU.

## [0.1.0-dev.13] - 2026-11-01

**Tipo:** modernizzazione esclusivamente visiva della sfida al Monaco.

### Modificato
- Scheda della sfida al Monaco allineata alle superfici
  pergamena e inchiostro della UI 2.0, con separatori
  illuminati, dati punteggio/mano/meta e ultimo tiro leggibili.
- Testi misurati sulle dimensioni del font, con riduzione
  controllata e troncamento UTF-8 sicuro anche in
  modalità testo grande.
- Pannello di vittoria/sconfitta/pareggio con pergamena,
  gerarchia tipografica coerente e pulsante Riprova con hover.
  La sua hitbox resta **esattamente** x=780..1130, y=540..585.
- Geometrie della scheda e del pannello finale isolate in un
  modulo di sola presentazione, con verifica degli ingombri.

### Verifiche e limiti
- `tests/bot_duel_parchment_view_test.lua`: stato live e finale,
  vittoria/Monaco/pareggio, 720p/1080p/1440p,
  testo grande, contrasto, bilanciamento grafico,
  richiamo dell'animazione e hitbox Riprova invariata.
- Nessuna modifica al modello dei duelli, bot, scoring, dadi g3d,
  fisica, camera, salvataggi, movimento della miniatura o
  splash rosa/azzurro con cuore del motore LÖVE.
- CI e screenshot in-game Windows LÖVE ancora da verificare.

## [0.1.0-dev.12] - 2026-11-01

**Tipo:** rifinitura esclusivamente grafica della composizione HUD UI 2.0.

### Modificato
- La colonna laterale di lavoro ora ha una cornice da legatura
  con doppio filo, piccole tacche d'angolo e separatore
  decorativo fra il folio e il pannello Strumenti.
- Le due possibili righe di azioni contestuali usano rettangoli
  esplicitamente dichiarati nel layout e identici alle precedenti
  hitbox del controller; nessun comando aggiunto o rimosso.
- Il titolo del registro dei sei dadi accantonati è stato spostato
  nel margine superiore libero della pagina, prima dei riquadri,
  così da non essere nascosto dalla presentazione di ogni dado.
- I sei riquadri del registro hanno ora tinte da pergamena e
  inchiostro, con evidenziazione ocra dei dadi contribuenti.
  Portrait g3d, dimensioni slot e posizioni invariati.

### Verifiche e limitazioni
- Nuovo `tests/ui_v2_sidebar_composition_test.lua` per solitario
  e Monaco a 720p, 1080p e 1440p: geometrie sidebar,
  leggibilità intestazione, assenza di sovrapposizioni con il tray,
  hitbox, bilanciamento dello stack grafico e immutabilità del Farkle.
- CI Lua 5.4/LuaJIT e Python da verificare; screenshot grafici
  Windows LÖVE e contrasto alto sono ancora da approvare.
- Nessuna modifica a Farkle, g3d, dadi 3D, camera, fisica,
  ricompense, salvataggi o splash rosa/azzurro del motore LÖVE.

## [0.1.0-dev.11] - 2026-10-31

**Tipo:** leggibilità e gerarchia visiva dell'HUD Farkle, soltanto interfaccia.

### Modificato
- Intestazione della commissione organizzata in celle misurate per
  nome, obiettivo, punti assicurati, punti a rischio e turni restanti;
  aggiunte sottili linee separatrici tra le informazioni.
- Etichette dei pulsanti e numeri dell'HUD adattati alle dimensioni
  effettive dei font e allo spazio disponibile: riduzione controllata
  della misura ed eventuale abbreviazione UTF-8 sicura invece di righe
  sovrapposte o caratteri spezzati.
- Il messaggio di stato Farkle è ora su una fascia di pergamena
  leggibile, con colore d'allerta in caso di Farkle/fallimento.
- Nessuna modifica alle aree cliccabili, alla proiezione 3D,
  alle regole Farkle, allo scoring o ai contenuti dei messaggi.

### Verifiche e limiti
- `tests/ui_v2_readability_test.lua`: controllo dei limiti delle
  celle, dell'adattamento testo, del layout a 720p/1080p/1440p,
  dello stato di partita e delle hitbox invariate.
- Lua 5.4/LuaJIT e i gate di CI da verificare prima del merge.
- QA grafica LÖVE Windows ancora aperta per contrasto, font reali,
  pulsanti a testo grande e corrispondenza con dadi g3d.
- Splash originale rosa/azzurro con cuore del motore LÖVE invariato.

## [0.1.0-dev.10] - 2026-10-31

**Tipo:** polish esclusivamente grafico dell'HUD Farkle UI 2.0.

### Modificato
- Intestazione della commissione e pannello Strumenti ridisegnati
  con toni pergamena, bordi d'inchiostro e testo bruno ad alto contrasto;
  tolti i precedenti riquadri quasi neri.
- Pulsanti primari, secondari, contestuali e di navigazione
  nello stesso stile delle voci del menu, tramite
  `src/features/ui_v2/menu_surface.lua`, con stati disabilitati
  chiaramente distinguibili al posto del vecchio pulsante verde.
  Hover evidenziato usando il passaggio canonico da coordinate
  dello schermo a quelle virtuali, senza cambiare il click.
- Geometrie del tavolo, pagina del manoscritto, area di lancio g3d,
  raccoglitore dei dadi e disposizione degli hitbox **immutate**.
  Nessuna duplicazione dell'HUD e nessun ramo legacy.

### Verifiche e limiti
- Nuovo `tests/ui_v2_parchment_hud_test.lua`: mock di disegno e
  geometrie a 720p/1080p/1440p, controlli di input, colori del
  folio e immutabilità dei punteggi Farkle.
- CI Lua 5.4/LuaJIT da verificare; QA visiva con LÖVE su Windows
  ancora necessaria per spaziature, hover, contrasto e texture 3D.
- Nessuna modifica a Farkle, bot Monaco, dadi, g3d, fisica, salvataggi,
  impostazioni o splash originale del motore LÖVE.

## [0.1.0-dev.9] - 2026-10-31

**Tipo:** UI 2.0 — redesign della schermata Settings.
**Conservato integralmente** lo splash originale del motore LÖVE,
con i suoi colori rosa e azzurro e il cuore: non è materiale
legacy di Project Folio e non va confuso con la GUI del gioco.

### Modificato
- `src/features/settings/module.lua`: le cinque sezioni e
  le schermate dei controlli utilizzano ora la superficie
  di pergamena condivisa `ui_v2/menu_surface.lua`,
  con righe selezionabili, tinta d'inchiostro e ornamenti.
- Eliminate dalla sola Settings le quattro fasce
  nere del vecchio layout; resta visibile lo sfondo
  illustrato della bottega.
- Font delle Settings dimensionati in funzione
  dell'altezza della finestra, oltre alla scala UI
  e all'opzione testo grande. I rettangoli cliccabili
  non vengono spostati rispetto a quelli disegnati.
- `settings_ui_schema.lua`: eliminati colori storici
  non più letti e adeguati oro e toni secondari
  a inchiostro su pergamena. Nome predefinito
  corretto in `Project Folio`.
- Conservati `SettingsState.save/apply`, le cinque
  sezioni Game/Controls/Accessibility/Video/Audio,
  le regolazioni slider, l'anteprima audio,
  `Reset`, `Confirm`, `Back`, i relativi
  eventi e il comportamento della navigazione.

### Verifiche
- `tests/settings_folio_layout_test.lua`:
  verifica sezioni, controlli, slider, pulsanti e
  pagine a 1280×720, 1920×1080 e 2560×1440;
  accerta che lo **splash LÖVE** continui a mostrare
  la propria animazione e mantenga lo skip
  da tastiera/mouse.
- Test di regressione Settings, Lua 5.4/LuaJIT,
  Python e FPS Lab da verificare in CI.
- **QA grafica Windows ancora aperta** per
  contrasto, selezione, font e clic reali.
- Nessuna modifica a Farkle, dadi g3d, fisica,
  miniature 2D o progressione. Nessun
  fallback HUD legacy introdotto.

## [0.1.0-dev.8] - 2026-10-31

**Tipo:** redesign visivo del frontend e unificazione delle superfici
del manoscritto, successivo al cutover definitivo UI 2.0.
**Nessuna reintroduzione del vecchio HUD né modifica al Farkle.**

### Aggiunto
- `src/features/ui_v2/menu_surface.lua`: geometria pura e
  rendering condiviso per pergamene, bordi ornamentali,
  righe selezionabili e separatori, riutilizzato dal menu
  principale, dalla scelta commissioni e dai dialoghi
  della UI 2.0. Conservata la scena illustrata sullo sfondo.
- `tests/frontend_folio_surface_test.lua`: verifica in
  ambiente Lua headless geometrie a 1280×720,
  1920×1080 e 2560×1440, tutte le **sei azioni**
  del menu, il controllo volume e i comandi della
  campagna dentro l'area visibile e senza sovrapposizioni;
  controlla inoltre che non tornino le bande nere legacy.

### Modificato
- Il menu principale non disegna più quattro fasce
  nere opache: presenta una **pagina di pergamena**
  laterale con testi color inchiostro, titoli
  medievali, sei righe interattive, evidenziazione
  oro/ocra e versione canonica leggibile.
- La selezione della commissione utilizza una
  **pagina centrale** e card coerenti con il
  menu, mantenendo `Farkle Roguelite` e `Back`.
  Gli hitbox coincidono con il disegno; le
  dimensioni dei caratteri ora dipendono anche
  dall'altezza della finestra.
- I dialoghi, le opzioni e le ricompense usano
  gli stessi bordi, pannelli e pulsanti della UI 2.0,
  senza cambiare le callback, l'ordine delle
  opzioni o i dati del gioco.
- Eliminati vecchi colori del menu commissioni
  rimasti inutilizzati e la funzione grafica
  di un ornamento non più chiamato.
- Versione canonica `0.1.0-dev.7` → `0.1.0-dev.8`.

### Verifiche e limiti
- I test automatici e il gate versione/changelog
  sono eseguiti via GitHub Actions; **il risultato
  effettivo va verificato prima del merge**.
- La GUI usa ancora la grafica illustrata esistente
  e alcuni font/copy storici; il redesign di
  `startup_splash` e impostazioni è separato.
- **QA grafica reale Windows LÖVE ancora aperta**:
  verifica contrasto, interazioni e hitbox,
  menu/commissione/dialoghi a 720p e 1080p,
  testi grandi, animazioni ridotte e screenshot.
- Farkle, g3d, bot, sei dadi fisici, RNG, miniature
  2D, progressione e salvataggi **invariati**.

## [0.1.0-dev.7] - 2026-10-31

**Tipo:** rimozione definitiva del fallback dell'HUD legacy e cutover
della schermata di gioco a UI 2.0. Nessuna modifica alle regole
di Farkle, alla fisica o al rendering 3D g3d.

### Rimosso
- `src/features/farkle/hud_minimal.lua` e il percorso di drawing,
  overlay e pulsanti della vecchia schermata di gioco.
- Variabile `MANUSCRIPT_UI_V2_EXPERIMENT`, biforcazione HUD
  e scorciatoia F6 che ritornava alla UI precedente.
- `src/features/farkle/hud.lua` dopo aver trasferito i
  dialoghi e le ricompense in `ui_v2/dialogs.lua`.
- `tests/smoke/compare_huds.lua`, confronto storico fra
  due HUD ormai inesistenti. Nessun fallback CPU/3D ripristinato.
- Coordinate inutilizzate `H.tray`, `H.slots` e `H.feedback`
  dal modello di presentazione Farkle; la geometria unica
  è definita da `ui_v2/layout_candidates.lua`.

### Aggiunto
- `ui_v2/accepted_dice.lua`: canalina/registro 2D dei
  sei dadi accantonati sulla pagina, con ritratti g3d
  originali e feedback sulle combinazioni; fuori dalla
  superficie di lancio dei dadi fisici.
- Test `tests/ui_v2_no_legacy_fallback_test.lua` per
  proteggere la UI 2.0 come unico percorso di gameplay,
  geometrie della canalina, viewport e non-mutazione
  dello stato Farkle.

### Modificato
- `controller.lua` e `ui_v2/hud.lua` chiamano soltanto
  l'HUD nuovo e i suoi componenti indipendenti per
  shelf, indicatori fisici/scoring, dialoghi e ricompense.
- Nella sfida al Monaco la pagina si sposta sotto il
  pannello di stato, eliminando la sovrapposizione
  evidente nella schermata utente.
- Test inventario, modali, percorsi di produzione e
  dipendenze renderer adeguati per **vietare il ritorno
  dei file di fallback**.
- Versione canonica `0.1.0-dev.6` → `0.1.0-dev.7`;
  documentati nuovo percorso unico e limiti della QA.

### Ulteriori correzioni dopo i test
- L'inizializzazione di Lovely Toasts è esclusivamente
  grafica: nei test headless, `Toast.show` non può
  caricare il font prima dell'esistenza di LÖVE.
  Aggiornato `tests/lovely_toasts_adapter_test.lua`.
- Eliminato da `main.lua` l'ultimo hook
  `MANUSCRIPT_HUD_COMPARISON` che richiamava lo smoke
  tra due HUD ormai eliminati.
- [CI #41240278666](https://github.com/Askeladd22/Project_Folio/actions/runs/41240278666)
  **superata**: Lua 5.4, LuaJIT, benchmark degli Incontri,
  laboratorio FPS nativo, test Python e gate versione.

### Verifiche e limiti
- CI Lua 5.4, LuaJIT, FPS Lab nativo e Python da
  verificare nell'esecuzione della PR. Nessuna
  certificazione grafica Windows viene dedotta dai
  test headless.
- Dialoghi e ricompense **restano funzionalmente
  equivalenti**, ma la loro estetica sarà oggetto
  del prossimo redesign. Menu principale e scelta
  commissioni hanno asset/pannelli da rifinire.
- **QA manuale ancora aperta**: avvio normale,
  sfida al Monaco, tiri Farkle, dadi accantonati,
  modali, ricompense, scorciatoie e layout
  1280×720/1920×1080, comprese opzioni di accessibilità.

## [0.1.0-dev.6] - 2026-10-31

**Tipo:** secondo esperimento isolato sui Segni; riallineamento dei
controlli del benchmark e test contro strategie dominanti.
**Nessuna modifica al gioco principale.**

### Corretto
- Risolto il confronto metodologicamente diseguale della prima
  variante B: B, C0 e C richiedono ora tutte **tre marche in
  massimo sei mani**; la baseline A mantiene la prima
  commissione ufficiale a quattro mani e 100 punti.
- Evitata la correlazione dei dadi virtuali introdotta dal
  semplice offset numerico fra semi. Il generatore di laboratorio
  usa ora una mescolatura non lineare portabile Lua 5.1/5.4,
  con test sulla varietà di 256 mani iniziali.

### Aggiunto
- **C0 (ablation test):** stesso sacchetto e forze della C
  ma senza i premi di due marche. Permette di isolare
  l'effetto dei bonus di Assalto e Occasione.
- **Confronto accoppiato** con stesso seme, mano,
  rilancio e ID dado per politiche differenti; le
  estrazioni del sacchetto sono indipendenti dai dadi
  ma riprodotte con lo stesso seme.
- Rapporti per categoria (Assalto, Guardia, Occasione)
  con frequenze incasso/rilancio e situazioni in cui
  le politiche dissentono; confronti B→C e C0→C
  con differenze osservate e intervalli descrittivi
  approssimativi al 95%.
- Test di regressione su stream virtuali, obiettivi
  dei controlli, C0 senza marche doppie, ripetibilità
  e coerenza dei confronti accoppiati.

### Modificato
- Versione canonica `0.1.0-dev.5` → `0.1.0-dev.6`.
- README e specifiche del laboratorio aggiornata la
  distinzione tra protocollo dev.5 e quello nuovo.
- Benchmark CI con campione più ampio ma di sola diagnostica.

### Risultati verificati in CI

- **256 scenari per strategia, seme iniziale 20261031**:
  in C, successo del 63,7% (prudente), 55,9% (audace)
  e 66,0% (reattiva); in C0, rispettivamente
  64,5%, 59,8%, 68,4%. Gli intervalli approssimativi
  dei delta accoppiati C0→C includono tutti lo zero:
  i bonus non hanno ancora dimostrato un vantaggio
  netto in questa fixture.
- Rapporto con numeri, semi, confronti B→C e C0→C,
  esiti accoppiati e limiti statistici:
  [`experiments/signs_lab/RESULTS_2026_10_31.md`](experiments/signs_lab/RESULTS_2026_10_31.md).
- [Workflow di verifica #41236347898](https://github.com/Askeladd22/Project_Folio/actions/runs/41236347898)
  superato per Lua 5.4, LuaJIT, test degli incontri,
  benchmark a 256 semi, FPS Lab nativo e Python.
  Nessuna QA grafica LÖVE effettuata.

### Limiti e gate
- I semi appaiati riducono una fonte di variabilità,
  ma non rendono identici gli stati raggiunti dopo
  decisioni differenti; non provano superiorità,
  bilanciamento o interesse delle scelte.
- Il gioco rimane Farkle con **sei dadi fisici g3d,
  personaggi 2D e duello beta al Monaco invariati**.
  La promozione di Incontri e Segni richiede ancora
  un vero playtest, studio dell'eventuale strategia
  prudente dominante e approvazione del design.
- Prove automatiche Lua 5.4, LuaJIT, FPS, Python e
  gate versione richiesti alla CI; nessuna prova
  grafica Windows LÖVE viene dichiarata eseguita.

## [0.1.0-dev.5] - 2026-10-31

**Tipo:** esperimento di game design riproducibile, non nuova funzione
della campagna né modifica alle regole Farkle approvate.

### Aggiunto
- Laboratorio isolato `experiments/signs_lab/` per verificare
  l'ipotesi di **Incontri asimmetrici e Duello delle Poste**.
  Il `Leone della Bordura` dispone di un sacchetto di sei Segni
  (Assalto, Guardia, Occasione) con forze e conseguenze
  **esplicitamente provvisorie** tratte dal documento di design.
- Sacchetto deterministico con **pesca senza reinserimento**,
  categoria annunciata prima della scelta di rischio, forza
  rivelata solo alla risoluzione, scarti e riciclo solo
  dopo esaurimento.
- Simulatore A/B/C in Lua puro, con le **vere** funzioni
  di `src/gameplay/farkle/rules.lua` per lanciare virtualmente,
  scegliere combinazioni, accantonare, rilanciare, incassare
  o perdere il provvisorio al Farkle. Non viene alterato il
  gioco fisico né il RNG globale.
- Tre politiche di rischio diagnostiche (prudente, audace,
  reattiva alla categoria annunciata), con tabella
  riproducibile di frequenze, durata, Farkle, scelte
  e stati di disaccordo. Comando:
  `luajit experiments/signs_lab/run.lua 100 20261031`.
- Nuovi test `tests/signs_encounter_lab_test.lua` per
  forza non rivelata, un solo Segno per mano completata,
  riciclo, vincita/sconfitta/parità, esiti Farkle,
  punteggio ufficiale e assenza di hook in produzione.

### Modificato
- `version.txt` da `0.1.0-dev.4` a `0.1.0-dev.5`.
- Aggiornati documento Incontri e Segni, Game Design,
  README e istruzioni del laboratorio, distinguendo
  **fixture sperimentale** e gameplay effettivo.
- Il workflow di regressione esegue un breve benchmark
  a seme fisso oltre ai test automatici.

### Verifiche e limiti
- Controlli Lua 5.4/LuaJIT, laboratorio fisico FPS e test
  Python richiesti via CI; **nessun playtest Windows LÖVE
  e nessuna approvazione di bilanciamento**.
- Le percentuali di successo A, B e C **non sono
  confrontabili come misura di difficoltà**, perché
  gli obiettivi e i massimi di mani differiscono.
  L'analisi serve a individuare scelte dominate e
  domande per un vero playtest.
- **Non modifica** `main.lua`, controller Farkle,
  g3d, fisica, menu, ricompense, medaglie o
  il beta simmetrico contro il Monaco.

## [0.1.0-dev.4] - 2026-10-31

**Tipo:** hotfix per crash di avvio segnalato su Windows LÖVE.
**Base:** `0.1.0-dev.3` (PR #41 del Monaco già integrata);
nessuna modifica al gameplay, ai controlli o alle miniature 2D.

### Corretto
- Eliminato `src/app/dice_runtime.lua:761: attempt to index global
  'light' (a nil value)` durante `spawn_initial_dice()`.
  La PR #38 aveva eliminato correttamente l'import del vecchio painter
  CPU, ma lasciato il riferimento obsoleto `light.plastic` nella
  creazione dei dadi.
- Rimossa la proprietà `die.material` del renderer CPU ormai dismesso.
  **g3d resta l'unico renderer 3D**, senza aggiungere import,
  materiali alternativi o fallback. Preservati i materiali fisici
  `bone`, corpi, facce, colori e geometrie D6/D8.

### Test
- Nuovo `tests/dice_startup_g3d_only_test.lua`: estrae e invoca
  **l'effettiva funzione** `spawn_initial_dice()` del runtime,
  con ambiente fisico minimo e `light` assente. Verifica la
  generazione e registrazione di tutti i dadi, incluso D8 dove
  previsto, e l'applicazione del materiale fisico.
- Esteso `tests/renderer_dependency_test.lua` per bloccare
  il ritorno di riferimenti a `light.plastic` e
  `material = die_material`.
- Gate CI Lua 5.4, LuaJIT, FPS Lab e Python da verificare
  sull'esecuzione della PR. **Avvio grafico Windows non ancora
  riprovato**: serve confermare che la schermata iniziale
  e i dadi siano visualizzati correttamente in LÖVE.

## [0.1.0-dev.3] - 2026-10-31

**Tipo:** presentazione dell'incontro beta, senza modifiche al punteggio o
alla fisica dei dadi. **Stato:** prototipo, non release pubblica.

### Aggiunto
- **Prima ricomposizione visiva del folio dopo un incontro:** il Monaco,
  figura piana 2D, emerge dalla pagina a inizio duello e torna alla
  miniatura quando il giocatore lo sconfigge. In caso di sconfitta o
  parità non viene mostrata una falsa vittoria.
- Resoconto leggibile della sfida nel margine del manoscritto:
  punteggi effettivi del giocatore e del bot, mano corrente,
  obiettivo della commissione, **facce dell'ultimo tiro virtuale**
  con trattini per i dadi non rilanciati, incasso o Farkle.
  Tutti i valori provengono dai rapporti reali di `Rules`; nessun
  lancio, bonus o avversario 3D viene creato dalla UI.
- Modello puro `src/features/farkle/bot_duel_presentation.lua`
  separato da LÖVE e dalla logica dell'avversario; test headless
  `tests/bot_duel_presentation_test.lua` per rendicontazione,
  duplicati, vittoria/sconfitta/parità e replay.

### Corretto
- Il pulsante **R / Riprova** ricrea la presentazione del Monaco,
  eliminando il risultato e le transizioni 2D della partita precedente.
- La modalità **animazioni ridotte**, attivata anche durante
  una transizione Flux già avviata, ora sposta immediatamente la
  miniatura alla destinazione corretta anziché lasciarla a metà.
  Aggiornati i test del toolkit delle miniature 2D.

### Test e limitazioni
- CI Lua 5.4 / LuaJIT, laboratorio FPS nativo e test Python
  richiesti dalla PR, senza considerare superate verifiche prima
  dell'esito effettivo.
- La miniatura è ancora un disegno originale **provvisorio**,
  generato dal codice. L'esecuzione Windows LÖVE a 1280×720 e
  1920×1080, l'eventuale sovrapposizione con la UI v2 e il
  ritmo della transizione richiedono **QA grafica reale**.
- La modalità è sempre il beta Farkle contro Farkle della
  [PR #36](https://github.com/Askeladd22/Project_Folio/pull/36),
  non il sistema di Incontri e Segni né una nuova regola
  di completamento della run.

## [0.1.0-dev.2] - 2026-10-31

**Tipo:** documentazione storica verificabile, senza variazioni a gameplay, renderer o risorse.
**Stato:** incremento della versione di sviluppo, non release pubblica.

### Aggiunto
- Ricostruzione retrospettiva dalla **prima importazione del 6 marzo 2026**,
  dalle specifiche e dai prototipi Farkle del 1–2 luglio, dalla
  trasformazione in libro/tray del 16 ottobre e dall'evoluzione fino
  al 31 ottobre. Le tappe sono distinte per periodo e collegano i
  commit pre-PR verificabili.
- **Indice completo delle 39 pull request integrate (#1–#39)**, ognuna
  con data di merge e link alla sua cronologia GitHub, più una
  ricostruzione tematica di renderer g3d, dadi fisici, UI 2.0, bot e
  librerie 2D. I PR #1–#39 erano già integrati prima di questa versione.
- Test automatico `tests/changelog_retrospective_test.lua` per
  preservare l'indice delle 39 PR e le origini del Farkle.
- Distinzione esplicita fra la **semplice IA Farkle sperimentale
  del luglio 2026** e il **Monaco beta** introdotto dalla PR #36.
  Le funzionalità eliminate in seguito non sono presentate come attuali.

### Modificato
- Incrementata la versione canonica da `0.1.0-dev.1` a
  `0.1.0-dev.2`, visibile nel menu attraverso `version.txt`.
- La precedente voce `0.1.0-dev.1` resta intatta come fotografia
  della prima baseline formalmente versionata; il materiale precedente
  non riceve versioni SemVer inventate.

### Verifiche e limiti
- Provenienza ricontrollata attraverso la storia commit e l'API GitHub:
  **39 PR numerate, tutte integrate**, nessuna release pubblica
  ricostruita artificialmente. Cronologia precedente non equivale
  alla presenza di quei moduli nel sorgente attuale.
- Nessuna build GPU/LÖVE Windows o sessione di gameplay aggiuntiva
  eseguita da questo intervento: restano da svolgere i gate grafici
  documentati in `docs/UI_V2_STATUS.md` e
  `docs/RENDERER_RETIREMENT.md`.
- I test CI di versionamento e regressione vengono eseguiti su questa PR;
  il loro risultato va verificato prima del merge.

## [0.1.0-dev.1] - 2026-10-31

**Tipo:** baseline iniziale del sistema di versionamento (prototipo in sviluppo).
**Stato:** prima versione tracciata formalmente, non release commerciale.

### Aggiunto
- Prima fonte di versione ufficiale `version.txt`, consultabile dal menu.
- Changelog cumulativo `CHANGELOG.md` e procedure di versionamento in
  `docs/VERSIONING.md`, con controllo automatico nelle PR.
- **Modalità beta contro il Monaco**: avversario Farkle con dadi virtuali
  indipendenti, stessa tabella ufficiale, miniatura 2D e punteggi affiancati
  ([PR #36](https://github.com/Askeladd22/Project_Folio/pull/36)).
- Librerie opzionali per le miniature e i testi 2D: **anim8, Flux, SYSL-Text**;
  vignettatura 2D sperimentale con **Moonshine** e laboratorio dedicato
  ([PR #35](https://github.com/Askeladd22/Project_Folio/pull/35)).
- Notifiche contestuali non bloccanti con **Lovely Toasts**, integrate nel
  laboratorio delle miniature e nella sfida al Monaco
  ([PR #36](https://github.com/Askeladd22/Project_Folio/pull/36)).

### Modificato
- Consolidato **g3d come unico renderer 3D** per dadi e tray, eliminando il
  painter CPU, il toggle F9 e i relativi fallback; F8/F10/F11 restano per
  le opzioni g3d ([PR #38](https://github.com/Askeladd22/Project_Folio/pull/38)).
- Ampliato il prototipo UI 2.0: studio dei layout, vertical slice giocabile,
  indicatori discreti per selezione, rischio e dadi accantonati
  ([PR #31](https://github.com/Askeladd22/Project_Folio/pull/31),
  [#32](https://github.com/Askeladd22/Project_Folio/pull/32),
  [#34](https://github.com/Askeladd22/Project_Folio/pull/34)).
- Adottato **Project Folio** come titolo pubblico provvisorio
  ([PR #33](https://github.com/Askeladd22/Project_Folio/pull/33)).

### Rimosso / pulizia
- Eliminati **32 file** del vecchio HUD cromatico, immagini non referenziate,
  test obsoleti e screenshot FX rigenerabili; mantenuti fisica, laboratori
  utili e texture attive
  ([PR #37](https://github.com/Askeladd22/Project_Folio/pull/37)).
- Rimossi fallback e painter 3D legacy, con documentazione di migrazione
  ([PR #38](https://github.com/Askeladd22/Project_Folio/pull/38)).

### Test e limiti conosciuti
- CI headless Lua 5.4/LuaJIT, Python e laboratorio FPS superata nelle PR
  richiamate. **La prova visiva Windows LÖVE reale a 1280×720 e 1920×1080
  resta un gate aperto**, in particolare per g3d, accantonamento, UI 2.0,
  notifiche e bot. I test headless non certificano shader e GPU.
- La sfida al Monaco è una modalità beta Farkle contro Farkle, **non** ancora
  il sistema definitivo di incontri asimmetrici e Segni.
- Le figure e gli avversari sono **2D**; i soli dadi e tray sono **3D**.

## Cronologia retrospettiva — prima del primo numero di versione ufficiale

> **Nota metodologica:** fino alla PR #39 del 31 ottobre 2026,
> `version.txt` **non esisteva**. Il footer `v0.1` era
> un'etichetta hardcoded del prototipo. Di conseguenza i periodi
> sottostanti sono tappe di **sviluppo**, non versioni o release
> numerate. Le informazioni derivano dai commit pubblici e dalle
> PR effettivamente integrate. Elementi successivamente rimossi
> sono indicati come *storici*.

### 6 marzo 2026 — importazione iniziale

- [`520f09a`](https://github.com/Askeladd22/Project_Folio/commit/520f09a210):
  primi file caricati nel repository.
- [`6904833`](https://github.com/Askeladd22/Project_Folio/commit/6904833677):
  ulteriore aggiornamento iniziale. I due titoli di commit non
  dettagliano funzionalità e non consentono di attribuirne con
  certezza una specifica.

### 1–2 luglio 2026 — specifiche Farkle, punteggio e prime IA

- [`a2758fe`](https://github.com/Askeladd22/Project_Folio/commit/a2758fed37):
  specifica del Farkle nello Scriptorium.
- [`e0b9326`](https://github.com/Askeladd22/Project_Folio/commit/e0b9326fd6)
  e [`1e55611`](https://github.com/Askeladd22/Project_Folio/commit/1e5561142c):
  progetto di una variante Farkle **1 contro 1**.
- [`42532c0`](https://github.com/Askeladd22/Project_Folio/commit/42532c09e7),
  [`ea836ac`](https://github.com/Askeladd22/Project_Folio/commit/ea836aca43)
  e [`06b4fa0`](https://github.com/Askeladd22/Project_Folio/commit/06b4fa05c5):
  scoring Farkle puro, correzioni di normalizzazione e stabilizzazione
  delle combinazioni di punteggio.
- [`601ab84`](https://github.com/Askeladd22/Project_Folio/commit/601ab841f9),
  [`cf4d7d8`](https://github.com/Askeladd22/Project_Folio/commit/cf4d7d84ad)
  e [`c1e7f61`](https://github.com/Askeladd22/Project_Folio/commit/c1e7f6171e):
  stato di partita Farkle, verifica del numero di lanci e
  **semplice IA sperimentale**. Quella IA non va confusa con
  il Monaco beta della PR #36, né presunta ancora presente dopo
  i refactor successivi.
- [`7cb8f12`](https://github.com/Askeladd22/Project_Folio/commit/7cb8f12249):
  percorso alternativo per eseguire i test tramite lovec.

### 16 ottobre 2026 — riorganizzazione e libro come tray

- [`d6d100f`](https://github.com/Askeladd22/Project_Folio/commit/d6d100fcd2):
  refactoring e aggiornamento del gameplay.
- [`53aa4b7`](https://github.com/Askeladd22/Project_Folio/commit/53aa4b7940),
  [`3a17a73`](https://github.com/Askeladd22/Project_Folio/commit/3a17a73a61),
  [`7f3e8d7`](https://github.com/Askeladd22/Project_Folio/commit/7f3e8d7eb8),
  [`28442cb`](https://github.com/Askeladd22/Project_Folio/commit/28442cb176)
  e [`d206bad`](https://github.com/Askeladd22/Project_Folio/commit/d206bad336):
  rimozione di vecchi moduli/test, backup e directory temporanee,
  audit e codice legacy. Si tratta di pulizie storiche,
  non di materiali ancora disponibili nella `main` attuale.
- **PR #1–#2:** prime varianti selezionabili del libro/tray,
  pagine di pergamena e cornice del codice; revisione dell'HUD,
  rimozione della precedente variante grafica F9 dell'interfaccia
  e conservazione dei pannelli modali condivisi.
  Non confondere questa rimozione UI con il **fallback renderer
  CPU/3D F9** eliminato solo dalla PR #38.

### 30 ottobre 2026 — stabilizzazione, g3d e dadi manipolabili

- **PR #3:** accettazione valida dei tiri Farkle, distinzione
  fra ripetizione fisica e tiro logico, seed diagnostico,
  impostazioni sicure in formato dati, isolamento di regole/commissioni,
  test headless Lua 5.4 e LuaJIT. Documentata la direzione narrativa
  delle miniature avversarie e dei Segni, ancora da sperimentare.
- **PR #4–#6:** primo laboratorio g3d su sei dadi fisici condivisi,
  due renderer in confronto A/B, camera equivalente, pareti del
  tray, prestazioni diagnostiche e avvio isolato. Il confronto
  con il painter CPU è storico: sarà eliminato il giorno successivo.
- **PR #7, #9–#10, #13:** laboratori con Free Physics Solver:
  prove isolate e seeded, compenetrazione del piano, sensibilità a
  substep 2×/4×, gestione del contatto, sonno e riattivazione.
  Il laboratorio **non** sostituisce la fisica di produzione.
- **PR #8, #12, #14, #19–#20:** g3d diventa renderer predefinito;
  vengono trasferite varianti F8, separatori e geometrie; materiali,
  luce e normali F10, smussi visivi F11 e puntini incisi. Il
  fallback CPU era inizialmente conservato, poi rimosso dalla PR #38.
- **PR #11, #16:** documentazione bilingue e rimozione del pacchetto
  PNG del banco originale non utilizzato.
- **PR #15, #17–#18:** presa e rilascio con mouse, gesti con inerzia,
  manipolazione di singoli dadi, selezione multipla a rettangolo
  e lancio coordinato, senza cambiare la tabella Farkle.

### 31 ottobre 2026 — fisica da tavolo, UX e nuova direzione

- **PR #21–#24:** miglioramenti visivi D6 (smusso, ombre,
  lettura dei semi); raccolta fisica dei dadi sotto il mouse,
  oscillazione della mano e rilascio, mucchio 3D credibile,
  zoom esclusivamente durante la presa di gruppo. Le
  ispirazioni esterne sono state adattate tramite codice proprio.
- **PR #25–#26:** laboratorio FPS con presa a forza e
  **handoff fisico senza perdita** dal laboratorio verso il
  solver Manuscript, in prove isolate: non equivale a migrare
  il motore della partita.
- **PR #27–#32, #34:** roadmap UI 2.0 con gate, baseline
  accessibilità/gesture e screenshot di controllo, studio folio
  singolo vs codice aperto, vertical slice con HUD sperimentale F6
  e indicatori più compatti. **QA visiva Windows ancora aperta**.
- **PR #33:** denominazione pubblica provvisoria **Project Folio**
  (titolo storico Scriptorium/Manuscript preservato dove necessario).
- **PR #35:** toolkit 2D opzionale (anim8, Flux, SYSL-Text,
  Moonshine solo per pass 2D) e laboratorio di miniature;
  personaggi e figure restano **2D**, dadi e tray **3D**.
- **PR #36:** Lovely Toasts e duello beta **contro il Monaco**,
  con regole Farkle ufficiali e RNG del bot indipendente.
  È una sfida di prova e **non** il sistema definitivo asimmetrico
  di Incontri e Segni.
- **PR #37:** eliminazione di 32 file inutilizzati,
  codice cromatico obsoleto e screenshot FX riproducibili;
  texture attiva del tray e fisica preservate.
- **PR #38:** rimozione definitiva del painter CPU, del toggle
  F9 di rendering, dei fallback e della cattura CPU dei
  ritratti dei dadi; g3d diventa l'unico renderer 3D.
- **PR #39:** prima versione ufficiale `0.1.0-dev.1`,
  menu collegato a `version.txt`, `CHANGELOG.md` cumulativo
  e controllo CI obbligatorio a ogni aggiornamento.

## Indice integrale — pull request precedenti alla versione 0.1.0-dev.2

Ogni riga è un aggiornamento **integrato in `main`**. Le date sono
quelle effettive di merge in UTC; i titoli riprendono
l'oggetto originale della PR e i link rimandano alle modifiche.
L'indice copre **PR #1–#39 (39/39 integrate)** e non attribuisce
a nessuna una release pubblica numerata distinta.

- **2026-10-16 — [PR #1](https://github.com/Askeladd22/Project_Folio/pull/1):** Prototype open codex tray as selectable visual workshop variant
- **2026-10-16 — [PR #2](https://github.com/Askeladd22/Project_Folio/pull/2):** Libro-tray: pagina giocabile e rimozione del vecchio HUD F9
- **2026-10-30 — [PR #3](https://github.com/Askeladd22/Project_Folio/pull/3):** Stabilize dice acceptance, safe settings, physics and Farkle architecture
- **2026-10-30 — [PR #4](https://github.com/Askeladd22/Project_Folio/pull/4):** Experiment: isolated g3d GPU vs original Manuscript renderer with shared physics
- **2026-10-30 — [PR #5](https://github.com/Askeladd22/Project_Folio/pull/5):** Lab 2: parity camera, complete tray rims and isolated renderer benchmarks
- **2026-10-30 — [PR #6](https://github.com/Askeladd22/Project_Folio/pull/6):** Lab 3: experimental g3d rendering in playable Scriptorium (F9 fallback)
- **2026-10-30 — [PR #7](https://github.com/Askeladd22/Project_Folio/pull/7):** Physics Lab 1: Free Physics Solver vs Manuscript, isolated seeded A/B
- **2026-10-30 — [PR #8](https://github.com/Askeladd22/Project_Folio/pull/8):** Promote g3d to default Scriptorium book renderer (legacy F9 fallback)
- **2026-10-30 — [PR #9](https://github.com/Askeladd22/Project_Folio/pull/9):** Physics Lab 2: diagnose FPS floor penetration; retain still-used legacy renderer
- **2026-10-30 — [PR #10](https://github.com/Askeladd22/Project_Folio/pull/10):** Physics Lab 2 follow-up: test FPS at 2x and 4x substeps
- **2026-10-30 — [PR #11](https://github.com/Askeladd22/Project_Folio/pull/11):** Docs: professional English/Italian repository README
- **2026-10-30 — [PR #12](https://github.com/Askeladd22/Project_Folio/pull/12):** g3d: migrate F8 tray variants, dividers and D8 rendering
- **2026-10-30 — [PR #13](https://github.com/Askeladd22/Project_Folio/pull/13):** Physics Lab 3: instrument FPS support, airborne sleep and optional wake
- **2026-10-30 — [PR #14](https://github.com/Askeladd22/Project_Folio/pull/14):** g3d: simplify book tray, use real depth floor and preserve clean F9 fallback
- **2026-10-30 — [PR #15](https://github.com/Askeladd22/Project_Folio/pull/15):** Farkle: grab a die with right mouse and throw active dice using drag momentum
- **2026-10-30 — [PR #16](https://github.com/Askeladd22/Project_Folio/pull/16):** Chore: remove unused Scriptorium desk prototype PNG pack
- **2026-10-30 — [PR #17](https://github.com/Askeladd22/Project_Folio/pull/17):** Tabletop-style physics: pick up, rotate and throw each Farkle die separately
- **2026-10-30 — [PR #18](https://github.com/Askeladd22/Project_Folio/pull/18):** Tabletop dice: marquee select multiple dice and throw selected group together
- **2026-10-30 — [PR #19](https://github.com/Askeladd22/Project_Folio/pull/19):** g3d dice: normal diagnostics and warm ivory lighting (F10 A/B)
- **2026-10-30 — [PR #20](https://github.com/Askeladd22/Project_Folio/pull/20):** g3d dice: visual chamfered D6 edges and subtle engraved pips (F11 A/B)
- **2026-10-31 — [PR #21](https://github.com/Askeladd22/Project_Folio/pull/21):** g3d visual refinement: subtler D6 bevel, matte pips and grounded shadows
- **2026-10-31 — [PR #22](https://github.com/Askeladd22/Project_Folio/pull/22):** Tabletop: gather selected dice under the mouse and restore full tray physics area
- **2026-10-31 — [PR #23](https://github.com/Askeladd22/Project_Folio/pull/23):** Tabletop-inspired mouse shaking: physical die spin and verified DLL mechanics study
- **2026-10-31 — [PR #24](https://github.com/Askeladd22/Project_Folio/pull/24):** Tabletop grip: real 3D dice pile and smooth group-only camera pullback
- **2026-10-31 — [PR #25](https://github.com/Askeladd22/Project_Folio/pull/25):** FPS Lab 4: test a force-based six-dice grip without scripted formations
- **2026-10-31 — [PR #26](https://github.com/Askeladd22/Project_Folio/pull/26):** FPS Lab 5: lossless physical dice handoff from FPS grip to Manuscript landing
- **2026-10-31 — [PR #27](https://github.com/Askeladd22/Project_Folio/pull/27):** UI 2.0: persistent redesign roadmap, phase gates and continuation protocol
- **2026-10-31 — [PR #28](https://github.com/Askeladd22/Project_Folio/pull/28):** UI 2.0 P0: baseline interaction matrix and executable controller/HUD contract
- **2026-10-31 — [PR #29](https://github.com/Askeladd22/Project_Folio/pull/29):** UI 2.0 P0: repair legacy folio modal and make Windows baseline capture reproducible
- **2026-10-31 — [PR #30](https://github.com/Askeladd22/Project_Folio/pull/30):** UI 2.0 P0: real six-die grip and accessibility screenshots in Windows baseline
- **2026-10-31 — [PR #31](https://github.com/Askeladd22/Project_Folio/pull/31):** UI 2.0 P1 study: single playable folio vs two-page codex, measurable 3D space and F6 wireframes
- **2026-10-31 — [PR #32](https://github.com/Askeladd22/Project_Folio/pull/32):** Feat/UI v2 playable slice 20261031
- **2026-10-31 — [PR #33](https://github.com/Askeladd22/Project_Folio/pull/33):** Use Project Folio as temporary public-facing title
- **2026-10-31 — [PR #34](https://github.com/Askeladd22/Project_Folio/pull/34):** UI v2 P3: compact physical/scoring indicators and one held-group badge
- **2026-10-31 — [PR #35](https://github.com/Askeladd22/Project_Folio/pull/35):** Add opt-in 2D miniature toolkit: anim8, Flux, SYSL-Text and Moonshine vignette
- **2026-10-31 — [PR #36](https://github.com/Askeladd22/Project_Folio/pull/36):** Add Lovely Toasts and playable beta Farkle duel against a 2D monk
- **2026-10-31 — [PR #37](https://github.com/Askeladd22/Project_Folio/pull/37):** Prune retired chromatic HUD, unused assets and generated FX audit PNGs
- **2026-10-31 — [PR #38](https://github.com/Askeladd22/Project_Folio/pull/38):** Retire CPU painter and all F9 renderer fallbacks; g3d only
- **2026-10-31 — [PR #39](https://github.com/Askeladd22/Project_Folio/pull/39):** Establish canonical Project Folio version and mandatory changelog for every update
