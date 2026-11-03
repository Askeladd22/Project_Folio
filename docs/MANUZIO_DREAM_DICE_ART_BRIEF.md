# Project Folio — Bottega, azzardo e sogno: brief del menu V2

**Revisione:** 3 novembre 2026 · **Stato:** specifica di produzione,
non artwork già approvato né funzionalità implementata.

**Tesi visiva:** una bottega tipografica veneziana, ispirata alla
cultura del libro attorno ad Aldo Manuzio, nella quale un
lavoratore ossessionato dal prossimo tiro **sogna** che i fogli,
i dadi e i caratteri mobili partecipino allo stesso gioco.
Il giocatore deve percepire «rischio o mi fermo?» prima di leggere
un pulsante. Il sogno non deve diventare una scena fantasy generica.

Questo brief integra, senza sostituirli:
- [MANUZIO_REFERENCE_SYNTHESIS.md](MANUZIO_REFERENCE_SYNTHESIS.md)
  (miniatura: lavoro e segni; Flameng: luce e spazialità);
- [GAME_DESIGN.md](GAME_DESIGN.md) (cornice bottega → azzardo serale →
  sogno; Farkle fisico, sei dadi e decisione di incassare/rilanciare);
- [ART_DIRECTION.md](ART_DIRECTION.md) e palette
  `src/data/art_palette.lua`.

## I tre piani dell'immagine

### I — Bottega reale (ancoraggio storico)

Una piccola officina editoriale tipografica, non uno scriptorium
monastico: finestre veneziane luminose, tavolo per la revisione,
bozze, legature, cassa dei caratteri e un torchio manuale ligneo.
Due o tre lavoratori concentrati sul compito, non un gruppo
che posa per lo spettatore. Le masse e gli oggetti grandi sono
credibili anche in miniatura.

L'ambientazione **non raffigura una bottega documentata di
Manuzio** e non attribuisce al personaggio storico il gioco
dei dadi. L'eventuale azzardo visibile è una **metafora
narrativa originale**: non una ricostruzione della pratica
del Farkle nella Venezia del 1500.

### II — La tentazione del rilancio (soggetto emotivo)

**Centro narrativo: una mano esitante.** Sul primo piano, appena
a destra della zona riservata alla UI, un lavoratore sospende
le dita sopra **sei dadi distinguibili** su una piccola
superficie di legno/carta. È il momento **prima di decidere**
se rischiare di nuovo o fermarsi, non un lancio celebrativo.

Composizione consigliata: tre dadi vicini alla mano e tre
leggermente separati sulla stessa superficie, con volumi e
punti leggibili a dimensione ridotta. Questa disposizione è
**iconografica**, non il risultato di un tiro né una nuova
regola Farkle. Evitare combinazioni di facce interpretate
come punteggi reali: non usare numerazioni tipografiche
inventate, token di casinò, monete-premio o contatori finti.

Un foglio di bozza con **pochi tratti di correzione**
mette in relazione la decisione del correttore e quella
del giocatore: ciò che è «in lavorazione» potrebbe essere
confermato oppure perduto. Non dipingere testo o HUD
con valori numerici sopra il foglio.

### III — Il sogno che quasi non si vede

Usare **un'anomalia principale** e al massimo
**un indizio secondario**, non un catalogo di magie.

**Anomalia principale proposta:** il bordo del foglio di
bozza si piega impercettibilmente fino a suggerire
il margine di un piano da lancio; ombra e venature
del legno sembrano proseguire nei tratti d'inchiostro.
È possibile interpretarlo come coincidenza della
prospettiva oppure come trasformazione del sogno.

**Indizio secondario facoltativo:** un carattere mobile
fuori posto proietta sulla carta un'ombra che ricorda
una minuscola figura miniata; oppure una lettera
sembra affacciarsi appena da una bordura. Non usare
insieme entrambe le opzioni. Nessuna creatura nuova
deve essere dichiarata «implementata».

La luce resta quella naturale delle finestre:
l'estraneità nasce dalla relazione impossibile
tra **carta, dado e inchiostro**, non da raggi,
particelle, nebulose, portali o effetti neon.

## Composizione di produzione — 1920×1080

| Zona orizzontale | Ruolo visivo | Contenuto |
|---|---|---|
| **0–32,5%** (0–624 px) | Zona sicura UI | parete calda, ombra morbida, nessun dado, mano, volto, testo o particolare indispensabile |
| **32,5–58%** (624–1114 px) | Tentazione / primo piano | bordo del tavolo, **sei dadi**, mano sospesa, foglio di prova che quasi diventa tray |
| **58–81%** (1114–1555 px) | Lavoro editoriale | correttore/compositore e cassa dei tipi, leggibilità dei gesti |
| **81–100%** (1555–1920 px) | Architettura e stampa | torchio, figura al lavoro, finestra; parti secondarie possono essere tagliate dal crop 4:3 |

**Attenzione al 4:3:** il loader ancora a sinistra il cover
e può tagliare l'estrema destra. Il **torchio deve
essere ancora riconoscibile nella zona 68–88%**, per quanto
possibile, non soltanto come dettaglio al 95–100%.
Queste fasce sono vincoli di progettazione della nuova
immagine, non coordinate dell'interfaccia o delle hitbox.

**Gerarchia percettiva:** (1) mano + dadi, (2) attività
tipografica e torchio, (3) ombre/impossibilità del sogno,
(4) accessori secondari. Chi guarda per due secondi
deve capire che questo è un **gioco dei dadi in un'officina
del libro**, non un documentario sulla stampa.

## Materiali, colore e forma

Conservare i pigmenti della palette implementata:
- superficie `#E7DCC8`, inchiostro `#352A23`,
  legno `#856448`, salvia `#8E957B`;
- accenti localizzati in rosso mattone `#A85F52`
  e blu ardesia `#6F8087` su stoffe/fascicoli;
- pochissima ocra `#BE9A4F` su metallo/legatura.

Contorno sottile intenzionale, campiture opache,
ombre comprensibili, irregolarità artigianali
senza finto rumore da pergamena su ogni superficie.
I dadi devono avere **volume e sei facce di oggetto**,
non sembrare icone generiche. La scena può suggerire
la futura unione fra folio e tray, ma **non modifica**
la geometria o il materiale dei dadi g3d reali.

**Da escludere:** saio/monastero, persona reale di
Manuzio come giocatore, carte da poker, fiches,
slot machine, denaro sparso come premio, punteggi
stampati, dadi giganti, apparizioni fantasy, oro
lucido generico, figure senza anatomia credibile,
mani moltiplicate, caratteri pseudo-tipografici,
cornici invadenti, decorazioni seriali, effetti
fotografici, bagliori e sfondi troppo scuri.

## Prompt di produzione V2

> Illustrazione originale 1920×1080 per il menu di
> **Project Folio**. Piccola bottega editoriale-tipografica
> veneziana fra tardo Quattrocento e primo Cinquecento,
> ispirata alla cultura del libro di Aldo Manuzio:
> torchio manuale ligneo, compositore con cassa dei
> caratteri, correttore alle bozze, ampie finestre
> con luce naturale diffusa; nessun monaco.
> **Tema principale: la tentazione di rischiare un altro tiro.**
> In primo piano, al centro-sinistra fuori dall'interfaccia,
> una mano sospesa nell'attimo di decidere sopra **sei
> dadi a sei facce**, chiaramente distinguibili; alcuni
> vicini, altri separati su un piccolo vassoio/piano.
> Sotto e accanto, un foglio di bozza diventa in modo
> quasi impercettibile lo stesso piano dei dadi,
> mescolando legno, carta e tratti d'inchiostro.
> Una sola ambiguità onirica ulteriore, piccolissima:
> l'ombra di un carattere mobile sembra una figura
> miniata. Il sogno deve poter essere scambiato per
> una coincidenza visiva. Il primo **32,5% del quadro
> a sinistra è vuoto, quieto, chiaro**, destinato
> interamente ai pulsanti LÖVE del menu. Concentrare
> mano, dadi e fogli entro il 32,5–58%; lavoro dei
> compositori nella parte centrale; torchio in
> centro-destra, ben visibile anche con crop 4:3.
> Stile di tavola narrativa rinascimentale con
> contorni a inchiostro, pigmenti opachi, luci
> naturali, toni pergamena/salvia/coccio/ardesia.
> Un'illustrazione pensata e artigianale, senza
> copiare quadri o miniature esistenti. **Nessun
> testo, logo, pulsante, HUD, casino, moneta-premio,
> magia vistosa o personaggio storico che gioca**.

## Verifiche e condizioni di accettazione

- [ ] A colpo d'occhio si riconoscono **sei dadi**, gesto
      di esitazione e attività di stampa (non soltanto
      un generico laboratorio storico).
- [ ] L'azzardo si legge come **rischio e decisione**, non
      come ricchezza o casino moderno.
- [ ] Il sogno contiene al massimo **due anomalie sottili**;
      senza la descrizione, qualcuno potrebbe
      interpretarle come normali dettagli della scena.
- [ ] Nel **primo 32,5%** non compaiono elementi essenziali
      o UI dipinta; l'immagine non contiene scritte
      prive di significato.
- [ ] Figure, mani, dadi e torchio restano leggibili
      in una miniatura al **25%** della risoluzione.
- [ ] A 16:9 e nel crop 4:3 la scena non perde
      contemporaneamente dadi e torchio.
- [ ] Sovrapposizione con il **vero menu LÖVE** senza
      copertura di soggetti o clipping dei pulsanti.
- [ ] Prove Windows a 1280×720, 1920×1080,
      high contrast e big text; screen capture
      e annotazioni visive archiviate.
- [ ] Nessuna modifica a Farkle, score, probabilità,
      dadi g3d, fisica, audio, input o salvataggi.

**Gate di produzione:** creare una tavola V2
**separata** e mostrarla al team prima di sostituire
`resources/ui/menu_manuzio.png`. La CI verde
controlla codice e file, **non** il gusto
artistico. Il PNG corrente rimane invariato
finché una revisione visiva esplicita non ne
autorizza la sostituzione.
