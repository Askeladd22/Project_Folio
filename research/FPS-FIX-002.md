# FPS-FIX-002 — Angular tunnelling e contatti multipli D6

**PAUL PLAN → APPLY autorizzato:** richiesta di correggere i problemi ancora aperti dopo FPS-FIX-001.
**Baseline reale:** `main@61a5626ba45215bbc547ffa9dee36395e0817553` (0.1.78; PR #135 già merged).
**Branch:** `fix/die-angular-substeps-multicontact-20261118`; nessun merge automatico.
**Perimetro:** fisica dei dadi, suite e versione/changelog; no regole Farkle/UI/renderer/dungeon crawler.

## Diagnosi e ipotesi falsificabili

- **F-04 rotazione:** `DieCollisions.sweep` mantiene l'orientamento alla fine dello step; un cubo che ruota da 0 a 90 gradi, con i centri fermi, può urtare un altro D6 a 45 gradi senza contatto all'inizio o alla fine. L'eventuale attraversamento rotazionale non viene visto dal CCD lineare.
- **F-05 più dadi:** `C.solve` esegue un unico passaggio sulle 15 coppie, correggendo il primo contatto prima degli altri. Con una catena di tre o sei dadi, le correzioni successive possono reintrodurre penetrazioni nei contatti già trattati.
- **F-06 risposta di contatto:** una sola coppia può essere valutata più volte durante i raffinamenti; i callback audio non devono duplicarsi. Il punto di contatto attuale è una stima dai supporti, non un manifold FPS completo. Non introdurre clipping manifolds finché non c'è un controesempio di qualità misurato.
- **F-07 collaudo reale:** la precedente documentazione registra 50 lanci Windows `NOT RUN`. Senza accesso al PC non dichiarare risolta la verifica umana.

## T1 — Sottopassi rotazionali limitati

**File:** `src/engine3d/physics.lua`.
**AC-1:** quando un D6 ruota da 0° a ~90° nello stesso passo .01s (centro fermo, altro dado vicino ma inizialmente separato), un controllo intermedio deve rilevare la collisione. Suddividere ogni passo *solo se necessario* in max 12 substep in base a `|angular|*dt`; non cambiare `box.dt`, il tempo fisico complessivo, i 5 maxSteps di recupero, né la frequenza del callback `after_step`.
**AC-1b:** a velocità angolare zero e nei test temporali esistenti la simulazione deve comportarsi identicamente. Se il numero di sottopassi è saturato da rotazioni estreme, contare `angular_substep_cap_hits`; non millantare CCD rotazionale analitico.

## T2 — Stabilizzazione dei contatti multipli

**File:** `src/engine3d/die_collision.lua`.
**AC-2:** con 3+ D6 con sovrapposizioni a catena, il solver ripete in modo deterministico i contatti SAT fino a max 4 passaggi, senza modificare il numero o gli ID dei dadi, senza impulso su `_manual_pending`; anche con 6 dadi i residui di penetrazione devono rimanere sotto una soglia misurata nel test.
**AC-2b:** il callback `on_contact('pair')` emette al massimo una volta per coppia e per *passo fisso* anche con più sottopassi e iterazioni. Conservare orientamento del normale, attrito, risoluzione delle velocità nel contatto e scoring invariati.

## T3 — Verifica regressioni e UAT

**File:** `tests/engine3d/die_collision_sat_ccd_test.lua`, suite esistente, changelog, protocollo UAT.
**AC-3:** regressione Lua 5.4/LuaJIT e LÖVE/Mesa su HEAD proposta green, compresi i test manual dice, audio collisioni, tempo a 20/30/60/144Hz, e il test di sei D6. Documentare valori osservati, numeri CI e problemi residui. Windows 50 lanci **NOT RUN** fino a verifica manuale.

## Stop/go

- **GO tecnico:** AC-1, AC-1b, AC-2, AC-2b, AC-3 automatici PASS.
- **NO GO release:** anche se green, UAT Windows non eseguita; PR draft, niente merge automatico.
- **Fuori scope:** port nativo FPS, hull universali D8, manifold completo a clipping, netcode, alterazione combinazioni, AI o gameplay del libro. Rivedere questi solo con prove di necessità.
