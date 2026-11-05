<div align="center">

# PROJECT FOLIO

**A dream of ink and dice.**

Roguelite di dadi ambientato nella Venezia di fine Quattrocento e inizio Cinquecento.

[![Lua regression tests](https://github.com/Askeladd22/Project_Folio/actions/workflows/lua-tests.yml/badge.svg)](https://github.com/Askeladd22/Project_Folio/actions/workflows/lua-tests.yml)
![LÖVE](https://img.shields.io/badge/L%C3%96VE-11.x-ec5d94)
![Status](https://img.shields.io/badge/status-active%20prototype-cc9955)

**[Visione attuale](docs/PROJECT_VISION.md) · [Regole Farkle](docs/FARKLE_RULES.md) · [Changelog](CHANGELOG.md) · [Collaudo Windows](docs/WINDOWS_TECHNICAL_QA.md)**

</div>

## Visione

*Project Folio* è un **titolo provvisorio**, non il nome commerciale definitivo.
L'idea narrativa attualmente discussa è una Venezia vicina al 1500:
un artigiano della tipografia di **Aldo Manuzio** lavora di giorno alle
immagini delle edizioni, la sera gioca alla zara in taverna e la notte
sogna xilografie animate che lo sfidano ai dadi. Il protagonista è muto,
il tono è meraviglioso e conviviale, **non horror**. Il sogno e gli
encounter asimmetrici sono ancora **design in discussione**, non
funzioni già disponibili nella build.

La direzione si fonda su **simplicity**, **world structure** e
**swelling power**, mantenendo una progressione fondata sull'abilità
reale del giocatore anziché su difficoltà adattiva nascosta.
La distinzione fra gameplay funzionante e proposte si trova in
[PROJECT_VISION.md](docs/PROJECT_VISION.md).

## Cosa è già giocabile

- **Sei D6 fisici**: tiro con mouse, presa singola e multipla,
  accantonamento, incasso e rischio di Farkle.
- **g3d come unico renderer 3D** del vassoio e dei dadi;
  nessun fallback CPU o vecchio renderer F9.
- **Commissioni Farkle** con punteggi e soglie ancora provvisori;
  nella modalità normale il tavolo è essenziale: nessuna sidebar
  permanente di commissione/folio/strumenti, soli punteggi
  assicurati e a rischio, dadi accantonati visibili quando presenti.
  Il folio completo rimane consultabile con **F**.
- Il Mercante illustrato accompagna la partita sul tavolo fisico.
- Menu con scena di bottega veneziana in
  `resources/ui/menu_manuzio.png`; splash originale LÖVE conservato.

Le regole operative sono in [FARKLE_RULES.md](docs/FARKLE_RULES.md).
Le specifiche del motore sono in [TECHNICAL.md](docs/TECHNICAL.md).

## Avvio

Serve **[LÖVE 11.x](https://love2d.org/)**. Non è necessario compilare
per avviare la partita.

```bash
git clone https://github.com/Askeladd22/Project_Folio.git
cd Project_Folio
love .
```

Su Windows avviare **`Avvia.cmd`** dalla radice del repository.
Il launcher accetta `LOVE_EXE` se LÖVE non è nel `PATH`.

Percorso attuale: **Splash → Menu principale → Nuova partita →
Commissione → Partita Farkle**. Il comando *Continua* non è ancora
un sistema di ripristino affidabile delle run.

### Controlli principali

| Azione | Comando |
|:--|:--|
| Selezionare un dado | Click oppure **1–6** |
| Lanciare / rilanciare | **Spazio**, oppure presa e lancio con il mouse |
| Selezione multipla / lancio di gruppo | Rettangolo con tasto sinistro, poi presa con tasto destro |
| Accantonare combinazione valida | **A** |
| Incassare i punti del turno | **Invio** |
| Passare al turno successivo | **N** |
| Regole / folio | **?** / **F** |
| Pannello medaglie | **M** |
| Pausa / indietro / annulla presa | **Esc**, secondo il contesto |
| Diagnostica grafica tray / materiale / bevel | **F8 / F10 / F11** |

Le azioni non valide vengono disabilitate durante i lanci fisici.
**F9 non attiva alcun renderer alternativo.**

## Struttura del repository

```text
main.lua, core.lua          Entrypoint LÖVE
src/app/                   Runtime giocabile e coordinamento
src/gameplay/farkle/       Regole, scoring, commissioni e bot beta
src/features/              Menu, UI, input e presentazione
src/engine3d/              Fisica di produzione e integrazione g3d
src/data/                  Schemi e configurazioni
lib/g3d/                  Renderer vendorizzato con licenza
resources/                Immagini, font, shader, texture e suoni
experiments/              Laboratori isolati: NON gameplay di produzione
tests/                    Test headless e harness per smoke/QA
scripts/                  Strumenti di sviluppo, cattura e verifica
docs/                     Documentazione corrente e storico delle ipotesi
```

I laboratori FPS, effetti, miniature e segni sono **esperimenti
indipendenti**. L'esistenza di un laboratorio nel repository non
significa che la sua meccanica sia stata integrata nella partita.

## Test e controllo qualità

GitHub Actions verifica sintassi e test headless sotto **Lua 5.4** e
**LuaJIT**, test Python e laboratorio FPS isolato. Non verifica da sola
la qualità visiva in una finestra LÖVE su Windows.

```bash
python scripts/test_luajit.py
python scripts/test_love_runtime.py
python scripts/run_smoke.py all
```

Per la revisione visiva locale:

```bash
python scripts/capture_ui_v2_review.py
```

Gli screenshot diagnostici e i relativi ZIP sono ignorati da Git;
restano sulla macchina di chi esegue il test. Condividere il
**bundle completo e verificato** seguendo
[WINDOWS_TECHNICAL_QA.md](docs/WINDOWS_TECHNICAL_QA.md).
Una cattura non equivale a QA grafica approvata.

## Design e documentazione

- [Visione e decisioni attuali](docs/PROJECT_VISION.md) — riferimento per il nuovo brainstorming.
- [Regolamento Farkle implementato](docs/FARKLE_RULES.md).
- [Game design storico](docs/GAME_DESIGN.md) e
  [Incontri e Segni](docs/INCONTRI_E_SEGNI.md) — esperimenti e proposte
  precedenti, **non** nuovi requisiti approvati.
- [Direzione artistica](docs/ART_DIRECTION.md),
  [bottega alla Manuzio](docs/MANUZIO_PRINTSHOP_ART_DIRECTION.md) e
  [brief sogno/dadi](docs/MANUZIO_DREAM_DICE_ART_BRIEF.md).
- [Roadmap UI](docs/UI_V2_ROADMAP.md) e
  [stato della UI](docs/UI_V2_STATUS.md).
- [Architettura tecnica](docs/TECHNICAL.md) e
  [versionamento](docs/VERSIONING.md).
- [Interventi di pulizia del repository](docs/REPOSITORY_HOUSEKEEPING_2026_11_04.md).
- [Registro dettagliato di tutte le modifiche](CHANGELOG.md).

La versione del software è definita **solo in [version.txt](version.txt)**;
ogni pull request deve aggiornarla insieme a `CHANGELOG.md`.
Le vecchie sezioni di release note sono conservate nel changelog e
nella cronologia Git, non duplicate nel README.

## Licenze e redistribuzione

- [g3d](https://github.com/groverburger/g3d) — MIT,
  [licenza vendorizzata](lib/g3d/LICENSE).
- [Free Physics Solver](https://github.com/0x1ED1CE/FPS) — MIT,
  **solo laboratorio isolato**, [licenza](experiments/physics_lab/vendor/LICENSE).
- Altre librerie, font, shader e contenuti di terzi hanno licenze
  o condizioni documentate in `third_party/` e nelle cartelle relative.

**Non esiste attualmente una licenza generale nella radice del progetto.**
La licenza MIT delle dipendenze non autorizza automaticamente il
riutilizzo commerciale di codice, musica o artwork originali.
