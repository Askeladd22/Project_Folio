# Manuscript — Game Design

**Versione 0.6 · 16 ottobre 2026.** Documento canonico. Manuscript è il titolo di lavoro; Scriptorium è il nome storico. Le etichette distinguono **attuale**, **approvato**, **proposta** e **aperto**. Per il comportamento effettivo prevalgono sorgenti e test; un'intenzione non è una funzionalità implementata.

## Identità e pilastri

Roguelite solitario ambientato in una bottega libraria del XV secolo, con una **nuova cornice narrativa approvata come direzione di progetto**: un copista lavora di giorno, frequenta un luogo di gioco d'azzardo la sera e, nel sonno, sovrappone la tensione dei dadi al proprio lavoro sul manoscritto. L'esatta città, la routine, i personaggi e la forma della narrazione rimangono aperti. Il nucleo è sempre il Farkle fisico: lanciare sei dadi, scegliere che cosa accantonare, assicurare punti o rischiarli. Non serve un avversario artificiale: commissioni e turni disponibili definiscono la sfida.

1. Il piacere visivo e fisico del lancio resta centrale.
2. Rischio leggibile, con distinzione fra lavoro provvisorio e assicurato.
3. Personalizzazione che modifica decisioni e compromessi, non soltanto quantità di punti.
4. Commissioni capaci di rendere utili strategie differenti.
5. Manoscritto visibile come avanzamento e ricompensa: ciò che è a rischio deve avere una presenza visiva reversibile, ciò che è incassato deve restare.
6. **Il libro è il tavolo di gioco:** l'oggetto-sogno unisce libro, superficie del Farkle e pagina in lavorazione. La trasformazione dei dadi in segni manoscritti deve rendere visibile il nesso fra rischio e opera.
7. Semplicità d'uso: primo lancio immediato, poca interfaccia, conseguenze comprensibili; nessuna animazione deve occultare la decisione successiva.
8. Codice e asset originali: i riferimenti non autorizzano copie proprietarie.

Pubblico e formato proposti: esperienza single-player a run relativamente brevi, per chi apprezza dadi e costruzione della propria dotazione. Durata commerciale, progressione persistente e numero finale di commissioni restano aperti.

## Cornice narrativa e significato del rischio

**Approvato come concept, non ancora implementato come sequenze narrative.** Il protagonista è un copista della bottega libraria quattrocentesca: il lavoro diurno gli impone precisione e scadenze; la sera scopre o pratica il gioco dei dadi; di notte sogna che i due mondi siano un unico tavolo. Il sogno è una **metafora ludica**, non la pretesa che il Farkle odierno fosse praticato nelle botteghe quattrocentesche o che le pergamene potessero cancellarsi magicamente. Giochi con dadi hanno una storia più ampia; eventuali riferimenti circostanziati a luoghi, forme di azzardo e costumi necessitano di verifica storica.

Il sogno consente che la scelta fra fermarsi e rilanciare si manifesti come avanzamento o perdita del **lavoro non ancora consolidato**. Incassare equivale, nella metafora, ad accettare e rendere definitivo un segmento di lavorazione; Farkle equivale a scartare/rifare quello in sospeso. Ciò che si dissolve è la sua **rappresentazione onirica**, non l'inchiostro materialmente scritto. Le medaglie sono segni/talismani o richiami del gioco serale, da reinterpretare in seguito con nomi e iconografie originali.

**Pacing narrativo proposto:** un'introduzione brevissima può stabilire bottega → gioco serale → sogno. Nel sogno, **un libro si apre e diventa la stessa superficie su cui si gioca**: non si passa da una schermata di dadi a una schermata di lavoro scollegate. Durante la partita niente intermezzi obbligatori dopo ogni tiro; il racconto deve emergere dall'oggetto, dai dadi che si trasformano in segni, dai suoni e da pochi segnali ambientali. Non sono approvati nuovi hub, dialoghi, personaggi giocabili, scene ripetute o meccaniche di taverna. Valutare il concept con un breve playtest prima di produrre animazioni narrative costose.

## Il codice onirico: libro, lancio e trasformazione

**Concept visuale approvato; implementazione ancora da prototipare.** L'oggetto principale di Manuscript non sarà un normale vassoio ligneo accostato a un folio, ma **un libro che nel sogno si trasforma in tavolo da gioco**. Il giocatore vede dapprima un codice chiuso, con coperta, dorso/costola e taglio delle carte; all'inizio della partita il volume si apre, offrendo un'ampia **superficie-folio giocabile**. L'immagine è intenzionalmente surreale: non pretende di riprodurre un oggetto realmente diffuso nelle botteghe del XV secolo. Riferimenti fotografici a cofanetti a forma di libro e custodie per dadi documentano materiali e meccanismi plausibili per una *fantasia visiva*, non l'esistenza storica di un simile libro da gioco.

**La costola come origine del lancio.** Il dorso aperto può trasformarsi *visivamente* in un bossolo, canaletto o piccola torre per dadi: da lì i sei dadi sembrano entrare nello spazio del foglio. La differenza fra **bossolo** e **dice tower** resta aperta e va confrontata con prototipi leggeri; nessuna delle due giustifica la riscrittura delle collisioni o l'aggiunta di un settimo corpo fisico. La traiettoria di ingresso può essere scenica e sincronizzarsi con l'avvio del tiro fisico esistente, purché non falsifichi risultati, selezione o orientamento delle facce. L'apertura del libro è un'introduzione **breve, saltabile e non ripetuta a ogni lancio**.

**I dadi rotolano sul folio.** La pagina stessa deve sembrare il piano di gioco, invece di avere un vassoio indipendente e una pagina decorativa separata. Servono una zona di lancio leggibile, bordi fisicamente credibili e un campo sufficiente per distinguere sei dadi, ombre, facce e selezioni. La pergamena può presentare linee guida e ornamentazione crescente, ma i tratti non devono diminuire il contrasto né rendere difficili picking e lettura. Un'eventuale seconda pagina o una finestra di ingrandimento può mostrare il lavoro più in dettaglio, senza duplicare in modo incoerente il progresso. La disposizione esatta delle facciate (una o due pagine visibili), le proporzioni e la camera sono **aperte a un workshop visivo**; la visione di base del lancio *sul folio* non va ridotta automaticamente a un vassoio con una carta accanto.

**Accantonare significa trasformare il dado in scrittura.** Dopo una selezione **confermata**, il dado esce visivamente dal campo del prossimo tiro e **si scioglie in segni**: inchiostro che si espande, lettere, righe, iniziali, tralci di bordura o pigmento, in relazione ai punti effettivamente accantonati. Non deve diventare un'animazione lunga e uguale per ogni dado; un segno breve, chiaro e variabile è sufficiente. Non associare rigidamente il numero del dado a un colore o a una specifica fase artigianale: niente ritorno al vecchio puzzle cromatico.

**Memoria dei dadi accantonati.** Lo scioglimento è **solo grafico**: il dado conserva nel modello logico ID, faccia accettata, valore, appartenenza al tiro e stato `used`. Sul **bordo superiore** del libro/tray restano fino a sei **segnali o impronte leggibili** che rappresentano gli accantonamenti (per esempio piccole tessere, sigilli, dadi miniaturizzati o icone numerate), anche quando la rappresentazione grande del dado si è dissolta nel folio. Questo sostituisce il precedente parcheggio di sei grossi dadi come obbligo visivo, ma non elimina l'informazione necessaria al giocatore. Se il playtest dimostra che i segni non bastano, conservare l'opzione di mostrare copie grafiche dei dadi nel bordo superiore. Gli eventuali dadi tornati disponibili con hot dice ricompaiono nel tiro successivo; **le tracce a rischio e i punti provvisori del turno restano**. La dissolvenza non altera la fisica né genera o distrugge dadi nell'autorità del controller.

**Rapporto fra rischio e folio.** Il segno nato dall'accantonamento rimane **provvisorio**, come preparazione, linea pallida o colore incompleto. Solo l'**incasso riuscito** ne rende definitivo l'aspetto. In un **Farkle definitivo** si ritira o si scioglie soltanto la lavorazione provvisoria di quel turno; le parti già assicurate non vengono mai cancellate. Se il Farkle può essere recuperato da una medaglia, attendere la risoluzione dell'effetto prima di mostrare la perdita finale. Il lavoro che appare è una metafora del sogno, non una pergamena il cui inchiostro reale evapora. La commissione conserva le sue condizioni di completamento anche se la pagina sembra piena.

| Evento del Farkle | Trasformazione onirica prevista | Stato reale |
|---|---|---|
| Apertura della commissione | Si apre il libro e appare il campo-folio | Nessun punto assegnato |
| Lancio | I dadi sembrano emergere dalla costola | Solo simulazione dei sei D6 esistenti |
| Selezione provvisoria | Evidenziazione reversibile sui dadi | Nessun accantonamento né testo acquisito |
| Accantonamento confermato | Il dado si scioglie in una porzione *tenue* del folio; segno sul bordo superiore | Aumento dei punti a rischio; ID del dado conservato |
| Rilancio / hot dice | Nuovi dadi attivi dalla costola; le tracce provvisorie restano | Regole Farkle invariate |
| Incasso | Tracce provvisorie fissate in inchiostro, rubricatura e colore | Incremento dei punti assicurati già calcolato |
| Farkle definitivo | Le sole tracce provvisorie sfumano / si ritirano | Azzeramento dei soli punti a rischio |
| Fine commissione | Il folio completo è presentato come opera conclusa | Vittoria solo se le condizioni logiche sono soddisfatte |

**Principio di produzione:** la fisica 3D consolidata ha priorità sulla metamorfosi scenica. Apertura, bossolo/costola, dissoluzione e colorazione vanno realizzati mediante trasformazioni di presentazione, maschere e livelli grafici compatibili con il motore esistente, non modificando spawn, collisioni, corpi o lettura delle facce. La transizione non deve bloccare decisioni oltre il necessario, deve essere saltabile e deve poter terminare istantaneamente nello stato visivo corretto.

**Rischio artistico principale:** la pagina che si decora progressivamente potrebbe rendere i dadi poco leggibili o distrarre durante il lancio. Testare contrasto fra dado e pergamena, densità ornamentale, tempo di ogni transizione e comprensione dei dadi già accantonati. Se necessario, collocare l'ornamentazione soprattutto ai margini e far emergere i dettagli nella pausa fra un tiro e il successivo; non cambiare le regole per accomodare la scenografia.

## Gioco attuale

**Il Farkle Roguelite è l'applicazione principale**, non un esperimento. Avvio dalla radice con `love .` o `Avvia.cmd`, senza pacchetti o build. Splash, Main Menu, Settings e Choose Commission sono ripristinati. Il selettore contiene Farkle Roguelite e Back; non le vecchie commissioni placeholder. Continue è disabilitato: non esiste ancora un salvataggio riprendibile della run.

Il [regolamento ufficiale](FARKLE_RULES.md) sostituisce la vecchia scala numerica: singoli 10/5, tris e gruppi definiti in tabella, scale, tre coppie, full 4+2 e due tris. Le convenzioni per i valori intermedi sono dichiarate; obiettivi, limiti e soglie degli incarichi rimangono parametri di test.

Ciclo: commissione → lancio → selezione di gruppi disgiunti dello stesso tiro → accantonamento → incasso consentito o rilancio → Farkle/hot dice/consegna → ricompensa → incarico successivo. Il giocatore può sacrificare punti immediati per tenere più dadi nella riserva. Deve fare una selezione valida di ogni tiro prima di rilanciare o incassare. Ingresso e minimo incasso possono costringerlo a continuare: questa pressione va valutata, non presunta divertente.

Mini-run attuale: Salterio, Libro di ore, Codice. Gli ultimi due chiedono rispettivamente un gruppo di almeno tre uguali e hot dice **incassati**. La build persiste fra incarichi, punti e ingresso no. Nessuna valuta, negozio, IA avversaria o economia aggiuntiva è implementata.

## Personalizzazione

**Attuale:** dopo il primo incarico si sceglie un dado inciso (la faccia 2 del dado 1 diventa 1) oppure un dado pesato tramite filtro e rilanci fisici visibili; dopo il secondo il Correttore oppure nessuna medaglia. Sono esempi minimi, non un catalogo bilanciato. Il pesato non simula una massa eccentrica; le probabilità ideali non certificano quelle fisiche.

**Approvato come direzione:** modificare facce fisicamente identificabili e acquisire medaglie che cambino il significato delle decisioni. Identità della faccia, numero/simbolo, effetto, texture e probabilità devono restare distinti. Due facce uguali non devono essere confuse con lo stesso dado fisico.

**Proposta, non implementata:** una costruzione/forgiatura unificata potrebbe raccogliere incisione e pesatura come modifiche dello stesso oggetto. Non sono ancora approvati economia, slot, costi, rarità, modifiche reversibili, simboli non numerici o interazione pesatura/incisione. Per faccia i, con probabilità pᵢ e valore vᵢ, P(v)=Σpᵢ per vᵢ=v: sostituire cambia vᵢ, pesare cambia pᵢ. Se in futuro il peso resta legato alla faccia fisica, un'incisione potrebbe trasferirne il vantaggio: occorre una decisione esplicita.

Evitare build che eliminano quasi il Farkle, duplicazioni fra sistemi e medaglie che amplificano qualsiasi risultato senza compromessi. Nel controllo senza modificatori non si simulano costi fittizi: serve a confrontare l'esperienza di base.

## Medaglie: riferimento sperimentale

**Attuale, non bilanciato:** un laboratorio separato permette di provare gli effetti documentati delle medaglie di *Kingdom Come: Deliverance II* (Warhorse Studios) con i punteggi di Manuscript. È una base comparativa destinata a una successiva revisione originale, non il catalogo definitivo. Nomi nell'interfaccia, codice e grafica sono originali e funzionali; i nomi KCD2 restano nella ricerca interna.

In partita: **Gestione run → Laboratorio medaglie**. Una sola medaglia per commissione; equipaggiarla riavvia esplicitamente la commissione corrente, mantenendo il dado personalizzato. Cariche per commissione, non per turno. Il comando **Medaglia: effetto / utilizzi** mostra condizioni, bersagli, disponibilità e risultato previsto. Sono attivi sette riferimenti: tre rilanci graduati, due scambi, un rilancio speciale e l'incasso ×2. Le definizioni incomplete o incompatibili sono consultabili ma non equipaggiabili. Il Correttore `retry` precedente rimane distinto da Resurrection, ancora da verificare.

I rilanci sono fisici, con identità e risultati conservati per i dadi non rilanciati. Nessuna nuova combinazione, conversione di punteggio arbitraria, settimo dado invisibile o trasformazione nascosta. Prima della revisione originale osservare ridondanza tra rilanci, utilità situazionale, consumo automatico delle cariche e impatto dell'incasso ×2 sulle commissioni; non correggerne adesso la potenza.

Inventario, divergenze e limiti: [ricerca medaglie](../KCD2_MEDAGLIE_RICERCA.md). Controlli, test e rollback: [implementazione](../MEDAGLIE_IMPLEMENTAZIONE.md).

## Commissioni e manoscritto

Una commissione deve influenzare quali dadi trattenere, quando fermarsi e quali modifiche scegliere. Possibili direzioni future: tempi stretti che valorizzano sicurezza, opere impegnative che premiano gruppi specifici, richieste prestigiose che impongono adattamento. Sono proposte; non reintrodurre il puzzle dei pigmenti o una seconda economia.

**Attuale:** il folio è un'anteprima laterale ingrandibile con iniziale, righe e bordura schematica; inchiostro scuro = assicurato, tenue = provvisorio. Non è ancora un sistema completo di miniatura né una pagina che si compone per elementi riconoscibili.

**Approvato come comportamento desiderato, ancora da implementare e provare:** ogni accantonamento *confermato* che incrementa i punti provvisori rende visibile una porzione di scrittura o decorazione **in forma tenue, incompleta o di disegno preparatorio**. La semplice selezione, l'hover e il tiro non generano lavoro acquisito. All'incasso, la porzione corrispondente ai punti effettivamente assegnati diventa stabile, più definita e colorata; in caso di Farkle il lavoro provvisorio sfuma e resta intatto tutto ciò che è già stato assicurato. Un hot dice conserva il provvisorio e rinnova soltanto la disponibilità dei dadi. L'animazione si può saltare senza modificare alcun punto.

**Contratto fra logica e grafica:** lo stato logico della commissione resta autorevole. Usare il totale realmente *assicurato*, il totale *a rischio* effettivamente confermato e il target per determinare la porzione della pagina visibile; non calcolare i punti a partire dalla grafica. Limitare la **percentuale visualizzata** al 100%, anche in presenza di sovrapunteggio; non troncare i punteggi reali. Le medaglie che cambiano l'accredito (per esempio incasso ×2) vanno riflesse solo sull'esito realmente risolto, senza anticipare bonus non garantiti. Raggiungere visivamente il target non completa da solo la commissione: rispettare anche eventuali condizioni speciali, come gruppi o hot dice incassati. Per modificatori, recuperi da Farkle, salti di animazione e cambio turno nessun doppio conteggio, nessuna perdita di progressi assicurati.

**Direzione artistica approvata per il prototipo del libro-folio:** evitare una barra che semplicemente tinge tutta la pergamena. Predisporre **strati distinti** (rigatura o disegno preliminare, testo, iniziali rubricate, bordura vegetale e particolari policromi) che emergano a soglie o porzioni continue dei punti; le soglie sono di sola presentazione, non requisiti di gameplay. Un riferimento illustrato di ornamento vegetale policromo con cornice e campo interno bianco guida la composizione, senza copiarne automaticamente l'immagine. Partire da una sola pagina originale e pochi strati per verificare la sensazione durante il rischio/incasso/Farkle. Fasi come preparazione, rigatura, scrittura, rubricazione, decorazione, doratura e rilegatura si applicano **solo quando pertinenti** e non definiscono una sequenza storica universale.

Ambientazione approvata: bottega quattrocentesca e cornice onirica del gioco serale; luogo, decennio, istituzione, grafia, dettagli della taverna e rapporto storico con l'azzardo restano da definire o verificare. Pigmenti e materiali sono riferimenti artistici e terminologici, non prove di disponibilità universale né risorse di gameplay già approvate. Commissioni specifiche, conversione punti→lavoro e medaglie sono astrazioni ludiche, non ricostruzioni letterali. Nessun asset commerciale o elemento riconoscibile della plancia di riferimento va copiato.

## Interfaccia e verifica dell'esperienza

**Attuale:** vassoio e sei dadi protagonisti; barra unica per commissione, turni e incasso; manoscritto laterale; controlli contestuali in posizioni stabili. Clic o 1–6 selezionano, **Scelte** espone le alternative, Accantona e Incassa restano espliciti. Regole e folio si consultano senza abbandonare la run. Durante il movimento gli input di gioco sono bloccati.

**Nuova direzione di interfaccia approvata (da prototipare, non ancora stato corrente):** il centro della scena è **un codice onirico aperto**, insieme superficie di lancio e manoscritto in costruzione. Non più, come impostazione definitiva, un comune vassoio rettangolare con un folio separato e statico. La costola suggerisce il punto di origine dei dadi; la superficie-folio lascia spazio al lancio fisico; sul **bordo superiore** sei segni leggibili documentano i dadi accantonati dopo la loro trasformazione grafica. Una zona di consultazione o ingrandimento permette di vedere scrittura, iniziali e ornamento senza nascondere il gesto fisico. Il documento di lavoro deve mantenere una **fascia informativa sottile** (commissione, obiettivo, assicurati, a rischio, turni) e **comandi essenziali, in posizioni stabili** (lancia/rilancia, accantona, incassa). Le ricompense si presentano in uno stato distinto. Il layout preciso, la collocazione del dettaglio del folio e il trattamento del bossolo/dice tower richiedono prototipi, non un commitment tecnico anticipato.

La plancia allegata in precedenza è **riferimento di gerarchia e materialità**, non modello da riprodurre: evitare griglie, fazioni, simboli, colori e layout identificativi del gioco altrui. La pagina con bordura floreale è **riferimento di grammatica ornamentale**; le fotografie più recenti di libri/cofanetti da dadi, coperte decorate e interni apribili sono **riferimenti di forma, apertura e materiali**, non asset di cui presumere i diritti di redistribuzione né attestazioni storiche di un libro da gioco quattrocentesco. Preferire asset originali/licenziati, contrasto leggibile, materiali poco invadenti ed effetti da sogno molto discreti. Conservare un flusso immediato sul modello del Farkle da tavolo: lancia → scegli → accantona → rilancia o incassa. Non nascondere il comando di accantonamento se serve a distinguere selezione reversibile e conferma.

Verificare 1280×720 e 1920×1080, impostazioni persistenti, testo grande, input mouse/tastiera, gruppi sovrapposti consentiti dal Farkle, transizioni saltate, medaglie e folio. Le modifiche visuali non devono reintrodurre la vecchia meccanica cromatica né alterare il motore fisico 3D.

Playtest successivi: annotare provvisorio, dadi residui, soglia, condizione mancante, turni restanti, scelta e motivo. Confrontare controllo, inciso e pesato alternando l'ordine; annotare separatamente l'attesa del filtro pesato. Cercare decisioni che cambiano con lo stato, non solo maggiore difficoltà. Osservare se Scelte è utile o macchinoso, se le soglie forzano troppi rilanci, se il Correttore viene speso automaticamente. Le simulazioni isolate nel regolamento non dimostrano divertimento o strategie ottime.

## Vincoli e prossimi passi

Architettura corrente: `src/gameplay/farkle/` per regole; `src/features/farkle/` per controller e presentazione; `src/app/` per runtime; `src/engine3d/` per motore congelato. Contratti e limiti nel [documento tecnico](TECHNICAL.md). Non dipendere da `experiments/` né caricare gameplay cromatico da `legacy/`.

Non migrare framework, usare `love.physics` per i dadi 3D, ridimensionare dadi/vassoio o riaprire SAT dinamico senza bug concreto e autorizzazione. Non sacrificare il gesto fisico a una ricerca tecnica interminabile. Intrecci, Motivi contesi, Arte del rischio e Folio progressivo/roguelite sono storici, non parti del regolamento corrente.

**Priorità aggiornate:** (1) realizzare un **prototipo giocabile essenziale** del libro aperto come superficie-folio, con costola come origine scenica del lancio e informazioni di accantonamento sul bordo superiore; verificare che i sei dadi rimangano leggibili senza cambiare la fisica; (2) collegare **un solo effetto originale di trasformazione dado → inchiostro/testo** ai punti provvisori effettivamente confermati, con fissaggio su incasso e dissoluzione su Farkle; (3) solo dopo, provare una brevissima apertura del libro e confrontare bossolo vs dice tower scenica, senza impegnarsi in geometrie fisiche nuove; (4) verificare le decisioni del Farkle ufficiale e bilanciare pochi incarichi e modifiche. Non produrre subito filmati, animazioni elaborate, un generatore di miniature, nuovi minigiochi o molte illustrazioni. Restano aperti nome commerciale, luogo/periodo preciso, modalità di racconto, lunghezza della run, progressione esterna, economia, catalogo di medaglie, distinzione fra peso/incisione e criterio di verifica dell'equità fisica. Non aggiungere contenuti soltanto per ampliare il catalogo.

## Biblioteca di progetto

Fonti consultate o allegate, non garanzia di lettura integrale né di adozione:

- **Design:** Tynan Sylvester, *Designing Games* (decisioni e conseguenze); Matt Hackett, *How to Make a Video Game All By Yourself* (gesto centrale, scope e playtest); John Harris, *Exploring Roguelike Games* (sistemi e rigiocabilità); Kameron e Frahaan Hussain, *The Art and Science of Game Development*; *Game Design Toolkit*. Nessun manuale certifica il bilanciamento.
- **Storia e immagini:** Sara J. Charles, *The Medieval Scriptorium*; Richard Hayman, *Illuminated Manuscripts*; Tymms e Wyatt, *Masterpieces of Illuminated Letters and Borders*; *Common Medieval Pigments*; *Come un copista medievale*; tavola comparativa dei pigmenti storici. Verificare epoca, area e permessi delle immagini; la carolina non è una grafia universale del XV secolo.
- **Giochi e riferimenti visivi:** Farkle/KCD2 e Squire's Dice per lancio fisico e immediatezza; Dice Forge per facce identificabili; Balatro per build e feedback causale; Biblios e Biblios: Quill and Parchment per obiettivi librari; Trismegistus per relazioni fra selezione e azioni. La plancia lignea, la pagina ornata e le fotografie del libro/cofanetto apribile fornite dall'utente sono riferimenti di struttura, materiali, apertura e lessico figurativo, non autorizzazioni a copiarne gli asset. I riferimenti non autorizzano aste, moltiplicatori o nuovi sottosistemi per analogia.

Le ricerche tecniche originali sono nell'[indice storico](../legacy/README.md); i materiali allegati non sono necessariamente distribuiti nel repository.
