# FPS Lab 4 — force-driven tabletop grip (experimental)

**Status: isolated.** This does not replace production physics or
integrate FPS into the Scriptorium renderer. Only the experimental bridge
`fpslab.c` and the LuaJIT lab FFI are extended. The upstream MIT FPS
1.2.5 `vendor/fps.h` remains **byte-for-byte unchanged**.

## Motivation

In current gameplay, selected dice converge toward fixed 3D slots,
so they look like a symmetrical sculpture even if the mesh is rendered
beautifully. The user wants the loose, bumping, rolling 'handful of dice'
seen in Tabletop Simulator.

FPS supplies `fps_body_force_apply`, `fps_body_torque_apply`,
`fps_collision_test` and `fps_body_step`, sufficient for an initial
force-following experiment **but not a built-in grab joint**.

## What the experiment actually does

- Create six genuine FPS cuboid rigid bodies at separated initial positions.
- Point **all six** toward ONE common hand target via a proportional/
  derivative spring force `F = mass * clamp(k*(hand-body)-d*velocity)`,
  not six predetermined target slots.
- Apply bounded torque with angular damping. Explicitly wake the held
  bodies, compensating for FPS's simplistic speed-only sleep threshold
  **during the held-only trial**.
- Test four combinations of stationary vs oscillating hand, each with
  native body/body collision enabled and disabled; compare convergence,
  overlapping pairs, SAT overlap depth, minimum center spacing, and
  overlap observations. The comparison prints metrics, even if contact
  solving performs poorly. It does not assume the colliding variant wins.
- **Omit gravity and board walls while held** to isolate gathering.
  This deliberately says nothing about how the dice land on the tray.
  Returning to the existing Manuscript solver is not attempted.

## Reproduction

From the root, with a LuaJIT interpreter and native C build support:

Windows:

```powershell
.\experiments\physics_lab\build-windows.ps1
luajit experiments\physics_lab\test_grip.lua
luajit experiments\physics_lab\run_grip.lua
```

Linux:

```bash
bash experiments/physics_lab/build-linux.sh
luajit experiments/physics_lab/test_grip.lua
luajit experiments/physics_lab/run_grip.lua
```

CI runs the same native bridge plus the existing full physics regression
suite, ensuring the new API has not broken or silently altered Labs 1–3.

## Interpretation and limits

- Current FPS floor/contact experiments previously recorded **38 invalid
  final D6 faces out of 384** with dt 0.0025s, versus zero from the
  existing solver in those identical seeded fixtures. A pleasant-looking
  grip cannot establish correct final Farkle results.
- FPS has no joint/constraint API in the current pinned header. This lab
  therefore implements an original proportional-damping spring controller
  using FPS forces, not a Unity-style native joint.
- Absence of over-penetration or excessive oscillation at a static hand
  point must be measured; our C bridge does not correct die overlaps
  with per-frame teleports.
- In any future hybrid grip, preservation of **each dice's position,
  orientation and linear/angular velocities** on transition to the
  current production solver is essential. A collision-safe, tested
  transition is mandatory before integration.
- For now this is **NOT part of the gameplay UI**, does not alter
  `src/engine3d/physics.lua`, and does not change Farkle scoring,
  camera, g3d, dice faces or actual mouse controls.

## Promotion criteria

1. Stable real contacts and convergence for stationary and moving hand.
2. Low 3D cube intersection depth, no exploding impulses and acceptable
   frame times, including 2/4/6 selected dice.
3. Successful shake and release without clipped or teleporting poses.
4. Repeated real in-game Windows tests, renderer QA, and unchanged
   official Farkle face-validity, fairness and retry behavior.
