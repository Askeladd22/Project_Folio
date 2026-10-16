# Motivi contesi — rapporto sperimentale, 13 ottobre 2026

**Esito: non integrare.** Abbiamo introdotto sacrifici reali e reso utili i
rilanci, ma non dimostrato che adattarsi sia meglio di seguire una buona terna
fissa. Il pianificatore migliorato nelle capacità è peggiore dell'opportunista
in due configurazioni. Tutto il lavoro è in `experiments/contesi`; il precedente
esperimento da 30.000 partite, il gioco originale e i suoi asset sono invariati.

## Criterio di progettazione e fonti

Ho consultato la [presentazione del libro da parte di Sylvester](https://tynansylvester.com/book/)
e il suo [articolo Decision-Based Gameplay Design](https://tynansylvester.com/2005/01/4/).
Non ho letto il testo integrale del libro durante questo esperimento. La prima
fonte presenta eleganza e valutazione dei compromessi; la seconda tratta scelte
concorrenti, conseguenze percepibili e il problema di ripetere situazioni con
una risposta già nota. Non attribuisco al libro soglie numeriche o algoritmi.

Applicazione progettuale: una scelta deve eliminare un'alternativa valida e
l'alternativa migliore deve dipendere dalla situazione. Aumentare le sconfitte
o distribuire le vittorie fra due rami non dimostra, da solo, profondità o
divertimento. Le emozioni e la leggibilità delle conseguenze richiedono ancora
playtest umani; le simulazioni misurano solo alcuni presupposti meccanici.

## Regole e tre configurazioni

Folio 4x5, quattro D6 cromatici, otto turni, massimo due piazzamenti per turno,
quattro rilanci globali. Ogni gettone rilancia un sottoinsieme non vuoto dei dadi
inutilizzati. Piazzamenti definitivi. Si può passare, perdendo le opportunità
residue del turno; i dadi non usati non si conservano. Tre motivi completati
vincono immediatamente, altrimenti si perde dopo l'ottavo turno.

Ogni motivo è un 2x2 con **pigmento richiesto in ciascuna posizione**, non una
scacchiera ruotabile liberamente o un quartetto permutabile. Questa è la nuova
specializzazione dichiarata delle richieste cromatiche. Le posizioni dei dadi
restano numeri tecnici; lo stato ludico contiene nomi di pigmenti. `place` non
accetta un colore scelto dall'agente: usa la faccia presente nella mano.

Legenda: R rosso, B blu, G giallo, V verde, M marrone, N nero. I quattro pigmenti
indicati sono in ordine alto-sinistra, alto-destra, basso-sinistra, basso-destra.
Coordinate (riga,colonna), base 1.

| Configurazione | A | B | C | D |
|---|---|---|---|---|
| Bivio | (1,1) R B B R | (1,2) V G G V | (3,1) G V M N | (3,4) R B M N |
| Ponti | (2,2) R B B R | (2,3) V G G V | (1,1) M N B R | (1,4) M N G B |
| Asimmetrico | (1,1) R B B R | (1,2) M N N M | (3,1) R B G V | (3,4) R B B R |

In ogni configurazione A e B condividono due caselle incompatibili. C e D sono
compatibili con entrambi. In Ponti i motivi di supporto condividono inoltre una
casella con il rispettivo ramo. In Asimmetrico A concentra ulteriormente rosso
e blu già richiesti dai supporti, mentre B richiede marrone e nero.

## Solver e sacrifici dimostrati

Il solver enumera tutte le quattro terne e unifica i requisiti esatti per
casella. Una doppia assegnazione incompatibile prova UNSAT; l'unione coerente è
un testimone completo SAT. Per questo linguaggio a colori esatti non serve una
ricerca approssimata. È verificato anche il budget massimo di 16 piazzamenti.

| Configurazione | Terne SAT | Piazzamenti necessari | Terne UNSAT |
|---|---|---:|---|
| Bivio | ACD, BCD | 12 ciascuna | ABC, ABD |
| Ponti | ACD, BCD | 11 ciascuna | ABC, ABD |
| Asimmetrico | ACD, BCD | 12 ciascuna | ABC, ABD |

Le matrici testimone sono in `solver.txt`. La disponibilità dei pigmenti su un
lancio concreto non è certificata dal solver; ciascun testimone ha però una
sequenza di lanci possibile e le simulazioni mostrano vittorie di entrambi i rami.

Esempio Bivio: blu in (1,2) è richiesto da A ma elimina B, che vi richiede verde.
La scelta opposta elimina A. Completare tutti e quattro i motivi è impossibile.
Compromettere anche C o D dopo questa scelta rende impossibile vincere.

## Agenti e protocollo

- Casuale prudente: uniforme fra piazzamenti utili ad almeno una terna ancora
  realizzabile. Non spreca mosse in caselle irrilevanti. Rilancia quando non ne
  trova, altrimenti piazza.
- Opportunista: premia immediatamente progresso e completamenti; stessa politica
  semplice di rilancio. Risolve i pareggi in ordine di casella/dado.
- Pianificatore: valuta piazzamenti, passaggio e tutti i sottoinsiemi di rilancio
  disponibili. Per ogni candidato usa 12 scenari indipendenti dalla mano futura
  reale, proseguendo fino alla fine del turno successivo. Durante le continuazioni
  riempie i colori più richiesti e può usare un ulteriore rilancio in ciascun
  turno se altrimenti perderebbe uno slot. Valuta fabbisogno residuo, concentrazione
  dei colori, tempo rimasto e riserva di gettoni.

L'agente sceglie una terna per la valutazione **prima** di mediare i futuri
campionati: non può selezionare retroattivamente il ramo migliore dopo aver
visto un futuro. L'osservazione passata ad `agents.lua` esclude seed reale,
contatori dei tentativi e nastro dei risultati. Un test verifica l'indipendenza
della decisione da seed nascosti diversi a osservazione uguale.

Limiti: il pianificatore usa una politica euristica nelle continuazioni, pochi
campioni e un orizzonte di un turno futuro; non è un giocatore ottimo. Non
preserva esplicitamente il valore di attendere prima di scegliere una terna.
La stima terminale può spingerlo a spendere troppo presto. Non è stato regolato
dopo aver visto i risultati per ottenere artificialmente un vantaggio.

Tutti gli agenti ricevono anche il medesimo filtro dei piazzamenti che mantengono
almeno una vittoria teorica. Quindi il casuale è un benchmark informato, non un
giocatore umano inesperto. Le mosse distruttive restano legali nel motore.

Seed di valutazione 10001..12000, distinti dal precedente esperimento.
Nastro casuale del precedente prototipo, indirizzato per turno/dado/tentativo:
il consumo di un rilancio non sposta gli altri lanci. Campionamento dell'agente
su uno stream separato; nessun accesso al nastro reale futuro. Il generatore
riusato è pseudocasuale, non una simulazione della distribuzione fisica 3D.

**48.000 partite:** 2.000 per configurazione e politica, tre configurazioni,
otto politiche: i tre agenti principali, planner senza rilanci, planner fisso
ACD/BCD e opportunista fisso ACD/BCD. I dati grezzi sono in `games.csv`,
gli aggregati in `results.csv`, intervalli e confronti accoppiati in `statistics.json`.

## Vittorie misurate

| Configurazione | Casuale | Opportunista | Pianificatore | Planner senza rilanci |
|---|---:|---:|---:|---:|
| Bivio | 92,45% | 93,95% | 85,65% | 69,00% |
| Ponti | 93,70% | 95,80% | 91,00% | 78,45% |
| Asimmetrico | 86,10% | 81,35% | 84,15% | 65,70% |

Delta planner meno opportunista, intervallo accoppiato approssimato al 95%:
- Bivio: **-8,30 pp**, [-10,01; -6,59].
- Ponti: **-4,80 pp**, [-6,20; -3,40].
- Asimmetrico: **+2,80 pp**, [0,69; 4,91].

Gli intervalli sono descrittivi, non corretti per confronti multipli. Differenze
di policy includono valutatore e gestione del rischio, non solo profondità di
ricerca: non sono una misura causale pura del valore della pianificazione.

## Strategie fisse e dominanza

| Configurazione | Opportunista fisso BCD | Opportunista fisso ACD | Planner fisso BCD | Planner fisso ACD |
|---|---:|---:|---:|---:|
| Bivio | 93,35% | 93,55% | 84,90% | 84,10% |
| Ponti | 96,25% | 90,45% | 90,55% | 88,05% |
| Asimmetrico | 93,20% | 73,20% | 84,10% | 64,70% |

Bivio non mostra un vantaggio convincente dell'adattamento: l'opportunista
libero supera il migliore fisso di appena 0,40 pp, IC [-0,32; 1,12].
Ponti permette di vincere quasi sempre fissando BCD prima di vedere i dadi.
Asimmetrico ha un ramo chiaramente preferibile per le politiche testate:
l'opportunista fisso BCD supera il libero di 11,85 pp.
Questo individua strategie empiricamente forti; non prova dominanza matematica
contro ogni possibile sequenza casuale o agente.

## Varietà, irreversibilità e rilanci

Numero di vittorie BCD / ACD:

| Configurazione | Casuale | Opportunista | Planner |
|---|---:|---:|---:|
| Bivio | 956 / 893 | 512 / 1367 | 862 / 851 |
| Ponti | 999 / 875 | 1237 / 679 | 1639 / 181 |
| Asimmetrico | 1223 / 499 | 555 / 1072 | 1676 / 7 |

Entrambe le strategie vincono realmente, ma nel planner Asimmetrico BCD
rappresenta il 99,58% delle vittorie. La varietà di Bivio non basta: due rami
equivalenti scelti presto possono essere una scelta cosmetica di strategia.

Turno medio del primo sacrificio irreversibile (resta una sola terna teorica):

| Configurazione | Casuale | Opportunista | Planner |
|---|---:|---:|---:|
| Bivio | 2,236 | 1,286 | 1,270 |
| Ponti | 1,694 | 2,639 | 1,986 |
| Asimmetrico | 2,095 | 1,234 | 1,994 |

Nessuna posizione finale senza una terna teoricamente recuperabile: il filtro
comune degli agenti lo impedisce. Le sconfitte sono scadenze, non errori cromatici
irreparabili aggiuntivi. Non si deve interpretare questo dato come assenza di
stati impossibili nel motore.

Il planner spende rispettivamente 3,235 / 2,947 / 3,280 rilanci medi. Togliendoli
perde 16,65 / 12,55 / 18,45 punti percentuali di vittorie: ora la risorsa conta.
Ma l'opportunista ne usa 2,445 / 2,042 / 3,113 e vince di più nei primi due casi.
Una risorsa utile non implica una gestione strategica ben riuscita del planner.
L'ablazione misura il risultato complessivo con budget zero, non il valore
causale del singolo rilancio, poiché modifica anche le scelte successive.

## Raccomandazione

Non integrare nessuna configurazione. Non c'è difficoltà eccessiva per questi
agenti informati; il problema è ancora il basso valore dell'adattamento.
Rispetto alle 30.000 partite precedenti abbiamo eliminato l'indifferenza ai
rilanci e introdotto rinunce vere, ma spesso una sola rinuncia iniziale.

Conservare Bivio come controllo simmetrico. Scartare Asimmetrico come candidato
principale: dimostra quanto una scarsità concentrata produca un ramo preferito.
Ponti è il punto di partenza più interessante per una revisione, grazie alle
caselle condivise con i supporti, ma **non è già una soluzione approvata**.

Prima di aggiungere regole, correggere la politica del planner su seed separati:
validare la stima terminale, confrontare 12/48/192 campioni, attribuire valore
alle alternative ancora aperte e controllare quando è meglio piazzare subito
anziché cercare una faccia migliore. Poi misurare su nuovi seed senza ulteriori
aggiustamenti. Il risultato peggiore non va mascherato aumentando la difficoltà.

Prossima modifica di design proposta, non realizzata: due momenti distinti di
contesa, così una decisione non risolve tutti i conflitti al primo turno.
Con soli quattro motivi e vittoria a tre, un'unica coppia incompatibile rende
gli altri due obbligatori: questa struttura limita intrinsecamente la varietà.
Per superarla servirà valutare alternative di realizzazione dei motivi oppure
un diverso insieme di obiettivi, non soltanto cambiare i pigmenti.

Condizioni per proseguire verso UI: un agente adattivo deve battere entrambe
le strategie fisse su casi non usati per tararlo; almeno due strategie devono
restare competitive in situazioni differenti. Infine playtest brevi devono
verificare che il sacrificio sia prevedibile e che il giocatore sappia spiegare
perché ha scelto un ramo. Nessun indicatore automatico dimostra il divertimento.

## Riproduzione e test

```powershell
rtk python scripts/test_luajit.py experiments/contesi/test.lua
rtk python scripts/test_luajit.py experiments/contesi/solver.lua
rtk python scripts/test_luajit.py experiments/contesi/simulate.lua
rtk python experiments/contesi/analyse.py
rtk python scripts/test_luajit.py
```

`CONTESI_N` può ridurre il numero di partite per debug; i CSV consegnati usano
il default 2000. `analyse.py` richiede almeno 2000 righe per confronto.
Solver e test delle tre configurazioni PASS; suite originale 12/12 PASS.
Test: testimoni vincenti e incompatibilità, budget di piazzamenti/rilanci,
permanenza, input invalidi senza consumo, fine partita e isolamento del seed.
Durante tutte le simulazioni un'asserzione controlla che nessuna mossa cambi
un piazzamento precedente. Non sono stati avviati il renderer o i salvataggi.
