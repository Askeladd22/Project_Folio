# Registro delle domande e decisioni — Folio R&D

**Regola:** la parola «approvato» richiede un'esplicita decisione registrata del team. Un test positivo non basta. Le questioni qui elencate non cambiano la visione canonica.

| ID | Domanda | Stato | Prossima prova |
|---|---|---|---|
| RQ-001 | Farkle + Mercante: token, prove contese o diverso sistema di dadi? | in ricerca | Deep research + confronto documentato V4/C |
| RQ-002 | Qual è la posta concreta del duello, distinta dai punti Farkle? | aperta | Test di chiarezza e payoff |
| RQ-003 | Come rendere leggibile ma non banale la scelta del rivale? | aperta | Predizione decisionale da playtester |
| RQ-004 | Qual è il contratto di vittoria dell'incontro? | aperta | Simulazione con policy alternative |
| RQ-005 | Come trasferire mastery e swelling power nella struttura della run? | aperta | Build test, stessa seed e skill differente |

## Modello di record decisione

**D-### — Titolo**

- Data e revisione Git:
- RQ / proposta:
- Prove a favore (fonti, esperimenti e link):
- Prove contrarie e confondenti:
- Vincoli valutati:
- Scelta: approvato / iterare / sospeso / respinto:
- Motivazione e alternative:
- Cosa cambia nel gioco (se approvato):
- Chi ha approvato e dove:
- PR di implementazione (se esiste):
- Condizione di revisione futura:

## Decisioni iniziali

**D-000 — Fondazione del protocollo (9 novembre 2026):**
Introdotta una struttura di ricerca e validazione **documentale**, non è stata approvata nessuna modifica al gameplay. Le decisioni pregresse valide restano in docs/project_vision.md e negli altri documenti canonici.

**Nessun vincitore di RQ-001 è stato scelto.** La comparazione in BASELINE.md è descrittiva e non comprende playtest eseguiti dal laboratorio.

## D-001 — Nome neutro dell'avversario predefinito (18 novembre 2026)

- **Base Git:** `main@b86264fd2d731ce164e6ffe191e6eb0b3a76d6f9` (0.1.75).
- **Richiesta approvata:** il default generico non deve più chiamarsi
  «Mercante», perché crea confusione fra il segnaposto e uno specifico
  personaggio/encounter.
- **Implementazione scelta:** ID neutro `rival`, denominato «Rivale»
  nei testi di utilizzo corrente e nei test G4/G4b; l'ID `merchant`
  rimane valido come scelta **esplicita**, senza rinominare asset storici
  o l'esperimento specifico Merchant Wager.
- **Stato della parola «Rivale»:** scelta di implementazione coerente
  con gli attuali testi del prototipo C, non una nuova identità narrativa
  obbligatoria o il nome proprio di un personaggio.
- **Compatibilità visiva:** `resources/opponents/merchant.png` è
  temporaneamente il ritratto del default `rival`; se è disponibile
  `resources/opponents/rival.png`, la nuova risorsa prevale.
  Il JPEG storico con il Mercante incorporato resta utilizzabile
  soltanto per `merchant` selezionato esplicitamente.
- **Prove da acquisire:** CI su branch, test di selezione/default e
  regressioni g3d/LÖVE, verifiche Windows a cura di un partecipante.
- **Fuori ambito:** cambiare il personaggio illustrato, le regole di
  Farkle, il comportamento del rivale o lo stato canonico di EX-002.
- **Decisione narrativa:** il Mercante rimane un possibile archetipo
  futuro e non è automaticamente il rivale predefinito.
- **Approvazione:** richiesta esplicita dell'utente nel turno
  «basta chiamare l'avversario default Mercante. crea incomprensioni!
  modifica anche il codice».
