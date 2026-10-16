# Studio comparativo degli effetti visivi

15 ottobre 2026. Ricognizione locale in sola lettura e ricerca su fonti primarie; laboratorio originale in [experiments/fx_lab](experiments/fx_lab/). Nessuna promozione nel gioco principale.

## Esito e grado di verifica

Le sette installazioni sono state individuate. Sono verificati shader leggibili in Balatro e Slay the Spire, configurazioni di animazione in Dicey Dungeons e pacchetti di risorse negli altri titoli. **La ricognizione tecnica è più completa dell'osservazione temporale del gameplay**: non disponiamo di misure affidabili delle durate, delle curve di interpolazione e della sincronizzazione audio dei sette giochi. Non presento i valori scelti nel laboratorio come misure recuperate dagli originali.

Legenda usata nel catalogo:

- **O**: osservazione diretta della finestra del gioco; non prova l'implementazione.
- **F**: contenuto o metadato verificato nei file installati.
- **D**: documentazione primaria dello sviluppatore o del manutentore di uno strumento di modding.
- **P**: proposta indipendente per Manuscript, non tecnica attribuita al gioco.
- **NV**: non verificato. Un nome di file o di classe è un indizio, non la prova di un comportamento.

Le fonti delle community di modding documentano i rispettivi strumenti: non provano che ogni effetto della versione commerciale sia realizzato nello stesso modo. I post su prototipi e versioni alpha sono indicati separatamente.

## Installazioni e superfici di studio

| Gioco | Installazione verificata | Risorse pertinenti e limiti |
|---|---|---|
| Balatro | `S:/Hydra Games/Balatro/Balatro.exe` | Archivio ZIP incorporato: 304 voci, 19 shader fragment, 47 Lua, 136 PNG. Inventario di shader, uniform e nomi; nessuna traduzione delle implementazioni. |
| Dicey Dungeons | `S:/Dicey Dungeons/diceydungeons.exe` | Documentazione Polymod/Haxe/hscript, 20 JSON in `data/graphics/battle_fx`. Nessuno shader sciolto individuato. |
| Luck Be a Landlord | `S:/Hydra Games/Luck.be.a.Landlord.Build.16940935.SteamGG.NET/Luck.be.a.Landlord.Build.16940935/` | `Luck be a Landlord.pck`: header Godot 3.4.4, 2.127 record validati entro i limiti del file; 25 script compilati, 33 scene TSCN, 17 TRES, 865 STEX. Script non decodificati. |
| Slay the Spire | `S:/Hydra Games/Slay the Spire/` | `desktop-1.0.jar`: 11.434 voci, 7.038 classi, 86 atlas, 2.228 PNG, 515 JSON; shader vertex/fragment leggibili. Nessuna decompilazione Java. |
| Scriptorium | `S:/Scriptorium Master of Manuscripts/` | Unity 2022.3.62f2; `Scriptorium_Data/data.unity3d` con firma UnityFS, 2.326.486.934 byte. Oggetti interni non estratti. Versione menu osservata WIN_GOG_1.2.0. |
| BOOK OF HOURS | `S:/BOOK OF HOURS/` | `bh.exe`, Unity 2022.3.62f2; 12 `.assets`, 6 `.resS`, 4 `.resource`, 2 `.bundle`. `AllIn1SpriteShaderAssembly.dll` è soltanto un indizio nominale. |
| Inkulinati | `S:/Inkulinati/` | Unity 2022.3.9f1; 699 `.assets`, 60 `.resS`, 2 `.resource`, 156 CSV. Oggetti shader/materiali/animazioni non analizzati internamente. |

Le directory reali sono state risolte anche dai collegamenti desktop; alcuni collegamenti aprono un launcher, non direttamente un eseguibile Steam. Non è stata modificata alcuna installazione né verificata l'autenticità commerciale delle build. L'avvio normale dei giochi può creare salvataggi o impostazioni attraverso il gioco stesso; nessuna scrittura diretta nei file commerciali.

Nei tre giochi Unity non sono stati trovati file sciolti `.shader`, `.glsl`, `.hlsl`, `.cginc`, `.anim`, `.mat`: ciò **non** significa che questi contenuti non esistano nei pacchetti. `boot.config` non è stato trattato come configurazione degli effetti. Le versioni Unity derivano dai metadati di `UnityPlayer.dll`, non dall'aspetto grafico.

Evidenze riproducibili: [inventario archivi](audits/fx-study/archive-inventory.json), [parser originale](audits/fx-study/inventory_archives.py), [risultati archivi](audits/fx-study/archive-inventory.txt), [inventario Unity/Dicey](audits/fx-study/unity-inventory.txt). Gli inventari contengono percorsi, metadati e riferimenti; non raccolte di sorgenti o asset da riutilizzare.

### Riscontri tecnici specifici

- **Balatro, F:** `resources/shaders/CRT.fs:7–14` espone parametri temporali, distorsione, rumore e intensità CRT/bloom; `dissolve.fs:7–13` parametri di dissolvenza e colori del bordo; `polychrome.fs:7–14` parametri dell'edizione e della dissolvenza. Esistono shader distinti `foil`, `holo`, `polychrome`, `hologram`, `negative`, oltre a `engine/particles.lua` e `ShopSignAnimation.png`. Questo distingue superfici di implementazione, senza stabilire formule o tempi runtime.
- **Dicey, F:** `data/graphics/battle_fx/pack1/blind.json:1` è stato parsato: versione 5.2.1, circa 29,97 fps, intervallo circa 0–156, layer/asset/trasformazioni. La struttura è compatibile con Lottie/Bodymovin; il lettore concreto non è stato verificato. Circa **5,2 s è la durata nominale del file**, non una misura in partita: velocità, tagli e riutilizzi possono differire.
- **Dicey, F:** `data/MODDING.txt:3–9,41–61` documenta overlay e merge Polymod; `data/text/scripts/MODDING.txt:34–36,77–84` documenta Haxe Dynamic e istanze hscript. La sola presenza di `lime.ndll` non identifica con certezza il renderer.
- **Slay, F:** coppie vertex/fragment nelle directory `grayscale`, `outline`, `water`, `whiteSilhouette`, `blur`, `redSilhouette`; `defaultTemplate.pfx` e nomi come `CardTrailEffect`/`ChestShineEffect` sono piste, non conferme di uso o tempistica. Le voci ZIP omonime sono distinte nell'inventario tramite offset.
- **Luck, F:** scene `Effect Text.tscn`, `ALabelWithAnimation.tscn`, `AnimationExample.tscn`. La scansione delimitata delle risorse testuali non ha identificato dichiarazioni esplicite Animation/ShaderMaterial/ParticlesMaterial; effetti costruiti a runtime restano possibili.

## Catalogo comparativo

### Registro dell'osservazione diretta

Sessione locale del 15 ottobre 2026, screenshot puntuali attraverso Computer Use, non registrazioni continue:

| Gioco | Copertura diretta | Evidenza / cosa manca |
|---|---|---|
| Balatro | Menu CRT e schermata di selezione del buio, obiettivo 300 e risorse del round | [Screenshot](audits/fx-study/observations/balatro-blind.png). Input non avanzati in modo affidabile; conteggio, edizioni e ricompense non misurati. |
| Dicey Dungeons | Combattimento Warrior/Space Marine, pannelli equipaggiamento, dado e fumetto; variazione di posa fra snapshot | Screenshot nei risultati della sessione strumenti, non esportati in un file dedicato. Nessuna sequenza completa di inserimento o uso dell'equipaggiamento verificata. |
| Scriptorium | Menu e sandbox vuoto, carta, selezione tessera, tavolozza e tooltip dei materiali | [Screenshot](audits/fx-study/observations/scriptorium-materials.png). Nessun deposito riuscito della figura o conclusione della commissione osservato. |
| BOOK OF HOURS | Scena St Brandan's Cove: fondo granuloso, onde disegnate, velo atmosferico, punti luminosi, icone sature e pannello nero/oro nettamente separati | [Screenshot](audits/fx-study/observations/book-of-hours-cove.png). Non è una misura del moto delle onde/particelle o dell'illuminazione; nessuna attribuzione a uno shader particolare. |
| Slay the Spire | Primo combattimento completo, selezione/uso di Strike e Bash, passaggio di turno, stato Vulnerable, ricompense e scelta carta | Sequenza `spire-*.png` nella cartella osservazioni. Build V2.3.4 (12-18-2022). Creato dal gioco uno slot vuoto `fx`, nessun salvataggio preesistente sovrascritto. Audio e durata esatta NV. |
| Luck Be a Landlord | Build v1.2.24: nuova partita, griglia iniziale, primo spin, conteggio e scelta di un simbolo | Dialogo firewall gestito dall'utente. Screenshot `luck-*.png`; catene complesse e audio non osservati. |
| Inkulinati | Menu, Accademia, anteprima e creazione di due cani con spada nel tutorial | Build WIN_GOG_1.48.1.0. Screenshot `ink-*.png`; osservati contorni, posizioni, costo e risultato. Transitorio della mano non catturato dai campioni puntuali. |

L'automazione ha incontrato input manuali concorrenti e, in alcune finestre, input senza un avanzamento riproducibile. Dopo l'autorizzazione dell'utente sono state svolte altre osservazioni, ma la segnalazione di input concorrenti è ricomparsa. Non sono stati forzati salvataggi, riavvii di partite esistenti o controlli tramite metodi alternativi. Mancano quindi un campione temporale comparabile dei sette giochi e una valutazione audio: è un limite sostanziale dello studio, non una misura negativa della qualità dei giochi. I filmati ufficiali citati ma non visionati restano piste per completarlo.

Gli screenshot commerciali sono evidenze locali di analisi, separati dal laboratorio; non sono sue texture. Possono contenere overlay del desktop e non sono predisposti per pubblicazione.

Le durate e la sincronizzazione audio sono **NV per tutte le righe**, salvo la durata nominale JSON specificata sopra e l'esistenza documentata di hook audio. Le complessità B/M/A sono stime relative di una versione originale e circoscritta in LÖVE, non tempi di sviluppo o costi misurati dei giochi commerciali. Tutte le proposte qui sotto sono compatibili concettualmente con LÖVE 11; i cinque prototipi effettivamente eseguiti sono descritti nel rapporto separato.

### Balatro

| Effetto / momento / scopo | Comportamento ed evidenza | Versione indipendente per Manuscript; complessità e rischio |
|---|---|---|
| Conteggio durante la valutazione: rendere leggibili i contributi | D: Event Manager di Steamodded supporta eventi ordinati, attese ed easing anche dei punteggi. La sequenza completa vanilla non è stata osservata. | P: sorgente → incremento → totale, mantenendo separato il valore definitivo dalla presentazione. B; troppe tappe possono rallentare ogni turno. |
| Impulso/trasformazione della carta all'attivazione | D: easing/eventi disponibili; O: carte e pulsanti del menu con rilievo e campo CRT. Ampiezza, curva e impulso in partita NV. | P: piccolo sollevamento o scala locale dell'indicatore attivo. B; evitare movimento del bersaglio cliccabile. |
| Foil, Holographic, Polychrome: distinguere edizioni | F: shader distinti; D: shader key/draw callback delle edizioni. Differenze visive esatte non ricostruite da riproduzione diretta. | P: un solo riflesso dorato locale per la medaglia, senza riprodurre lo spettro o i motivi delle carte. M; fill rate e perdita di contrasto se applicato ovunque. |
| Dissolvenza di comparsa/rimozione | F: shader e parametri di dissolvenza. Sequenza e uso precisi NV. | P: maschera originale su un ornamento, conclusione immediata in modalità ridotta. M; bordi alpha e stato finale vanno verificati. |
| Attivazioni multiple | D: eventi `calculate` possono attendere quelli dei Joker precedenti nel framework. Non prova tutti i trigger vanilla. | P: fila breve di conferme causali, aggregazione quando numerosa. M; rischio di accumulare ritardi. |
| Transizioni turno/ricompensa | O: schermata di selezione del buio, obiettivo e risorse separati; coreografia di ricompensa NV. | P: lasciare il totale conclusivo stabile prima delle azioni successive. B; non bloccare comandi per una decorazione. |

Fonti: [Event Manager](https://docs.smods.dev/Guides/Event-Manager/), [edizioni](https://docs.smods.dev/Game%20Objects/SMODS.Center/SMODS.Edition/), [shader API](https://docs.smods.dev/Game%20Objects/SMODS.Shader-and-SMODS.ScreenShader/), [press kit ufficiale](https://www.playbalatro.com/press-kit/). Le API di modding sono un riferimento architetturale, non codice importato.

### Dicey Dungeons

| Effetto / momento / scopo | Comportamento ed evidenza | Versione indipendente; complessità e rischio |
|---|---|---|
| Movimento/collocazione dei dadi: collegare risorsa e slot | O parziale: combattimento con dado e slot; non è stata acquisita una sequenza affidabile di inserimento. D: uso dei dadi negli equipaggiamenti. | P: proxy grafico dal risultato alla raccolta; identità e valore devono restare stabili. B; sovrapposizione all'HUD e doppio disegno sono i rischi principali. |
| Conferma della selezione | O: slot e pannelli distinguibili; animazione di conferma NV. | P: contorno persistente prima della conferma, breve trasferimento soltanto dopo. B; non confondere selezione e consumo. |
| Equipaggiamenti che entrano in posizione | D: funzione `animateequipmentintoplace` esposta nella versione 1.11. | P: interpolazione verso una posizione stabile. B; non serve simulazione fisica per un pannello. |
| Effetti speciali / risposta del combattente | O: fumetto e variazione di posa in combattimento; F: timeline JSON; D: `squeak`, `reloadanimation`, suoni specifici degli equipaggiamenti. Audio non ascoltato/misurato. | P: una conferma visiva per sorgente, con eventuale suono già disponibile in Manuscript in una futura integrazione. M; evitare feedback multipli indistinguibili. |

Fonti: [versione 1.11](https://terrycavanagh.itch.io/dicey-dungeons/devlog/233105/dicey-dungeons-version-111), [alpha 13](https://diceydungeons.com/blog/2018/09/29/version-13.html), [alpha 15](https://diceydungeons.com/blog/2018/12/25/version-15.html), [equipaggiamenti](https://wiki.diceydungeons.com/doku.php?id=equipment), [modding](https://mods.diceydungeons.com/doku.php?id=start). I post alpha documentano l'introduzione di controlli di velocità e animazioni, non i dettagli della build installata.

### Luck Be a Landlord

| Effetto / momento / scopo | Comportamento ed evidenza | Versione indipendente; complessità e rischio |
|---|---|---|
| Sequenza di attivazioni | D: Effects espone ordine, `last`/`push_front` e animazioni circle/rotate/bounce/shake. Sequenza audiovisiva commerciale NV. | P: ordine causale comprensibile dei contributi. M; una coda generica complessa sarebbe sproporzionata per cinque effetti. |
| Reazione a catena | D: `anim_targets` distingue sorgente, vicino interessato e tutti i vicini. | P: evidenziare insieme origine e conseguenza, senza animare tutto il tavolo. M; molte pulsazioni simultanee cancellano la gerarchia. |
| Sinergie | D: campi trigger/effect/reminder, destinatari delle animazioni. | P: indizio locale della relazione che ha prodotto l'incremento. B/M; non attribuire una sinergia che la logica non ha effettivamente attivato. |
| Conteggio / trasformazione dei simboli | O: primo spin ridistribuisce i cinque simboli nella griglia; snapshot intermedio con importo 5 separato dal saldo 0, poi saldo 5 e pannello di scelta del nuovo simbolo. D: valore moneta, effetti e cicli di texture ordinati con immagine terminale. Durata e contributi individuali non misurati. | P: totale definitivo stabile e animazione soltanto rappresentativa. B; terminale visivo sempre identico con animazioni disattivate. |

Fonti primarie dello sviluppatore: [Effects](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Effects), [Modding Variables](https://github.com/TrampolineTales/LBAL-Modding-Docs/wiki/Modding-Variables), [aggiornamento modding](https://blog.trampolinetales.com/the-magnificent-modding-update-patch-notes/). Sono l'evidenza più precisa dello studio sul rapporto fra animazione e destinatari semantici.

Evidenze dirette: [prima dello spin](audits/fx-study/observations/luck-before-spin.png), [conteggio intermedio](audits/fx-study/observations/luck-spin-count.png), [scelta successiva](audits/fx-study/observations/luck-symbol-choice.png). La nuova partita parte da 1 moneta, arriva a 0 durante lo spin e a 5 dopo l'accredito; non deduco da questi tre frame l'algoritmo di animazione del contatore. Il comando Continue non ha aperto una partita; Start ha mostrato l'introduzione iniziale, senza richiesta di sovrascrittura.

### Slay the Spire

| Effetto / momento / scopo | Comportamento ed evidenza | Versione indipendente; complessità e rischio |
|---|---|---|
| Attivazione di una reliquia | O: Ironclad mostra Burning Blood e il recupero di 6 HP a fine combattimento (74→80); non catturato un eventuale flash dell'icona. D: hook `onEquip` e LandingSound di BaseMod riguardano acquisizione, non questo evento. | P: distinguere arrivo/equipaggiamento da consumo di carica. B; non usare lo stesso segnale per significati opposti. |
| Feedback di disponibilità/effetto | O: contorno ciano sulle carte giocabili, carta selezionata ingrandita/sollevata, freccia rossa arcuata verso il bersaglio e quattro marcatori gialli; a energia zero sparisce il glow delle carte e prevale End Turn. D/F: API glow e shader esistono, ma non ne è dimostrato il collegamento interno. | P: stato disponibile discreto e impulso solo all'evento. B/M; contorni troppo brillanti competono con i dadi. |
| Impatto e stato applicato | O: Strike produce una falce luminosa azzurra; Bash mostra scia calda, numero 8 vicino al nemico e parola Vulnerable con icona. Dopo il transitorio restano HP, blocco e stato sotto il bersaglio. | P: evento breve vicino al destinatario, seguito da indicatore persistente. M; evitare che la scia copra il numero. |
| Ricompense | O: dopo il combattimento sfondo oscurato, pannello centrale con oro e accesso alla scelta carta; incasso 99→110, riga rimossa; tre carte separate e pulsante Skip. F: `ChestShineEffect` non collegato a questa schermata. | P: conclusione prima della nuova scelta, salienza del solo contenuto utilizzabile. B/M; non serve una luce continua. |
| Passaggio fra fasi | O: banner Battle Start con spade; mano distribuita e poi assestata a ventaglio; Enemy Turn su fascia scura, mano rimossa e bottone rietichettato; nuova mano al ritorno del controllo. Tempi/audio NV. | P: segnale esplicito del controllo e posizioni terminali stabili. B; niente ritardi obbligatori. |

Fonti: [BaseMod Custom Relics](https://github.com/daviscook477/BaseMod/wiki/Custom-Relics), [Card Border Glow Manager](https://github.com/daviscook477/BaseMod/wiki/Card-Border-Glow-Manager), [press kit Mega Crit](https://www.megacrit.com/press-kits/slay-the-spire/). Non sono stati decompilati i corpi delle classi.

Evidenze dirette: [ingresso combattimento](audits/fx-study/observations/spire-battle-start.png), [bersaglio](audits/fx-study/observations/spire-target.png), [danno e blocco](audits/fx-study/observations/spire-hit.png), [stato applicato](audits/fx-study/observations/spire-status-impact.png), [energia esaurita](audits/fx-study/observations/spire-end-turn-ready.png), [turno avversario](audits/fx-study/observations/spire-enemy-turn.png), [Strike finale](audits/fx-study/observations/spire-final-strike.png), [ricompense](audits/fx-study/observations/spire-rewards.png), [scelta carta](audits/fx-study/observations/spire-card-reward.png). Sono snapshot in ordine causale, non una registrazione a frame rate noto: l'intervallo fra chiamate degli strumenti non misura la durata dell'effetto. Nell'ultima azione un frame con la scia era disponibile circa 233 ms dopo l'invio del clic; è un campione puntuale che include latenza di input/cattura, non la durata di Strike.

### Scriptorium: Master of Manuscripts

| Effetto / momento / scopo | Comportamento ed evidenza | Versione indipendente; complessità e rischio |
|---|---|---|
| Presentazione del manoscritto | O: libro aperto, pagine irregolari, piega centrale, cuciture, strati e coperta; il piano di lavoro rimane leggibile. D: composizione e sandbox. | P: contenuto progressivo su una superficie stabile. M; dettaglio di sfondo non deve degradare testo e dadi. |
| Carta e materiali | O: grana fine, variazione calda vicino alla piega, tavolozza con colori opachi/metallici e motivi. Metodo shader/materiali NV. | P: texture originale statica + effetto locale transitorio, non rumore animato su tutta la carta. M; alpha e scala della grana. |
| Composizione della pagina | O: selezione di una figura evidenzia la tessera e apre una tavolozza; tooltip sul materiale. Deposito della figura e sua animazione non verificati. D: elementi trascinabili. | P: maschera d'inchiostro soltanto come conferma della progressione; non attribuita a Scriptorium. M; non ritardare la lettura del risultato. |
| Decorazione e illuminazione | O: luce non uniforme e separazione carta/coperta/tessuto; D: personalizzazione luce e finestre. Dinamica della luce NV. | P: un accento caldo sul banco. M; mantenere bassa ampiezza, niente flicker. |

Fonti: [pagina ufficiale del gioco](https://store.steampowered.com/app/3119540/Scriptorium_Master_of_Manuscripts/), [Yaza](https://www.yazagames.com/home). [Gameplay ufficiale di un'ora](https://www.youtube.com/watch?v=o2wbUR70lcg) individuato ma non visionato con annotazione temporale: non usato come prova di durata.

### BOOK OF HOURS

| Effetto / momento / scopo | Comportamento ed evidenza | Versione indipendente; complessità e rischio |
|---|---|---|
| Atmosfera ambientale | D: intenzione di uno spazio accogliente, luce diurna e angoli a lume di candela; non prova un algoritmo di luce. | P: separare atmosfera tenue e segnali decisionali nitidi. M; oscurare i comandi non produce automaticamente atmosfera. |
| Illuminazione e cromie | D: direzione artistica e palette; variazioni temporali NV. | P: luce locale calda con inviluppo lento e limitato. M; costo proporzionale ai pixel, non al numero di oggetti fisici. |
| Interfacce | D: libri dalla grafica semantica riconoscibile dentro ambienti illustrati; post di sviluppo su zoom e finestre. Comportamento finale non dedotto dai prototipi. | P: icone leggibili sul banco materico. B; ridurre la decorazione vicino ai numeri. |
| Oggetti e superfici | D storico: prototipo 2019 con Surface, accatastamento e inclinazione su scaffale; non conferma della build corrente. | P: breve lift/settle grafico verso una sede visibile. M; non usare questi post per giustificare nuove collisioni. |

Fonti: [direzione artistica dei libri](https://weatherfactory.biz/boh-the-early-draft-edition/), [lancio ufficiale](https://weatherfactory.biz/book-of-hours-is-out-now/), [prototipo 2019](https://weatherfactory.biz/in-which-weather-factory-invents-the-3rd-dimension/), [UI in sviluppo](https://weatherfactory.biz/shutter-the-windows-against-the-sea/), [locmod ufficiali](https://weatherfactory.biz/book-of-hours-locmod-creation-reference/). I locmod documentano sostituzioni localizzate di immagini, non un'API generale degli shader.

### Inkulinati

| Effetto / momento / scopo | Comportamento ed evidenza | Versione indipendente; complessità e rischio |
|---|---|---|
| Inchiostro e creazione | O: costo 5, saldo 10→5 alla prima creazione e 5→0 alla seconda, poi risorsa 3 al passaggio successivo; figura colorata e identificata sulla pagina. D: Living Ink. Shader di diffusione NV. | P: frontiera irregolare originale che scopre un ornamento. M; non simulazione fluidodinamica. |
| Apparizione delle figure | O: anteprima al solo contorno, sedi turchesi, camera che centra/ingrandisce la zona durante la conferma; risultato colorato con nome, HP e simbolo di sonno. D: grande mano; il transitorio del tratto non catturato, durata NV. | P: rendere visibile una trasformazione di stato, senza importare la mano o i personaggi. M; coreografie lunghe penalizzano azioni ripetute. |
| Tratteggi e contorni | O: contorno scuro e campiture piatte, carta granulosa e piegata, fondali desaturati e poco contrastati, figure leggibili davanti. D: ispirazione alle marginalia. Implementazione e animazione dei contorni NV. | P: tratteggio statico originale, rivelato localmente. B/M; aliasing a 720p. |
| Impatti coerenti con pergamena | D: azioni della mano, spinte, barriere e colpi. Particelle, shake e maschere specifiche NV. | P: piccolo accento d'inchiostro confinato all'evento. M; evitare di sporcare valori e bersagli interattivi. |

Fonti: [descrizione ufficiale](https://store.steampowered.com/app/957960/Inkulinati/), [comunicato Daedalic del 22 febbraio 2024](https://daedalic.prezly.com/wield-thy-quills-inkulinati-is-out-now-for-ye-olde-pc-nintendo-switch-playstation-and-xbox). Il filmato pre-release segnalato dallo sviluppatore nel 2021 non è una prova del runtime corrente.

Evidenze dirette: [anteprima](audits/fx-study/observations/ink-preview.png), [prima figura creata](audits/fx-study/observations/ink-created.png), [due figure e cambio di stato](audits/fx-study/observations/ink-two-created.png). Questi snapshot verificano il cambiamento, non una rivelazione progressiva o una simulazione dell'inchiostro. Il laboratorio resta un'implementazione concettuale indipendente; la sua maschera non è attribuita al renderer di Inkulinati.

## Licenze e possibilità di riuso

**Non è stato importato codice da nessuna delle fonti.** I cinque prototipi usano Lua/GLSL e geometria procedurale scritti per questo laboratorio, con il font predefinito di LÖVE. I termini sotto sono una verifica di ambito, non un'autorizzazione estesa agli asset commerciali.

| Componente / provenienza | Licenza verificata | Obblighi e decisione per Manuscript |
|---|---|---|
| [Steamodded](https://github.com/Steamodded/smods/blob/main/LICENSE) | GPL-3.0 del framework | Una sua integrazione richiederebbe valutare gli obblighi GPL di distribuzione e sorgenti. Non utilizzato; non autorizza shader o grafica di Balatro. |
| [BaseMod](https://github.com/daviscook477/BaseMod/blob/master/LICENSE) | MIT, copyright 2018 t-larson | Conservare avviso e licenza in copie sostanziali; non copre il gioco. Tecnologicamente non serve a questo laboratorio Lua. Non utilizzato. |
| Dipendenze nel JAR Slay | Avvisi Apache-2.0 | Conservare licenza/avvisi e NOTICE applicabili, segnalare modifiche quando richiesto. L'associazione di ogni risorsa a un avviso non è risolta: nessun riuso proposto. |
| Mod Dicey `frogurt` | Codice `.hscript/.hs` MIT-form; altri file CC BY 4.0 | Ambiti distinti, attribuzione e indicazione modifiche per asset CC. Non estendere a `.hx` o gioco base. Nulla importato. |
| Mod Dicey `reunion` | Asset limitati a progetti Polymod Dicey salvo permesso scritto | Nessun fondamento per riuso in Manuscript. |
| Wiki modding Dicey | CC BY-SA 4.0 per i contenuti, salvo eccezioni | Attribuzione e share-alike per adattamenti del testo; qui sintesi originale e link, nessun asset copiato. |
| Altri file commerciali / pacchetti | Nessuna licenza di riuso pertinente stabilita | Installazione o presenza di una EULA non autorizza importazione. Solo studio concettuale. |

`data/text/licenses/README.txt` di Dicey dichiara esplicitamente che i modelli di licenza non licenziano Dicey/Haxegon. L'EULA Inno Setup di Scriptorium riguarda l'installer. Le librerie presenti o nominate non sono state automaticamente qualificate come open source senza una licenza pertinente.

## Principi scelti e limiti

1. **Causalità prima dello spettacolo:** mostrare chi produce un effetto e quale valore cambia; il conteggio deve terminare sul valore reale.
2. **Posizioni finali stabili:** il trasferimento grafico deve chiarire dove è finita una risorsa, senza cambiarne identità o fisica.
3. **Materiali persistenti, segnali transitori:** carta e legno restano quieti; un riflesso indica un evento, non diventa un rumore continuo.
4. **Tempo separato dalle regole:** salto/riduzione dell'animazione deve lasciare lo stesso esito.
5. **Effetti locali:** nessun post-processing globale necessario per i cinque studi.

La valutazione di soddisfazione, ritmo audiovisivo e interferenza con l'HUD richiede ancora una prova umana in situazione. Il laboratorio permette tale confronto ma non ne anticipa il risultato. Tempi dei giochi, sincronizzazione audio, prestazioni GPU dei riferimenti e algoritmi interni Unity restano sconosciuti. Le evidenze locali non sono asset del laboratorio e non devono diventarlo.

La graduatoria operativa, i risultati misurati e i controlli sono in [FX_PROTOTYPES.md](FX_PROTOTYPES.md).
