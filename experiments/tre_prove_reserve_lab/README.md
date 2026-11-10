# EX-TP-001 — Tre Prove / Riserva finita

**Research-only; non è gameplay canonico.** Branch di partenza:
`main@f10af7585a72d3d8cbe1c6de1993dedac30ed6f1`.
Preregistrazione: [EX-TP-001_PROTOCOL.md](../../research/EX-TP-001_PROTOCOL.md).
Usa il valutatore Farkle canonico da `src/farkle/rules.lua`, senza duplicarne le combinazioni.

Tre prove: Capilettera, Miniatura, Marca. Il giocatore usa i suoi 6 D6 per incassare `1/2/3` sigilli per round (soglie 40/90) e investe tutto su una prova. Il Mercante risponde con PASS oppure `1..Smax` sigilli presi da una riserva **pubblica che non si rigenera**. La riserva compete fra tutte le prove. Prima parte con 2 prove chiuse a quota 4 vince; a cinque round le prove aperte sono decise per maggioranza, con pareggi neutrali. Su Farkle risponde comunque il Mercante. Non si usano carte, HP, soldi o modifiche di produzione.

## Esecuzione dalla root

```sh
lua5.4 tests/labs/tre_prove_reserve_test.lua
luajit tests/labs/tre_prove_reserve_test.lua
mkdir -p tp-results
lua5.4 experiments/tre_prove_reserve_lab/run.lua 1001 1000 tp-results
```

Pilot preregistrato: 6 celle `R={6,8,10}, Smax={1,2}`, 3 policy player (`commit/aware/blind`), 3 policy rival (`aggressive/conserve/balanced`), seed 1001–2000, 54.000 incontri. `aware` vs `blind` differiscono nella sola riserva rivale **presunta** (reale contro 8). Questo è uno screening di euristiche, non una soluzione ottimale. Ogni CSV contiene un incontro, compresi i pareggi. L'ordine dell'incontro è asimmetrico e fisso.

## Punti deboli da investigare

- Il rivale non tira dadi: ha un'azione pubblica e finita, ma la sua agency è un modello di policy.
- `aware` e `blind` non sono player di mastery misurata.
- Il salto 40/90 crea forti incentivi di soglia.
- `bait_patterns` è soltanto un pattern osservato di cambio prova dopo spesa rivale, non un'intenzione psicologica dimostrata.
- Non è un confronto causale diretto con Encounter C originale né con Merchant V4.
- STOP/CONTINUE counterfactual e playtest richiedono misure separate; non dichiararli eseguiti basandosi sulle win rate.

Non modificare `src/` o `main`. Nessuna PR senza revisione umana di versioning/changelog e decisione di integrazione.
