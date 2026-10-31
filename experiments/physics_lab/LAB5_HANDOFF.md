# FPS Lab 5 — exact state handoff to Manuscript's production solver

**Experimental; not loaded by the game.**

FPS Lab 4 showed that native FPS collisions prevent the worst interpenetrations
while six rigid bodies dynamically chase a common point. The next question
is whether a group held by FPS could be **released into Manuscript's
current proven dice solver** without teleporting, changing the top face or
silently destroying velocity/spin.

## Different body representations

- FPS outputs a row-major `4×4` rigid transform plus world-space
  **eight-corner D6 vertices**, world-space linear velocity and angular velocity.
- `src/engine3d/physics.lua` stores the eight vertices **relative to
  body.position**; it subsequently rotates those local vertices and
  integrates the body's velocity, angular velocity and collisions.
- A naïve copy of FPS world vertices into a Manuscript body causes
  **double translation**. The Lab 5 converter subtracts `body.position`
  from each FPS world vertex and preserves all eight indices as-is,
  maintaining the **six face-value identities**.

## Safety checks at transfer

`experiments/physics_lab/handoff.lua` verifies the *entire* group
before constructing any Manuscript world. It rejects malformed/non-finite
pose and velocity values, wrong edges for the standard 1.25-unit D6,
non-orthogonal axes, mirrored handedness and mismatched body origin/center.
It then constructs ordinary bone-material Manuscript D6 physics bodies and
replaces their local vertices with the validated FPS pose.

Every imported body is **awake and dynamic**, so the existing
Manuscript gravity, floor, wall, collision, sleep and official face
classification can take over. FPS itself never selects a final face.

`H.error` independently compares **pre/post position, all eight world
vertices, three velocity components and three angular velocity
components**. The numeric continuity gate is at most `1e-5` world units.

## Reproduction

From the project root after a native lab build:

```bash
bash experiments/physics_lab/build-linux.sh
lua5.4 tests/physics_handoff_test.lua
luajit experiments/physics_lab/run_handoff.lua 32
```

Windows: build using `experiments/physics_lab/build-windows.ps1`
and substitute `luajit`.

The native experiment uses 32 seeded starting arrangements, with both
a stationary and a moving/shaken hand:

1. Create six genuinely separate FPS D6, with distinct Euler orientations.
2. Grip dynamically for 240 steps at `dt=0.005` with FPS contacts enabled.
3. Snapshot **all** world-space vertices, transforms and velocities.
4. Transfer all six into the unchanged Manuscript solver, assert that
   each immediate pose and velocity still matches the snapshot, and
   assert that the face-to-pip map is unchanged.
5. Run 500 original-physics fixed steps of 0.01 s and report unsettled
   dice, unaccepted final faces and any physics anomalies.

**Do not claim landing correctness just because the handoff itself
is lossless.** If native FPS overlap or preserved velocities cause
problems when released, report them rather than manually snapping
cube positions to make the metrics look better.

## Not yet included

No gameplay FPS switch, embedded C DLL shipping, camera changes,
real-time g3d rendering, Farkle scoring changes or user-facing mouse
setting. A reliable cross-solver transfer is necessary but insufficient
for a safe production hybrid.

Next: test more seeds and hand paths, ensure transition velocities feel
natural and track acceptable official faces before considering an
explicitly opt-in Windows prototype.

## Measured outcome

[LAB5_RESULTS.md](LAB5_RESULTS.md) records the CI-backed 768-die
comparison of baseline FPS contacts versus an experimental soft
pairwise repulsion during the hold. Full transform/velocity conversion
was exact in both; the original solver still moved some dice during
its first collision step. Soft repulsion reduced that movement but
left one persistent floor-penetration failure after eight seconds.
**No FPS-to-production runtime integration is authorized.**
