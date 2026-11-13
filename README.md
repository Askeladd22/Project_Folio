# Project Folio

*Project Folio* è il titolo di lavoro di un roguelite di dadi ambientato nella Venezia di Aldo Manuzio. Di giorno un incisore prepara le xilografie per la stampa. Di notte sogna che le figure prendano posto al tavolo e lo sfidino ai dadi.

Nel prototipo puoi giocare a Farkle sul **Tavolo del Mercante**. Lanci sei dadi fisici, scegli quali accantonare e decidi se incassare o rilanciare. Se il lancio non produce combinazioni valide, perdi i punti del turno.

## Come giocare

Installa [LÖVE 11.x](https://love2d.org/) e scarica il repository. Su Windows apri `run_game.cmd`. Da terminale, esegui `love .` nella cartella del progetto.

Premi **Spazio** per lanciare, clicca sui dadi per selezionarli, premi **A** per accantonarli o **Invio** per incassare. Con **?** apri le regole.

## Dove trovare il codice

La produzione è raccolta in **29 file Lua** sotto `src`. I principali punti
di ingresso sono [controller](src/farkle/controller.lua),
[interfaccia](src/farkle/ui.lua),
[tavolo](src/farkle/tabletop.lua),
[menu e impostazioni](src/screens/frontend.lua) e
[regole](src/farkle/rules.lua).
La [mappa tecnica](docs/technical.md) elenca tutti i moduli e le loro sezioni.

[Documentazione](docs/README.md) · [Mappa del codice](docs/technical.md) · [Regole Farkle](docs/farkle_rules.md) · [Visione del progetto](docs/project_vision.md) · [Changelog](CHANGELOG.md) · [Crediti e licenze di terzi](lib/licenses/)
