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
