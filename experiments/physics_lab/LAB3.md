# Physics Lab 3 — support-aware sleep diagnostics

This is an **isolated instrumented investigation**, not a new physics
engine for Manuscript. The pinned MIT FPS 1.2.5 header is unchanged.

## Hypothesis

FPS's upstream `fps_body_step` sleeps when speed magnitude is below 0.5,
regardless of whether a die is supported. A smaller integration timestep
can therefore *increase* false airborne sleeps.

A native read-only probe measures the lowest transformed vertex, counts
unsupported sleeping bodies and bodies penetrating below z=0 after **every**
FPS substep. Unlike the 0.1s sampling in Lab 1/2, these are body-step
observations; the denominators must account for 1x/2x/4x integration.

A separate experimental variant `FPS4x+wake` wakes a sleeping D6 with
lowest corner more than 0.08 world units above the floor **before** calling
the original FPS step. This does not address tilted resting cubes or
contact normals; it is a diagnostic intervention, not a proposed fix.

## Reproduce

From the repository root with LuaJIT and the native library built:

```powershell
.\experiments\physics_lab\build-windows.ps1
luajit .\experiments\physics_lab\test_support.lua
luajit .\experiments\physics_lab\run_support.lua 64 450
```

The CSV is written to `experiments/physics_lab/build/results-support.csv`.
Exactly the same 64 seeded six-D6 fixtures are used by the five solvers:
Manuscript's production physics, unmodified FPS at 0.01/0.005/0.0025s,
and FPS4x with optional unsupported-body wake. All runs simulate 4.5s.

## Interpretation

Compare **invalid top-face results**, floor penetration and tilt separately,
as well as airborne body-step rates, number of wake interventions, and dice
still moving at the end. A reduction in airborne sleeps is insufficient if
contact stability or final face validity degrades.

This is not a performance ranking or evidence of unbiased dice outcomes.
FPS uses different static floor/rim bodies and collision rules. Renderer g3d,
Farkle, RNG and shipping physics remain untouched; GPU and Windows visual QA
are still required before any replacement.
## Lab 3b — controlled single-die contact poses

To isolate contact handling from die–die interactions, Lab 3 also
contains a **one-body** drop matrix: upright **face-first**, 45° **edge**,
and an oblique **corner** orientation, each from z=3 with zero initial
linear/angular velocity and with dt 0.01, 0.005 and 0.0025 seconds. Every
case simulates 4.5 seconds in an independently constructed FPS world.
Euler rotations are applied by the diagnostic C bridge after saving and
restoring the world translation (upstream FPS rotation setter otherwise
reinitializes the transform).

```powershell
luajit .\experiments\physics_lab\run_contact_poses.lua
```

This writes `results-contact-poses.csv` with final validity, reason,
airborne-body observations, penetration-body observations and maximum
depth for each of the nine cases. **No production or upstream physics
files are modified.** The corner configuration is an oblique drop, not
a mathematically certified exact vertex-first orientation.
