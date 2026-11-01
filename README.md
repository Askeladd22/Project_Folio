<div align="center">

# PROJECT FOLIO

**A dice-driven roguelite set in a fifteenth-century scriptorium.**

Risk every throw. Build your manuscript. Decide when to stop.

[![Lua regression tests](https://github.com/Askeladd22/Project_Folio/actions/workflows/lua-tests.yml/badge.svg)](https://github.com/Askeladd22/Project_Folio/actions/workflows/lua-tests.yml)
![LÖVE](https://img.shields.io/badge/L%C3%96VE-11.x-ec5d94)
![Status](https://img.shields.io/badge/status-active%20prototype-cc9955)

[Game design](docs/GAME_DESIGN.md) · [Farkle rules](docs/FARKLE_RULES.md) · [Technical notes](docs/TECHNICAL.md) · [UI 2.0 roadmap](docs/UI_V2_ROADMAP.md) · **[Versione](version.txt) · [Registro aggiornamenti](CHANGELOG.md)**

</div>

## Versioni e aggiornamenti

La versione attuale del prototipo è definita **esclusivamente**
in [`version.txt`](version.txt) ed è mostrata automaticamente nel
menu principale. Ogni update deve aumentare la versione e aggiungere
una sezione datata al [`CHANGELOG.md`](CHANGELOG.md), indicando
funzioni aggiunte/modificate/rimosse, test e limitazioni.

**La CI rifiuta una PR senza bump di versione e changelog aggiornato.**
Per il procedimento completo vedere [`docs/VERSIONING.md`](docs/VERSIONING.md).
La versione del documento di game design resta indipendente da quella
del software. La **prima baseline ufficiale** è `0.1.0-dev.1`
(31 ottobre 2026); la ricostruzione retrospettiva completa è entrata
nella successiva `0.1.0-dev.2`.

Il [registro storico](CHANGELOG.md) documenta anche l'evoluzione
**precedente a version.txt**: dai primi commit del marzo 2026
alla prima IA e allo scoring Farkle del luglio 2026, fino alle
**39 PR integrate** fra il 16 e il 31 ottobre, con date e link originali.
Non si confondono esperimenti rimossi, funzionalità attive o release.

## Prototipi di gameplay isolati

Il laboratorio [**Incontri e Segni A/B/C0/C**](experiments/signs_lab/README.md)
confronta il Farkle corrente, una progressione lineare e un
duello sperimentale (con e senza bonus) contro la miniatura del Leone della Bordura,
con estrazione di Segni senza reinserimento e criteri di rischio
riproducibili. Si avvia con
`luajit experiments/signs_lab/run.lua 100 20261031`:
**non è una modalità già integrata nella partita** e non
sostituisce la sfida beta al Monaco.

## Interfaccia di gioco — UI 2.0 unica

La `0.1.0-dev.18` migliora la **presa fisica multipla**
dei dadi ispirandosi a Free Physics Solver: invece di formare
una pila 3+3 o una griglia rigida, i sei corpi reali
inseguono con un moto elastico smorzato un punto di presa
comune. I contatti temporanei della mano evitano il
collasso in un unico punto; il rilascio preserva le
posizioni dei singoli D6 e torna al solver esistente.
La presa singola, Farkle, g3d, il bot e lo splash LÖVE
rimangono invariati. Occorre ancora una prova di movimento
reale su Windows.



Dalla `0.1.0-dev.17` la
[galleria per la revisione visiva Windows](docs/UI_V2_VISUAL_REVIEW.md)
può mostrare **le vere hitbox del controller** sovrapposte
agli screenshot LÖVE: oro = azioni abilitate; grigio =
azioni disabilitate; blu = regione fisica dei sei D6.
La vista diagnostica è reversibile e non modifica i
pulsanti, la fisica o i PNG acquisiti.
La QA visiva sul PC Windows resta da completare.


Dalla `0.1.0-dev.16` la tipografia delle modali Farkle V2
misura anche **righe e altezza** di paragrafi e descrizioni,
evitando la fuoriuscita del testo dalle schede del folio.
Sono compresi aiuto, tabella dei punteggi, ricompense e
laboratorio medaglie; le hitbox e il gameplay sono invariati.
La conferma della leggibilità con i font reali richiede
ancora la QA LÖVE su Windows.


**Revisione grafica Windows della UI V2 attiva (0.1.0-dev.15):**
eseguire `python scripts/capture_ui_v2_review.py` per acquisire
32 screenshot reali LÖVE a 720p/1080p e ottenere una galleria
HTML, un manifesto verificabile e una checklist di QA.
Vedere [la guida alla revisione visiva](docs/UI_V2_VISUAL_REVIEW.md).
La cattura non approva automaticamente l'aspetto; le prove
fisiche con sei D6 e gli stati di punteggio diagnostici sono
documentati separatamente. Gameplay e renderer invariati.


Dalla `0.1.0-dev.14` anche le finestre di partita della UI V2
(aiuto, combinazioni, medaglie, folio, menu run e ricompense)
utilizzano etichette adattive, hover e separatori coerenti
con la pergamena illuminata. Le ricompense sono presentate
su due schede separate. ID delle azioni, hitbox, Farkle
e dadi 3D rimangono invariati. QA grafica Windows
ancora da verificare.


Dalla `0.1.0-dev.13` la sfida opzionale al Monaco condivide
i pannelli di pergamena e le etichette adattive della UI 2.0:
scheda dell'avversario, punti e ultimo tiro, più il risultato
finale con lo stesso comando Riprova. L'animazione del Monaco,
i dadi 3D e i comandi originali rimangono invariati.
La verifica grafica Windows è ancora necessaria.


Dalla `0.1.0-dev.12` il folio laterale e il pannello Strumenti
formano una composizione coerente con cornice da legatura e
separatore ornamentale. Il titolo del registro dei sei D6
accantonati è nel margine sopra gli slot, che ora hanno toni
pergamena/inchiostro; la zona di lancio e gli hitbox sono identici.
QA grafica Windows LÖVE ancora necessaria.


Dalla `0.1.0-dev.11` la barra Farkle mostra dati di
commissione in celle di lettura distinte e il messaggio
di stato appare su una fascia pergamena. Pulsanti e
titoli lunghi adattano il font alla larghezza senza
andare a capo o troncare i caratteri UTF-8.
Nessun cambiamento a dadi g3d, controlli o gameplay.
La QA grafica reale Windows rimane necessaria.


Dalla `0.1.0-dev.10` anche intestazione della commissione,
pannello Strumenti e pulsanti del Farkle adottano i toni
pergamena/inchiostro del frontend, mantenendo gli stessi
hitbox, tiri di dadi 3D e regole. La verifica grafica reale
sotto LÖVE Windows resta necessaria.


Dalla versione `0.1.0-dev.7` il gioco usa **esclusivamente**
`src/features/farkle/ui_v2/hud.lua` per la schermata
Farkle. Il vecchio HUD, il fallback con F6 e la
variabile `MANUSCRIPT_UI_V2_EXPERIMENT` sono stati
rimossi dal codice operativo; nessuna doppia
interfaccia è disponibile. La fisica dei D6, il
libro/tray g3d e le regole Farkle restano invariati.

Le finestre di regole, medaglie e ricompense ora
vivono in `ui_v2/dialogs.lua`; il loro redesign
visivo completo è ancora un'attività aperta.
Vedere [stato e gate di QA](docs/UI_V2_STATUS.md).

## Menu e commissioni — stile folio

Da `0.1.0-dev.8` il menu principale, la scelta di
commissioni e i dialoghi del Farkle utilizzano il
componente comune `src/features/ui_v2/menu_surface.lua`:
pagine di pergamena e bordi miniati al posto
delle vecchie fasce scure. È conservato il fondale
della bottega; le azioni del menu e le regole
di gioco rimangono le stesse. Le risoluzioni
720p/1080p/1440p sono coperte dai test di geometria;
la verifica fotografica LÖVE Windows resta da fare.

## Impostazioni e splash LÖVE

Da `0.1.0-dev.9` anche le **Settings** usano la
superficie comune di pergamena della UI 2.0,
con geometrie verificabili a 720p/1080p/1440p.
I controlli, gli effetti audio in anteprima,
le opzioni di accessibilità e la persistenza
rimangono inalterati.

La sequenza iniziale con **cuore, rosa e azzurro**
è lo splash originale del motore **LÖVE**:
non appartiene alla vecchia GUI di Project Folio
e viene conservata con animazioni e pulsanti
di salto originali.

## Overview

The display name is temporary. The `manuscript` repository, internal `scriptorium` scene IDs and existing save identity stay unchanged for compatibility; they are not the public-facing game title.

**Project Folio** (temporary working title; formerly presented as *Scriptorium*) is a single-player, dice-driven roguelite built with **Lua/LuaJIT and LÖVE 11.x**. Six physical three-dimensional dice are the heart of the experience. Each throw creates a decision: bank a promising result, set dice aside, or push your luck with another roll.

The world is a late-medieval workshop of scribes and illuminators. Manuscript pages, commissions and the book-shaped tray provide the visual language for a game that retains the tension of **Farkle** rather than reproducing a conventional deck-building roguelite.

> **Development status:** playable prototype, not a finished or commercially released game. Scores, commission thresholds, progression and some presentation details are under active development. This repository also contains isolated experiments that are *not* part of normal gameplay.

## Current playable features

- **Six physical D6**, with shared rigid-body simulation, identifiable upper faces and textured 3D geometry.
- **Farkle-inspired push-your-luck**: choose scoring combinations, keep selected dice, reroll or bank your turn; risk a Farkle if a throw produces no valid scoring option.
- **Commission-oriented progression**, with a dedicated manuscript-themed folio and HUD. Some objective values are currently prototype parameters.
- **Interactive 3D book tray** using [g3d](https://github.com/groverburger/g3d) exclusively, GPU depth testing, paper-edge geometry, contact shadows and highlighted usable dice.
- **Original production physics** retained while alternative solvers are evaluated independently.
- **Menu, settings, resolution scaling, sound and keyboard/mouse controls** with regression and smoke-test tooling.

All F8 tray variants and existing D8 geometry use g3d; the CPU painter and F9 switch have been retired. g3d shader or Canvas failures are now reported explicitly rather than silently switching renderers. Windows graphical verification is still required. The alternative [Free Physics Solver](https://github.com/0x1ED1CE/FPS) is **not** used by the playable game.

## Getting started

**Requirements:** Windows or Linux; [LÖVE 11.x](https://love2d.org/) installed and accessible (or its executable configured). No compilation or Python installation is necessary for ordinary play.

```bash
git clone https://github.com/Askeladd22/manuscript.git
cd manuscript
love .
```

On Windows, use **`Avvia.cmd`** instead of `love .`; it searches for a LÖVE executable and also accepts the `LOVE_EXE` environment variable. Start from the repository root so that assets resolve correctly.

**In-game path:** Splash → Main Menu → New Game → Choose Commission → Farkle Roguelite. **Continue** is not currently available; do not treat the existing run registry as a resumable game save.

### Controls

| Action | Input |
|:--|:--|
| Select a die | Click the die or press **1–6** |
| Roll / reroll | **Space** (automatic), right-drag individual dice, or **left-drag a selection rectangle then right-drag the group** |
| Set aside scoring dice | **A** when available |
| Bank turn points | **Enter** |
| Advance after the turn | **N** |
| Open rules / folio | **?** / **F** |
| Open medal panel | **M** |
| Close an overlay / navigate back | **Esc** |
| Cycle experimental tray artwork | **F8** |
| Cycle dice render material / normal debug | **F10** |
| Toggle visual D6 bevel (g3d normals/diffuse/ivory) | **F11** |

Actions are context dependent; dice selection and scoring actions are blocked while a physical roll is in progress.

### Renderer options

**g3d is the only 3D renderer** for the six physical D6 and the book tray.
F8 changes the tray artwork, F10 cycles g3d dice materials and F11
toggles the g3d bevel diagnostic. **F9 no longer toggles a CPU painter.**
`MANUSCRIPT_RENDERER=legacy` and `MANUSCRIPT_G3D_INGAME=0` are retired.
Set `MANUSCRIPT_G3D_DEBUG=1` to display the g3d material diagnostic.

A g3d / required shader failure is now surfaced directly. Check the
LÖVE console or error report; there is **no silent CPU-renderer
recovery**. See the [retirement record](docs/RENDERER_RETIREMENT.md)
for the changes and remaining Windows visual QA.

## Optional 2D miniature presentation toolkit

The game now includes pinned, MIT-licensed (or license-noted) 2D libraries
for sprite animation (anim8), tweens (Flux), manuscript text (SYSL-Text),
and an **opt-in-only 2D** vignette (Moonshine). None of these libraries
changes the g3d 3D dice/tray or Farkle physics.

See [2D toolkit and dependency licenses](docs/2D_PRESENTATION_LIBRARIES.md)
and [isolated miniature lab](experiments/miniature_2d_lab/README.md).
The library lab is not a production battle or a 3D character engine.

## Project architecture

```text
main.lua                Canonical LÖVE entry point
src/
  app/                  Playable dice runtime and integration
  core/                 Navigation, settings, events, resolution, audio
  data/                 Scene configuration and data schemas
  engine3d/             Current physics, g3d adapter and geometry/camera tools
  features/farkle/      Controller, tray, HUD, presentation, input
  features/scriptorium/ Manuscript desk visuals and page layout
  gameplay/farkle/      Rules and scoring independent from LÖVE
lib/g3d/                Vendored third-party g3d library
resources/              Art, shaders, dice textures, fonts, audio
experiments/
  g3d_lab/              Isolated g3d camera and physics diagnostics
  physics_lab/          Optional native FPS benchmarks (C / LuaJIT FFI)
tests/                  Pure Lua regression tests and graphical smoke harnesses
docs/                   Design, engineering notes and research
```

**Separation of responsibilities:** physics computes die poses; rendering presents them; Farkle resolves accepted dice and scores. The FPS laboratory must never modify the production solver simply because one benchmark appears faster.

## Testing

**Continuous integration** runs Lua 5.4 and LuaJIT headless regression tests, syntax checks, and a native Linux build/smoke comparison for the optional FPS lab. The graphical scene and GPU depth/compositing require manual validation in a real LÖVE window.

From the repository root:

```bash
python scripts/test_luajit.py
python scripts/test_love_runtime.py
python scripts/run_smoke.py all
```

For the FPS experiments, install a native compiler and a standalone `luajit` executable. On Windows, open an **x64 Visual Studio Developer PowerShell**:

```powershell
.\experiments\physics_lab\build-windows.ps1
luajit .\experiments\physics_lab\run.lua 64 450 lab2
```

The lab saves a reproducible comparison to `experiments/physics_lab/build/results-lab2.csv`. The FPS 1.2.5 code remains a **work in progress**; smaller time steps improve its face-validity metrics but it has not met the production acceptance criteria. See [experimental methodology and results](experiments/physics_lab/LAB2_RESULTS.md). **Do not ship the lab DLL or substitute FPS into Farkle without separate engineering and visual QA.**

## Roadmap

The priorities are to validate the now g3d-only visual paths, physical rolls and interaction across resolutions, refine manuscript-specific roguelite progression, and complete structured testing of alternative contact solvers. These are planned improvements, **not promises of implemented features**.

For detailed design decisions, consult [GAME_DESIGN.md](docs/GAME_DESIGN.md) and [FARKLE_RULES.md](docs/FARKLE_RULES.md).

## Attribution and licensing

- [g3d](https://github.com/groverburger/g3d) — MIT; vendored notice: [`lib/g3d/LICENSE`](lib/g3d/LICENSE).
- [Free Physics Solver](https://github.com/0x1ED1CE/FPS) — MIT; used **only** by the optional lab; notice: [`experiments/physics_lab/vendor/LICENSE`](experiments/physics_lab/vendor/LICENSE).
- Additional third-party fonts, effects and assets have their notices in `third_party/`, `resources/` and related source directories. Check individual terms before redistributing any asset.

**The repository has no project-wide root `LICENSE` file at present.** MIT permissions for vendored libraries **do not** automatically license the game's original source code, artwork or music. Contact the repository owner for redistribution or commercial-use authorization until a project license is published.


## Beta duel vs a 2D manuscript miniature

Choose **Sfida il Monaco (beta)** in the main menu to play an optional
one-commission Farkle duel against an AI-controlled **flat 2D monk**.
The human still uses the original physically rolled g3d dice and tray.
The opponent uses an independent fair virtual D6 generator and official
Farkle rules; the normal solo campaign is unchanged. See
[bot duel and Lovely Toasts documentation](docs/BOT_DUEL_AND_TOASTS.md).
