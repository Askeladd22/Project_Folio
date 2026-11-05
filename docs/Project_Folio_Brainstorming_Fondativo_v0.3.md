# Project Folio — Documento fondativo di brainstorming

**Versione:** 0.3 — 4 novembre 2026  
**Natura:** documento di visione e game design in evoluzione  
**Stato:** brainstorming; non costituisce una specifica di implementazione
**Principi di design approvati:** Simplicity · World Structure · Swelling Power
**Vincolo trasversale approvato:** la crescita di abilità deve appartenere al giocatore, non a una difficoltà che si adegua segretamente a lui

> **Di giorno imprime le immagini. Di notte, le immagini lo sfidano a dadi.**

## 1. Premessa

**Project Folio** (titolo provvisorio) è un videogioco di dadi con struttura roguelite ambientato nella **Venezia tra la fine del XV e l'inizio del XVI secolo**. Il protagonista è un artigiano che lavora alle edizioni della tipografia di **Aldo Manuzio**, occupandosi di immagini e matrici. Di giorno lavora nella bottega; la sera gioca alla **zara** in taverna; durante il sonno incontra e sfida ai dadi le figure delle xilografie a cui ha lavorato.

Il gioco nasce dall'incontro di tre mondi: la cultura materiale del libro rinascimentale, il piacere del gioco d'azzardo e la libertà dell'immaginazione onirica. **Non è una storia di espiazione, né un horror.** Il protagonista gioca anzitutto perché gli piace giocare.

## 2. Decisioni consolidate

| Ambito | Decisione |
|---|---|
| Luogo e periodo | Venezia, fine Quattrocento / inizio Cinquecento |
| Contesto | Tipografia di Aldo Manuzio; lavoro alle edizioni aldine |
| Protagonista | Artigiano incisore/illustratore, con ruolo storico da precisare; **muto**, senza dialoghi o pensieri imposti al giocatore |
| Incipit | Di giorno il lavoro, la sera la zara in taverna, di notte il sogno dei dadi e delle xilografie animate |
| Motivazione | Il piacere del gioco, non una missione salvifica o una punizione |
| Tono | Onirico, meraviglioso, colto, conviviale, talvolta bizzarro e ironico; **niente horror** |
| Nucleo ludico del giocatore | **Farkle con sei D6**, decisioni di accantonamento, rilancio, incasso e rischio di Farkle |
| Figure del sogno | Personaggi nati dalle immagini stampate, avversari di gioco con personalità; non mostri da uccidere |
| Tensione | Deve provenire dal rischio dei dadi e dalle scommesse, non da paura o minacce apocalittiche |
| Principi vincolanti di design | **Simplicity, World Structure, Swelling Power** |
| Principio di padronanza | **Il giocatore deve percepire che migliora la propria skill; il gioco non deve adattarsi segretamente alle sue prestazioni** |

**Precisazione:** il Farkle è il nucleo meccanico contemporaneo scelto per il videogioco; non stiamo sostenendo che fosse il gioco praticato nella tipografia aldina. La **zara** appartiene invece all'incipit storico della taverna.

## 3. Tre principi cardine di game design — approvati

**Simplicity, World Structure, Swelling Power** sono i tre filtri obbligatori per ogni futura scelta di design. Devono aiutare il giocatore a trovare **significato, orientamento e speranza** in run che possono essere difficili e punitive. La difficoltà non deve mai risultare opaca o gratuita.

### 3.1 Simplicity — un nucleo comprensibile che consenta profondità

Il nucleo resta **sei D6, Farkle, accantonamento, rischio di Farkle, incasso**. Un principiante deve poter iniziare senza conoscere le regole storiche della Zara, dell'Azar o di altri giochi. Le particolarità degli avversari vanno introdotte una alla volta e devono cambiare le scelte del giocatore senza richiedere una seconda enciclopedia di regole.

- **Vincolo:** nessuna nuova meccanica entra nel prototipo se non può essere spiegata chiaramente e mostrata nel feedback di gioco.
- **Segnale di successo:** chi gioca sa dire *che cosa può fare, che cosa rischia e perché un risultato è avvenuto*.
- **Antipattern:** sommare tabelle, punti vita, magie, eccezioni e categorie di punteggio perché sembrano singolarmente interessanti.

**Nota:** semplicità non significa assenza di profondità; significa che la profondità nasce dall'interazione di regole leggibili.

### 3.2 World Structure — un percorso leggibile e ricco di significato

Il giocatore deve comprendere **dove si trova nella run, cosa ha già conquistato, cosa può scegliere e quale obiettivo lo attende**. L'universo del libro, delle xilografie e della bottega onirica offre un linguaggio naturale per tappe e progressione, ma **non abbiamo ancora approvato** una struttura a pagine, capitoli, notti o mappe ramificate.

- **Vincolo:** la casualità deve generare percorsi con identità e scelte, non sequenze indistinte di partite.
- **Segnale di successo:** anche una run persa lascia un traguardo riconoscibile e un'idea concreta per il tentativo successivo.
- **Antipattern:** incontri casuali senza ritmo, obiettivi visibili o differenze fra le fasi della partita.

**Nota:** la struttura del mondo è anzitutto ludica, non soltanto narrativa o scenografica.

### 3.3 Swelling Power — una crescita percepibile durante ogni run

La run deve evolvere da un Farkle essenziale verso **possibilità sempre più potenti e combinazioni memorabili**, acquisite attraverso scelte significative. Il giocatore deve poter sperimentare momenti in cui la propria strategia sembra eccezionalmente efficace. Questa forza appartiene soprattutto alla run e non deve dipendere da una progressione permanente obbligatoria.

- **Vincolo:** i potenziamenti devono influire sulle decisioni, sul rischio, sulle opportunità o sulle sinergie; non soltanto aumentare un numero.
- **Segnale di successo:** nella seconda parte della run il giocatore può descrivere una strategia diversa da quella iniziale e ricordare almeno un momento di particolare potenza.
- **Antipattern:** incremento lineare dei punteggi, combinazioni sempre identiche, bonus automatici senza scelte, o crescita che rende qualsiasi rischio irrilevante.

**Nota:** la progressione deve essere crescente **senza cancellare la suspense del Farkle**. Il giocatore può diventare molto forte e restare esposto a decisioni difficili.

### 3.4 Procedura di valutazione delle nuove idee

Ogni proposta (scommessa, nemico, regola storica, ricompensa, UI o progressione) dovrà rispondere a tre domande:

1. **Simplicity:** introduce una decisione comprensibile, oppure soltanto complessità?
2. **World Structure:** rende il percorso e il prossimo obiettivo più chiari e significativi?
3. **Swelling Power:** consente al giocatore di costruire capacità e strategie più interessanti nel corso della run?

Una proposta può servire soprattutto uno dei tre pilastri, ma **non deve compromettere gli altri due**. Se non supera la verifica, va semplificata, testata come esperimento separato o scartata.

**Riferimento concettuale:** analisi dei tre pilastri del roguelike attribuita a Blurbs, sintetizzata in *How to Make a Roguelike (The 3 Pillars of Design)*, https://game-designers.net/how-to-make-a-roguelike/ . La loro adozione in Project Folio è una decisione progettuale di questo brainstorming.

### 3.5 Mastery, not accommodation — vincolo trasversale approvato

**Il giocatore deve diventare più bravo a giocare; non è il gioco a dover diventare artificialmente più facile per lui.** Questo non sostituisce i tre pilastri: specifica *come* devono essere realizzati, in particolare *Swelling Power*.

**Tre livelli distinti:**

1. **Abilità del giocatore (persistente):** conoscenza delle probabilità, riconoscimento del rischio con dadi disponibili, gestione del banking, lettura delle intenzioni del rivale, valutazione delle poste, costruzione delle sinergie. È la vera progressione fra run.
2. **Potenza della build (temporanea):** strumenti, dadi e possibilità ottenuti nella run. Devono espandere le scelte; il giocatore esperto li sfrutta meglio di uno inesperto. Potenza non equivale a vittoria automatica.
3. **Difficoltà e regole (coerenti):** le probabilità, le condizioni di vittoria e le regole note di un encounter devono restare stabili e spiegabili. Varianti e livelli di difficoltà dichiarati possono esistere, ma non una compensazione nascosta delle prestazioni.

**Da evitare:**

- *Dynamic difficulty adjustment* nascosto, rubber-banding, percentuali dei dadi alterate in base a vittorie/sconfitte, avversari che giocano peggio per far vincere chi perde.
- Potenziamenti permanenti puramente numerici indispensabili per superare contenuti, che rendano indistinguibile la bravura del giocatore dalla crescita statistica.
- Punizioni inspiegabili, probabilità opache e modificatori che cancellino sistematicamente il peso delle decisioni.
- Confondere la sensazione di imparare con la richiesta di memorizzare eccezioni: la competenza deve emergere da scelte significative e da informazioni leggibili.

**Da privilegiare:**

- Esiti casuali autentici e regole dichiarate; la bravura aumenta le probabilità di successo **su molte partite**, senza garantire la vittoria di ogni singola run.
- Informazioni utilizzabili per decidere: dadi ancora lanciabili, punti a rischio, regole e posta dell'avversario, conseguenze prevedibili di incasso e rilancio.
- Avversari che insegnano indirettamente nuove competenze, senza richiedere tutorial interminabili; possibilità di riconoscere a posteriori un errore o una scelta corretta.
- Potenziamenti con tempismo e costo opportunità: il medesimo strumento deve risultare più efficace in mani esperte.
- Ripetibilità verificabile: a parità di condizioni e di casualità, la bontà delle decisioni deve incidere sul risultato; in simulazione, strategie informate devono prevalere nel lungo periodo su strategie casuali o ingenue.

**Test di progettazione:**

1. Una persona esperta, con gli stessi dadi e la stessa build di una principiante, può ottenere risultati migliori nel lungo periodo grazie alle proprie decisioni?
2. Una sconfitta permette di distinguere la sfortuna da una scelta migliorabile?
3. Un potenziamento amplia le opzioni strategiche oppure aumenta soltanto un numero?
4. Le probabilità e le regole restano eque e leggibili, anche dopo una serie di sconfitte?

**Formula interna:** *«È migliorato chi lancia i dadi, non il dado che lancia.»*

---

## 4. Il sogno e la sua logica

**Principio narrativo:** durante il sonno, gli oggetti e le immagini familiari della bottega e della taverna acquistano una vita ludica impossibile. Le xilografie escono dalla carta, parlano, scherzano e propongono partite. Il protagonista non deve necessariamente combatterle: può **giocare contro di loro** e, vincendo, contribuire alla composizione del libro.

Un'immagine possibile — **non ancora definitiva** — è una bottega trasformata in taverna impossibile: torchi che lavorano da soli, margini di pagina che diventano architetture, xilografie che si siedono al tavolo da gioco. Il luogo resta riconoscibile, ma cambia in base al libro e ai personaggi incontrati.

**Rimangono aperte:** la geografia precisa del sogno; quanto il sogno sia letteralmente “dentro” il libro; se le figure di libri diversi condividano un luogo comune; se il mondo onirico abbia una spiegazione esplicita. Non è necessario introdurre una maledizione, un'entità antagonista o una grande catastrofe.

### Riferimento storico-visivo prioritario

L'**Hypnerotomachia Poliphili**, stampata a Venezia da Aldo Manuzio nel **1499**, è un riferimento particolarmente pertinente per la combinazione di sogno, architetture allegoriche e immagini xilografiche. È una **fonte d'ispirazione**, non una trama da copiare né la prova che ogni edizione aldina avesse la stessa ricchezza illustrativa.

## 5. Il protagonista e il punto di vista

Il protagonista è un **avatar del giocatore**, non un personaggio che parla al suo posto. Non necessita di un nome obbligatorio né di una biografia psicologica rigidamente prescritta. Le sue decisioni ludiche — prudenza, audacia, ostinazione, capacità di fermarsi — emergono dall'azione.

**Possibilità visiva da valutare:** mostrare soprattutto le mani, che di giorno incidono o compongono e di sera/notte afferrano e lanciano i dadi. Gli avversari possono rivolgersi direttamente al giocatore; il protagonista risponde con le proprie azioni.

**Questione di accuratezza storica aperta:** precisare se definirlo incisore xilografico, disegnatore di immagini, illustratore o artigiano con mansioni multiple. “Miniatore” e “incisore” non sono termini automaticamente intercambiabili nella produzione tipografica.

## 6. Le figure: rivali, non nemici da eliminare

Le figure possono provenire da xilografie, allegorie, emblemi, capilettera, racconti classici, favole e altre immagini dei libri. Nel sogno hanno desideri e stili di gioco differenti.

**Archetipi puramente esplorativi:**

- **La Fortuna:** provocatoria, imprevedibile, amante delle poste audaci.
- **Il Mercante:** calcolatore, attento alle quote e all'opportunità di ritirarsi.
- **Il Satiro:** spaccone, divertito dai rilanci e dalle sfide assurde.
- **Il Re o l'imperatore:** orgoglioso, sensibile alle sconfitte pubbliche.
- **Il Filosofo:** argomentativo, ossessionato da ordine e probabilità.

Questi non sono personaggi approvati né un roster definitivo. Sono esempi di come **il carattere debba emergere anche dal comportamento al tavolo**, non soltanto dai dialoghi.

Il successo di una partita può riportare la figura alla sua pagina e arricchire visivamente il volume. La sconfitta può significare una posta persa e una rivincita futura, senza morte, danno fisico o condanna morale.

## 7. Il Farkle rimane il centro del gioco

Per il giocatore conserviamo i **sei dadi D6**, con scelte di accantonamento delle combinazioni valide, rilanci, incasso dei punti e rischio di perdere il bottino non ancora assicurato quando si verifica un **Farkle**.

**Principio di design:** un avversario è riuscito solo se cambia realmente la decisione del giocatore su **quando incassare, quando rilanciare e quanto rischiare**. Il giocatore deve poter imparare a prendere tali decisioni meglio, senza ricevere correzioni nascoste delle probabilità. Aggiungere risultati casuali o danni numerici non basta.

La presenza di sistemi di scommesse non deve eliminare il ruolo centrale dei dadi né trasformare il gioco in un simulatore di negoziazione. Il piacere fisico e la suspense del lancio restano prioritari.

## 8. Encounter e asimmetria: direzione promettente, non risolta

**Orientamento condiviso:** gli avversari potrebbero avere **un proprio set di dadi**, indipendente dai sei D6 del giocatore. È preferibile all'idea di far loro leggere soltanto i dadi del protagonista. La quantità e il tipo di dadi possono variare fra gli avversari.

**Non è ancora deciso** come debbano funzionare i loro turni, né come confrontare risultati ottenuti con regole diverse. L'esempio “sei D6 Farkle contro tre D6 Azar” è una **ipotesi di prototipo**, non un sistema di combattimento approvato.

Abbiamo individuato un rischio fondamentale: **due giochi separati non costituiscono automaticamente un incontro interessante**. Se il giocatore lancia Farkle e il rivale lancia Azar senza incidere sulle rispettive scelte, l'encounter resta una successione di eventi casuali.

La soluzione va cercata in una **competizione comprensibile per una posta condivisa**, con decisioni capaci di influenzarsi reciprocamente. Non basta convertire punti Farkle in danno o assegnare punti vita al boss.

## 9. La posta: importante quanto il punteggio

La scommessa deve avere **un peso consistente**, quasi paragonabile a quello del Farkle, ma conservare una gestione semplice e leggibile.

Distinguiamo due livelli:

1. **Rischio del lancio:** il piatto Farkle del turno può aumentare oppure andare perso prima dell'incasso.
2. **Rischio dell'incontro:** i contendenti mettono in palio qualcosa che conta nella run e possono eventualmente accettare, rilanciare la posta o rinunciare, secondo regole ancora da progettare.

**Possibili rappresentazioni della posta, non ancora approvate:** monete, gettoni d'impressione, fogli di prova, caratteri/matrici, oppure diritti simbolici di imprimere una figura sul folio. La ricompensa narrativa può essere la xilografia che torna alla pagina; la posta economica o ludica deve avere conseguenze concrete, altrimenti la scommessa è puramente decorativa.

**Problema aperto centrale:** quale meccanismo condiviso permette a un Farkle del giocatore e a un gioco di dadi differente del rivale di contendersi la stessa posta? Non abbiamo ancora una risposta soddisfacente.

## 10. Giochi storici e tradizionali studiati

Abbiamo esplorato giochi da cui **attingere principi**, non regolamenti da accumulare senza criterio:

| Riferimento | Possibile insegnamento | Stato |
|---|---|---|
| **Zara italiana** | Dichiarare una somma e scommettere su un risultato | Riferimento per la taverna; possibile meccanica |
| **Azar del *Libro de los juegos* (1283)** | Azar/Reazar, due sorti rivali, confronto fra risultati su lanci successivi | Candidato a prototipo asimmetrico |
| **Hazard** | Main/Chance, risoluzione persistente fra due numeri | Da valutare, complesso da sovrapporre al Farkle |
| **Pietjesbak** | Spavalderia, fermarsi presto, poste rafforzate e limite ai lanci del rivale | Promettente per il comportamento dei giocatori |
| **Kassie-zes / Ship, Captain and Crew** | Obiettivi numerici da ottenere in sequenza | Rischio di diventare automatico con sei dadi |
| **Shut the Box** | Scelte di chiusura con conseguenze sui risultati futuri | Promettente per il folio, ma richiede un costo reale |
| **Glückshaus** | Poste e risorse che rimangono visibili sul tabellone | Spunto per risorse contese; attenzione alla datazione del regolamento moderno |
| **Astronomical Chess** | Dadi che modificano relazioni su uno spazio simbolico | Spunto visivo e sistemico per incontri speciali |
| **Sic Bo, Bo Bing, Liar's Dice, altri** | Quote, premi, bluff, informazione nascosta e rarità | Serbatoio d'idee, non priorità |
| **Yahtzee/Yacht e derivati** | Schede di punteggio e combinazioni | Evitare di replicare il modello di Deviled Dice |

**Avvertenza storica:** questi giochi provengono da luoghi ed epoche differenti. L'Azar alfonsino appartiene alla Castiglia del XIII secolo, non automaticamente alla Venezia aldina; un riferimento meccanico non deve essere presentato come ricostruzione locale autentica.

## 11. Struttura delle run e dei libri: aperta

Sono state considerate **una notte = una run = un libro** e **un libro distribuito su più notti**. Entrambe possono funzionare; non abbiamo scelto.

Una possibilità intermedia è usare **la notte come unità ludica** e **il libro come unità narrativa**, con edizioni di durata differente, ma è soltanto un'ipotesi.

Non è nemmeno definito se i libri siano mondi completamente distinti o se i loro personaggi frequentino uno stesso grande tavolo onirico. Potrebbe esserci un luogo ricorrente che cambia aspetto in funzione dell'edizione affrontata.

Il giorno nella bottega e la sera in taverna servono, per ora, come **cornice narrativa**. Non è stato deciso di introdurre minigiochi di mestiere, routine obbligatorie o un simulatore gestionale di tipografia.

## 12. Identità estetica e tono

**Da perseguire:** Venezia aldina, materiali della stampa, carta, legno, matrici, inchiostro, xilografie bidimensionali che si animano; atmosfere oniriche teatrali e ricche di carattere, con convivialità e ironia.

**Da evitare:** horror, demoni come antagonisti obbligatori, maledizioni, salvezza dell'anima, generico fantasy medievale, casino contemporaneo travestito, effetti magici vistosi senza rapporto con la stampa, copie del linguaggio visivo o delle meccaniche di Balatro/Deviled Dice.

Il sogno può essere assurdo, imprevedibile e competitivo **senza diventare angosciante**.

## 13. Cosa ancora non sappiamo

1. **Qual è la condizione esatta di vittoria di un encounter?**
2. **Che cosa si scommette in termini meccanici?** Come si ottiene, perde e spende la posta?
3. **Quali scelte strategiche compie il rivale?** Come rende visibile la propria intenzione?
4. **Come interagiscono due giochi differenti?** Evitare giochi paralleli o penalità arbitrarie.
5. **Come si conclude una notte, una run e un libro?** Che cosa permane dopo la sconfitta?
6. **Qual è la prima tipologia di libro?** Quanto può variare l'identità dei personaggi?
7. **Quale ruolo artigianale del protagonista è storicamente più preciso?**
8. **Come si presenta il sogno nello spazio di gioco?** Tavolo condiviso, bottega trasfigurata, ambienti distinti?

## 14. Prossima attività consigliata

**Non aggiungere subito codice, boss o ulteriori sistemi di dadi.** Progettare su carta **un solo incontro astratto**, senza grafica, con un protagonista Farkle a sei D6 e un rivale con una propria logica di gioco.

La scheda dell'esperimento dovrà rispondere a queste domande:

- **Posta iniziale:** cosa rischia ciascun giocatore?
- **Vittoria e sconfitta:** quali eventi concludono la partita?
- **Turno:** chi sceglie cosa, in quale ordine e con quali informazioni?
- **Interazione:** quale mossa del giocatore costringe il rivale a rivedere la propria strategia, e viceversa?
- **Farkle:** come rimangono centrali accantonamento, rilancio e incasso?
- **Equilibrio:** esiste una strategia dominante? Come cambia fra prudenza e aggressività?

**Criteri di successo:** se rimuovendo il rivale il giocatore prenderebbe le stesse identiche decisioni, l'encounter non funziona. Se un giocatore esperto non può migliorare i risultati attraverso decisioni più consapevoli, l'encounter non soddisfa il principio di padronanza.

---

## Sintesi in una frase

**Un incisore silenzioso della Venezia di Aldo Manuzio, appassionato di zara, sogna ogni notte una bottega impossibile in cui le xilografie dei libri diventano eccentrici compagni di gioco: fra dadi, scommesse e rivalità, gioca per il puro piacere di giocare.**

*W la ludo.*
