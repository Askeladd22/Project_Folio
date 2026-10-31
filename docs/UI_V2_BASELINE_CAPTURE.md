# UI 2.0 — acquisizione della baseline grafica P0 (Windows)

**Obiettivo:** catturare la **vera** interfaccia LÖVE legacy a due risoluzioni,
con codice e impostazioni identificabili, prima di disegnare UI 2.0.
Non si sostituiscono gli screenshot con mock, schizzi o risultati headless.

## Test automatico della baseline esistente

Da PowerShell, nella radice del repository Manuscript:

```powershell
git rev-parse HEAD
python scripts/capture_ui_v2_baseline.py
```

Richiede Python, `git` e **LÖVE 11.x** installato in Windows;
se `love.exe` non viene trovato automaticamente:

```powershell
$env:LOVE_EXE = 'C:\Program Files\LOVE\love.exe'
python scripts/capture_ui_v2_baseline.py
```

Lo script invoca il test già disponibile `scripts/run_smoke.py hud`;
questo avvia **la vera scena** con le funzioni di gioco, cattura
frame 1920×1080 e 1280×720 e controlla il log delle prove.
Tutti i dati vengono scritti sotto `audits/ui-v2-p0/`:

- `hud/hud-usability-1920-*.png`, `hud/hud-usability-1280-*.png`;
- `hud/hud-smoke.log`, comprensivo delle asserzioni del runtime;
- `baseline-manifest.json`: commit, working tree dirty/clean, numero di PNG,
  percorso, dimensione e SHA-256 di ciascuno screenshot.

**Il contenuto di `audits/` è locale**: non aggiungere automaticamente
file generati o screenshot al repository. Per la revisione è sufficiente
condividere screenshot/log/manifest dal percorso sopra indicato.

## Verifiche manuali ancora indispensabili

Il smoke HUD esistente non copre ogni gesto interattivo. Aprire
`Avvia.cmd` sulla stessa versione del gioco e acquisire un'immagine:

| Stato | Azione riproducibile e cosa controllare |
|---|---|
| Fresh | Inizio commissione, sei D6 leggibili, testata e azioni non sovrapposte al folio |
| Held / manipolazione | Marquee di sei D6, destro mantenuto, convergenza sotto il puntatore, nessuna perdita di spazio o cerchi che nascondono i pallini |
| Ready / scoring | Lancio completato, selezione di 1 e/o 5, azioni Set aside / Bank coerenti con la fase |
| Folio modal | `F`, verificare che si apra senza errore, progresso assicurato e a rischio, `Esc` chiude senza mutare punti |
| Reward | Completare la prima commissione, scelta `weighted` / `engraved` visibile e cliccabile |
| Accessibilità | Ripetere con big text, high contrast e reduced animations, annotando eventuali elementi tagliati o non cliccabili |
| Debug | F8/F9/F10/F11, soprattutto overlay dei D6 rispetto alla camera e al tray |

Annotare per ogni cattura risoluzione, commit e impostazioni, distinguendo
lo stato Farkle dal movimento fisico dei dadi. Misurare per la stessa
inquadratura il frame time/FPS con HUD legacy e g3d: servirà come
riferimento per verificare che UI 2.0 non peggiori sensibilmente la resa.

La PR P0 rende **ripetibile** la cattura ma non dimostra che il test
sia già stato eseguito sul computer dell'utente. La fase P0 rimane
aperta finché screenshot e controllo manuale non sono registrati nel
[tracker](UI_V2_STATUS.md).

## Bug legacy verificato durante P0

`hud.lua` usava `manuscript(...)` nel modal `folio`, ma non
esisteva alcuna funzione con quel nome nello scope. È stato
sostituito con `folio_view.draw(...)`, già usato nella testata
laterale, con l'obiettivo della commissione autentico.
`tests/ui_v2_folio_modal_regression_test.lua` rende il dialog e
gli altri modali con un grafico fittizio **solo per testare controllo
e invarianti**. Non sostituisce la prova visiva Windows.
