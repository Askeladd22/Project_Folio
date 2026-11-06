# Project Folio — PNG avversari sostituibili

## Livelli della scena (0.1.33)
1. Un **fondale senza persone**, comune a tutti: `resources/scenes/printshop-room.png`.
2. Un solo **avversario con alpha**, `resources/opponents/<id>.png`, disegnato davanti al fondale e dietro i dadi 3D.
3. HUD e tavolo/dadi g3d esistenti, senza modifiche.

L'esportazione del Mercante dovrà essere `resources/opponents/merchant.png`.
Per cambiare avversario basta inserire ad esempio
`resources/opponents/monk.png`, con trasparenza RGBA e busto vicino
al bordo inferiore dell'immagine, e scegliere l'ID `monk`.

```lua
require('src.core.navigation').go('scriptorium',{opponent_id='monk'})
-- Oppure durante una scena già attiva:
require('src.features.farkle.controller'):setOpponentVisual('monk')
```

Il loader costruisce il nome del file dall'ID senza inserire nomi di
avversari nel rendering. Sono ammessi solo ID composti da lettere minuscole,
numeri e underscore. Le immagini vengono centrate sull'asse del tavolo,
con massimo 520 px di larghezza, 350 px di altezza e piede a y=373
nel canvas virtuale 1920×1080: tutte conservano il rapporto d'aspetto.
L'area di lancio, le hitbox e le regole non vengono modificate.

**Art pack 0.1.34:** i due PNG necessari sono stati prodotti e resi
disponibili separatamente come `Project_Folio_Art_Pack_0.1.34.zip`.
Estrarre lo ZIP nella radice di `Project_Folio`, preservando i percorsi
`resources/scenes/printshop-room.png` e
`resources/opponents/merchant.png`. All'avvio il loader riconosce entrambi
ed esclude automaticamente il Mercante incorporato nel vecchio JPEG.
Il pacchetto non e' commitato nel repository.

**Senza art pack:** `resources/merchant/table-host.jpg` ha il Mercante
già disegnato nello sfondo. Fino alla disponibilità di `printshop-room.png`
(senza Mercante) e `merchant.png` (isolato su trasparenza), il Mercante
usa ancora il composito storico. NON è stato creato un PNG separato.

Per ogni altro ID è obbligatorio avere sia il fondale pulito sia il suo
PNG: in caso contrario il gioco genera un errore esplicito, evitando
che il Mercante rimanga sullo sfondo dietro un nuovo personaggio.
La pipeline è pronta per gli asset futuri, ma non li inventa.
