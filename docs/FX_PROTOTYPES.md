# Laboratorio originale degli effetti di Manuscript

15 ottobre 2026. Cinque prototipi autonomi, **nessun effetto integrato nel Farkle**. Il confronto dei riferimenti e i limiti della ricerca sono in [FX_STUDIO.md](FX_STUDIO.md).

## Avvio e controlli

Dalla radice del repository:

```powershell
love experiments/fx_lab
```

Oppure aprire [experiments/fx_lab/Avvia.cmd](experiments/fx_lab/Avvia.cmd). Il launcher usa `LOVE_EXE`, il PATH oppure le installazioni Windows note. Avvio direttamente dai sorgenti, nessun pacchetto `.love`, nessuna nuova dipendenza.

Il pannello **A** mostra lo stato finale senza effetto; **B** mostra la stessa scena animata. La comparazione riguarda la presentazione, non due simulazioni fisiche.

| Comando | Azione |
|---|---|
| Pulsanti superiori o 1–5 | Scegliere uno dei cinque studi |
| Spazio / Play-Pause | Avviare, sospendere o riprendere |
| R / Replay | Ricominciare da zero |
| Repeat | Ripetizione automatica, senza accumulare eventi |
| B / Effect | Attivare/disattivare l'effetto corrente; la scelta è conservata per ciascuno studio |
| M / Reduced motion | Stato finale immediato, nessun movimento decorativo |
| Frecce sinistra/destra o Duration −/+ | Durata da 0,4 a 6 s, passi di 0,2 s |
| Frecce giù/su o Intensity −/+ | Intensità da 0 a 100%, passi del 10% |
| Esc | Chiudere il laboratorio |

Durata iniziale 2,4 s e intensità 70%: valori **da ispezione rallentata**, non una proposta di imporre 2,4 s a ogni azione del gioco. Disattivazione e modalità ridotta raggiungono subito lo stesso stato terminale. Audio non implementato nel laboratorio, chiaramente indicato nell'interfaccia.

## Implementazioni

### 1. Trasferimento del dado

Un proxy bidimensionale originale con cinque punti si sposta dal piano verso un ripiano. Posizione orizzontale interpolata con easing cubico simmetrico; arco verticale sinusoidale e rotazione limitata che termina a zero. Coordinate locali: x 110→410, y finale 234; altezza massima dell'arco 92×intensità. Non viene usato un corpo fisico, non vengono sorteggiati o letti risultati.

Il modello illustra il principio di **origine, percorso e destinazione leggibili**, coerente con lo studio della collocazione dei dadi/equipaggiamenti. Non replica traiettorie o durate di Dicey. In un'eventuale integrazione il proxy riceverebbe identità, valore e origine già determinati; il laboratorio non implementa né sostituisce il ripiano a sei dadi del gioco attivo.

Giudizio visivo: destinazione chiara e sagoma leggibile a entrambe le risoluzioni; il prototipo resta una grafica 2D, non dimostra la qualità di un trasferimento del dado tridimensionale. Un solo oggetto non misura la leggibilità di sei trasferimenti simultanei. Per una prova futura partire da 0,4–0,7 s, senza attesa obbligatoria. Complessità di manutenzione bassa; principale rischio d'integrazione: doppia rappresentazione o bersaglio di picking durante il movimento.

### 2. Conteggio progressivo

Tre contributi illustrativi **40 + 35 + 25 = 100**, non combinazioni Farkle e non nuovi bonus di gameplay. Intervalli normalizzati 0–0,40, 0,42–0,72 e 0,74–1; easing di uscita e arrotondamento del solo valore mostrato. Il totale visualizzato è la somma dei tre contributi, quindi non contraddice le righe intermedie. Nessuna logica del punteggio viene caricata.

Il riferimento concettuale è la causalità delle attivazioni, documentata nelle API di Balatro/Luck, non il loro codice. Le righe sono sempre nello stesso punto e non rimbalzano. A metà sequenza il laboratorio mostra 40+21+0=61, mentre il pannello di controllo mostra 100.

Giudizio visivo: il totale prevale sulle righe; contributi leggibili a 720p. Manca l'evidenziazione dell'oggetto sorgente dentro il vero HUD e manca il suono. Prova futura 0,6–1,0 s, interrompibile; con molte attivazioni servirebbe aggregare, non aumentare indefinitamente la durata. Complessità bassa, rischio principale nascondere temporaneamente un numero necessario per decidere.

### 3. Rivelazione dell'ornamento

Un ramo botanico procedurale viene disegnato una volta su Canvas trasparente. Uno shader originale fa avanzare una frontiera in UV con piccola ondulazione e bordo morbido; maschera moltiplicata su **RGB e alpha**. Non è una simulazione dell'inchiostro, non segue l'ordine storico delle pennellate e non riproduce figure di Inkulinati o Scriptorium. La carta sottostante rimane statica.

Giudizio visivo: conferma materiale coerente con il tema, bordo localizzato senza contaminare la pagina. Il tratto ripetitivo e schematico è un segnaposto originale, non arte finale. A 1080p il Canvas 540×370 viene ingrandito 1,5×: i bordi risultano più morbidi rispetto alla geometria ridisegnata a risoluzione piena, ma rimangono leggibili. Prova futura 0,5–0,9 s per un evento significativo, non per ogni lancio. Complessità media; rischi alpha, scala e sovrapposizione ai testi.

### 4. Riflesso dorato sulla medaglia

Medaglia procedurale originale con nastro e stella. Uno shader produce una fascia obliqua morbida che percorre la superficie; maschera circolare limita il riflesso al metallo, alpha limita l'aggiunta alle parti disegnate e un inviluppo sinusoidale azzera l'effetto ai due estremi. Il nastro non diventa metallico. Non sono ripresi i motivi Foil/Holo/Polychrome.

Giudizio visivo: differenza discreta fra i due pannelli, senza lampeggio globale. L'effetto comunica salienza, ma da solo **non distingue equipaggiamento, disponibilità o consumo di una carica**: il futuro trigger va scelto esplicitamente. Prova futura 0,4–0,8 s, una sola passata all'evento. Complessità media; rischio di far sembrare cliccabile un oggetto puramente informativo.

### 5. Luce locale sul banco

Banco, carta, calamaio e penna sono geometria originale prerenderizzata su Canvas opaco. Uno shader somma un accento caldo con decadimento radiale ellittico e inviluppo temporale morbido. Centro UV (0,62;0,52); nessuna luce fisica, ombra dinamica o modifica alla camera. Non riproduce il modello d'illuminazione di BOOK OF HOURS.

Giudizio visivo: atmosfera più calda senza movimento degli oggetti. L'utilità decisionale è inferiore a trasferimento e conteggio; può ridurre il contrasto della carta se intensificata. Prova futura 0,8–1,5 s per un cambio di stato importante, senza ritardare il gioco. Complessità media; costo GPU dipendente dall'area e dal numero di passate.

Le finestre temporali proposte sono **ipotesi da provare manualmente**, non risultati di un test di gradimento né misure dei titoli di riferimento. Il laboratorio non impone tempi alla sequenza del Farkle.

## Struttura e contratti

| File nuovo | Responsabilità |
|---|---|
| `experiments/fx_lab/main.lua` | UI, callback LÖVE, confronto A/B e audit opt-in |
| `model.lua` | Tempo trascorso, easing, pausa/ripetizione, riduzione e disattivazione |
| `visuals.lua` | Geometria originale, tre Canvas, disegno e ripristino dei contenuti dopo cambio modalità |
| `shaders.lua` | Tre shader GLSL originali, compilazione protetta e fallback |
| `conf.lua`, `Avvia.cmd` | Applicazione autonoma e launcher |
| `test.lua`, `model_test.lua`, `audit.ps1` | Verifiche logiche, sintassi, esecuzione grafica seriale |
| `README.md` | Istruzioni locali del laboratorio |

Nessun import da `src/`, nessun renderer 3D, solver, spawn, medaglia, RNG o regola Farkle coinvolti. Il laboratorio usa il font predefinito LÖVE e non carica immagini/audio commerciali. Tre Canvas 540×370 vengono allocati in `love.load`, ridisegnati solo quando necessario e riutilizzati. Nessun framework d'animazione.

Le animazioni avanzano in secondi tramite `dt`, non in numero di frame; la ripetizione conserva il residuo temporale. Scala uniforme e letterboxing su superficie virtuale 1280×720; coordinate mouse riportate nello stesso spazio. Il disegno dei Canvas usa alpha premoltiplicato e ripristina il blend in ingresso; gli shader vengono disattivati dopo il proprio disegno. Il modulo è un'applicazione isolata, non una libreria pronta a essere inserita senza adattamento in uno stato grafico arbitrario del gioco.

Riferimenti tecnici: [Canvas in LÖVE](https://love2d.org/wiki/Canvas), [formule di blending](https://love2d.org/wiki/BlendMode_Formulas), [stato degli shader](https://love2d.org/wiki/love.graphics.setShader). Sono riferimenti API, non sorgenti proprietari adattati.

## Verifiche e correzione emersa

Comandi dalla radice:

```powershell
rtk proxy python scripts/test_luajit.py experiments/fx_lab/test.lua experiments/fx_lab/model_test.lua
rtk powershell -ExecutionPolicy Bypass -File experiments/fx_lab/audit.ps1
rtk proxy python scripts/test_luajit.py
rtk proxy python scripts/test_love_runtime.py
```

L'audit avvia soltanto il laboratorio, acquisisce PNG e termina. Non eseguirlo contemporaneamente ad altri benchmark grafici. `FX_LAB_AUDIT` è ripristinata al termine dello script.

- **2/2 file di test Lua del laboratorio:** partizione del tempo, 20/30/60/144 Hz, pausa, ripresa del modello, ripetizioni con residuo, fine unica, riduzione/disattivazione, estremi easing e sintassi dei moduli.
- **26/26 suite Lua della produzione** e **4 test Python del runtime** superati.
- **20 casi grafici:** cinque effetti × due risoluzioni × animato/disabilitato.
- Tre shader compilati su **LÖVE 11.5.0**, OpenGL 3.3.0, NVIDIA driver 617.14, GeForce RTX 5080.
- Callback reali `love.keypressed`/`love.mousepressed` verificate sinteticamente a entrambe le risoluzioni: cinque schede, pausa/play/replay, ripetizione, preferenza indipendente on/off, riduzione, durata e intensità, con coordinate mouse trasformate. Sono test delle callback, non clic OS o una prova umana.
- Conteggio delle chiamate reali a `newCanvas`: **3 in caricamento, 0 dopo**.
- Controlli dei Canvas: contenuto opaco e variazione cromatica presenti dopo i cambi di modalità; non basta confrontare due immagini vuote.
- Confronto pixel degli interni A/B allo stato finale e a effetto disabilitato: tolleranza massima di un byte per canale, nessun pixel oltre la soglia nei casi superati.
- Ispezione visiva di dado, conteggio, maschera, riflesso e luce: comandi visibili a 720p e 1080p; nessun pannello tagliato. Gli screenshot sono stati realmente aperti e controllati.

**Difetto trovato e corretto nel laboratorio:** il primo audit cambiava modalità video dopo la preparazione dei Canvas e li mostrava vuoti. Il semplice test di uguaglianza passava erroneamente per gli effetti 3–5. Sono stati aggiunti ridisegno dei Canvas esistenti dopo `setMode`/`love.resize` e controlli di contenuto non vuoto. La seconda esecuzione mostra effettivamente ornamento, medaglia e banco. Non è una correzione al motore di Manuscript.

Revisione indipendente del codice eseguita; nessun problema segnalato nella logica/alpha. La scoperta successiva dei Canvas vuoti dimostra perché la revisione non sostituisce l'ispezione grafica. I fallback degli shader sono presenti, ma il percorso di compilazione fallita non è stato provocato sul driver usato.

Due comandi iniziali di discovery Python non erano adatti al repository: importavano lo script CLI `test_luajit.py` come unittest oppure non risolvevano `love_runtime`. Non sono regressioni del gioco; il comando canonico diretto sopra ha eseguito i quattro test con successo.

## Prestazioni: cosa misurano i numeri

Dati completi dello storico audit: [metrics.csv](../experiments/fx_lab/audit/metrics.csv), [runtime.txt](../experiments/fx_lab/audit/runtime.txt), [pixel-checks.csv](../experiments/fx_lab/audit/pixel-checks.csv).

Ogni caso ha dieci frame iniziali esclusi e 54 campioni. Il costo di disegno è **tempo CPU di invio dell'intero laboratorio**, compresi entrambi i pannelli e l'interfaccia. Il modello viene aggiornato realmente, poi la posa di disegno è riportata a metà animazione per il confronto. Non è un benchmark della fluidità di una partita né della durata reale della sequenza. Lettura Canvas, acquisizione PNG e controlli pixel sono fuori dall'intervallo di disegno misurato, ma possono influire indirettamente sul carico del processo.

L'ultima misura osservata è circa **0,12–0,19 ms CPU di disegno** per caso e **0,00018–0,0019 ms** per l'aggiornamento del piccolo modello. Questi valori molto piccoli sono sensibili a scheduler, warmup e risoluzione del timer: differenze negative fra animato e disabilitato sono rumore, non un'accelerazione dimostrata. Il CSV dell'ultima esecuzione è l'evidenza autorevole.

| Effetto | CPU draw 720p animato / spento (ms) | CPU draw 1080p animato / spento (ms) |
|---|---:|---:|
| Trasferimento | 0,163 / 0,136 | 0,152 / 0,159 |
| Conteggio | 0,144 / 0,160 | 0,188 / 0,148 |
| Inchiostro | 0,170 / 0,130 | 0,149 / 0,164 |
| Oro | 0,154 / 0,163 | 0,155 / 0,121 |
| Luce | 0,138 / 0,131 | 0,178 / 0,118 |

33 draw call per il trasferimento, 40 per il conteggio, 36 per gli altri studi nei casi misurati; texture memory riportata da LÖVE **2.397.600 byte**. Non è il totale della RAM/VRAM del processo. Dimensione dei Canvas costante alle due risoluzioni; aumenta invece il numero di pixel sullo schermo.

**Tempo GPU non misurato.** Le misure CPU non dimostrano che shader, compositing o LÖVE siano privi di colli di bottiglia su altre schede. La macchina non è stata isolata da tutte le altre applicazioni. Non viene attribuito alcun miglioramento prestazionale al gioco principale, che non è stato modificato.

## Evidenze visive (rigenerabili)

I **20 PNG dello storico audit** (5 effetti × 2 risoluzioni ×
animato/disabilitato) sono stati rimossi dal repository il 31 ottobre 2026:
sono catture generate, non asset di gioco. Restano recuperabili tramite
la cronologia Git precedente alla pulizia oppure rigenerabili con:

```powershell
powershell -ExecutionPolicy Bypass -File experiments/fx_lab/audit.ps1
```

I nuovi screenshot saranno salvati localmente in
`experiments/fx_lab/audit/` e ignorati da Git. I tre report testuali
storici riportati sopra restano tracciati e verificabili.
Una cattura statica non dimostra il ritmo di animazione: per questo
occorre comunque osservare Replay/Repeat nel laboratorio LÖVE.

## Graduatoria per un'eventuale integrazione

| Priorità | Effetto | Motivazione / condizione prima di promuoverlo |
|---|---|---|
| 1 | Trasferimento del dado | Chiarisce la destinazione della risorsa e la differenza fra selezione e accantonamento. Confrontare con il trasferimento già presente, preservando identità, picking e sei dadi; non sostituirlo solo perché questo esempio è nuovo. |
| 2 | Conteggio progressivo | Spiega il contributo al totale. Provare con punteggi reali e possibilità di saltare, senza ritardare incasso o nuovo turno. |
| 3 | Rivelazione d'inchiostro | Lega il risultato al manoscritto con una superficie stabile. Serve un evento di progressione significativo e un ornamento originale definitivo. |
| 4 | Riflesso della medaglia | Conferma locale a basso ingombro. Richiede un significato univoco e verifica che le cariche restino più leggibili del riflesso. |
| 5 | Luce sul banco | Coerente con l'ambiente, ma beneficio decisionale più debole. Mantenere solo se la prova A/B lo preferisce senza perdita di contrasto. |

Questa graduatoria è un giudizio progettuale motivato, **non un risultato di playtest**. Il laboratorio non include l'HUD della partita, quindi l'assenza di sovrapposizioni nei pannelli non dimostra compatibilità con tutti gli stati reali del Farkle. Per ciascuno: confronto effetto spento/acceso, poi modalità ridotta, 720p/1080p, durata breve e ripetizione per almeno dieci azioni. Annotare comprensione dell'evento, attesa percepita e distrazione; non premiare soltanto lo spettacolo.

## File e rollback

Creati soltanto il laboratorio, i due rapporti e le evidenze sotto `audits/fx-study/`. [Manifest prima](audits/fx-study/production-before.json) e [verifica dopo](audits/fx-study/production-after.json): **164 file attivi invariati**. Nessun `.love` nel laboratorio, nessuna modifica a fisica, geometria, camera, probabilità, regole o HUD di produzione.

Per smettere di usarlo basta chiudere il laboratorio e continuare ad avviare Manuscript con `love .`. Nessun rollback del gioco necessario; non eliminare gli audit storici. L'eventuale futura promozione richiede una decisione separata.
