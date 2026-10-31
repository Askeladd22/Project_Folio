# Project Folio — versionamento e registro obbligatorio

## Fonte canonica

- **`version.txt` (radice):** contiene esattamente una versione SemVer,
  senza il prefisso `v`. È la fonte ufficiale della versione software.
- **`CHANGELOG.md` (radice):** registro cronologico **dalla voce più
  recente alla più vecchia**, sempre aggiornato nello stesso PR.
- **`src/core/version.lua`:** legge la versione dal file, senza
  duplicarla nell'applicazione. Il menu principale mostra `vX.Y.Z-dev.N`.
- **`docs/GAME_DESIGN.md`:** la sua versione interna misura la revisione
  del documento; **non** equivale alla versione del gioco.
- **`docs/UI_V2_STATUS.md`:** tracker delle milestone UI, utile ma
  distinto dal changelog ufficiale del software.

## Regola per OGNI update

**Ogni nuova PR che modifica il repository, inclusi fix, refactor,
documentazione, librerie, test, grafica e cleanup, deve:**

1. Aggiornare `version.txt` con una versione **strettamente maggiore**
   di quella presente nel branch di destinazione.
2. Inserire in testa a `CHANGELOG.md` la sezione
   `## [X.Y.Z-dev.N] - YYYY-MM-DD`, corrispondente alla versione.
3. Registrare cosa è stato **aggiunto, modificato, corretto, rimosso**,
   quali test sono stati eseguiti e quali gate rimangono aperti.
   Non dichiarare superati test che non sono stati eseguiti.
4. Mettere link o numero della PR quando è noto; indicare esplicitamente
   se un esperimento **non** è attivo nel gioco.
5. Aggiornare i tracker tecnici interessati, se necessario, senza
   sostituire il changelog.

**Non fondere una PR senza questo aggiornamento.** La CI verifica
`version.txt`, la prima sezione del changelog, il bump monotono rispetto
alla base e che entrambi i file siano effettivamente cambiati nella PR.
Il controllo funziona senza servizi esterni e viene eseguito su push e PR.

### Scelta iniziale della numerazione

Non esisteva un file di versione precedente a questa implementazione:
il footer del menu era **`v0.1` hardcoded**, un'etichetta alpha, non
una catena di release certificata. La prima baseline è
**`0.1.0-dev.1`** (31 ottobre 2026), senza inventare release passate.

Durante lo sviluppo usare `0.1.0-dev.2`,
`0.1.0-dev.3`, ... per ogni PR. Quando si deciderà una milestone
pubblica, adottare versioni SemVer stabili e/o prerelease standard.
Si può aumentare minor/major per cambi incompatibili o nuove tappe
di prodotto: la CI richiede solo l'ordine SemVer corretto.

**Non modificare il numero dentro vecchie sezioni:** sono uno
storico verificabile. Correggere eventuali errori aggiungendo una nota
alla nuova sezione, salvo rettifica esplicitamente documentata.

## Template di una nuova sezione

```markdown
## [0.1.0-dev.2] - YYYY-MM-DD

**Stato:** ...

### Aggiunto
- ...

### Modificato
- ...

### Corretto
- ...

### Rimosso
- ...

### Verifiche
- Passati: ...
- Da verificare su Windows/LÖVE: ...
```

Omettere solo le categorie effettivamente vuote. In caso di più PR
contemporanee, prima di integrare verificare che la versione sia ancora
maggiore dell'ultima `main`: se necessario, aumentarla e riallineare
il changelog prima del merge.

## Controllo locale

Dalla radice del repository:

```bash
python3 scripts/check_versioning.py
```

Il comando controlla la versione attuale e il formato del changelog.
La modalità PR usa `--base-sha` e `--head-sha` sulla cronologia Git,
richiede la modifica di entrambi i file e il bump rispetto alla base.
Per la PR di bootstrap senza vecchi file canonici si applica una
eccezione **soltanto alla comparazione storica**, non alla presenza
dei file nella nuova versione.
