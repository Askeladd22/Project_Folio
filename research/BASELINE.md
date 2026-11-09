# RQ-001 — Inventario e confronto iniziale (9 novembre 2026)

**Stato: ricognizione documentale, non valutazione quantitativa.**
Fonte: README e codice dei laboratori della main al commit 2239cd55bb7e66b520ea265878a2e748b22cf132. Nessun test o playtest è stato eseguito per questo documento. Per le regole definitive controllare il codice allo SHA indicato.

| Prototipo | Decisione del giocatore | Agenzia del rivale | Risorsa / esito | Punti critici da verificare |
|---|---|---|---|---|
| Farkle attuale | scelta subset, incasso/rilancio | nessun avversario completo: commissioni | punti, soglie, commissione | limite dell'esperienza solitaria e crescita della mastery |
| Merchant Wager V4 | Farkle, incasso, rialzo monetario volontario | cassa di 20 token pubblica, offerte/controfferte | denari (posta) separati dai punti | X iniziale, spiegabilità delle controfferte, effetto reale del rialzo |
| Encounter A | divisione di offerte fra due prove | il rivale sceglie una delle due | sigilli e maggioranze | tradeoff genuino o scelta ottimale ovvia? |
| Encounter C | scegliere dove investire su tre prove | risposta del rivale secondo priorità pubbliche | sigilli, conquista di 2 categorie | leggibilità vs prevedibilità, rischio di strategia dominante |
| P4ND0RA 1:1 | Farkle, opzioni di conversione | token asimmetrici con attacchi/difesa | HP/Resistenza **solo nel lab** | scostamento dall'identità non-combat e costo cognitivo |

## Numeri preesistenti: da non presentare come conclusioni

Il README V4 documenta una simulazione **precedente** di 200 seed con policy balanced (50% senza rialzi, 51,5% con il vecchio sistema) e avverte espressamente che **non misura il nuovo rialzo volontario**. Riporta inoltre un rischio iniziale di X di circa 28,4% e una regola potenzialmente problematica che assegna subito la mano al giocatore. Sono dichiarazioni della documentazione del prototipo, **non risultati qui replicati**.

## Confronti prioritari

**C1 — Chiarezza dell'avversario:** su Encounter C e Merchant V4, mostrare ai tester lo stato e chiedere di prevedere la prossima risposta del rivale prima che avvenga. Misurare accuratezza, motivazione espressa e sorpresa negativa.

**C2 — Qualità delle decisioni:** per il medesimo stato, confrontare policy alternative e loro valore atteso, identificando scelte dominanti e decisioni senza effetto.

**C3 — Fairness e posta:** distribuzione della durata, percentuale di esiti prematuri per X, conservazione della valuta, convenienza del rialzo, frequenza di insolvenza.

**C4 — Linguaggio dei dadi:** confrontare Farkle e alternative **solo dopo** aver precisato posta, vittoria e azioni del rivale: cambiare il punteggio dei dadi senza cambiare il duello non garantisce miglioramento.

## Incognite aperte

Non conosciamo ancora, sulla base dei dati disponibili: performance reali dei giocatori, loro interpretazione della logica del rivale, intervalli di confidenza su metriche aggiornate, valore delle strategie dominanti, impatto di una diversa famiglia di giochi di dadi e capacità di sostenere swelling power durante una run.

**Prossimo passo:** eseguire la prima ricerca di [DEEP_RESEARCH_BRIEF.md](DEEP_RESEARCH_BRIEF.md) e un baseline numerico riproducibile secondo [SIMULATIONS.md](SIMULATIONS.md). Nessun prototipo è promosso in produzione.
