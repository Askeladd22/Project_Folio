# Registro delle domande e decisioni — Folio R&D

**Regola:** la parola «approvato» richiede un'esplicita decisione registrata del team. Un test positivo non basta. Le questioni qui elencate non cambiano la visione canonica.

| ID | Domanda | Stato | Prossima prova |
|---|---|---|---|
| RQ-001 | Farkle + Mercante: token, prove contese o diverso sistema di dadi? | in ricerca | Deep research + confronto documentato V4/C |
| RQ-002 | Qual è la posta concreta del duello, distinta dai punti Farkle? | aperta | Test di chiarezza e payoff |
| RQ-003 | Come rendere leggibile ma non banale la scelta del rivale? | aperta | Predizione decisionale da playtester |
| RQ-004 | Qual è il contratto di vittoria dell'incontro? | aperta | Simulazione con policy alternative |
| RQ-005 | Come trasferire mastery e swelling power nella struttura della run? | aperta | Build test, stessa seed e skill differente |

## Modello di record decisione

**D-### — Titolo**

- Data e revisione Git:
- RQ / proposta:
- Prove a favore (fonti, esperimenti e link):
- Prove contrarie e confondenti:
- Vincoli valutati:
- Scelta: approvato / iterare / sospeso / respinto:
- Motivazione e alternative:
- Cosa cambia nel gioco (se approvato):
- Chi ha approvato e dove:
- PR di implementazione (se esiste):
- Condizione di revisione futura:

## Decisioni iniziali

**D-000 — Fondazione del protocollo (9 novembre 2026):**
Introdotta una struttura di ricerca e validazione **documentale**, non è stata approvata nessuna modifica al gameplay. Le decisioni pregresse valide restano in docs/project_vision.md e negli altri documenti canonici.

**Nessun vincitore di RQ-001 è stato scelto.** La comparazione in BASELINE.md è descrittiva e non comprende playtest eseguiti dal laboratorio.

## D-001 — Nome neutro dell'avversario predefinito (18 novembre 2026)

- **Base Git:** `main@b86264fd2d731ce164e6ffe191e6eb0b3a76d6f9` (0.1.75).
- **Richiesta approvata:** il default generico non deve più chiamarsi
  «Mercante», perché crea confusione fra il segnaposto e uno specifico
  personaggio/encounter.
- **Implementazione scelta:** ID neutro `rival`, denominato «Rivale»
  nei testi di utilizzo corrente e nei test G4/G4b; l'ID `merchant`
  rimane valido come scelta **esplicita**, senza rinominare asset storici
  o l'esperimento specifico Merchant Wager.
- **Stato della parola «Rivale»:** scelta di implementazione coerente
  con gli attuali testi del prototipo C, non una nuova identità narrativa
  obbligatoria o il nome proprio di un personaggio.
- **Compatibilità visiva:** `resources/opponents/merchant.png` è
  temporaneamente il ritratto del default `rival`; se è disponibile
  `resources/opponents/rival.png`, la nuova risorsa prevale.
  Il JPEG storico con il Mercante incorporato rimane fallback
  di compatibilità sia per `rival` sia per `merchant` esplicito quando
  mancano gli asset modulari, senza cambiare l'ID logico predefinito.
  Resta un segnaposto visivo da sostituire, non un'identità narrativa.
- **Prove da acquisire:** CI su branch, test di selezione/default e
  regressioni g3d/LÖVE, verifiche Windows a cura di un partecipante.
- **Fuori ambito:** cambiare il personaggio illustrato, le regole di
  Farkle, il comportamento del rivale o lo stato canonico di EX-002.
- **Decisione narrativa:** il Mercante rimane un possibile archetipo
  futuro e non è automaticamente il rivale predefinito.
- **Approvazione:** richiesta esplicita dell'utente nel turno
  «basta chiamare l'avversario default Mercante. crea incomprensioni!
  modifica anche il codice».

## D-002 — Denominazione Opponent e presa fisica obbligatoria (21 novembre 2026)

- **Baseline:** `main@1dae4428f24cdb280cd5afc5374a951bd1686f52`, 0.1.98.
- **Decisione esplicita:** sostituire il nome generico «Mercante» con **Opponent** nel codice,
  nell'HUD e nella documentazione corrente; superare la precedente scelta D-001
  `rival` come ID iniziale. L'avversario rimane una figura sostituibile.
- **Interazione:** rimuovere pulsante e scorciatoia per lancio automatico umano;
  iniziare ogni tiro prendendo fisicamente uno o più dadi. Resta il lancio fisico
  autonomo dell'IA e la possibilità di recupero tecnico.
- **Cleanup approvato:** ritirare dalla working tree le implementazioni di
  Battute Gemelle (EX-BG-001) e Tre Prove / Riserva (EX-TP-001) con gate G3
  negativo, lasciando intatti report, risultati, commit e tag Git storici.
- **Gate ancora aperto:** test suite completa, Windows/LÖVE, confronto visivo,
  controllo che la vecchia denominazione non sia più utilizzata nei componenti attivi.
- **Storia:** non riscrivere i commit precedenti né i titoli storici dei log;
  le sigle dei branch originali rimangono identificatori di provenienza.

## D-003 — Single Opponent Duel entry and legible turns (21 November 2026)

- **Baseline:** `main@3864304e84175eca31569949fe5ee0b950aacd16`, v0.1.100.
- **Approved in chat:** replace the two game entries with a single Opponent Duel, English-only game UI, scored physical dice left on the tabletop and slower, explained Opponent decisions.
- **Unchanged:** canonical six-D6 Farkle scoring, g3d physics and AI bank/reroll policy. The old solo commission mode is kept internally for regression and R&D only; no new health, cards or permanent roguelite progression is implied.
- **Presentation:** show selection preview, set-aside gain, current unbanked total, secure score and risk decision in separate timed beats.
- **Gate:** full Lua/LuaJIT, Mesa and Windows LÖVE visual/manual tests before merge. Not a claim of measured competitiveness or a finished run structure.

## D-004 — Table eye-line and paper ledgers; retired campaign selector (21 November 2026)

- **Baseline:** `feat/unified-opponent-duel-english-0.1.101@64a97bd52d3dcbf8a9fd5145c36e81a30218fc53`.
- **Explicitly requested:** improve tabletop perspective and diegetic UI/UX; remove obsolete source and dated documentation without destroying research provenance.
- **Choice:** fixed perspective `pitch=0.965`, six real D6 and shared projection/picking unchanged. Separate gameplay score from presentation; replace floating status-card styling with paper ledgers and an engraved wager ruler.
- **Cleanup evidence:** the selectable campaign page is unreachable after New Game routes directly to `scriptorium`; delete only that page, its now-unused schema, translations and registration, plus the tests that incorrectly required the dead page. Historical solo scorer and R&D experiments remain executable in isolation.
- **Not deleted:** historical research reports, experiments and their CI; source of truth remains `docs/project_vision.md`, `docs/farkle_rules.md`, implementation and changelog.
- **Gate:** Lua 5.4, LuaJIT, Python and Mesa CI on the exact SHA; Windows visual acceptance at 1280×720 / 1920×1080 / ultrawide; test physical pickup, rear parked dice and readable opponent intention before merge.
