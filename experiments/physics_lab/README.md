# Physics Lab 1 — Free Physics Solver vs Manuscript

**This is an isolated experiment, not a new gameplay physics engine.**
Manuscript's Farkle run, g3d rendering, RNG, scoring, persisted data and
`src/engine3d/physics.lua` are unchanged. The long-term **definitive g3d
integration in Scriptorium remains a separate priority**.

Source: [0x1ED1CE/FPS](https://github.com/0x1ED1CE/FPS), commit
`24713767b8943336749a42ac5e542474065e9b05`, FPS **1.2.5** (MIT).
The original header and its license are retained in `vendor/`; the lab's
`fpslab.c` is a very small C ABI wrapper. No FPS binaries are shipped.
FPS is marked **WIP** upstream; it is not presumed production-ready.

## Run on Windows

Open an **x64 Visual Studio Developer PowerShell** in the Manuscript
repository, then:

```powershell
.\experiments\physics_lab\build-windows.ps1
luajit .\experiments\physics_lab\run.lua 6 450
```

A standalone `luajit.exe` (LuaJIT 2.x, same family as LÖVE) must be
available on PATH to run this headless comparison. `love.exe` alone does
not provide a LuaJIT command-line interpreter. You can also use the Linux
CI job, which compiles FPS and invokes the comparison automatically.

## Run on Linux

```bash
bash experiments/physics_lab/build-linux.sh
luajit experiments/physics_lab/run.lua 6 450
```

The run prints metrics for each seed and creates
`experiments/physics_lab/build/results.csv`, with no graphics requirement.

**What is comparable:** six 1.0-sized D6 bodies; the same seeded start
positions, translational/angular velocities, timestep `0.01 s`, gravity,
floor/tray dimensions, D6 face mapping, and a *separate* 15-axis SAT
intersection-depth measurement.

**What is NOT yet equivalent:** FPS uses convex cuboid static floor and
rim colliders; the legacy solver has vertex-against-plane wall handling
and additional ad hoc rim nudges and damping. Different collision
physics means diverging trajectories are expected. Absolute CPU times
compare different implementations and allocations, not equivalent
workloads. Measurements for each solver are sequential; no shared random
state is consumed.

Metrics include: overlapping die-pair observations and worst overlap
depth; floor penetration observations; cases in which a body went to
sleep while airborne; unslept bodies at end; ambiguous/invalid upper
faces. Invalid faces are classified as moving, penetrating the floor,
insufficient upward alignment (tilt) or insufficient top-face gap,
in that priority order. Face counts from a handful of rolls **cannot** establish fair
dice distributions. For fairness, test many runs, orientations, stability
at rest, and repeatability separately.

**Known FPS limitations:**
- Upstream body sleep uses a raw `0.5` linear/angular speed threshold
  without checking floor support. We do not silently fix this in Lab 1.
- Multi-body inertia has an unimplemented parallel-axis theorem TODO.
- Convex clipping and contact points require numerical stress tests.
- FPS is C; the native DLL/SO is platform-specific and accessed solely
  through LuaJIT FFI. Always retain an optional, isolated build path.

## Acceptance criteria before any production consideration

No out-of-tray escape or crashes, no airborne-sleep events, few or no
physical intersections after settling, stable face resolution, believable
edge and corner impacts, acceptable fixed-step costs, and distribution
checks across a statistically meaningful number of physical rolls.
Only then compare any new solver with the live g3d renderer, **without**
substituting scores or overriding accepted rolls.

## Lab 2 — diagnostic floor intervention (experimental)

The original FPS 1.2.5 source and the Lab 1 baseline are **unchanged**.
Lab 2 provides a controlled third variant, `FPS+guard`, on the same seeded
six-D6 input. It corrects only dice which penetrate the nominal z=0 floor
AFTER the regular FPS physics step: raise the body's centre by the measured
lowest-corner penetration depth, reset negative vertical velocity to zero,
and allow the existing FPS body to update its transforms. This is **not a
replacement solver**. It can mask an underlying contact-normal or clipping
bug, change bounce and sleep statistics, and create visible snapping.

Build as in Lab 1 and run from the project root:

```powershell
luajit .\experiments\physics_lab\test_floor_guard.lua
luajit .\experiments\physics_lab\run.lua 8 450 lab2
```

Lab 2 writes `build/results-lab2.csv`, leaving the Lab 1 `results.csv`
independent. Rows compare `legacy`, **unmodified** `FPS`, two unmodified FPS substep
variants (`FPS2x`, `FPS4x`, respectively 0.005 and 0.0025 second integration
steps, same 4.5-second simulated time) and `FPS+guard` per identical fixture.
This isolates step-size sensitivity without changing the source engine. Additional CSV fields count post-step
guard corrections and the maximum upward correction, even if they occurred
between normal observation samples.

The guard is only a **diagnostic upper bound**: preventing final floor
penetration alone does not demonstrate physical correctness. Compare
overlaps, sleep, tilt, final face validity, corrections, and geometry before
considering a real FPS contact-solver patch. Neither the Farkle physics nor
g3d rendering imports these experimental functions.

### Promotion gate

- No uncorrected floor penetration (threshold 0.002 world units), no
  airborne sleeping, and valid final faces at least as reliable as legacy.
- No persistent high correction counts or visible popping. The ultimately
  adopted solver should resolve real contacts, not rely on a per-frame
  position clamp.
- Test both seeded single-die impacts and multi-die runs at the original
  `dt=0.01`; then visual Windows QA on real dice, and separate statistical
  fairness analysis. CI passing does not imply these gates were met.


## Lab 4 — held-dice spring experiment

See [LAB4_GRIP.md](LAB4_GRIP.md). This new, separate native experiment
tests how **six FPS rigid bodies dynamically chase the same hand target**
under spring forces and die/die contact rather than occupying a fixed
3D formation. It compares collisions on/off and stationary/moving hands.

```powershell
.\experiments\physics_lab\build-windows.ps1
luajit experiments\physics_lab\test_grip.lua
luajit experiments\physics_lab\run_grip.lua
```

The experiment does **not** alter or replace the production physics,
dice scoring, face classification, HUD, g3d or mouse pickup. It is a
held-only trial; FPS still fails some official landing tests.
