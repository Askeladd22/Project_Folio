# Tipografia — Aldine Aetna e Cardo

Project Folio riprende il carattere romano inciso da **Francesco Griffo**
per `De Aetna`, pubblicato da **Aldo Manuzio nel 1496**. Il carattere
principale è **Aldine Aetna Regular**, facsimile prodotto nel 2026 da
Source Library a partire dalle impressioni delle lettere conservate.
Non è una riproduzione dei punzoni di metallo in sé, ma una digitalizzazione
delle loro tracce sulla carta.

**Font principale:** `resources/font/AldineAetna-Regular.ttf` — CC0.
Fonte e licenza: https://sourcelibrary.org/articles/aldine-roman

**Font secondario:** `resources/font/Cardo-Regular.ttf` — SIL Open
Font License 1.1 (copyright e termini nel relativo `OFL-Cardo.txt`).
Progetto: https://github.com/google/fonts/tree/main/ofl/cardo

## Comportamento in LÖVE

Tutte le schermate di produzione caricano i font tramite
`src/core/typography.lua`. La chiamata `Typography.load(path, pixelSize)`
crea il font Aetna e un'istanza Cardo della **stessa dimensione**, poi
chiama `Font:setFallbacks(cardoFont)` sul font principale.

Questo permette di sostituire soltanto i glifi che non appartengono
all'Aetna (accenti, punteggiatura, simboli e lettere moderne dove
necessario), mantenendo il resto del testo nel carattere storico.

Se una stringa contiene glifi non presenti **in nessuno dei due**
font, non esiste una terza risorsa sostitutiva: tali simboli vanno
identificati nel collaudo e resi tramite asset vettoriali o font
aggiuntivi con licenze appropriate, anziché lasciare quadratini vuoti.

**Nota tecnica:** l'Aetna comprende varianti contestuali di lettere
riprodotte dalla stampa storica; il supporto degli automatismi
OpenType dipende dal renderer di testo LÖVE. La riproduzione della
carta impressa nel 1496 non è garantita dal semplice TTF.

## Ambiti

Menu principale, impostazioni, selezione delle commissioni, splash,
HUD della partita, dialoghi, folio e toast. Nessuna modifica alla
logica Farkle, ai dadi fisici o agli input.

## Collaudo Windows

- Testare `ÀÈÉÌÒÙ àèéìòù`, apostrofi e virgolette, `€ £ &`, cifre,
  segni `+`, `-`, `?` e caratteri speciali effettivamente presenti.
- Controllare ridimensionamento e allineamento nei cartigli e pulsanti
  alle risoluzioni 1280×720, 1920×1080 e ultrawide.
- Controllare differenze tra il display standard e testo grande.
- Prima di aggiungere altri simboli, verificare la copertura reale
  con `Font:hasGlyphs()` nella build LÖVE.
