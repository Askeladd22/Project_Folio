# Registro modifiche — Project Folio

Questo file è il **registro ufficiale e cumulativo** degli aggiornamenti del gioco.
Ogni PR deve aggiungere una nuova sezione, collegata alla versione scritta in
[`version.txt`](version.txt). La CI verifica che versione e changelog siano
aggiornati insieme; le istruzioni sono in [`docs/VERSIONING.md`](docs/VERSIONING.md).

> Le versioni precedenti al 31 ottobre 2026 non avevano un registro versionato
> unico: gli interventi già integrati sono qui riepilogati come **baseline
> retrospettiva** tramite PR verificabili, **non** come release pubblicate.
> La versione del documento di game design è indipendente da quella del software.

## [0.1.0-dev.1] - 2026-10-31

**Tipo:** baseline iniziale del sistema di versionamento (prototipo in sviluppo).
**Stato:** prima versione tracciata formalmente, non release commerciale.

### Aggiunto
- Prima fonte di versione ufficiale `version.txt`, consultabile dal menu.
- Changelog cumulativo `CHANGELOG.md` e procedure di versionamento in
  `docs/VERSIONING.md`, con controllo automatico nelle PR.
- **Modalità beta contro il Monaco**: avversario Farkle con dadi virtuali
  indipendenti, stessa tabella ufficiale, miniatura 2D e punteggi affiancati
  ([PR #36](https://github.com/Askeladd22/Project_Folio/pull/36)).
- Librerie opzionali per le miniature e i testi 2D: **anim8, Flux, SYSL-Text**;
  vignettatura 2D sperimentale con **Moonshine** e laboratorio dedicato
  ([PR #35](https://github.com/Askeladd22/Project_Folio/pull/35)).
- Notifiche contestuali non bloccanti con **Lovely Toasts**, integrate nel
  laboratorio delle miniature e nella sfida al Monaco
  ([PR #36](https://github.com/Askeladd22/Project_Folio/pull/36)).

### Modificato
- Consolidato **g3d come unico renderer 3D** per dadi e tray, eliminando il
  painter CPU, il toggle F9 e i relativi fallback; F8/F10/F11 restano per
  le opzioni g3d ([PR #38](https://github.com/Askeladd22/Project_Folio/pull/38)).
- Ampliato il prototipo UI 2.0: studio dei layout, vertical slice giocabile,
  indicatori discreti per selezione, rischio e dadi accantonati
  ([PR #31](https://github.com/Askeladd22/Project_Folio/pull/31),
  [#32](https://github.com/Askeladd22/Project_Folio/pull/32),
  [#34](https://github.com/Askeladd22/Project_Folio/pull/34)).
- Adottato **Project Folio** come titolo pubblico provvisorio
  ([PR #33](https://github.com/Askeladd22/Project_Folio/pull/33)).

### Rimosso / pulizia
- Eliminati **32 file** del vecchio HUD cromatico, immagini non referenziate,
  test obsoleti e screenshot FX rigenerabili; mantenuti fisica, laboratori
  utili e texture attive
  ([PR #37](https://github.com/Askeladd22/Project_Folio/pull/37)).
- Rimossi fallback e painter 3D legacy, con documentazione di migrazione
  ([PR #38](https://github.com/Askeladd22/Project_Folio/pull/38)).

### Test e limiti conosciuti
- CI headless Lua 5.4/LuaJIT, Python e laboratorio FPS superata nelle PR
  richiamate. **La prova visiva Windows LÖVE reale a 1280×720 e 1920×1080
  resta un gate aperto**, in particolare per g3d, accantonamento, UI 2.0,
  notifiche e bot. I test headless non certificano shader e GPU.
- La sfida al Monaco è una modalità beta Farkle contro Farkle, **non** ancora
  il sistema definitivo di incontri asimmetrici e Segni.
- Le figure e gli avversari sono **2D**; i soli dadi e tray sono **3D**.
