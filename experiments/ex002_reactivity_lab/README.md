# EX-002 — Reattività del Mercante nel prototipo C

**Status:** research only (RQ-003); non è una nuova regola approvata.
Base: `main@1b8fb88590a084488c2c3f029d6e188b76426a6f` (0.1.72).

## Domanda falsificabile

La categoria scelta dall'Incisore cambia le risposte del Mercante in modo
strategicamente utile, oppure la policy reattiva è equivalente a un timer
che aggiunge sigilli secondo un ordine fisso?

## Condizioni isolabili

- **R / reactive / default:** fra le categorie ancora aperte il rivale sceglie
  il massimo di `5 * sigilli_rivale + 2 * sigilli_player + priorità`.
  Priorità: Capilettera 3, Miniatura 2, Marca 1. Pareggio = primo indice.
- **F / fixed / opt-in:** fra le categorie ancora aperte il rivale sceglie
  il massimo della sola priorità 3,2,1, pari agli indici 1,2,3.

Identici sei D6, evaluator Farkle canonico, incasso 1/2/3 sigilli
per <40 / 40..89 / >=90 punti, 4 per sigillare, fino a sei prove.
Il rivale riceve 1 sigillo/turno, 2 ogni terza prova. Nessuna casualità nascosta.
Non alterare `src/`, Encounter A o il comportamento default di C.

API: `E.new('C',seed,{rival_target_mode='fixed'})` seleziona F;
`E.new('C',seed)` mantiene R. `E.preview_rival_target(s)` espone
`target`, `name`, `marks`, `score`, `rule` e `candidates`
a partire solo dal board pubblico, senza mutazioni.

## Protocollo preregistrato prima dei dati

- Pilot: **seed 1000–1999 inclusi**, per 3 policy dadi × 2 policy
  di allocazione × 2 condizioni avversario = **12.000 incontri**.
- Holdout **2000–6999** riservato; nessuna calibrazione sul holdout.
- Dadi: prudent (bank >=30), balanced (>=60), daring (>=110);
  stesso `best_option` e stesso tie-break di
  `experiments/encounter_ac_lab/simulate.lua`.
- Allocazione: **first** sceglie la prima categoria legale;
  **informed** valuta esaustivamente ogni singola assegnazione legale,
  osserva il risultato immediato (nessun dado futuro), massimizza
  `4*(sigilli_P-sigilli_R) + 50*lane_player_lock - 50*lane_rival_lock`,
  con bonus terminale +500 per vittoria P / -500 per vittoria R;
  a parità sceglie il primo indice. È un'euristica diagnostica, **non**
  un modello validato di padronanza umana.
- Per ogni stato pre-claim si confrontano TUTTE le categorie legali su
  copie delle sole tabelle di stato, senza far avanzare il RNG.
  Il confronto misura bersaglio, board immediato e stato terminale
  **solo alla fine di quella mossa**; 'unfinished' non indica la
  conclusione futura della partita.
- `target_sensitive`: almeno due azioni legali producono bersagli rivale
  diversi; **NON** prova causalità sull'esito.
- `nonlocking_target_sensitive`: lo stesso conteggio quando nessuna
  azione del giocatore sigillerebbe una categoria (elimina il confondente
  della perdita di eleggibilità del bersaglio).
- `terminal_status_sensitive`: le scelte legali producono risultati
  terminali immediati differenti, incluso `unfinished`; non è una
  stima della differenza di vittorie finali.
- Risultati: vittorie P/R/pareggi, numero turni, Farkle, punti bancati,
  scelte, alternative legali, differenza appaiata R-F e intervallo
  approssimato al 95% per win-rate del giocatore.
- Stop tecnico su nondeterminismo, stati illeciti, loop, mutazione
  delle sorgenti dei controfattuali o divergenza attuale-vs-trial.
  Una differenza in win-rate **senza** scelte leggibili o utili
  non costituisce superamento del gate di agency.

## Riproduzione

Da root con Lua 5.4 e LuaJIT:

```sh
lua5.4 tests/labs/encounter_ac_test.lua
luajit tests/labs/encounter_ac_test.lua
lua5.4 tests/labs/ex002_reactivity_test.lua
luajit tests/labs/ex002_reactivity_test.lua
mkdir -p /tmp/ex002
lua5.4 experiments/ex002_reactivity_lab/run.lua 1000 1999 /tmp/ex002
```

Il runner scrive `ex002_matches.csv` (12.000 righe oltre header)
ed `ex002_counterfactuals.csv` (una riga per *tutte* le opzioni
in ogni stato di claim) e stampa il sommario. La CI specifica
conserva l'archivio grezzo.

## Interpretazione e gate

G2 tecnico verificabile con Lua 5.4, LuaJIT e regressione esistente.
G3 solo dopo audit dei CSV e dei controesempi, confrontando coppie
seed/policy omogenee. G4 playtest crossover con predizione della
risposta del Mercante, senza presentare nuove meccaniche come canoniche.
G5 decisione scritta in `research/DECISIONS.md` solo su approvazione.

## EX-002b — stress diagnostico post-pilot

Il pilot ha rilevato `first == informed` su tutti i percorsi visitati,
così l'effetto della reattività è osservabile nei soli controfattuali.
Per falsificare la possibile equivalenza completa senza usare l'holdout
si esegue un sondaggio dichiaratamente **post-hoc** con policy `last`
(ultima categoria aperta; non skill ottimale), seed 8000..8999:

```sh
mkdir -p /tmp/ex002b
lua5.4 experiments/ex002_reactivity_lab/stress_run.lua 8000 8999 /tmp/ex002b
```

`ex002b_matches.csv` registra anche il percorso effettivo dei target.
Questo esperimento di stress non modifica il protocollo congelato del
pilot e non sostituisce un playtest umano o il futuro holdout.
