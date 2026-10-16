# Manuscript — vertical slice roguelite

Prototipo indipendente giocabile con il motore fisico 3D e la bottega esistenti. Non implementa Folio progressivo: segue la nuova richiesta di applicazioni persistenti, sessioni limitate e scelta di una tecnica dopo il primo folio.

## Avvio

Aprire **Avvia.cmd** in questa cartella, oppure aprire `folio-roguelite.love` con LÖVE. Dal workspace:

```powershell
rtk proxy python scripts/run_folio.py
```

Il launcher ricostruisce l'archivio prima di avviarlo. Non avviare direttamente `app/main.lua`: usa il pacchetto con il motore condiviso. Finestra 1920×1080 ridimensionabile, verificata anche a 1280×720.

## Come giocare

1. **Spazio / Lancia**: tira quattro dadi.
2. Clic su un dado 3D, sul suo pulsante nella riserva, oppure **1–4**: seleziona il dado.
3. Clic su un requisito libero dello stesso pigmento: applica il colore. Il dado esce dalla riserva fino alla sessione seguente. Puoi completare più decorazioni nella stessa sessione.
4. **Invio / Fissa**: conserva tutte le applicazioni, anche incomplete, e termina la sessione. **N** apre la successiva con quattro dadi nuovi.
5. Oppure **Spazio / Rilancia**: tira tutti i dadi non usati. Se nessuno può riempire un requisito libero, perdi soltanto le applicazioni umide e la sessione termina. Le applicazioni fissate restano.
6. Completa e fissa il primo folio, scegli una tecnica, poi affronta il secondo. **R** ricomincia una prova da zero; **Esc** chiude.

Durante il moto i comandi di gioco sono bloccati. I dadi già usati rimangono visibili e indicati come tali; vengono esclusi dai corpi attivi durante il tiro, tramite lo stesso adattatore dell'esperimento precedente. Non sono dadi trattenuti e non si possono riutilizzare o liberare nella stessa sessione.

## Specifica implementata

Due folii, **quattro sessioni per folio**, sei requisiti ciascuno. Ogni decorazione ha due pigmenti differenti. Ricette provvisorie, sempre visibili:

| Folio | Iniziale | Bordura | Miniatura |
|---|---|---|---|
| 1 | Rosso + Giallo | Giallo + Verde | Blu + Nero |
| 2 | Rosso + Blu | Blu + Verde | Giallo + Marrone |

Un pigmento condiviso rende possibile il trasferimento fra due decorazioni; di conseguenza un pigmento non serve nel primo folio e un altro nel secondo. Non è stato nascosto alterando le facce dei dadi. I due folii hanno lo stesso profilo di quantità richieste, a meno di rinominare i colori.

**Prima applicazione e rischio:** il primo lancio non causa fallimento. Se è positivo, bisogna applicare almeno un dado prima di rilanciare; questo evita la ricerca illimitata di un risultato desiderato senza impegno. Se il primo lancio non offre nessuna mossa, si può chiudere una sessione vuota oppure effettuare un rilancio. Un rilancio senza avanzamenti possibili termina sempre la sessione, anche se non c'era lavoro umido da perdere.

Non c'è un numero arbitrario aggiuntivo di rilanci: la riserva diminuisce applicando dadi. Non si recuperano dadi al completamento di una decorazione. Con riserva vuota o tutti i requisiti pieni si può soltanto fissare. Una decorazione piena ma umida può ancora perdere applicazioni in un fallimento mentre si cerca di completarne un'altra.

La vittoria richiede i due folii completamente **fissati**, non soltanto riempiti provvisoriamente. La quarta sessione può ancora completare il folio; se termina incompleta la prova finisce. Non ci sono punti, soglia 25, Tentazione, denaro, negozi o obblighi aggiuntivi di varietà.

### Tecniche

**Fissativo.** Nel secondo folio, premi T e scegli una casella UMIDA. `[P]` la identifica. In un fallimento quell'applicazione viene fissata; tutte le altre umide si perdono. Prima del lancio si può cambiare la scelta, ma soltanto una è protetta. La protezione si azzera a fine sessione ed è disponibile nella successiva. Fissare normalmente conserva tutto senza consumi ulteriori.

**Modello preparatorio.** Premi T, scegli una casella occupata, poi un requisito libero dello stesso pigmento in un'altra decorazione. Un uso per folio. Si può trasferire lavoro fissato o umido; lo stato resta identico. Il dado non torna nella riserva e il trasferimento non autorizza da solo un nuovo rilancio. Spostare una parte fissata può riaprire una decorazione già completa.

Le tecniche sono astrazioni ludiche, non ricostruzioni letterali delle lavorazioni medievali.

**Limite strutturale del Modello:** con queste sole regole il trasferimento non cambia il multinsieme dei pigmenti mancanti, la riserva o il rischio. Cambia quale decorazione è completa, ma non rende più probabile finire l'intero folio. L'enumerazione verifica questa invariante. Non sono stati aggiunti premi di decorazione o effetti nascosti per mascherarla. Questa tecnica serve anche come controllo negativo: se si cerca una progressione che modifichi le decisioni di rischio, non è ancora sufficiente. Fissativo invece modifica direttamente la perdita possibile.

## Probabilità e coerenza

Modello analitico: D6 cromatici uniformi e indipendenti. Non si è cambiata la fisica e non si è dimostrato che il suo campionamento coincida esattamente con il modello. La UI chiama il dato «rischio teorico».

Con `n` dadi non usati e `k` colori distinti ancora richiesti, la probabilità di fallimento del prossimo rilancio è `((6-k)/6)^n`. Conta l'insieme dei colori, non il numero di caselle libere: due requisiti gialli sono una sola faccia utile per evitare il fallimento, ma richiedono due applicazioni per essere entrambi riempiti.

| Dadi liberi | Colori utili | Fallimento esatto |
|---:|---:|---:|
| 4 | 5 | 1/1296 = 0,077% |
| 3 | 3 | 1/8 = 12,5% |
| 2 | 2 | 16/36 = 44,44% |
| 2 | 1 | 25/36 = 69,44% |
| 1 | 1 | 5/6 = 83,33% |

La prima riga descrive una riserva completa con cinque colori utili: il primo lancio, per regola, **non** causa perdita. Le altre righe mostrano perché il progresso sul folio cambia la convenienza di rischiare: diminuiscono sia la riserva sia i colori che possono avanzare.

### Una scelta che Fissativo può cambiare

Stato raggiungibile: due applicazioni fissate da sessioni precedenti, due umide nella sessione attuale, due dadi liberi e due requisiti mancanti di colori diversi.

- Fissare subito garantisce **2 nuove applicazioni permanenti**.
- Rilanciare una volta, applicare tutti i risultati compatibili e fissare: media esatta **62/36 = 1,722** nuove applicazioni. Il rischio è sfavorevole rispetto al fissare per questo obiettivo locale.
- Stessa decisione con una delle due applicazioni protetta: **78/36 = 2,167**. Il confronto si inverte.

I 36 esiti comprendono 16 fallimenti; il guadagno totale delle nuove applicazioni compatibili nei restanti esiti è 22. Senza protezione: `20×2+22=62`. Con protezione: si aggiungono 16 applicazioni salvate. È un calcolo di progresso medio, **non** una politica ottimale di vittoria con sessioni residue.

Vicino all'ultima sessione può convenire rischiare anche perdendo progresso medio: fissare un folio incompleto nell'ultima sessione significa perdere la prova. Viceversa, con sessioni disponibili, fissare parti incomplete conserva opportunità future. Sono condizioni da osservare, non dimostrazioni di coinvolgimento.

Con una sola applicazione umida protetta, il fallimento non può ridurre il progresso già acquisito nella sessione: Fissativo può rendere quel rilancio quasi automatico. Non è una proprietà da nascondere; va registrata come possibile debolezza del potenziamento.

### Perché quattro sessioni

Un controllo esatto semplice, senza rilanci e senza tecniche, assegna tutti i pigmenti utili del primo tiro di ogni sessione e fissa subito. Completare un folio entro quattro sessioni equivale a soddisfare le quantità richieste in 16 dadi: probabilità **3888316705/6530347008 = 59,5423%**.

È stata ottenuta con programmazione dinamica sui conteggi saturati dei pigmenti, non con simulazioni di partite. Indica che assicurare sempre è una strategia praticabile ma non garantita. Non è la percentuale prevista di vittoria del prototipo, né una validazione del limite scelto: giocatori, rilanci e fisica possono produrre risultati diversi.

## Verifiche eseguite

- Test del modello: conservazione parziale, consumo dei dadi, callback fisiche parziali e atomiche, fallimento, sessioni esaurite, passaggio di folio, vittoria, protezione e trasferimento umido/fissato una volta per folio.
- Enumerazione locale: tutti gli esiti dei casi di rischio riportati e invariante del trasferimento nei sottoinsiemi compatibili delle caselle.
- Smoke grafico: lancio e rilancio **realmente fisici**, picking, blocco input durante il moto, posa invariata del dado consumato. Seguono callback controllate per raggiungere in modo deterministico entrambi i rami delle tecniche e la fine della prova.
- Verificati pulsanti anche dopo resize a 1280×720; screenshot esaminati a 1080 e 720.
- Test dell'esperimento L'arte del rischio ancora passanti; file originali del motore e del prototipo precedente non modificati.

`preview-physical.png` mostra un risultato fisico reale. Le altre anteprime provano l'interfaccia con stati controllati: le etichette delle facce possono non corrispondere alla posa fisica precedente perché il test immette callback deterministiche. Non sono campioni statistici del motore.

Riproduzione:

```powershell
rtk proxy python scripts/test_luajit.py experiments/folio_roguelite/test.lua experiments/folio_roguelite/analyse.lua
rtk proxy python experiments/folio_roguelite/analyse_bank.py
rtk proxy python scripts/run_folio.py --smoke
```

Non sono state avviate simulazioni massive o modificati i salvataggi delle altre modalità. Il pacchetto usa l'identità LÖVE `scriptorium-folio-roguelite`; non salva una partita da riprendere. Registra soltanto `runs.csv` nella directory dati di questa identità (normalmente `%APPDATA%/LOVE/scriptorium-folio-roguelite`), distinguendo ogni nuova prova. Lo smoke usa la stessa directory e le sue prove vanno escluse dalla lettura delle sessioni manuali.

## Come valutare manualmente la struttura

Giocare prima senza cercare di massimizzare una formula; prima di un rilancio dichiarare che cosa si può perdere e perché si preferisce continuare. Completare almeno una prova con ciascuna tecnica, ricominciando con R. Alternare l'ordine fra giocatori; non confrontare solo percentuali di vittoria, perché i lanci saranno diversi.

Annotare:

1. Dopo una decorazione completata, si desidera davvero proseguire oppure si fissa sempre? Che cosa cambia con molte caselle libere rispetto all'ultimo pigmento mancante?
2. Il giocatore sa distinguere fissato e umido e spiegare quanto perderà? Fissa anche parti incomplete per conservare la sessione riuscita?
3. Con un pigmento condiviso sceglie consapevolmente la destinazione? Le regole attuali rendono equivalente la destinazione per completare l'intero folio: non confondere una preferenza figurativa con un vantaggio strategico.
4. Fissativo cambia una decisione oppure diventa solo un pulsante automatico? Modello ha un valore percepito sulla composizione pur essendo neutro sulle probabilità?

`runs.csv` registra lanci, applicazioni, fissaggi, fallimenti, protezioni e trasferimenti con folio, sessione, lavoro fissato/umido, riserva e colori ancora necessari. Non misura desiderio o divertimento: servono osservazione e una domanda al giocatore dopo la prova. Il log non contiene dati personali.

**Criterio per proseguire:** decisioni diverse fra stati, motivate e comprese; desiderio di un altro tentativo; Fissativo che cambia almeno alcune scelte senza annullare la tensione. **Motivi per rivedere:** fissare/rilanciare sempre in modo automatico, progressione percepita soltanto come facilitazione, o decorazioni che rimangono tre etichette per lo stesso contatore. La slice permette di verificare questi limiti; non prova già che la struttura debba diventare il nucleo definitivo.
