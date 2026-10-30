# Manuscript — renderer A/B (g3d)

**Laboratorio A/B storico e reversibile.** Nella partita reale g3d e ora il
renderer predefinito del libro; qui i due percorsi continuano a confrontare gli
stessi corpi fisici indipendentemente dalle preferenze del giocatore.

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
- **W** — mostra/nasconde le pareti in entrambi i renderer;
- **Esc** — esci.

Lo stato di movimento e le pose vengono dal motore fisico originale; le
texture dei sei dadi provengono dagli asset di Manuscript. I pannelli
utilizzano una camera ortografica comune, mentre la profondità sul lato
g3d è risolta dal depth buffer GPU.

## Lab 2 — allineamento reale e bordo del vassoio

- I due pannelli usano la **stessa camera ortografica in coordinate mondo**:
  la correzione di orientamento è nella matrice di vista g3d, **non** in
  un'immagine specchiata a valle.
- Il piano, le quattro pareti interne/esterne e il bordo superiore della
  vaschetta hanno le stesse dimensioni e gli stessi otto segmenti del
  painter. Rimane un prototipo: la geometria completa della bottega/libro
  e gli overlay definitivi non fanno ancora parte del laboratorio.
- **W** mostra/nasconde le pareti in entrambi i renderer per confrontare
  l'occultamento dei dadi; **A/D** ruota la camera condivisa.
- **1** e **2** sono misure separate (la modalità non attiva non viene
  renderizzata); **3** visualizza entrambi. Ogni cambio modalità azzera
  le medie mobili. In basso sono mostrate le medie degli ultimi 120 campioni
  del tempo CPU di invio ai renderer; il tempo g3d comprende l'upload
  delle facce dinamiche. Non si tratta di tempi GPU e non sono
  confrontabili direttamente con un benchmark di GPU.
- Controllare che nessuna faccia appaia invertita, che il bordo nasconda
  correttamente i dadi solo quando deve farlo e che i numeri corrispondano
  fra i due pannelli a varie angolazioni.
- **M non è più necessario**: lo specchiamento del Canvas è stato rimosso.

## Vincoli della prova

Questa è una **prima comparazione qualitativa**. Non equivale a una migrazione
né a un test di gameplay completo: selezione via mouse, vassoio definitivo,
raggiungibilità di tutte le schermate, effetti, Farkle e salvataggi non sono
integrati. Il laboratorio riproduce il bordo geometrico del vassoio
dell'attuale renderer, ma non l'intero libro/leggio della scena definitiva.
Le corrispondenze tra posizione, texture e numero dei dadi vanno
ancora verificate visivamente anche durante il movimento.

La CI controlla sintassi e logica geometrica in Lua 5.4/LuaJIT; non può
certificare la resa GPU o il *game feel*. Prima di adottare g3d nel runtime
servono screenshot, verifiche di orientamento, z-order, controllo del mouse,
profilazione, screenshot a risoluzioni differenti e almeno 50 lanci completi
comparati.

## Origine e licenza

`lib/g3d/` deriva da **groverburger/g3d**, v1.6.0, commit
`639120acd754dc5c34402e41eb1687b1a5a3ffa8` (MIT). La licenza originale
si trova in `lib/g3d/LICENSE`. Gioco e laboratorio condividono una sola
copia della libreria e gli adattatori in `src/engine3d/`.

- https://github.com/groverburger/g3d
- https://github.com/Askeladd22/manuscript
