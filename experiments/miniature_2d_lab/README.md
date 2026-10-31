# Project Folio — laboratorio miniature 2D

Laboratorio LÖVE **opt-in**, non un nuovo motore e non la schermata di gioco.
Solo immagini/sprite piatti, glosse e una vignettatura bidimensionale facoltativa.
I dadi, il tray 3D g3d, la fisica e lo scoring Farkle non sono caricati.

## Avvio Windows

Aprire `experiments/miniature_2d_lab/Avvia.cmd`, oppure dalla radice:

```powershell
$env:PROJECT_FOLIO_MINIATURE_LAB="1"
.\Avvia.cmd
```

`PROJECT_FOLIO_MINIATURE_LAB` **non** viene attivata dal menu di gioco:
il normale `Avvia.cmd` continua ad aprire Project Folio.

| Tasto | Funzione |
|---|---|
| P | Fa uscire la miniatura dal folio: sprite 2D con Flux |
| R | Riporta la miniatura sulla pagina |
| V | Attiva/disattiva la vignettatura Moonshine solo per il Canvas 2D |
| M | Riduce il movimento: posa e testo finali immediati |
| Esc | Esce dal laboratorio |

Lo sprite del cavaliere è **procedurale e originale, provvisorio**, generato
all'avvio in 4 frame su un `Canvas` trasparente. Non è grafica finale.

Dipendenze già vendorizzate in `lib/`: anim8, Flux, SYSL-Text e core
Moonshine con il solo effetto vignettatura. Il demo mostra i percorsi
di utilizzo; non dimostra compatibilità GPU con il renderer 3D, che non
viene mai chiamato nel laboratorio. In caso di problemi con Moonshine
lasciare **V disattivato**: il post-process non è necessario alle figure.

**Non dedurre un'approvazione visiva dalla CI**: testare su Windows con
LÖVE 11.x, a 1280×720 e 1920×1080, e verificare leggibilità, UTF-8,
resize, pulizia degli stati grafici e FPS prima di usare questi effetti
nel gioco.
