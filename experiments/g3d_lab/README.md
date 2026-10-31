# Project Folio — laboratorio g3d-only

Il laboratorio è uno strumento di test di **geometria, camera,
texture e fisica** su sei dadi D6 originali. Dopo la dismissione
del vecchio painter CPU (31 ottobre 2026), visualizza **un'unica
scena g3d**, senza confronto A/B tra renderer.

## Avvio Windows

```cmd
experiments\g3d_lab\Avvia.cmd
```

Oppure dalla radice del repository:

```cmd
set MANUSCRIPT_G3D_LAB=1
Avvia.cmd
```

Comandi: **Spazio** pausa/riprende, **R** ricrea i sei corpi,
**A/D** ruotano la camera, **W** mostra/nasconde le pareti,
**Esc** esce. Non esistono più i vecchi tasti 1/2/3 del
confronto grafico.

È mantenuta una sola simulazione fisica e una sola vista GPU.
Il tempo mostrato in basso è il tempo CPU di invio della scena
g3d (media degli ultimi 120 campioni), **non** una misura della GPU.
Il laboratorio non include Farkle, picking di gioco, commissioni,
medaglie né salvataggi.

Il renderer di produzione usa lo stesso g3d ma moduli di scena
più ricchi: questo laboratorio non sostituisce la verifica visiva
della partita effettiva. Testare l'eseguibile su Windows a 720p
e 1080p, verificando occlusione, profondità, orientamento e FPS.

## Licenza

`lib/g3d/` deriva da [groverburger/g3d](https://github.com/groverburger/g3d)
(MIT); licenza nel file `lib/g3d/LICENSE`.
