# Consolidamento dello spawn e congelamento del motore 3D

15 ottobre 2026. Promozione autorizzata del candidato della fase 8, senza nuova ottimizzazione fisica.

## Versione integrata

File di produzione modificati:

- `main.lua`: generazione originale delle proposte, validazione prima del primo passo, applicazione delle posizioni valide; correzione della sola componente orizzontale uscente quando il fallback cambia lato.
- `src/engine3d/spawn_clearance.lua` — nuovo: SAT dedicato allo spawn, margine 0,01, ordine di collocamento variabile, sottogeneratore locale, tentativi limitati e fallback controllato.
- `experiments/farkle_roguelite/manuscript-farkle.love` — ricostruito con il builder esistente.

I due sorgenti promossi coincidono byte per byte con quelli verificati della fase 8. Non sono state adottate le varianti Distribuito, Obliquo o Obliquo basso. Quattro regioni originali, altezze, spin e velocità originarie conservati, salvo l'inversione della componente uscente già approvata: il modulo della velocità rimane identico. Nessun risultato numerico imposto.

Il SAT opera soltanto alla generazione, non durante la risoluzione delle collisioni. Limiti: 32 tentativi sul lato originale, 96 sugli stessi quattro lati, scansione finita di 64 punti per lato; se falliscono, rollback dei corpi e recupero tecnico esplicito. I dadi accantonati non partecipano alla ricerca e non vengono riposizionati.

## Renderer e texture preservati

`face_texture.lua`, `geometry.lua` e il percorso per-dado in `experiments/farkle_roguelite/dice.lua` sono invariati. Rimangono due triangoli ancorati ai quattro vertici proiettati, UV esistenti e mapping base `{1,6,3,5,4,2}`. La faccia incisa continua a leggere la mappa individuale, senza ritorno alla vecchia closure condivisa.

Conservate anche le sei texture temporanee argentate: la promozione copia esclusivamente i due sorgenti dello spawn, non le risorse obsolete del candidato. Camera, proiezione e geometria non sono cambiate.

## Verifiche della promozione

Evidenze in `audits/engine3d/phase9/`:

| Verifica | Risultato |
| --- | --- |
| Suite generale | 17/17 file superati, `general.log` |
| Farkle, HUD e unità spawn | 3/3 file superati, `farkle-hud-spawn.log` |
| 11 seed con fallback noto + 8 normali + 20 consecutivi | 39/39 conclusi, zero overlap iniziali |
| Faccia accettata e valore comunicato nei 39 lanci | Zero esiti geometricamente invalidi accettati, zero discrepanze |
| Seed 54083 | Fallback verso l'interno verificato, `fallback/test.txt` |
| Rilanci parziali e completi | Subset 1; 2/4/6; 1–5; 1–6 superati, dadi esclusi invariati |
| Singolo dado pesato | Percorso di rilancio fisico verificato; regola di accettazione non modificata |
| Esaurimento spawn | Rollback atomico, punteggio invariato, retry riuscito |
| A/B | Posa ambigua rifiutata, recuperi limitati, errore tecnico e retry manuale corretti |
| Renderer, 5 pose controllate inclinate | Zero pixel texture fuori geometria, zero occlusioni errate nei campioni stabili |
| Lancio, selezione e rendering 1280×720 / 1920×1080 | Bounds validi, picking 6/6, selezione valida; screenshot durante movimento e all'arresto |

Questa è una verifica mirata, non una nuova campagna statistica. I risultati delle fasi precedenti restano disponibili; non si deduce uniformità dei dadi da questi 39 lanci. Le prove A/B e le pose inclinate usano esclusivamente harness diagnostici esterni.

Prima della promozione: `candidate/observations.txt`, CSV in `candidate/`, `partial/partial.txt`, `face-gate/observations.txt`, `renderer/renderer.txt`. Screenshot di lancio e arresto a entrambe le risoluzioni in `candidate/`; pose controllate in `renderer/`.

Verifica del pacchetto ricostruito: confronto di **tutte** le voci con il precedente. Unica voce esistente cambiata: `engine_main.lua`; unica aggiunta: `src/engine3d/spawn_clearance.lua`. Corrispondenza byte per byte verificata fra pacchetto e sorgenti, incluse fisica, renderer, mapping e sei PNG. Hash e risultato in `promotion.json`.

Smoke finale direttamente sul pacchetto promosso: `package-smoke/result.json` e `package-smoke/experiments/farkle_roguelite/hud-smoke.log`. Verifica lancio, selezione, accantonamento, rilancio e blocco input alle due risoluzioni; gli ulteriori stati HUD, inclusi hot dice, commissioni e potenziamenti, usano le fixture esistenti. Le regole hot dice sono inoltre coperte dalla suite Farkle e il rilancio di tutti i sei corpi dal test fisico completo.

## Checkpoint e ripristino

Backup verificato prima di qualsiasi modifica alla versione attiva: `audits/engine3d/phase9/before.zip`, con manifest SHA-256 `before.json`. Comprende sorgenti, texture correnti e pacchetto giocabile precedente. SHA-256 del backup:

`852911e4c8734ded70e16aa19d74fe4489932bcfa04dffe5f2e5e0ea286cd9db`

Per tornare immediatamente alla versione precedente, chiudere il gioco e avviare `audits/engine3d/phase9/Ripristina checkpoint.cmd`, oppure:

```powershell
rtk python audits/engine3d/phase9/rollback.py
```

Vengono ripristinati `main.lua` e il pacchetto precedente completo, incluse le nuove texture argentate. Il modulo aggiunto può rimanere sul disco, inutilizzato e assente dal pacchetto ripristinato. Il ripristino del pacchetto completo sovrascriverebbe eventuali cambiamenti futuri: questo checkpoint è quello immediatamente precedente alla presente promozione. Nessun backup delle fasi precedenti è stato eliminato.

## Limiti conosciuti e congelamento

Nei 39 lanci mirati rimangono **3 lanci con compenetrazione finale**: 1 nel gruppo fallback, 1 nei normali, 1 nella sequenza. Restano possibili intersezioni dado-dado e dado-vassoio dopo lo spawn. La posa inclinata diagnostica 3 contiene deliberatamente una penetrazione del bordo: la texture resta aderente, ma il renderer non rende valida quella posa fisica.

Nessun problema bloccante nuovo rilevato nelle verifiche eseguite. Questo non certifica una simulazione perfetta, l'assenza universale di compenetrazioni o l'imparzialità statistica del motore.

**Il motore 3D è congelato per lo sviluppo del gameplay.** `physics.lua`, risolutore, geometria, vassoio, contenimento, gravità, attrito, restituzione, inerzia, calendario D2 e sistema A/B sono rimasti invariati. Nessun SAT dinamico integrato. Farkle, commissioni e potenziamenti invariati.

Ulteriori interventi fisici richiederanno un bug riproducibile che comprometta concretamente la giocabilità e una nuova autorizzazione. Non sono previsti autonomamente SAT completo, ottimizzazioni generali, ridimensionamenti o esperimenti sulle traiettorie. Il prossimo lavoro riguarda le meccaniche roguelite.
