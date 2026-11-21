# RQ-MERCHANT-001 — IA per un rivale Farkle, partendo da KCD2

**Data:** 2026-11-21 · **Baseline di Folio:** `main` @
`3b2175731c12eef8809842e1e1976529b4a506bc`.
**Stato:** ricerca documentale + primo prototipo astratto;
nessuna validazione della qualità ludica o del comportamento fisico.

## Domanda falsificabile

Un Mercante Farkle simmetrico, che mostra i motivi per cui incassa
o rilancia e usa solo il punteggio canonico, è distinguibile da
un lanciatore casuale e produce scelte comprensibili senza trucchi?

## Evidenze esterne — REA limitata a fonti accessibili

1. **Warhorse / GDC 2025, Matej Marko** descrive GOAP e modular
   behavior trees nell'IA generale degli NPC di KCD2. **Non prova**
   che il minigioco dei dadi usi lo stesso sistema.
   https://gdcvault.com/play/1035576
2. **GameSpot, 2025-02-03** documenta Farkle con turni alternati,
   obiettivo a punti, avversari NPC, selezione parziale,
   incasso/rilancio, hot dice, scommesse e badge.
   https://www.gamespot.com/gallery/kingdom-come-deliverance-2-dice-game-farkle-tips-guide/2900-6189/
3. **Nexus, mod Easy Dice AI (2025-02-14):** una modifica
   documentata fa sì che l'NPC incassi dopo il primo lancio.
   Questa è una prova indiretta della *possibilità di alterare
   il comportamento di arresto*, NON una descrizione del codice
   originale né dell'algoritmo vanilla.
   https://www.nexusmods.com/kingdomcomedeliverance2/mods/244
4. **Folio fonte primaria:** `docs/farkle_rules.md` e
   `src/farkle/rules.lua`; 1 singolo=10, 5 singolo=5, tris
   1=75, piccola scala=100, sei valori diversi=200.
   **KCD2 usa un diverso schema di punti**: non trasferirlo.

Nessun file di gioco KCD2, disassemblato, script NPC o trace REA
è stato letto. Le affermazioni sull'IA specifica del minigioco
sarebbero inferenze e non vanno presentate come reverse engineering
del codice originale.

## Confronto simmetrico

| Politica | Decisione | Pregio | Vulnerabilità |
|---|---|---|---|
| Casuale | Incassa/rilancia casualmente | Baseline di controllo | Può perdere senza motivo |
| Soglia fissa | Incassa sopra X punti | Molto leggibile | Ignora dadi residui e obiettivo |
| One-step (proposta) | Incassa se il rischio supera il guadagno atteso del prossimo tiro | Spiegabile, nessun cheat, usa il rischio Folio | Non ottimizza più tiri, target match e adattamenti |
| GOAP/BT | Pianifica stati e obiettivi | Utile per NPC complessi | Troppa infrastruttura per 2 decisioni |

**Scelta del lab:** one-step per decidere quando fermarsi, subset
con massimo punteggio immediato; nulla di questo è un port di KCD2.
La strategia subset non è ottima per forza: talvolta conservare più
dadi offre un valore futuro maggiore.

## Protocollo e criticità

- Enumerazione teorica uniforme indipendente di 6^n esiti per
  n=1..6, senza calibrare la distribuzione fisica: non confondere
  modello IID con frequenze reali.
- Guadagno `E[max(selectable_points)]` di un solo lancio, con
  Farkle che perde il provvisorio corrente; confronto
  `gain_sum > bust_count * pot`. In parità, incassa.
- Nessun buff/nerf nascosto al dado del Mercante, niente guardare
  il futuro, niente vantaggi legati al risultato del giocatore.
- Simulare match **appaiati** con le stesse sequenze per le politiche,
  confrontare vittorie, durata, Farkle per incontro, rischio
  complessivo e frequenza di hot dice; non affermare risultati
  fino a esecuzione effettiva.
- Playtest: mostrare prima dell'azione pot, dadi residui e motivo
  del Mercante; chiedere di anticipare azione e motivazione.
- Exploit da cercare: hot dice ripetuti, policy troppo prudente a
  1–2 dadi, sottoselezione sempre dominata, obiettivo troppo basso
  e partita finita dopo un singolo turno.

## Risultati e limiti

**Implementato nel branch sperimentale:** `ai.lua`, `duel.lua`,
CLI e test. Non è ancora un avversario nel tavolo g3d.
**QA verificata:** test dedicato Mercante PASS con Lua 5.4 e LuaJIT
su GitHub Actions run 44892339140, incluso replay degli stessi 50 seed.
**Suite generale FAIL** su `wooden_board_contract_test.lua:7`:
`main` avvia `old_wooden`, il test richiede `wooden_compact`.
La discrepanza precede questo esperimento; nessuna verifica grafica
Windows o confronto appaiato di strategie è stata eseguita.

## Decisione e prossimo gate

**Decisione provvisoria:** tenere il modello compatto e
spiegabile. Portarlo nel controller principale **solo dopo**
l'esecuzione dei test, la validazione della policy e
l'approvazione del contratto competitivo. Non promuovere il lab
a feature canonica implicitamente.
