# Integrazione del game feel

Data: 15 ottobre 2026. Applicazione principale avviabile con `love .` o `Avvia.cmd`; nessun pacchetto `.love` generato.

## Risultato e confini

Il ripiano mostra copie grafiche dei dadi realmente accantonati, con un trasferimento di 0,52 secondi. Il punteggio viene presentato progressivamente in 0,70 secondi, con contributi delle combinazioni e bonus della medaglia distinti. La conclusione del turno mostra incasso/perdita, obiettivo e turni rimasti; il comando esistente per proseguire resta subito disponibile.

La fisica, i risultati, le commissioni e le medaglie rimangono autoritativi e immediati. Non attendono gli effetti. Non sono state modificate regole, probabilità, spawn, contenimento, camera, geometria, texture, renderer triangolato, validazione A/B o frontend. Non è stata aggiunta un'animazione del manoscritto.

## Ripiano e vassoio

`presentation.lua` osserva lo stato `used`: selezionare non trasferisce; confermare trasferisce. Ogni elemento conserva indice fisico, valore, numero del lancio accettato, turno e commissione. I recuperi tecnici non creano nuovi gruppi logici. I sei posti sono ordinati per identità del dado; i vuoti sono intenzionali. La riga compatta indica `D` (dado), valore e `T` (tiro di origine).

`tray_view.lua` ricava il bordo anteriore dalle coordinate già proiettate del vassoio. Non cambia la proiezione: aggiunge soltanto i riferimenti per la scenografia del ripiano.

`presentation_view.lua` acquisisce, una volta per accantonamento, i comandi grafici prodotti dal renderer esistente usando copie dei vertici e una posizione grafica all'origine. Conserva orientamento e materiali della posa accettata. La traslazione verso il ripiano è esclusivamente grafica; nessun corpo viene spostato o integrato. Si usa la stessa scala dei dadi nel vassoio. Il trasferimento adotta un'interpolazione cubica e un piccolo arco, adattando il principio del laboratorio FX alla proiezione reale.

Il filtro già esistente esclude i dadi `used` sia dal vassoio sia dal picking. La copia sul ripiano non registra hitbox. Non viene disegnata contemporaneamente una seconda copia nel vassoio. Hot dice, nuovo turno e nuova commissione rimuovono i vecchi elementi tramite lo stato logico; i rilanci parziali conservano quelli accantonati.

**Persistenza:** nella versione ricevuta l'inquadratura era già basata su un inviluppo fisso, non sulle posizioni istantanee dei dadi. Non ho introdotto un'altra correzione della camera. Nei video prima/dopo, a 1280×720, centro e scala restano costanti: `cx=483,333333`, `cy=405,173527`, `scala=89,802108`. La ricomparsa descritta non è stata riprodotta nel percorso corrente.

## Punteggio e ritmo

Prima di accantonare/incassare viene conservata la partizione disgiunta già calcolata da `rules.selection_option`: identità dei dadi, etichetta e punti. Nessuna seconda valutazione delle combinazioni. Il registro del turno conserva anche contributi dei tiri precedenti; all'incasso il bonus è la differenza fra incremento reale della banca e base registrata.

Il contatore interpolato è una presentazione, non una seconda banca. La riga di rischio e i comandi usano sempre i valori reali. Oltre due contributi vengono raggruppati; il bonus resta separato. La sequenza occupa temporaneamente la prima riga del pannello azioni, senza aggiungere pannelli o spostare i comandi. Una perdita cancella il contatore precedente.

| Effetto | Durata normale | Interruzione |
|---|---:|---|
| Trasferimento al ripiano | 0,52 s | Tab, rilancio, impostazione animazioni ridotte |
| Conteggio | 0,70 s | Tab, rilancio, cambio turno, animazioni ridotte |
| Accento della conclusione | 0,45 s | Tab, cambio turno, animazioni ridotte |

Le animazioni ridotte applicano subito la posa e il valore finali. Non esiste una nuova attesa obbligatoria. Il comando «Prossimo turno» resta quello esistente. La progressione del folio continua a usare i dati logici già presenti.

## Audio originale

Cinque cue sintetizzati una sola volta e riutilizzati attraverso `AudioManager`: accantonamento/conferma combinazione (0,13 s), incasso (0,24 s), perdita (0,18 s), hot dice (0,27 s), medaglia (0,20 s). Risonanze smorzate con attacco breve; nessun campione commerciale, nuova dipendenza o consumo del generatore casuale.

Conferma e accantonamento sono lo stesso evento: un solo suono. Hot dice sostituisce il cue ordinario. L'incasso diretto emette il cue di incasso. Una medaglia che incassa produce due eventi distinti, attivazione e incasso. Un Farkle recuperabile non emette prematuramente il suono di perdita definitiva. I recuperi fisici A/B non attivano cue di medaglia.

Volume generale, volume effetti e disattivazione passano dalle impostazioni esistenti. Le osservazioni ripetute dello stesso stato non ripetono i suoni. La gradevolezza timbrica resta da valutare all'ascolto da parte dell'utente: non viene dedotta dai test automatici. I video prodotti sono senza traccia audio.

## File

Produzione, sei file modificati:

- `src/core/audio_manager.lua`: cue originali e instradamento nel mixer esistente.
- `src/features/farkle/controller.lua`: collegamento agli eventi reali, fotografia dei contributi, Tab.
- `src/features/farkle/presentation.lua`: registro grafico, conteggio, durate, eventi.
- `src/features/farkle/presentation_view.lua`: ripiano, copie grafiche, contributi e conclusione.
- `src/features/farkle/tray_view.lua`: coordinate del bordo per il ripiano.
- `src/features/farkle/hud.lua`: contatori e messaggio contestuale integrati.

Diagnostica modificata: `scripts/capture_turn_feel.py`, `tests/smoke/turn_feel.lua` (tempi CPU, limite di acquisizione, esito incompleto ora esplicito).

Tre test aggiunti: `tests/game_feel_test.lua`, `tests/game_feel_audio_test.lua`, `tests/game_feel_events_test.lua`. Il laboratorio `experiments/fx_lab/` è conservato integralmente e non viene importato nel runtime.

## Evidenze e verifiche

Baseline: 26/26 file di test Lua superati. Dopo: 29/29, compresi contatore e bonus, skip, animazioni ridotte, cue memorizzati, mute, attivazioni illegali e deduplicazione degli eventi nel controller. Le suite preesistenti coprono Farkle, hot dice, soglie, gruppi disgiunti, medaglie, facce, spawn e calendario fisico.

Comandi riproducibili dalla radice:

```text
rtk proxy python scripts/test_luajit.py
rtk proxy python scripts/run_smoke.py all --out audits/game-feel-integration/final
rtk proxy python scripts/capture_turn_feel.py audits/game-feel-integration/after-video
```

Le impostazioni degli smoke sono isolate. La suite fisica comprende rilanci di 1, 3, 5 e 6 corpi, corpi accantonati invariati, rollback dello spawn esaurito, recupero di pose ambigue, dadi normali/incisi/pesati, rilanci selettivi delle medaglie, hot dice e corrispondenza delle facce accettate. Non è una nuova verifica statistica delle probabilità.

Gli smoke HUD comprendono entrambe le risoluzioni, selezione mouse, accantonamento 1–6, rilancio, Farkle, incasso, hot dice, medaglie, reward e stati terminali. **Distinzione:** i casi rari predisposti mediante `feed` assegnano valori logici per verificare l'HUD, senza orientare i corpi fisici. I loro screenshot non dimostrano corrispondenza fra texture e risultato; per questa verifica valgono i lanci fisici e il video reale. Non è stata alterata la fisica per abbellire le fixture.

La sequenza filmata usa il lancio fisico seed 54083: prima lettura `5/5/6/1/3/5`, scelta, accantonamento, rilancio e passaggio al turno successivo. Il video successivo arriva a `phase=done`. La vecchia acquisizione si arrestava a 40 secondi in `phase=ended`: conserva il confronto visivo, ma non costituisce prova completa del cambio turno. Il nuovo harness segnala esplicitamente una cattura incompleta.

Evidenze in `audits/game-feel-integration/`:

- `before/turn-feel.mp4`, `before/held.png`: precedente presentazione.
- `after-video/turn-feel.mp4`, `after-video/held.png`, `frames.csv`, `turn-feel.log`: sequenza reale e misure.
- `final/hud/`: screenshot e log a 1280×720 e 1920×1080.
- `final/partial/`, `final/face-gate/`, `final/integration/`, `final/frontend/`: log delle verifiche integrate.

## Prestazioni e limiti

225 aggiornamenti/disegni misurati nella partita reale durante l'acquisizione a 1280×720:

| Misura CPU, ms | Media | p95 | Massimo |
|---|---:|---:|---:|
| `love.update` applicativo | 0,888 | 1,857 | 6,317 |
| `love.draw` applicativo | 1,254 | 1,486 | 97,282 |

Il timer esclude la richiesta di screenshot e la codifica PNG, ma il carico dell'acquisizione influenza la cadenza. Il massimo include il caricamento iniziale. Sono tempi CPU di invio del disegno, **non** tempi GPU né una certificazione degli FPS. Il video preserva i timestamp reali e può mostrare scatti da acquisizione: 225 immagini su circa 41 secondi. Non attribuire questa durata alle sole animazioni del gameplay. Non è disponibile una misura CPU precedente comparabile, quindi non viene dichiarato un miglioramento prestazionale quantitativo.

Nessun nuovo Canvas/shader per frame o post-processing globale. Le closure del dado vengono generate una volta per accantonamento; audio generato e memorizzato al primo uso. Permangono le allocazioni preesistenti del renderer. Non sono stati corretti i limiti fisici noti di compenetrazione. La qualità percepita e il timbro richiedono una prova manuale; i test attestano correttezza dei collegamenti, non divertimento.

## Checkpoint e rollback

`audits/game-feel-integration/checkpoint.zip`: 553 file, verificati SHA-256 contro `checkpoint-manifest.json`, inclusi sorgenti, risorse, laboratorio e materiali legacy. Gli audit e backup storici preesistenti sono rimasti in loco, senza duplicare circa 32 GB di audit nell'archivio. Il checkpoint è una copia eseguibile completa del progetto, non una seconda copia di tutti i dati storici.

Per tornare alla versione precedente, chiudere LÖVE, estrarre il checkpoint in una cartella temporanea, confrontare il manifest e ripristinare **solo gli otto file modificati elencati sopra**. Rimuovere facoltativamente i tre nuovi test e questo rapporto. Non sovrascrivere eventuali modifiche successive dell'utente, salvataggi o impostazioni. Conservare audit e video.

Il confronto finale con il manifest verifica 105 file protetti invariati nelle cartelle `src/engine3d`, `src/gameplay`, `src/app`, `resources` ed `experiments/fx_lab`.
