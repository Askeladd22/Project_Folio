# Documentazione di Project Folio

> **Stato attuale:** consultare sempre la versione in [`version.txt`](../version.txt).
> Le specifiche di gameplay non vanno dedotte da vecchi esperimenti, screenshot
> o roadmap: gli unici contratti di produzione sono sorgenti e test correnti.

## Da leggere per iniziare

| Documento | Contenuto |
|---|---|
| [Visione](PROJECT_VISION.md) | Venezia aldina, protagonista, tre principi cardine e scelte aperte |
| [Brainstorming fondativo](Project_Folio_Brainstorming_Fondativo_v0.3.md) | Discussione estesa del 4 novembre 2026; idee non tutte approvate |
| [Regolamento Farkle](FARKLE_RULES.md) | Combinazioni, accantonamenti, incasso, rischi e commissioni provvisorie |
| [Controlli e stati UI](CONTROLS.md) | Contratto pratico degli input, tasti, dialoghi e pulsanti attivi |
| [Architettura tecnica](TECHNICAL.md) | Componenti, dati, rendering, test e laboratori |
| [Changelog](../CHANGELOG.md) | Evoluzione versionata, rimozioni, limiti e PR |
| [Versionamento](VERSIONING.md) | Regole per release e CI |

## Grafica, ambientazione e presentazione

- [Direzione artistica](ART_DIRECTION.md)
- [Bottega tipografica manuziana](MANUZIO_PRINTSHOP_ART_DIRECTION.md)
- [Riferimenti storici e spaziali](MANUZIO_REFERENCE_SYNTHESIS.md)
- [Brief narrativo: dadi, bottega e sogno](MANUZIO_DREAM_DICE_ART_BRIEF.md)
- [Tipografia: Aldine Aetna / Cardo](TYPOGRAPHY.md)
- [Fondale e avversari PNG separati](OPPONENT_PORTRAIT_PIPELINE.md)
- [Dadi g3d: illuminazione](G3D_DICE_SHADING.md) e [smusso visivo](G3D_VISUAL_BEVEL.md)
- [Audio, feedback e game feel](GAME_FEEL_INTEGRATION.md)
- [Manipolazione fisica dei dadi](MOUSE_GRAB_THROW.md)
- [Presentazione di miniature 2D](2D_PRESENTATION_LIBRARIES.md)

## QA e test attuali

- [Piano QA Windows](WINDOWS_TECHNICAL_QA.md)
- [Acquisizione e revisione visuale della UI](UI_V2_VISUAL_REVIEW.md)
- [Pensionamento del painter CPU](RENDERER_RETIREMENT.md)

Il collaudo Windows (input fisico, FPS reali, audio e resa g3d) **non**
è sostituibile dai test Lua/LuaJIT o dagli smoke Mesa.

## Game design e ricerca (NON funzionalità implementate)

- [Game Design storico](GAME_DESIGN.md): idee di partenza, non fonte canonica.
- [Incontri e Segni](INCONTRI_E_SEGNI.md) e
  [risultati del laboratorio](../experiments/signs_lab/RESULTS_2026_10_31.md):
  esperimenti, non regole di produzione.
- [Medaglie KCD2: ricerca](KCD2_MEDAGLIE_RICERCA.md) e
  [implementazione sperimentale](MEDAGLIE_IMPLEMENTAZIONE.md).
- [Studio tecnico Balatro](BALATRO_TECHNICAL_STUDY.md).
- [FX Studio](FX_STUDIO.md) e [prototipi effetti](FX_PROTOTYPES.md).
- [Tabletop Simulator: meccaniche](TTS_DLL_MECHANICS_STUDY.md) e
  [diagnosi presa/scuotimento](TTS_GRIP_DRAG_SHAKE_DIAGNOSIS.md).
- [Pile fisiche](TABLETOP_DICE_PILE.md) e [convergenza di gruppo](TABLETOP_GROUP_CONVERGENCE.md).
- [Giochi tradizionali: Zara](<Gioco della zara - ENG.pdf>),
  [Barca](<Gioco della barca - ENG.pdf>),
  [Lepanto](<Gioco di Lepanto - ENG.pdf>) ed
  [Early Games of Dice](dice-games.pdf).

## Materiale storico eliminato dalla cartella

Le vecchie roadmap della UI V2 (P0/P1, F6/F9, HUD legacy), la beta
ritirata del Monaco, le procedure obsolete per gli asset del menu e gli
inventari di pulizie pregresse sono stati **tolti dalla working tree**
nella v0.1.40. Restano integralmente recuperabili nella
[revisione storica precedente alla pulizia](https://github.com/Askeladd22/Project_Folio/tree/36ea51a283d82df5d53ddccb1791a978b38d8e89/docs)
e nei commit Git: questa modifica **non riscrive la storia**.

Non ripristinare file antichi solo perché ancora citati in un vecchio
paragrafo del changelog. Le relative citazioni possono utilizzare
permalink al commit storico.
