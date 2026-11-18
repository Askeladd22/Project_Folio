# PAUL 03-01 — EX-003 Apply/Unify (18 novembre 2026)

**Piano approvato dall'utente.** Base
`main@97c730ef6df28a234ba4b78bd1174c9430833c42`,
versione 0.1.76. Branch
`experiments/ex003-duel-paul-seed-20261118` con
proposta v0.1.77; PR #134 **draft**, non promossa su main.

## PLAN — contrasto preregistrato

Due bracci D (duello Farkle diretto) e C (Encounter C corrente),
sei D6 canonici, quattro policy, 200 seed 16000–16199,
holdout 2000–6999 intatto; nessuna carta, HP o conversione
del regolamento di produzione. Metriche principali:
divergenze di incasso/continuazione nello stesso stato pubblico
e variazione di P(win) `situational-balanced` appaiata
**all'interno** di ogni braccio.

## APPLY — verifica Execute / Report / Qualify

| Task/AC | Stato | Qualifica | Evidenza reale |
| --- | --- | --- | --- |
| T1 / AC-1 Direct Farkle | DONE | PASS | `direct.lua`; il Rivale lancia 6 D6 e può vincere, test `ex003_duel_test.lua` |
| T2 / AC-2 Confronto e simulazioni | DONE | PASS | 1.600 partite sintetiche + CSV archiviati in CI; statistiche in `EX-003.md`; regressioni A/C e G4b |
| T3 / AC-3 Protocollo umano | DONE_WITH_CONCERNS | **NOT RUN** per i partecipanti | `EX-003-UAT.md` preparato; nessuna sessione umana, interfaccia D non pronta per test visivo |

**CI EX-003:** [#44344134551](https://github.com/Askeladd22/Project_Folio/actions/runs/44344134551)
(regressione A/C, G4b, test EX-003 Lua5.4/LuaJIT, pilot 1600,
CSV validato 15 colonne) **PASS**;
[#44344432082](https://github.com/Askeladd22/Project_Folio/actions/runs/44344432082)
sulla HEAD con versione/changelog **PASS**.
La CI generale della PR deve essere verificata sulla **HEAD finale**
dopo l'aggiornamento di questo rapporto.

## Risultati quantitativi e red team

- **D**: prudente 120/200 vittorie, bilanciata 109/200,
  audace 100/200, situazionale 106/200.
  `Δwin(situational-balanced)=-1,5 pp` approx95 [-3,7;+0,7].
- **C**: prudente 85/200, bilanciata 75/200,
  audace 66/200, situazionale 86/200.
  `Δwin(situational-balanced)=+5,5 pp` approx95 [+2,0;+9,0].
- Decisioni di banking sensibilizzate: D **158/1.965**,
  C **87/1.831** sullo stato visitato dalla situazionale.
- Scelte categoria della situazionale C divergenti
  dal primo aperto: **0/784**. La policy di targeting
  non ha prodotto differenze dirette nelle allocazioni del
  giocatore nel pilot.
- **Non** confrontare le win-rate D e C fra loro come
  se i due incontri avessero stesse mosse, pari risorse
  o un identico payoff: D concede sei turni Farkle anche
  al Rivale, C un'automatica risposta in sigilli.
- Una strategia naive prudente è competitiva, talvolta
  migliore della situazionale. Nessuna misura qui osserva
  motivazioni o mastery umana.

## UNIFY / SEED

**Risultato tecnico:** il contratto T1–T2 è realizzato e
riproducibile; T3 solo pianificato. I file sono confinati a
`experiments/ex003_duel_lab/`, `tests/labs/`, `research/`
e al workflow CI, versione/changelog.

**SEED quality gate: WARN** (non FAIL perché il confronto è
operativo e falsificabile; non PASS perché mancano decisioni
umane e prova di utilità di una seconda meccanica).
**Game design G3:** WARN; **G4:** NOT RUN;
**G5:** non approvato.

**Unico prossimo gate:** condurre 1–2 pilot cognitivi
con entrambi i modelli, usando `EX-003-UAT.md` e
preparando la modalità di partecipazione senza
toccare la produzione; registrare ogni problema
prima di scegliere D o C. Questo richiede volontari
reali, quindi non risulta svolto in CI.

Nessun merge, nessuna modifica `src/`, nessuna
promessa di vittoria commerciale o promozione di una
meccanica sperimentale.
