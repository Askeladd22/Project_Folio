# Intrecci cromatici — esperimento indipendente

Esito del 13 ottobre 2026: **non ancora pronto per l'integrazione**. Le regole
funzionano, ma le simulazioni non dimostrano un vantaggio della pianificazione
sulla scelta opportunista. Nessun modulo di produzione, asset, UI, fisica o
salvataggio è stato modificato. Solo questa directory contiene il prototipo.

## Esecuzione

Dalla radice del repository, usando il runner LuaJIT già disponibile:

```powershell
rtk python scripts/test_luajit.py experiments/intrecci/test.lua
rtk python scripts/test_luajit.py experiments/intrecci/simulate.lua
```

Il secondo comando rigenera `results.csv` e `games.csv` in questa directory.
Default: 2.000 seed per agente per configurazione. `INTRECCI_N` permette una
quantità diversa per debug; i risultati consegnati usano il default.
Non serve avviare LÖVE: il runner utilizza la sua DLL LuaJIT, senza grafica.

## Regole implementate

20 caselle, 4 D6, 8 turni, massimo 2 piazzamenti per turno, 4 gettoni rilancio
globali. Un gettone rilancia un sottoinsieme non vuoto di dadi non utilizzati.
Le caselle contengono stringhe: rosso, blu, giallo, verde, marrone, nero.
`place(state, die, cell)` prende il pigmento dalla mano, senza parametro colore.
Non esistono valori numerici con significato ludico. Il risultato casuale è
uniforme fra sei pigmenti. I dadi non usati vengono scartati a fine turno.
Si può passare, anche senza piazzare. Dopo due piazzamenti termina il turno;
nessun rilancio è consentito a quota due. Un pigmento piazzato non si rimuove.

Coordinate (riga,colonna), base 1, dei quattro motivi:

1. Scacchiera, origine (1,1).
2. Quartetto, origine (1,3).
3. Quartetto, origine (2,2).
4. Scacchiera, origine (3,4).

Scacchiera = diagonali dello stesso pigmento, diagonali fra loro diverse.
Quartetto = quattro pigmenti distinti. Entrambi richiedono tutte e quattro le
caselle. Vittoria immediata a tre motivi; sconfitta al termine dell'ottavo turno
se la soglia non è raggiunta. Le mosse che compromettono motivi restano legali.

Nota sul progetto precedente: il quarto motivo di questa disposizione è
isolato, non sovrapposto. Abbiamo conservato questa disposizione come baseline
del rapporto e misurato separatamente una correzione (`connected`), spostando
solo nell'esperimento il quarto motivo a (3,2). Così tutti fanno parte dello
stesso insieme connesso. Nessuna coordinata dell'interfaccia è cambiata.

## Agenti e metodologia

- `random`: casuale prudente. Sceglie uniformemente fra coppie dado/casella che
  aumentano il progresso senza compromettere motivi vivi. È deliberatamente
  più forte di un agente che spreca mosse fuori dai motivi.
- `greedy`: massimizza una funzione immediata (caselle nei motivi possibili,
  premio di completamento, penalità dei motivi compromessi). Nessuna ricerca.
- `planner`: ricerca di due piazzamenti sui dadi visibili, con beam di quattro
  prime mosse ed enumerazione delle seconde. Valuta i tre migliori motivi,
  favorendo il completamento; conserva un piccolo valore per il quarto.

Tutti rilanciano i dadi rimasti quando non trovano progresso secondo la propria
valutazione; altrimenti piazzano. Se non possono migliorare e non hanno gettoni,
passano. Non è implementata una scelta ottima dei sottoinsiemi da rilanciare,
sebbene il motore la supporti. Il pianificatore non simula i turni futuri:
è una ricerca breve, non MCTS o un solutore ottimo. Questi limiti impediscono
di concludere che il gioco non possa avere alcuna profondità.

Seed 1..2000 accoppiati fra gli agenti. Nastro Park–Miller con warmup, indirizzato
per turno/dado/tentativo: azioni differenti non spostano i risultati degli altri
dadi. I numeri del seed non sono accessibili agli agenti attraverso la loro
politica; nessun agente consulta il nastro futuro. I test controllano frequenza
dei pigmenti e frequenza di uguaglianza di dadi consecutivi (tolleranza 1 punto
percentuale): sono diagnostici, non una certificazione statistica del generatore.
Una prima costruzione casuale troppo correlata è stata scartata; tutti i CSV
consegnati sono rigenerati con il nastro corretto.

Un solver separato verifica la fattibilità congiunta di ogni terna di motivi,
mediante backtracking su sei pigmenti. Non guida gli agenti e non predice il caso.
`feasible_at_end` ignora il tempo esaurito: indica se la posizione sarebbe ancora
completabile avendo ulteriori piazzamenti/colori, non se la partita è vinta.

## Risultati: 30.000 partite

2.000 per agente per configurazione = 6.000 per riga.

| Configurazione | Casuale prudente | Opportunista | Pianificatore |
|---|---:|---:|---:|
| Base: 8 turni, 4 rilanci | 73,70% | 100% | 100% |
| 8 turni, 3 rilanci | 72,80% | 100% | 100% |
| 7 turni, 4 rilanci | 72,85% | 100% | 100% |
| 8/4, coppie fisse nelle scacchiere | 66,60% | 99,95% | 99,70% |
| 8/4, tutti i motivi connessi | 52,05% | 100% | 100% |

Coppie fisse: rosso/blu per la prima scacchiera, marrone/verde per la quarta;
le due orientazioni restano consentite. È una variante diagnostica, non una
modifica alla baseline. Non abbiamo calibrato parametri degli agenti sui seed
per ottenere questi risultati. Non esiste ancora un test su schemi inediti.

100% significa 2000/2000, non garanzia universale: intervallo Wilson 95% circa
99,81–100%. Il confronto base è saturo: non permette di misurare un vantaggio
del pianificatore. La differenza di -0,25 punti nella variante a coppie fisse
non dimostra che pianificare sia dannoso.

## Diagnosi

Il solver conferma che bastano **10 piazzamenti** per soddisfare i primi tre
motivi, contro 16 disponibili. Il quarto non serve. Nella baseline l'opportunista
vince escludendo il quarto in 1922/2000 partite (96,1%); il pianificatore in
1900/2000 (95%). È una strategia empiricamente prevalente, non una dimostrazione
matematica di dominanza su ogni possibile lancio.

La baseline richiede in media appena 0,050 rilanci all'opportunista e 0,051 al
pianificatore. Ridurne la dotazione da quattro a tre non risolve il problema.
Nella variante connessa i due agenti restano al 100%, ma il pianificatore usa
0,152 rilanci contro 0,352: ottimizza una risorsa che non limita la vittoria.
Connettere i motivi riduce soprattutto il successo del casuale, non elimina la
strategia facile per un agente informato.

Nessuna posizione finale generata dagli agenti è risultata cromaticamente
irrecuperabile con risorse illimitate. Le sconfitte sono quindi scadenze, non
contraddizioni permanenti nel campione. Le politiche sono conservative: questo
non significa che le regole impediscano errori fatali.

Esempi verificati dai test:
- Due colori uguali adiacenti nella prima scacchiera la compromettono.
- Ripetere rosso in (2,2) e (3,2) compromette il quartetto centrale, ma si può
  ancora vincere con gli altri tre motivi.
- Aggiungere blu sia in (1,3) sia in (1,4) compromette anche il secondo motivo:
  con due motivi persi la vittoria è impossibile, indipendentemente dai lanci.
- Dalla griglia vuota, nove piazzamenti non bastano per vincere.

## Correzione consigliata, non ancora implementata

Non integrare ancora questo bilanciamento nell'interfaccia. Conservare otto
turni, due piazzamenti e quattro rilanci per isolare la variabile importante:
la struttura delle richieste cromatiche.

Prossimo esperimento: schemi connessi in cui ogni terna richieda 12 caselle
distinte, quartetti con una quaterna di pigmenti richiesta (per esempio
rosso/blu/giallo/verde), e sovrapposizioni che costringano a scegliere quale
motivo sacrificare. Il solver deve prima confermare almeno una terna risolvibile.
I quattro obiettivi potrebbero essere incompatibili congiuntamente: è accettabile
solo se le alternative di tre sono chiare e più di una è realizzabile.

Le quaterne richieste sono una proposta più restrittiva, non un risultato già
misurato. Non aggiungere contemporaneamente macchie, inventari o altri sistemi.
Prima del nuovo confronto, estendere il pianificatore ai lanci del turno
successivo campionati e alla scelta dei sottoinsiemi di rilancio. Valutare su
schemi e seed non usati nello sviluppo. Un eventuale aumento di difficoltà da
solo non è successo: cercare un vantaggio stabile della pianificazione e
diverse strategie vincenti, poi provarlo con giocatori umani.

## Collegamento futuro ai dadi 3D

Punti di aggancio verificati in produzione:
- `Actions.requestRoll` inoltra `onRollRequest(max_dice, roll_indices)`.
- `Actions.onDiceSettled` riceve risultati con `value`, `kind`, `sides`, `index`.
- `EngineBridge.pickTrayDie` restituisce l'indice del dado fisico selezionato.
- `dice_roll_schema.lua` configura attualmente 4 D6 e 3 D8.

Creare un adapter del solo esperimento: `value` della faccia diventa un indice
tecnico verso rosso/blu/giallo/verde/marrone/nero. Alla logica passa solo la stringa
pigmento e l'identità del dado. Non usare la tavolozza D8 né il selettore libero
del colore del gameplay attuale. Usare una configurazione di sessione con soli
quattro D6, senza cambiare lo schema globale della modalità esistente.

Per la modalità fisica, separare richiesta di lancio e accettazione del risultato:
le attuali `roll`/`reroll` headless producono casualità immediatamente, mentre
l'adapter dovrà addebitare un solo gettone alla richiesta e aspettare il callback.
Un ID di richiesta impedirà doppi callback. Non generare un secondo pigmento
casuale dopo che il dado fisico si è fermato. Gli indici scelti per un rilancio
parziale passano al bridge esistente; il picking usa gli stessi indici.

Le facce 3D dovranno mostrare i pigmenti mediante materiali/texture associati
agli stessi ID delle normali di faccia. Mesh, collisioni, gravità, impulso e
calcolo della faccia superiore restano invariati. Verificare in seguito tutti
i sei orientamenti, il picking dopo resize e i callback dei rilanci parziali.
Nulla di questa integrazione è stato effettuato nel presente esperimento.

## Verifiche eseguite

`test.lua`: scacchiere, quartetti, pigmento ottenuto, permanenza, due piazzamenti,
budget globale, passaggio di turno, sconfitta, vittoria, richieste invalide senza
addebito, solver, casualità diagnostica e invarianti dei tre agenti: PASS.
Suite preesistente: 12/12 file PASS. Simulazioni: 30.000 partite completate.
