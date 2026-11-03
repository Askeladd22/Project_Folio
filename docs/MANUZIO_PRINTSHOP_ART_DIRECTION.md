# Project Folio — Bottega editoriale alla Manuzio

**Direzione artistica approvata · 3 novembre 2026.** L'immaginario del
menu diventa quello di una **bottega editoriale-tipografica veneziana
fra la fine del Quattrocento e l'inizio del Cinquecento**, ispirata ad
Aldo Manuzio, non uno *scriptorium* monastico.

## Nuove reference di produzione — miniatura + Flameng

La direzione visiva è stata affinata usando una miniatura con
torchio e collaboratori e un dipinto storico di François Flameng
come **reference per luce e spazio**. La miniatura guida i
gesti del lavoro e la gerarchia cromatica; Flameng guida la
finestratura, l'aria e la disposizione ambientale.
**Non copiare le opere come layout finito**.

**Nota storica:** il dipinto di Flameng non risale al 1840.
Il Grolier Club cataloga uno studio attorno al 1894 e avverte
che l'incontro veneziano raffigurato è una licenza artistica:
la visita attestata di Manuzio e Grolier fu a Milano nel 1511.

**Documento di produzione con prompt, layout e checklist:**
[MANUZIO_REFERENCE_SYNTHESIS.md](MANUZIO_REFERENCE_SYNTHESIS.md).

## Scena

Officina del libro urbana: correttore umanista al tavolo delle bozze,
compositore con cassa di caratteri mobili, stampatore al torchio, fogli
in asciugatura, piccoli volumi, attrezzi e luce naturale da una finestra
su Venezia. Abiti rinascimentali, poche figure concentrate sul lavoro,
nessun monaco o iconografia religiosa come protagonista.

**È un'interpretazione artistica, non la ricostruzione attestata
di una bottega effettivamente appartenuta a Manuzio.**

## Linguaggio pittorico

Adottare le quattro reference fornite dal team: contorno a inchiostro
leggibile, colori opachi e smorzati, gerarchia del dettaglio, forme e
materiali riconoscibili. Mantenere la palette di
`src/data/art_palette.lua`: pergamena `#E7DCC8`, inchiostro
`#352A23`, salvia `#8E957B`, rosso `#8D4B43`, ardesia
`#6F8087`, ocra `#BE9A4F`. Niente fotorealismo, bloom,
ornamenti casuali o scritte illeggibili messe in primo piano.

## Fondale prodotto

**`ProjectFolio_Bottega_Manuzio.zip`**, disponibile come allegato
nella conversazione. Contiene:

- `resources/ui/menu_manuzio.png`, **1920×1080**, senza testo UI,
  titolo o pulsanti disegnati nell'immagine
- `MENU_ASSET_README.txt`, con informazioni e SHA-256

**SHA-256 del PNG:**
`65e6748253a54dc58486b73cd3cea1a772e8a033509baaf1243240bcaa858d15`.

Il **primo 32,5% a sinistra** è intenzionalmente più tranquillo per
il menu interattivo. Il centro-destra ospita i lavoratori e la
tipografia. Il crop su schermi stretti conserva la zona di navigazione.

## Integrazione da v0.1.8

Main Menu, Settings e commissioni caricano nell'ordine:

1. `resources/ui/menu_manuzio.png` — nuova scena
2. `resources/ui/menu_illustrated.png` — precedente illustrazione
3. `resources/ui/menu.png` — fallback storico

**Aggiornamento 0.1.9:** il PNG è ora **incluso in GitHub**
nel percorso corretto `resources/ui/menu_manuzio.png`, usando
l'identico file approvato (SHA-256 invariato). Il precedente upload,
salvato con il nome lungo `ProjectFolio_Manuzio_Bottega_1920x1080.png`,
è stato rinominato senza ricodificare i pixel.

```powershell
git pull --ff-only
.\Avvia.cmd
```

`resources/ui/menu_illustrated.png` non è più incluso in
`main`, per scelta artistica; il loader continua a tollerarlo
come fallback locale. `resources/ui/menu.png` è il fallback
effettivamente incluso nel repository.

Il codice LÖVE continua a rendere titolo, pulsanti, hover e footer
separatamente. Nessuna modifica a Farkle, dadi 3D/g3d, fisica,
audio, input e salvataggi.

## Controlli Windows non ancora eseguiti

Verificare 1280×720, 1920×1080, 2560×1440, 4:3, high contrast e
big text: nessun clipping delle sei voci, nessuna interazione persa,
e visibilità del torchio e dei compositori. La coerenza tipografica
umanistica (romano/corsivo anziché gotico diffuso) sarà valutata in
una fase successiva.

## Fonti storiche di contesto

- [Treccani, Dizionario Biografico — Aldo Manuzio](https://www.treccani.it/enciclopedia/manuzio-aldo-il-vecchio_%28Dizionario-Biografico%29/)
- [Biblioteca Casanatense — Le edizioni aldine](https://casanatense.cultura.gov.it/attivita/editoriali/le-edizioni-aldine-della-casanatense/)
