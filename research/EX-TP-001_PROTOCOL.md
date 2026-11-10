# EX-TP-001 — Protocollo preregistrato: Tre Prove / Riserva finita

**Stato: PREREGISTERED (prima di eseguire simulazioni)** · 2026-11-10.
**RQ:** RQ-001, controgioco Farkle vs Mercante. **Baseline Git immutabile:** `main@f10af7585a72d3d8cbe1c6de1993dedac30ed6f1` (PR #118 già unita, BG sotto experiments/, NON produzione).
**Controllo di conformità:** nessuna modifica a `src/`, `main`, regole canoniche, UI, valuta, HP, carte obbligatorie o fisica.
**Fonti interne:** `src/farkle/rules.lua` (autorità implementativa), `docs/project_vision.md`, `docs/farkle_rules.md`, `research/PROTOCOL.md`, `research/SIMULATIONS.md`, `research/EX-BG-001.md`, `experiments/encounter_ac_lab/engine.lua`. Fonte progettuale: report RQ-001 v2 (2026-11-09) e piano Deep Research EX-TP-001 del 2026-11-10. Non si tratta di storia attestata della Venezia del XVI secolo.

## Ipotesi e alternativa nulla

H1: una riserva rivale pubblica, finita e condivisa fra tre obiettivi modifica in modo verificabile le decisioni del giocatore, comprese allocazione dei sigilli e scelta STOP/CONTINUE, più di una semplice policy di priorità.
H0: conoscere quantità e distribuzione della riserva non aggiunge valore alle scelte oltre una policy state-blind; la riserva è cosmetica oppure degenerata.

## Regole congelate — solo laboratorio

Tre prove aperte: Capilettera, Miniatura e Marca (0–0). Sei D6 Farkle: tutte le valutazioni, selezioni valide, Farkle e hot dice provengono **esclusivamente** da `src/farkle/rules.lua` e dal motore `Rules.new('control')`; nessun punteggio duplicato. Un turno di Farkle per round, massimo cinque round. L'incasso produce `1` sigillo per `1–39` punti, `2` per `40–89`, `3` per `90+`; tutto il lotto deve essere collocato su **una** prova aperta. Farkle fa perdere i punti provvisori, ma il Mercante ha comunque diritto a una risposta. Su ogni round (anche dopo Farkle), il Mercante osserva lo stato, sceglie PASS oppure un'unica prova aperta e spende `1..Smax` sigilli, senza superare la riserva residua o il limite di quattro sigilli su quella prova. Nessun refill. Una prova si chiude per chi arriva per primo a quattro sigilli; la prova chiusa è immutabile. Prima parte con due prove chiuse vince subito. Alla fine del quinto round, le prove non chiuse sono attribuite alla maggioranza; parità locale neutrale; parità totale = draw. Se il player chiude la seconda prova con il proprio deposito, il Mercante non ha una risposta post-terminale.

**Fattoriale**: `R={6,8,10}` × `Smax={1,2}` (sei celle, senza ulteriore tuning delle soglie 40/90, delle tre prove o dei cinque round). In caso di insensibilità ai parametri, non introdurre automaticamente altri sottosistemi. I valori non sono presunti bilanciati.

## Politiche scripted congelate

**Giocatore**: `commit` (concentra avanzamento, STOP Farkle a 40), `aware` (conosce la riserva effettiva e il profilo pubblico di risposta rivale), `blind` (stessa euristica di aware ma usa sempre `R=8` come riserva rivale presunta). Aware/blind condividono scelta canonica delle combinazioni, euristica di piazzamento e RNG; sono un'ablazione della sola conoscenza della riserva. L'euristica di STOP può dipendere dalla riserva prevista: è una proxy scripted, non una policy ottima. Scelta del sottoinsieme Farkle: massimo `points + 5 * free_dice_after_take`, pareggi con mask minore. **Rivale**: `aggressive` (spesa immediata su progresso / chiusura), `conserve` (spesa solo con minaccia evidente o possibilità di chiusura), `balanced` (valore del progresso e chiusura meno costo della risorsa; può passare). Nessun avversario è un giocatore umano.

## RNG, campione, output

Generatori Park-Miller separati per dadi per round, tie-break casuali (se usati) e per eventuali rollout. Seed condivisi tra tutte le celle; confronti appaiati **per etichetta seed**, non identità di sequenze RNG qualora le azioni divergano. Pilot: seed interi **1001..2000**, tutti i 6 trattamenti × 3 policy player × 3 policy rival = **54.000 incontri**. Salvare il CSV grezzo con un record per incontro: seed, configurazione, policy, winner, rounds, busts, banks, spese, pass, riserva finale, risorsa esaurita, cambi corsia e dati diagnostici. Registrare log e commit di esecuzione. Non eliminare draw.

Un eventuale screening di conferma usa esclusivamente seed **5001..10000**, preregistrati qui e non visti durante la taratura; il pilot NON basta a confermare effetti piccoli. Il counterfactual previsto prima di un'eventuale decisione definitiva usa **400 stati Farkle validi** stratificati per round/stato della plancia/riserva, 512 rollout comuni per STOP e CONTINUE, contro condizioni con riserva 2 vs 8 (limitando 2 alla quantità disponibile in cella) e rival conservative/aggressive; `CONTINUE` significa un lancio canonico aggiuntivo con miglior combinazione euristica e poi BANK, non ottimalità globale. I risultati counterfactual non esistono finché non sono effettivamente eseguiti.

## Gate prima dei dati

- **G2 / integrità:** test deterministici su sigilli, riserva mai negativa, spesa mai maggiore di Smax, chiusura immutabile, Farkle, pari, limite, seed e regole canoniche; esecuzione Lua 5.4 + LuaJIT quando CI disponibile.
- **TP-G1 (conferma):** `aware - blind` ≥+3 pp di utility attesa (win=1/draw=.5/loss=0), limite inferiore IC 95% appaiato >0 contro almeno **due** policy del rivale. Non affermare pass da pilot marginale.
- **TP-G2 (conferma):** ≥10% inversioni decisive di preferenza STOP/CONTINUE al variare della riserva/policy rivale, con limite inferiore IC 95% >5%; stimare su stati realmente validi, escludere ambigui solo secondo margine prefissato di 0,10 di utility.
- **TP-G3:** nelle occasioni con riserva positiva e almeno una prova aperta, PASS e SPEND entrambi ≥20% per almeno una policy avversaria *non random*, nella candidata.
- **TP-G4:** riserva esaurita in 10–80% degli incontri per almeno una policy rivale nella candidata, non è desiderabile spendere sempre o mai.
- **TP-G5:** nessuna policy di allocazione domina universalmente ogni altra per ≥5 pp contro ogni rivale con intervallo simultaneo positivo. Diagnosticare, non interpretare come equilibrio Nash.
- **TP-G6:** controllare vantaggio d'ordine. L'esperimento ha un ordine fisso deliberatamente asimmetrico (player Farkle, Mercante risponde), quindi G6 "first-player advantage <7 pp" del piano Deep Research **non è stimabile** senza una variante apposita; registrarlo **non testato**, non pass.
- **TP-G7:** 100% degli incontri entro 5 round per costruzione; segnalare bug, e percentuale di conclusioni anticipate.
- **Gate umano G4 della R&D:** non aprire senza evidenza G3; richiede osservazione della comprensione delle intenzioni del Mercante e degli exploit, non solo win rate.

**Analisi:** percentuali con Wilson 95%; delta aware-blind su unità seed (IC appaiato o bootstrap con seed come cluster); correzione Holm per confronti multipli; report win/draw/loss; tassi del Mercante condizionati all'eleggibilità. Le policy `commit` e `blind` sono controlli contro la banalità, non benchmark di livello umano.

## Stop / red team / punti controversi

Analizzare spesa sempre/mai, bluff che attira spesa su corsia poi abbandonata, soglie di incasso 40/90, decisioni su un solo obiettivo dominante, rivalità apparente senza effetti STOP, Farkle come occasione di risorsa avversaria. **Metrica bluff esplorativa:** spesa Mercante dopo deposito player non terminale, seguita da deposito player su corsia differente al round successivo; è comportamento osservabile, non prova di intenzione di bluff. Il rivale deve avere almeno una policy capace di vincere; se non si verifica, sospendere.

Dopo il pilot si possono correggere bug di implementazione *documentandoli*; non cambiare retroattivamente metriche/gate. Nessun merge, PR o cambio di gameplay senza autorizzazione esplicita. Riferimento alla versione Git nella scheda EX-TP-001.
