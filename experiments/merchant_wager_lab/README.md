# Merchant Wager Lab — esperimenti opt-in

Laboratorio opt-in per esperimenti sul Farkle. Le modalità V2, V3 e Il
Correttore sono separate e non modificano il gioco principale.

## Avvio e matrice delle nove partite

```bat
experiments\merchant_wager_lab\run_lab.cmd
experiments\merchant_wager_lab\run_lab.cmd --seed 12345
experiments\merchant_wager_lab\run_lab.cmd --analyze
experiments\merchant_wager_lab\run_lab.cmd --simulate 500 --seed 1
```

Nella schermata iniziale scegli la modalità; per V2, seleziona una variante e
un seed oppure inserisci un intero da 1 a 2147483646, poi premi **Inizia**.
Per un confronto accoppiato
gioca tutte le nove combinazioni, preferibilmente nell'ordine indicato:

| Seed | Partita 1 | Partita 2 | Partita 3 |
|---:|---|---|---|
| 101 | A — Controllo | B — Inseguimento | C — Alta posta |
| 202 | A — Controllo | B — Inseguimento | C — Alta posta |
| 303 | A — Controllo | B — Inseguimento | C — Alta posta |

Il selettore offre già i seed 101, 202 e 303; gli stessi seed sono anche
modificabili manualmente. **Non significa che le partite siano identiche:**
scelte e rilanci differenti cambiano quanti valori casuali consuma ciascun
contendente e quindi la sequenza successiva del suo flusso.
`--seed N` apre la scelta con `N` già inserito; `--simulate` esegue il
diagnostico automatico storico, non sostituisce le nove partite umane.

Per seed `s`, il generatore usa Park–Miller: `x = (x * 16807) % 2147483647`,
valore D6 `1 + floor(x / 2147483647 * 6)`. Il flusso dell'Artista parte da
`s`; quello indipendente del Mercante da `1 + ((s * 48271) % 2147483646)`.
Un contendente non consuma il flusso dell'altro. Le varianti non cambiano
questi seed o il comportamento dell'IA.

Comandi in partita: clic o tasti **1–6** selezionano i dadi, **Spazio** lancia
o rilancia, **A** accantona, **I** incassa, **V** vede, **P** passa, **R**
ricomincia con lo stesso seed e variante, **Esc** torna alla scelta A/B/C.
Il vantaggio corrente è sempre mostrato sopra la plancia.

## Condizioni

| Variante | Punteggio iniziale Artista/Mercante | Fogli totali ciascuno | Deposito iniziale ciascuno | Piatto iniziale |
|---|---:|---:|---:|---:|
| A — Controllo | 0 / 0 | 4 | 1 | 2 |
| B — Inseguimento | 0 / 30 | 4 | 1 | 2 |
| C — Alta posta | 0 / 0 | 4 | 2 | 4 |

La B registra 30 punti iniziali, senza turno fittizio. In C i quattro fogli
sono il totale, quindi la riserva inizia con due fogli a testa. Tutte le altre
regole restano comuni: sei D6 e Farkle di produzione per l'Artista; Mercante
con tre D6, selezione di maggior valore e un solo rilancio; rialzo da 30 punti;
Vedo/Passo; soglia 80 verificata alla fine del round completo; parità con
restituzione dei fogli depositati. Nessun vantaggio nascosto o IA adattiva.

Al termine di ogni partita il programma chiede pressione percepita
(nessuna/moderata/forte), se il Mercante ha influenzato il banking
(sì/no/non saprei), l'influenza principale (vantaggio, fogli, rischio Farkle,
nessuna) e note facoltative. La motivazione è inserita dal tester, mai dedotta
dalle azioni.

## Prototipo — Il Correttore

Avvia `experiments\merchant_wager_lab\run_lab.cmd`, scegli **Il Correttore**,
seleziona uno dei seed 101/202/303 o inseriscine uno e premi **Inizia**.
L'Artista usa i sei dadi e il regolamento Farkle canonico. Il Correttore tira
sei dadi, accantona tutti i 4/5/6 (singoli 50 punti; tris 300, poker 600,
cinquina 1000, sestina 1500), rilancia obbligatoriamente sotto 300 punti e
da 300 tira un D6: 1–3 incassa, 4–6 rilancia. Dopo un Farkle perde il
provvisorio e ruba un foglio dal centro, oppure all'Artista se il centro è
vuoto.

Entrambi possono convertire 500 punti non spesi in un foglio dal centro.
Il giocatore può chiudere l'incontro tra i propri turni; termina anche quando
il centro è vuoto e tutti i fogli appartengono a un solo contendente. Vince chi
ha più fogli, con i punti non spesi come spareggio. Un seed genera flussi
Park–Miller separati per Artista e Correttore: ripete i flussi casuali, non
necessariamente la stessa partita se cambiano le decisioni.

Comandi: clic o **1–6** per selezionare dadi, **Spazio** per lanciare/rilanciare,
**A** per accantonare, **I** per incassare, **C** per comprare un foglio,
**O** per giocare il turno del Correttore, **Esc** per chiudere tra i turni,
**R** per ricominciare con lo stesso seed. Dopo la partita, inserisci quante
decisioni di banking hai cambiato e se la minaccia si è sentita (sì/parziale/no);
le motivazioni restano soggettive. Il prototipo conta come opportunità decisive
i tiri dell'Artista con almeno una selezione valida e mostra la quota riferita,
così i playtest possono confrontarla con la soglia-obiettivo del 40%.

## Modalità V3 — cassa tipografica

Avvia lo stesso launcher e scegli **V3** nella schermata iniziale:

```bat
experiments\merchant_wager_lab\run_lab.cmd
```

La V3 è un esperimento distinto: primo a due mani su un massimo di tre,
quattro fogli totali a testa e un foglio ciascuno nel piatto. Il Mercante
estrae due caratteri per l'offerta iniziale da una cassa pubblica di 20
(`V10×6`, `V20×5`, `V30×4`, `V40×2`, `X×3`). Ogni controfferta aggiunge un
carattere: `X` fa perdere la mano al Mercante. Il Farkle dell'Artista continua
a usare le regole canoniche di produzione. Non ci sono rialzi economici,
abilità o vantaggi dipendenti dalla variante.

Prima di una controfferta il programma mostra la probabilità esatta di
superare il risultato dell'Artista prima di estrarre `X`, calcolata dalla
composizione pubblica residua. Il Mercante continua con soglia 30% se è dietro
nelle mani, 50% in parità e 65% se è avanti; in caso di continuazione, il
carattere viene estratto solo dopo aver mostrato la decisione. Una cassa
esaurita rimescola tutti i 20 caratteri dagli scarti. La schermata V3 distingue il turno Farkle, la decisione del Mercante, la mano
conclusa e l'incontro concluso; mostra solo le azioni di gameplay valide nella
fase. I dadi accantonati e selezionati hanno anche etichette, non solo colori.
**E** apre/chiude i dettagli pubblici della cassa, con composizione iniziale,
residui, scarti, estrazioni della mano e rimescolamenti. **Spazio** lancia o
rilancia, **1–6** selezionano i dadi, **A** accantona, **I** incassa, **C**
esegue una decisione del Mercante, **N** inizia la mano successiva, **F** apre
il feedback al termine dell'incontro, **R** rigioca lo stesso seed e **Esc**
torna alle varianti (oppure chiude prima i dettagli della cassa).

Il seed inizializza flussi indipendenti per dadi dell'Artista e cassa del
Mercante: le scelte di un contendente non consumano la casualità dell'altro.
Rigiocare il seed riproduce i flussi, ma non garantisce un incontro identico
se cambiano le decisioni. Dopo l'incontro, il tester inserisce cinque risposte
di feedback e note facoltative; nessuna motivazione viene dedotta dai log.

La V3 scrive file separati nello stesso percorso LÖVE indicato sopra:
`merchant_v3_matches.csv`, `merchant_v3_hands.csv`,
`merchant_v3_decisions.csv` e `merchant_v3_feedback.csv`. Nessun file V2,
storico o `runs.csv` viene sovrascritto. È un test di game design, non una
validazione dell'equilibrio o prova statistica.

## V4 — Lira, soldo e denaro: Merchant Duel con scommesse

**Modalità sperimentale isolata.** Dalla schermata iniziale seleziona
**V4 — Duello monetario** (tasto **4**) e il seed; puoi abilitare o
disabilitare i rialzi per confrontare il comportamento delle due varianti.
L'esperimento V3 originale resta disponibile e non cambia.

- **Incisore:** Farkle canonico con sei D6 (clic o tasti 1–6 per
  selezionare, Spazio per lanciare, A per accantonare, I per incassare).
- **Mercante:** usa soltanto la cassa V3 con **20 caratteri**
  (`V10×6, V20×5, V30×4, V40×2, X×3`); l'IA può proporre,
  accettare o rifiutare un rialzo pre-roll secondo offerta iniziale,
  quantità residua pubblica e stato dell'incontro.
- **Valuta:** 1 lira = 20 soldi = 240 denari. Tutti gli importi sono
  **interi in denari**; la lira è una moneta di conto.
  Non esiste alcun cambio punti Farkle → soldi.
- **Patrimonio:** 1 lira ciascuno; ante iniziale 2 soldi ciascuno per
  ogni mano (piatto 4 soldi). Un rialzo, solo prima del primo tiro,
  aggiunge 2 soldi ciascuno al piatto (8 soldi).
  Non sono ammessi controrilanci, crediti, debiti o all-in.
- **Rifiuto e restituzione:** se una proposta non viene chiamata,
  il versamento aggiuntivo del proponente è restituito e il
  rifiutante perde soltanto la propria quota iniziale nel piatto.
  Ritiro volontario durante il turno Farkle disponibile con **P**.
- **Esito:** il punteggio incassato e l'offerta determinano il vincitore
  della mano, come in V3. Il vincitore ottiene il piatto. Primo a due
  mani su tre conquista l'incontro; insolvenza all'ante successiva
  provoca una sconfitta anticipata.
- **Registro:** tasto **E** per aprire/chiudere il libro mastro,
  con trasferimenti, saldi e piatto. Tasto **R** per rigiocare lo
  stesso seed e **Esc** per tornare agli esperimenti.

Il giocatore può proporre un rialzo prima di iniziare il lancio;
il Mercante risponde automaticamente secondo una policy
**deterministica e verificabile**. Quando è il Mercante a proporre,
l'Incisore vede **Accetta** o **Rifiuta e ritirati**.
Nessuna informazione futura del RNG dei dadi viene letta dalla policy.

### Trasparenza e test

Le soglie della policy sono **sperimentali**, non dimostrazioni di equilibrio.
Conserviamo la logica V3 del sacchetto, le sue controfferte e il
Farkle di produzione. Nessun file del gioco principale viene modificato.

CSV dedicati (nella cartella save del laboratorio):
`merchant_v4_matches.csv`, `merchant_v4_hands.csv`,
`merchant_v4_transactions.csv`, `merchant_v4_policy.csv`.
I CSV V2, V3 e Correttore non vengono sovrascritti.

Controlli:

```sh
lua5.4 tests/labs/merchant_wager_v3_test.lua
lua5.4 tests/labs/merchant_duel_money_test.lua
luajit tests/labs/merchant_duel_money_test.lua
```

La workflow GitHub `.github/workflows/merchant_money_lab.yml`
esegue gli stessi test e un avvio LÖVE automatizzato. Le somme
devono sempre soddisfare l'invariante
`wallet_artista + wallet_mercante + piatto = 480 denari`.

## Dati e riepilogo

In Windows i file sono nella cartella di salvataggio LÖVE
`%APPDATA%\LOVE\project-folio-merchant-wager-lab\`, separata dal gioco
principale. Le colonne storiche di `merchant_matches.csv` e
`merchant_decisions.csv` restano intatte; il nuovo esperimento scrive:

- `merchant_matches_v2.csv`: id, variante, seed, punteggi iniziali e finali,
  posta iniziale e massima, esito, Farkle/rilanci, rialzi e fogli finali.
- `merchant_decisions_v2.csv`: decisioni dell'Artista con round, punteggi
  prima della scelta, differenza Mercante−Artista, provvisorio, dadi
  disponibili, azione e risultato del tiro successivo quando applicabile.
- `merchant_feedback_v1.csv`: risposte soggettive e note associate all'id.
- `merchant_summary_v1.csv`: riepilogo CSV generato da `run_lab.cmd --analyze`.
- I quattro registri V3 descritti sopra: incontro, mani, sequenza di decisioni
  dell'Artista e del Mercante, e feedback.
- Il Correttore scrive `corrector_matches_v1.csv`,
  `corrector_events_v1.csv` e `corrector_feedback_v1.csv`.

L'analisi stampa anche un riepilogo per variante: partite, vittorie/sconfitte/
parità, percentuale di vittoria dell'Artista, punteggi medi, rilanci e Farkle
medi, rialzi medi, banking dichiarato influenzato e distribuzione della
pressione. I rilanci non sono una misura autonoma della qualità delle scelte:
confrontarli con punteggi, svantaggio registrato nelle decisioni e feedback.
Nove partite sono un campione descrittivo, non una conclusione statistica.

Test isolati: `tests/labs/merchant_wager_lab_test.lua`,
`tests/labs/merchant_wager_v3_test.lua` e `tests/labs/corrector_test.lua`.
Nessun asset nuovo, fisica, medaglie, progressione o economia persistente.
