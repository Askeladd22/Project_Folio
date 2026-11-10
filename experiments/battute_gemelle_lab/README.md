# EX-BG-001 — Battute Gemelle (RQ-001, headless)

**Stato:** prototipo isolato, NON canonico, NON integrato nel gioco.
**Preregistrazione:** 2026-11-10, prima dell'esecuzione CI del nuovo laboratorio.
**Base Git verificata:** main `d749cd54306b518c341b0ba8b4c17fcfb64cea66` (v0.1.62).
**Fonti:** `src/farkle/rules.lua` alla base; `docs/project_vision.md`,
`docs/farkle_rules.md`, `research/PROTOCOL.md`,
`research/SIMULATIONS.md` e report RQ-001 v2 del 10 novembre.
**Confine:** nessuna modifica a `src/`, g3d, asset, salvataggi, build o UI.

## Ipotesi falsificabile

La scelta del Leader di incassare dopo k lanci, concedendo al
Rispondente **esattamente un massimo di k lanci**, produce stati
in cui STOP è preferibile e altri in cui CONTINUE è preferibile.
Inoltre la scelta preferibile può cambiare se il Rispondente usa
una policy di accantonamento diversa. La nulla è che una delle
due azioni domina o che la policy del rivale è irrilevante.

Questa è una **proposta**, non una dimostrazione di profondità,
equilibrio, comprensibilità o divertimento.

## Regole congelate (G1/G2)

1. Ogni contendente usa sei D6 equi, punteggi e selezioni validi
   del modulo **canonico** `src/farkle/rules.lua`. Nessuna tabella
   di punteggio duplicata. Non si applicano commissioni, medaglie
   o potenziamenti: sono un altro problema di design.
2. Si alternano **Leader** e **Rispondente** a ogni mano; il primo
   Leader è un parametro, nei pilot alternato secondo la parità
   del seed. Primo a **due mani** vinte, massimo tre mani.
3. Il Leader deve accantonare almeno una selezione valida dopo
   ogni lancio, può fermarsi dopo k=1,2,3 lanci; il terzo impone
   l'incasso. Un Farkle perde immediatamente la mano.
4. Il Rispondente vede il punteggio S e dispone di **al massimo
   k lanci**. Deve superare S, non soltanto pareggiarlo.
   Se lo supera, la mano termina immediatamente; se pareggia,
   non lo supera entro k o Farkla, vince il Leader.
5. Hot dice conservati dal valutatore canonico: se tutti i dadi
   sono accantonati, il successivo lancio usa di nuovo sei dadi,
   sempre contando verso il massimo di tre.
6. Il vincitore conquista **una mano**, non HP, danni o moneta.
   La posta economica resta aperta in RQ-002; non la si inventa
   per questo test.

Nota tecnica: l'engine usa `Rules.new('control')`,
`Rules.start`, `Rules.settle`, `Rules.options`,
`Rules.toggle`, `Rules.take` e `Rules.can_roll`.
Non usa `Rules.bank_turn` perché questa funzione attiva
commissioni e avanzamento di produzione, estranei al duello.
Il banking è invece risolto localmente con `turn.pot`.

## Protocollo numerico congelato prima del pilot

**Seed:** pilot 1001–2000 inclusi, 1000 incontri per cella;
5 policy del giocatore × 2 policy del rivale = 10 celle.
I seed sono appaiati come etichette fra le celle, ma i consumi
di RNG possono divergere per scelte differenti. Flussi di dadi
distinti per contendente e mano, Park–Miller deterministico.
Nessun RNG truccato e nessun recupero dinamico.

**Policy scripted, non competenza umana:**
- `prudent`: sceglie l'accantonamento col maggior punteggio
  immediato; come Leader incassa da 40 punti.
- `aggressive`: valuta punti + 9 per ogni dado disponibile al
  prossimo lancio; come Leader incassa da 120 punti.
- `random_legal`: sceglie uniformemente una selezione valida
  e come Leader incassa con probabilità 1/2.
- `informed`: valuta punti + 6 per dado disponibile;
  come Leader usa soglia 60 contro Rivale prudente, 85 contro
  Rivale aggressivo. È un'euristica informata, **non ottima**.
- `informed_blind` (ablazione): medesima euristica di
  selezione ma soglia fissa 70, senza leggere la policy rivale.

Il Rispondente di qualunque policy non concede volontariamente
una mano se può ancora rilanciare e non ha superato il bersaglio;
una volta superato, il gioco termina. La differenza fra policy
del Rispondente risiede quindi soprattutto **nella selezione dei
dadi**, non in una falsa scelta di incasso. Il confronto
`informed` vs `informed_blind` è un controllo limitato,
non una prova di ottimalità.

**Studio controfattuale STOP/CONTINUE:** si campionano i primi
80 stati validi dopo k=1 e i primi 80 dopo k=2 tra i seed
20001–20200, con selezione prudente del Leader. Per ogni
stato e ogni Rispondente (`prudent`/`aggressive`),
96 campioni appaiati confrontano: STOP ora, oppure **un
solo lancio ulteriore seguito da incasso** (se non Farkla).
Il secondo ramo è un'approssimazione one-step, **non** la
policy ottima a più passi. Le stime sono probabilità di
vittoria del Leader, non punteggi medi.

**Classificazione:** `CONTINUE` se
P(vittoria|continue) - P(vittoria|stop) > +0.10;
`STOP` se < -0.10; altrimenti `incerto`.
La fascia ±0.10 evita di chiamare significativa una differenza
minima da Monte Carlo; non è un test statistico formale.

**Gate numerici esplorativi, stabiliti prima del test:**
- **Trade-off G3a:** per almeno un k e almeno un profilo del
  Rispondente, almeno il 10% degli 80 stati classificato STOP
  e almeno il 10% CONTINUE. In caso contrario, indizio di
  scelta dominante o troppo rara.
- **Sensibilità G3b:** almeno 5% dei 160 stati complessivi
  cambia classificazione decisiva STOP↔CONTINUE fra i due
  profili del Rispondente. In caso contrario, il rivale potrebbe
  essere decorativo, oppure i profili insufficientemente distinti.
- **Invarianti G2:** nessuna mano con >3 lanci del Leader;
  nessun Rispondente con più lanci del Leader; pareggio al
  Leader; Farkle immediato; ruolo alternato; best-of-three;
  stesso seed e policy ⇒ stesso evento e risultato.
- **G4 umano:** non verificato da questi script. Prima di
  promuovere, chiedere al tester perché si ferma e quale
  opportunità concede, e confrontare due stati con policy
  del rivale differente.

Le soglie G3 sono **criteri di screening** arbitrati prima del
pilot, non garanzia di qualità. Win rate ≈50% non è un gate.

## Esecuzione dalla root del repository

```sh
lua5.4 tests/labs/battute_gemelle_test.lua
luajit tests/labs/battute_gemelle_test.lua

mkdir -p bg-results
lua5.4 experiments/battute_gemelle_lab/run.lua 1000 1001 bg-results
# oppure senza output CSV:
lua5.4 experiments/battute_gemelle_lab/run.lua 1000 1001
```

Output: `bg_matches.csv` (10.000 righe di match + header)
e `bg_states.csv` (320 righe di stima + header);
report stampato su stdout. La workflow branch-only archivia
i CSV come artefatti CI; non altera il gioco.

## Criticità da cercare

- **STOP sempre al primo lancio:** l'opportunità concessa domina
  il guadagno atteso del secondo.
- **CONTINUE sempre:** la limitazione k non crea costo reale.
- **Falsa differenza di rivale:** follower prudente e aggressivo
  scelgono le stesse combinazioni nella maggior parte degli stati.
- **Cap mutilante:** il limite tre riduce il piacere del Farkle
  o rende hot dice irrilevanti; richiede playtest.
- **Bias di ruolo:** il vantaggio di pareggio al Leader può
  non compensare il fatto che il Rispondente conosce S.
- **Falso senso di prova:** Monte Carlo one-step e policy
  euristiche non dimostrano l'ottimo matematico.
- **Posta assente:** la posta economica e swelling power
  non vengono risolte in questo primo laboratorio.

## Stato dei gate

- **G0:** fonti e SHA della baseline documentati.
- **G1:** regole isolate e invarianti definiti; review ancora aperta.
- **G2:** PASS; 11 casi Lua 5.4 e 11 LuaJIT, workflow CI verde
  sul commit `16a48c3c163811170ae50c3f4d2c3a8cccdef277`.
- **G3a:** NON SUPERATO; nessuna condizione raggiunge 8/80 stati
  CONTINUE decisivi (massimo 7/80).
- **G3b:** NON SUPERATO; 0/160 inversioni decisive cambiando
  policy del Rispondente.
- **G4:** playtest umano non eseguito.
- **G5:** decisione provvisoria: sospendere questa forma minima,
  non integrare. Nessuna approvazione canonica.

**Risultati, limiti e dati grezzi:** [scheda EX-BG-001](../../research/EX-BG-001.md),
[CI #42783312311](https://github.com/Askeladd22/Project_Folio/actions/runs/42783312311),
[CSV e report](https://github.com/Askeladd22/Project_Folio/actions/runs/42783312311/artifacts/13746373235).
Le soglie preregistrate sopra non sono state cambiate dopo i risultati.

Non modificare `src/` e non aprire una PR di integrazione
senza decisione esplicita e aggiornamento version.txt/CHANGELOG.md
secondo `docs/versioning.md`.
