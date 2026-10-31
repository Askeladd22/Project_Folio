> **v0.1.0-dev.7:** la UI 2.0 è l'unica UI di
> gioco e la pagina del Monaco si colloca ora
> sotto il pannello di resoconto, non dietro di esso.
> Il contrasto, il ritmo delle animazioni e l'allineamento
> a 720p/1080p richiedono verifica grafica Windows.
>
# Project Folio — Lovely Toasts e sfida sperimentale al Monaco

31 ottobre 2026. Funzioni implementate come test giocabile isolato dalla
campagna standard. Nessuna modifica ai dati del Farkle, alla fisica dei
dadi o al rendering del tray g3d.

## Avvio

Dal menu principale scegliere **Sfida il Monaco (beta)**.
Non sono richieste variabili d'ambiente. Il normale **New Game** continua
ad aprire la campagna corrente, senza avversario.

- Il giocatore usa **i sei D6 fisici in 3D** e gli stessi controlli del
  gioco originale. Può accantonare, rilanciare e incassare.
- Il **Monaco è una miniatura 2D**, animata con anim8/Flux. La figura è
  un **placeholder originale procedurale**, non grafica definitiva.
- Il Monaco usa uno stato Farkle separato (Rules.new) e tiri virtuali di
  sei D6 equi, con generatore pseudocasuale indipendente da quello della
  fisica. **Non è un filmato/roll truccato né un corpo 3D.** I risultati
  sono calcolati con `rules.lua` e `scoring.lua`, con identiche
  combinazioni, accantonamento, penalità Farkle e minimi d'incasso.
- Il Monaco sceglie la combinazione valida col punteggio maggiore e,
  quando può incassare, decide di fermarsi in base a punti, dadi rimasti
  e numero di rilanci. Questa è **una politica di partenza da calibrare**,
  non un'intelligenza ottimale.
- Ogni turno del giocatore completato riceve una risposta del Monaco.
  La sfida usa **la prima commissione già prevista**: obiettivo 100
  punti, massimo quattro turni per parte. Raggiunto l'obiettivo
  (o terminati i turni), il punteggio maggiore vince. Una parità è
  esplicitata.
- A fine sfida **R** ricomincia, **Esc** ritorna al menu principale;
  si può anche cliccare sul pulsante di riprova nel pannello finale.

## Aggiornamento 0.1.0-dev.3 — Il monaco torna sul folio

Il bot presenta ora un **registro visivo dell'ultima mano**: punteggi
reali del giocatore e del monaco, mano corrente, obiettivo, numero
e facce dell'ultimo tiro virtuale (un trattino significa che quel
dado non è stato rilanciato), più esito di incasso/Farkle.
Il registro non può modificare i punteggi del `rules.lua`.

Il monaco nasce nel margine del folio e si porta in primo piano
con una transizione **esclusivamente 2D**. Quando il confronto
termina con una vittoria del giocatore, `miniature_2d.lua`
riporta la figura alla sua miniatura, riducendone le dimensioni.
In caso di parità o di vittoria del monaco non viene simulato un
ritorno che suggerirebbe un incontro vinto. `R` o il pulsante
Riprova ripristinano figura e resoconto senza lasciare animazioni
del duello precedente.

Chi usa **animazioni ridotte** vede l'ingresso e il ritorno
immediati, anche se l'opzione è attivata durante una transizione
già in corso. Le coordinate sono vincolate al folio della UI
1920×1080; **nessun oggetto 3D** nuovo e nessun click sui dadi.
La grafica del monaco resta un placeholder da sostituire in una
successiva fase di direzione artistica.

Verifica automatica: `tests/bot_duel_presentation_test.lua` e
`tests/miniature_2d_libraries_test.lua`; da provare graficamente
in LÖVE a 720p e 1080p con la UI precedente e la UI 2.0.

## Lovely Toasts: glosse, non finestre modali

Originale MIT [Loucee/Lovely-Toasts](https://github.com/Loucee/Lovely-Toasts)
copiato invariato in `lib/lovelyToasts.lua` e licenza completa in
`third_party/LICENSE_lovely_toasts`. `toast_messages.lua` è il nostro
adattatore: lazy load, palette da manoscritto, dimensioni virtuali
1920×1080, singolo messaggio, animazioni ridotte e mai intercettazione
del mouse. Posizione sopra il tray e lateralmente spostata verso la
zona del folio. Le glosse sono disattivate in presenza di modali o
schermate di ricompensa. Il gameplay non si blocca quando compaiono.

Le glosse sono abilitate nella sfida al Monaco e nella UI v2
sperimentale (feedback incasso e Farkle), non nel normale HUD legacy.
Il laboratorio originale `experiments/miniature_2d_lab/Avvia.cmd`
usa ora i toast al ritorno/uscita della miniatura.

## Vincolo di design

**Questo Farkle contro Farkle è una modalità beta tecnica**, separata
dalla direzione ancora da sperimentare di **avversari asimmetrici e
Segni** in [INCONTRI_E_SEGNI.md](INCONTRI_E_SEGNI.md).
Non si trasformano automaticamente la campagna, gli incontri e la
run in modalità versus. Non sono stati introdotti punti vita, attacchi,
una valuta parallela, nuovi dadi o bonus non documentati.

## Gate di qualità

I test `tests/farkle_bot_duel_test.lua` e
`tests/lovely_toasts_adapter_test.lua` devono superare Lua 5.4 e
LuaJIT insieme ai test esistenti. La CI **non verifica**
l'aspetto del Monaco, la dimensione delle glosse, la sovrapposizione
sul folio o il funzionamento effettivo degli shader g3d.
Prima di promuovere la modalità, fare QA Windows LÖVE a 1280×720 e
1920×1080, provando normale campagna, cambi UI con F6, Farkle
automatico, lancio manuale, Esc, click Riprovare e modalità
animazioni ridotte.
