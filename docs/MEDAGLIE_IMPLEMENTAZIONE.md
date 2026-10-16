# Medaglie sperimentali: implementazione

## Piano circoscritto

Lua/LuaJIT, LÖVE2D 11.x. Specifica comparativa: [ricerca](KCD2_MEDAGLIE_RICERCA.md).

- [x] Ricerca, inventario, compatibilità e checkpoint: `audits/medals-reference/before.zip`, 174 file attivi, hash individuali nel manifest. Audit e legacy non duplicati e non modificati.
- [x] Baseline: 22 file Lua superati; smoke reali superati.
- [x] Test-first: `tests/farkle_medals_test.lua` fallisce inizialmente per API di equipaggiamento assente.
- [x] Definizioni in `src/gameplay/farkle/medals.lua`: inventario e cariche. Collegamenti locali in `rules.lua` senza cambiare scoring.
- [x] Rilanci in controller: sottoinsieme fisico distinto dall'insieme ancora valutabile; preservare risultati e posizioni esclusi, incluse ripetizioni A/B/pesato.
- [x] Pannello catalogo/attivazione dedicato, etichette neutre, cariche e motivi di blocco. Riavvio esplicito della commissione per equipaggiare.
- [x] Unit test e smoke fisico separati; HUD a entrambe le risoluzioni, confronto hash motore/assets.
- [x] Risultati, limiti e rollback documentati; Game Design aggiornato.

Rischi da verificare: Farkle valutato soltanto sul sottoinsieme rilanciato; consumo doppio dopo recupero tecnico; dadi accantonati coinvolti; superamento indebito delle soglie d'incasso; cariche ricaricate al cambio turno; controlli attivabili durante moto o commissione chiusa.

Le proprietà sconosciute non vengono implementate. Non sono previste modifiche al motore congelato, a `scoring.lua`, ai parametri delle commissioni, alle probabilità o al mapping delle facce.

## Utilizzo

Avviare con `love .` o `Avvia.cmd`, entrare nel Farkle, aprire **Gestione run → Laboratorio medaglie**. Le sei pagine contengono tutte le 34 definizioni. Cliccando una riga si leggono effetto o blocco. **Riavvia ed equipaggia** abbandona esplicitamente i progressi della commissione corrente: conserva stadio e dado personalizzato, azzera incassi e turni. Non richiede completamento della run e non introduce un negozio.

Il comando laterale **Medaglia: effetto / utilizzi** apre l'attivazione. Per i rilanci si scelgono bersagli separati dalla selezione da accantonare, anche se non producono punti. Per l'incasso ×2 si usa la selezione a punti corrente. Il pannello mostra cariche, motivo di indisponibilità e, per ×2, il totale esatto prima dell'incasso. Durante il moto gli input restano bloccati. Le cariche tornano al massimo al cambio commissione, mai al cambio turno o hot dice.

| Riferimento interno | ID / etichetta pubblica | Attivazione |
|---|---|---|
| Fortune T/S/G | `reroll_tin/silver/gold` / Rilancio stagno/argento/oro | 1 uso, fino a 1/2/3 dadi |
| Exchange S | `exchange_silver` / Scambio singolo | 1 uso, un dado |
| Exchange G | `exchange_gold` / Scambio di due uguali | 1 uso, esattamente due valori uguali, ID distinti |
| Wedding G | `reroll_wedding` / Rilancio speciale di tre | 1 uso, fino a tre dadi |
| Warlord G | `bank_multiplier_gold` / Incasso x2 | 1 uso, totale del turno ×2 e chiusura |

Sono sette medaglie equipaggiabili. I rilanci operano su tiro valido: la finestra post-Farkle di questi riferimenti resta da verificare. Il `retry` originale mantiene regole, ricompensa e percorso fisico precedenti: non è stato rinominato Resurrection.

## Incompatibilità e limiti espliciti

27 definizioni non equipaggiabili: Resurrection (conservazione punti/timing da confermare), Transmutation (timing/durata/resa temporanea), Doppelganger (ultimo tiro, selezione vuota e conclusione), Headstart (numeri), Warlord T/S (arrotondamento), Advantage (punteggi/incastri), Emperor/Tyche (gruppi estesi e nuove combinazioni Manuscript), Might/Bird King (settimo corpo), Defence (avversario assente), Balatro (dado speciale assente). Tutti i livelli elencati e i motivi sono consultabili. Nessun moltiplicatore, carica o bonus è stato ribilanciato per colmare le lacune.

Non esiste una conversione uniforme KCD2→Manuscript. I bonus nuovi non sostituiscono i punti base; ×2 sul turno è esatto e non richiede arrotondamenti. Le soglie ordinarie si controllano prima del bonus: scelta locale dichiarata nella ricerca, non comportamento KCD2 dimostrato.

La replica non è completa né verificata direttamente nell'eseguibile KCD2. Non sono stati implementati o testati come funzionanti trasformazione, combinazioni speciali, settimo dado o Resurrection. I test verificano invece che tali definizioni rimangano bloccate e non consumino/modifichino lo stato. I difetti geometrici già noti del motore restano; nessuna nuova campagna statistica o correzione del solver.

## Modifiche e ordine degli effetti

- **Nuovo `src/gameplay/farkle/medals.lua`**: 34 definizioni, identificatori neutri, riferimento interno, livelli, attivazione, parametri, fonte, compatibilità, stato e cariche nello stato della partita (`medalCharges`).
- **`src/gameplay/farkle/rules.lua`**: equipaggiamento a commissione vergine, controllo disponibilità, consumo atomico, insieme fisico `active` distinto dall'insieme ancora valutabile durante il rilancio della medaglia; bonus applicato prima dell'incasso e della verifica dell'obiettivo. Il motore delle combinazioni rimane invariato.
- **`src/features/farkle/controller.lua`**: adapter verso `begin_physical`, protezione degli input, registrazione eventi `reference_equipped/reference_used`, riavvio esplicito della commissione di prova. Maschera `medalHeld` per mantenere esclusi dalla simulazione i dadi conservati anche dopo la conclusione del rilancio. Restano selezionabili perché `game.used` è distinto; il successivo lancio ordinario usa nuovamente il contratto originale. Il filtro pesato e A/B non spendono altre cariche.
- **Nuovo `src/features/farkle/medal_panel.lua`**, **`hud.lua`**: catalogo paginato e pannello attivazione. Nessuna nuova grafica commerciale né cambiamento alla disposizione del vassoio/camera.
- **Nuovi `tests/farkle_medals_test.lua`, `tests/farkle_medal_controller_test.lua`**: regole, limiti, identità, maschere, filtro pesato e recupero tecnico.
- **`tests/smoke/integration.lua`, `tests/smoke/farkle_hud.lua`**: estensioni dei test reali e delle catture alle due risoluzioni.
- **`docs/GAME_DESIGN.md`**, questo rapporto e **`KCD2_MEDAGLIE_RICERCA.md`**: stato sperimentale, uso e limiti.

Rilancio: lettura accettata → scelta bersagli → verifica carica/stato/ID → consumo → tiro fisico → eventuale recupero A/B o filtro pesato → lettura → ricomposizione della mano non accantonata → combinazioni normali → accantonamento/incasso. Il giocatore può rilanciare un dado utile, ma non un dado già speso. Nessuna combinazione riutilizza un ID.

Incasso ×2: selezione valida e soglie ordinarie → eventuale accantonamento → consumo → moltiplicazione del provvisorio → incasso → verifica condizioni reali della commissione. Non raddoppia la banca precedente, non inventa gruppi o hot dice, non si riattiva durante la transizione.

## Verifiche eseguite

Ambiente: LÖVE 11, LuaJIT 2.1.1700008891, OpenGL 3.3 NVIDIA RTX 5080. Log/screenshot in `audits/medals-reference/`; impostazioni di test isolate tramite APPDATA, salvataggi utente non usati.

| Prova | Risultato |
|---|---|
| `python scripts/test_luajit.py` | 24/24 file Lua PASS; baseline 22/22 |
| `python scripts/test_love_runtime.py` | 4/4 PASS |
| `python scripts/test_luajit.py scripts/farkle_analysis.lua` | PASS, 923 multinsiemi; regolamento e rischio teorico invariati |
| `run_smoke.py all --out audits/medals-reference/baseline` | PASS prima delle modifiche |
| Sottoinsiemi e A/B (`after/partial`, `after/face-gate`) | PASS: dadi esclusi, fallimento spawn atomico, ripetizione tecnica, ambiguità non accettata |
| `run_smoke.py integration --out audits/medals-reference/final` | PASS: normali/incisi/pesati, faccia visibile/valore, rilancio selettivo reale, carica singola, hot dice, vecchio retry, 36 chiamate texture |
| HUD (`final/hud`, precedente passaggio in `after/hud`) | PASS a 1920×1080 e 1280×720: catalogo, sospese, equipaggiamento, tiro reale, attivazione, carica esaurita, ×2, stati ordinari e picking |
| Frontend (`after/frontend`) | PASS: splash, menu, impostazioni persistenti isolate, scelta commissione, avvio da launcher |
| Hash protezioni | 70 file preesistenti in `src/engine3d/`, `src/app/`, `resources/` e `scoring.lua` identici al checkpoint |

I test unitari usano valori deterministici. I test fisici leggono i dadi reali: non assegnano esiti per far riuscire un rilancio. Gli screenshot dell'incasso usano fixture di regole dichiarate, quelli del rilancio selettivo sono catture di tiri fisici. Nessuna misura di distribuzione è dedotta da questi pochi tiri.

Ispezionati visivamente catalogo, equipaggiamento, selezione e anteprima incasso alle due risoluzioni: testo e comandi nei pannelli, nessun cambiamento all'inquadratura. Esempi: [attivazione 720p](audits/medals-reference/final/hud/hud-usability-1280-reference-activation.png), [incasso 1080p](audits/medals-reference/final/hud/hud-usability-1920-reference-bank-preview.png).

Limite della copertura: il test unitario del filtro pesato dimostra conservazione dei valori e consumo singolo durante il rifiuto di una proposta. Non certifica ogni possibile movimento residuo dei dadi già accettati dopo un successivo rilancio del solo D1; quel percorso preesistente non è stato riscritto. Le prove fisiche documentano i casi eseguiti, non una garanzia per tutte le traiettorie. Revisione separata completata sulla maschera di esclusione e sulla sua durata; nessun ulteriore difetto grave rilevato.

Problemi rilevati e risolti durante la verifica:

1. Il nuovo smoke presumeva un primo tiro valido; il seed produceva un Farkle naturale nella sequenza corrente. Ora prosegue normalmente ai turni successivi, senza cambiare seed o forzare facce.
2. Lo smoke a velocità reale ha dimostrato un movimento dei dadi conservati dopo la conclusione del rilancio: `sync` li reinseriva nel solver. Correzione locale `medalHeld`, riprodotta prima con un test fallente e poi superata in unitario e a entrambe le risoluzioni. Nessuna modifica al solver.
3. Revisione separata: i motivi di blocco Warlord T/S erano nascosti dalla descrizione dell'effetto. Ora sono mostrati esplicitamente.

## Rollback

Checkpoint attivo prima dell'intervento: `audits/medals-reference/before.zip`, SHA-256 `2d7d6b7653f47ed9f5ccebc5dcb60d50fd4f656a3cd54e4aab3992f43236849b`. Verificati CRC e hash di tutti i 174 file presenti; `before-manifest.json` contiene gli hash individuali. Gli audit e i materiali legacy preesistenti non sono stati ricopiati né alterati. Non è un pacchetto `.love`.

Chiudere LÖVE. Per tornare alla baseline, ripristinare dall'archivio solamente i sei file preesistenti elencati sopra (`rules`, `controller`, `hud`, due smoke, Game Design). Rimuovere o mettere da parte i quattro nuovi moduli/test (`medals.lua`, `medal_panel.lua`, i due test medaglie). I due nuovi rapporti possono restare come documentazione storica. Verificare gli hash contro il manifest, poi eseguire la suite Lua e lo smoke baseline. Non sovrascrivere modifiche successive senza prima salvarle. Non serve toccare salvataggi o ricostruire archivi eseguibili.
