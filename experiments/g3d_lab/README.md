# Manuscript — renderer A/B (g3d)

**Laboratorio sperimentale e reversibile.** Il renderer Farkle originale rimane
attivo e invariato nella normale esecuzione di Manuscript.

## Esecuzione (Windows)

Dalla cartella principale del repository, esegui:

```cmd
experiments\g3d_lab\Avvia.cmd
```

In alternativa:

```cmd
set MANUSCRIPT_G3D_LAB=1
Avvia.cmd
```

Il laboratorio utilizza due viewport simultanei: a sinistra il renderer
painter di Manuscript, a destra il renderer GPU di g3d. Sono alimentati dallo
**stesso identico stato** dei sei corpi rigidi a ogni frame; **nessuna**
seconda simulazione o faccia simulata casualmente. L'esperimento non apre
commissioni, non segna punti, non altera salvataggi né medaglie.

Comandi:
- **Spazio** — pausa/continua la fisica;
- **R** — riparte dalla stessa fixture fisica;
- **1 / 2 / 3** — solo renderer originale / solo g3d / confronto affiancato;
- **A / D** — ruota la telecamera di entrambi i renderer;
- **Esc** — esci.

Lo stato di movimento e le pose vengono dal motore fisico originale; le
texture dei sei dadi provengono dagli asset di Manuscript. I pannelli
utilizzano una camera ortografica comune, mentre la profondità sul lato
g3d è risolta dal depth buffer GPU.

## Vincoli della prova

Questa è una **prima comparazione qualitativa**. Non equivale a una migrazione
né a un test di gameplay completo: selezione via mouse, vassoio definitivo,
raggiungibilità di tutte le schermate, effetti, Farkle e salvataggi non sono
integrati. Il piano di fondo è semplificato, non sono rappresentati i bordi
fisici/artistici del libro. Nel pannello g3d la camera viene allineata alla
proiezione storica con un'inversione X al momento della composizione: confronta
anche l'orientamento delle cifre, non soltanto la sovrapposizione delle facce.

La CI controlla sintassi e logica geometrica in Lua 5.4/LuaJIT; non può
certificare la resa GPU o il *game feel*. Prima di adottare g3d nel runtime
servono screenshot, verifiche di orientamento, z-order, controllo del mouse,
profilazione, screenshot a risoluzioni differenti e almeno 50 lanci completi
comparati.

## Origine e licenza

`g3d/` deriva da **groverburger/g3d**, v1.6.0, commit
`639120acd754dc5c34402e41eb1687b1a5a3ffa8` (MIT). La licenza originale
è conservata in `g3d/LICENSE`. Il codice upstream è isolato in questa
directory e non viene importato dal gioco normale.

- https://github.com/groverburger/g3d
- https://github.com/Askeladd22/manuscript
