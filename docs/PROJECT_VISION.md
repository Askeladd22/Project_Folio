# Project Folio — visione di riferimento (brainstorming)

**Stato:** direzione narrativa e principi di design confermati il 4 novembre 2026.
**Non è una descrizione delle feature implementate.**
Per la build corrente consultare [README](../README.md),
[regole Farkle](FARKLE_RULES.md), sorgenti e test.

## Ambientazione e incipit — confermati

- **Luogo ed epoca:** Venezia, fine XV / inizio XVI secolo.
- **Lavoro del protagonista:** artigiano illustratore e incisore di
  matrici xilografiche presso la tipografia di **Aldo Manuzio**.
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

La partita attuale usa commissioni e include, separatamente,
`Sfida il Monaco (beta)`, duello **simmetrico** Farkle.
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

## Stato della presentazione — 0.1.14

Il tavolo Farkle della partita normale è stato semplificato: nessuna
sidebar di commissione/folio/strumenti, sei dadi fisici in uno spazio
più ampio, punteggi assicurati/a rischio e azioni essenziali.
**È una revisione UI, non la nuova meccanica di encounter.**
Gli obiettivi delle vecchie commissioni rimangono nel gameplay
provvisorio e nel folio accessibile con **F**.
La Sfida il Monaco beta resta temporaneamente separata.
