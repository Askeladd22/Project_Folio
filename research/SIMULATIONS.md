# Protocollo di simulazione — R&D Lab

## Ambiente e ripetibilità

Eseguire i comandi dalla root del repository. Su Windows utilizzare un ambiente con Lua 5.4 oppure LuaJIT disponibile nel PATH; LÖVE 11.x serve per l'interfaccia dei laboratori, non per le simulazioni headless. Registrare commit SHA, OS, versione runtime, comando completo, policy, seed iniziale, N, config/regole, timestamp e file output.

**Non confondere stesso seed con identica casualità:** chiamate RNG che differiscono fra rami possono divergere. Quando possibile, usare flussi separati e seed appaiati; interpretare esplicitamente i limiti.

## Baseline: comandi esistenti

~~~powershell
# Test di regressione isolati
lua5.4 tests/labs/merchant_wager_v3_test.lua
lua5.4 tests/labs/merchant_duel_money_test.lua
lua5.4 tests/labs/merchant_offer_calibration_test.lua
lua5.4 tests/labs/encounter_ac_test.lua
lua5.4 tests/labs/encounter_ac_ui_test.lua
lua5.4 tests/labs/p4ndora_farkle_test.lua

# Merchant V4: con/senza rialzo volontario; prudente, bilanciata, aggressiva
lua5.4 -e "print(require('experiments.merchant_wager_lab.money_simulate').report(100,101))"

# Profili della cassa e valori dei token
lua5.4 -e "print(require('experiments.merchant_wager_lab.money_simulate').calibration_report(100,101))"

# Encounter A/C
lua5.4 -e "print(require('experiments.encounter_ac_lab.simulate').report(60,101))"
~~~

I comandi derivano dai README e dalle workflow esistenti. **Non sono stati eseguiti dalla presente configurazione del laboratorio.** Prima dell'uso con N maggiori verificare limiti, performance e firma delle funzioni alla revisione corrente.

## Campioni consigliati

- **Smoke:** 40–100 partite, individuare errori di logica.
- **Pilot:** 1.000 seed per policy/variante, esplorare distribuzioni ed exploit.
- **Conferma:** fino a 5.000 seed per condizione dove consentito dall'API (limite documentato dal simulatore V4); altro campione indipendente deciso **prima** di vedere l'esito.

Campioni ampi riducono l'errore casuale ma **non** eliminano bias di policy o di modello. Ripetere con almeno una strategia non usata per tarare il regolamento.

## Metriche minime

1. Vittorie/pareggi e intervalli 95% (Wilson per proporzioni; bootstrap **sui delta appaiati** ove applicabile).
2. Distribuzione, non solo media, di durata (turni, mani, decisioni, rilanci).
3. Payout/saldi e invarianti economici; insolvenze e stato di fine partita.
4. Farkle, hot dice, X iniziali, controfferte che ribaltano l'esito.
5. Frequenza e valore delle scelte: incasso, rilancio, accantonamento, rialzo, scelta dell'obiettivo.
6. Differenza fra policy e vulnerabilità a strategia dominante/degenerata.
7. Eventi anomali e seed di riproduzione.

Separare metriche **matematiche** da metriche **umane** (leggibilità, intenzione, coinvolgimento). **Win rate vicina al 50% non dimostra un buon gioco.**

## Metodo comparativo

Scegliere prima le policy, i parametri e l'insieme di seed, poi eseguire tutte le varianti. Conservare output testuale/CSV, commit hash e matrice di condizioni. Se una differenza osservata è piccola, riportarne intervallo e variabilità invece di chiamarla miglioramento. Ripetere run dopo ogni modifica delle regole.

## Esiti e rapporto

Per ogni test aprire una scheda da [templates/EXPERIMENT_CARD.md](templates/EXPERIMENT_CARD.md), con:
- ipotesi preregistrata;
- tabelle delle metriche;
- risultati grezzi con percorso Git/attachment;
- fallimenti e limiti;
- decisione: continua / cambia / scarta / sospendi.

Non pubblicare numeri simulati non realmente eseguiti. Le GitHub Actions esistenti testano regressioni, ma non sostituiscono un disegno sperimentale.
