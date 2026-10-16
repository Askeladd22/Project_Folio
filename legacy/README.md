# Archivio storico di Manuscript

Questa directory non fa parte del percorso `love .`. I sorgenti correnti non importano moduli da `legacy/`.

| Categoria | Origine e contenuto | Stato |
|---|---|---|
| `cromatic-system/src/` | Dominio folio/run, pigmenti e leganti, vecchie commissioni, controller cromatico, persistenza precedente e schema relativi | Storico, non giocabile attraverso il menu attuale |
| `cromatic-system/tests/` | Quattro test esclusivi del dominio e del salvataggio cromatico | Conservati senza modifiche; richiedono i percorsi del checkpoint originale |
| `prototypes/experiments/` | Intrecci, Motivi contesi, Arte del rischio e Folio Roguelite, con documentazione, risultati e risorse | Esperimenti precedenti, non modalità Farkle |
| `old-scripts/scripts/` | Launcher degli esperimenti e smoke del banco cromatico | Percorsi relativi storici conservati; non eseguirli dalla nuova posizione |
| `old-assets/resources/shaders/` | Demo bloom, pulse, inkblot e reflection, incluse dipendenze e licenze | Demo estranee al prodotto corrente, conservate integralmente |

I percorsi originali sono mantenuti sotto ogni categoria per facilitarne la ricostruzione. Non abbiamo corretto gli import interni storici per farli dipendere dal gioco moderno: per rieseguire un vecchio esperimento, ripristinare il checkpoint completo in una directory separata. I pacchetti `.love` storici già esistenti sono stati conservati, senza generarne altri.

`src/features/scriptorium/desk_view.lua`, `page_layout.lua`, `src/data/scriptorium_module_config.lua` e Colors rimangono nel gioco attivo perché condivisi dal banco e dalla pergamena. Le facce cromatiche D8 restano nelle risorse correnti perché il costruttore geometrico D8 le indirizza dinamicamente; non sono una modalità giocabile.

Inventario per file con origine, destinazione, dimensione e SHA-256: [archive-manifest.json](../audits/repository-cleanup/archive-manifest.json). Le 203 risorse archiviate sono identiche al checkpoint. Nessun audit o backup preesistente è stato spostato o eliminato.

Per i contratti attuali: [TECHNICAL.md](../docs/TECHNICAL.md); per la promozione e il rollback: [PROMOZIONE_FARKLE.md](../PROMOZIONE_FARKLE.md).

## Promozione definitiva del Farkle

`farkle-prototype/` conserva esclusivamente evidenze storiche rimaste dopo il trasferimento dei sorgenti: screenshot, log, manifest e pacchetto `.love` già esistente; launcher e vecchio smoke rimangono come testimonianza e **non sono comandi correnti**. Non usarli dalla posizione archiviata. Regole, controller e test attivi hanno un solo percorso canonico in `src/`, `tests/` e `scripts/`.

`reports/` conserva sei rapporti con evidenze uniche:

- [Audit motore 3D](reports/audit-motore-3d.md): fotografia tecnica originaria, non elenco dei difetti ancora attuali.
- [Correzione renderer](reports/correzione-renderer-dadi.md): diagnosi e prove delle texture.
- [Consolidamento finale spawn](reports/consolidamento-finale-spawn.md): ultima promozione fisica e limiti noti.
- [Fallback spawn](reports/verifica-fallback-spawn.md): caso mirato e correzione direzionale.
- [Ricerca KCD2](reports/reverse-kcd2-dice.md) e [ricerca Scriptorium](reports/reverse-scriptorium.md): fonti, evidenze e limiti della ricostruzione; non regole del prodotto attuale.

I percorsi in codice, comandi e riferimenti testuali dei rapporti descrivono il loro checkpoint storico. I collegamenti Markdown locali sono aggiornati dove possibile. Gli audit sono lasciati intatti per tracciabilità. I piani conclusi, le vecchie versioni del GDD e i report intermedi rimossi non sono duplicati qui: copie integrali nel checkpoint verificato della promozione e censimento in `audits/farkle-promotion/markdown-before.json`.

Il vecchio esperimento Arte del rischio conserva i propri dati e la relativa documentazione: le 54.000 simulazioni riguardano quel modello, non il Farkle ufficiale. Gli altri README dei prototipi e il README della dipendenza bloom restano perché descrivono materiali archiviati, non il gioco principale. Attribuzioni e licenze non sono state eliminate.
