# Il Opponent e la posta — Opponent Duel Lab

**Un solo prototipo giocabile: V4, duello asimmetrico Farkle + cassa del Opponent.**
I prototipi V2, V3 come modalità autonoma e Il Correttore sono stati ritirati:
la loro storia resta consultabile nei commit Git, non nel menu o nel codice attivo.
La logica delle offerte e del sacchetto di V3 è conservata in `duel.lua` e
`box.lua`, poiché costituisce il motore avversario della V4.

## Avvio

Da Windows:

```bat
experiments\opponent_wager_lab\run_lab.cmd
experiments\opponent_wager_lab\run_lab.cmd --seed 101
experiments\opponent_wager_lab\run_lab.cmd --money-simulate 100 --seed 101
```

**La V4 parte direttamente:** niente scelta fra prototipi obsoleti.

L'Incisore gioca sempre con **sei D6 e il regolamento Farkle canonico**
di `src/farkle/rules.lua`. Il Opponent usa una cassa pubblica di
20 token: **V10×6, V20×5, V25×4, V55×2, X×3**.
Le due tessere V55 sono volutamente rare: consentono al Opponent
controfferte più forti senza aumentare molto l'offerta media.
La precedente distribuzione **V10/V20/V30/V40** rimane disponibile
come riferimento nel simulatore, non è più il profilo predefinito V4.
La cassa pesca senza reinserimento fino all'esaurimento e poi ricostituisce
il contenuto dagli scarti. Non ci sono carte per il giocatore.

## Bilanciamento del confronto Farkle / token

La V4 utilizza il profilo **tail** scelto dopo un confronto preliminare
a seed appaiati (200 partite per combinazione). Con la policy Farkle
`balanced`, nella simulazione precedente l'Incisore aveva vinto 50%
senza rialzi e 51,5% con il vecchio sistema. Questi risultati **non
misurano il nuovo rialzo volontario**, che richiede ricalibrazione.
I token comuni sono da 10/20/25 punti;
il raro da 55 punti aumenta l'ampiezza delle offerte possibili
(prima 80 punti massimo nei primi due token; ora 110)
senza alterare i 20 token né il numero di X.

Attenzione: i valori dei token NON devono imitare il massimo di una
combinazione Farkle. L'avversario può sommare estrazioni e
controfferte; risultati Farkle eccezionali devono restare premianti.
La probabilità di un X iniziale resta circa 28,4% e oggi fa vincere
direttamente la mano all'Incisore: è una **regola separata da
rivalutare** e un limite di questo test. Non interpretare il tasso
globale di vittorie come prova definitiva di equità.

`money_simulate.calibration_report(N,seed)` consente di confrontare
altri profili di ricerca mantenendo fissi i seed; i profili non
compaiono nel menu per evitare un'interfaccia diagnostica.

## Valuta e duello

- 1 lira = 20 soldi = 240 denari: lira come unità di conto veneziana.
- Ciascuno parte con 1 lira, registrata come 240 denari interi.
- Ogni mano: **2 soldi a testa**, piatto iniziale **4 soldi**.
- **Un solo rialzo volontario del giocatore** prima del lancio:
  +2 soldi per contendente, pareggiati subito dal Opponent, per
  un piatto da **8 soldi**. Senza rialzo, il piatto resta da **4 soldi**.
- Il Opponent non impone rialzi e non impedisce l'inizio del duello
  con richieste di accettazione. Nessuna puntata resta in attesa.
- Un'offerta numerica del Opponent e il punteggio Farkle incassato
  decidono il vincitore della mano; **i punti non sono denaro**.
- Il Opponent può eseguire una controfferta secondo la cassa pubblica
  e una policy di rischio. Il primo a due prove vinte vince l'incontro;
  insolvenza sull'ante successiva provoca sconfitta.
- Il saldo totale di Incisore, Opponent e piatto resta **480 denari**.

### Comandi

- **Spazio** — Lancia o rilancia i dadi.
- **1–6 / clic** — Seleziona un dado.
- **A** — Accantona la combinazione selezionata.
- **I** — Incassa e lascia rispondere il Opponent.
- **Invio** — Inizia la mano senza rialzare.
- **P** — Ritirati e concedi la prova durante il turno di dadi.
- **Alza la posta** — Pulsante facoltativo; pareggio automatico.
- **C** — Risolvi la controfferta automatica.
- **N** — Mano successiva.
- **E** — Libro mastro monetario.
- **B** — Dettagli della cassa pubblica.
- **R** — Rigioca lo stesso seed.
- **S** — Nuovo incontro: scegli seed (101/202/303) e rialzi attivi/disattivati.

L'interfaccia si ispira alle risorse già presenti in Project Folio:
`resources/scenes/printshop-room.png` (bottega),
`resources/opponents/opponent.png` (avversario intercambiabile),
`resources/font/AldineAetna-Regular.ttf` per titoli
e `Cardo-Regular.ttf` per testo operativo. Gli asset vengono caricati
dalla directory di produzione, senza farne copie in laboratorio.
In assenza di uno degli asset, la modalità rimane avviabile con fallback.

### Registri

Nel save separato LÖVE `project-folio-opponent-wager-lab`:

- `opponent_v4_matches.csv`
- `opponent_v4_hands.csv`
- `opponent_v4_transactions.csv`
- `opponent_v4_policy.csv`
- `opponent_v4_dice_decisions.csv`

Il libro mastro mostra deposito, rialzo volontario, pareggio automatico,
ritiro e vincita. I dettagli numerici della cassa
si aprono su richiesta, non rimangono esposti nella scena principale.

## Diagnostica e limiti

```sh
lua5.4 tests/labs/opponent_wager_v3_test.lua
lua5.4 tests/labs/opponent_duel_money_test.lua
luajit tests/labs/opponent_duel_money_test.lua
```

`--money-simulate N --seed S` confronta posta base e rialzo volontario
usando seed accoppiati e tre policy giocatore. Queste policy non rappresentano
giocatori umani: la qualità della scelta fra rilancio e incasso va
verificata tramite playtest.

Non modificare direttamente il Farkle, la fisica g3d né i salvataggi
del gioco principale. Questa modalità è un laboratorio isolato.
