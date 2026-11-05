# Project Folio — direzione artistica 2.0

> **Aggiornamento 3 novembre 2026:** il fondale principale è ora una
> **bottega editoriale-tipografica veneziana ispirata ad Aldo Manuzio**
> (circa 1495–1510), non uno scriptorium monastico. La palette
> dei pigmenti e il tratto illustrato restano validi.
>
> Il documento vincolante per la composizione della nuova scena è
> [MANUZIO_PRINTSHOP_ART_DIRECTION.md](MANUZIO_PRINTSHOP_ART_DIRECTION.md).
> L'identità centrale unisce **officina rinascimentale, dadi e
> onirismo sottile**. Il brief operativo è
> [MANUZIO_DREAM_DICE_ART_BRIEF.md](MANUZIO_DREAM_DICE_ART_BRIEF.md).
> Le nuove reference per torchio, lavoro e luce veneziana, con
> note sulla licenza artistica di Flameng, sono raccolte in
> [MANUZIO_REFERENCE_SYNTHESIS.md](MANUZIO_REFERENCE_SYNTHESIS.md).
> Dalla **v0.1.9** `resources/ui/menu_manuzio.png` è incluso
> nel repository. Il percorso `menu_illustrated.png` resta
> opzionale per vecchie installazioni, mentre `menu.png`
> è il fallback incluso. Non ripristinare lo scriptorium
> come scena principale.
> Il testo seguente conserva anche i riferimenti alle fasi precedenti.

**Stato:** palette tecnica implementata nella v0.1.5. La direzione
nasce dalle quattro reference pittoriche condivise dal team:
paesaggio tardo-medievale, abitato, interno e bottega copista.

## Principio

Un **manoscritto illustrato che prende vita**, non un render fantasy
fotografico. Fondi con campiture opache e contorno intenzionale;
gerarchia leggibile, pigmenti terrosi, dettagli selettivi. Trattare
la storia come materia visiva: carta, inchiostro, legno, intonaco,
pietra, lino e pigmenti opachi; niente bloom o metalli lucidi generici.

La palette è un **vincolo di produzione**, non una richiesta di
desaturare brutalmente ogni texture. Le reference non autorizzano
a copiare personaggi/composizioni di altri illustratori.

## Dadi base in osso inciso — riferimento del 5 novembre 2026

Il riferimento fotografico approvato mostra dadi color osso invecchiato,
con superfici crema/miele, patina tenue, piccoli pori e spigoli consumati.
I punti sono cavità scure circondate da anelli incisi nella stessa materia.

Le facce opposte dei dadi comuni seguono le coppie **1/6, 2/5 e 3/4**.
La mappa fisica è `{1,6,3,5,4,2}`; il test verifica le tre coppie
sulle facce geometricamente opposte. La build incisa modifica
intenzionalmente la faccia 2 del primo dado in 1.

Il materiale ivory calcola superficie e incisioni nel frammento g3d.
Il valore visualizzato arriva dalla mappa effettiva della faccia;
la patina dipende dall'ID del dado e resta stabile durante la rotazione.
Lo smusso grafico deriva dalla geometria fisica. Le miniature
degli accantonamenti usano lo stesso materiale.

Lo smoke `PROJECT_FOLIO_BONE_DICE_SMOKE=1` verifica le sei facce,
le incisioni, il renderer e i ritratti con LÖVE/Mesa in CI.
Su Windows confrontare il risultato con la foto a 720p/1080p/1440p,
inclusi i dadi piccoli a fondo tavolo e quelli accantonati.

## Scala cromatica canonica

Il file autoritativo è `src/data/art_palette.lua`, usabile
in puro Lua senza caricare LÖVE:

| Ruolo | HEX | Utilizzo |
|---|---|---|
| Carta / UI | `#E7DCC8` | pannelli, folio |
| Carta secondaria | `#D8C9B1` | righe e layer |
| Calce | `#DCD5C8` | intonaco e fondi |
| Pietra | `#BFB4A1` | sfondo neutro |
| Inchiostro | `#352A23` | testo principale |
| Terra | `#6E533C` | testo secondario |
| Legno | `#856448` | bordi e travi |
| Salvia | `#8E957B` | elementi naturali |
| Oliva | `#72785C` | profondità, vegetazione |
| Verde bosco | `#59604A` | accenti positivi |
| Rosso coccio | `#C38B7A` | tessuti, pareti |
| Mattone | `#A85F52` | miniature e tetti |
| Cinabro | `#8D4B43` | pericolo e perdita |
| Blu ardesia | `#6F8087` | acqua, ombre e selezione |
| Blu inchiostrato | `#4F5E66` | focus UI |
| Ocra spenta | `#BE9A4F` | reward e segnalazioni |
| Ocra chiara | `#D4B66A` | evidenza puntuale |

Percentuali indicative, non limiti software: ~75% colori di
superficie/naturali, ~20% differenziazione di scena e ~5% accenti
funzionali. Non usare rosso/verde come unica codifica di stato.

## Implementazione e limiti

Da v0.1.5: `menu_surface.lua`, menu principale, HUD Farkle
e dialoghi condividono le stesse sorgenti cromatiche. Gli
indicatori dei dadi continuano a usare colori molto leggibili,
soprattutto in modalità alto contrasto. Gli elementi fisici
g3d, gli asset esistenti, la fisica, i salvataggi, l'audio
e la leggibilità delle facce dei dadi **non vengono modificati**.

### Seconda fase — fondale illustrato (integrazione 0.1.6)

Il loader condiviso supporta **`resources/ui/menu_illustrated.png`** su
Main Menu, Settings e selezione commissioni: se l'immagine è presente e
LÖVE riesce a caricarla, la preferisce allo sfondo legacy
`resources/ui/menu.png`. Se manca o è corrotta, mantiene l'immagine
precedente e non interrompe il gioco.

La prima illustrazione 1920×1080 era distribuita come **asset
separato** durante la sperimentazione 0.1.6–0.1.7.
È stata rimossa da `main` dopo la scelta della bottega
alla Manuzio, ora incorporata in `menu_manuzio.png`. Il pacchetto ZIP fornito nella
conversazione contiene già il path `resources/ui/menu_illustrated.png`.
Installare lo ZIP dalla root del repository con
`python scripts/install_menu_art.py PERCORSO_ZIP`, poi verificare
con `python scripts/install_menu_art.py --verify-installed` e
riavviare LÖVE. Il controllo dell'immagine è documentato in
[MENU_ART_INSTALLATION.md](MENU_ART_INSTALLATION.md).

Da **0.1.7** il pannello si restringe automaticamente nel margine
illustrato (~32,5% a sinistra) e a 4:3 il ritaglio preserva il lato
riservato all'UI. La nuova illustrazione mantiene il proprio colore,
mentre lo sfondo precedente conserva la sua color correction.
Non sostituire `menu.png` e non incorporare pulsanti o lettering
nell'immagine: il software li disegna dinamicamente, anche a 720p.

I passaggi di QA prima di committare l'asset sono descritti in
[WINDOWS_TECHNICAL_QA.md](WINDOWS_TECHNICAL_QA.md). Non confondere la
**preparazione del supporto** con la presenza dell'asset nel repository.

### Terza fase — asset definitivi

1. Definire l'immagine guida della bottega con **bozzetto di
   composizione**, focal point, spazio negativo per il pannello
   sinistro e luci piatte; approvare prima di sostituire
   `resources/ui/menu.png`.
2. Passare a scene con line art e colori opachi ispirati
   ai processi del XV secolo. Sfondi e oggetti vanno
   illustrati intenzionalmente, non ottenuti con filtri
   indiscriminati su render fotorealistici.
3. Coordinare texture del folio, vassoio, dadi e miniature
   con la palette senza perdere volume e leggibilità 3D.
4. Collaudare su Windows in LÖVE a 720p/1080p/1440p,
   con high contrast e big text, fotografando anche la
   scena in movimento. **CI verde non sostituisce l'audit visivo.**

## Regole di giudizio

Il risultato dovrebbe sembrare prodotto da un illustratore
con una logica di forma e colore. Verificare coerenza storica,
spazio per il gameplay, leggibilità di tutte le interazioni e
identità riconoscibile anche in un fermo immagine senza titolo.
