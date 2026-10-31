# Manuscript — Incontri con le miniature e sacchetti di Segni

**Stato: proposta di game design, 30 ottobre 2026. Nessuna delle meccaniche di incontro descritte qui è dichiarata implementata.** Questo documento sviluppa la direzione discussa dopo il prototipo di folio progressivo. Riferimenti canonici: [GAME_DESIGN.md](GAME_DESIGN.md) per visione e priorità, [FARKLE_RULES.md](FARKLE_RULES.md) per le regole effettive del Farkle.

> **Aggiornamento di laboratorio — 31 ottobre 2026 / 0.1.0-dev.5:**
> è ora implementato esclusivamente
> [`experiments/signs_lab/`](../experiments/signs_lab/README.md)
> il primo modello A/B/C con sacchetto, soglie e politiche
> provvisorie del Leone della Bordura. Questo è **codice
> sperimentale separato**, non una funzionalità giocabile
> in `main.lua` o nella campagna; nessuna regola è stata
> approvata automaticamente. I gate di playtest restano aperti.
>
## Sintesi della direzione

**Direzione condivisa:** le figure raffigurate nei manoscritti (re, monaci, animali fantastici, allegorie, creature marginali) prendono vita, escono dal folio e diventano gli interlocutori/avversari del copista nel sogno. Superato un incontro, la figura rientra nella miniatura; completare le figure del libro porta alla conclusione della run. Tipologia e iconografia del libro orientano il cast: per esempio, un salterio può presentare figure bibliche, allegoriche e marginali coerenti con il suo repertorio, non un assortimento arbitrario di nemici.

**Principio non negoziabile:** Manuscript resta un roguelite solitario fondato sul **brivido del Farkle**: lancio fisico di sei D6, accantonamento, scelta se assicurare o rilanciare, possibilità concreta di perdere tutto il punteggio provvisorio e colpi eccezionali che cambiano la situazione. Il combattimento deve amplificare la tensione *mi fermo o rilancio?*, non trasformare i dadi in una valuta per un puzzle tattico. La difficoltà non equivale automaticamente a profondità. Preferire un incontro semplice ed emozionante a più sottosistemi mediocri.

L'idea di colorare/riempire la pagina in proporzione ai punti non è più il centro della vittoria: il manoscritto si ricompone principalmente **per il ritorno delle figure sconfitte**. L'inchiostro provvisorio e le trasformazioni dei dadi rimangono possibilità di feedback scenico del rischio, da verificare, non obiettivi che devono guidare le regole.

## Che cosa è deciso e che cosa no

| Ambito | Stato | Confine |
|---|---|---|
| Farkle come nucleo, dadi 3D e rischio di Farkle | **Vincolo approvato** | Non riscrivere combinazioni, punteggi o fisica per il nuovo concept |
| Figure animate e ricomposizione del libro | **Direzione narrativa/visiva approvata** | Non ancora implementata |
| Nemici asimmetrici: il giocatore tira dadi, il nemico segue regole diverse | **Direzione di design** | Va dimostrata in un incontro giocabile |
| Sacchetto di Segni e gettoni a esaurimento | **Ipotesi preferita** | Composizione, probabilità, tempistiche e riciclo da testare |
| Manipolazione del sacchetto | **Ipotesi** | Non introdurre un menu permanente o una seconda valuta senza prova |
| HP, Scudo, Concentrazione, Vincoli o condizioni speciali | **Aperto** | Non decidere contro gli HP solo perché «basici»; non usare condizioni facili da ottenere |
| Numero di avversari/folii/turni e durata run | **Aperto** | Nessun numero approvato; i turni attuali delle commissioni non si trasferiscono automaticamente |
| Tarocchi / Trionfi | **Rinviato esplicitamente** | Non includere nel primo ciclo di prototipazione |

Le cifre (8 Segni, 2 estrazioni, costi 20/30/50, soglie di 30/70, 12 HP o 2–3 vincoli) emerse negli esempi conversazionali sono **segnaposto**, non taratura approvata. Anche il vincolo dei «due rilanci» evocato nella discussione deve essere confrontato con le regole e il runtime effettivi prima di inserirlo come requisito tecnico.

## Asimmetria: Farkle contro Segni

Il **giocatore** continua a scegliere un sottoinsieme valido di dadi, accantonarlo, rilanciare i dadi liberi oppure incassare nel rispetto delle regole in [FARKLE_RULES.md](FARKLE_RULES.md). Le combinazioni non diventano automaticamente «attacco», «cura» o «elemento»; eventuali effetti supplementari devono lasciare leggibili i punti e la decisione di rischio.

L'**avversario** ha una regola peculiare e un insieme di **Segni**, piccoli frammenti di pergamena miniata che rappresentano le sue azioni. L'ispirazione di design proviene dal prototipo cooperativo *Star Realms Boss Fight Concept* (2020) fornito dall'utente: boss asimmetrico, gettoni in un sacchetto, sequenza di abilità/attacco/difesa e crescita nel tempo. Gli script di Tabletop Simulator sono **materiale di studio**, non codice da copiare. In particolare, il prototipo P4ND0RA usa una pesca senza reinserimento immediato, scarti, riciclo, neutralizzazione e aumento della potenza di estrazione quando il sacchetto si esaurisce. Questo non costituisce ancora una specifica implementativa per Manuscript.

Categorie **provvisorie** dei Segni:
- **Assalto:** minaccia diretta al copista o al suo stato, da definire.
- **Guardia:** protezione temporanea dell'avversario, se nel test serve.
- **Ripristino:** recupero di una risorsa del nemico, soltanto se produce decisioni interessanti.
- **Segno peculiare:** abilità specifica della figura, che modifica rischi e opportunità del Farkle.

Altri Segni (preparazione, escalation, maledizioni) possono derivare da una regola speciale, senza moltiplicare subito le categorie universali. **Stesso significato funzionale, iconografia diversa:** categorie leggibili a colpo d'occhio, simboli miniati adattati a salterio, bestiario, cronaca ecc. Evitare gettoni da casinò moderni. Le rappresentazioni di sacchetto, sigilli e rasura sono scenografia originale, non ricostruzione storica letterale.

## La vera interazione: il nemico altera la posta, non il gesto del lancio

Una possibile sequenza per il **prototipo**, non ancora approvata come regola, è:

1. Una **Intenzione** o una minaccia del nemico viene rivelata *prima* della decisione del giocatore. L'informazione può essere parziale ma deve permettere scelte comprensibili.
2. Si svolge il normale turno Farkle. Il giocatore può scegliere quando assicurare i punti e quanto esporsi al Farkle.
3. L'incasso ha una conseguenza sull'incontro; un eventuale effetto di controllo del sacchetto deve avere un **costo-opportunità reale**. Il Farkle cancella i punti non incassati secondo il regolamento, fatte salve le medaglie già previste.
4. Se l'avversario può agire, risolve la minaccia e gli eventuali altri Segni secondo un ordine esplicito, poi aggiorna sacchetto/scarti.

**Evitare penalità automatiche a ogni rilancio:** se ogni ulteriore tiro è sempre punito dal nemico, il gioco incentiva a fermarsi e spegne il suo nucleo emotivo. Preferire alternanza fra occasioni da sfruttare, rischi visibili e colpi eccezionali. Un nemico può spingere ad assicurare presto; un altro a inseguire la soglia; nessuno deve rendere sempre corretta la medesima scelta.

## Manipolazioni da valutare separatamente

- **Sigillatura / neutralizzazione:** impedisce l'effetto di un Segno annunciato o estratto **per una sola risoluzione**; non equivale a eliminarlo permanentemente.
- **Rasura / scarto:** sposta un Segno dal sacchetto agli scarti. Può prevenire una minaccia, ma **accelera il riciclo** e l'eventuale escalation, quindi non è un beneficio garantito.
- **Lettura / previsione** e **vincolo di categoria**: opzioni possibili per modificatori futuri, non comandi base da inserire subito.

L'accesso a queste manipolazioni potrebbe nascere da combinazioni, da scelte sull'incasso o da glosse/strumenti acquisiti nella run. **Nessun metodo è approvato**; iniziare con un solo controllo e confrontarlo con un incontro senza manipolazioni. Eventuali glosse, reliquie o strumenti non sono automaticamente una nuova economia o un inventario aggiuntivo.

## Vittoria, sconfitta e progressione

**Obiettivo narrativo:** ricondurre le figure al folio e completare tutte le figure previste dal libro. L'HP puro è comprensibile ma rischia di ridurre ogni tiro a danno lineare; la sola combinazione obbligatoria può invece produrre vittorie facili o dipendenti dalla fortuna. Sono da confrontare almeno:
1. **Resistenza/HP essenziali**, con comportamento dei Segni che cambia la convenienza di incassare o rilanciare;
2. **Finestre di opportunità e progressi consolidati**, senza che i «Vincoli» diventino semplicemente HP divisi in segmenti;
3. eventuale **ibrido**: incontri ordinari rapidi e figure principali con regole peculiari.

Non fissare soglie o condizioni di vittoria sulla base di esempi inventati. Evitare ripristini del nemico che allungano gli scontri senza offrire scelte nuove. L'azione visiva di «ritorno nel folio» deve essere chiara e gratificante ma breve e saltabile.

Il libro definisce il tema della run e il cast; la sequenza fra folii, incontri, ricompense e figura conclusiva è aperta. Le modifiche di dadi/facce/probabilità e medaglie restano la direzione roguelite da approfondire **dopo** la validazione del primo incontro. Nessuna richiesta di generare cataloghi di nemici prima di validare il ciclo.

## Candidato per il prossimo prototipo: il Duello delle Poste

**Proposta di prova, non approvazione definitiva né funzione implementata (30 ottobre 2026).** Per risolvere l'alternativa fra HP lineari e una combinazione obbligatoria troppo semplice, confrontare un **duello di azzardo a più mani**. È una *ipotesi di lavoro* da verificare rispetto alla baseline HP, non un cambiamento già deciso nelle regole ufficiali Farkle.

### Ciclo minimo da modellare

1. La miniatura rivela la **categoria** del Segno estratto da un sacchetto senza reinserimento; l'esatta *forza* può rimanere nascosta finché il giocatore non incassa. La distribuzione delle forze dev'essere nota o deducibile e mai falsata dall'interfaccia.
2. Il copista esegue un **normale turno Farkle**: sei D6, selezioni valide, accantonamento, hot dice, opzione di continuare o incassare. Nessun dado o punteggio fittizio per il combattimento.
3. Incassando, si confrontano i **punti effettivamente assicurati** con la forza del Segno. In questa variante iniziale, se raggiungono la forza il giocatore vince la mano; altrimenti la vince la miniatura. Il Farkle fa perdere il punteggio provvisorio e la mano.
4. Il Segno risolto va negli scarti. Si definisce cosa accade al sacchetto esaurito prima dei test: riciclo semplice, con o senza modifiche, senza introdurre automaticamente una nuova economia.
5. La miniatura rientra nel folio quando l'incontro è vinto. Non è necessario disegnare una barra HP, né inventare condizioni basate su un unico tiro raro.

### Prima fixture illustrativa: il Leone della Bordura

Un primo sacchetto di **sei Segni**, due per categoria: **Assalto** con forze 20/40, **Guardia** con forze 30/50, **Occasione** con forze 35/55. La proposta iniziale è una **gara a tre mani vinte**, con possibilità condizionata di ottenere **due successi** da un'Occasione vinta con almeno 25 punti di margine; un Farkle sotto Assalto attribuirebbe due successi all'avversario. Queste sono *tutte* cifre esplorative. Non chiamarle bilanciate né compatibili a priori con ogni soglia di ingresso del regolamento vigente. Stabilire anche la gestione di esaurimento Segni e parità di successi in modo esplicito prima di simulare.

**Esempio di decisione:** 40 punti provvisori, tre dadi liberi; un Segno Guardia è noto come categoria ma potrebbe valere 30 oppure 50. Incassare ora può vincere o perdere la mano; rilanciare può migliorare l'incasso e, insieme, far perdere tutto. Non etichettare come probabilità di vittoria un calcolo che non modelli scelte, hot dice, distribuzione del sacchetto e condizioni di incasso. La varianza nascosta dev'essere presentata al giocatore in modo comprensibile; i numeri dell'esempio non sostituiscono una simulazione.

### Cosa dobbiamo falsificare

**Obiezione principale:** rischiamo di sostituire gli HP con una semplice *soglia casuale*, oppure creare incontri troppo brevi, due successi troppo facili o una strategia fissa che domina ogni Segno. Il modello è utile **solo se** mostra decisioni significativamente differenti per categorie e stati, mantenendo la suspense del rilancio.

**Confronto A/B/C:** A = Farkle corrente senza nemico; B = incontro con HP/progresso semplice; C = Duello delle Poste e sacchetto. Solo se C supera B nell'interesse delle scelte, aggiungere una variante D con **una** manipolazione (Sigillatura o Rasura) e costi-opportunità dimostrabili. Misurare almeno mani per incontro, tasso di Farkle, probabilità condizionate di incasso e rilancio, ruolo dei colpi eccezionali, distribuzione esiti e percentuale di stati in cui strategie diverse sono migliori. Non calibrare gli incontri soltanto per rendere le vittorie più rare.

**Vincoli invariati:** non toccare combinazioni, punteggi, dadi fisici o sistema hot dice per facilitare l'esperimento; evitare Tarocchi/Trionfi e penalizzazioni monotone per ogni rilancio. **Nessuna integrazione nel gameplay principale** finché non esistono una specifica completa e test riproducibili.

## Primo esperimento e criteri di verifica

**Prima di implementare:** specificare un **solo incontro completo** con stato iniziale, regole di fine turno, condizioni di vittoria e sconfitta, conseguenze esatte di incasso/Farkle, segnali visibili, sacchetto/scarti e durata massima. Preferire pochi Segni e una sola abilità distintiva. Il primo scenario possibile è una creatura marginale di un salterio: scelta illustrativa, non un requisito.

Confronti da simulare e playtestare, usando le **combinazioni Farkle reali**:
- **Controllo A:** Farkle corrente senza nemico;
- **Controllo B:** nemico con semplice progresso/HP, senza effetti sui rilanci;
- **Variante C:** nemico con intenzioni/Segni che influenzano davvero la decisione di fermarsi o rischiare;
- **Variante D, solo se C funziona:** aggiunta di una manipolazione del sacchetto.

Registrare per ciascuna decisione: dadi rimasti, punti provvisori, stato della minaccia, possibilità di incasso, scelta presa, conseguenza e motivo. Misurare durata, Farkle e recuperi, distribuzione vittorie, sensibilità alle strategie e varietà delle scelte *a parità di stato*. Una difficoltà maggiore o più pulsanti **non** costituisce profondità. Cercare strategie dominanti (sempre incassare, sempre rilanciare, sempre neutralizzare), vittorie per un unico tiro fortunato e scontri lunghi senza escalation comprensibile.

**Gate di progettazione:** nessuna modifica a runtime, fisica, HUD o scoring prima che il design di un incontro sia formulato e il vantaggio rispetto al controllo B sia almeno plausibile e verificabile. Solo dopo definire i contratti tecnici minimi.

## Non obiettivi di questa fase

Non implementare Tarocchi/Trionfi, puzzle cromatico, tavole di piazzamento stile roll-and-write, combattimento tattico a molte risorse, taverna giocabile, animazioni lunghe, nuovi sistemi di scripting o un generatore di miniature. Il lessico medievale e i manoscritti devono differenziare **un gioco di dadi emozionante**, non mascherare un gioco tattico ordinario.

### Vincolo tecnico per il prototipo di incontro

Il sacchetto dei Segni e la risoluzione delle mani potranno reagire solo all'evento ludico `dice.roll_accepted` (o, meglio, all'esito esplicito dell'incasso della mano), **non** a `dice.physical_settled` e non a ogni simulazione di lancio. Un risultato respinto dal dado pesato o un retry meccanico non deve consumare Segni, cambiare il numero di mani o alterare la posta. Il codice degli avversari non fa ancora parte della run.

