# Tabletop Simulator dice handling — static .NET analysis

**Source:** `Assembly-CSharp.dll` supplied by the user from their own
Tabletop Simulator installation on 2026-10-31. SHA-256:
`f34f48a2f9f450b15fedc71357b745a4972344496cd20dfe1062aef4ab6f936c`.

The assembly is a 4,287,432-byte Unity/Mono .NET binary. This document
records **behavioral findings, not copied or redistributed source code**.
Analysis used managed metadata and disassembled IL; graphics/input
configuration from the rest of the Unity installation was not supplied.

## Confirmed execution paths

| Type / method | What the bytecode establishes |
|---|---|
| `ManagerPhysicsObject.UpdateGrabbedNPO` | Computes desired position/rotation for each grabbed object and uses the rigid body's `AddForce` and `AddTorque` methods to approach those targets while held |
| `ManagerPhysicsObject.ClientGrab` | Associates grabbed physics objects with the pointer/player, their offsets and rotation indices |
| `ShakeDetector.FixedUpdate` | Measures hand target versus rigid-body position, and checks a directional dot product with rigid-body velocity; counts shake events within a 1-second window |
| `Pointer.Shake` | Processes the player's held objects; dice/coins take a distinct branch from decks and bags, with object-randomize and shake-sound signals |
| `ManagerPhysicsObject.ClientRelease` | Restores physical collision handling, examines the linear/angular movement of dice/coins, applies extra spin in a fast-release branch, and damps/caps movement |
| `ManagerPhysicsObject.Randomize` | Separate explicit randomize path: applies random torque to dice/coins, including a distinct delayed rotation path; not the same as holding or throwing |
| `Pointer.Flick` | Separate flick-tool path: wakes objects and applies an impulse, rather than acting as the normal dice release |
| `NetPhysObject.Drop` | Resets the object and toggles held/collision state before the remainder of the release processing |

### Relevant observed numbers

All values below are Unity-side constants. Their units/tuning must **not**
be transposed directly to Manuscript's custom Lua world:

- `ShakeDetector.FixedUpdate` compares `dot(hand_position-body_position,
  body_linear_velocity) < -3`, counts movements and uses a **1-second**
  reset window. The count is compared with a tunable
  `ManagerPhysicsObject.ShakeThreshold`. The static initializer starts
  that field at 0, although runtime user settings can override it.
- The detector and held-body update both apply **forces** using position
  errors and time steps; the exact stable result depends on Unity's
  rigid-body integrator. In particular, the held-body translation uses
  a coefficient containing `20000 × 1.25 × deltaTime` before optional
  force reduction. It is not a pixel-to-world teleport.
- At release, dice/coins are specially considered for rotation when
  horizontal-component magnitudes exceed roughly **2** or angular
  magnitude exceeds **2**, followed by an `AddTorque` branch.
- The release path applies linear damping factors including **0.5**
  and **0.8** (conditional) and a mass-sensitive maximum speed.
- The explicit `Randomize` action samples random torque components in
  a `[-6,6]` range and includes an upward-velocity component. This is
  conceptually separate from mouse-release force.

### What we must *not* infer from the assembly alone

This analysis does **not** establish that the release result is uniform
among all six die faces, that any particular Unity settings are active
in the user's installed game, or that FPS is the same physics engine
as Tabletop Simulator. No Unity DLLs were provided, so final component
configurations, mouse options and literal world-to-screen scaling remain
unverified. FPS is a separate experimental solver.

## Original Manuscript adaptation in this branch

Manuscript currently holds queued dice kinematically in its own engine
and guides them to a compact formation. This is **not identical** to
TTS's dynamic rigid-body force-based grip. Reproducing that fully needs
a separate collision and solver-stability experiment.

This small experiment adds a pure-Lua
`src/features/farkle/shake_detector.lua`:

- Detect two strong direction reversals in **0.85 seconds** rather than
  mistaking a one-way swipe for shaking; suppress small cursor jitter.
- Produce distinct **bounded angular kicks** per held die while physically
  rotating its existing body vertices, and retain a small spin boost at
  release.
- Support single-die and selected-group grabs through their common
  `MouseThrow.track` path.
- Use a **private deterministic gesture PRNG** for varied spins: no
  consumption of Farkle's existing RNG and no direct assignment of a
  final face or score.
- Preserve Esc cancel, the same active-dice Farkle logical roll,
  scoring-after-settlement, kept dice exclusions, legacy renderer and
  physical solver.

The 0.85-second / two-reversal thresholds are **Manuscript design
choices**, not claimed to be TTS's actual default settings.

## Validation

`tests/tabletop_shake_test.lua` exercises:
- no shake from one continuous fast throw or tiny jitter,
- no reactivation from stale/double-timestamp samples,
- alternating hand movement triggers a bounded angular kick,
- actual physical mesh rotation while held,
- the normal release transition and group dice handling.

Before merging, test in real Windows LÖVE at high and low pointer
sensitivities, inspect 50+ complete legal Farkle rolls, verify no
invalid/stuck faces or excessive spin, and compare stationary grips
versus deliberate shake-and-release in the default g3d tray.
