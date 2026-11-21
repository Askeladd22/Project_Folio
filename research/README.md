# Project Folio — Research & Development Lab

**Stato:** laboratorio metodologico, introdotto il 9 novembre 2026. **Nessuna meccanica qui è automaticamente canonica.**

Questa cartella coordina ricerca esterna, critica, confronti, simulazioni, playtest e decisioni di game design. La **visione canonica** resta [docs/project_vision.md](../docs/project_vision.md); le **regole implementate** restano [docs/farkle_rules.md](../docs/farkle_rules.md) e il codice. Le decisioni sui prototipi non si traducono automaticamente in modifiche al gioco.

## Documenti operativi

| File | Funzione |
|---|---|
| [PROTOCOL.md](PROTOCOL.md) | Pipeline, criteri di confronto, gate e tracciabilità |
| [BASELINE.md](BASELINE.md) | Inventario dei prototipi esistenti e lacune da colmare |
| [DEEP_RESEARCH_BRIEF.md](DEEP_RESEARCH_BRIEF.md) | Prima ricerca da avviare in Deep research |
| [SIMULATIONS.md](SIMULATIONS.md) | Comandi esistenti, metodologia e metriche |
| [DECISIONS.md](DECISIONS.md) | Domande aperte e registro delle decisioni |
| [CHATGPT_PROJECT_INSTRUCTIONS.md](CHATGPT_PROJECT_INSTRUCTIONS.md) | Istruzioni da copiare in un Progetto ChatGPT |
| [templates/EXPERIMENT_CARD.md](templates/EXPERIMENT_CARD.md) | Scheda per ogni ipotesi/prototipo |
| [templates/SOURCE_CARD.md](templates/SOURCE_CARD.md) | Scheda di provenienza, attendibilità e conflitti |
| [templates/PLAYTEST_CARD.md](templates/PLAYTEST_CARD.md) | Osservazioni di giocatori reali |

## Regole di gestione

1. **Separare le evidenze dai giudizi:** ogni affermazione deve essere classificata come fatto verificato, risultato sperimentale, interpretazione o ipotesi.
2. **Fonti controllabili:** link, autore, titolo, versione/data, pagine o sezioni. Dichiarare esplicitamente quando un riferimento non è stato consultato integralmente.
3. **Un protocollo prima dei test:** preregistrare domanda, ipotesi, seed, policy, metriche e criteri di arresto prima di scegliere la soluzione vincente.
4. **Nessuna vittoria per percentuale isolata:** la win rate non dimostra profondità strategica, chiarezza o divertimento.
5. **Simulazione != playtest:** agenti scripted non sono giocatori umani; i due tipi di risultati sono pubblicati separatamente.
6. **Nessun cambio di gameplay senza gate:** un esperimento supera prima valutazione critica, regressione numerica, playtest e decisione registrata.
7. **Non duplicare il corpus canonico:** versioni precedenti e idee ritirate si consultano nella cronologia Git, non si reinseriscono come regole correnti.

## Flusso operativo

Domanda (RQ) → ricerca documentata (R) → confronto (C) → prototipo isolato (E) → simulazione (S) → playtest (P) → decisione (D) → eventuale PR di integrazione.

Ogni record include ID, data, commit SHA, autore/revisore, collegamenti a fonti e output, stato (**proposto / in ricerca / in prova / approvato / respinto / sospeso**).

**Primo tema RQ-001:** comprendere se il duello del Opponent debba usare un'offerta a token, prove contese oppure un confronto fra sistemi di dadi; usare Opponent V4 ed Encounter C come baseline.

**Avvertenza sul corpus storico:** vecchi file di ricerca ricordati da altri documenti non sono presenti nella main esaminata il 9 novembre 2026. Non considerarli esistenti senza recuperarli esplicitamente dalla cronologia e verificarne lo status.

## Confine con il repository

- [experiments/](../experiments/) contiene i prototipi eseguibili isolati.
- [tests/labs/](../tests/labs/) contiene le verifiche.
- [.github/workflows/](../.github/workflows/) contiene gli automatismi di regressione esistenti.
- Non modificare src/, lib/, risorse artistiche o la fisica solo per avviare una ricerca.
- Ogni PR, **anche documentale**, segue [docs/versioning.md](../docs/versioning.md): bump versione e changelog.

**Pulizia 0.1.99:** i report EX-BG-001 ed EX-TP-001 rimangono prove storiche,
mentre i due laboratori eseguibili con gate negativo sono rimossi dalla working tree.
I risultati non diventano conclusioni canoniche, e gli SHA originari restano recuperabili.

## Audit di conservazione — 0.1.102 (21 novembre 2026)

La pagina `campaign_select` non era più raggiungibile dopo l'unificazione
del duello in 0.1.101: rimossi schermata, schema, etichette di traduzione,
registrazione e verifiche specifiche. Le nuove decisioni di produzione
sono in `CHANGELOG.md`, `research/DECISIONS.md` e `docs/technical.md`.
Il testo di verifica 0.1.98 sulla vecchia selezione è recuperabile
dalla cronologia Git, non resta come procedura corrente.

**File mantenuti intenzionalmente:** `EX-*.md`, `FPS-FIX-*.md`,
`RQ-002_FANTASY_FIRST_UI.md`, `BASELINE.md` e `SIMULATIONS.md`
conservano metodi, risultati, confronti e gate storici, anche quando
i relativi esperimenti non sono attivi. Gli studi e i template non sono
codice morto; nessun file di ricerca viene cancellato solo per età.

## Direzione aggiornata — 21 novembre 2026 (D-005)

Unica premessa creativa fissa: **incisore nella Venezia rinascimentale**.
La precedente fantasy del giocatore di dadi e i principi narrativi non
sono più obblighi della futura build. `src/` resta la baseline giocabile
v0.1.103; i risultati precedenti non vanno rietichettati come conferme
della nuova visione. I report e i protocolli storici conservano il loro
valore anche quando i relativi laboratori vengono ritirati: la storia
Git preserva i sorgenti cancellati con SHA, senza duplicarli nel tree.
