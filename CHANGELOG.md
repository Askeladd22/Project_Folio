# Registro modifiche — Project Folio

Questo file è il **registro ufficiale e cumulativo** degli aggiornamenti del gioco.
Ogni PR deve aggiungere una nuova sezione, collegata alla versione scritta in
[`version.txt`](version.txt). La CI verifica che versione e changelog siano
aggiornati insieme; le istruzioni sono in [`docs/VERSIONING.md`](docs/VERSIONING.md).

> Le versioni precedenti al 31 ottobre 2026 non avevano un registro versionato
> unico: gli interventi già integrati sono qui riepilogati come **baseline
> retrospettiva** tramite PR verificabili, **non** come release pubblicate.
> La versione del documento di game design è indipendente da quella del software.

## [0.1.0-dev.3] - 2026-10-31

**Tipo:** correzione urgente del crash di avvio introdotto dalla rimozione del
painter CPU in PR #38. Questa versione è un hotfix del `main`
`0.1.0-dev.2`, non una nuova release pubblica.

### Corretto
- Risolto `src/app/dice_runtime.lua:761: attempt to index global 'light'
  (a nil value)` durante `spawn_initial_dice()`. Il materiale grafico
  `light.plastic` era rimasto dopo che il renderer CPU e il suo import
  erano stati eliminati.
- Eliminati **il riferimento e la proprietà `material` del vecchio
  painter** dai dadi creati in avvio. Le texture, i colori, la geometria
  e i materiali fisici `bone` rimangono invariati; il rendering
  continua esclusivamente con **g3d**, senza introdurre alcun fallback.

### Test
- Aggiunto `tests/dice_startup_g3d_only_test.lua`: esegue in ambiente
  headless **il vero corpo di `spawn_initial_dice()`** con stub del
  motore fisico, verificando che D6/D8 e regioni siano creati
  e registrati senza `light` o materiali CPU.
- Rafforzato `tests/renderer_dependency_test.lua` per impedire
  di reintrodurre questa dipendenza.
- Verifica automatica Lua 5.4/LuaJIT, test Python e laboratorio
  FPS richiesta su GitHub Actions; **avvio grafico Windows ancora
  da verificare** con l'eseguibile LÖVE reale.
- **Nota di integrazione:** la precedente PR #41, ancora aperta al
  momento dell'hotfix, ha proposto `0.1.0-dev.3` in parallelo.
  Dopo l'integrazione di questo fix dovrà assumere un numero
  successivo e riallineare il suo changelog.

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
