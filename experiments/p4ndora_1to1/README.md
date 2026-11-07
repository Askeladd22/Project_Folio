# P4ND0RA originale — laboratorio isolato di Project Folio

**Stato: esperimento, NON gameplay approvato.** Questo laboratorio riproduce
**il motore delle azioni del boss P4ND0RA** dalla mod Tabletop Simulator
`STAR REALMS BOSS FIGHT CONCEPT` (script Lua condiviso dall'autore il
30 ottobre 2026). Non è una conversione dei danni in punti Farkle.

## Che cosa significa «1:1» qui

Riproduzione *a livello di regole e sequenze del boss*, non dei componenti
fisici di Tabletop Simulator e non dell'intero gioco commerciale Star Realms.

**Fedeltà implementata:**
- Difficoltà Easy/Normal/Hard/Nightmare con statistiche originali per 1–4 giocatori.
- 20 token iniziali: **6 Attack, 4 Defense, 2 Repairs, 3 One Star,
  2 Two Star, 1 Three Star, 1 Special, 1 Upgrade**.
- I giocatori agiscono per primi; poi P4ND0RA pesca fino a `draw` token
  (massimo 8). Sacchetto e scarti separati, senza reinserimento immediato.
- Risoluzione rigorosa: **abilità → attacchi → difesa/riparazione → upgrade
  (una sola volta anche con più token Upgrade)**.
- Missile Barrage: ogni giocatore sceglie se distruggere una base
  oppure perdere Authority pari alla potenza missilistica.
- EMP: scarta il numero previsto di carte; su Nightmare, almeno
  una carta fazione se disponibile.
- Three Star / CQC: danno Combat in ingresso dimezzato e arrotondato
  per difetto fino alla scadenza del numero previsto di turni.
- Special: prepara il nucleare per tre estrazioni; alla quarta,
  **-20 Authority e distruzione di tutte le basi**, poi azzera il contatore.
- Attack: bersaglio casuale fra giocatori vivi; Defense aggiunge scudi;
  Repairs cura fino al massimo.
- Upgrade incrementa Attack e Repairs di 1, Shield di 1 o di 2
  (se più di due giocatori).
- Gli scudi si azzerano **all'inizio del turno del boss**, come nello script.
- L'esaurimento del sacchetto incrementa `draw` (+1 fino a 8) e
  permette di rimescolare gli scarti alla fine del turno.
- Due contromisure: scartare un token casuale dal sacchetto,
  neutralizzare i primi token della prossima pesca.
- Authority iniziale 50 per giocatore; perdita definitiva a zero;
  vittoria contro gli HP del boss o sconfitta con tutti eliminati.

## Limiti dichiarati rispetto all'originale

**Non è 1:1 dell'intero scenario Tabletop Simulator / Star Realms.**

1. Il tavolo 3D, gli oggetti TTS, la distribuzione delle carte, il
   mazzo commerciale, Trade Row, fazioni, Outpost, regole complete delle
   carte e animazioni originali non sono portati.
2. Il giocatore **immette manualmente** Combat, Authority curata, carte
   in mano e basi dal pannello: questi valori devono riflettere il suo
   turno reale a Star Realms. Il prototipo non genera carte gratuitamente
   secondo un regolamento interno.
3. EMP scarta automaticamente dal conteggio delle carte. Non simula
   quali effetti specifici si perdono; su Nightmare riduce il conteggio
   di carte fazione quando presente.
4. Gli attacchi del boss colpiscono direttamente Authority perché
   lo script TTS annuncia danni tramite memo; la scelta manuale fra
   Outpost/Base e giocatore non è automatizzata nel codice originale.
5. Il sistema TTS utilizza talvolta `math.randomseed(os.time())`
   durante gli attacchi: qui si usa un generatore locale con seed
   ripetibile, senza favori nascosti.
6. La modifica al Draw è applicata appena il sacchetto diventa vuoto
   dopo la pesca. Questo elimina una particolarità di temporizzazione
   dello script TTS quando la pesca esaurisce esattamente il sacchetto.
7. Le contromisure hanno un costo esplicito di **1 carta** oppure
   **1 base**, rispettivamente; nel TTS l'esborso è effettuato
   manualmente sul tavolo e non controllato dai pulsanti Lua.
8. Il sistema mantiene separata l'interfaccia sci-fi originale; **non**
   reinterpreta P4ND0RA come Mercante, xilografia o cassa tipografica.
   L'eventuale adattamento a Project Folio verrà deciso dopo i test.

Le differenze non sono correzioni dichiarate del regolamento originale:
sono i limiti o le normalizzazioni della trasposizione automatica.

## Avvio

Con **LÖVE 11.x** installato:

```powershell
love experiments/p4ndora_1to1
```

Da Windows, doppio click su
`experiments/p4ndora_1to1/run_lab.cmd`.

**Controlli principali:** scegli difficoltà, numero di giocatori (1–4)
e seed, quindi avvia. Nella fase giocatori immetti i risultati
delle carte: **Combat +1/+5/+10**, Cura +5, + Base, + Carta.
Per un ingresso diverso da questi valori, combina più pressioni o
modifica le risorse di prova in un test mirato. Dopo che tutti
hanno agito, premi **Invio / Fase boss**. Durante P4ND0RA
premi **Spazio** per risolvere il successivo token nell'ordine corretto.

Se esce Missile Barrage, **non puoi avanzare** finché ogni giocatore
coinvolto non sceglie se perdere una base o Authority. I pulsanti
restano attivi soltanto nelle fasi pertinenti. Con **Tab** cambi
giocatore, **R** ripeti lo stesso setup/seed, **Esc** torna al setup.

Per testare fedelmente gli effetti delle carte di Star Realms,
la distribuzione e il calcolo devono rimanere **manuali**: il progetto
non incorpora o riproduce il mazzo commerciale.

## Test

Dalla root del repository:

```powershell
lua5.4 tests/labs/p4ndora_original_test.lua
luajit tests/labs/p4ndora_original_test.lua
```

La CI ordinaria esegue il test perché si trova sotto `tests/`.
I test verificano composizione del sacchetto, quattro difficoltà,
seed, conservazione dei token, ordine, azioni, contromisure, nucleare,
scudi, CQC, rimescolamento, eliminazione e vittoria.

## Scopo dell'esperimento

Osservare come il boss originale produca pressione, escalation e
contromisure con **un sistema d'azione indipendente dal giocatore**.
Questo laboratorio serve da riferimento per valutare un futuro
avversario asimmetrico in Project Folio; **nessun gameplay di
Farkle o modulo in produzione viene modificato**.
