# Project Folio — direzione artistica corrente

**Stato:** guida di produzione. La scena illustrata resta distinta dai
risultati fisici e dalle regole Farkle; il 2.5D è una proposta, non un
nuovo renderer approvato.

## Identità minima (brief 21 novembre 2026)

**Unico vincolo creativo:** il giocatore interpreta un **incisore nella
Venezia rinascimentale**. Botteghe, matrici, torchi, carte e legno
offrono un linguaggio materiale autentico da esplorare. L'ambientazione
attuale manuziana, lo stile xilografico, il sogno e il tono non horror
descrivono la **build 0.1.103**, non gli obblighi del gioco futuro.
La scena e il picking 3D devono restare coerenti finché questo
prototipo viene utilizzato per il confronto. I principi visivi di un
eventuale redesign devono essere motivati e playtestati prima di
sostituire gli asset attuali.

## Tavolo e livelli della scena

Il **tavolo da gioco** è la composizione attualmente giocabile:
sei D6 tridimensionali in osso, tavolo g3d, avversario illustrato
oltre il piano e UI su livelli 2D separati. Evitare di sacrificare
leggibilità e picking dei dadi a favore dell'ornamento.
La composizione corrente privilegia il rivale: il ritratto è più
presente sopra un tavolo compatto, mentre punteggio e comandi restano
fissi sullo schermo. La prospettiva del tavolo e il picking condividono
la stessa proiezione; il cambiamento è solo di inquadratura.

**0.1.102 — Framing del duello:** camera prospettica vincolata, con
`pitch=0.965`, `yaw=0` e `distance=52`. Il bordo posteriore rimane
agganciato alla stanza disegnata e i sei D6 mantengono coordinate
identiche per mesh, silhouette e input. La lieve elevazione dell'occhio
riduce l'imponenza della fascia anteriore, senza trasformare la scena
in un piano dall'alto.

**0.1.103 — UI diegetica corrente:** un foglio-contabilità per il giocatore
e un foglio più compatto per l'Opponent mostrano banca, rischio e scelta. Pergamena,
inchiostro, doppie righe sottili e righello inciso sostituiscono il
lessico dei pannelli digitali senza perdere accessibilità, numeri,
azioni o stato del tiro. La nota delle scelte dell'Opponent compare
**solo** durante il suo turno; il giocatore legge una breve istruzione
incisa sulla fascia anteriore del tavolo. I toast che duplicano banca
o Farkle sono soppressi durante il duello. Nessun nuovo asset, stato di gameplay o carta
obbligatoria è introdotto.

- Fondale senza personaggi: `resources/scenes/printshop-room.png`.
- Ritratto intercambiabile: `resources/opponents/<id>.png`.
- Menu: `resources/ui/menu_manuzio.png`.
- Dadi: materiale g3d color osso, patina sobria, punti incisi,
  contatto e ombra leggibili; identità/valori derivano dalla fisica.
- Font: **Aldine Aetna** con fallback **Cardo** (vedi
  [Tipografia](#tipografia-e-licenze)).

La scena applica una parallasse leggera a fondale e ritratto illustrati,
con opzione di animazioni ridotte. Non sostituisce g3d o il solver
dei dadi.

Il **Folio** non è più una sidebar permanente della partita. Resta
consultabile con **F** e rimane il perno narrativo della futura
ricomposizione delle xilografie, **non** una barra da colorare per
raggiungere una soglia di punti. Il sistema competitivo finale
degli incontri non è ancora definito.

## Palette del prototipo corrente (reversibile)

Il file autoritativo è `src/data/frontend_schema.lua`, sezione `palette`.
Toni opachi, contrasti funzionali, superfici artigianali:

| Ruolo | HEX |
|---|---|
| Pergamena | `#E7DCC8` |
| Inchiostro | `#352A23` |
| Legno | `#856448` |
| Salvia | `#8E957B` |
| Rosso cinabro | `#8D4B43` |
| Blu ardesia | `#6F8087` |
| Ocra | `#BE9A4F` |

I colori delle facce dei dadi, dello stato di selezione e dei
pulsanti devono restare leggibili in alto contrasto. Nessun
filtro fotografico indiscriminato per fingere materiali storici.

## Modelli del tavolo nel prototipo

La build corrente offre il tavolo `old_wooden` con
`resources/models/old_wooden_table_fallback.lua` e la variante
`wooden_compact`. I dettagli delle prove 0.1.93–0.1.96, la
comparazione dei modelli e le relative misure sono nella
[revisione 0.1.103](https://github.com/Askeladd22/Project_Folio/blob/ac814220a721f2946914d5c4a1ac9e389f40a8f6/docs/art_direction.md).
La presenza dei modelli non vincola la nuova fantasy.

## Riferimenti e accuratezza

L'*Hypnerotomachia Poliphili* (1499) è un riferimento per
sogno e xilografie, non una storia da riprodurre. Le immagini
storiche della tipografia guidano gesti, utensili e luce
veneziana, ma **non** provano che l'ambiente raffigurato sia la
bottega reale di Manuzio. Non copiare composizioni o asset
protetti di artisti esterni.

Gli studi precedenti su menu, Flameng, prospettive folio e
ornamenti sono conservati nei
[commit Git storici](https://github.com/Askeladd22/Project_Folio/tree/0fc25e369bc2655aa42489ae9078b04b9cef1650/docs),
non costituiscono specifiche di produzione concorrenti.

## Verifiche necessarie

Controllare Windows LÖVE a 1280×720, 1920×1080, 1440p e ultrawide:
facce dei dadi e picking, materiali, ritratto, leggibilità dei
font, tavolo durante presa/lancio multiplo, contrasto, testo grande
e animazioni ridotte. La CI non sostituisce il collaudo visivo.


---

## Tipografia e licenze

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

### Comportamento in LÖVE

Tutte le schermate di produzione caricano i font tramite
`src/core/presentation.lua`, sezione `typography`. La chiamata `Typography.load(path, pixelSize)`
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

### Ambiti

Menu principale, impostazioni, ingresso diretto al duello, splash,
HUD della partita, dialoghi, folio e toast. Nessuna modifica alla
logica Farkle, ai dadi fisici o agli input.

### Collaudo Windows

- Testare `ÀÈÉÌÒÙ àèéìòù`, apostrofi e virgolette, `€ £ &`, cifre,
  segni `+`, `-`, `?` e caratteri speciali effettivamente presenti.
- Controllare ridimensionamento e allineamento nei cartigli e pulsanti
  alle risoluzioni 1280×720, 1920×1080 e ultrawide.
- Controllare differenze tra il display standard e testo grande.
- Prima di aggiungere altri simboli, verificare la copertura reale
  con `Font:hasGlyphs()` nella build LÖVE.

---

## PNG e ritratti degli avversari

**Stato attuale:** gli asset modulari sono nel repository, non
richiedono più un pacchetto grafico esterno da installare.

### Strati

1. `resources/scenes/printshop-room.png` — bottega pulita,
   **senza personaggi**.
2. `resources/opponents/opponent.png` — Opponent con canale alfa
   indipendente, davanti al fondale e dietro al tavolo 3D.
3. Tavolo, sei D6 g3d e HUD — livelli separati, nessuna modifica
   agli eventi fisici o ai punteggi.

Per altri personaggi usare `resources/opponents/<id>.png`, con
`<id>` composto solo da lettere minuscole, cifre e underscore.
Usare trasparenza RGBA, busto coerente e proporzioni leggibili;
il motore usa un'area di ancoraggio comune senza distorcere
il rapporto d'aspetto.

### Identità del rivale corrente

L'Opponent visibile nella baseline si identifica con
`opponent_id='opponent'` e usa il PNG separato
`resources/opponents/opponent.png`. L'architettura distingue
ritratto, room e fisica; sostituire un'immagine non aggiunge
comportamenti dell'IA. Nessun roster narrativo è vincolante
per il redesign.

### 0.1.103 — Compact Opponent ledger

The rival's score, at-risk amount, selected gain and announced action
now share **one compact parchment** on the right of the printshop. The
redundant centre "Turn · Opponent" placard and second floating action
card are no longer painted. The left ledger already displays whose
turn it is; this preserves a quiet view of the engraved portrait.
Scored dice are fixed *solid* kinematic objects on the 3D table; active
dice collide with them, but they cannot be moved or rerolled. Ordinary
held dice remain non-colliding until release.
