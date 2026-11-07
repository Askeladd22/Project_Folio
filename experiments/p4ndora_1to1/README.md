# Project Folio — Farkle VS P4ND0RA (laboratorio)

**Versione 0.1.54; sperimentale, non presente nel gioco principale.**

L'incisore gioca **esclusivamente Farkle con sei D6**; P4ND0RA usa
il proprio sistema originale di estrazione dei token. **Non esistono
carte per il giocatore nel laboratorio giocabile.** Le precedenti carte
di prova erano un errore di impostazione e sono state eliminate.

## Regole dell'incisore

1. Lancia sei dadi virtuali (pulsante **Lancia**, oppure **Spazio**).
2. Seleziona con il mouse uno o più dadi in una **combinazione valida**
   secondo il regolamento effettivo di `src/farkle/rules.lua`.
3. **Accantona [A]** la selezione e rilancia i dadi disponibili,
   oppure **Incassa [I]** per terminare il turno.
4. I dadi accantonati restano fuori dai rilanci, salvo la regola
   canonica degli **hot dice**. Il Farkle annulla i punti
   provvisori di quel turno.
5. Ogni **5 punti Farkle incassati** valgono **1 Combat**.
   Esempio: 55 punti → 11 Combat. Il Combat viene applicato
   agli scudi e agli HP del boss tramite il suo motore originale.
   Questa conversione **NON** proviene da Star Realms: è una
   regola sperimentale per collegare i due sistemi.
6. Dopo che ogni giocatore ancora in vita ha concluso il suo turno
   (incasso o Farkle), si passa alla **fase di P4ND0RA [Invio]**.
   Il boss risolve i token in ordine con **Spazio**.
7. Si vince azzerando gli HP del boss; si perde quando tutti i
   giocatori arrivano a zero Resistenza.

I punteggi e la selezione provengono da una **copia esattamente identica**
del modulo di produzione, `farkle_rules_snapshot.lua`. Il laboratorio LÖVE
si avvia da una sottocartella, quindi non può importare automaticamente
`src/` dalla root. La CI confronta i **byte** della copia con
`src/farkle/rules.lua`, e fallisce se divergono; **non esiste una seconda
implementazione del regolamento**.

I dadi sono al momento **virtuali e 2D**, con valori da D6 corretti.
Non è ancora integrata la fisica g3d, che resta intatta nel gioco principale.

## P4ND0RA: meccaniche conservate

- Quattro difficoltà originali (Easy, Normal, Hard, Nightmare);
  da uno a quattro giocatori, 50 Resistenza iniziale ciascuno.
- **20 token:** Attack 6, Defense 4, Repairs 2, One Star 3,
  Two Star 2, Three Star 1, Special 1, Upgrade 1.
- Estrazione senza reinserimento fino a esaurimento del sacchetto;
  max 8 token per turno; +1 potenza di pesca all'esaurimento
  fino al limite 8; mescolamento degli scarti.
- Ordine: **abilità → attacco → difesa/riparazione → upgrade**.
- Missile Barrage, Active Defense/CQC, Nucleare,
  attacchi su bersagli casuali, scudi, riparazione e upgrade.
- Scudi azzerati all'inizio del turno boss.

### Traduzioni dichiarate dell'interazione con P4ND0RA

Queste regole **non sono 1:1** del mod Star Realms:

| Regola originale | Nell'esperimento Farkle |
|---|---|
| Combat dalle carte | Combat da punti Farkle: 5 punti = 1 Combat |
| EMP scarta carte | EMP blocca 2 dadi (o numero secondo difficoltà) **solo nel tiro iniziale del turno successivo**, fino a un massimo di 3 dadi |
| Scarta un token sacrificando una carta | Incassa spendendo 30 punti Farkle per scartare 1 token casuale; il resto del punteggio produce Combat |
| Neutralizza un token sacrificando una base | Incassa spendendo 20 punti Farkle per neutralizzare il primo token della prossima pesca; il resto produce Combat |
| Missile: perde Authority o sacrifica una base | Senza basi nel Farkle, il giocatore perde la Resistenza indicata |
| Health/Authority del boss | Rimangono HP e Resistenza per confrontare la curva di escalation; **non** sono ancora tradotti in posta di fogli |

Costi, limiti, valore di conversione e controllo dei dadi sono
**variabili di laboratorio**, non proposte definitive per Project Folio.
Nessuna medaglia, nuovo modificatore o buildcraft è incluso.

Il motore P4ND0RA in `engine.lua` mantiene la propria modalità
headless **manuale** per i test delle meccaniche originali. La
schermata LÖVE, però, usa **sempre Farkle**, mai carte.

## Avvio

Da root con LÖVE 11.x:

```powershell
love experiments/p4ndora_1to1
```

Su Windows si può utilizzare
`experiments/p4ndora_1to1/run_lab.cmd`.

**Comandi:** Spazio = lancia o risolvi token, click sui dadi =
seleziona, A = accantona, I = incassa/attacca,
N = incassa/neutralizza (20 punti), D = incassa/scarta
(30 punti), Invio = fase boss, Tab = cambia giocatore,
R = ricomincia con stesso seed, Esc = setup.

## Collaudo

```powershell
lua5.4 tests/labs/p4ndora_original_test.lua
lua5.4 tests/labs/p4ndora_farkle_test.lua
luajit tests/labs/p4ndora_original_test.lua
luajit tests/labs/p4ndora_farkle_test.lua
```

La workflow `p4ndora_lab.yml` esegue anche il controllo di
identità del regolamento e un avvio LÖVE in OpenGL software.
La ripetibilità del seed si riferisce al motore virtuale,
non al lancio fisico dei dadi del gioco principale.

## Scopo

Confrontare il **push-your-luck reale del Farkle** con le
reazioni di un avversario asimmetrico alimentato da un sacchetto.
Il quesito sperimentale è se incassare, rilanciare o sacrificare
punti per una contromisura dia scelte comprensibili e interessanti.
Non usare i risultati di questo laboratorio come prova di bilanciamento
o qualità del gameplay definitivo.
