# Project Folio — direzione artistica corrente

**Stato:** guida di produzione. La scena illustrata resta distinta dai
risultati fisici e dalle regole Farkle; il 2.5D è una proposta, non un
nuovo renderer approvato.

## Identità

Una **bottega tipografica veneziana tra fine XV e inizio XVI secolo**,
nell'ambiente di Aldo Manuzio: fogli, matrici xilografiche, torchio,
correttori, caratteri mobili, legno, pigmenti e inchiostro.
**Non** uno scriptorium monastico o un fantasy medievale generico.

Il protagonista è un **artista originale ispirato al profilo di
Albrecht Dürer** — disegnatore e incisore, curioso e colto — non Dürer
stesso e non un ritratto della sua biografia. È muto e non gli si
impongono dialoghi. Il legame con la bottega aldina è narrativa di
finzione, non attribuzione di un episodio storico documentato.

Il sogno trae forza da poche anomalie legate a carta, xilografie,
inchiostro e tavolo. La tensione deve essere quella dell'azzardo:
**incasso o rilancio?** Non horror, maledizioni, effetti neon o
ornamenti decorativi ripetuti senza funzione.

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

**0.1.102 — UI diegetica:** due fogli-contabilità appoggiati alla
composizione della bottega raccontano banca e rischio; un foglietto
separato illustra il turno e le scelte dell'Opponent. Pergamena,
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

## Palette canonica

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

## Tavolo in uso — Old Wooden Table (proposta v0.1.96)

Il candidato originale dell'utente, attribuito ad Alex Krush,
viene preferito alla pesante cornice Pixel Life per il suo
aspetto da tavolo di gioco vissuto e non da banco da lavoro.
Il piano è ampio quanto il campo fisico dei sei D6, mentre
gambe e fascia mantengono proporzioni autonome; una cornice
grafica sottile suggerisce i limiti della superficie senza
nascondere i dadi. La scena, il Opponent e la camera non cambiano.

**Stato artistico non canonico:** la variante F8 `old_wooden`
mostra l'asset originale solo se installato localmente.
Senza GLB viene caricata una struttura di riserva creata
per il progetto, non l'asset di Alex Krush. L'integrazione
ufficiale richiede confronto su screenshot reali, texture
leggibile a 720p e test del lancio Windows.

Licenza e distinzione dei materiali in
`resources/models/OLD_WOODEN_TABLE_CREDITS.md`.

## Tavolo — Variante B «Compatta» (v0.1.95)

**Obiettivo visivo:** tavolo da gioco ravvicinato, non banco da lavoro.
Manteniamo il Pixel Life come base, ma riduciamo il mobile visibile
sotto il piano: gambe e fascia frontale vengono schiacciate nel
rendering 3D, senza deformare il piano su cui toccano i D6.
Il bordo è sottile ma continua a coincidere con le pareti fisiche,
e le giunzioni delle assi sono più discrete.

La scelta iniziale in laboratorio è `wooden_compact`. Il confronto
con `wooden` resta disponibile via F8; l'esito è provvisorio fino a
una prova reale sul monitor Windows e all'approvazione della composizione.
Non sono previste carte, HUD supplementari, cambi RNG o nuove
meccaniche. In particolare il tavolo **non** viene ridotto
indipendentemente dalla zona fisica per non creare collisioni invisibili.

## Tavolo in noce: contatto fisico e assi (v0.1.94)

La board Pixel Life è già la variante iniziale. Il fallback ora
mostra otto assi in legno con sottili giunzioni, concentrando la
decorazione lontano dalle facce dei sei dadi.
Per evitare che i dadi sembrino affondati, la silhouette resta
0,018 unità sotto il piano di contatto (z=0) e le assi
decorative solo 0,006 sopra. Il GLB completo opzionale
usa invece le proprie UV e la texture originale, allineando
il piano superiore a z=+0,005.

Un GLB derivato ottimizzato dall'originale (4538 triangoli,
texture colore a 1024²) è consegnato come ZIP separato.
La PR non include il binario: il fallback integrato funziona
senza installazioni aggiuntive.

## Tavolo di gioco (laboratorio v0.1.93)

La candidata principale è la silhouette del tavolo in legno
di **Pixel Life**, ridotta e reinterpretata nel materiale per
privilegiare il contrasto con i sei dadi. Il piano centrale
resta relativamente uniforme, il bordo meno monumentale della
precedente decorazione; il Rivale PNG rimane indipendente.
La variante precedente è disponibile con **F8**: nessuna
decisione artistica è definitiva finché le due schermate non
sono confrontate in una prova giocata.

La geometria derivata e il GLB originale sono materiali di terzi
con attribuzione CC BY 4.0: la documentazione è in
`resources/models/WOODEN_TABLE_CREDITS.md`. Non scambiare
il fallback a bassa poligonizzazione per un export identico
all'asset originale.

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

### Selezione dell'avversario

L'identità di default è **Rivale** (`opponent_id='rival'`), un
segnaposto neutro: **Opponent** non è il nome di tutti gli avversari.
Il PNG `opponent.png` è ancora usato *provvisoriamente* per il default
finché non esisterà `resources/opponents/rival.png`, che verrà preferito
automaticamente. La grafica esistente non attribuisce al default le
meccaniche del Opponent.

```lua
require('src.core.navigation').go('scriptorium',{new_run=true})
-- Soltanto quando si vuole esplicitamente il personaggio Opponent:
require('src.core.navigation').go('scriptorium',{new_run=true,opponent_id='opponent'})
-- Oppure nella scena corrente:
require('src.farkle.controller'):setOpponentVisual('opponent')
```

Il modulo `src/farkle/ui.lua`, sezione `opponent_scene`, risolve
fondale e ritratto. Un ID non disponibile non deve mostrare il
Opponent dietro a un altro personaggio: in assenza dell'immagine
richiesta il loader segnala l'errore esplicitamente.

Il vecchio composito `resources/opponent/table-host.jpg` resta un
**fallback tecnico di compatibilità** per `rival` quando non sono disponibili
gli asset modulari, e per `opponent` quando è selezionato esplicitamente.
Il composito contiene già il Opponent: non è un ritratto neutro e non
va impiegato per creare altri personaggi. In produzione si preferisce
sempre la stanza pulita con un PNG indipendente.

**Confine di design:** sostituire un PNG non crea un bot, una
scommessa o un encounter competitivo. Quei sistemi restano aperti
nella [visione](project_vision.md). I ritratti e la stanza non
devono alterare le hitbox o la fisica dei dadi.
