# g3d — verifica visiva del tray in Project Folio

Il 30 ottobre 2026 era stata individuata una doppia superficie:
il painter CPU disegnava le pagine prima della scena g3d, causando
croci e riquadri molto grandi sopra il piano dei dadi. La correzione
originaria aveva separato piano e 3D; il **31 ottobre**, con PR #38,
il renderer CPU è stato definitivamente rimosso.

## Percorso attuale

Il solo pass 3D è **g3d**: pavimento a z=0, ombre di contatto,
pareti e divisore, sei dadi fisici. Le miniature avversarie, le
glosse, i pannelli e il folio rimangono **2D**.

Non esiste più un toggle F9 e i seguenti override sono obsoleti:
`MANUSCRIPT_RENDERER=legacy`, `MANUSCRIPT_G3D_INGAME=0`.
La compilazione di shader obbligatori e gli errori di scena
vengono segnalati esplicitamente.

## Checklist per Windows LÖVE 11.x

1. Avviare `Avvia.cmd` ed eseguire una run normale e una partita
   **Sfida il Monaco (beta)**.
2. A **1280×720** e **1920×1080** controllare il libro e tutte le
   cinque varianti del tray selezionabili con **F8**.
3. Verificare sei D6 singoli, semi leggibili, faccia superiore
   corrispondente al punteggio, pareti e ombre che si occultano
   correttamente.
4. Provare camera/proiezione, selezione e trascinamento manuale,
   lancio di gruppo, accantonamento con i ritratti g3d;
   includere Farkle, dadi caldi, rilanci e medaglie.
5. Provare **F10** (materiali), **F11** (smusso), **F6**
   quando l'esperimento UI v2 è abilitato, e notifiche 2D.
6. Ripetere almeno 50 lanci accettati, verificando corrispondenza
   tra valore fisico e punteggio. Registrare FPS e log di errore
   nei casi di shader non supportato.

**La CI headless non sostituisce questa prova GPU.**
