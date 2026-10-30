# Physics Lab 2 — measured results (2026-10-30)

This report describes the controlled *diagnostic* FPS experiments in
`experiment/fps-substep-sensitivity-20261030`. **No production physics or
g3d renderer change** is involved. Source: upstream FPS 1.2.5, pinned at
`24713767b8943336749a42ac5e542474065e9b05`, left unchanged.

## Reproduction

From the repository root with LuaJIT and the native FPS lab built:

```powershell
.\experiments\physics_lab\build-windows.ps1
luajit .\experiments\physics_lab\test_floor_guard.lua
luajit .\experiments\physics_lab\run.lua 64 450 lab2
```

The 64 seed fixtures start at 1337, incrementing by 7919. Each of the
five solvers runs the same six D6 initial states independently for 4.5 s.
The baseline integration step is 0.01 s; FPS2x performs two 0.005 s steps
per nominal frame and FPS4x performs four 0.0025 s steps per nominal
frame. `FPS+guard` retains 0.01 s and applies a *non-physical* post-step
penetration correction for comparison.

Verified in [GitHub Actions run 41111081859](https://github.com/Askeladd22/manuscript/actions/runs/41111081859):
headless Lua, native Linux build, baseline comparison and expanded Lab 2
all completed successfully.

## Observed results: 64 runs, 384 final dice per solver

| Metric | Manuscript current | FPS 0.01 | FPS 0.005 | FPS 0.0025 | FPS+guard |
|:--|--:|--:|--:|--:|--:|
| Invalid final upper faces | 0 | 215 | 35 | 37 | 384 |
| Invalid because of floor (final) | 0 | 206 | 9 | 0 | 0 |
| Invalid because of tilt (final) | 0 | 3 | 25 | 37 | 89 |
| Invalid because still moving | 0 | 6 | 1 | 0 | 295 |
| Airborne-sleep sampled events | 0 | 0 | 0 | 28 | 41 |
| Overlapping die-pair observations | 555 | 334 | 438 | 243 | 470 |
| Maximum die-pair overlap depth | 0.3623 | 0.2611 | 0.2455 | 0.2221 | 0.3519 |
| Worst floor penetration at sampled times | 0.0495 | 0.1654 | 0.0717 | 0.0322 | 0.0000 |
| Per-step floor guard corrections | 0 | 0 | 0 | 0 | 93868 |
| Largest individual guard correction | 0 | 0 | 0 | 0 | 0.2224 |
| Average CPU time/run (s) | 0.022 | 0.006 | 0.008 | 0.011 | 0.007 |

Every observation counter is sampled at 0.1 s intervals, whereas the
floor guard correction counter is recorded on **every step**. A brief
mid-step penetration can therefore be corrected without appearing in
the sampled penetration column. The `invalid_faces` metric uses our
independent strict 5-degree top-normal threshold and no final floor
penetration deeper than 0.002 world units; it is not a direct sample of
the in-game accepted-roll algorithm.

CPU numbers are only exploratory, not a synchronized equivalent-workload
benchmark. FPS and Manuscript use different collision and wall handling
and simulations diverge after contact.

## Conclusions and next steps

1. Reducing the unmodified FPS step from 0.01 s to 0.005 s lowers final
   invalid faces from 215/384 to 35/384, but does not meet the current
   Manuscript standard of 0/384 on the same fixture sample.
2. 0.0025 s does **not** improve overall face validity: 37/384 invalid,
   and 28 sampled airborne-sleep events. A smaller step is not sufficient.
3. The naive post-step floor guard is **rejected** for integration:
   384/384 invalid, 295 unsettled dice, 93,868 adjustments. Its zero
   floor penetration merely masks a worse dynamics problem.
4. The next isolated investigation should log per-contact normals,
   separation depths, floor-vs-wall contact counts and sleeping decisions
   on single-body drop tests, then on multi-body edge impacts.
5. Revisit upstream FPS collision/penetration resolution and support-based
   sleep criteria only in a separate, clearly labelled fork/variant;
   do not silently edit vendored FPS or production physics.
6. Longer tests, real Windows graphical QA, fairness testing and
   reliable final face classification must precede any engine migration.

**Decision: retain `src/engine3d/physics.lua` and the g3d renderer.**
The older renderer `src/engine3d/render.lua` is also retained for its
still-active F8/HUD/fallback and A/B responsibilities; see
`docs/RENDERER_RETIREMENT.md`.
