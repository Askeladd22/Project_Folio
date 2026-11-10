# EX-TP-001 — Tre Prove / Riserva finita: primo screening numerico

**Data:** 2026-11-10. **Stato:** pilot eseguito, screening G3 **negativo nel complesso**; decisione provvisoria: **sospendere la forma congelata, non integrare**. Non è una decisione canonica G5.
**Baseline:** `main@f10af7585a72d3d8cbe1c6de1993dedac30ed6f1`; rispetto alla baseline precedente, PR #118 ha già aggiunto il laboratorio Battute Gemelle in `experiments/`, non in `src/`.
**Commit di codice effettivamente testato:** `1a0c3b8857781a4e582de606de0155c9f9a9aebc`.
**CI:** [GitHub Actions #42787215598](https://github.com/Askeladd22/Project_Folio/actions/runs/42787215598): **success**, Lua 5.4 + LuaJIT, 15 regressioni deterministiche PASS su ciascun runtime.
**Dati primari:** [artifact #13749273849](https://github.com/Askeladd22/Project_Folio/actions/runs/42787215598/artifacts/13749273849): `tp_matches.csv` (54.000 incontri + intestazione), `report.txt`, `SHA256SUMS`.
**Protocollo congelato prima del motore:** [EX-TP-001_PROTOCOL.md](EX-TP-001_PROTOCOL.md). G4 umano non svolto.

## Domanda falsificabile, fonti e confronto

Una **riserva pubblica, finita e condivisa** induce decisioni strategicamente diverse, oppure trasforma il rivale in una progressione predeterminata di sigilli? H0: la conoscenza della riserva non offre un vantaggio materiale a parità di resto.
Fonti interne, alla baseline indicata: `src/farkle/rules.lua`, `docs/project_vision.md`, `docs/farkle_rules.md`, `research/PROTOCOL.md`, `research/SIMULATIONS.md`, `research/EX-BG-001.md`, `experiments/encounter_ac_lab/engine.lua`. Input progettuale: report Deep Research RQ-001 v2, 2026-11-09, e piano di follow-up del 2026-11-10. Le regole di Tre Prove non sono storiche né approvate per il gioco.

| Sistema | Accoppiamento | Debolezza da verificare |
|---|---|---|
| Farkle / commissioni (produzione) | soglie di progressione, nessun antagonista | nessun controgioco |
| Merchant V4 (laboratorio) | posta/controfferta in denaro | reattività locale e rialzo opaco |
| Encounter C (laboratorio precedente) | tre prove, risposta rivale di priorità | riserva avversaria non realmente scarsa |
| Battute Gemelle (EX-BG-001) | numero di lanci leader/follower | gate STOP/CONTINUE falliti |
| **Tre Prove, riserva finita** | risposta pubblica con risorsa intertemporale | possibile spesa sempre/mai; Farkle come mero generatore di sigilli |

## Regole e test realmente eseguiti

Tre prove a quota quattro, vittoria con due prove chiuse, massimo cinque round, Farkle canonico con sei D6 e hot dice, incasso punti→1/2/3 sigilli (soglie 40 e 90) su una prova; Mercante non tira dadi, ma sceglie PASS oppure spende 1..Smax dalla riserva unica che non si rigenera. Sul Farkle il Mercante può rispondere. A scadenza contano le maggioranze, parità locale neutrale e pareggio finale ammesso.

Fattoriale senza tuning: `R={6,8,10}` × `Smax={1,2}` × tre policy giocatore (`commit/aware/blind`) × tre policy Mercante (`aggressive/conserve/balanced`) × seed 1001–2000 = **54.000 incontri**, seed etichettati e appaiati. I flussi di dadi vengono riavviati per round, ma le sequenze effettive possono divergere al divergere delle scelte. `aware` e `blind` condividono euristica, salvo che `blind` assume riserva avversaria costantemente pari a 8.

CI su Ubuntu: `luac5.4 -p` per i quattro file Lua, `lua5.4 tests/labs/tre_prove_reserve_test.lua`, `luajit tests/labs/tre_prove_reserve_test.lua`, `lua5.4 experiments/tre_prove_reserve_lab/run.lua 1001 1000 tp-results`. Esiti e hash archiviati. Nessun test grafico, di fisica o umano.

## Risultati MISURATI del pilot (policy scripted)

Nella cella centrale **R=8, Smax=2**, 1.000 seed per matchup:

| Player | Mercante | Vittorie | Pareggi | Sconfitte | Riserva esaurita | Spesa su opportunità eleggibili |
|---|---|---:|---:|---:|---:|---:|
| commit | aggressive | 493 | 141 | 366 | 73,9% | 100,0% |
| aware | aggressive | 419 | 135 | 446 | 81,3% | 100,0% |
| blind | aggressive | 409 | 78 | 513 | 82,5% | 100,0% |
| commit | conserve | 962 | 28 | 10 | 0,0% | 19,4% |
| aware | conserve | 984 | 16 | 0 | 0,0% | 23,0% |
| aware | balanced | 984 | 16 | 0 | 0,0% | 26,7% |

**Delta di utilità appaiata aware − blind** (win=1, draw=0,5, loss=0):
- R=8, cap=2 vs aggressive: **+3,85 punti percentuali**, IC normale approssimato 95% **[+2,49; +5,21]**;
- R=8, cap=2 vs conserve: **0,00 pp**, nessuna differenza nei seed;
- R=8, cap=2 vs balanced: **0,00 pp**, nessuna differenza nei seed.
- R=6, cap=2 vs aggressive: **+13,95 pp**, IC approx95 **[+12,10; +15,80]**, ma stesso fattoriale vs conserve/balanced = zero.
- R=10, cap=2 vs aggressive: **+0,50 pp**, IC approx95 **[−0,31; +1,31]**.

La conoscenza della riserva **può** cambiare il comportamento di una policy scripted contro il rivale che spende sempre; non si generalizza a due policy rivali e non certifica mastery. Il controllo `commit` vince **493** volte contro l'aggressivo centrale contro **419** di `aware`: osservazione coerente con un'euristica aware non ottimale.

**Sensibilità della spesa:** con `Smax=1` l'aggressivo spende nel 100% delle occasioni eleggibili e **non esaurisce mai la riserva** in tutte le celle. Con `Smax=2`, `R=6` consuma tutta la riserva in **100%** degli incontri contro l'aggressivo; `R=8` esaurimento **73,9–82,5%**; `R=10` **27,9–29,6%**. In ogni caso aggressivo spende nel **100%** delle opportunità eleggibili. Conservativo e bilanciato spendono più selettivamente, ma non esauriscono mai la riserva nel pilot e nella cella centrale perdono quasi sempre.

**Finta / cambio corsia:** contro l'aggressivo in R=8, cap=2, `aware` mostra **0,084** cambi volontari di prova per incontro e **0,022** pattern “spesa rivale sulla prova precedente, poi cambio volontario del giocatore” per incontro. Sono frequenze descrittive di un comportamento scripted; non dimostrano che una finta intenzionale sia redditizia.

## Gate e red team

| Gate preregistrato | Esito | Motivazione |
|---|---|---|
| G2 / integrità | **PASS** | 15/15 test per runtime, dati completi, invarianti e determinismo |
| TP-G1 / vantaggio knowing reserve | **FAIL nel pilot** | effetto >3 pp solo vs aggressive, **non** contro almeno due archetipi |
| TP-G2 / inversioni STOP–CONTINUE | **NON ESEGUITO** | manca counterfactual di 400 stati × 512 rollout, non si attribuisce pass |
| TP-G3 / PASS e SPEND almeno 20% | **PASS per alcune policy** | ad esempio balanced: 26,7% SPEND, 73,3% PASS nella cella centrale; aggressive fallisce |
| TP-G4 / esaurimento 10–80% | **PASS solo per aggressive in alcune celle** | per commit R=8,cap=2: 73,9%; ma lo stesso aggressive fallisce TP-G3. balanced/conserve falliscono G4 |
| TP-G5 / nessuna dominante | **NON CERTIFICATO** | tre policy euristiche; mancano agente red team e inferenza corretta fra confronti multipli |
| TP-G6 / ordine di turno | **NON STIMABILE** | incontro asimmetrico giocatore→risposta Mercante; non due turni equivalenti |
| TP-G7 / durata e loop | **PASS tecnico** | 54.000 incontri terminati entro i 5 round, assert attivo su ogni incontro |
| G4 persone / G5 approvazione | **NON ESEGUITI** | nessun test umano, nessun merge autorizzato |

**Criticità strutturale:** nessuna cella/policy del Mercante ha mostrato **insieme** risorsa usata selettivamente (TP-G3) e riserva realmente scarsa/esauribile (TP-G4). L'aggressivo spende sempre, i rivali parsimoniosi non competono. Potrebbe essere una debolezza delle tre policy scripted **anziché un'impossibilità matematica del contratto**: non sarebbe corretto sostenere di aver falsificato ogni forma di riserva pubblica.

**Exploit da testare in eventuale ciclo separato:** il rivale potrebbe spendere due sigilli su una prova che il giocatore chiuderà al turno seguente; la spesa non impedisce la chiusura altrui e può essere un placebo. Viceversa, il giocatore può richiamare risposta su una prova che poi abbandona. Il pilot segnala pattern ma non ottimalità, convenienza di bluff o comprensione umana. Le soglie 40/90 e le policy di incasso restano possibili confondenti.

## Decisione provvisoria e prossimo gate

**SOSPENDERE EX-TP-001 nella forma congelata; non integrare in `src/`, non rifare la grafica, non aggiungere altre risorse o ritoccare ex post i gate.** Il laboratorio ha una procedura valida e incontra una condizione riproducibile in cui la riserva sembra avere valore, ma non ha identificato un Mercante insieme **competitivo, selettivo e sensibile ai costi futuri**. L'effetto su STOP/CONTINUE non è stato ancora misurato.

**Prossimo gate utile, se si desidera recuperare Tre Prove:** piccolo audit separato EX-TP-002 su una policy rivale che espliciti costo opportunità del sigillo e preview comprensibile per il giocatore. Prima si verifica se due decisioni avversarie **alternativamente razionali** esistono a pari plancia; poi, e solo se sì, si fanno counterfactual Farkle e un playtest umano. Alternativa di minore complessità: tornare al confronto Merchant V4/Encounter C e scartare la riserva.

Il risultato negativo dello screening è utilizzabile per scegliere cosa **non** integrare, non per bocciare in assoluto la struttura delle tre prove.
