# Project Folio — avversari illustrati sostituibili

**Stato attuale:** gli asset modulari sono nel repository, non
richiedono più un pacchetto grafico esterno da installare.

## Strati

1. `resources/scenes/printshop-room.png` — bottega pulita,
   **senza personaggi**.
2. `resources/opponents/merchant.png` — Mercante con canale alfa
   indipendente, davanti al fondale e dietro al tavolo 3D.
3. Tavolo, sei D6 g3d e HUD — livelli separati, nessuna modifica
   agli eventi fisici o ai punteggi.

Per altri personaggi usare `resources/opponents/<id>.png`, con
`<id>` composto solo da lettere minuscole, cifre e underscore.
Usare trasparenza RGBA, busto coerente e proporzioni leggibili;
il motore usa un'area di ancoraggio comune senza distorcere
il rapporto d'aspetto.

## Selezione dell'avversario

```lua
require('src.core.navigation').go('scriptorium',{opponent_id='merchant'})
-- Oppure nella scena corrente:
require('src.features.farkle.controller'):setOpponentVisual('merchant')
```

Il modulo `src/features/farkle/ui_v2/opponent_scene.lua` risolve
fondale e ritratto. Un ID non disponibile non deve mostrare il
Mercante dietro a un altro personaggio: in assenza dell'immagine
richiesta il loader segnala l'errore esplicitamente.

Il vecchio composito `resources/merchant/table-host.jpg` resta un
fallback limitato al Mercante e non è il formato da utilizzare
per creare nuovi avversari.

**Confine di design:** sostituire un PNG non crea un bot, una
scommessa o un encounter competitivo. Quei sistemi restano aperti
nella [visione](PROJECT_VISION.md). I ritratti e la stanza non
devono alterare le hitbox o la fisica dei dadi.
