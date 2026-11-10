# EX-BG-001 — RQ-001, Battute Gemelle: primo gate numerico

**Data:** 2026-11-10 · **Stato:** eseguito, screening G3 negativo; decisione provvisoria **sospendere / non integrare**.
**Baseline main:** `d749cd54306b518c341b0ba8b4c17fcfb64cea66` (0.1.62).
**Commit realmente testato:** `16a48c3c163811170ae50c3f4d2c3a8cccdef277`.
**CI verificata:** [GitHub Actions #42783312311](https://github.com/Askeladd22/Project_Folio/actions/runs/42783312311), **success**.
**Dati grezzi:** [artifact #13746373235](https://github.com/Askeladd22/Project_Folio/actions/runs/42783312311/artifacts/13746373235)
(`bg_matches.csv`, `bg_states.csv`, `report.txt`).
**Autorizzazione:** richiesta dell'utente di eseguire il prossimo esperimento del report RQ-001 v2; nessuna approvazione di gameplay canonico o merge.

## Ipotesi e fonti

**Ipotesi falsificabile:** concedere al Rispondente tanti lanci quanti ne ha usati il Leader crea un trade-off reale STOP/CONTINUE e la migliore scelta cambia al cambiare della policy del Rispondente.

**Fonti primarie interne:** `src/farkle/rules.lua` al commit base,
`docs/project_vision.md`, `docs/farkle_rules.md`,
`research/PROTOCOL.md`, `research/SIMULATIONS.md`.
**Fonte di proposta:** report di Deep Research RQ-001 v2 fornito dall'utente il 10 novembre 2026; il principio di Pietjesbak è un riferimento esterno, non una prova di compatibilità con Farkle.

**Comparazione strutturale (non misurata in questo test):**

| Baseline | Accoppiamento delle decisioni | Limite pertinente |
|---|---|---|
| Farkle/commissioni | nessun rivale | decisioni contro soglie |
| Merchant V4 | cassa e controfferta post-incasso | poca risposta durante il turno |
| Encounter C | tre prove comuni | risorsa avversaria poco vincolata |
| Battute Gemelle | k del Leader impone limite al Rispondente | possibile STOP dominante; ritmo Farkle modificato |

## Regole, protocollo e test

Regole e soglie **preregistrate prima del pilot** nel
[README del laboratorio](../experiments/battute_gemelle_lab/README.md).
Sei D6, valutatore canonico, max tre lanci, pareggio al Leader,
Farkle perde la mano, ruoli alternati, primo a due mani.
Non si introducono carte, HP, valuta, UI o modifiche a `src/`.

**Runtime CI:** GitHub-hosted Ubuntu; Lua 5.4 e LuaJIT.
**Comandi eseguiti:**
- `luac5.4 -p` su engine, simulatore, runner e test;
- `lua5.4 tests/labs/battute_gemelle_test.lua`;
- `luajit tests/labs/battute_gemelle_test.lua`;
- `lua5.4 experiments/battute_gemelle_lab/run.lua 1000 1001 bg-results`.

**Risultato verificato:** 11 casi PASS in Lua 5.4 e 11 in LuaJIT,
workflow **success**; 10.000 match CSV + header e 320 stati di
controfattuale + header archiviati. Non sono stati eseguiti test
grafici né playtest umani per questo laboratorio.

## Pilot: risultati MISURATI (policy scripted, non esseri umani)

1000 seed per cella, seed 1001–2000; ogni seed usato in tutte
le celle. Il consumo di casualità può divergere fra policy.
Intervalli Wilson al 95% sulle vittorie del player.

| Player | Rivale prudente | Rivale aggressivo |
|---|---:|---:|
| Prudente | 494/1000 (46,3–52,5%) | 547/1000 (51,6–57,8%) |
| Aggressivo | 449/1000 (41,8–48,0%) | 506/1000 (47,5–53,7%) |
| Casuale-legale | 242/1000 (21,6–27,0%) | 300/1000 (27,2–32,9%) |
| Informato | 484/1000 (45,3–51,5%) | 517/1000 (48,6–54,8%) |
| Informato cieco | 464/1000 (43,3–49,5%) | 531/1000 (50,0–56,2%) |

Differenza appaiata informato − cieco:
- contro prudente **+2,0 punti percentuali**, IC normale approssimato 95% [+1,13; +2,87] pp;
- contro aggressivo **−1,4 punti percentuali**, IC normale approssimato 95% [−2,36; −0,44] pp.

**Interpretazione limitata:** il controllo casuale-legale perde
molto più spesso delle policy definite; è un segnale di sensibilità
alle scelte, non una prova di mastery umana. La policy
«informata» **non** prevale stabilmente sulla stessa euristica
cieca: migliora contro il prudente ma peggiora contro
l'aggressivo. Il valore della conoscenza del rivale non è dimostrato.

## Controfattuale STOP vs un lancio ulteriore: risultati MISURATI

80 stati dopo k=1 e 80 dopo k=2, primi stati validi nei seed
20001–20200; 96 rollout appaiati per stato/profilo, fascia
di indecisione ±0,10. L'azione CONTINUE nel confronto è
**un lancio ulteriore e poi incasso**, non un piano ottimo.

| Stato | Follower | STOP | CONTINUE | Incerto |
|---|---|---:|---:|---:|
| dopo 1 lancio | prudente | 47/80 | 4/80 | 29/80 |
| dopo 1 lancio | aggressivo | 49/80 | 6/80 | 25/80 |
| dopo 2 lanci | prudente | 43/80 | 4/80 | 33/80 |
| dopo 2 lanci | aggressivo | 48/80 | 7/80 | 25/80 |

**Gate G3a — NON SUPERATO:** il protocollo richiedeva, in almeno
una riga, almeno 8/80 stati STOP e 8/80 CONTINUE. In nessuna
riga CONTINUE arriva a 8: massimo 7/80.

**Gate G3b — NON SUPERATO:** il protocollo richiedeva almeno
8/160 stati con inversione decisiva STOP↔CONTINUE cambiando
policy del follower. Osservati **0/160**.

**G2 — SUPERATO** per i controlli implementati: sintassi,
regressioni deterministiche, vincoli di turno e riproducibilità.
**G4 — NON ESEGUITO:** nessun test di comprensione o
divertimento con persone. **G5 — NON APPROVATO**.

## Red team: che cosa NON dimostrano i dati

1. **STOP sembra spesso migliore nel campione**, ma i risultati
   derivano da una proxy one-step e da selezioni prudenti;
   non è una dimostrazione matematica di STOP dominante in
   tutti gli stati raggiungibili.
2. Le due policy del follower potrebbero essere troppo simili:
   la mancata inversione non prova che nessuna possibile
   strategia avversaria possa influenzare il Leader.
3. Le soglie informate 60/85 e cieca 70 sono euristiche
   predefinite, non un algoritmo ottimo. L'ablazione
   evidenzia una debolezza, non una conclusione universale.
4. Pareggio a favore del Leader, cap tre e best-of-three
   sono parametri di prototipo, non bilanciati.
5. Nessuna comparazione quantitativa diretta con Merchant V4
   o Encounter C è stata eseguita in questo ciclo.
6. La win rate vicino al 50% non equivale a profondità;
   il controllo casuale può perdere per semplici errori
   di selezione senza che esista controgioco significativo.
7. Mancano playtest, posta concreta, struttura di run e
   prova di swelling power.

## Decisione PROVVISORIA, non canonica

**Sospendere Battute Gemelle nella forma minima congelata; non
promuovere in `src/` e non modificare a posteriori i gate.**
Il primo screening non trova abbastanza stati CONTINUE
decisivi né alcuna inversione decisiva rispetto ai due
profili di Rispondente. La CI verde dimostra che il
laboratorio funziona, non che la meccanica soddisfa RQ-001.

**Alternativa successiva dal report:** Tre Prove — Riserva
finita. È una nuova ipotesi da preregistrare separatamente:
in Encounter C la spesa rivale deve diventare una risorsa
pubblica, limitata e realmente contesa fra prove. Prima
di scrivere una UI, verificare se il giocatore cambia corsia
dopo la spesa del rivale e se le finte inducono costi reali.

**Prossimo gate:** decisione dell'utente su avvio del
secondo laboratorio RQ-001; poi protocollo, codice headless,
test appaiati e, solo se supera G3, playtest umano G4.
Nessun merge, PR di integrazione o aggiornamento delle
regole canoniche è autorizzato da questi risultati.
