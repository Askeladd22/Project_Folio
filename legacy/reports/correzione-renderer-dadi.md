# Correzione delle texture dei dadi e diagnosi del bordo

## Esito

**Corrette e integrate le texture che si staccavano dalla geometria.** Non modificati proiezione, camera, dimensioni, materiali, fisica, validazione A/B, Farkle o ordinamento generale del renderer.

**La compenetrazione fisica col bordo rimane:** riprodotta anche con un lancio reale, non soltanto con pose artificiali. Non viene mascherata tramite clipping o ridisegnando la cornice sopra tutti i dadi. Correggerla richiede un intervento sui contatti/contenimento, distinto da questa correzione grafica.

La posa esatta dell'immagine fornita non è recuperabile dal solo ritaglio: sono state riprodotte le stesse categorie di artefatto con pose note, senza attribuire al ritaglio coordinate fisiche inventate.

## Salvaguardia

[Backup verificato della versione precedente](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/before.zip), comprendente sorgenti e pacchetto giocabile. SHA-256: c11e3f67600f8c11de65d05accf52981c167847aeef87f7f16d4478498da9799.

Prima correzione nella copia separata audits/engine3d/phase6/workspace, poi promozione dopo test. [Manifesto della promozione](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/promotion.json).

## 1. Proiezione e trasformazione delle texture

[view.project / view.get](C:/Users/Davide/Desktop/manuscript-main/src/engine3d/view.lua) applicano yaw, pitch e divisione prospettica. Non è stata dimostrata una proiezione errata nelle pose provate; il confronto indipendente con raggi usa l'inversa di questa camera e concorda con la geometria disegnata.

Il problema dimostrato è a valle. La precedente immagine D6 utilizzava graphics_transform in [render.lua](C:/Users/Davide/Desktop/manuscript-main/src/engine3d/render.lua:31), costruita usando i vertici 1, 2 e 4. Il vertice 3 proiettato non partecipava alla trasformazione. In prospettiva una faccia quadrata proietta generalmente un quadrilatero che non è un parallelogramma: una sola trasformazione affine del rettangolo non può coincidere con tutti e quattro i vertici.

Inoltre l'helper scambia gli assi per il determinante negativo e limita la deformazione angolare. Non è necessario attribuire ogni pixel errato a una di queste limitazioni per dimostrare il disallineamento: nelle cinque pose, la distanza fra il quarto angolo generato dal vecchio helper e il vertice corretto è 22,00 / 27,58 / 30,61 / 23,75 / 29,88 pixel alla scala diagnostica 900. Non sono errori misurati in pixel del normale HUD.

**Correzione:** [face_texture.draw](C:/Users/Davide/Desktop/manuscript-main/src/engine3d/face_texture.lua) disegna due triangoli 2D con gli stessi quattro vertici proiettati della faccia e coordinate UV esplicite. La superficie coperta coincide con quella geometrica. Una mesh 2D condivisa viene riutilizzata; non sono introdotti shader, camera GPU o un nuovo motore 3D. Il progetto utilizzava già questo tipo di primitive per D8 e vassoio.

L'interpolazione UV è affine per triangolo: **non è una mappatura prospettica esatta per ogni texel**. Rimane una possibile deformazione interna del motivo, specialmente a forte inclinazione, ma non il precedente rettangolo che oltrepassa la faccia. Nessuna pretesa di aver corretto tutte le approssimazioni prospettiche del motore.

Il vecchio helper generico resta disponibile agli altri utilizzatori; i due percorsi D6 interessati non lo chiamano più.

## 2. Texture fuori dai poligoni

Riproduzione con cinque pose note, disegno su Canvas trasparente e confronto con una maschera geometrica senza texture. Si contano pixel opachi della texture oltre la sagoma, escludendo una fascia di un pixel per la rasterizzazione.

| Posa | Pixel fuori sagoma prima | Dopo |
|---|---:|---:|
| 1, cubo inclinato al centro | 1233 | 0 |
| 2, vicino al bordo ma interno | 11 | 0 |
| 3, volontariamente intersecante il bordo | 23 | 0 |
| 4, inclinato lateralmente | 0 | 0 |
| 5, lato posteriore | 8 | 0 |

La misura usa la sagoma complessiva del dado; la corrispondenza ai singoli poligoni deriva anche dai vertici espliciti delle due primitive. Zero pixel rilevati non significa assenza di qualsiasi possibile artefatto su tutte le pose.

Il test è stato eseguito prima della modifica con asserzione attiva: fallimento atteso, “Texture escaped geometric silhouette”. Dopo la modifica e dopo la promozione: superato.

[Confronto ingrandito prima/dopo](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/texture-prima-dopo.png)

## 3. Backface culling e profondità

[render.die](C:/Users/Davide/Desktop/manuscript-main/src/engine3d/render.lua:367) ricava la normale dai vertici, la orienta verso l'esterno e verifica il prodotto scalare con il vettore verso la camera. Le pose controllate mostrano 2 o 3 facce visibili coerenti. La correzione non cambia questo percorso.

render.zbuffer/paint è un ordinamento del pittore, non un depth buffer per pixel: i dadi usano la profondità media di faccia, alcune primitive del bordo la minima. Questa è una limitazione strutturale, ma non basta da sola a dimostrare che causi il difetto allegato.

Verifica indipendente: dado uniforme bianco, bordo opaco, niente texture; raggi camera intersecati con cubo orientato e quattro volumi del bordo. Confrontati i pixel lontani almeno due pixel dalle transizioni, su una griglia ogni tre pixel. Cinque pose: vicino al bordo anteriore senza penetrarlo, inclinato all'interno, in aria sopra il bordo, vicino al lato destro e vicino al retro.

| Posa di profondità | Campioni confrontati | Occlusioni discordanti |
|---|---:|---:|
| 1 | 52410 | 0 |
| 2 | 52344 | 0 |
| 3 | 52329 | 0 |
| 4 | 52406 | 0 |
| 5 | 52507 | 0 |

Totale 261996 campioni per versione. Esito uguale prima/dopo. **Nessuna correzione del culling o dell'ordinamento giustificata da questi casi.** Non è una prova universale per tutte le intersezioni o sovrapposizioni possibili. Anche i raggi riguardano un cubo e i bordi, non ogni configurazione di sei cubi intrecciati.

## 4. Occlusione del bordo e contorni senza texture

Nelle schermate controllate, la fila posteriore è interna; quella anteriore è intenzionalmente collocata attraverso il bordo. Senza texture vengono disegnate facce solide e contorni verdi sugli esatti poligoni proiettati. La porzione che invade la cornice resta visibile anche in questa modalità: non è soltanto una linea della texture proiettata fuori posto.

Le immagini senza texture a 1280×720 e 1920×1080 sono **identiche byte per byte prima/dopo**. Questo conferma che la modifica non ha spostato geometria o cambiato l'ordinamento.

[Contorni geometrici, 1280](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/before/1280-controlled-wire.png) · [Prima con texture](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/before/1280-controlled-texture.png) · [Dopo con texture](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/active/1280-controlled-texture.png)

[Contorni geometrici, 1920](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/before/1920-controlled-wire.png) · [Dopo con texture](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/active/1920-controlled-texture.png)

Non è stato aggiunto un taglio della sagoma al contorno 2D del vassoio: un dado in aria può legittimamente proiettarsi sopra la cornice. Un simile taglio nasconderebbe anche parti che dovrebbero restare visibili.

## 5. Compenetrazione fisica reale

La posa controllata 3 raggiunge y=3,65573 contro il piano interno anteriore y=3,05: penetrazione intenzionale di 0,60573. Serve a distinguere i fenomeni, non viene presentata come frequenza naturale.

Verificato anche un lancio vero, sei dadi, seed 54001, condizioni iniziali originali, aggiornamento 60 Hz. Accettato dopo 298 aggiornamenti, fase ready. Il dado 2 termina con:

- centro x=3,603167; y=2,674744; z=0,578276;
- massimo superamento anteriore: **0,288889**;
- superamento con vertici nella fascia z=0…0,74 del bordo: **0,288214**.

Quindi si tratta di intersezione con il volume del bordo, non soltanto di proiezione di un corpo alto sopra la cornice. Pose finali e tempi coincidono esattamente prima/dopo la correzione grafica.

Causa coerente con il codice: [constrain_dice_to_regions](C:/Users/Davide/Desktop/manuscript-main/main.lua:394) limita il centro usando circa metà del raggio sferico, non l'ingombro orientato dei vertici. Il box fisico usa inoltre semiampiezza y=3,4, mentre il lato interno visibile è a y=3,05. Questi vincoli possono accettare un centro lasciando parte del cubo nel bordo. Nella direzione laterale esistono inoltre differenze fra regione di contenimento e rettangolo usato per disegnare il bordo.

**Non corretto qui:** intervenire sui contatti o sul margine cambierebbe la fisica e le traiettorie. Una correzione soltanto grafica che nascondesse l'intersezione non risolverebbe la causa. Restano le conclusioni degli audit fisici precedenti, senza promuovere un nuovo solver.

[Lancio reale prima, 1920](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/before/1920-natural.png) · [Dopo, stessa posa](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/active/1920-natural.png)

## File e verifiche

File funzionali modificati:

- [src/engine3d/face_texture.lua](C:/Users/Davide/Desktop/manuscript-main/src/engine3d/face_texture.lua): nuovo helper locale di mappatura.
- [src/engine3d/geometry.lua](C:/Users/Davide/Desktop/manuscript-main/src/engine3d/geometry.lua): percorso D6 condiviso usa quattro vertici.
- [experiments/farkle_roguelite/dice.lua](C:/Users/Davide/Desktop/manuscript-main/experiments/farkle_roguelite/dice.lua): stesso helper per le facce individuali della build.
- Pacchetto manuscript-farkle.love ricostruito tramite il launcher esistente.

Physics.lua, main.lua, view.lua, render.lua, geometria fisica, materiali e schemi dimensionali invariati. Il disegno dei contorni è confinato all'harness diagnostico.

Verifiche superate: suite 17/17; Farkle/HUD 2/2; test grafico RED→GREEN; confronto con raggi; identità delle schermate geometriche; identità del lancio naturale. Smoke HUD completo a entrambe le risoluzioni: lancio fisico, selezione e picking, accantonamento, rilancio, Farkle, incasso, hot dice, commissioni, build e medaglie. Gli stati rari dello smoke sono preparati dall'harness; non tutti derivano da una run casuale completa.

[Log renderer prima](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/before/renderer.txt) · [Log versione attiva](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/active/renderer.txt) · [Log smoke](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/smoke-after/experiments/farkle_roguelite/hud-smoke.log)

Riproduzione dalla root: rtk python audits/engine3d/phase6/run.py verifica --active --assert. Le pose e i raggi sono definiti in [harness.lua](C:/Users/Davide/Desktop/manuscript-main/audits/engine3d/phase6/harness.lua). Il test non modifica i sorgenti o lo stato fisico del gioco attivo: lavora in un pacchetto diagnostico separato.

Non sono state eseguite nuove simulazioni massive o affermate ottimizzazioni CPU. La correzione dimostrata riguarda l'aderenza delle texture, non l'eliminazione di ogni limite del renderer o della fisica.
