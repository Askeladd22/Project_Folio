# FPS Lab 4 — measured six-die spring-grip results

**First successful CI:** [run 41185705049](https://github.com/Askeladd22/manuscript/actions/runs/41185705049),
2026-10-31, six dynamically simulated FPS box bodies per world.
All existing Lua, physics Lab 1–3 and Python regression tests passed.
The FPS 1.2.5 vendor code was unchanged.

## Setup

Every experiment begins with the same six separated dice. They chase
**one common 3D hand target**, using capped proportional/damping forces.
There are **no fixed per-die formation offsets**. Two axes are compared:
stationary vs smoothly oscillating hand, and FPS body/body collision
detection enabled vs disabled. Each case runs 320 x 0.005 s = **1.6 s**.
The moving hand also receives a deterministic oscillating twist torque.

The held-only lab has **no gravity, floor, or walls**: the benchmark
isolates the grip and dice/dice contact response, not die landing.

## Verified output

| Scenario | Mean distance to hand at finish | Intersecting die pairs at finish | Maximum final SAT overlap | Largest sampled overlap | Nearest two centers |
|---|---:|---:|---:|---:|---:|
| Static hand, no contacts | 0.004 | 15 | 1.2451 | 1.2478 | 0.005 |
| **Static hand, FPS contacts** | **1.139** | **7** | **0.0318** | **0.0740** | **1.236** |
| Moving hand, no contacts | 0.669 | 15 | 1.2451 | 1.2478 | 0.005 |
| **Moving hand, FPS contacts** | **1.268** | **6** | **0.0307** | **0.1216** | **1.246** |

All distances and depths are world units, not pixels. Each simulated
die has an edge of **1.25** world units. FPS contacts therefore prevent
the severe shared-target collapse: peak final overlap decreases from
approximately 1.245 units to approximately 0.031 units in this fixture
(a roughly 39-fold reduction).

The nonzero 6–7 intersecting pairs reflect **minor remaining SAT cube
intersections**; these still require independent visual and multiseed
tests. The body's inability to reach the exact hand target while
remaining separate is expected: six solid cubes cannot occupy one point.

## What this supports

FPS collision response is **promising for the held/manipulation phase**:
six bodies dynamically collect around the hand, without scripted slots,
while native collisions maintain substantially more separation than
uncolliding bodies. It is a better mechanistic model for an organic
Tabletop Simulator-like handful than the current 3+3 fixed formation.

This is **not** evidence that FPS is fit to produce authoritative Farkle
face results. The separate Lab 3 still reports 38 invalid FPS final
faces out of 384 vs 0 for the current solver in those matched seeded
fixtures. Do not use this experiment to justify a full physics-engine
replacement.

## Next technical experiment

1. Try several hand-path intensities, 2/4/6 selected dice, mixed
   orientations and different starting distances. Profile the maximum
   SAT overlap and compute time.
2. Add a *throw hand-off study*: preserve every FPS die's transform,
   linear velocity and angular velocity when passing into a **copy of**
   Manuscript's existing solver in a separate lab, without visual jumps.
3. Only after a lossless bridge is demonstrated, prototype an explicitly
   opt-in real Windows LÖVE grip. No unverified physics engine changes
   should reach production Farkle.

## Important caveat

The FPS spring is original C code added to the isolated lab wrapper,
not a built-in native grab joint and not copied from Unity or Tabletop
Simulator. It calls the documented FPS force, torque, contact and step
APIs. It temporarily wakes held bodies because the upstream sleep
condition is known to be simplistic.
