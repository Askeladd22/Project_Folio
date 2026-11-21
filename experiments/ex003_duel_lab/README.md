# EX-003 — Duello Farkle diretto (D) vs prove contese (C)

**Stato:** esperimento PAUL/SEED approvato; **NON** integrato nel gameplay.
Baseline `main@97c730ef6df28a234ba4b78bd1174c9430833c42`,
versione 0.1.76; protocollo in [research/EX-003.md](../../research/EX-003.md).

## Scopo

Verificare se **sapere come sta giocando il Rivale** cambia le
decisioni del rischio Farkle. L'incisore usa sei D6 canonici
in entrambe le condizioni. Il nome generico è **Rivale**;
il personaggio specifico Opponent non è il benchmark.

- **D (nuovo controllo):** 6 turni Farkle a testa, incassi in
  punti e confronto dei totali. Il Rivale tira veramente i
  propri D6 (stream RNG indipendente), usa una soglia pubblica
  contestuale di 30/60/110 e può vincere o pareggiare.
- **C (identico Encounter C):** 6 prove massimo, punti incassati
  diventano 1/2/3 sigilli, tre categorie contese, risposta del
  Rivale `reactive` come nell'engine già esistente. L'unica
  differenza del benchmark è la scelta delle azioni dell'Incisore;
  l'engine `experiments/encounter_ac_lab/engine.lua` non viene toccato.

**Attenzione:** D e C NON sono comparabili tramite sola win-rate:
D concede 6 turni al Rivale, C assegna automaticamente sigilli.
La vittoria ha significato diverso. Il confronto corretto è
`situational` vs `balanced` **dentro ciascuna modalità**.

## Eseguire

```sh
lua5.4 tests/labs/ex003_duel_test.lua
luajit tests/labs/ex003_duel_test.lua
mkdir -p /tmp/ex003
lua5.4 experiments/ex003_duel_lab/run.lua 16000 16199 /tmp/ex003
```

Output: `ex003_matches.csv` (1600 righe sintetiche di partita,
non dati umani) e `ex003_summary.txt`, esportati da CI come artifact.

## Policy pubbliche

Prudent (30 punti), balanced (60), daring (110), situational.
La policy situational D regola lo stop con differenza di punti
e round; in C usa opportunità pubbliche dei sigilli e un
oracolo controfattuale su copie per scegliere la categoria.
Il Rivale D usa sempre la policy situational, nota a priori.

La tabella canonica dei punti, il significato di Farkle e i
sei dadi non vengono modificati. Gli stream dei dadi del
giocatore partono con lo stesso seed per turno e modello;
dopo le scelte differenti possono divergere. Holdout
2000..6999 intatto.

## Human gate

Vedere [research/EX-003-UAT.md](../../research/EX-003-UAT.md).
La CI non può misurare divertimento, comprensibilità né
padronanza del rischio da parte di persone.
