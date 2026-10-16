# Balatro: studio statico dei 19 shader

Analisi originale per parafrasi dell'archivio ZIP incorporato in `S:/Hydra Games/Balatro/Balatro.exe`, letto in memoria con Python `zipfile`. Nessun sorgente o asset estratto nel repository. I riferimenti sono percorsi interni e righe a base 1 di questa copia locale; gli hash sotto identificano esattamente i byte esaminati. **Confermato staticamente** significa presente nel codice e nei collegamenti Lua; non significa misurato su GPU o osservato durante una partita. Non sono disponibili qui catture runtime, tempi GPU o compilati dei driver.

## Contratto comune e composizione

`game.lua:127-134` enumera e compila tutti i file `.fs`, usando il nome senza estensione come chiave. Presenza/compilazione non prova utilizzo effettivo. `engine/sprite.lua:73-117` invia uniform, attiva il programma, disegna lo sprite e azzera lo shader. `Sprite:draw`, righe 162-167, esegue in ordine gli eventuali draw steps. Si tratta di disegni sovrapposti: gli shader di edizione campionano l'atlante originale, non automaticamente il risultato del passaggio precedente.

La famiglia sprite usa `texture_details` = indice della cella x/y e dimensione della cella in pixel; `image_details` = dimensioni dell'atlante (`engine/sprite.lua:43-53`). Il passaggio da UV dell'atlante a coordinate locali della carta moltiplica per la dimensione dell'immagine, sottrae l'origine della cella e divide per la dimensione della cella. Le onde così rimangono legate alla carta. `screen_coords` viene invece usato dai fondali procedurali; CRT lavora sulle UV del canvas.

Uniform comuni: `dissolve`, `time`, `texture_details`, `image_details`, `shadow`, `burn_colour_1/2`, `mouse_screen_pos`, `hovering`, `screen_scale`; ai materiali si aggiunge generalmente un vec2 con il nome del programma. **Il `time` comune non è il tempo corrente:** `engine/sprite.lua:100` invia un numero deterministico derivato dall'ID, modulo 3000. Il campo di dissolvenza è quindi stabile per oggetto mentre cambia la soglia. Invece `card.lua:4348-4350` passa nel vec2 del materiale una fase che combina rotazione visuale, tempo reale/28, juice e tilt; la seconda componente è tempo reale. Non chiamare indistintamente entrambi questi valori “tempo”. Il percorso custom (`sprite.lua:82-86`) consente uniform da valori, funzioni o tabelle.

Il vertex shader comune (esempio `dissolve.fs:69-86`) modifica la coordinata omogenea w dopo la trasformazione: il termine dipende dalla distanza quadratica dal cursore e dalla posizione rispetto allo schermo. La divisione prospettica produce il movimento apparente della carta senza una mesh 3D. `hovering <= 0` evita il calcolo; reduced motion forza no-tilt (`sprite.lua:74,98`). Ombre: spostamento/scalatura Lua temporanei, stesso campionamento, RGB nero e alpha al 30%; non un blur né un'ombra fisica.

## Priorità: materiali e postprocess

### dissolve — maschera comune, `dissolve.fs:15-66`

Un campionamento dell'atlante. Una soglia cubic smoothstep del parametro dissolve viene estesa leggermente oltre [0,1] (estremi effettivi -0,01 e 1,01). UV quantizzate in pixel alimentano tre campi radiali traslati da sinusoidi, poi una modulazione cosinusoidale. Una penalità presso i bordi accelera la scomparsa periferica. Il confronto campo/soglia decide alpha zero o originale; due bande di larghezza dipendente dalla fase scelgono i colori di bruciatura. La versione base tinge anche l'interno verso il colore di bruciatura. Sotto dissolve 0,001 la maschera ritorna subito, evitando il campo trigonometrico. Gli altri materiali incorporano una maschera analoga: materiale prima, ritaglio/bruciatura dopo. Usato normalmente per centro, fronte, retro e ombre (`card.lua:4362,4422-4425,4553`) e sprite del blind (`blind.lua:452-453`).

### foil — metallo blu, `foil.fs:98-123`

UV locali centrate e corrette per rapporto larghezza/altezza. Un primo fattore costruisce anelli tramite distanza e sinusoidi annidate, un secondo usa il prodotto scalare normalizzato rispetto a un vettore variabile per le strisce angolari; altri due introducono onde lungo x/y. Massimo e somma amplificano i picchi. Il contrasto derivato dal texel regola sottrazione da rosso/verde e forte aggiunta al blu; alpha rende il disegno un velo parzialmente trasparente. Non c'è riflessione ambientale, normal map o luce 3D. Il vec2 `foil` guida la fase; il `time` comune entra solo nella dissolvenza. Un sample, parecchie funzioni trigonometriche e lunghezze, nessun loop di sampling. Le conversioni HSL definite nel file non vengono chiamate dal suo effect. Il rapporto angolare ha un denominatore nullo al centro geometrico: rischio numerico statico da verificare su driver, non difetto osservato. Attivazione `card.lua:4458-4462`, dopo il disegno base, su centro e fronte quando applicabile.

### holo — reticolo iridescente, `holo.fs:97-132`

Un sample; mescola inizialmente il colore con blu e converte in HSL. Campo a tre distanze su UV quantizzate, con scala spaziale 250 e tempo derivato da `holo.y` più il seed comune. La componente x del materiale sposta la fase del campo. Tre famiglie di coseni producono linee verticali e diagonali: il massimo delle creste introduce un reticolo nella tonalità. Saturazione e luminosità vengono aumentate; la ricombinazione RGB privilegia il blu ed è miscelata con il texel originale secondo il suo contrasto. Alpha basso viene ulteriormente attenuato. HSL, trigonometria e campi radiali rendono il costo ALU maggiore di un tint semplice, ma resta un solo fetch. `card.lua:4452-4456` attiva l'edizione holo su centro/fronte.

### polychrome — variazione cromatica larga, `polychrome.fs:97-130`

Un sample e HSL. Una piccola correzione iniziale dipende dall'escursione RGB del texel; campo analogo a holo ma scala spaziale 50, quindi variazioni più ampie rispetto al reticolo holo. La tonalità combina campo, componente x e lenta deriva della seconda componente; la saturazione è incrementata e limitata a 0,6. La luminosità HSL del materiale rimane la base strutturale della figura. Non usa il reticolo di holo. Alpha sotto 0,7 viene diviso per tre. `card.lua:4464-4468` applica l'edizione. Costo: un fetch, conversione HSL e campo trigonometrico, oltre alla maschera quando dissolve è attivo.

### hologram — figura luminosa discontinua, `hologram.fs:54-109`

Diverso da holo: è l'effetto del Joker Hologram sulla floating sprite (`card.lua:4512-4519`), con maggior tilt e trasformazioni oscillanti Lua. Il primo stadio campiona un quadrato 9×9 dell'alpha, accumulando soltanto campioni sotto 0,9 e normalizzando per il loro numero. Due somme di sinusoidi lungo y, animate dalla seconda componente, generano rari spostamenti orizzontali del sample centrale. Pixel quasi opachi vengono eliminati, quelli trasparenti assumono un colore ciano, e un alone verde/ciano viene aggiunto con intensità pulsante. Il margine locale del 5% viene ritagliato. Sono **82 fetch espliciti per frammento** prima del ritorno sul bordo: 81 per l'alone e uno centrale. Questo è il candidato più costoso per area della famiglia carta. Il raggio è in UV dell'intero atlante, non in pixel di cella. Possibile divisione per zero se tutti gli 81 alpha sono almeno 0,9; l'effetto dipende quindi anche dalla struttura dell'asset. È un rischio statico, non una prova di artefatto visibile.

### negative — inversione HSL, `negative.fs:97-113`

Un sample, conversione HSL, inversione della luminosità se la seconda componente del vec2 è diversa da zero, inversione/offset della tonalità e aggiunta di una tinta grigio-ciano. Non equivale a `1 - RGB`; questa distinzione cambia la resa. Riduce alpha già debole, poi applica colore del draw e maschera. Sostituisce il passaggio base per edizione negative o Antimatter scoperto (`card.lua:4416-4425`). La brillantezza separata arriva da negative_shine, non da questa trasformazione. Costo moderato ALU e un fetch; `negative.x` non anima direttamente il frammento.

### CRT — canvas finale, `CRT.fs:20-132`

Pipeline: UV centrate/scalate → curvatura con termini incrociati quadratici → maschera smussata ai bordi → eventuale glitch orizzontale → campione centrale → due campioni laterali per separare rosso/verde → attenuazione e reticolo RGB a sinusoidi → rumore aritmetico su coordinate quantizzate → compensazione contrasto/luminosità → bloom → maschera finale. Il bloom è un quadrato 7×7: soglia per canale, poi minimo dei tre canali e peso diagonale; produce un bagliore sostanzialmente neutro, non un Gaussian blur separabile. Normalizza per 9, non per il numero 49 di tap: scelta artistica, non media uniforme.

Uniform: tempo, distorsione/scalatura vec2, feather, noise, bloom, intensità CRT/glitch, densità scanline e tilt. `game.lua:2933-2965` disegna CANVAS verso AA_CANVAS con CRT, poi presenta quest'ultimo scalato. Prima dell'invio, l'impostazione CRT è temporaneamente moltiplicata per 0,3; il tempo è 400 + REAL, bloom è impostazione meno uno, scanlines dipende dall'altezza canvas/CANV_SCALE. **Il glitch viene inviato come zero** in questo percorso: la sua esistenza nello shader non prova glitch normalmente visibile. Costo statico: 1 fetch base, +2 se aberrazione attiva, +49 se bloom attivo = fino a 52, su quasi tutto lo schermo. Quindi può costare globalmente più di hologram, pur avendo meno tap per frammento. Il vertex tilt CRT ha coefficienti diversi da quello carta. Nessuna misura FPS inferita.

## Gli altri dodici file

| File e righe | Meccanismo, uniform e coordinate | Attivazione Lua e costo statico |
|---|---|---|
| background.fs:7-51 | time/spin_time distinti, tre colori, contrast e spin_amount. Coordinate schermo quantizzate e normalizzate per diagonale; rotazione polare dipendente dal raggio; cinque iterazioni di deformazione trigonometrica, quindi tre pesi di colore. | game.lua:2282-2292: REAL_SHADER e BACKGROUND, palette e spin da tabelle. Zero fetch, molta ALU su area estesa. |
| booster.fs:54-78 | Vec2 booster più contratto sprite. Cinque onde inclinate modulate fra loro, massimo/somma/prodotto, tinta blu e alpha variabile. Differenza decisiva da voucher: il contrasto incorpora anche il minimo RGB, rendendo attive zone meno sature. | card.lua:4449-4450 per Booster/Spectral. Un fetch, numerosi sin/cos. |
| debuff.fs:98-129 | Vec2 debuff; HSL da texel tinto rosso. Le due diagonali UV locali definiscono una X, con spessore abilitato dalla componente y non nulla; fuori X desatura, scurisce e riduce alpha. | card.lua:4526-4530. Un fetch, HSL e confronti; nessuna animazione trigonometrica specifica oltre dissolve. |
| flame.fs:8-68 | time, amount, id, due colori e dettagli atlante. UV locali centrate e quantizzate; traslazione verticale animata, cinque iterazioni di turbolenza sinusoidale, soglie e limiti laterali producono lingue colorate con alpha binario. amount modula scala/estensione; id sfasa. | functions/button_callbacks.lua:2005-2016 invia timer/intensità/palette/id, righe 2021-2024 collegano l'intensità al punteggio. Zero fetch; ritorno trasparente economico a intensità molto bassa, altrimenti ALU elevata. |
| flash.fs:8-22 | time e mid_flash, coordinate schermo quantizzate. Due espansioni radiali bianche con avvio temporale distinto, una a radice quadrata e una quadratica; alpha controllato da mid_flash. | game.lua:1411-1417, splash foreground. Zero fetch, poche operazioni rispetto ai fondali. |
| gold_seal.fs:1-21 | Vec4 gold_seal dichiarato, ma solo r effettivamente usato per fase. Due onde su UV atlante schiariscono RGB senza oscurarlo; alpha originale. | Compilato dal loader; nessuna chiamata nominale trovata nei Lua esaminati. Gold seal attuale usa dissolve più voucher (card.lua:4475-4476). Un fetch. Non attribuire automaticamente questo file al sigillo visibile. |
| negative_shine.fs:54-78 | Vec2 omonimo; cinque onde inclinate, contrasto RGB meno una piccola costante, tinta blu, differenza rosso/verde più forte di voucher e alpha attenuato. | card.lua:4470-4471, sopra la base negative, centro. Un fetch e trigonometria; non campiona il framebuffer negative. |
| played.fs:98-110 | Vec2 played; HSL con saturazione dimezzata (piccolissimo contributo x), luminosità all'80%, alpha dimezzato. UV locali servono a dissolve. | card.lua:4532-4536 quando greyed. Un fetch, conversione HSL. |
| skew.fs:1-18 | Solo vertex: cursore, hovering e screen_scale; variazione w equivalente al tilt comune. Nessun tempo e nessun effetto frammento scritto qui. | Compilato; nessuna chiamata nominale trovata nei Lua. La stessa tecnica è incorporata in altri shader attivamente usati. Costo per vertice basso; campionamento del pixel delegato al normale percorso grafico. |
| splash.fs:7-55 | time, vort_speed/offset, due colori, mid_flash. Coordinate schermo quantizzate, vortice polare e cinque iterazioni trigonometrico-turbolente. Tre regioni colore includono scuro; mix bianco controllato da flash e creste. | game.lua:1303-1312 sandbox, 1395-1405 splash; altre definizioni 1549 e 1740. Zero fetch, ALU elevata. |
| vortex.fs:1-21 | Solo vertex; vortex_amt cambia raggio e angolo del vortice. Distanza corretta per aspect ratio e rotazione polare rispetto al centro schermo. | card.lua:4403-4413 quando vortex; sprite.lua:88-89 passa tempo trascorso da vortex_time. Effetto geometrico sui vertici esistenti, non un warp denso per pixel. La smoothstep usa estremi invertiti: portabilità GLSL da verificare, non comportamento runtime dimostrato. |
| voucher.fs:54-78 | Vec2 voucher e contratto comune. Stessa famiglia di onde oblique del booster, contrasto da max-min RGB; ricombinazione blu e velo alpha variabile. | card.lua:4440,4446-4447; sigilli/sticker 4475-4500; misc_functions.lua:1823-1828. Un fetch e molte sinusoidi. |

## Interpretazione dei costi e principi trasferibili

I conteggi dei tap sono conteggi del percorso GLSL, non numero di transazioni RAM: cache, filtraggio, compilatore, branching e formato texture possono cambiare i costi. Analogamente una funzione HSL definita ma inutilizzata non dimostra istruzioni GPU eseguite. Il numero di carte, sovrapposizioni, centro/fronte, ombre, risoluzione canvas e bloom possono dominare il risultato. Per validare servirebbero confronto GPU/frame con bloom on/off, carta hologram isolata, dissolve attivo/inattivo e scala canvas, mantenendo scena e impostazioni costanti.

Principi riutilizzabili senza copiare implementazioni: separare seed stabile da clock; usare coordinate locali indipendenti dall'atlante; combinare poche onde deterministiche per materiali ricchi; preservare leggibilità tramite HSL; comporre velo e base come draw espliciti; limitare i filtri multi-tap a piccole superfici o buffer ridotti; trattare hover geometrico, materiale, dissolvenza e postprocess come responsabilità distinte. Le costanti, il codice e gli asset originali non sono necessari per un'implementazione autonoma di questi principi.

## Impronte SHA-256 dei file interni

La tabella seguente è generata dai byte letti nell'archivio; nessun file sorgente viene scritto su disco.

| File interno | SHA-256 |
|---|---|
| resources/shaders/CRT.fs | 117d20bc8ede642c6c446d1c6155e8482d14033ef4cef0438c8ab5e49f97ee8f |
| resources/shaders/background.fs | 81a512572b159d247ca747de36335bc47c933178cb5f6fb914ec6ce74dabf632 |
| resources/shaders/booster.fs | 9e19fad026a3f6980981e246105ad2376c9c31c9139434a294dc4b79918d6792 |
| resources/shaders/debuff.fs | 77b6039c6e33cb26fc140bf9237a013da157239cd13d46eda5aea1b1ea6947f3 |
| resources/shaders/dissolve.fs | f2187e221f35867b2a7f81a90f9af3081cc47de8a0a7f4b42d93476cd53d2075 |
| resources/shaders/flame.fs | e0c5d028c872b81209f506aabd85d2a04510c316a14c4c7928eabde1050df9f3 |
| resources/shaders/flash.fs | cadbed13e9fa45309ebd4dec4d9c4a1acc903fed22c00555932cba78bd59ea63 |
| resources/shaders/foil.fs | 866160b946acc03520b5cf2cb56996124771c7c8482d8b4291bca11215c93b9e |
| resources/shaders/gold_seal.fs | 2d98e57ff4421309d1cd4976fa475aa52afaf98e1e02f818de211d647d4e50ed |
| resources/shaders/holo.fs | c6d30f9e55e247205534cd2e4d070522c633643dd1bc69858f787e310a556131 |
| resources/shaders/hologram.fs | f830ec35a4835532a9ed1092596c0391c9db0c65603b577d39c4181b96e4108d |
| resources/shaders/negative.fs | 4ef1978d24595cbe0ad9514b3e6136990dacf88609b6414e31eb5ff206180408 |
| resources/shaders/negative_shine.fs | 4c31de2ea8ce3f73b1aebbc0e561a0f103e0683dcc6397a5e03a2dd39f0cf4d8 |
| resources/shaders/played.fs | 76b59859412d97bfb01405ad885b78cdc5624429a8b034ed27fee4a7ef3c155b |
| resources/shaders/polychrome.fs | 1ec510e5a23a82b3365057688d55d5ff6c7c50b49d4ebcbd04c6dd5572c2867b |
| resources/shaders/skew.fs | 69ec9dac7e177aa0a5815e18b66f1b07c696c638a641b8a6a578ecbbc2f9eadb |
| resources/shaders/splash.fs | ca20993fa5d92d5441f2ff09441fdf8eff4310ccc71f946caa5425003b7ee24f |
| resources/shaders/vortex.fs | 7dc96d21ef5afa14a8403ab7662b3c978d0d0346a52404a9072aabeb8594dc73 |
| resources/shaders/voucher.fs | 2dec0c0e477f35371cad350c12d400dac6f1c145415794375a0d3070e7aa623c |
| engine/sprite.lua | c5e10ea7a91a57ea7a9389cbecae7504bcbf835645eb90fff669f5c3f4f803de |
| card.lua | 5073d834e08119da9516f1795a8c3d93110669aeb409c29ad1b308e0eb0be453 |
| game.lua | bbc67bd3fbadd1ea3f3f0aba07ef8596118d89ff1e9758718f9e17c07a96e912 |
| blind.lua | 0a7e5fde144da36d4ca1a96950b4bf51e3c95be55fb02764a555de53a3bd8afb |
| functions/button_callbacks.lua | c88a74ca3a8fa8ace0ce46ad10a97238f347c292842c9164d11136fe9952c101 |
| functions/misc_functions.lua | c36ed54d8ab441be994a9afc5d38b8ac530f3b93995dfed424ec11f02e633198 |
