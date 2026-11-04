# Project Folio — repository housekeeping (4 novembre 2026)

## Perimetro

Baseline `main@dff95698622ef1544e8fb7f3d744610c06ad9839`,
versione `0.1.12`. Inventario Git: **461 file** (escluse le directory).
Intervento **di manutenzione**, senza modifica di motore fisico,
Farkle, UI runtime, librerie o comportamento del gioco.

## Eliminazioni verificate

- Rimossi **36 file** (18 PNG, 18 TSV; **2.047.031 byte**)
  da `audits/ui-v2-review/20261101-101134-b2e7f4cb/hud/`.
  Si trattava di un vecchio snapshot parziale della UI, preceduto
  nel progetto dall'acquisizione più recente del 3 novembre.
  La ricerca nei sorgenti e nella documentazione corrente non ha
  rilevato riferimenti testuali a quella cartella.
- I file eliminati rimangono **recuperabili nella cronologia Git**;
  la dimensione del clone storico non diminuisce per questo.
  Nessun rewrite della storia e nessuna cancellazione di prove recenti.

## Materiale conservato volutamente

- `audits/ui-v2-review/20261103-084723-1e3761ce/`:
  **36 file / 2.013.052 byte**; il rapporto
  [WINDOWS_QA_CAPTURE_REVIEW_20261103.md](WINDOWS_QA_CAPTURE_REVIEW_20261103.md)
  vi fa ancora riferimento. È un'acquisizione incompleta
  (**18/32** scene), non un'attestazione di QA superata.
- `resources/textures/tray/walnut.png`: **81.056.842 byte**,
  texture attiva. La sostituzione o compressione richiederebbe
  confronto a 720p e 1080p, UV e integrità del vassoio;
  **non è stata toccata**.
- `resources/sounds/maintitle.ogg` (~5,1 MB),
  `resources/ui/menu_manuzio.png` (~4,2 MB) e
  `resources/ui/menu.png` (~2,1 MB): asset in uso
  o fallback di compatibilità.
- Shader e grafiche dello **splash originale LÖVE**,
  sei texture D6, `lib/g3d`, fisica di produzione,
  esperimenti FPS/g3d/FX/miniature/signs, test e relative licenze.
  I laboratori sono isolati ma rimangono diagnostici.
- Tutto `CHANGELOG.md`: registro cumulativo e storia verificabile.

## Organizzazione e prevenzione

- `README.md` riportato allo stato corrente: rimosso
  il lungo racconto cronologico dei singoli `0.1.0-dev.*`,
  già conservato nel changelog.
- `docs/PROJECT_VISION.md` distingue i pilastri e il
  brainstorming approvati dalle funzionalità reali.
- `docs/GAME_DESIGN.md` e `INCONTRI_E_SEGNI.md`
  rimangono come storia della ricerca, non fonte canonica
  per la nuova direzione degli encounter.
- `.gitignore` esclude **nuove** catture
  `audits/ui-v2-review/`, QA `audits/windows-qa/`,
  output compilati dei laboratori e bundle distributivi.
  Ignorare un percorso **non rimuove i file già tracciati**:
  lo snapshot del 3 novembre rimane versionato.
- La procedura consigliata è condividere lo ZIP di evidenza
  verificato, non committare decine di screenshot temporanei.
  Eventuali futuri campioni di QA destinati al repository
  richiedono una scelta esplicita e `git add -f`.

## Verifiche e limiti

- Test headless aggiunto per i confini del cleanup e per
  la conservazione dei componenti di produzione.
- CI prevista: Lua 5.4/LuaJIT, Python, laboratorio FPS isolato.
- QA grafica Windows **non attestata**: nessun test headless
  dimostra da solo la resa g3d, l'audio o il comportamento del mouse.
- Il peso della **storia Git** non è ridotto; per questo
  sarebbe necessario un intervento separato (LFS/rewrite)
  che non rientra in una pulizia conservativa.
