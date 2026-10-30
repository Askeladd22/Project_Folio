# FPS Lab 3 — support and sleeping diagnosis (2026-10-30)

**Result: the support-only waking intervention is not an acceptable
replacement for the current Manuscript solver.**

[CI evidence: run 41112638114](https://github.com/Askeladd22/manuscript/actions/runs/41112638114).
The Linux CI completed successfully, including an unchanged upstream FPS
1.2.5 build, a single-body wake test, and 64 seeded runs (384 final D6)
of each candidate at 4.5 seconds simulated time.

## Protocol

Identical deterministic fixtures: seed `1337 + 7919*(run-1)`, six D6,
consistent initial positions and velocities. Five independent worlds per
seed: Manuscript current, unmodified FPS 0.01s, unmodified FPS 0.005s,
unmodified FPS 0.0025s, and FPS 0.0025s with support-based wake.

The probe runs **after each native substep**, measuring the lowest
transformed corner and current sleeping flag. It counts unsupported sleeping
bodies when that corner is >0.08 world units above the z=0 surface,
and floor penetration at <−0.002. The wake intervention, where enabled,
runs before the native step only on unsupported sleeping bodies; it does
not modify upstream FPS or inject translations. Its count is a **number
of interventions**, potentially repeatedly on one body.

## Results

| Metric | Current | FPS 0.01 | FPS 0.005 | FPS 0.0025 | FPS 0.0025 + wake |
|---|---:|---:|---:|---:|---:|
| Invalid faces / 384 | 0 | 215 | 35 | 38 | 38 |
| Invalid by floor | 0 | 206 | 9 | 0 | 0 |
| Invalid by tilt | 0 | 3 | 25 | 37 | 37 |
| Invalid by remaining movement | 0 | 6 | 1 | 0 | 0 |
| Invalid by airborne sleeping at finish | 0 | 0 | 0 | 1 | 1 |
| Overlapping-pair observations | 555 | 334 | 438 | 243 | 234 |
| Unsupported sleep, body-steps | n/a | 0 | 0 | 1,119 | 819 |
| Penetrating, body-steps | n/a | 83,179 | 19,979 | 6,434 | 7,132 |
| Largest probed floor penetration | n/a | 0.29787 | 0.39349 | 0.34791 | 0.34791 |
| Wake interventions | 0 | 0 | 0 | 0 | 818 |

Body-step denominators: **172,800** for FPS 0.01;
**345,600** for FPS 0.005; **691,200** for FPS 0.0025 and FPS 0.0025 +
wake. These counters represent *samples*, not distinct sleeping events.
The current Manuscript solver does not implement this native probe:
its zeros for these counters would be misleading, hence **n/a** above.
Overlaps and final face validity are measured with the independent
Lua metrics, as in Labs 1/2.

## Interpretation

Support-only waking reduces unsupported-sleep body-step observations
(1,119 → 819) but **does not reduce invalid faces** (38/384 in both
variants) and **increases the frequency of floor penetration** (6,434
→ 7,132 body-steps). It is therefore not a solver improvement.

The 0.005-second unmodified FPS variant remains better than 0.01
for final face validity, yet still has 35/384 failures compared with
zero in the current engine under these fixtures. A smaller integration
step is not sufficient, and no evidence currently supports adopting FPS.

### Next diagnostic before a solver patch

1. Reproduce single-die face-on, edge-on and corner-first contacts.
2. Measure the contact normal, contact-point position and separation
   correction *inside an opt-in instrumented FPS variant* to distinguish
   bad contact geometry from the rigid-body integrator's sleep threshold.
3. Test angular settling and contact-moment response under identical
   fixtures at 0.005 seconds, without per-step positional clamps.
4. Repeat Windows graphical QA, 50+ real rolls and unbiased-result tests
   only after basic geometric and face-validity acceptance gates pass.

**No changes to production physics, g3d rendering, scoring or saves.**

## Stricter final-face metric and isolated drop test

An additional nine-case drop matrix (face/edge/oblique corner, each at
0.01/0.005/0.0025s) exposed a previously hidden classification error:
**all nine single-die fixtures ended with the body sleeping in midair**,
because the initial stationary body was put to sleep before reaching the
floor. Before this correction, the horizontal face-first die was
misclassified as valid, solely because its top face was level.

The independent `metrics.finish` test now treats a sleeping die whose
lowest vertex is more than **0.08 units** above the floor as
`invalid_airborne`. That diagnostic fix does not modify FPS itself or
production physics. Re-running the 64-seed comparison changes FPS4x
from **37/384 to 38/384** invalid final faces; the FPS4x+wake variant is
also **38/384**. It leaves the other final-face counts unchanged.

[Corrected CI: 41113882338](https://github.com/Askeladd22/manuscript/actions/runs/41113882338).
**The original two-step notes are historically valid only under the
older, less strict face-validity classifier.**

## Confirmatory impact tests

The initial nine zero-velocity contact-pose experiments never reached the
floor: they were valid demonstrations of sleep failure, **not** floor
collision tests. The final Lab 3 matrix therefore retains those nine
`rest` fixtures and adds nine `impact` fixtures initialized at z=3
with a downward velocity of −5 units/s. An assertion requires the
impact bodies to approach the floor within 0.08 world units. The results
are exported to `results-contact-poses.csv` as 18 cases (plus header).
The exact outcomes are reported by CI and should not be confused with
the 64-run, multi-die evaluation.
