# Verifica conclusiva del fallback di generazione

15 ottobre 2026 — candidato isolato, **non promosso**. Il checkpoint attivo e il candidato precedente della fase 7 sono conservati.

## Difetto riprodotto e correzione locale

Sono stati ripresi soltanto gli 11 seed dei 600 lanci precedenti nei quali si verificavano cambi di lato: 54083, 54150, 54175, 56016, 56024, 56032, 56047, 56068, 56116, 56174, 56206. Il seed 56068 contiene due cambi, per un totale di 12 dadi.

**11 dei 12 dadi avevano una componente della velocità diretta verso l'esterno del nuovo lato.** Esempio riproducibile: seed 54083, dado 6, passaggio dal lato sinistro al destro, vx=+23,566676 invece di una direzione verso sinistra. Non è una mera differenza statistica: è una contraddizione geometrica fra posizione di generazione e direzione iniziale. Dati completi in `audits/engine3d/phase8/before/directions.csv`.

La sola modifica aggiuntiva è in `audits/engine3d/phase8/workspace/main.lua`, al momento di applicare le posizioni restituite da `Spawn.place` dentro `rollAllDice`:

- Si interviene **soltanto se il fallback cambia lato e la componente associata a quel lato è uscente**.
- Lati sinistro/destro: si inverte il segno di vx. Lati posteriore/anteriore: si inverte il segno di vy.
- L'altra componente orizzontale, vz, quota, posizione, orientamento e spin rimangono invariati. Il modulo della velocità, anche orizzontale, resta invariato per costruzione.
- Nessun nuovo prelievo RNG, nessuna scelta o correzione di facce. Il cambio di direzione avviene prima del primo passo fisico, non durante il moto.
- Il cambio di lato già diretto verso l'interno (seed 54175) resta invariato. Nessuna modifica ai tentativi sullo stesso lato.

La nozione di “interno” qui riguarda la direzione orizzontale dal lato di generazione, non una nuova normale di contatto del risolutore. La correzione non garantisce una traiettoria libera da successive collisioni o dai difetti preesistenti del bordo.

Il modulo `spawn_clearance.lua` è **identico** a quello approvato per conservazione: nessuna riprogettazione del SAT di spawn, dei tentativi, del margine o del fallback. Diff locale: `audits/engine3d/phase8/fallback.diff`. Rispetto al candidato precedente cambia un solo sorgente, `main.lua`.

## Verifiche circoscritte

Nessuna nuova campagna estesa: 39 lanci prima e 39 dopo, così ripartiti, oltre a prove mirate di integrazione e acquisizioni video.

| Gruppo | Numero per versione | Durata media prima → dopo | Overlap iniziali prima → dopo | Overlap finali prima → dopo |
| --- | --- | --- | --- | --- |
| Seed con fallback già noto | 11 | 5,126 → 3,158 s | 0 → 0 | 0 → 1 |
| Lanci normali, seed 58001–58008 | 8 | 4,854 → 4,854 s | 0 → 0 | 1 → 1 |
| Lanci consecutivi, seed iniziale 99801 | 20 | 3,559 → 3,640 s | 0 → 0 | 0 → 1 |

Tutti i lanci si concludono. Zero recuperi spontanei, timeout, risultati geometricamente invalidi accettati o discrepanze fra valore e faccia in questi gruppi. Zero passi con l'intero dado oltre uno stesso piano laterale del vassoio; questo non significa assenza di intersezioni parziali con il bordo.

Nei casi selezionati di fallback i passi con eccesso del bordo a quota bassa scendono in media da 354,64 a 228,45; nella sequenza aumentano da 262,15 a 303,50. Si tratta dell'osservatore della fase 7, non di collisioni uniche. Non si generalizzano questi piccoli campioni né si presenta la correzione come miglioramento universale delle collisioni. Le due nuove sovrapposizioni finali osservate sono limiti residui da dichiarare; non giustificano in questa fase interventi sul risolutore.

Il forte calo della durata nei seed di fallback non deriva da riduzione dell'energia iniziale: la vecchia spinta uscente viene ora rivolta verso l'interno. **La qualità visiva di questa differenza resta da approvare.**

### Invarianti e regressioni

- 19 coppie di lanci indipendenti, 114 dadi confrontati subito dopo la generazione: identiche posizioni, quote, vz e componenti angolari; identici valori assoluti di vx/vy. Cambia soltanto il segno previsto per 11 dadi. Stato RNG principale identico.
- Per i 12 dadi che cambiano lato, modulo completo della velocità, vz e modulo dello spin coincidono nei CSV prima/dopo. Nessuna componente uscente residua nei cambi osservati, incluso quello incontrato nella sequenza consecutiva.
- Gli 8 lanci normali conservano esattamente valori finali, durata, validità di arresto e metriche di recupero. Non si richiede che i lanci corretti producano gli stessi risultati numerici.
- Test di regressione reale seed 54083: fallisce sul candidato precedente (`red/test.txt`), passa dopo la correzione (`green/test.txt`).
- 17/17 file della suite generale superati; 2/2 suite Farkle/HUD superate. Log: `regressions.log`, `farkle.log`.
- Rilanci parziali {1}, {2,4,6}, {1,2,3,4,5} e completi, ciascuno con due disposizioni dei corpi esclusi: i dadi accantonati non influenzano lo spawn e rimangono invariati per tutta la simulazione. Verificato anche il percorso fisico del singolo dado pesato; la regola di accettazione pesata resta quella esistente, non ricalibrata.
- Esaurimento delle proposte forzato nell'harness: rollback dei corpi, nessuna variazione di punti o turno, retry fisico riuscito (`partial/partial.txt`).
- Compatibilità A/B verificata separatamente con una posa ambigua controllata: rifiuto del risultato, due recuperi automatici limitati, arresto tecnico senza loop infinito, retry manuale disponibile e stato Farkle invariato (`face-gate/observations.txt`). Le pose di test non vengono accettate artificialmente.
- Smoke fisico/rendering a 1280×720 e 1920×1080: bounds rispettati, picking 6/6, selezione valida da 100 punti in entrambe le risoluzioni. Immagini e log in `after/`. Non sono stati modificati renderer o HUD.

Il campione mirato non permette una nuova conclusione sulla distribuzione delle sei facce; non è stata cercata o imposta l'uniformità. Restano validi i limiti statistici dichiarati nella relazione precedente.

## Materiale per la conferma visiva

Cartella: `audits/engine3d/phase8/`.

- `confronto.html`: vecchio candidato e fallback corretto affiancati, ripartenza sincronizzata, seed 54083 e 56068.
- `confronto-54083.mp4`, `confronto-56068.mp4`: prima a sinistra, dopo a destra.
- `Avvia candidato.cmd`: copia giocabile corretta, `spawn-candidate.love`, salvataggi separati con identità `manuscript-spawn-reviewed`.
- `candidate-before.love`: pacchetto precedente preservato; la cartella della fase 7 non è stata modificata.

Video a velocità 1×: 6 secondi ciascuno, aggiornamento fisico richiesto a 60 Hz e acquisizione a 12 fps, codifica differita. Nessuna accelerazione né interpolazione. I log `before-video/observations.txt` e `after-video/observations.txt` riportano durata reale e ritardi di acquisizione. Il campionamento non permette di giudicare ogni singolo urto rapido.

Durata reale misurata circa 6,000 s per tutte le clip; ritardo massimo iniziale 81 ms prima e 90 ms dopo. Nel seed 56068 il vecchio candidato è ancora in movimento alla fine dei sei secondi: il filmato è troncato temporalmente, non si tratta di un timeout tecnico. Il candidato corretto ha concluso entrambi i lanci entro la finestra acquisita.

## Checkpoint e stato della promozione

93 file della versione attiva, pacchetto incluso, verificati contro il manifest precedente: **invariati**. Backup verificabile già conservato in `audits/engine3d/phase7/before.zip`; copia del manifest in `audits/engine3d/phase8/active-checkpoint.json`. Sorgenti del candidato corretto in `audits/engine3d/phase8/workspace/`.

Collisioni, contenimento, dimensioni, rendering, facce, punteggi, medaglie e probabilità deliberate non sono stati modificati. Non è stato introdotto un nuovo modello di lancio.

**Verifica tecnica mirata conclusa. Promozione sospesa in attesa della conferma dell'utente sulla qualità visiva del movimento.** Il prossimo passo previsto è la decisione su questo candidato, non un'altra campagna di ottimizzazione fisica.

Per ripetere i controlli senza toccare il checkpoint:

```powershell
rtk python audits/engine3d/run.py --source-root audits/engine3d/phase8/workspace --harness audits/engine3d/phase8/harness.lua --output audits/engine3d/phase8/after
rtk python audits/engine3d/run.py --source-root audits/engine3d/phase8/workspace --harness audits/engine3d/phase8/partial-harness.lua --output audits/engine3d/phase8/partial
rtk python audits/engine3d/run.py --source-root audits/engine3d/phase8/workspace --harness audits/engine3d/phase8/harness.lua --output audits/engine3d/phase8/face-gate --face-gate
rtk python audits/engine3d/phase8/finish.py
```

Le riesecuzioni sovrascrivono i rispettivi output diagnostici. `prepare.py` è una preparazione una tantum e rifiuta di sovrascrivere la copia già esistente.
