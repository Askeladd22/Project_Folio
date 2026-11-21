# Project Folio — direzione creativa aperta

**Decisione esplicita del 21 novembre 2026 (D-005).** Un solo vincolo di
identità rimane fisso: **sei un incisore nella Venezia rinascimentale**.
Tutto il resto della visione precedente è riapribile, compresi genere,
loop, Farkle, 6 D6, avversari, mercante/«Opponent», sogni, libri, premi,
progressione, tono e forma degli incontri. Aprire una possibilità **non**
significa averla approvata, né autorizza la sua implementazione implicita.

**Baseline tecnica:** `main@ac814220a721f2946914d5c4a1ac9e389f40a8f6`,
v0.1.103, usata come prototipo di confronto. Questa pagina riguarda la
**direzione possibile**, non descrive funzioni già esistenti: per il codice
effettivo leggere [README](../README.md), [architettura](technical.md),
[regole del prototipo](farkle_rules.md), commit e test.

## Cosa non cambiamo senza una nuova decisione esplicita

- **Chi:** artista/incisore originale, espresso attraverso il giocatore.
  Non deve impersonare un personaggio storico reale.
- **Dove/quando:** Venezia rinascimentale; stampa, botteghe, legno,
  inchiostro, matrici, torchi, incisione e rapporti sociali sono
  materiali d'ispirazione, non checklist obbligatorie di gameplay.

Tutto il resto è **aperto**. La collocazione precisa (fine Quattrocento /
primo Cinquecento), Aldo Manuzio, Dürer, protagonista muto, azzardo
serale, taverna, mondi-libro, sogno, commedia, orrore e competizioni
sono elementi delle versioni precedenti, ancora studiabili ma non
vincoli per una nuova proposta.

## La build giocabile è una baseline, non la nuova visione

| Elemento | Stato del software v0.1.103 | Stato di design da oggi |
|---|---|---|
| Dadi g3d, presa e lancio | Implementato | Disponibile come baseline, modificabile |
| Punteggi Farkle e sei D6 | Implementato | Una possibile meccanica, non vincolo creativo |
| Opponent Duel, primo a 500 | Implementato | Un possibile loop, non promessa finale |
| UI su pergamena e bottega illustrata | Implementato | Riferimento artistico reversibile |
| Libro, matrici e armadio | Idee non implementate | Esperimenti separati, non lore approvata |
| Trasformare persone in matrici | Brainstorming | Verificare tono, significato e reciprocità |

Non cancellare o riscrivere in automatico le regole testate per
inseguire una nuova fantasy. Il prototipo deve restare riproducibile
finché una proposta alternativa non supera la propria verifica.

## Tre fantasy concorrenti (nessuna approvata)

### A — Maestro del rischio
Un incisore affina la propria abilità ai dadi e impara a superare
rivali capaci di agire e vincere. **Promessa:** «vinco perché so giocare,
non perché il gioco mi favorisce». Rischio: l'incisione rimane soltanto
una cornice estetica; il gesto fisico potrebbe non dare vera agency.

### B — Maestro dell'impronta
Un incisore sfida individui e ottiene, perdendo o vincendo una posta,
il diritto di raffigurarli: matrici, stampe e catalogo di incontri.
**Promessa:** «le mie vittorie lasciano un'impronta visibile».
Rischio: collezionare immagini non cambia l'azione del giocatore.
La variante che trasforma davvero persone in matrici implicherebbe un
tono più oscuro e va valutata senza introdurre automaticamente
violenza, HP, catture o carte.

### C — Arte e inganno
Un incisore usa destrezza, osservazione, trucchi di bottega e
manipolazione materiale per inserirsi in conflitti veneziani.
**Promessa:** «supero situazioni sociali attraverso il mio mestiere».
Rischio: minigiochi scollegati; similitudine superficiale con Card Shark
non è prova di originalità o divertimento.

Queste direzioni possono anche essere scartate tutte. La domanda
centrale è **che cosa fa il giocatore ripetutamente, con quale scelta
e conseguenza, e perché dovrebbe scegliere Folio rispetto ad altri?**

## Criteri di valutazione (non ricette di implementazione)

1. **Simplicity:** profondità comprensibile senza sistemi duplicati.
2. **World Structure:** struttura dell'esperienza e payoff riconoscibili.
3. **Swelling Power:** opportunità crescenti se il genere lo richiede,
   non numeri gonfiati per tradizione roguelite.
4. **Mastery, not accommodation:** la bravura del giocatore deve contare,
   senza manipolazioni nascoste del caso o compensazioni segrete.
5. **Fantasy incarnata:** i gesti, le scelte, la posta e la conseguenza
   devono raccontare l'incisore; un guardaroba di trofei da solo non basta.

Non introdurre HP canonici, carte obbligatorie, progressione permanente
o trasformazioni irreversibili di persone senza una decisione motivata.

## Metodo: falsificare prima di espandere

**RQ-FANTASY-01:** quale fra A, B e C è compresa senza spiegare il
Farkle, e quale mantiene la promessa dopo una breve prova giocabile?

**Gate 1 — pitch cieco:** tre brevi descrizioni e materiali statici,
ordine alternato; chiedere ai partecipanti che cosa credono di fare
minuto per minuto e cosa desiderano conquistare.

**Gate 2 — prototipi di payoff:** confrontare almeno due varianti
nella stessa baseline: solo punteggio/vittoria versus matrice
xilografica consegnata e conservata dopo una vittoria. Nessuna nuova
meccanica finché il valore del payoff non è provato.

**Metriche proposte:** comprensione spontanea, intenzione motivata di
continuare, decisioni ricordate, discrepanze promessa/azione,
tempo necessario per comprendere la posta. La preferenza estetica
non dimostra divertimento. Numeri e risultati non ancora raccolti.

**Decisione:** scrivere un record in
[research/DECISIONS.md](../research/DECISIONS.md), mantenendo
i prototipi in `experiments/` e il gioco giocabile in `src/`.

## Provenienza

Il precedente testo canonico con tre pilastri vincolanti, il ludopatico,
il Folio e i mondi-libro è recuperabile integralmente in
[`project_vision.md` al commit v0.1.103](https://github.com/Askeladd22/Project_Folio/blob/ac814220a721f2946914d5c4a1ac9e389f40a8f6/docs/project_vision.md).
Le regole v0.1.103 restano codificate, testate e documentate
separatamente come baseline. Nessun esito di playtest è implicito
in questa revisione.
