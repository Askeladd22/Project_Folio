# Project Folio — laboratorio A/B/C0/C «Incontri e Segni»

**31 ottobre 2026 — aggiornato alla v0.1.0-dev.6: esperimento NON approvato né integrato nella partita.**
Il gioco effettivo resta il Farkle con sei D6 fisici g3d; personaggi e
miniature sono 2D. Nessuna modifica a `src/`, a `main.lua`, allo
scoring, alla fisica o ai comandi è richiesta per lanciare il laboratorio.

La prima versione dev.5 e l'ablation test dev.6 sviluppano la prova proposta in
[`docs/INCONTRI_E_SEGNI.md`](../../docs/INCONTRI_E_SEGNI.md),
senza confonderla con il **duello Farkle simmetrico contro il Monaco**
già giocabile nella beta.

**Risultati di regressione estesa (256 semi):**
[rapporto sperimentale con evidenze CI](RESULTS_2026_10_31.md).
Il campione non dimostra che i bonus C migliorino le scelte:
l'ablazione C0 va leggermente meglio per tutte le politiche.

## Analisi della v0.1.0-dev.6 — controllo più equo e ablation test

Il primo esperimento `dev.5` aveva tre limiti: **B mirava a
100 punti in sei mani** mentre **C mirava a tre marche**,
quindi le quote di vittoria non erano comparabili; il semplice
offset tra stream pseudocasuali di dadi era correlato; inoltre
non si poteva distinguere il contributo delle forze dei Segni
da quello dei bonus. Il nuovo laboratorio corregge il protocollo,
non il gameplay e non dimostra automaticamente la profondità.

**Quattro condizioni (A/B/C0/C):**

| Modalità | Condizione di successo | Limite |
|---|---|---|
| A | Commissione Farkle reale: 100 punti incassati | 4 mani |
| B | Progressione fissa: 3 marche, una per ogni mano con almeno 35 punti incassati | 6 mani |
| C0 | Stesso sacchetto, forze e obiettivo della C, **ma senza marche doppie** | 6 mani |
| C | Leone con sacchetto, forze nascoste e bonus esplorativi | 6 mani |

B, C0 e C hanno **tre marche e sei mani**; restano comunque
differenti per frequenza delle soglie, informazioni, riciclo
e bonus. A resta un riferimento di controllo alle regole
attuali, non un benchmark con pari difficoltà.

Per la prova riproducibile ora si usa un generatore virtuale
**indicizzato da (seme, mano, rilancio, ID del D6)**. I dadi
della medesima posizione ricevono la stessa faccia iniziale
nelle tre strategie anche quando queste consumano una diversa
quantità di tiri; il sacchetto è mescolato separatamente.
Il mescolamento con XOR a 31 bit è scritto in puro Lua
5.1/5.4: evita il precedente collasso in poche sequenze,
ma **non costituisce una certificazione di casualità fisica**.

L'output ora include:
- **PAIRED_OUTCOMES**, con risultati congiunti sui medesimi
  semi, varianti C contro B e C contro C0, inclusa differenza
  di frequenza delle vittorie e intervallo approssimativo
  al 95% (non un test di causalità o divertimento);
- **PUBLIC_CATEGORY_CHOICES**, con incassi, rilanci e
  divergenze degli stati osservati sotto Assalto, Guardia
  e Occasione;
- i contatori precedenti di durata, Farkle e rilanci.

Le tre strategie restano politiche a soglia inventate per
l'esperimento. La prima domanda da falsificare è se
**C batte C0 soltanto grazie alle marche doppie**, e
se **prudente** continua a prevalere a campioni maggiori.
Non promuovere C a modalità giocabile in base a questa
tabella senza playtest umano.

### Riproduzione

```powershell
luajit experiments/signs_lab/run.lua 256 20261031
```

Il benchmark in CI usa un campione più piccolo per
limitare i tempi di regressione. Nella documentazione
i risultati numerici vanno dichiarati **solo dopo**
l'effettiva esecuzione, con numero di semi e commit.

## Avvio, senza LÖVE né compilazioni native

Dalla cartella principale:

```powershell
luajit experiments/signs_lab/run.lua 100 20261031
```

In alternativa:

```powershell
lua5.4 experiments/signs_lab/run.lua 100 20261031
```

Il primo argomento è il numero di fixture-seed **per ogni
coppia modalità/strategia**, il secondo è il seme iniziale.
L'output è testo leggibile: modalità, strategia, campioni,
quota di raggiungimento dell'obiettivo, mani e lanci medi,
Farkle, incassi, rilanci e divergenze di scelta fra le strategie.
A parità di seme e versione sorgente, il risultato è riproducibile.
Non scrive file né cambia impostazioni o salvataggi del gioco.

## Dati storici del primo esperimento dev.5 (protocollo superato)

> **Nota v0.1.0-dev.6:** questa sezione descrive il protocollo
> della versione `dev.5`; la modalità B è stata ridefinita
> e C0 aggiunta come descritto sopra. Non usare la tabella
> seguente per interpretare i nuovi risultati del CLI.


| Modalità | Condizione sperimentale | Limite |
|---|---|---|
| **A — controllo Farkle** | Prima commissione esistente, obiettivo 100 punti incassati | **4 mani**, come in `commission_progress.lua` |
| **B — progresso lineare** | Obiettivo sperimentale di 100 punti cumulativi, senza avversario | **6 mani**, per confrontare il ritmo di una risorsa semplice |
| **C — Poste / Leone** | Prima a 3 marche fra copista e figura; i Segni sono estratti senza reinserimento | **6 mani**, con possibile parità |

La **percentuale di vittorie in A, B e C NON è un confronto
equilibrato di difficoltà**: obiettivi e numero massimo di mani
sono diversi. Le metriche sono esplorative. Nessuna affermazione
di profondità, «bilanciamento» o divertimento deriva
automaticamente dal fatto che C abbia una quota diversa.

Le stesse tre politiche vengono confrontate in ogni modalità:
- **prudente:** considera di incassare quando il totale
  selezionato raggiunge 25 punti;
- **audace:** preferisce proseguire fino a 85;
- **reattiva:** soglia 35/55/65 quando è annunciato
  rispettivamente Assalto/Guardia/Occasione; 40 senza Segno.
  Tutti i numeri sono *segnaposto* di laboratorio.

Le politiche rispettano sempre la possibilità legale di
`Rules.bank_status`, le selezioni di `Rules.options`,
`Rules.toggle`, `Rules.take`, `Rules.start`,
`Rules.settle` e `Rules.bank_turn`. I lanci D6
sono virtuali **per la sola simulazione**, non sostituiscono
il lancio fisico g3d nella partita.

## Una fixture completa (C): Leone della Bordura

Il file `fixture.lua` usa i **numeri esplorativi già scritti**
nel documento di design, senza dichiararli approvati.

- **Sei Segni**, distinti per ID: Assalto 20/40,
  Guardia 30/50, Occasione 35/55.
- Prima della mano, il sacchetto **rivela la categoria**
  del Segno ma non la forza; i valori possibili sono
  noti dalla fixture. Ogni Segno pescato rimane attivo
  finché la mano non è stata risolta, poi passa agli scarti.
- Si usano i **punti effettivamente incassati** al termine
  del turno Farkle. Con punti pari o superiori alla forza
  del Segno, una marca va al copista; altrimenti alla figura.
  Il Farkle perde i punti provvisori e la mano.
- Un'Occasione superata con **almeno 25 punti di margine**
  assegna due marche al giocatore. Un Farkle sotto
  Assalto assegna due marche alla figura.
- La prima parte che raggiunge **3 marche** vince.
  Al raggiungimento delle **6 mani** (se nessuno ha vinto)
  prevale il numero di marche, altrimenti è parità.
- Il sacchetto **si ricicla solo quando è vuoto**:
  tutti i Segni risolti tornano disponibili dopo
  un nuovo mescolamento. Nessun reinserimento immediato.

**Queste condizioni sono una fixture di test falsificabile,
non la nuova modalità canonica di Project Folio.** Dopo un
playtest le soglie, i doppi punti, le condizioni di termine
e persino l'esistenza di un sacchetto potrebbero cambiare.

## Qualità dei dati / problemi aperti

La colonna `POLICY_DISAGREEMENTS` conta i momenti in cui
le politiche prenderebbero decisioni diverse **sullo stesso
stato pubblico osservato**. Non misura il loro valore atteso
controfattuale, e non prova che un'opzione sia migliore.

I risultati non considerano:
- abilità e medaglie acquisite nella run, dadi truccati,
  effetti delle facce, progressione persistente;
- ritmi visivi, input con mouse, motion reduced,
  suspense del lancio fisico e attenzione del giocatore;
- volontà e reazioni del giocatore umano, né strategie
  ottime calcolate su tutti gli stati.

C non potrà essere promossa al runtime finché non si saranno
eseguiti playtest reali e confronti su **diverse fixture e
strategie**, verificando l'assenza di una politica dominante,
la durata e la qualità delle scelte. Il valore di «più
difficile» non equivale a «più interessante».

### Gate di isolamento

`tests/signs_encounter_lab_test.lua` verifica anche che
nessun modulo `experiments.signs_lab` sia importato da
`main.lua` o dal controller Farkle. Il sacchetto non
riceve eventi `dice.physical_settled`: un Segno si risolve
**solo dopo una mano Farkle completata**. L'uso del
generatore Park–Miller evita di modificare il RNG globale
o quello della fisica.
