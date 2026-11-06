# Project Folio — documentazione essenziale

Questa cartella contiene **soltanto i documenti necessari al progetto
corrente**. La versione del gioco è in [`version.txt`](../version.txt);
gli aggiornamenti e le rimozioni sono nel [changelog](../CHANGELOG.md).
Le idee non approvate non devono essere considerate meccaniche implementate.

## Game design

- [Visione](PROJECT_VISION.md) — Venezia di Manuzio, protagonista ispirato
  ad Albrecht Dürer, principi **Simplicity / World Structure / Swelling Power**,
  mastery e incontri ancora da progettare.
- [Brainstorming fondativo v0.3](Project_Folio_Brainstorming_Fondativo_v0.3.md)
  — documento storico del 4 novembre; la definizione successiva del
  protagonista è nella *Visione*.
- [Regolamento Farkle](FARKLE_RULES.md) — il comportamento del gioco attuale.

## Produzione

- [Architettura e test](TECHNICAL.md)
- [Controlli e stati UI](CONTROLS.md)
- [Direzione artistica](ART_DIRECTION.md)
- [Tipografia](TYPOGRAPHY.md)
- [Ritratti degli avversari](OPPONENT_PORTRAIT_PIPELINE.md)
- [Versionamento](VERSIONING.md)

## Verifiche Windows

- [Checklist tecnica](WINDOWS_TECHNICAL_QA.md)
- [Acquisizione grafica UI attiva](UI_V2_VISUAL_REVIEW.md)

## Studi separati dalla documentazione

Gli studi sperimentali su [incontri/Segni](../research/INCONTRI_E_SEGNI.md),
[medaglie](../research/MEDAGLIE_IMPLEMENTAZIONE.md),
[presa e scuotimento](../research/TTS_GRIP_DRAG_SHAKE_DIAGNOSIS.md)
e le [fonti storiche](../research/README.md) sono in `research/`.
Questi studi **non approvano automaticamente nuovi sistemi**.

Gli studi superati di GUI, renderer, tavolo-folio, FX e prime prove
grafiche sono stati rimossi dalla *working tree*, non dalla storia Git.
Sono recuperabili nel
[commit precedente alla pulizia](https://github.com/Askeladd22/Project_Folio/tree/0fc25e369bc2655aa42489ae9078b04b9cef1650/docs).

**Nessuna cartella `archive/` dentro `docs/`**: quella avrebbe
mantenuto lo stesso problema di sovraffollamento.
