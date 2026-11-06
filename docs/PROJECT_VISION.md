# Project Folio — visione e brainstorming unificati

**Stato:** principi approvati il 4 novembre 2026, integrati il 6 novembre. Le ipotesi restano ipotesi, non istruzioni di implementazione.
**Non è una descrizione delle feature implementate.**
Per la build corrente consultare [README](../README.md),
[regole Farkle](FARKLE_RULES.md), sorgenti e test.

## Ambientazione e incipit — confermati

- **Luogo ed epoca:** Venezia, fine XV / inizio XVI secolo.
- **Lavoro del protagonista:** artista originale rinascimentale,
  disegnatore e incisore **ispirato al profilo di Albrecht Dürer**,
  attivo nell'ambiente delle edizioni di **Aldo Manuzio**. La
  collaborazione è una scelta narrativa, non una biografia storica
  né una rappresentazione di Dürer stesso.
- **Giorno:** lavora alle edizioni aldine.
- **Sera:** si diverte a giocare alla **zara** in taverna.
- **Notte:** sogna un mondo onirico in cui le xilografie prendono vita
  e lo sfidano ai dadi.
- **Protagonista:** muto e senza personalità imposta: è il giocatore.
  La sua bravura e il suo carattere emergono dalle scelte al tavolo.
- **Motivazione:** gioca **per puro piacere**.
- **Tono:** meraviglioso, ironico, conviviale, stravagante.
  **Niente horror, maledizioni o missione di espiazione.**

La bottega può trasformarsi nel sogno e incorporare la taverna e le
immagini dei libri; non è ancora deciso se esistano mondi-libro
separati, un tavolo comune o una struttura ibrida.
L'`Hypnerotomachia Poliphili` (1499) è un riferimento storico
pertinente alla produzione di Manuzio, **non** una trama da copiare.

## Tre pilastri di design — vincolanti

1. **Simplicity.** Le decisioni essenziali devono essere comprensibili
   senza strati inutili di sottosistemi. La profondità nasce dalle
   conseguenze delle scelte, non dal numero di regole da ricordare.
2. **World structure.** Ogni run deve avere una struttura leggibile:
   percorso, opportunità, progressi e obiettivo. Non una successione
   indistinta di lanci.
3. **Swelling power.** Il potere cresce **all'interno della run**,
   aprendo nuove possibilità e sinergie. Non equivale soltanto
   a moltiplicare numeri.

**Vincolo trasversale: mastery, not accommodation.** A parità di
regole e condizioni, l'abilità accumulata dal giocatore deve
migliorare i risultati sul lungo periodo. Nessun favore occulto
dell'RNG, difficoltà adattiva punitiva o compensazione segreta.
La crescita delle build deve premiare la competenza, non sostituirla.

## Nucleo gameplay — implementato, da preservare

Il protagonista lancia **sei D6 fisici**, conserva combinazioni valide,
sceglie se incassare o rilanciare e rischia di perdere il bottino del
turno con un Farkle. Rendering unico **g3d**; nessun ripristino
di painter/fallback legacy.

La partita attuale usa commissioni sul Tavolo del Mercante.
Il bilanciamento di obiettivi e progressione è ancora provvisorio.

## Incontri e poste — principi forti, regolamento ancora aperto

Le figure dei libri sono **giocatori rivali**, non mostri da
uccidere. Possono scherzare, bluffare, rischiare e
reclamare la rivincita. La scommessa deve essere importante:
distinguere il **rischio del rilancio Farkle** da ciò che si mette
in palio **contro l'altro giocatore**.

È promettente che i rivali abbiano **set di dadi propri** e regole
asimmetriche, ma non è stata approvata una formula per
confrontare giochi differenti o risolvere una partita.
Non trasformare automaticamente punti Farkle in punti vita.
Nessun boss Azar, Hazard, Pietjesbak o Shut the Box è ancora
una feature canonica.

Le ricerche su giochi storici e tradizionali servono a trovare
**decisioni strategiche reali**, non a collezionare minigiochi.
La premessa narrativa non conferma automaticamente la storicità
delle singole regole nella Venezia del 1500.

## Questioni deliberatamente aperte

- Qual è la **posta concreta** e come si conquista/perde?
  Gettoni d'impressione, fogli di prova e diritti simbolici di stampa
  sono esempi, non una decisione presa.
- Come interagiscono **due set di dadi e regole differenti** senza
  diventare due giochi paralleli?
- Qual è la condizione di vittoria di un incontro, in assenza di
  combattimento mortale o traduzione in danni?
- Una notte è una run? Un libro richiede più notti? Esistono volumi
  brevi e lunghi?
- Come si esprime *swelling power* mantenendo valutazione del rischio
  e maestria personale centrali?

**Prossimo gate:** prototipo astratto di un solo incontro, separato
dal gameplay, con posta e decisioni verificabili; valutare almeno
strategie prudenti e aggressive prima di lavorare su UI e arte.

> Di giorno imprime le immagini. Di notte, le immagini lo sfidano a dadi.
>
> **W la ludo.**

## Ruolo attuale del Folio

Il Folio non è stato eliminato: dalla v0.1.14 non occupa la sidebar
permanente del tavolo, ma resta consultabile con **F**. Il tavolo
g3d del Mercante è la scena giocabile. Il vecchio obiettivo di
**colorare progressivamente una pagina fino alla vittoria** è
abbandonato come loop principale: rimane invece da progettare la
ricomposizione delle xilografie nel libro dopo gli incontri.

Il Mercante è per ora una figura illustrata modulare, **non**
un avversario competitivo già completo. La modalità Monaco beta è
stata rimossa nella v0.1.16.

**Identità del protagonista aggiornata:** disegnatore e incisore
rinascimentale originale, ispirato ad **Albrecht Dürer**. Non è
Dürer stesso e non ne riproduce la biografia. Rimane muto e
le scelte del giocatore ne definiscono il carattere.

## Approfondimenti dal brainstorming fondativo v0.3

Sono conservati i dettagli non ridondanti sulle scelte, sui
giochi tradizionali studiati e sulle domande di design ancora
aperte. La fonte integrale del 4 novembre è
[disponibile nella cronologia Git](https://github.com/Askeladd22/Project_Folio/blob/629573929604a096d32236a151c44124ce94e02a/docs/Project_Folio_Brainstorming_Fondativo_v0.3.md):
non è un secondo documento concorrente. I termini del testo
storico non prevalgono sulle decisioni successive qui sopra.

#### 3.4 Procedura di valutazione delle nuove idee

Ogni proposta (scommessa, nemico, regola storica, ricompensa, UI o progressione) dovrà rispondere a tre domande:

1. **Simplicity:** introduce una decisione comprensibile, oppure soltanto complessità?
2. **World Structure:** rende il percorso e il prossimo obiettivo più chiari e significativi?
3. **Swelling Power:** consente al giocatore di costruire capacità e strategie più interessanti nel corso della run?

Una proposta può servire soprattutto uno dei tre pilastri, ma **non deve compromettere gli altri due**. Se non supera la verifica, va semplificata, testata come esperimento separato o scartata.

**Riferimento concettuale:** analisi dei tre pilastri del roguelike attribuita a Blurbs, sintetizzata in *How to Make a Roguelike (The 3 Pillars of Design)*, https://game-designers.net/how-to-make-a-roguelike/ . La loro adozione in Project Folio è una decisione progettuale di questo brainstorming.

#### 3.5 Mastery, not accommodation — vincolo trasversale approvato

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

### 4. Il sogno e la sua logica

**Principio narrativo:** durante il sonno, gli oggetti e le immagini familiari della bottega e della taverna acquistano una vita ludica impossibile. Le xilografie escono dalla carta, parlano, scherzano e propongono partite. Il protagonista non deve necessariamente combatterle: può **giocare contro di loro** e, vincendo, contribuire alla composizione del libro.

Un'immagine possibile — **non ancora definitiva** — è una bottega trasformata in taverna impossibile: torchi che lavorano da soli, margini di pagina che diventano architetture, xilografie che si siedono al tavolo da gioco. Il luogo resta riconoscibile, ma cambia in base al libro e ai personaggi incontrati.

**Rimangono aperte:** la geografia precisa del sogno; quanto il sogno sia letteralmente “dentro” il libro; se le figure di libri diversi condividano un luogo comune; se il mondo onirico abbia una spiegazione esplicita. Non è necessario introdurre una maledizione, un'entità antagonista o una grande catastrofe.

#### Riferimento storico-visivo prioritario

L'**Hypnerotomachia Poliphili**, stampata a Venezia da Aldo Manuzio nel **1499**, è un riferimento particolarmente pertinente per la combinazione di sogno, architetture allegoriche e immagini xilografiche. È una **fonte d'ispirazione**, non una trama da copiare né la prova che ogni edizione aldina avesse la stessa ricchezza illustrativa.

### 6. Le figure: rivali, non nemici da eliminare

Le figure possono provenire da xilografie, allegorie, emblemi, capilettera, racconti classici, favole e altre immagini dei libri. Nel sogno hanno desideri e stili di gioco differenti.

**Archetipi puramente esplorativi:**

- **La Fortuna:** provocatoria, imprevedibile, amante delle poste audaci.
- **Il Mercante:** calcolatore, attento alle quote e all'opportunità di ritirarsi.
- **Il Satiro:** spaccone, divertito dai rilanci e dalle sfide assurde.
- **Il Re o l'imperatore:** orgoglioso, sensibile alle sconfitte pubbliche.
- **Il Filosofo:** argomentativo, ossessionato da ordine e probabilità.

Questi non sono personaggi approvati né un roster definitivo. Sono esempi di come **il carattere debba emergere anche dal comportamento al tavolo**, non soltanto dai dialoghi.

Il successo di una partita può riportare la figura alla sua pagina e arricchire visivamente il volume. La sconfitta può significare una posta persa e una rivincita futura, senza morte, danno fisico o condanna morale.

### 8. Encounter e asimmetria: direzione promettente, non risolta

**Orientamento condiviso:** gli avversari potrebbero avere **un proprio set di dadi**, indipendente dai sei D6 del giocatore. È preferibile all'idea di far loro leggere soltanto i dadi del protagonista. La quantità e il tipo di dadi possono variare fra gli avversari.

**Non è ancora deciso** come debbano funzionare i loro turni, né come confrontare risultati ottenuti con regole diverse. L'esempio “sei D6 Farkle contro tre D6 Azar” è una **ipotesi di prototipo**, non un sistema di combattimento approvato.

Abbiamo individuato un rischio fondamentale: **due giochi separati non costituiscono automaticamente un incontro interessante**. Se il giocatore lancia Farkle e il rivale lancia Azar senza incidere sulle rispettive scelte, l'encounter resta una successione di eventi casuali.

La soluzione va cercata in una **competizione comprensibile per una posta condivisa**, con decisioni capaci di influenzarsi reciprocamente. Non basta convertire punti Farkle in danno o assegnare punti vita al boss.

### 9. La posta: importante quanto il punteggio

La scommessa deve avere **un peso consistente**, quasi paragonabile a quello del Farkle, ma conservare una gestione semplice e leggibile.

Distinguiamo due livelli:

1. **Rischio del lancio:** il piatto Farkle del turno può aumentare oppure andare perso prima dell'incasso.
2. **Rischio dell'incontro:** i contendenti mettono in palio qualcosa che conta nella run e possono eventualmente accettare, rilanciare la posta o rinunciare, secondo regole ancora da progettare.

**Possibili rappresentazioni della posta, non ancora approvate:** monete, gettoni d'impressione, fogli di prova, caratteri/matrici, oppure diritti simbolici di imprimere una figura sul folio. La ricompensa narrativa può essere la xilografia che torna alla pagina; la posta economica o ludica deve avere conseguenze concrete, altrimenti la scommessa è puramente decorativa.

**Problema aperto centrale:** quale meccanismo condiviso permette a un Farkle del giocatore e a un gioco di dadi differente del rivale di contendersi la stessa posta? Non abbiamo ancora una risposta soddisfacente.

### 10. Giochi storici e tradizionali studiati

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

### 11. Struttura delle run e dei libri: aperta

Sono state considerate **una notte = una run = un libro** e **un libro distribuito su più notti**. Entrambe possono funzionare; non abbiamo scelto.

Una possibilità intermedia è usare **la notte come unità ludica** e **il libro come unità narrativa**, con edizioni di durata differente, ma è soltanto un'ipotesi.

Non è nemmeno definito se i libri siano mondi completamente distinti o se i loro personaggi frequentino uno stesso grande tavolo onirico. Potrebbe esserci un luogo ricorrente che cambia aspetto in funzione dell'edizione affrontata.

Il giorno nella bottega e la sera in taverna servono, per ora, come **cornice narrativa**. Non è stato deciso di introdurre minigiochi di mestiere, routine obbligatorie o un simulatore gestionale di tipografia.

### 13. Cosa ancora non sappiamo

1. **Qual è la condizione esatta di vittoria di un encounter?**
2. **Che cosa si scommette in termini meccanici?** Come si ottiene, perde e spende la posta?
3. **Quali scelte strategiche compie il rivale?** Come rende visibile la propria intenzione?
4. **Come interagiscono due giochi differenti?** Evitare giochi paralleli o penalità arbitrarie.
5. **Come si conclude una notte, una run e un libro?** Che cosa permane dopo la sconfitta?
6. **Qual è la prima tipologia di libro?** Quanto può variare l'identità dei personaggi?
7. **Quale ruolo artigianale del protagonista è storicamente più preciso?**
8. **Come si presenta il sogno nello spazio di gioco?** Tavolo condiviso, bottega trasfigurata, ambienti distinti?

### 14. Prossima attività consigliata

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
