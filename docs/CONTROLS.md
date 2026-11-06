# Project Folio — Controlli e contratto UI attivo

**Versione documentale:** 6 novembre 2026 · v0.1.40.
Questa è la descrizione sintetica della UI in uso, **non**
l'inventario della UI legacy o la roadmap F6.

## Gesti e tasti

- **Spazio:** lancio o azione contestuale consentita dal Farkle.
- **Click sinistro:** selezione di dadi per punteggio; trascinamento
  sulla superficie per scegliere più dadi fisici (marquee).
- **Tasto destro:** presa e rilascio/lancio manuale di un dado o gruppo.
- **A:** Accantona; **Invio:** Incassa quando consentito.
- **1–6:** selezione dei dadi per punteggio dopo un lancio valido.
- **N:** passo successivo consentito; **M:** intervento medaglia quando disponibile.
- **Esc:** annulla prima la presa, poi la selezione fisica; chiude modali
  o apre/chiude il menu di pausa quando il lancio è stabile.
- **F:** consulta il Folio; **?** apre le regole.
- **F7:** laboratorio medaglie (diagnostico), **F8:** workshop del tavolo;
  **F10/F11:** diagnostica g3d.
- **F6 e F9:** *rimossi*; non ci sono HUD e painter di fallback.

## Controlli di partita gestiti dall'unico HUD

Gli identificatori sono parte del contratto di regressione e non
vanno confusi con nuove funzioni approvate:
`help`, `runmenu`, `folio`, `roll`, `take`,
`bank`, `next`, `rescue`, `fail`, `retryphysical`,
`medaluse`.

Nel pannello delle ricompense e nella pausa:
`weighted`, `engraved`, `medal`, `none`, `close`,
`resume`, `settings`, `restart`, `mainmenu`, `cancel`,
`confirmrestart`, `confirmexit`, `helpTab1`.

Nel laboratorio delle medaglie:
`inspect1`, `equip`, `medalprev`, `medalnext`,
`target1`, `activate`. `inspect1`, `target1` e
`helpTab1` sono esempi di ID generati dinamicamente.

## Stati e precedenze

- `fresh`: si può iniziare il lancio; il punteggio non è selezionabile.
- `rolling`: nessun incasso o accantonamento fino all'accettazione
  del risultato fisico.
- `ready`: si selezionano combinazioni valide e poi si accantona,
  incassa o rilancia secondo le regole.
- `rescue`: Correttore o accettazione del Farkle.
- `physics_error`: ripetizione *tecnica* dello stesso tiro, senza
  consumare una seconda mano di gioco.
- `upgrade`/`medal`/`ended`: dialoghi, ricompense o chiusura,
  non una seconda implementazione di scoring.

La selezione **fisica** con marquee non produce punti; la selezione
**logica** degli ID dadi accetta solo i risultati riconosciuti
dal motore Farkle. Esc non deve mai terminare brutalmente LÖVE.

## Fonti autoritative

- `src/features/farkle/controller.lua`: precedenza degli input.
- `src/features/farkle/ui_v2/hud.lua` e `actions.lua`: comandi.
- `src/features/farkle/ui_v2/dialogs.lua`: modali e conferme.
- `src/features/farkle/medal_panel.lua`: controlli medaglie.
- `src/gameplay/farkle/rules.lua`: condizioni di gioco.
- `tests/ui_v2_interaction_inventory_test.lua`: invarianti verificati.
- [Regole Farkle](FARKLE_RULES.md) e [QA Windows](WINDOWS_TECHNICAL_QA.md).

*Nuovi controlli e modifiche alle scorciatoie devono essere sincronizzati
con la UI effettiva e i test. Questo documento non prescrive nuove regole.*
