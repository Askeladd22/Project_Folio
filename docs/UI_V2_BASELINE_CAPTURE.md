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
- per ciascuna risoluzione, la baseline ora **richiede** `fresh-pre-grip`,
  `marquee-six`, `physical-group-held`, `accessibility-on`,
  `fresh-after-cancel`, `folio` e `upgrade`;
- l'opt-in `--ui-v2-baseline` abilita il percorso diagnostico esclusivamente
  nella smoke HUD; l'avvio normale non esegue nessuno di questi gesti;
- `hud/hud-smoke.log`, comprensivo delle asserzioni del runtime;
- `baseline-manifest.json`: commit, working tree dirty/clean, numero di PNG,
  percorso, dimensione e SHA-256 di ciascuno screenshot.

La scena `physical-group-held` è acquisita con gli effettivi comandi
`U:mousepressed`, `U:mousemoved`, `U:mousereleased` del controller:
vengono selezionati tutti e sei i D6 con un marquee, presi col tasto
destro, mantenuti brevemente e infine annullati con Esc. Il test fallisce
se la selezione non comprende sei dadi, se la presa non è realmente di
gruppo o se l'annullamento causa il rilascio fisico. La scena
`accessibility-on` attiva temporaneamente testo grande, contrasto alto
e animazioni ridotte, poi ripristina la configurazione precedente.

**Importante:** la cattura registra i flag di accessibilità ma **non
dimostra** che il vecchio HUD li applichi correttamente: la leggibilità
di quel frame deve essere valutata visivamente.

**Il contenuto di `audits/` è locale**: non aggiungere automaticamente
file generati o screenshot al repository. Per la revisione è sufficiente
condividere screenshot/log/manifest dal percorso sopra indicato.

## Verifiche manuali ancora indispensabili

Il smoke HUD esistente non copre ogni gesto interattivo. Aprire
`Avvia.cmd` sulla stessa versione del gioco e acquisire un'immagine:

| Stato | Azione riproducibile e cosa controllare |
|---|---|
| Fresh | Inizio commissione, sei D6 leggibili, testata e azioni non sovrapposte al folio |
| Held / manipolazione | Frame generato automaticamente con sei dadi afferrati; verificare visivamente il comportamento della convergenza, del puntatore e degli overlay azzurri |
| Ready / scoring | Lancio completato, selezione di 1 e/o 5, azioni Set aside / Bank coerenti con la fase |
| Folio modal | `F`, verificare che si apra senza errore, progresso assicurato e a rischio, `Esc` chiude senza mutare punti |
| Reward | Completare la prima commissione, scelta `weighted` / `engraved` visibile e cliccabile |
| Accessibilità | Frame generato automaticamente con i tre flag attivi; controllare visivamente se testo e contrasti *cambiano davvero* e se pulsanti/hitbox restano corretti |
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
