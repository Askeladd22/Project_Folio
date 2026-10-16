# L'arte del rischio — prototipo manuale isolato

Apri `arte-del-rischio.love` con LÖVE, oppure dalla cartella del progetto:

```powershell
rtk python scripts/run_risk.py
```

Il launcher ricostruisce il pacchetto e apre una finestra 1920×1080 ridimensionabile.
Non avviare app/main.lua direttamente: il pacchetto include il motore condiviso.
Identità LÖVE dedicata `scriptorium-arte-del-rischio`; nessuna partita viene salvata.
Il gioco originale e le sue modalità non sono modificati.

## Comandi

- Nuova A/B/C in basso a sinistra (anche tasti A/B/C): nuova partita, azzera i progressi.
- Progetto nel cartiglio sinistro: selezione, o cambio C quando consentito.
- Spazio / Lancia: primo lancio o rilancio dei dadi non trattenuti.
- Clic su un dado 3D o tasti 1–4: trattieni/libera. `[F]` indica trattenuto.
- Invio / Assicura: completa l'opera e applicala al folio.
- T / Tentazione: terzo rilancio, dopo i due ordinari, una volta per turno.
- N / Abbandona / Turno seguente: chiude un turno o passa al prossimo.
- Esc: chiude il prototipo.

Durante il moto i comandi di gioco sono bloccati. Se tutti i dadi sono trattenuti,
liberarne almeno uno prima di rilanciare. I nomi sotto i dadi consentono di distinguere
i pigmenti anche quando luce e ombre riducono il contrasto.

## Regole implementate

Otto turni. Quattro D6: rosso, blu, giallo, verde, marrone, nero.
Capolettera RR=3, fregio VVG=6, miniatura RBGN=10 (G=giallo).
Ogni dado eccedente di un pigmento della ricetta aggiunge 2 punti: massimi 7/8/10.
La miniatura richiede tutti i dadi e non ha finiture disponibili.

A: progetto vincolato prima del primo lancio. B: scelto dopo il primo lancio,
poi vincolato. C: scelto prima, un cambio dopo un lancio risolto, ricompensa -2.

Due rilanci ordinari. Da preparazione incompleta si consumano tentativi.
Da preparazione completa bisogna aumentare strettamente il valore lordo della
ricetta impegnata: altrimenti l'intera preparazione si perde e il turno termina.
Le opere già assicurate restano. Non si può cambiare progetto per recuperare
un rischio fallito. Il costo del cambio si applica solo all'opera completata.

Tentazione: un rilancio extra, costo immediato 1, poi 2, poi 3… punti per ogni
utilizzo nella partita, anche se fallisce. Il saldo può diventare negativo.
Vittoria: almeno 25 punti netti e almeno un'opera di ogni tipo dopo otto turni.

Le opere sul folio sono disegni procedurali sperimentali, non nuovi asset definitivi.
Non sono introdotte risorse, carte, modifiche delle facce o progressioni.

## Riproduzione dei controlli

```powershell
rtk python scripts/test_luajit.py
rtk python scripts/test_luajit.py experiments/arte_del_rischio/test.lua experiments/arte_del_rischio/analyse.lua
rtk python scripts/test_luajit.py experiments/arte_del_rischio/simulate.lua
rtk python experiments/arte_del_rischio/summarize.py
rtk python scripts/run_risk.py --smoke
```

Per ripetere soltanto i controlli dell'interfaccia senza il campione di 64 lanci:
`rtk python scripts/run_risk.py --quick-smoke`.

Il test grafico apre LÖVE, verifica A/B/C e resize, poi raccoglie 64 lanci fisici.
Può richiedere diversi minuti. Produce smoke.log, screenshot e physical-sample.csv.
Le simulazioni senza grafica producono results.csv e games.csv (54.000 partite).
Il modello Lua condiviso non contiene RNG: l'interfaccia usa le facce reali lette
dal motore, le simulazioni un generatore separato documentato nel rapporto.

## Limiti noti

Rischiare una ricetta completa è generalmente sfavorevole ai punti: le regole
sono state conservate per valutarle, non corrette automaticamente.
La scelta può cambiare vicino alla soglia finale di vittoria.

I dadi trattenuti vengono esclusi dall'elenco dei corpi attivi durante il lancio,
conservando posizione e orientamento visibili. Il solver fisico originale resta
inalterato; un dado attivo può sovrapporsi visivamente a uno trattenuto. I tasti
1–4 restano un'alternativa al picking in caso di sovrapposizione.

Leggere REPORT.md prima di interpretare una percentuale di vittoria come prova
di bilanciamento o divertimento.
