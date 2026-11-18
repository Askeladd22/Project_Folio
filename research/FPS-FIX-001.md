# FPS-FIX-001 — Correzione degli urti fra D6 (PAUL / SEED)

**18 novembre 2026, PLAN → APPLY autorizzato dall'utente.**
**Baseline:** `main@6189aa860ab85b2f233c14f13723c5b927a3027b`
(`0.1.77`), rapporto precedente
`FPS_AUDIT_PAUL_SEED_2026-11-18.md` disponibile come allegato
conservato fuori dal repository.
**Branch separato:** `fix/dice-obb-ccd-angular-20261118`.
**Nessun merge senza nuovo assenso.**

## Ipotesi falsificabile

È possibile correggere le collisioni premature, il tunnelling
lineare e l'assenza di impulso angolare tra i sei D6 mantenendo
il solver Lua, la fisica degli urti con il tavolo e il rendering
g3d, senza importare l'intero FPS C 1.2.5?

## Task / acceptance criteria

**T1 — Geometria OBB SAT.** In
`src/engine3d/die_collision.lua`, usare tre assi dei dadi
e nove assi incrociati (SAT) su vertici ruotati reali; lasciare
`bounds.fps.footprint` per il solo contenimento del tavolo.
**AC-1:** a due D6 allineati con centri distanti 1.2 unità,
quando passa `dt=.01`, non si devono respingere; a distanza
0.83 la compenetrazione va ridotta.

**T2 — CCD lineare e contatto fuori centro.**
Memorizzare il centro di ciascun D6 all'inizio dello step
prima dell'integrazione; swept SAT fra posizioni precedenti
e nuove, anche quando le forme al termine sono disgiunte;
applicare impulso e attrito al punto di contatto usando
la già esistente `body:push(impulse,displacement)`.
**AC-2:** passaggio veloce con -1.5/+1.5 e velocità
+250/-250 non attraversa; impatto decentrato produce
momento angolare misurabile. Mantenere la semantica di
`on_contact` senza doppi eventi e il comportamento
`_manual_pending`.

**T3 — Test di non regressione e handoff.** Eseguire
`tests/engine3d/die_collision_sat_ccd_test.lua` con
Lua 5.4/LuaJIT, insieme a
`manual_dice_physics_test.lua`,
`dice_physics_audio_callbacks_test.lua`,
`physics_time_test.lua`, screenshot LÖVE/Mesa e
controlli di versionamento.
**AC-3:** CI generale green sulla HEAD finale e nessun
cambiamento alle regole Farkle. 50 lanci manuali Windows
sono un gate **NOT RUN** finché non vengono svolti davvero.

## Implementazione e limiti espliciti

- Collisioni D6-D6: SAT di cubi orientati con risposta normale
  e friction, contact point stimato dai supporti di faccia.
- CCD: swept SAT su traslazione; orientamento congelato
  alla fine dello step. Tunnelling causato da rotazioni
  estremamente rapide non viene garantito assente.
- Nessun port nativo FPS, binding FFI, libreria esterna o
  import di `fps.h`. Mantenuta l'attribuzione per
  l'adattamento dell'ingombro già presente in `bounds.lua`.
- `src/engine3d/physics.lua`: il precedente solver a sfere
  viene sostituito solo **per le coppie**. Sponde, pavimento,
  integrazione a passo fisso, audio ed interazioni restano
  basati sui sistemi esistenti.
- Dadi in mano/pending non collidono con quelli liberi:
  comportamento preesistente non modificato, da valutare
  in un'altra decisione UX.
- Il criterio più importante è la stabilità del rilascio
  dei dadi nel gioco reale, non l'uguaglianza numerica con
  FPS upstream.

## SEED gate

**Prima dei test:** WARN. Le collisioni più plausibili sono
un requisito di usabilità del nucleo, non un nuovo gameplay.
Non si promuove a PASS senza regressioni e QA manuale.
