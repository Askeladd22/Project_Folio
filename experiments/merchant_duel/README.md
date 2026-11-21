# Laboratorio: duello Farkle contro il Mercante (v0.1.97)

**Stato: esperimento isolato, NON collegato alla scena LÖVE/g3d.**
Baseline: `main` commit `3b2175731c12eef8809842e1e1976529b4a506bc` (2026-11-21).

## Avvio interattivo

Dalla radice del repository, con Lua 5.4 o LuaJIT:

```sh
lua5.4 experiments/merchant_duel/cli.lua 1234 500
```

`1234` è il seed e `500` è un obiettivo **prototipale** configurabile.
In ogni tiro sono mostrati gli ID fisici 1–6. Il giocatore può scegliere
qualunque sottoinsieme valido digitando gli ID separati da virgole,
oppure usare la selezione suggerita. Poi decide se incassare o rilanciare.
Il Mercante compie le stesse azioni, senza conoscere i risultati futuri.

## Contratto tecnico

- `duel.lua` è una FSM in Lua puro: `roll → select → decision → roll`,
  oppure incasso/Farkle che passa il turno; vince chi incassa
  almeno il target. Ogni giocatore ha un punteggio sicuro.
- `ai.lua` sceglie il subset con **massimo punteggio immediato** tra
  le opzioni valide fornite da `src/farkle/rules.lua`.
- Il Mercante incassa se ciò basta a vincere, altrimenti confronta
  incasso immediato con **un solo rilancio seguito da incasso**:
  `gain_sum > pot * bust_count`. I valori sono enumerazioni teoriche
  per D6 uniformi normali e punteggio Folio; non misure del solver 3D.
- È un'approssimazione **one-step**, non la strategia ottima né
  una ricostruzione dell'IA proprietaria di KCD2.
- Il generatore di facce vive nel chiamante (`cli.lua`);
  `duel.lua` accetta soltanto valori forniti. Non applica
  modificatori invisibili, non altera la fisica o la distribuzione.
- Nessuna soglia delle commissioni solitarie è introdotta qui,
  nessuna medaglia/upgrade, nessuna valuta, nessun HP.
- Il gioco principale, `src/`, le sei D6 fisiche e la UI non cambiano.

## QA

```sh
lua5.4 tests/labs/merchant_duel_ai_test.lua
# oppure
luajit tests/labs/merchant_duel_ai_test.lua
```

Il test copre transizioni, subset illegali, incasso, Farkle, hot dice,
vittoria, soglie di rischio, 216 esiti per 3 dadi, partite seedate.
**Risultato verificato:** PASS Lua 5.4 e LuaJIT nella CI run
44892339140. La suite globale fallisce su una assertion del tavolo
preesistente (`wooden_board_contract_test.lua:7`); questo lab resta
isolato e non corregge quel problema fuori scope.

## Gate per integrazione nel prototipo

1. **Numerico:** match appaiati con stesse sequenze RNG,
   confronto politica casuale / soglia fissa / one-step,
   vantaggio misurabile e nessuna strategia ovvia che domina.
2. **Umano:** giocatori capaci di motivare la prossima decisione del
   Mercante prima della sua azione, almeno su una raccolta di stati
   ingannevoli; raccogliere errori e ambiguità.
3. **Engine:** adattare turni e feedback all'`src/farkle/controller.lua`
   mantenendo identità fisica, evento `dice.roll_accepted`, proiezione,
   selezione, target e HUD coerenti. I dadi del Mercante vanno
   lanciati fisicamente, non assegnati con un RNG separato in produzione.

Vedi `research/merchant_ai_kcd2_2026-11-21.md` per fonti, analisi e limiti.
