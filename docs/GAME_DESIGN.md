# Manuscript — Game Design

**Versione 0.7 · 30 ottobre 2026.** Documento canonico. Manuscript è il titolo di lavoro; Scriptorium è il nome storico. Le etichette distinguono **attuale**, **approvato**, **proposta** e **aperto**. Per il comportamento effettivo prevalgono sorgenti e test; un'intenzione non è una funzionalità implementata.

> **Stato prototipi al 31 ottobre 2026:** nel laboratorio
> [`experiments/signs_lab`](../experiments/signs_lab/README.md)
> esiste una simulazione riproducibile A/B/C di Incontri e
> Segni. La variante C è una *ipotesi non approvata* e non
> entra nel gameplay. Nel gioco resta separatamente
> disponibile il beta simmetrico del Monaco (PR #36);
> miniatura 2D e dadi/tray g3d 3D sono invariati.
>
## Identità e pilastri

Roguelite solitario ambientato in una bottega libraria del XV secolo, con una **nuova cornice narrativa approvata come direzione di progetto**: un copista lavora di giorno, frequenta un luogo di gioco d'azzardo la sera e, nel sonno, sovrappone la tensione dei dadi al proprio lavoro sul manoscritto. L'esatta città, la routine, i personaggi e la forma della narrazione rimangono aperti. Il nucleo è sempre il Farkle fisico: lanciare sei dadi, scegliere che cosa accantonare, assicurare punti o rischiarli. **Attuale:** commissioni e turni disponibili definiscono la sfida, senza IA avversaria. **Direzione di game design approvata, non implementata:** figure miniaturizzate che escono dal folio e diventano avversari asimmetrici; una volta superate, ritornano nel libro. Il Farkle resta il protagonista e il rischio deve essere più emozionante, non più burocratico. Vedere [Incontri e Segni](INCONTRI_E_SEGNI.md).

1. Il piacere visivo e fisico del lancio resta centrale.
2. Rischio leggibile, con distinzione fra lavoro provvisorio e assicurato.
3. Personalizzazione che modifica decisioni e compromessi, non soltanto quantità di punti.
4. Incontri e commissioni capaci di cambiare realmente la scelta fra fermarsi e rilanciare, senza imporre un puzzle di combinazioni obbligatorie.
5. Manoscritto come mondo e ricompensa: la figura sconfitta rientra nella propria miniatura; il feedback provvisorio dei punti non deve sostituire la contesa con l'avversario.
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

**Accantonamento e feedback onirico (concept visivo preesistente, da rivalutare con gli incontri).** Dopo la selezione **confermata**, il dado esce dal prossimo tiro; una traccia di inchiostro, lettera o bordura può rendere visibile il rischio temporaneo. Non è più obbligatorio che ogni punto colori o riempia la pagina: il progresso principale della nuova direzione dipende dal ritorno delle figure nel folio. Evitare animazioni ripetitive, colori associati rigidamente ai valori e qualsiasi ritorno al puzzle cromatico.

**Memoria dei dadi accantonati.** Lo scioglimento è **solo grafico**: il dado conserva nel modello logico ID, faccia accettata, valore, appartenenza al tiro e stato `used`. Sul **bordo superiore** del libro/tray restano fino a sei **segnali o impronte leggibili** che rappresentano gli accantonamenti (per esempio piccole tessere, sigilli, dadi miniaturizzati o icone numerate), anche quando la rappresentazione grande del dado si è dissolta nel folio. Questo sostituisce il precedente parcheggio di sei grossi dadi come obbligo visivo, ma non elimina l'informazione necessaria al giocatore. Se il playtest dimostra che i segni non bastano, conservare l'opzione di mostrare copie grafiche dei dadi nel bordo superiore. Gli eventuali dadi tornati disponibili con hot dice ricompaiono nel tiro successivo; **le tracce a rischio e i punti provvisori del turno restano**. La dissolvenza non altera la fisica né genera o distrugge dadi nell'autorità del controller.

**Rapporto fra rischio, avversario e folio (direzione rivista).** Nella versione attuale l'incasso rende definitive porzioni di ornamento e il Farkle ritira soltanto il provvisorio: è il contratto del prototipo in funzione. Per i futuri incontri, la pagina **non deve più essere un misuratore da colorare fino a una soglia**. I punti non assicurati possono produrre tracce fugaci, ma la ricomposizione del folio avviene narrativamente quando la miniatura sconfitta torna alla propria sede; gli effetti scenici non decidono da soli la vittoria.

| Evento | Stato logico attuale | Direzione visiva per gli incontri |
|---|---|---|
| Lancio e selezione | Risultati fisici, scelta reversibile | Dadi leggibili sul libro; figura/minaccia visibile senza oscurare il tiro |
| Accantonamento | ID e gruppi conservati, punteggio provvisorio | Traccia temporanea o segnale leggibile dei dadi, non avanzamento automatico della vittoria |
| Incasso | Solo punti realmente assicurati | Impatto chiaramente presentato sullo stato dell'incontro, senza conversione numerica ancora fissata |
| Farkle definitivo | Perdita dei soli punti provvisori secondo le regole | Evidenziare la perdita senza cancellare progressi già assicurati |
| Incontro vinto | Non implementato | La figura rientra nel folio; breve ricomposizione della miniatura |
| Libro completato | Non implementato | L'insieme delle figure riconquistate chiude la run |

Le varianti «inchiostro che si fissa» e «dado che si dissolve» sono effetti possibili, non prerequisiti di combattimento né richieste di riscrivere la fisica.

**Principio di produzione:** la fisica 3D consolidata ha priorità sulla metamorfosi scenica. Apertura, bossolo/costola, dissoluzione e colorazione vanno realizzati mediante trasformazioni di presentazione, maschere e livelli grafici compatibili con il motore esistente, non modificando spawn, collisioni, corpi o lettura delle facce. La transizione non deve bloccare decisioni oltre il necessario, deve essere saltabile e deve poter terminare istantaneamente nello stato visivo corretto.

**Rischio artistico principale:** la miniatura avversaria, i Segni e l'ornamentazione potrebbero rendere i dadi poco leggibili o distrarre durante il lancio. Testare contrasto fra dado e pergamena, densità ornamentale, tempo di ogni transizione e comprensione dei dadi già accantonati. Se necessario, collocare l'ornamentazione soprattutto ai margini e far emergere i dettagli nella pausa fra un tiro e il successivo; non cambiare le regole per accomodare la scenografia.

## Gioco attuale

**Il Farkle Roguelite è l'applicazione principale**, non un esperimento. Avvio dalla radice con `love .` o `Avvia.cmd`, senza pacchetti o build. Splash, Main Menu, Settings e Choose Commission sono ripristinati. Il selettore contiene Farkle Roguelite e Back; non le vecchie commissioni placeholder. Continue è disabilitato: non esiste ancora un salvataggio riprendibile della run.

Il [regolamento ufficiale](FARKLE_RULES.md) sostituisce la vecchia scala numerica: singoli 10/5, tris e gruppi definiti in tabella, scale, tre coppie, full 4+2 e due tris. Le convenzioni per i valori intermedi sono dichiarate; obiettivi, limiti e soglie degli incarichi rimangono parametri di test.

Ciclo: commissione → lancio → selezione di gruppi disgiunti dello stesso tiro → accantonamento → incasso consentito o rilancio → Farkle/hot dice/consegna → ricompensa → incarico successivo. Il giocatore può sacrificare punti immediati per tenere più dadi nella riserva. Deve fare una selezione valida di ogni tiro prima di rilanciare o incassare. Ingresso e minimo incasso possono costringerlo a continuare: questa pressione va valutata, non presunta divertente.

Mini-run attuale: Salterio, Libro di ore, Codice. Gli ultimi due chiedono rispettivamente un gruppo di almeno tre uguali e hot dice **incassati**. La build persiste fra incarichi, punti e ingresso no. Nessuna valuta, negozio, IA avversaria o economia aggiuntiva è implementata. Le commissioni correnti sono **baseline tecnica e di confronto**, non la struttura finale dei futuri libri con miniature animate.

## Incontri e Segni — nuova direzione, non implementata

**Approvato come obiettivo di design:** un libro coerente per tema e iconografia ospita figure che prendono vita e devono tornare nel folio; superare tutte le figure previste porta alla vittoria della run. Il giocatore usa il Farkle attuale, mentre ogni avversario può avere proprie intenzioni e un sacchetto di azioni (*Segni*). HP, Vincoli, scudi, neutralizzazioni, danni, durate e probabilità **non sono ancora regole approvate**. La vittoria per solo esaurimento HP può essere troppo lineare, ma condizioni ottenibili con un solo tiro fortunato sarebbero altrettanto deboli. Non aggiungere complessità soltanto per evitarne l'apparente banalità.

**Principio ludico:** il nemico deve cambiare la posta del rischio e la convenienza di incassare o rilanciare; non punire sistematicamente ogni rilancio, non costringere sempre a cercare soglie e non trasformare i dadi in una valuta tattica. L'idea di manipolare il sacchetto è promettente per la memoria delle azioni e il compromesso tra neutralizzazione immediata e riciclo futuro, ma resta da validare contro un incontro con semplici HP. Design, esperimenti e criteri nel nuovo documento [Incontri con le miniature e sacchetti di Segni](INCONTRI_E_SEGNI.md).

**Rinviato:** Tarocchi/Trionfi. Non costituiscono la prima famiglia di avversari da produrre.

**Primo candidato sperimentale (30 ottobre 2026):** il *Duello delle Poste*, gara a mani Farkle contro Segni di forza variabile, è documentato in [Incontri e Segni](INCONTRI_E_SEGNI.md). Non è approvato come loop definitivo; va confrontato in simulazione con il controllo a HP prima di toccare scoring, HUD o fisica.

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

**Stato attuale:** il folio laterale mostra inchiostro stabile/provvisorio sulla base dei punti e degli obiettivi delle tre commissioni; i target e le condizioni di consegna descritte nel [regolamento](FARKLE_RULES.md) restano effettivi. Le precedenti proposte di colorazione progressiva per strati (rigatura, scrittura, iniziali, rubricatura, bordure, oro) sono utili come materiali di presentazione, **non** più come loop di vittoria della nuova direzione.

**Direzione futura:** il libro è anche lo spazio che contiene gli avversari. Una miniatura prende vita ed esce dalla pagina; al termine dell'incontro torna alla posizione originaria, così il folio si ricompone per elementi riconoscibili. Una run ha un libro con un proprio repertorio di figure: salterio con temi appropriati al contesto, eventuali altri libri con repertori differenti. L'ordine degli incontri, il numero di pagine, le ricompense e la condizione di completamento di ogni singolo incontro sono aperti. Il nemico non deve necessariamente essere un personaggio malvagio: può essere una figura, una prova o un ostacolo onirico.

**Contratto futuro da definire:** il punteggio resta determinato dalle regole Farkle, non dalla grafica; la rappresentazione dei dadi accantonati, dei punti non incassati e dell'intenzione nemica deve essere fedele e leggibile. Danni, neutralizzazioni e progresso dell'incontro non hanno ancora una conversione punti→effetto approvata. Il Farkle non deve cancellare figure già ricondotte al libro; la durata dei turni e la persistenza degli stati tra incontri non sono fissate.

**Ambiente storico e diritti:** bottega del XV secolo e sogno come cornice, non simulazione letterale di una pergamena animata. Ricercare iconografie pertinenti alla tipologia libraria e al periodo senza imporre una falsa uniformità. Usare asset originali o con licenza idonea, non trasferire immagini o codice proprietari dai riferimenti. La nuova direzione non autorizza il ripristino del vecchio puzzle cromatico.

## Interfaccia e verifica dell'esperienza

**Attuale:** vassoio e sei dadi protagonisti; barra unica per commissione, turni e incasso; manoscritto laterale; controlli contestuali in posizioni stabili. Clic o 1–6 selezionano, **Scelte** espone le alternative, Accantona e Incassa restano espliciti. Regole e folio si consultano senza abbandonare la run. Durante il movimento gli input di gioco sono bloccati.

**Direzione di interfaccia da prototipare:** un codice onirico aperto, insieme superficie del lancio e sede degli avversari. La costola può suggerire l'origine dei dadi; il folio lascia spazio alla miniatura animata e a pochi **Segni/intenzioni leggibili**, senza invadere il campo dei sei dadi. Sul bordo superiore rimangono tracce o impronte leggibili dei dadi accantonati. Una fascia informativa sottile comunica punti a rischio/incassati, minaccia avversaria e disponibilità di turni; i comandi Farkle conservano posizioni stabili (lancia/rilancia, accantona, incassa). Non aggiungere subito indicatori simultanei per HP, Scudo, Concentrazione, Vincoli e valute: la necessità di ciascuno va dimostrata nel playtest.

La versione attuale del libro-tray e le prove precedenti di dissoluzione in inchiostro rimangono riferimenti tecnici e artistici. Le transizioni devono essere brevi, saltabili e non influenzare risultato fisico o punteggio; l'eventuale ritorno della figura sul folio non deve interrompere il ritmo degli incontri.

La plancia allegata in precedenza è **riferimento di gerarchia e materialità**, non modello da riprodurre: evitare griglie, fazioni, simboli, colori e layout identificativi del gioco altrui. La pagina con bordura floreale è **riferimento di grammatica ornamentale**; le fotografie più recenti di libri/cofanetti da dadi, coperte decorate e interni apribili sono **riferimenti di forma, apertura e materiali**, non asset di cui presumere i diritti di redistribuzione né attestazioni storiche di un libro da gioco quattrocentesco. Preferire asset originali/licenziati, contrasto leggibile, materiali poco invadenti ed effetti da sogno molto discreti. Conservare un flusso immediato sul modello del Farkle da tavolo: lancia → scegli → accantona → rilancia o incassa. Non nascondere il comando di accantonamento se serve a distinguere selezione reversibile e conferma.

Verificare 1280×720 e 1920×1080, impostazioni persistenti, testo grande, input mouse/tastiera, gruppi sovrapposti consentiti dal Farkle, transizioni saltate, medaglie e folio. Le modifiche visuali non devono reintrodurre la vecchia meccanica cromatica né alterare il motore fisico 3D.

Playtest successivi: annotare provvisorio, dadi residui, soglia, condizione mancante, turni restanti, scelta e motivo. Confrontare controllo, inciso e pesato alternando l'ordine; annotare separatamente l'attesa del filtro pesato. Cercare decisioni che cambiano con lo stato, non solo maggiore difficoltà. Osservare se Scelte è utile o macchinoso, se le soglie forzano troppi rilanci, se il Correttore viene speso automaticamente. Le simulazioni isolate nel regolamento non dimostrano divertimento o strategie ottime.

## Vincoli e prossimi passi

Architettura corrente: `src/gameplay/farkle/` per regole; `src/features/farkle/` per controller e presentazione; `src/app/` per runtime; `src/engine3d/` per motore congelato. Contratti e limiti nel [documento tecnico](TECHNICAL.md). Non dipendere da `experiments/` né caricare gameplay cromatico da `legacy/`.

Non migrare framework, usare `love.physics` per i dadi 3D, ridimensionare dadi/vassoio o riaprire SAT dinamico senza bug concreto e autorizzazione. Non sacrificare il gesto fisico a una ricerca tecnica interminabile. Intrecci, Motivi contesi, Arte del rischio e Folio progressivo/roguelite sono storici, non parti del regolamento corrente.

**Priorità aggiornate al 30 ottobre 2026 (solo game design):** (1) definire **un singolo incontro completo** con condizioni di vittoria/sconfitta, gestione di incasso/Farkle e comportamento del sacchetto; (2) confrontare un controllo senza nemici, un nemico a HP semplici e uno con Intenzioni/Segni reattivi, osservando se cambiano le decisioni di rischio; (3) solo dopo valutare una manipolazione del sacchetto e la sua utilità reale; (4) se il loop è valido, progettare la progressione fra folii e ricompense dei dadi; (5) quindi pianificare l'integrazione con libro-tray, HUD e animazione della miniatura. **Nessuna implementazione del nuovo combattimento è autorizzata da questo documento**. Non modificare scoring o fisica 3D per renderlo più spettacolare.

Restano aperti: HP contro altri modelli di vittoria, quantità e pesi dei Segni, ordine/rivelazione delle intenzioni, costi-opportunità delle manipolazioni, eventuale Concentrazione del copista, ritmi e limiti degli incontri, scalata del nemico e struttura definitiva della run. La precedente priorità visiva «colorare progressivamente il folio» è superata come obiettivo principale, non cancellata come ricerca di feedback. Non avviare ancora Tarocchi/Trionfi, nuovi minigiochi o un catalogo esteso di boss.



## Biblioteca di progetto

Fonti consultate o allegate, non garanzia di lettura integrale né di adozione:

- **Design:** Tynan Sylvester, *Designing Games* (decisioni e conseguenze); Matt Hackett, *How to Make a Video Game All By Yourself* (gesto centrale, scope e playtest); John Harris, *Exploring Roguelike Games* (sistemi e rigiocabilità); Kameron e Frahaan Hussain, *The Art and Science of Game Development*; *Game Design Toolkit*. Nessun manuale certifica il bilanciamento.
- **Storia e immagini:** Sara J. Charles, *The Medieval Scriptorium*; Richard Hayman, *Illuminated Manuscripts*; Tymms e Wyatt, *Masterpieces of Illuminated Letters and Borders*; *Common Medieval Pigments*; *Come un copista medievale*; tavola comparativa dei pigmenti storici. Verificare epoca, area e permessi delle immagini; la carolina non è una grafia universale del XV secolo.
- **Giochi e riferimenti visivi:** Farkle/KCD2 e Squire's Dice per lancio fisico e immediatezza; Dice Forge per facce identificabili; Balatro per build e feedback causale; Biblios e Biblios: Quill and Parchment per obiettivi librari; Trismegistus per relazioni fra selezione e azioni. Il concept della mod cooperativa *Star Realms Boss Fight* (2020) e il codice Lua Tabletop Simulator di P4ND0RA, condivisi in discussione, sono riferimenti per IA asimmetrica e sacchetto a esaurimento: non regole già adottate né codice del progetto. La plancia lignea, la pagina ornata e le fotografie del libro/cofanetto apribile fornite dall'utente sono riferimenti di struttura, materiali, apertura e lessico figurativo, non autorizzazioni a copiarne gli asset. I riferimenti non autorizzano aste, moltiplicatori o nuovi sottosistemi per analogia.

Le ricerche tecniche originali sono nell'[indice storico](../legacy/README.md); i materiali allegati non sono necessariamente distribuiti nel repository.

### Consolidamento tecnico senza nuove regole (ottobre 2026)

La stabilizzazione ha separato i limiti e le condizioni delle commissioni dalle regole dei dadi e ha chiarito il confine fra lanci fisici e lanci **accettati**. Non sono state introdotte nuove combinazioni, modifiche di probabilità né avversari. Il Duello delle Poste rimane una proposta di prototipo documentata, non la regola della run attuale.

