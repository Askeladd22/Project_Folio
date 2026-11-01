# Presa, trascinamento e scuotimento — confronto con Tabletop Simulator

## Evidenza e limiti della fonte

Il file [TTS_DLL_MECHANICS_STUDY.md](TTS_DLL_MECHANICS_STUDY.md)
contiene i risultati del precedente esame statico, datato
31 ottobre 2026, dell'assembly Mono `Assembly-CSharp.dll`
fornito dall'utente (SHA-256:
`f34f48a2f9f450b15fedc71357b745a4972344496cd20dfe1062aef4ab6f936c`).
In questo intervento vengono **riletti i risultati archiviati**,
non rieseguita la decompilazione della DLL. L'adattamento è originale;
non copia codice proprietario di Tabletop Simulator.

### Pipeline verificata nel rapporto TTS

1. `ManagerPhysicsObject.ClientGrab`: registra gli oggetti fisici
   presi dal puntatore e relativi offset.
2. `ManagerPhysicsObject.UpdateGrabbedNPO`: determina le pose volute
   e guida i Rigidbody con `AddForce` e `AddTorque`.
   La forza posizionale **non equivale** a imporre una velocità
   angolare direttamente da ogni spostamento orizzontale del mouse.
   La coppia serve per il controllo di orientamento.
3. `ShakeDetector.FixedUpdate`: osserva l'errore
   `hand_position - rigidbody_position` e il prodotto scalare
   con la velocità del corpo. Incrementa gli eventi su un
   intervallo di circa un secondo e confronta una soglia
   configurabile.
4. `Pointer.Shake`: distingue dadi e monete da mazzi e sacchetti.
5. `ManagerPhysicsObject.ClientRelease`: torna alla normale
   simulazione fisica, con trattamento specifico di velocità,
   rotazione e damping per dadi/monete.
6. `ManagerPhysicsObject.Randomize` e `Pointer.Flick` sono
   **percorsi separati** dal semplice trascinamento.

I valori del motore Unity non sono trasferibili 1:1 al solver
LÖVE del progetto. Il rapporto non dimostra che il gioco
originale abbia una particolare impostazione utente attiva.

## Diagnosi nel codice di Project Folio 0.1.0-dev.19

Il difetto è una doppia attribuzione di responsabilità:

- `group_throw.lua:G.move` invoca `Single.track` **per ogni dado**
  selezionato e guida le posizioni dei corpi mediante la molla.
- `mouse_throw.lua:T.track`, su ogni movimento del mouse, imposta
  `g.angular` a partire da `dx/dt` e `dy/dt`, identici
  per ciascun dado del gruppo.
- `mouse_throw.lua:T.tick` trasferisce poi quegli stessi valori
  a `body.angular` e ruota realmente i vertici del dado.
- Parallelamente `group_shaker.lua` riconosce inversioni rapide,
  applica impulsi differenziati e usa i contatti nella fase
  di presa. L'imposizione della rotazione da trascinamento
  ne ostacola la percezione e può sovrascriverne il risultato.
- Inoltre `Single.begin` inizializzava `angular={2,1.4,.6}`,
  dando una rotazione spontanea persino alla presa ferma.

Il problema è dunque in primo luogo il **coupling degli input**
tra traslazione e rotazione, non una mancata attivazione del rilevatore
di shake né un errore di facce/punteggio.

## Correzione 0.1.0-dev.20

- I gesti dei dadi in **presa multipla** sono marcati con
  `group_hold=true` e partono con velocità angolare nulla.
- `Single.track` continua a registrare puntatore e inversioni
  per tutti i dadi, ma **non impone** loro la formula di rotazione
  `dx/dt` e `dy/dt` durante il trascinamento di gruppo.
- Lo shaker esistente rimane attivo e muove ogni corpo con
  impulsi/rotazioni differenziati quando sono riconosciute
  inversioni rapide della mano.
- In quiete lo spin del gruppo si attenua più velocemente;
  per il dado **singolo** si conservano interamente
  l'interazione e il damping precedenti.
- Nessuna modifica a Farkle, G3D, contatti del lancio,
  RNG di gameplay, conteggio dei lanci o salvataggi.

Questa correzione **non replica integralmente il detector TTS**,
che valuta anche la velocità rispetto al target mano-corpo;
è una separazione controllata delle responsabilità per risolvere
la rotazione indebita osservata dall'utente. Una futura
sperimentazione del detector basato su ritardo dei Rigidbody
richiede test dinamici, non un semplice cambio di soglie.

## Gate

`tests/group_grip_drag_spin_decoupling_test.lua` prova prese
da due a sei dadi: trascinamento unidirezionale senza rotazione,
scuotimento con rotazione individuale, smorzamento a riposo
e presa singola invariata. Si devono inoltre conservare i
test esistenti `tabletop_shake_test.lua` e
`group_grip_shaker_test.lua`.

**Non equivalente a QA Windows:** il comportamento fisico e
l'aspetto visivo sono da osservare nuovamente in LÖVE con
movimento lento, continuo, inversioni rapide e rilascio.
