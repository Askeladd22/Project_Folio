# Project Folio — Fantasy del giocatore

**Stato:** fantasy primaria **approvata** dal giocatore il 20 novembre 2026; derivazioni di gameplay **da validare**.  
**Baseline verificata:** `main@ded8bdc06f26510f54321a677ba86f9227a2cfee`.  
**Autorità:** [visione canonica](project_vision.md) → [regole Farkle](farkle_rules.md) → [RQ-002](../research/RQ-002_FANTASY_FIRST_UI.md) → codice per ciò che è implementato. Questo documento sintetizza la promessa esperienziale; **non sostituisce le regole**.

## 1. La promessa, prima delle meccaniche

> **Voglio essere un giocatore di dadi temerario.** Voglio prendere i dadi nelle mie mani, scuoterli, orientarli, lanciarli e convincermi di poter piegare la sorte. Ogni volta devo decidere se mettere in salvo ciò che ho conquistato o tentare ancora, sapendo che posso perdere il provvisorio.

«Ludopatico giocatore di dadi» è la formulazione volutamente iperbolica scelta per la *fantasy* del personaggio-giocatore, **non** una diagnosi o una proposta di scommesse con denaro reale. L'esperienza si fonda su tensione, destrezza, rischio e responsabilità della scelta; nessuna monetizzazione basata sul caso è implicata.

**Fantasy di potere:** diventare bravissimo nel mestiere più incerto del mondo: **lanciare dadi e leggere il rischio meglio degli altri**, senza avere garanzie di vittoria. Il giocatore deve percepire *il mio gesto*, *la mia decisione*, *la mia conseguenza*.

### Una frase per descrivere il gioco (copy provvisorio)

*In una Venezia rinascimentale sognata, le figure dei libri prendono vita per sfidarti ai dadi. Afferrali, scuotili e lanciali davvero; metti alla prova la tua mano e decidi quando rischiare tutto o incassare.*

La frase descrive la **visione**: gli avversari competitivi sono un obiettivo ancora aperto, non una feature già disponibile. Il suo valore commerciale su Steam non è stato misurato.

## 2. Chi sono e dove sono

- **Giorno:** un incisore originale ispirato al contesto di Dürer prepara immagini per le edizioni di Aldo Manuzio, a Venezia tra la fine del XV e l'inizio del XVI secolo. Non interpreta il Dürer storico.
- **Sera:** gioca alla zara per puro piacere; il rischio è una passione e una sfida.
- **Notte:** nel sogno le xilografie si staccano dalle pagine, scherzano, provocano e si siedono al tavolo. Non sono mostri da uccidere.
- **Protagonista:** muto, senza carattere prescritto; il giocatore racconta chi è attraverso le decisioni. **Tono:** meraviglioso, ironico, conviviale, non horror.

Il **tavolo** è l'oggetto centrale del mondo. La bottega, il sogno, i rivali e il futuro libro devono valorizzare le azioni sui dadi, non allontanare l'attenzione dal gesto.

## 3. Tre sensazioni da consegnare

| Sensazione desiderata | Azione che la esprime | Verità nella build / stato |
|---|---|---|
| **La sorte nelle mie mani** | Afferrare, scuotere, orientare, rilasciare D6 fisici | **Implementato:** corpi fisici e lettura delle facce. **Non misurato:** se una tecnica orienti gli esiti meglio del caso |
| **Rischio perché lo decido io** | Conservare una combinazione, incassare o rilanciare mettendo in gioco il provvisorio | **Implementato:** Farkle, hot dice, soglie e punti a rischio |
| **Voglio vincere il tavolo** | Leggere le intenzioni di un rivale, fargli accettare la sfida e vincere una posta comprensibile | **Progettuale:** il Rivale illustrato non è ancora un giocatore autonomo competitivo |

Il Farkle attuale è un **mezzo** per incarnare la fantasy. Non dobbiamo conservare o cambiare una regola solo perché ricorda giochi celebri: serve una decisione realmente interessante.

## 4. Il minuto di gioco ideale

1. **Osservo:** vedo quanti punti ho già assicurato, quanti sono ancora in gioco, quali dadi restano e quali sono le azioni lecite.
2. **Prendo:** seleziono uno o più dadi fisici; con il mouse li afferro, scuoto e rilascio sul tavolo.
3. **Attendo:** collisioni, rotazioni e lettura delle facce sono fisiche. Il risultato non viene scelto da un pulsante invisibile dell'HUD.
4. **Interpreto:** scelgo un sottoinsieme valido, senza che il gioco ottimizzi automaticamente per me.
5. **Sfido:** incasso il provvisorio se consentito, oppure rilancio accettando il rischio di Farkle.
6. **Imparo:** distinguo una buona decisione da un buon esito. La vittoria non deve sembrare un favore nascosto del sistema.

**Ritmo desiderato:** gesto tattile → sospensione → risultato leggibile → decisione informata → nuova tensione. Non esiste ancora una misura oggettiva della sua qualità.

## 5. Promesse e limiti non negoziabili

- **Simplicity:** sei D6, pochi gesti, poche decisioni ad alta conseguenza. Nessuna sidebar permanente, carta obbligatoria o sottosistema introdotto solo per «aggiungere profondità».
- **World Structure:** le run avranno progressione e incontri leggibili, non una sequenza indistinta di tiri. La struttura definitiva è aperta.
- **Swelling Power:** durante la run il giocatore può costruire nuove possibilità sui dadi; non soltanto moltiplicatori. Le modifiche già presenti (es. Inciso/Pesato) rimangono dichiarate e verificabili.
- **Mastery, not accommodation:** la competenza deve crescere nel giocatore. Niente RNG accomodante, rubber-banding nascosto, risultati fissati dall'HUD o compensazioni non dichiarate.
- **Niente HP canonici** e niente avversari decorativi spacciati per competitori completi. Il Opponent, se introdotto come rivale, deve poter **agire comprensibilmente e vincere**.
- **Fisica ≠ controllo assicurato:** tenere, muovere e scuotere i dadi influenza il moto simulato, ma non è dimostrato che permetta di ottenere facce prefissate. Non promettere ciò che non abbiamo misurato.

## 6. Come deve comportarsi l'interfaccia

**Principio UI:** *mostrare la posta e togliersi di mezzo*. Ogni elemento permanente deve servire il tiro o la decisione.

| Momento | Informazione essenziale | Indicazione visiva | Cosa evitare |
|---|---|---|---|
| Prima del tiro | Dadi disponibili, presa fisica e lancio rapido | Gesti del mouse riconoscibili, comandi brevi | Tutorial invasivo, HUD che copre il piano |
| Dado in mano | Numero di dadi, scuotimento **davvero** rilevato, possibilità di rilascio | Badge vicino alla mano, nei bordi schermo | Feedback fittizio su «lancio perfetto» |
| Dadi fermi | Facce leggibili e selezioni valide / parziali / non valide | Contorni sull'oggetto reale | Linee decorative scollegate dai dadi |
| Dopo una scelta | Punti al sicuro, punti a rischio, obiettivo | **Un'unica scorecard** e barra proporzionale `sicuri + provvisori` | Numeri ripetuti in cinque pannelli |
| Incassa / rilancia | Valore esatto e conseguenza del comando | Due azioni prominenti e contestuali | Raccomandazione automatica «scelta migliore» |
| Farkle | Perdita **solo** del provvisorio, separata dai punti già assicurati | Contrasto e testo chiaro, senza ambiguità | Animazione che suggerisce una regola diversa |

La barra introdotta nella proposta `v0.1.91` mostra esclusivamente **punti effettivamente incassati** e **provvisorio già accantonato** rispetto all'obiettivo. Un dado semplicemente selezionato non crea ancora provvisorio. I segmenti sono limitati all'obiettivo: i valori numerici nella scorecard rimangono autorevoli anche se il totale lo supera.

## 7. Le due ipotesi da falsificare prima di espandere le meccaniche

### EX-F01 — La tecnica di lancio è apprendibile?

**H0:** con condizioni equivalenti, la pratica del lancio manuale non produce un vantaggio riproducibile nella capacità di ottenere risultati scelti a priori, rispetto al controllo standardizzato.

**Pilota proposto:** 12 partecipanti, circa 40 lanci per condizione, ordine appaiato e bilanciato. Loggare input, stato iniziale, velocità e spin al rilascio, collisioni rilevanti, facce finali e scelte. Confrontare risultati su condizioni *non* usate in allenamento, con intervalli d'incertezza. Misurare separatamente sensazione di controllo e prestazione. Dimensioni e soglie **non sono esiti già raccolti**.

**STOP:** se emerge un gesto quasi immobile ripetibile che domina senza decisione, oppure se la skill fisica non è distinguibile dal rumore. In entrambi i casi correggere la *promessa* o prototipare una modifica fisica esplicita, non falsare i risultati.

### EX-F02 — Un rivale dà significato al rischio?

Confrontare una partita Farkle a commissione con un **duello Mirror Farkle** in `experiments/`: entrambi con sei dadi e una possibilità di incassare, rischio e condizioni di vittoria trasparenti.

Misurare comprensione delle azioni del rivale, differenza nelle strategie prudenti/aggressive, qualità percepita delle scelte e frequenze di vittoria di entrambi. Il rivale deve poter vincere per regole e decisioni, non solo tramite una simulazione scenica. **Non integrare in `src/` senza gate e approvazione.**

## 8. Decisioni registrate e prossimo gate

| Decisione | Stato |
|---|---|
| Fantasy di giocatore di dadi attratto dal rischio e dalla destrezza | **Approvata dall'utente** |
| Sei D6, Farkle fisico, g3d, scelta incassa/rilancia | **Implementata** |
| Inquadratura leggermente più dall'alto e HUD ingrandito | **Implementata in baseline** |
| Barra visiva `sicuri / a rischio` nella scorecard | **Implementata su branch v0.1.91; CI e UAT da verificare** |
| Destrezza capace di piegare le probabilità in modo riproducibile | **Ipotesi non misurata** |
| Duello col Opponent, posta, libri e rivali asimmetrici | **Progettazione aperta** |

**Prossimo gate:** QA della barra e delle azioni senza coprire i dadi, poi EX-F01. Non aggiungere nuove abilità fisiche o valute finché non sappiamo se il gesto attuale riesce a incarnare la promessa.

---

*Fonti interne: [project_vision.md](project_vision.md), [farkle_rules.md](farkle_rules.md), [RQ-002](../research/RQ-002_FANTASY_FIRST_UI.md); per l'implementato prevale il codice della revisione indicata. Nessuna ricerca di mercato, simulazione EX-F01/EX-F02 o verifica commerciale è stata svolta per questo documento.*
