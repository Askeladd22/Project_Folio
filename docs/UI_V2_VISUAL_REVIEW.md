# Project Folio — revisione visiva della UI V2 (Windows)

**Ambito:** interfaccia V2 attualmente attiva in Project Folio; script
introdotto con `0.1.0-dev.15`, confermato per la serie `0.1.x`.
La precedente procedura [P0 legacy](https://github.com/Askeladd22/Project_Folio/blob/36ea51a283d82df5d53ddccb1791a978b38d8e89/docs/UI_V2_BASELINE_CAPTURE.md) è
documentazione storica. Questa cattura automatica è **un passaggio**
della [checklist tecnica Windows](WINDOWS_TECHNICAL_QA.md), che comprende
anche controlli manuali di input, OpenGL, audio, 50 lanci e FPS.

## Avvio

Dalla radice del repository aggiornato, in PowerShell:

```powershell
git rev-parse HEAD
python scripts/capture_ui_v2_review.py
```

Serve Python 3.9+, Git e **LÖVE 11.x** su Windows. Il launcher di test
cerca automaticamente `love.exe`. Se necessario:

```powershell
$env:LOVE_EXE = 'C:\Program Files\LOVE\love.exe'
python scripts/capture_ui_v2_review.py
```

È possibile scegliere un'altra directory con `--out C:\Percorso\Prove`.
Ogni esecuzione crea **una cartella separata** sotto
`audits/ui-v2-review/<data-ora>-<commit>`, senza sovrascrivere
le acquisizioni precedenti.

Il percorso di prova è **esclusivamente diagnostico**: `run_smoke.py hud
--ui-v2-review` imposta `MANUSCRIPT_UI_V2_REVIEW_CAPTURE=1`.
All'avvio normale di Project Folio non modifica HUD, logica, 3D o impostazioni.

## Output e attendibilità

- Da `0.1.3` viene prodotto anche `<nome-cattura>-evidence.zip`
  **all'esterno** della directory acquisita, contenente tutti i
  32 PNG, i 32 TSV, manifesto, galleria, checklist, log e un indice
  SHA-256. La creazione del pacchetto fallisce se mancano file:
  [procedura e comandi](WINDOWS_TECHNICAL_QA.md). Il bundle non
  include `appdata`, non sostituisce la revisione manuale e non
  modifica la simulazione fisica.
- `gallery.html` apre una galleria locale di tutte le immagini,
  organizzate per stato e risoluzione. La casella **«Mostra hitbox reali»**
  sovrappone in modo reversibile i rettangoli acquisiti dal controller
  **nello stesso frame** dello screenshot: oro per i comandi attivi,
  grigio tratteggiato per quelli disabilitati, blu per il tavolo 3D.
  La galleria non altera gli screenshot PNG originali.
- `hud/hud-usability-<risoluzione>-<stato>.hitboxes.tsv`
  conserva ID, coordinate *screen-space* e stato abilitato di ciascun
  controllo. Il programma verifica duplicati, dimensioni e limiti
  dello schermo e li include nel manifesto.
- `review-manifest.json` contiene SHA del commit, flag working tree sporco,
  data UTC, dimensioni dei PNG, byte e SHA-256.
- `review-checklist.md` raccoglie i controlli **da compilare
  manualmente**: contrasti, clipping, proporzioni, hover/input, FPS e g3d.
- `hud/hud-smoke.log` contiene le asserzioni eseguite dal runtime.
- `hud/hud-usability-1920-*.png` e `hud/hud-usability-1280-*.png`
  sono **32 frame reali catturati tramite LÖVE** (16 stati per risoluzione).

I frame registrano menu della partita, informazioni nell'HUD,
help/regole, folio, combinazioni, ricompensa dado, ricompensa
medaglia, catalogo e tavolo del Mercante.

I frame `marquee-six` e `physical-group-held` eseguono una **vera**
selezione e presa fisica con sei dadi 3D tramite il controller. Il
test verifica il numero effettivo di dadi e che Esc non registri un
rilascio fittizio.

I frame terminanti con `-fixture` rappresentano invece **stati
diagnostici**: vengono iniettati valori di dadi nel controller,
che applica le **vere regole Farkle**, per riprodurre una schermata
di combinazioni o ricompense. Non attestano corrispondenza fra facce
dei dadi fisici e punteggi nello screenshot. La verifica dei lanci
reali è un gate separato.

Le modifiche di accessibilità applicate durante il frame
`accessibility-on` vengono ripristinate in seguito.

## Gate di approvazione (non automatico)

Aprire la galleria sul computer Windows e compilare
`review-checklist.md`, annotando eventuali anomalie e i frame
relativi. Verificare anche manualmente puntamento ai D6,
corrispondenza fra hitbox esportate e pulsanti **attivando la casella
«Mostra hitbox reali»** nella galleria, testo grande, contrasto alto,
animazioni ridotte e prestazioni/FPS in partita reale.

Le hitbox provengono dai dati dell'interfaccia realmente in esecuzione,
non da geometrie ricostruite in Python. La sovrapposizione controlla
allineamento geometrico, **non prova che un click sia stato realmente
eseguito o accettato**.

**Un run con stato PASS garantisce solo che siano state ottenute
immagini vere e complete alle dimensioni attese. Non certifica
l'aspetto visivo né autorizza a segnare P5/P7 come completate.**

Condividere almeno `review-manifest.json`, `review-checklist.md`
e gli screenshot problematici per poter intervenire sui difetti
visibili. I file generati rimangono locali e non sono aggiunti
automaticamente al repository.
