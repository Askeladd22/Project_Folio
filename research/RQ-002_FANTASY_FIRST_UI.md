# RQ-002 — Fantasy-first come criterio per Project Folio

**Data:** 20 novembre 2026  
**Stato:** proposta R&D, non decisione canonica né feature implementata  
**Baseline di lettura:** `main@b315bf57f2c5e11608608baccca2b1f28342d556`  
**Fonti:** slide fornite dall'utente (20/11/2026); `docs/project_vision.md`, `docs/art_direction.md`, `docs/farkle_rules.md`; codice del Tavolo del Mercante alla baseline.

## Domanda falsificabile

Una promessa espressa in termini di desiderio e azioni del giocatore, anziché in termini di «Farkle roguelite», rende la partita più comprensibile e desiderabile **senza** trasformare i dadi in un'interfaccia che gioca al posto dell'utente?

## Contributo delle slide: che cosa trasferire

- **Fantasy prima della meccanica.** Descrivere cosa il giocatore desidera *sentirsi capace di fare*, non soltanto la categoria del prodotto.
- **Craving vs fantasy interna.** Distinguere l'idea del creatore dal motivo per cui il pubblico sceglie di giocare.
- **Borrow frameworks, not IP.** Estrarre chiarezza delle interazioni, struttura degli obiettivi e riduzione dell'attrito da casi comparativi; non copiare ambientazioni, regole integrali, interfacce o asset.
- Le slide menzionano Farming Simulator (interazioni leggibili con macchine), Armored Core 6 (struttura missioni e upgrade), PVKK (controlli tattili e complessità intuitiva). Sono **esempi presentati nelle slide**, non prove di compatibilità o successo per Folio.

## Fantasy candidate, non approvate

| Candidata | Promessa al giocatore | Interazione già presente | Rischio / elemento ancora assente |
|---|---|---|---|
| F1 — «La sorte nelle mie mani» | Tiro davvero i dadi, scelgo quali salvare e quando rischiare | sei D6 fisici, presa/lancio, selezione, incasso/Farkle | Se la fisica ruba attenzione al significato dei punti, la fantasy è solo gesto |
| F2 — «Le immagini mi sfidano» | Le xilografie dei libri prendono vita e diventano rivali con un proprio carattere | stanza e ritratto PNG, tavolo condiviso | Il Mercante non è ancora un avversario competitivo completo nel gioco principale |
| F3 — «Lascio il segno nel libro» | Le mie vittorie producono qualcosa di visibile e mio nella run | Folio consultabile, progressione per commissioni provvisorie | La ricomposizione delle xilografie è da progettare, non implementata |

**Sintesi candidata:** «In una Venezia sognata, le figure dei libri mi sfidano a un tavolo di dadi. Con le mie mani decido quanto rischiare; ogni vittoria potrebbe lasciare un segno sull'edizione che prende vita».

Questa frase è una **ipotesi di esperienza**, non autorizza un nuovo sistema di combattimento, valuta, carte, HP o trucchi nascosti sul RNG. Non attribuisce a Folio un duello già implementato.

## Risoluzione dell'utente: fantasy F1 scelta (20/11/2026)

Il giocatore vuole essere un **appassionato temerario del gioco di dadi**
(espresso dall'utente come «ludopatico giocatore di dadi») e tentare di
**battere l'alea attraverso il lancio e la manipolazione fisica**.
Questa è la direzione fantasy approvata per Project Folio:
**prendere, scuotere, ruotare e lanciare dadi reali nel motore, poi
decidere se rischiare o incassare**.

Non significa che il giocatore possieda già un metodo riproducibile per
indirizzare le facce. Il codice muove corpi reali, ma la dimensione della
skill expression *fisica* rispetto alla casualità resta **NON MISURATA**.
La manipolazione delle probabilità del dado speciale dichiarata dalle
regole non è una conseguenza garantita del gesto, né una facoltà
nascosta dell'interfaccia.

**Decisione UI autorizzata:** feedback leggibile per selezione
multipla con trascinamento sinistro, presa destra, gestualità scuotimento
riconosciuta, rilascio e stato del lancio manuale. Solo dati già presenti
nel controller/gestore fisico; nessun tasto o potere per imporre facce.

**Test successivo e falsificabile:** registrare condizioni iniziali,
input fisici, valori finali e bust con protocollo appaiato per più
tecniche di lancio. Confrontare distribuzioni e intervalli di
incertezza; il miglioramento percepito non prova un vantaggio
statistico, mentre una differenza statistica non prova automaticamente
che il controllo sia divertente o leggibile. Test umano distinto per
comprensione, destrezza e percezione di controllo.

## Prima frizione da rimuovere, senza cambiare gameplay

1. **Prima della scelta:** il giocatore vede quanti punti ha selezionato, quanti dadi restano e se può incassare.
2. **Durante la scelta:** il comando mostra quanto diventerebbe il totale a rischio o quanti punti diventerebbero sicuri.
3. **Dopo la scelta:** il feedback usa il risultato autorevole delle regole; mai un dado virtuale o una faccia decisa dall'HUD.

La PR UI associata a questa ricerca implementa solo il feedback `Accantona / Incassa` e la chiarezza dei relativi stati; **non** implementa F2 o F3.

## Obiezioni red-team

- Una bella scena rinascimentale non sostituisce una relazione strategica tra giocatore e Mercante.
- «Controllare la sorte» potrebbe suggerire dadi truccati o esiti deterministici: la promessa deve riguardare le **decisioni**, non l'esito del lancio.
- Copiare una struttura missione/upgrade senza una posta comprensibile potrebbe moltiplicare i sottosistemi e indebolire *Simplicity*.
- Materiali Steam, wishlists o conversioni **non sono stati misurati**: “marketable” resta una domanda, non un risultato.

## Gate successivo: prova a basso costo

**H0:** il nuovo feedback UI non migliora la previsione delle conseguenze rispetto all'interfaccia precedente.  
**H1:** giocatori nuovi distinguono più spesso e più rapidamente `Accantona` da `Incassa` e anticipano correttamente il risultato.

- Mostrare stati identici della stessa partita nelle due UI; ordine alternato, stessa distribuzione dei dadi e regole.
- Chiedere **prima del clic**: «Quanto perderesti con un Farkle? Quanti punti salveresti con Incassa? E quali dadi rilanceresti?».
- Registrare risposte corrette, tempo di risposta, azioni errate e motivazione; il campione pilota va dichiarato in anticipo e non autorizza conclusioni sulla popolazione.
- Playtest separato sulla fantasy: mostrare una descrizione con «Farkle roguelite» e una con la promessa esperienziale; raccogliere comprensione, aspettativa e discrepanza rispetto alla build effettiva, senza promuovere la frase solo per preferenza del team.
- **STOP** se le nuove etichette invadono il campo di lancio, producono numeri errati o indicano come incassabile una selezione non valida.
- Prima di promuovere F2/F3: definire e testare l'azione autonoma del Mercante e il contratto competitivo; nessun merge di laboratori in `src/` per inerzia.

## Decisione provvisoria

**Fantasy F1 approvata dal giocatore, conseguenze meccaniche ancora non dimostrate.** Conservare i tre pilastri e *mastery not accommodation*. Non modificare il Farkle per inseguire riferimenti commerciali prima dei test.
