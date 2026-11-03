# Project Folio — audit acquisizioni UI Windows del 3 novembre 2026

**Stato:** revisione parziale delle **evidenze effettivamente presenti** su GitHub.
Nessuna approvazione estetica, nessun benchmark FPS, nessuna modifica
alla logica del Farkle o al motore 3D.

## Origine verificata

- Repository: `Askeladd22/Project_Folio`
- Commit upload: [`c2b2f74aaf1e`](https://github.com/Askeladd22/Project_Folio/commit/c2b2f74aaf1eec31ec21aeeaf31439632e59441d)
- Commit del runtime al momento dell'acquisizione:
  `1e3761cee88909a2e298fec51f08000d1524ce61` (codificato
  nella directory acquisizioni come `1e3761ce`)
- Cartella: [`audits/ui-v2-review/20261103-084723-1e3761ce/`](https://github.com/Askeladd22/Project_Folio/tree/main/audits/ui-v2-review/20261103-084723-1e3761ce)
- Lo strumento `scripts/capture_ui_v2_review.py` richiede
  **16 scenari × 2 risoluzioni = 32 PNG** con i relativi TSV.

## File rilevati nel repository

| Risoluzione | PNG presenti / richiesti | TSV presenti / richiesti | Copertura |
|---|---:|---:|---|
| 1920×1080 | 16/16 | 16/16 | Tutti gli scenari definiti nel generatore |
| 1280×720 | 2/16 | 2/16 | Solo `fresh` e `marquee-six` |
| **Totale** | **18/32** | **18/32** | **Acquisizioni non complete nel tree** |

**14 scenari 1280×720 mancanti nell'upload:** `physical-group-held`, `fresh-after-cancel`, `accessibility-on`, `help`, `help-scores`, `folio`, `run-menu`, `ready-fixture`, `choices-fixture`, `selected-fixture`, `upgrade-fixture`, `medal-fixture`, `reference-catalog`, `monk-live`.

**Non presenti nella cartella acquisizioni:** `gallery.html`,
`review-manifest.json`, `review-checklist.md`, `hud/hud-smoke.log`.
Non compare sul branch `main` neppure `audits/windows-qa/smoke/`.
Non dedurre da questa assenza che tali file non esistano sul
computer dell'operatore: il repository contiene solo ciò che è stato
effettivamente committato.

## Controlli tecnici delle mappe hitbox

Analizzati tutti i **18 TSV**:
- nessun comando con rettangolo non valido, fuori dalle dimensioni
  corrispondenti o fuori dallo schermo;
- nessuna sovrapposizione fra due azioni **abilitate** nello stesso frame;
- negli unici due scenari disponibili a entrambe le risoluzioni,
  `fresh` e `marquee-six`, le coordinate `x,y,w,h`
  a 1280×720 corrispondono a **2/3 esatti** di quelle a 1920×1080;
  gli stati `enabled` coincidono;
- nel frame `physical-group-held` a 1920, tutte le azioni
  `folio/help/roll/runmenu` risultano disabilitate durante la presa,
  coerentemente con il blocco delle azioni nel gesto fisico.

Questi sono controlli **geometrici e di stato**, non revisione
visiva dei PNG né conferma di click reali o corrispondenza delle
facce Farkle. Non sono stati misurati fps/frametime o audio.

## CI del commit di acquisizione

La [CI GitHub Actions `41606048617`](https://github.com/Askeladd22/Project_Folio/actions/runs/41606048617)
sul commit `c2b2f74a` è **FAIL** per il primo gate
`Require version bump and changelog for every update`:
`missing: CHANGELOG.md, version.txt`. Tutti i passi Lua, LuaJIT,
laboratorio FPS e Python sono quindi **SKIPPED**, non falliti.
Il commit precedente `1e3761ce` aveva invece CI completa verde.

Il presente intervento incrementa la versione a `0.1.2` e aggiorna
il changelog, ripristinando la compatibilità con la policy del progetto.
Verificare l'esito della CI di questa modifica prima del merge.

## Gate P5 e azioni necessarie

1. Confermare se i **14 PNG/TSV 1280** mancanti sono sul PC e
   includerli nel repository senza rigenerare risultati fittizi.
2. Aggiungere i file effettivamente prodotti:
   `review-manifest.json`, `gallery.html`,
   `review-checklist.md` **compilata** e `hud/hud-smoke.log`
   (inclusi path/sha corretti e dopo eventuale oscuramento
   di dati personali).
3. Completare lo smoke separato LÖVE e annotare il comando usato,
   gli esiti e la versione effettivamente collaudata.
4. Documentare almeno 50 lanci fisici interattivi, gestione
   grab/shake/throw e incasso/Farkle senza forzare risultati.
5. Verificare personalmente le immagini a 720p/1080p, la
   resa GPU g3d, la leggibilità dei testi e l'allineamento
   effettivo fra hitbox e grafica; annotare FPS e audio.

**Conclusione:** evidenze parziali credibili e geometrie coerenti
per quanto analizzato; **QA Windows non ancora certificata**.
Nessuna richiesta di modificare la fisica in assenza di un
problema riproducibile.
