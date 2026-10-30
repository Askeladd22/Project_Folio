# Lab 3 — g3d nello Scriptorium giocabile

**Modalità sperimentale, reversibile.** Il gioco normale parte sempre con
il renderer originale. Per usare g3d nel gameplay, lancia:

```cmd
experiments\g3d_lab\Avvia-Nel-Gioco.cmd
```

Oppure dalla radice, in CMD:

```cmd
set MANUSCRIPT_G3D_INGAME=1
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
- Per evitare effetti collaterali, g3d viene caricato soltanto quando si
  abilita esplicitamente la variabile `MANUSCRIPT_G3D_INGAME=1`.
  Se il disegno GPU genera un errore, il renderer si disabilita e lascia
  al painter la prosecuzione del gioco.

## Differenze note / controlli manuali

Questa è una **prima integrazione sperimentale**, non ancora il renderer
di produzione. In particolare:

- L'effetto glow dei dadi selezionabili è ancora specifico del vecchio
  percorso 2D: nella variante GPU i dadi si disegnano normalmente.
- Le sette righe illustrative lungo i bordi delle pagine nella variante
  `book` non sono ancora riprodotte identicamente.
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
`experiments/g3d_lab/g3d/LICENSE`). Non viene aggiunta una seconda copia.
