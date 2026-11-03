# Project Folio — direzione artistica 1.0

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

### Seconda fase — asset authored

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
