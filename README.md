# Manuscript — Farkle Roguelite

Gioco solitario di sei dadi fisici e tre commissioni librarie, in Lua/LuaJIT e **LÖVE2D 11.x**. g3d e il renderer GPU predefinito del vassoio a libro; il motore fisico personalizzato rimane invariato.

## Avvio

Aprire questa directory in VS Code/Codex ed eseguire:

```text
love .
```

Su Windows: **Avvia.cmd**. Il libro utilizza g3d automaticamente; **F9**
attiva il renderer storico. `MANUSCRIPT_G3D_INGAME=0` oppure
`MANUSCRIPT_RENDERER=legacy` forzano il painter all'avvio.
`MANUSCRIPT_G3D_DEBUG=1` mostra l'etichetta diagnostica.
g3d viene caricato solo al primo rendering compatibile; in caso di errore
GPU si torna al painter. Le altre varianti F8 e i dadi non D6 usano
ancora il percorso precedente.
Usa `LOVE_EXE`, un'installazione Windows nota oppure `love.exe` nel PATH. Nessun Python necessario per giocare, nessun pacchetto `.love`, nessuna build intermedia. Modificare un sorgente e riavviare LÖVE.

Splash → Main Menu → New Game → Choose Commission → **Farkle Roguelite**. Il selettore contiene solo il gioco e Back. Settings e grafica originali sono conservati. Continue resta disabilitato: non è implementata la ripresa di una run.

## Controlli

Clic sui dadi oppure **1–6**: selezione. **Scelte**: alternative del tiro, con ID, punti e dadi residui. **Accantona/A**, **Lancia o Rilancia/Spazio**, **Incassa/Invio**, **Avanti/N**, **Medaglia/M** quando disponibili. **?**: regole; **F**: folio; **Esc**: chiude la finestra o torna al menu. Nuova run e Senza mod sono in Gestione run. I comandi sono bloccati mentre i dadi si muovono.

Il regolamento ufficiale usa singoli 10/5, combinazioni disgiunte del tiro corrente, selezione parziale, soglie d'ingresso/incasso, Farkle e hot dice. I numeri delle commissioni sono ancora **parametri di test**, esplicitamente indicati nell'HUD.

Il vassoio usa un'inquadratura ortografica stabile. Dopo **Accantona**, i dadi raggiungono il ripiano sotto il bordo: ogni posto conserva valore, ID del dado e numero del lancio accettato. La selezione non confermata resta sul vassoio. Hot dice libera tutti i posti al nuovo lancio. A fine turno vengono mostrati punti incassati/persi, obiettivo e turni rimasti; **Prossimo turno / N** è immediatamente disponibile. Trasferimento e feedback sono brevi, senza attese obbligatorie, e rispettano l'impostazione di riduzione delle animazioni.

## Sorgenti e sviluppo

- `main.lua`, `conf.lua`: entry point e identità dell'applicazione.
- `src/gameplay/farkle/`: regole e punteggio, indipendenti da LÖVE.
- `src/features/farkle/`: controller, selezione, HUD, mappe dei dadi e adattatore visivo.
- `src/app/`: runtime; `src/engine3d/`: fisica congelata e adattatori GPU.
- `lib/g3d/`: libreria MIT condivisa con il laboratorio A/B.
- `src/core/`, `src/data/`, altre `src/features/`: frontend e servizi condivisi.
- `resources/`, `lib/`: asset e librerie attivi.
- `tests/`, `tests/smoke/`, `scripts/`: test e strumenti correnti.
- `legacy/`: materiali storici; `audits/` e `backups/`: evidenze e checkpoint protetti.

`experiments/` contiene laboratori A/B e il laboratorio nativo FPS, isolati dal runtime normale. Il gioco non importa moduli da queste directory. I componenti condivisi `src/features/scriptorium/desk_view.lua` e `page_layout.lua` restano necessari alla grafica; il vecchio gameplay cromatico è separato.

Identità salvataggi invariata: `manuscript-farkle-roguelite`, normalmente `%APPDATA%/LOVE/manuscript-farkle-roguelite`. Impostazioni `settings_data.lua`, registro `runs.csv`; nessuna scrittura nei salvataggi del vecchio Scriptorium.

## Verifiche

Dalla radice:

```text
python scripts/test_luajit.py
python scripts/test_love_runtime.py
python scripts/test_luajit.py scripts/farkle_analysis.lua
python scripts/run_smoke.py all
```

Il runner Lua usa la DLL LuaJIT già distribuita con LÖVE; `LOVE_LUA_DLL` permette di specificarla. Gli smoke usano `love .` e il launcher, isolano APPDATA e producono screenshot/log in `audits/farkle-promotion/after/` (oppure `--out DIRECTORY`). Si possono scegliere `hud`, `frontend`, `partial`, `face-gate`, `integration` o `tray` singolarmente. Le fixture degli stati rari non rappresentano tiri fisici; le prove fisiche confrontano faccia geometrica e valore. I vecchi harness in audits restano riproducibili con i rispettivi checkpoint, non sono i comandi correnti.

Non lasciare variabili `MANUSCRIPT_*_SMOKE` o `MANUSCRIPT_SOURCE_CASE` impostate per il gioco normale. Non avviare script storici di packaging o formatter sull'intero archivio. Le probabilità teoriche non certificano l'uniformità del simulatore.

## Documentazione autorevole

- [Game Design 0.4](docs/GAME_DESIGN.md): identità, stato e decisioni aperte.
- [Regole Farkle](docs/FARKLE_RULES.md): tabella ufficiale, soglie, commissioni e analisi preliminare.
- [Tecnica](docs/TECHNICAL.md): architettura, contratti e limiti del motore congelato.
- [Archivio storico](legacy/README.md): materiali conservati e provenienza.
- [Promozione strutturale](PROMOZIONE_FARKLE.md): mappa dei trasferimenti, verifiche e rollback.

La fisica non è una simulazione perfetta: persistono limiti di contatto e contenimento. Non riaprire autonomamente solver SAT, geometria, proporzioni, spawn o validazione A/B. Il prossimo lavoro riguarda il gameplay.
