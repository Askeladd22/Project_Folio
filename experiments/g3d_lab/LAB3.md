# Lab 3 — g3d nello Scriptorium giocabile

**Storico del Lab 3.** Il vassoio `book` usa ora g3d automaticamente.
Il laboratorio resta disponibile per il confronto con F9. Per mostrare
anche l'etichetta diagnostica, lancia:

```cmd
experiments\g3d_lab\Avvia-Nel-Gioco.cmd
```

Oppure dalla radice, in CMD:

```cmd
set MANUSCRIPT_G3D_DEBUG=1
Avvia.cmd
```

Entra nello Scriptorium e usa **F9** per passare immediatamente da g3d
al renderer painter tradizionale e viceversa. F8 continua a gestire le
varianti di vassoio. g3d è abilitato soltanto nella variante `book` con
vassoio unificato e sei D6; le altre varianti ricadono automaticamente nel
renderer originale senza modificare dadi o punteggi.

## Cosa è stato effettivamente sostituito

- Le sei facce texturizzate di ogni dado 3D sono disegnate su GPU usando
  i vertici delle **stesse pose fisiche** del runtime Farkle.
- Le pareti e il bordo superiore del libro vengono ricostruiti in 3D con
  le stesse dimensioni fisiche e una palette di pergamena e legatura.
- Lo sfondo del folio, i segni di rigatura, il banco, le ombre disegnate
  in 2D, gli overlay, le decorazioni e l'intero HUD rimangono sul percorso
  attuale.
- La selezione dei dadi resta basata sui punti proiettati originari.
- Nessuna modifica a fisica, RNG, scelta del valore superiore, regole Farkle,
  rilanci, accantonamento, salvataggi o medaglie.
- La libreria g3d viene caricata solo al primo rendering compatibile;
  `MANUSCRIPT_G3D_INGAME=0` forza l'avvio con il vecchio painter.
  Se il disegno GPU genera un errore, il renderer si disabilita e lascia
  al painter la prosecuzione del gioco.

## Differenze note / controlli manuali

Questa è una **prima integrazione sperimentale**, non ancora il renderer
di produzione. In particolare:

- Lo shader glow 2D del painter e sostituito da una tinta calda sulle facce
  dei dadi utilizzabili; il cerchio di selezione del mouse resta invariato.
- Le sette righe sui tre tagli delle pagine sono ora realizzate in geometria
  g3d; verificare profondita e spessore a diverse risoluzioni.
- Le altre varianti F8 non usano ancora g3d.
- La fisica cubo-cubo rimane quella precedente, senza alcuna correzione.
- La CI controlla sintassi e moduli puri, **non** la grafica GPU.
- Bisogna verificare il Canvas trasparente, la profondità delle pareti,
  la camera, l'allineamento alla vera tavola e l'assenza di interferenze
  con scissor/stencil su risoluzioni differenti.

### Procedura di verifica

1. Apri il gioco tramite il launcher qui sopra, entra in una partita e
   assicurati che il tavolo sia in variante `book` (F8).
2. Premi **F9**: usa i medesimi dadi e il medesimo HUD con entrambi i renderer.
3. Esegui lanci, seleziona, accantona, rilancia, incassa e completa almeno
   un incontro. Controlla che le facce numerate e i punti coincidano.
4. Controlla soprattutto i dadi vicini ai bordi e le collisioni fra dadi:
   g3d corregge l'occlusione visiva, **non** la fisica.
5. Ripeti a una seconda risoluzione e verifica che il click colpisca lo
   stesso dado con entrambi i renderer.
6. Registra FPS minimi e medi nelle due modalità, a gioco fermo e in
   movimento, nella **stessa scena** e senza altri programmi pesanti.

### Origine del renderer

Questa prova usa le sorgenti MIT di `groverburger/g3d` già importate e
conservate nel laboratorio A/B (commit upstream
`639120acd754dc5c34402e41eb1687b1a5a3ffa8`, licenza in
`lib/g3d/LICENSE`). Il gioco e il laboratorio condividono una sola copia.
