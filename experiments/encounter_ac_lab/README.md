# Project Folio — Encounter Research A/C

**Due prototipi giocabili isolati**, non integrati nel gioco principale.
Sono adattamenti ORIGINALI di principi: la divisione con scelta del rivale
(Hanamikoji) e gli obiettivi contesi (Schotten Totten / Biblios). Non
riproducono il regolamento completo di alcun board game.

## Contratto comune

- L'Incisore usa il **Farkle canonico con 6 D6**, importato da
  src/farkle/rules.lua: stessa valutazione delle combinazioni, stessa
  selezione/accantonamento, stesso Farkle e stessa regola hot dice.
- Il Rivale **non lancia dadi** e non cerca un totale Farkle. La risposta
  viene da una strategia pubblica, ripetibile, senza informazioni segrete.
- La posta provvisoria del turno Farkle si traduce, SOLO nel laboratorio,
  in sigilli spendibili sulle tre prove: Capilettera, Miniatura e Marca tipografica.
  I sigilli non sono monete né danno: la conversione è un'ipotesi.
- Non ci sono salute, economia, progressione della run o build. Il laboratorio
  usa grafica 2D semplificata; il rendering g3d di produzione resta intatto.

## A — Offerte e contromosse

**Cinque prove**, una possibilità di incasso Farkle per prova.
I punti INCASSATI generano un'offerta da dividere fra due prove diverse:

| Punti Farkle incassati | Sigilli da dividere |
| --- | --- |
| Meno di 50 | 2 |
| Da 50 a 99 | 3 |
| Da 100 a 149 | 4 |
| Almeno 150 | 5 |

Il giocatore sceglie una coppia fra le tre possibili e distribuisce
almeno un sigillo per parte. Il Rivale sceglie per sé una delle due
offerte, considerando quantità, valori fissi e situazione pubblica
della partita; all'Incisore va l'altra **con 1 sigillo fisso di iniziativa**
per aver rinunciato alla prima scelta. L'interfaccia mostra in anticipo
quale offerta il rivale sceglierebbe, così la scelta rimane leggibile. **La scelta del rivale ha una
conseguenza, non è una risposta casuale di punteggio.**

Se esce Farkle, il Rivale avanza di un sigillo su una categoria.
Dopo cinque prove ogni categoria con più sigilli appartiene al
contendente corrispondente; una categoria in parità rimane neutrale.
Vince chi controlla più categorie. Possibile pareggio.

**Da verificare:** equilibrio fra offerte, scelte dominanti, utilità
delle tre coppie, frequenza di vere decisioni rispetto alla fortuna.

## C — Prove contese

**Sei prove**, tre categorie contese. Il primo a ottenere **4 sigilli**
in una categoria la sigilla definitivamente; 2 categorie sigillate
assegnano subito la vittoria.

| Punti Farkle incassati | Sigilli investibili |
| --- | --- |
| Meno di 40 | 1 |
| Da 40 a 89 | 2 |
| Almeno 90 | 3 |

Il giocatore sceglie UNA categoria disponibile. Il Rivale risponde
con 1 sigillo per prova, 2 ogni terza prova, secondo una priorità
pubblica basata sul suo avanzamento e sulla minaccia del giocatore.
Il Rivale avanza anche se il giocatore ha fatto Farkle.
Alla sesta prova, se nessuno ha già sigillato 2 categorie,
la maggioranza dei sigilli decide il controllo di quelle incomplete.
Anche qui può esserci un pareggio.

**Da verificare:** rischio di una strategia dominante, eccessiva
prevedibilità del Rivale e incentivi a rischiare dopo un incasso valido.

## Avvio

Con LÖVE 11.x su Windows dalla root del repository:

    experiments\encounter_ac_lab\run_lab.cmd
    experiments\encounter_ac_lab\run_lab.cmd --mode C --seed 101

Oppure, con LÖVE nel PATH:

    love experiments/encounter_ac_lab --mode A --seed 101

**Comandi:** M cambia esperimento; R ricomincia allo stesso seed;
SPAZIO tira o rilancia; 1–6/clic seleziona dadi; A accantona;
I incassa; in A TAB cambia coppia, frecce sinistra/destra
modificano la divisione e INVIO conferma l'offerta; in C
Z/X/C oppure i pulsanti scelgono le tre prove; INVIO passa
alla prova successiva.

## Test numerici

Da root:

    lua5.4 tests/labs/encounter_ac_test.lua
    luajit tests/labs/encounter_ac_test.lua
    lua5.4 tests/labs/encounter_ac_ui_test.lua
    lua5.4 -e "print(require('experiments.encounter_ac_lab.simulate').report(60,101))"

Le policy prudent, balanced e daring condividono gli stessi seed fra
A e C. Non sono giocatori umani né rappresentano strategie ottime.
Verificare determinismo, vittorie/pareggi, numero di Farkle e
decisioni dominanti: **la percentuale di vittorie non basta**.
Non fondere nel gioco principale senza playtest e valutazione della
qualità delle scelte. Nessun conflitto intenzionale con Merchant Wager V4.
