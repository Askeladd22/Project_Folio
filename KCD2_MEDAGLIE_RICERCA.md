# Medaglie: riferimento sperimentale KCD2

Ricerca del 15 ottobre 2026. Inventario comparativo, non certificazione ottenuta giocando direttamente a KCD2. Nessun sorgente, asset o testo descrittivo proprietario è stato importato. Le descrizioni seguenti sono sintesi originali. I nomi originali servono esclusivamente alla ricerca; l'interfaccia usa nomi funzionali.

## Fonti e attendibilità

- **F**: [Fandom, Dice KCD2](https://kingdom-come-deliverance.fandom.com/wiki/Dice_(KCD2)), catalogo comunitario.
- **I**: [INARA, dadi e medaglie](https://inara.cz/kingdom-come-2/items-dice/), database non ufficiale con esplicito avviso di possibili inesattezze.
- **G**: [GamerGuides, Badges](https://www.gamerguides.com/kingdom-come-deliverance-ii/database/other/badges), descrizioni e identificatori degli oggetti, non specifica eseguibile.
- **V**: [GuideVault, inventario 32 medaglie](https://guidevault.online/kcd2/extras/dice-badges), consultato anche tramite indicizzazione testuale: il caricamento iniziale restituiva solo l'involucro, la ricerca ha poi restituito le famiglie e le descrizioni. La verifica nel browser non è riuscita. Non verificati i contenuti interattivi.
- **E**: [Escapist, tutte le medaglie](https://www.escapistmagazine.com/how-to-get-all-badges-in-kingdom-come-deliverance-2/), riscontro secondario dei livelli e utilizzi.
- **B**: [Escapist, confronto medaglie](https://www.escapistmagazine.com/best-badges-in-kingdom-come-deliverance-2/), descrive Resurrection come ripetizione del tiro fallito e Fortune come rilancio selettivo.
- **O1**: [osservazioni su attivazione e fine turno](https://www.reddit.com/r/kingdomcome/comments/1l3u7py/); **O2**: [prove descritte su Doppelganger](https://www.reddit.com/r/kingdomcome/comments/1inc4fb). Testimonianze di giocatori, non nostre riproduzioni controllate.
- **T**: [INARA Tyche](https://inara.cz/kingdom-come-2/item/5034/), effetto e appartenenza al DLC Legacy of the Forge.
- **J**: [GamesRadar, prova dell'aggiornamento 1.5.6](https://www.gamesradar.com/games/action-rpg/kingdom-come-deliverance-2-adds-balatros-jimbo-in-a-surprise-new-quest-with-a-huge-addition-to-the-rpgs-best-minigame/), osservazione diretta dell'autore della ricompensa Balatro. [Supporto ufficiale PLAION](https://beta.support.plaion.com/en/games/kingdomcome2/) elenca la patch 1.5.6; non specifica tutte le semantiche delle medaglie.
- Modding consultato: [Farkle Improved PTF, autore ModdingAt137](https://www.nexusmods.com/kingdomcomedeliverance2/mods/2830). È una modifica al gioco, non una prova del comportamento vanilla: non ne sono stati tradotti file o algoritmi. Non risolve le lacune sui trigger.

Concordanza di più cataloghi non equivale a prove indipendenti: possono ripetere la stessa descrizione. **Alta documentale** significa descrizione numerica concordante; **media** indica testimonianze o timing incompleto; **DA VERIFICARE** impedisce l'implementazione delle proprietà mancanti.

## Inventario e matrice di compatibilità

T/S/G = stagno/argento/oro. I livelli esplicitamente elencati sono distinti; nessun livello mancante viene creato per simmetria. Salvo diversa indicazione si tratta del gioco base. Una riga a tre livelli genera tre definizioni separate. I numeri dei bonus Headstart non vanno confusi con il prezzo degli oggetti.

| Famiglia / livelli | Effetto originale documentato | Utilizzi per partita | Fonte / certezza | Equivalente o blocco Manuscript |
|---|---|---|---|---|
| Fortune T/S/G | Rilancia rispettivamente fino a 1/2/3 dadi scelti dopo il tiro | 1 | F, G; alta sul limite, media sul timing | Rilancio fisico selettivo; finestra verificabile dopo tiro valido, prima del tiro successivo |
| Resurrection T/S/G | Ripete un tiro fallito | 1/2/3 | E, B; alta su numero, media su dettagli | SOSPESA: totale conservato e timing esatto da verificare |
| Might T/S/G | Aggiunge un dado al tiro | 1/2/3 | I, E; alta su numero | BLOCCATA: servirebbe una settima identità fisica; durata esatta del dado aggiunto DA VERIFICARE |
| Transmutation T/S/G | Trasforma un dado scelto in 3/5/1 | 1 | E; alta sul valore, media sul timing | SOSPESA: finestra post-Farkle, permanenza tra accantonamenti e resa temporanea della faccia da verificare insieme |
| Doppelganger T/S/G | Raddoppia l'ultimo tiro | 1/2/3 | F, V, O1/O2; media | SOSPESA: fine turno osservata; selezione vuota e ultimo tiro già accantonato hanno testimonianze anomale. T non compare in I/G |
| Warlord T/S/G | Bonus al turno +25%/+50%/+100% | 1 ciascuno | G, O1; media sul timing | G: incasso esplicito ×2. T/S sospese per arrotondamento non documentato sui piccoli punteggi Manuscript |
| Headstart T/S/G | Vantaggio iniziale crescente | automatico all'inizio | F, I; importo DA VERIFICARE | SOSPESE: nessun numero inventato |
| Defence T/S/G | Neutralizza la medaglia avversaria del livello corrispondente | passivo, durata partita | F, I; alta descrittiva | INCOMPATIBILE con solitario; nessun effetto sostitutivo |
| Swap-out/Exchange S | Rilancio di un dado scelto | 1 | G, E; alta descrittiva | Rilancio fisico; definizione distinta da Fortune |
| Swap-out/Exchange G | Rilancio di due dadi dello stesso valore | 1 | G, V; alta sul vincolo | Esattamente due identità distinte, valori uguali; nessun T documentato |
| Advantage Carpenter T | Nuova formazione 3+5, Cut | ripetibile | V; media | SOSPESA: punteggio e sovrapposizioni non sufficientemente verificati |
| Advantage Executioner S | Nuova formazione 4+5+6, Gallows | ripetibile | V; media | SOSPESA: stessa lacuna |
| Advantage Parish Priest G | Nuova formazione 1+3+5, Eye | ripetibile | V; fonti discordanti | SOSPESA: testimonianze di 500 punti originali, conversione non definita |
| Emperor G | Triplica la formazione di tre 1 | ripetibile | G; alta sul tris | SOSPESA: estensione a 4–6 uguali e interazione con doppio tris/full house da verificare. Tris semplice Manuscript sarebbe 75→225 |
| Bird King S | Un dado aggiuntivo, associato anche al nome Silver King | 2 | I, E; media | BLOCCATA come Might; V dichiara descrizione mancante |
| Wedding G | Rilancia fino a tre dadi scelti | 1 | E, V; alta descrittiva | Definizione distinta, stesso percorso fisico di Fortune G |
| Tyche G, DLC Legacy of the Forge | Raddoppia tre 6 | ripetibile secondo “sempre” | T; alta sul tris, media sui casi estesi | SOSPESA: tris Manuscript 60→120; gruppi estesi e combinazioni concorrenti DA VERIFICARE |
| Balatro T, aggiornamento 1.5.6 | Cambia il risultato del dado Balatro | 1 | J; media, osservazione pubblicata | BLOCCATA: dado speciale/jolly assente; dominio esatto e livelli ulteriori DA VERIFICARE |

L'inventario di riferimento comprende 34 definizioni (32 del catalogo V, più Tyche e Balatro T). Non è una prova che non esistano ulteriori medaglie in ogni versione futura. Presunti livelli Balatro superiori e “Gold Joker” non hanno evidenza sufficiente per una definizione implementabile.

## Trigger, durata, interazioni e limiti

**Fortune / Exchange / Wedding**: attivazione manuale dopo lettura fisica; scelta dei dadi separata dalla selezione a punti. La carica viene consumata una sola volta quando parte il rilancio. L'effetto termina con la nuova lettura; gli altri dadi conservano posizione, identità e valore. Non si rilanciano dadi già accantonati. In Manuscript il tiro corretto comprende anche i dadi rimasti sul tavolo: si rivaluta quell'insieme, non solamente il sottoinsieme rilanciato. Le combinazioni restano disgiunte secondo il regolamento corrente. Non si possono riciclare dadi già spesi. La possibilità originale di attivare questi effetti *dopo un bust già annunciato* non è accertata: in questa versione non è abilitata. È una limitazione esplicita della replica, non una regola KCD2 dichiarata verificata. Le finestre aggiuntive create dall'accantonamento parziale di Manuscript sono un adattamento locale dichiarato.

**Resurrection**: rilancio dopo tiro fallito e limiti 1/2/3 documentati. La conservazione esatta del totale e la finestra prima della cancellazione non sono sufficientemente provate: i tre livelli rimangono disabilitati. Il `retry` preesistente continua a funzionare, ma non viene presentato come replica verificata di Resurrection. Nessuna carica gameplay viene consumata dal recupero tecnico A/B. Serve una cattura KCD2 con totale prima/dopo.

**Warlord G**: O1 concorda sulla chiusura del turno. Anteprima del totale selezionato più provvisorio, verifica delle soglie Manuscript, accantonamento, raddoppio del totale del turno, incasso, verifica commissione. Gli incassi precedenti non raddoppiano. Nessun arrotondamento serve per ×2. Le soglie sono verificate sul valore ordinario: KCD2 non documenta un equivalente di queste specifiche soglie, quindi questa precedenza è un adattamento Manuscript, visibile e testato. Il bonus non crea un gruppo né hot dice che non si siano realmente verificati.

**Moltiplicatori sospesi**: non implementare un semplice ×3 su qualsiasi selezione contenente tre 1: moltiplicherebbe erroneamente singoli e altre formazioni. Occorre prima decidere con evidenza se i gruppi di 4–6 valgano come estensioni e quale partizione premiata prevalga. [Testimonianza Emperor/Tyche](https://www.reddit.com/r/kingdomcome/comments/1qfcyxy/kcd2_gold_emperors_badge_vs_gold_tyche_badge/) riferisce bonus anche oltre il tris; non basta per tutti i nuovi incastri Manuscript. [Testimonianza Eye](https://www.reddit.com/r/kingdomcome/comments/1s1v4jy/whats_your_dice_loadout_and_why_kcd2/) riporta 500 originali: non si può applicare automaticamente una conversione ×0,1, perché il nuovo regolamento non è una scala uniforme di KCD2.

**Transmutation sospesa**: il valore trasformato deve restare distinto da quello fisico. Prima di abilitarla occorre documentare il momento consentito e la durata, e aggiungere una presentazione temporanea esplicita che non modifichi la mappa permanente. Non viene simulata con un valore numerico diverso dalla faccia visibile.

**Equipaggiamento**: una sola medaglia. Una commissione equivale provvisoriamente a una partita: le cariche si ricaricano solo al cambio commissione. Il pannello di prova riavvia la commissione corrente, azzera punti/turni e conserva il dado personalizzato: selezionare una medaglia non ricarica gratuitamente una partita in corso. Nessun acquisto, premio economico o combinazione tra medaglie. Defence non ha bersaglio; non viene reinterpretata.

**Dadi pesati e incisi**: i rilanci usano il controller fisico attuale e il trattamento già esistente del dado pesato. Gli indici fisici rimangono gli stessi, anche quando due facce hanno lo stesso numero. I bonus non cambiano la probabilità di uscita. Hot dice ripristina sei dadi tramite il percorso originale; le cariche non si ripristinano.

## Divergenze e verifiche ancora necessarie

- V riporta per Priest una fonte alternativa che descrive un raddoppio del turno; F/I/G lo trattano come formazione. Non unificare con Warlord.
- [Dexerto](https://www.dexerto.com/gaming/dice-mini-game-in-kingdom-come-deliverance-2-explained-3059001/) riporta due utilizzi per Silver Warlord contro uno in G/F; prevale il riscontro dei cataloghi, ma la versione resta sospesa per l'arrotondamento.
- Tin Doppelganger presente in F/V, assente nei cataloghi I/G consultati: stato di esistenza da confermare per versione.
- Nessun confronto diretto nel KCD2 installato effettuato. Gli ID di inventario e i prezzi non provano trigger, bonus o durata.
- Test richiesti nel riferimento: bust con pot positivo e Resurrection; Fortune/Transmutation su bust; doppia attivazione e selezione vuota Doppelganger; Advantage con dadi sovrapposti fra formazioni; gruppi 4–6 per Emperor/Tyche; durata del dado Might; Headstart su tutti i livelli; eventuali regole introdotte da patch/DLC.

Questa versione offre un sottoinsieme utilizzabile e limiti dichiarati, non sostiene di aver completato una replica esatta dell'intero inventario.
