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

**Primo tema RQ-001:** comprendere se il duello del Mercante debba usare un'offerta a token, prove contese oppure un confronto fra sistemi di dadi; usare Merchant V4 ed Encounter C come baseline.

**Avvertenza sul corpus storico:** vecchi file di ricerca ricordati da altri documenti non sono presenti nella main esaminata il 9 novembre 2026. Non considerarli esistenti senza recuperarli esplicitamente dalla cronologia e verificarne lo status.

## Confine con il repository

- [experiments/](../experiments/) contiene i prototipi eseguibili isolati.
- [tests/labs/](../tests/labs/) contiene le verifiche.
- [.github/workflows/](../.github/workflows/) contiene gli automatismi di regressione esistenti.
- Non modificare src/, lib/, risorse artistiche o la fisica solo per avviare una ricerca.
- Ogni PR, **anche documentale**, segue [docs/versioning.md](../docs/versioning.md): bump versione e changelog.
