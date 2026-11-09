# Protocollo di ricerca, confronto e validazione — Folio R&D

## 0. Mandato e guardrail

Obiettivo: trovare un duello a dadi leggibile, profondo, originale e verificabile, non un gioco con il maggior numero di regole. Vincolanti **Simplicity**, **World Structure**, **Swelling Power**, **mastery, not accommodation**. Protagonista con dadi fisici; niente carte giocabili obbligatorie; avversari figure con agency; nessuna conversione automatica punti→HP; giochi storici come ricerca, non come prova automatica di autenticità veneziana.

## 1. Domanda e ipotesi

Aprire un ID RQ-###. Definire:
- domanda falsificabile e alternativa nulla;
- problema osservato e citazione della build/prototipo;
- vincoli immutabili e variabili testabili;
- criteri osservabili di successo/fallimento (non solo sensazioni);
- cosa NON verrà toccato.

Esempio: «Le decisioni del Mercante in Encounter C sono più prevedibili **senza diventare banali** di quelle di Merchant V4?». Va misurata la comprensione dei giocatori e la differenza di performance fra policy, oltre all'equilibrio.

## 2. Deep research — ricerca delle evidenze

Per ogni affermazione: fonte primaria (regolamento originale, documento storico, codice), fonte secondaria (studio, analisi) o testimonianza (forum, recensione, playtest). Registrare autore/ente, titolo, link, data/versione, passaggio pertinente, accessibilità, possibili conflitti, limite dell'inferenza.

Cercare esplicitamente controesempi; non trasformare una meccanica moderna in una presunta pratica storica. Reddit, BGG e forum sono fonti per esperienze e opinioni, non prove statistiche o ricostruzioni storiche.

Consegnare una sintesi **pro**, **contro**, **evidenza insufficiente**. Ogni proposta cita il materiale che l'ha generata.

## 3. Confronto controllato

Confrontare sempre (a) Farkle/commissioni correnti, (b) Merchant Wager V4, (c) Encounter C e (d) eventuale nuovo candidato; Encounter A e P4ND0RA servono da comparatori di design con vincoli distinti.

Punteggio **solo dopo raccolta delle evidenze**. Scala descrittiva 0–4 per:
- qualità delle decisioni significative (peso 20);
- leggibilità/intenzione del rivale (20);
- possibilità di mastery verificabile (15);
- semplicità e carico cognitivo (15);
- world structure / progressione encounter (10);
- swelling power senza automatismi di potenza (10);
- realizzabilità tecnica, manutenzione e compatibilità (10).

La media pesata è un riepilogo, **non** una prova. Indicare per ogni voto evidenza, intervallo di incertezza o «ND». Non calcolare una classifica definitiva se mancano playtest umani. *Hard gate:* violazione dei pilastri, regole arbitrarie non spiegabili, dipendenza da carte del player, incoerenza narrativa strutturale, impossibilità di mantenere invarianti economici.

## 4. Red team / analisi avversaria

Prima di prototipare, cercare:
- strategie dominanti e scelte placebo;
- rivale opaco oppure totalmente prevedibile;
- payout e conversioni che falsano la posta;
- esiti dovuti al caso contro esiti dovuti alle scelte;
- casi limite: Farkle precoce, hot dice, X iniziale, pareggi, insolvibilità, turni eccessivi;
- UX: quanto il giocatore sa prima di decidere, cosa riesce a spiegare dopo.

Le obiezioni sono riportate anche quando contraddicono la direzione preferita del team.

## 5. Simulazioni e playtest

Usare [SIMULATIONS.md](SIMULATIONS.md); archiviare gli output grezzi, non soltanto una percentuale conclusiva. Confrontare policy prudente, bilanciata, aggressiva e, quando possibile, policy casuale/ottimizzata come controlli; non definire una policy scripted «giocatore esperto» senza validazione. Usare seed condivisi quando le implementazioni consentono confronti appaiati; chiarire quando la sequenza RNG diverge.

Il playtest osserva **comprensione**, decisioni e fiducia nell'equità oltre al divertimento. Non descrivere un test simulato come playtest umano.

## 6. Gate decisionali

- **G0 — Evidenze:** problema e fonti riproducibili, lacune esplicitate.
- **G1 — Coerenza:** supera i guardrail e spiega quali decisioni introduce.
- **G2 — Prototipo:** esperimento isolato, regole scritte, test deterministici.
- **G3 — Dati:** simulazioni riproducibili, exploit investigati, risultati non selezionati a posteriori.
- **G4 — Persone:** almeno un ciclo di playtest documentato, con metriche di comprensione.
- **G5 — Decisione:** approvare, iterare, sospendere, respingere in [DECISIONS.md](DECISIONS.md). Solo dopo, aprire una PR di integrazione.

I gate non richiedono una soglia numerica predefinita: definirla prima dell'esperimento quando serve. **Non confondere approvazione del prototipo con merge nel gioco.**

## 7. Protocollo GitHub

Branch isolato, una questione per PR. Titolo RQ/EX e breve design brief; link a evidenze e risultati. Le PR non devono alterare src/ se lo scopo è solo ricerca. Verificare test, versioning, changelog e impatto sui documenti canonici. Riportare test effettivamente eseguiti (locali o CI) e non dichiarare superati quelli da verificare.

## 8. Ritmo

- All'apertura di una RQ: scheda di ricerca.
- Al termine della ricerca: matrice comparativa e criticità.
- Prima dei test: protocollo con seed e metriche congelati.
- Dopo ogni esperimento: risultati, limiti, decisione provvisoria.
- Solo per ipotesi supportate: roadmap d'integrazione e PR.
