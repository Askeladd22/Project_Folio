# Project Folio — collaudo tecnico Windows (UI V2 / g3d)

**Versione di riferimento:** 0.1.1 · **Data piano:** 3 novembre 2026  
**Repository:** [Askeladd22/Project_Folio](https://github.com/Askeladd22/Project_Folio)  
**Stato:** **NON ESEGUITO su PC Windows**; il risultato CI Linux non approva questo gate.  
**Scope:** collaudo operativo, osservazione e raccolta prove; non modificare regole
Farkle, fisica, RNG, g3d o assets per “far passare” un test.

## 0. Che cosa è già verificato (e che cosa no)

Il commit di riferimento precedente a questo piano è
\`main@dddd6b5e54dae2aa0df69c33d0b040a5f5de5bff\` (v0.1.0).
GitHub Actions [run 41603525911](https://github.com/Askeladd22/Project_Folio/actions/runs/41603525911)
è **SUCCESS** su Ubuntu: gate versione/changelog, sintassi Lua 5.4,
**85 file \`tests/*_test.lua\`** eseguiti sia con Lua 5.4 sia con LuaJIT,
benchmark deterministico di ricerca Incontri/Segni, laboratorio FPS
*isolato* compilato e provato, e test Python. Non significa che siano stati
eseguiti test GPU LÖVE, audio, input o FPS su Windows.
Il solver FPS nativo dei laboratori **non** è integrato nel gioco.

Il repository include \`scripts/run_smoke.py\` e
\`scripts/capture_ui_v2_review.py\`. Quest'ultimo acquisisce
**32 PNG reali LÖVE** (16 scenari × 2 risoluzioni: 1280×720 e
1920×1080) con coordinate hitbox esportate dal controller,
\`gallery.html\`, \`review-manifest.json\`, \`review-checklist.md\`
e log. Le schermate \`*-fixture\` usano stati artificiali per la
presentazione e **non provano la correttezza di 50 tiri fisici reali**.

## 1. Preflight (PowerShell, nella radice del repository)

Requisiti: **Windows 10/11**, LÖVE 11.x funzionante, Git, Python 3.9+
nel PATH e driver GPU aggiornato. Per i soli test Lua, usare il runtime
disponibile; \`scripts/test_luajit.py\` cerca per default
\`C:\Program Files (x86)\LOVE\lua51.dll\`. Se la DLL è altrove,
impostare \`LOVE_LUA_DLL\` esplicitamente.

Eseguire dalla root di **Project_Folio**, non dalla directory \`scripts\`:

\`\`\`powershell
git fetch origin
git switch main
git pull --ff-only
git rev-parse HEAD
git status --short
python --version
Get-Command git, python
# Solo se love.exe non è nel PATH o nelle directory Program Files:
$env:LOVE_EXE = 'C:\Program Files\LOVE\love.exe'
.\Avvia.cmd
\`\`\`

**PASS:** lo splash LÖVE (rosa/azzurro con cuore) appare, poi il menu
principale; il footer riporta \`v0.1.1\`. Nessun traceback, finestra nera
persistente o errore shader. Lo splash con cuore è **del motore LÖVE**,
non un residuo legacy. Se fallisce: registrare messaggio esatto,
Windows/GPU/driver, \`love --version\` dove disponibile e SHA del commit.
Annotare \`git status --short\`: le modifiche locali devono essere note.

## 2. Test automatici locali (se l'ambiente li supporta)

\`\`\`powershell
# Richiede LuaJIT/lua51.dll fornita da LÖVE oppure LOVE_LUA_DLL.
python scripts/test_luajit.py

# Test del rilevamento del runtime e del sistema di cattura.
python scripts/test_love_runtime.py
python scripts/test_ui_v2_review.py

# Smoke di gameplay con LÖVE reale e profili di salvataggio isolati.
python scripts/run_smoke.py all --out audits/windows-qa/smoke
\`\`\`

\`run_smoke.py all\` esegue \`partial\`, \`face-gate\`, \`integration\`,
\`hud\`, \`frontend\`; il controllo \`tray\` è separato:

\`\`\`powershell
python scripts/run_smoke.py tray --out audits/windows-qa/tray
\`\`\`

**PASS:** terminazione senza errori, marcatori \`PASS\` nei log generati;
lo smoke non sostituisce una partita interattiva. Registrare anche eventuali
test **NON ESEGUITI** (per esempio DLL LuaJIT assente) senza segnarli PASS.
I comandi Python sono le entrypoint presenti nel repository, non nuovi test.

## 3. Cattura della UI V2 attiva — obbligatoria

\`\`\`powershell
python scripts/capture_ui_v2_review.py
\`\`\`

L'output è creato in una directory con data e SHA sotto
\`audits/ui-v2-review/\`. Aprire \`gallery.html\` e attivare
**«Mostra hitbox reali»**; compilare \`review-checklist.md\`, non lasciarla
implicitamente approvata. Esaminare soprattutto:

- [ ] **1280×720 e 1920×1080:** sei facce leggibili, scena g3d e HUD
  non tagliati, pulsanti dentro il viewport, nessun testo oltre i bordi.
- [ ] Marquee dei sei dadi, frame \`physical-group-held\`, overlays non
  invasivi e nessuna confusione fra selezione fisica e Farkle.
- [ ] Modali Aiuto, Scelte/Combinazioni, Ricompense, Folio, Medaglie e
  Monaco: tutte le righe leggibili e controlli raggiungibili.
- [ ] Hitbox esportate allineate ai pulsanti realmente disegnati
  (oro = attivo; grigio = disabilitato; blu = area dei dadi).
- [ ] Flag big-text, high-contrast e reduced-animations: contenuti
  ancora accessibili e contrasti sufficienti.

**PASS del generatore** = 32 immagini e manifest completi; **PASS visuale**
= revisione manuale annotata in checklist con risoluzione e frame.
Non sostituire l'uno all'altro. Fare ulteriori controlli manuali a
**2560×1440** e, se disponibile, in **ultrawide** (non inclusi nei 32 PNG).

## 4. Sessione manuale reale — minimo 50 lanci

Avviare normalmente con \`.\Avvia.cmd\` dopo gli smoke. La sessione
deve usare le vere mesh/facce/risoluzioni: **non** forzare un seed di
scoring o un risultato tramite test fixture. Registrare i progressivi
dei lanci e un log essenziale PASS/FAIL:

| Serie | Minimo | Verifica |
|---|---:|---|
| Lanci automatici (Space) | 15 | fisica, arresto, faccia superiore leggibile, punteggio coerente |
| Presa e lancio singolo (tasto destro) | 10 | una presa / un rilascio / un suono, nessun doppio lancio |
| Selezione marquee + lancio multiplo | 10 | da 2 a 6 dadi mantenendo identità e contatti |
| Shake prima del rilascio | 10 | attivazione solo con inversioni reali, nessuno spin imposto dal drag lineare |
| Rilanci parziali e hot dice | 5 | dadi accantonati fermi, selezioni/accettazioni consistenti |
| **Totale minimo** | **50** | annotare anche i retry fisici e non contarli come nuovi lanci Farkle |

Oltre alle 50 prove, verificare quando si presentano: Farkle (perdita
dei soli punti provvisori), incasso, passaggio di turno/commissione,
ricompensa, medaglia e recupero tecnico. **Non forzare Farkle o hot dice
nel gioco reale**: se non osservati, segnare **NON OSSERVATO** e
aggiungere una sessione mirata. Le prove logiche headless coprono casi
rari ma non provano l'esatta faccia resa sul monitor.

Per le collisioni annotare separatamente: dadi che si incastrano fra loro,
penetrazione dei bordi, clipping, faccia ambigua, reset/freeze, permanenza
di dadi accantonati nel tiro e disallineamento fra picking e render.
Un evento osservato non giustifica da solo la sostituzione del solver.

## 5. Renderer, audio, accessibilità e prestazioni

- [ ] **g3d:** F8 cambia le varianti del tray; F10 materiali, F11
  diagnostica dello smusso. F9 **non** è un'opzione di renderer.
  Nessun fallback CPU, profondità/ombre corrette, texture e facce
  distinguibili, nessuno shader error su GPU reale.
- [ ] **Audio:** dal menu, \`maintitle.ogg\` resta sotto gli SFX
  (mix relativo 0,25 del livello Music); lasciando il menu il brano
  deve fermarsi. \`grab\` una volta per presa, \`shake\` solo per
  inversioni reali, \`throw\` una volta per lancio singolo/multiplo.
  Verificare mute e slider Master/Music/SFX, senza tagli o clipping.
- [ ] **Accessibilità:** scala UI, big text, contrasto elevato,
  reduced animations, mouse/tastiera e Alt-Tab; verificare che
  i controlli non slittino rispetto alle hitbox.
- [ ] **FPS/frametime:** misurare sul PC locale con un overlay/tool
  del sistema (annotando quale). Registrare valori a riposo,
  durante sei dadi in caduta, gruppo in mano e shake, nelle
  risoluzioni 720p e 1080p. Riportare FPS medi/minimi e
  eventuale stuttering, **senza inventare benchmark**. Se
  disponibile una baseline sullo stesso hardware, confrontarla
  prima di proporre interventi alla fisica.
- [ ] **Stabilità:** passaggi Menu → New Game → Commissione → Run,
  Esc, Settings, ritorno al menu e nuova partita senza blocchi.

## 6. Scheda risultati ed evidenze

Per ogni anomalia registrare:

| Campo | Cosa inserire |
|---|---|
| Versione | Commit SHA e \`git status --short\` |
| Ambiente | Windows, LÖVE, GPU, driver, risoluzione, DPI |
| Test | ID/serie del tiro, azione e stato Farkle |
| Evidenza | PNG/video, nome file/log e percorso; risultato atteso/reale |
| Esito | PASS / FAIL / NON ESEGUITO / NON OSSERVATO |
| Prestazioni | FPS/frametime misurati, tool usato, scenario |
| Riproduzione | Passaggi minimi, frequenza, eventuale seed registrato |

Da conservare localmente: \`review-manifest.json\`,
\`review-checklist.md\` **compilata**, \`gallery.html\`, PNG
problematici, \`hud-smoke.log\`, log smoke, resoconto dei 50 tiri
e misurazioni FPS. **Non caricare l'intero \`APPDATA\`**: può contenere
preferenze personali e percorsi locali; oscurare informazioni sensibili
prima di condividere log o screenshot.

**Gate P5:** si può marcare PASS solo dopo risultati verificati di
cattura, gameplay, audio, accessibilità e prestazioni su Windows,
senza bug bloccanti. Fino a quel momento la dicitura resta
**«QA Windows non ancora approvata»**. Gli eventuali bug vanno
tracciati come issue/PR separate, senza modifiche al solver nel
presente audit documentale.
