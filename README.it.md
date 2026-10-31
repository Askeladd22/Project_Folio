# Project Folio — titolo provvisorio

**Un roguelite solitario di dadi ambientato in una bottega di copisti e miniatori del XV secolo.**

[English README](README.md) · [Game design](docs/GAME_DESIGN.md) · [Regole Farkle](docs/FARKLE_RULES.md) · [Roadmap UI 2.0](docs/UI_V2_ROADMAP.md)

## Il progetto

**Project Folio** è un nome di lavorazione temporaneo: non è ancora il titolo commerciale. Il nome del repository `manuscript`, gli identificatori tecnici `scriptorium` e l'identità dei salvataggi non cambiano per ragioni di compatibilità.

Il nucleo di Project Folio è il **Farkle a sei dadi tridimensionali**: scegliere combinazioni, accantonare dadi e decidere se incassare o rischiare un nuovo lancio. La bottega medievale, le commissioni e le pagine del manoscritto definiscono l'identità del gioco e la progressione roguelite in sviluppo. Non si tratta di un gioco completo o pubblicato.

## Funzioni attuali

Il prototipo comprende dadi 3D con fisica indipendente dalla grafica, punteggio Farkle, selezione, rilanci, accantonamento, HUD e schermate iniziali. **g3d è il renderer predefinito della variante libro**; F9 passa al vecchio renderer per confronto e sicurezza. La migrazione GPU dei layout F8 e dei dadi D8 è in sviluppo e richiede ancora controlli grafici prima di eliminare il fallback. FPS è un laboratorio di fisica separato e **non viene usato durante la partita**.

## Avvio

Serve **LÖVE 11.x**, con `love.exe` nel PATH oppure specificato da `LOVE_EXE`. Dalla cartella del progetto:

```powershell
git clone https://github.com/Askeladd22/manuscript.git
cd manuscript
.\Avvia.cmd
```

Su Linux: `love .`. Nessuna build è necessaria per giocare.

Percorso: Splash → Main Menu → New Game → Choose Commission → Farkle Roguelite. Il comando Continue non riprende ancora una run.

| Azione | Comando |
|:--|:--|
| Seleziona dado | Click o 1–6 |
| Lancia/rilancia | Spazio (automatico); tasto destro per un dado; **trascina col sinistro per selezionare più dadi, poi lanciali insieme col destro** |
| Accantona | A |
| Incassa | Invio |
| Prossimo turno | N |
| Medaglie | M |
| Regole / folio | ? / F |
| Indietro | Esc |
| Varianti grafiche sperimentali | F8 |
| g3d ↔ renderer precedente | F9 |
| Materiali dadi e diagnostica normali (g3d) | F10 |
| Attiva/disattiva smussatura visiva D6 (g3d) | F11 |

I comandi dipendono dalla fase del turno. Per forzare la grafica precedente: `MANUSCRIPT_RENDERER=legacy`. Per mostrare la diagnostica: `MANUSCRIPT_G3D_DEBUG=1`.

## Codice e prove

Le regole pure sono in `src/gameplay/farkle/`, la partita in `src/app/` e `src/features/farkle/`, il renderer e la fisica attuale in `src/engine3d/`; la libreria g3d è in `lib/g3d/`. I test sono in `tests/` e `scripts/`. I laboratori indipendenti sono in `experiments/g3d_lab/` e `experiments/physics_lab/`.

```powershell
python scripts/test_luajit.py
python scripts/test_love_runtime.py
python scripts/run_smoke.py all
```

Per il laboratorio FPS servono LuaJIT standalone e compilatore C nativo (su Windows Visual Studio Developer PowerShell x64). Vedi [Physics Lab](experiments/physics_lab/README.md) e [risultati](experiments/physics_lab/LAB2_RESULTS.md). La fisica di produzione resta invariata.

## Stato, licenze e attribuzioni

Il progetto è in sviluppo e contiene funzionalità sperimentali. Le librerie **g3d** e **FPS** utilizzano la licenza MIT, conservata rispettivamente in `lib/g3d/LICENSE` ed `experiments/physics_lab/vendor/LICENSE`. Le licenze delle librerie non rendono automaticamente open source l'intero gioco.

**Al momento manca una licenza generale del progetto nella radice.** La redistribuzione del codice originale e degli asset richiede autorizzazione, in attesa di una licenza esplicita. Per dettagli e avvertenze consulta il [README inglese](README.md).
