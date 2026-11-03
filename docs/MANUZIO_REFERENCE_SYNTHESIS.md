# Project Folio — sintesi delle reference per il fondale della bottega

**Revisione artistica: 3 novembre 2026** · **Versione documentale: 0.1.10**

**Stato:** specifica di produzione per la **prossima iterazione
dell'illustrazione**. Non equivale a una nuova immagine già integrata.
Il fondale correntemente distribuito resta
`resources/ui/menu_manuzio.png` (0.1.9), finché una nuova tavola
non viene realizzata, collaudata e approvata.

## Le due reference: contributi distinti

**Reference A — miniatura con bottega tipografica e torchio,
condivisa dal team.** Rilevanti:
- il torchio e i gesti di stampa sono immediatamente riconoscibili;
- lavoratori, lettori e fogli raccontano operazioni differenti;
- prospettiva semplificata, geometrie leggibili e materia del legno;
- blu intensi e rossi negli abiti, concentrati su pochi punti;
- gerarchia dei dettagli e incorniciatura architettonica, non
  riproduzione letterale dei capitelli o dell'immagine di origine.

**Reference B — François Flameng, *Grolier in the House of Aldus*
(serie di opere e studi di fine Ottocento).** Rilevanti:
- finestratura ampia e luce naturale diffusa;
- percezione urbana e veneziana, non una cella monastica;
- grande torchio in secondo piano a destra, come struttura spaziale;
- atmosfera umanistica e relazione fra libri, lettori e stampa;
- ordine di masse, aria e spazio libero, non l'effetto pittorico
  accademico ottocentesco né i costumi letteralmente copiati.

**Avvertenza storica verificata:** attribuire questo dipinto al **1840**
è errato: Flameng nacque nel **1856**. Il Grolier Club cataloga uno
**studio datato circa 1894**. Secondo il Grolier Club la raffigurazione
dell'incontro nella tipografia veneziana è una *licenza artistica*:
Manuzio e Grolier si incontrarono invece a **Milano nel 1511**.
Non rappresentare dunque la visita di Grolier al torchio di Venezia
come un episodio storicamente attestato. L'immagine serve a studiare
**luce/composizione** e non a ricostruire un evento.

Fonti di attribuzione/contesto (non asset da copiare):
- [Grolier Club — Portraits, Grolier in the House of Aldus](https://grolierclub.omeka.net/exhibits/show/aldus-manutius/portraits)
- [Wikimedia Commons — file attribuito a François Flameng](https://commons.wikimedia.org/wiki/File:Aldus_in_His_Printing_Establishment_at_Venice_Showing.jpg)

## Composizione narrativa: 1920×1080, asset senza UI

| Zona orizzontale | Funzione | Indicazione |
|---|---|---|
| **0–32,5%** | Spazio per menu LÖVE | parete chiara, architettura morbida, poco contrasto, nessuna figura o testo |
| **32,5–60%** | Transizione / lavoro sul testo | banco con fogli, bozze, correttore seduto, tavole leggibili |
| **60–85%** | Centro della bottega | compositore presso cassa dei caratteri mobili e un garzone; linee orientate verso il lavoro |
| **85–100%** | Torchio / profondità | torchio manuale a vite in legno, figura impegnata, finestra e scorcio veneziano sfumato |

Sono **orientamenti di produzione**, non posizioni di hitbox:
il software già dimensiona la UI e mantiene il crop ancorato a sinistra.
Il soggetto non deve richiedere che il pannello si sposti.
Non collocare volti, mani o caratteri tipografici importanti sotto
il primo terzo dello schermo. Verificare anche il 4:3, che taglia
parte della zona destra.

### Gestualità prima del dettaglio

- Un **correttore** verifica fogli/prove con segni discreti;
- un **compositore** seleziona tipi da scomparti e allinea le righe;
- uno **stampatore** lavora al torchio manuale a vite;
- eventuale **garzone** trasporta un piccolo fascicolo, non posa
  davanti alla camera.

Concentrarsi su **due o tre azioni** chiaramente distinguibili
a dimensione di menu; evitare sei personaggi immobili e decorazioni
tipografiche senza funzione.

## Stile e colore

**Tratto:** illustrazione narrativa rinascimentale stilizzata;
line art sottile, campiture opache, ombre di 2–3 toni, bordi e
materiali credibili. Forme intenzionali e dettagli selettivi.
Non copiare né composizione, né volti, né ornamenti delle reference.

**Luce:** naturale laterale attraverso finestre a piccoli vetri,
uniforme e luminosa, senza glow cinematografico o controluce
drammatico. Lo scorcio veneziano deve essere una *suggestione*
architettonica, non la veduta inventata da Flameng spacciata
per documento storico.

**Pigmenti:** usare `src/data/art_palette.lua`. Fondi neutri
in pergamena `#E7DCC8`, calce `#DCD5C8`, legno
`#856448`, salvia `#8E957B`; **rosso mattone `#A85F52`**
e **blu ardesia `#6F8087`** come accenti leggibili su
abiti/fascicoli, **ocra `#BE9A4F`** per pochi dettagli.
La reference miniata dimostra che la palette non deve essere
appiattita fino a diventare uniformemente grigia.

**Non includere:** scriptorium religioso, monaci, volto di Grolier,
visita di Grolier ricostruita come fatto, elementi fantasy,
torchi industriali moderni, fotografie elaborate con filtri,
micro-dettaglio disordinato, oro metallico ovunque,
testo senza senso, iscrizioni inventate, vignettatura forte,
logo o pulsanti dipinti dentro l'immagine.

## Prompt di produzione — copiabile

> Illustrazione originale panoramica 16:9 (1920×1080) per lo sfondo
> del menu di Project Folio. Interno di una piccola bottega
> tipografica veneziana tra la fine del XV e l'inizio del XVI secolo,
> ispirata alla cultura editoriale di Aldo Manuzio, **senza raffigurare
> alcun incontro storico specifico**. Tono colto e operoso:
> correttore umanista che legge bozze al centro, compositore che
> lavora a una cassa di caratteri al centro-destra, stampatore
> presso un torchio ligneo manuale a vite sulla destra; fascicoli,
> libri e fogli in lavorazione. Ampia finestra con luce veneziana
> naturale morbida, volumi architettonici semplici. Ispirazione
> narrativa dalle miniature della stampa rinascimentale e, per
> la qualità spaziale e luminosa, dai dipinti storici ottocenteschi,
> **senza riprodurne la composizione**. Line art fine e intenzionale,
> texture carta appena percepibile, campiture opache, palette
> pergamena, salvia, calce, bruno legno, rosso mattone, blu ardesia
> e ocra come accento. Esattamente il primo 32,5% del frame a sinistra
> deve essere calmo, chiaro, privo di personaggi, strumenti
> importanti e scritte: lì il gioco renderizza il menu interattivo.
> Centro e destra leggibili anche in piccolo, silhouette
> comprensibili, dettagli selettivi, nessuna posa teatrale.
> Nessun logo, lettering, pulsante, falsa UI, monaco, monastero,
> apparecchiatura industriale moderna, fotorealismo,
> illuminazione cinematografica, bloom o fantasy generico.

## Criteri di accettazione (prima del merge di un nuovo PNG)

1. **Soggetto:** almeno correttore, compositore e stampa riconoscibili
   da silhoutte/gesto a un quarto della risoluzione nativa.
2. **Composizione:** nessun soggetto narrativo nel primo 32,5%;
   verificare cattura con menu reale e sei pulsanti.
3. **Coerenza:** finestra e torchio non competono con il titolo;
   palette coerente con `art_palette.lua` ma non monocroma.
4. **Storicità:** documentare eventuali semplificazioni; evitare
   l'incontro Grolier–Manuzio come falsa documentazione veneziana.
5. **Tecnica:** PNG 1920×1080 senza UI incorporata; verificare
   resa LÖVE 1280×720, 1920×1080, 2560×1440, 4:3, high contrast,
   big text e continuità Menu → Settings → Commissioni.
6. **Regressioni:** gameplay, g3d, fisica e input invariati;
   nessun cambio a `resources/ui/menu_manuzio.png` senza
   approvazione visiva e test su Windows.

**Regola di consegna:** prima approvare la tavola come immagine
separata, poi aggiornare l'asset del repository in una PR specifica.
La documentazione da sola non dichiara completato il nuovo fondale.
