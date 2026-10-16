# L'arte del rischio — rapporto sperimentale

14 ottobre 2026. Regole approvate conservate, senza ribilanciamenti nascosti.
Prototipo A/B/C giocabile con gli stessi dadi fisici e asset della bottega.

## Esito

**C merita la prossima prova manuale**, con B come controllo. Il cambio a costo
fisso offre una decisione osservabile fra insistere e accettare una ricompensa
minore. Non è ancora dimostrato che C produca più suspense.

La criticità comune è il rischio da opera completa: le finiture non compensano
normalmente la perdita possibile. Il rischio utile compare soprattutto vicino
alla soglia di vittoria, all'ultimo turno. Nessuna variante risolve da sola questo
problema. Non consiglierei ancora di sostituire il gameplay principale.

## Metodo e riproducibilità

54.000 partite finali, 2.000 per ciascuna di 3 varianti × 9 politiche.
Semi 10001–12000, Park–Miller con 32 passi di riscaldamento; flussi separati
per dadi e decisioni casuali. Il primo lotto senza riscaldamento era distorto
ed è stato scartato, non incluso nelle tabelle. Un test controlla adesso la
distribuzione della prima faccia sui semi di valutazione (334/333/334/334/332/333).
Gli agenti non accedono al seme, allo stato del generatore o ai risultati futuri.
Le sequenze divergono quando cambia il numero di dadi lanciati: non presentiamo
le differenze fra politiche come un test appaiato con identici lanci per turno.

- Casuale: progetto e sottoinsieme di dadi casuali; da opera completa assicura
  con probabilità 1/2; Tentazione con probabilità 1/2 quando disponibile.
  È un controllo debole, non rappresenta un principiante umano.
- Opportunista: valuta esattamente un rilancio e l'assicurazione immediata,
  massimizzando punti. Non valorizza la varietà obbligatoria.
- Pianificatore: enumera esattamente le continuazioni dei rilanci per la ricetta
  impegnata nel turno; bonus euristico +4 per un tipo d'opera ancora mancante.
  Sceglie fra cambio C e prosecuzione allo stato corrente, ma non anticipa un
  cambio C futuro. Non risolve l'intera partita.
- Pianificatore con soglia: come sopra; nell'ottavo turno aggiunge utilità 1000
  alla vittoria raggiungibile. È un controllo della sensibilità all'obiettivo,
  non un solver ottimo di partita. Prima dell'ultimo turno usa la stessa euristica.
- Controlli: pianificatore senza Tentazione, senza rischio da opera completa,
  e tre preferenze fisse di progetto.

L'enumerazione usa tutte le 126 mani cromatiche non ordinate con le loro
molteplicità esatte, verificate separatamente sui 1.296 esiti ordinati.
Le simulazioni assumono D6 uniformi e indipendenti: le frequenze del motore
fisico sono una verifica separata, non la sorgente di probabilità del solver.
Il campione reale di 64 lanci iniziali (256 dadi) ha prodotto rosso 51, blu 40,
giallo 44, verde 38, marrone 42, nero 41: rispettivamente 19,9%, 15,6%, 17,2%,
14,8%, 16,4%, 16,0%. Non mostra una distorsione grossolana, ma non certifica
uniformità, indipendenza o frequenze dopo una trattenuta. In particolare non
va usato per riscrivere le probabilità delle ricette sulla base di sole 256 facce.
Il test esteso ha richiesto un limite di tempo superiore al primo tentativo;
il run completo conclusivo è registrato in smoke.log e physical-sample.csv.
Le politiche non sono state ottimizzate sui semi per ottenere una variante vincente.
L'agente con soglia è un'analisi esplorativa aggiunta dopo aver osservato la
carenza dell'obiettivo a punti; servirebbero nuovi semi per una validazione esterna.

## Confronto misurato

Percentuale di partite vinte; la vittoria richiede sia 25 punti sia tutti i tipi.

| Variante | Casuale | Opportunista | Pianificatore | Pianificatore con soglia |
|---|---:|---:|---:|---:|
| A, vincolo preventivo | 0,05% | 0,00% | 24,15% | 31,65% |
| B, scelta dopo il primo lancio | 0,05% | 33,65% | 43,80% | 46,90% |
| C, cambio a costo 2 | 0,00% | 22,65% | 38,65% | 44,15% |

L'opportunista A produce in media 19,62 punti, più del pianificatore (17,32),
ma sceglie sempre il fregio e non vince mai. È un esempio concreto del motivo
per cui il solo punteggio medio sarebbe una misura fuorviante.

Con soglia finale, la media è 16,84 / 23,23 / 21,19 per A/B/C: meno punti del
pianificatore base, più vittorie. Gli intervalli Wilson 95% delle vittorie sono
29,6–33,7%, 44,7–49,1%, 42,0–46,3% rispettivamente. B e C non sono separati
nettamente da questi intervalli; soprattutto, vittoria non significa suspense.

Tabelle complete, quantili e intervalli: measured-tables.md. Partite individuali:
games.csv; aggregati e conteggi decisionali: results.csv.

## Difficoltà delle ricette

| Ricetta | Premio base / massimo | Primo lancio | Entro due rilanci ottimali per completare |
|---|---:|---:|---:|
| Rosso, rosso | 3 / 7 | 13,1944% | 56,1243% |
| Verde, verde, giallo | 6 / 8 | 4,4753% | 35,7328% |
| Rosso, blu, giallo, nero | 10 / 10 | 1,8519% | 20,5367% |

Calcoli esatti per progetto impegnato, senza cambio o Tentazione, trattenendo
ottimamente per massimizzare il completamento. Non sono le percentuali della
politica a punti, che può fare scelte differenti.

Moltiplicando solo il premio base per la probabilità entro tre lanci si ottiene
1,68 / 2,14 / 2,05 punti. Le ricompense non sono quindi sproporzionate come
potrebbero apparire dal solo primo lancio, ma il fregio resta competitivo.
La miniatura occupa tutti i dadi: nessuna finitura è possibile. Marrone non
serve a nessuna ricetta; è sempre un pigmento da rilanciare. Questo riduce
la varietà delle decisioni di trattenuta e va considerato nel prossimo design.

## Assicurare oppure rischiare

Enumerazione delle mani complete, includendo costo di cambio 0 e 2: in 56
stati canonici il valore atteso di fermarsi supera quello di continuare con
due rilanci residui e senza Tentazione. I dadi permutati non sono contati come
scelte diverse. Nei massimi 7/8/10, continuare fallisce con certezza.

Esempi con un ultimo rilancio:

- Capolettera da 3: tenendo RR, rilanciando due dadi, 10/36 danno 5 punti,
  1/36 ne dà 7; 25/36 fanno perdere tutto. Valore atteso 57/36 = 1,58, contro 3.
- Capolettera da 5: un dado per arrivare a 7; valore atteso 7/6 = 1,17, contro 5.
- Fregio da 6: un dado, due pigmenti utili su sei; valore atteso 8/3 = 2,67, contro 6.

Questo NON dimostra che fermarsi domini rispetto alla vittoria in ogni stato.
Ultimo turno, 21 punti, tutti i tipi già presenti, RRBG e capolettera da 3:
assicurare porta a 24 e perde; rischiare gli altri due dadi vince con 11/36.
Con 22 punti e la medesima mano, fermarsi vince certamente. Entrambi i casi
sono testati nell'analisi esatta.

La frequenza è però molto bassa: il pianificatore base sceglie zero rischi
da opera completa; quello con soglia ne sceglie **0 in A, 3 in B, 2 in C**,
su 16.000 turni per variante. Sono 0%, 0,01875%, 0,0125% dei turni simulati.
La tensione del miglioramento è quindi possibile, ma quasi assente per queste
politiche. Il controllo senza rischio riproduce esattamente il pianificatore base.
I conteggi stop_better escludono gli stati senza alcun rilancio legale.

## Decisioni, varietà e Tentazione

Il pianificatore base completa:

| Variante | Capilettera / fregi / miniature | Cambi per partita | Tentazioni per partita |
|---|---|---:|---:|
| A | 30,5% / 49,5% / 20,0% | 0 | 1,946 |
| B | 34,2% / 45,6% / 20,2% | 0 | 1,847 |
| C | 33,6% / 44,0% / 22,5% | 3,103 | 1,787 |

In C il cambio viene usato in circa il 38,8% dei turni: non è né irrilevante
né automatico. È una frequenza di azioni sotto questa politica, non una misura
diretta di esitazione o profondità umana. In B l'osservazione della prima mano
consente di adattarsi senza rimpiangere un impegno precedente.

Per una ricetta incompleta, i rilanci ordinari sono gratuiti e non rischiano
opere precedenti: continuare prevale normalmente su abbandonare. Per una completa,
fermare prevale normalmente per punti. Gran parte del ciclo è dunque prevedibile;
le scelte principali sono progetto, dadi utili, cambio C e pagamento della Tentazione.
Le colonne reroll1..reroll4 registrano la frequenza dei sottoinsiemi per numero
di dadi, non la scambiano per una misura automatica di decisioni significative.

Senza Tentazione, il pianificatore vince 28,45% / 37,70% / 36,60%.
Con Tentazione: 24,15% / 43,80% / 38,65%. Differenze osservate -4,30 / +6,10 /
+2,05 punti percentuali. Non sono effetti causali del solo pulsante: cambiano
anche le decisioni e la sequenza di dadi consumata. In particolare A rivela che
l'euristica può pagare troppo per inseguire un tipo mancante. La penalità crescente
ha un effetto reale; il casuale accumula costi e punteggi medi negativi.

Le politiche fisse non possono soddisfare la varietà richiesta e perdono per
costruzione: questo non prova l'assenza di una strategia dominante fra politiche
adattive. Non abbiamo un solver globale degli otto turni. Il fregio domina
la preferenza dell'opportunista A, non tutte le decisioni possibili del gioco.

## Giocabilità e verifiche

Pacchetto autonomo arte-del-rischio.love e launcher scripts/run_risk.py.
Tre varianti selezionabili dall'interfaccia; dadi fisici colorati, trattenuta
individuale, rilanci selettivi, cambio C, Tentazione, assicurazione e opere
procedurali sul folio. Nomi dei pigmenti, massimo ottenibile e avviso di perdita
certa aiutano a comprendere il rischio. Animazione del lancio originale e breve
apparizione dell'opera; nessuna illustrazione nuova o modifica al layout originale.

Il collegamento è in un processo LÖVE separato: sostituisce in memoria il
controller importato da main.lua e il pool iniziale. main.lua e tutti i file
di produzione restano invariati. Il solver fisico non è modificato. I dadi
trattenuti sono esclusi dai corpi attivi, così le collisioni non ne alterano la faccia;
possono però sovrapporsi visivamente ai dadi rilanciati. Picking e tasti 1–4
offrono due modi di selezione. Questo limite visivo resta da valutare manualmente.

La suite originale passa 12/12 file. I test sperimentali coprono ricette,
finiture, limiti, varianti, cambio, penalità, vittoria, fallimento, callback
parziali e regressione del generatore. Prove reali LÖVE verificano A/B/C, blocco
input in volo, picking a 1920×1080 e 1280×720, orientamento trattenuto invariato,
cambio/assicurazione e Tentazione. I rami rari del controller sono provati con
callback controllati, distinti dai test di lanci fisici effettivi nel log.

Screenshot e log sono locali; nessun test simulato viene presentato come partita
manuale osservata. Le animazioni e la leggibilità sono state ispezionate tramite
screenshot, non mediante uno studio con giocatori.

## Raccomandazione

Provare prima C, poi B, infine A, quindi invertire l'ordine in una seconda serie.
Annotare tre cose: quando nasce un'esitazione reale; quando si paga un cambio
con rimpianto; quando si desidera un altro lancio pur comprendendo la perdita.
Distinguere la voglia di recuperare una ricetta incompleta dalla voglia di rischiare
un risultato già ottenuto: oggi il sistema genera soprattutto la prima.

Se le partite manuali confermano il problema, il prossimo esperimento dovrebbe
toccare soltanto il rapporto fra premio della finitura e perdita al fallimento.
Non servono nuove risorse o potenziamenti. Nessuna di queste correzioni è stata
applicata qui: questo pacchetto conserva integralmente la specifica approvata.
