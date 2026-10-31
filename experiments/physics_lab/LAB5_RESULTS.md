# FPS Lab 5 — verified cross-solver release results (2026-10-31)

**Status: experimental, do not enable in gameplay.**

Source: [GitHub Actions 41186812215](https://github.com/Askeladd22/manuscript/actions/runs/41186812215)
(complete 32-seed validation, Linux Lua5.4/LuaJIT + isolated native FPS).

## Test design

- 32 deterministic starting arrangements with six D6 each.
- For each arrangement, two hand motions: static and shaking/moving.
- Compare two FPS *held-only* controllers:
  1. **Native contacts:** spring force toward the common cursor, FPS
     cuboid contact handling; no artificial target slots.
  2. **Compatible repulsion:** above plus **gradual pairwise forces**
     during the hold, trying to respect Manuscript's **larger spherical
     collision envelope**, without teleporting dice.
- 128 total simulated releases × 6 dice = **768 outcomes**.
- 240 FPS hold steps at 0.005s each; then one validated **instantaneous
  transfer of the full eight-corner pose, position, linear and angular
  velocity**, preserving the six canonical face indices.
- Manuscript's existing solver then runs for **five seconds**, and
  continues for an additional **three seconds** to distinguish slow
  settling from persistent floor or face errors.

## Verified results

| Metric | FPS grip, native contacts | FPS grip, compatible repulsion |
|---|---:|---:|
| Simulated releases | 64 | 64 |
| Final D6 examined | 384 | 384 |
| **Max handoff pose/velocity error** | **0** | **0** |
| Maximum first original-physics step displacement | **0.29211** | **0.13283** |
| Maximum initial legacy collision-sphere overlap deficit | 0.40123 | 0.20108 |
| Maximum FPS held-body SAT overlap | 0.26339 | 0.14541 |
| Invalid at five seconds | 3/384 | 4/384 |
| Of these, still moving at five seconds | 3 | 3 |
| Of these, penetrating floor at five seconds | 0 | 1 |
| **Invalid after eight seconds** | **0/384** | **1/384** |
| Persistent floor penetration at eight seconds | 0 | **1** |

### What the measurements actually prove

1. **The conversion works.** The snap at the transfer instant is exactly
   zero, and the position, all eight face-defining vertices, linear
   velocity and angular velocity of each D6 are unchanged.
2. **Collision envelopes differ.** The original solver's approximate
   collision radius is larger than FPS's precise cube contact geometry.
   When a dense FPS-held handful is passed to the original solver, its
   *very first fixed step* separates bodies by up to **0.292 world
   units**, a visually noticeable pop. This is an actual post-transfer
   physics effect, not a coordinate conversion bug.
3. **Gradual pairwise repulsion reduces but does not eliminate the pop**:
   0.292 → 0.133 world units, roughly a 55% improvement.
4. **However, the modified held controller is NOT acceptable**: one
   die retains floor penetration even after eight seconds. Smaller
   first-step movement alone must not override physical correctness.
5. The standard native-contact FPS grip followed by Manuscript landing
   produced all valid results after eight seconds in these particular
   384 fixtures. **This is not a proof of general validity**, and its
   first-step displacement remains unacceptable for the desired
   Tabletop Simulator feel.

## What to do next

- Do **not** merge a production FPS switch or replace the Farkle landing
  physics on this evidence.
- Avoid immediate release while the new physical engine sees dense
  overlapping collision envelopes. Explore a **continuous, contact-safe
  pre-release transition** over a short real-time window, controlled
  forces rather than instantaneous position corrections.
- Repeat with changed hand paths, orientations, partial groups,
  collision rates, peripheral board positions and mixed dice behavior.
- Measure not only final valid faces but **per-frame discontinuities**,
  time to settle, shake impulse, overlap and worst-case individual die.
- Once 0 invalid outcomes and an acceptable maximum displacement are
  demonstrated across diverse fixtures, implement **an explicit opt-in
  Windows LÖVE hybrid grip**. Preserve old reliable Farkle scoring and
  technical retries until it passes interactive QA.

**Lab 5 does not render a game window and ships no FPS DLL.** The
upstream MIT FPS header remains untouched; no proprietary Tabletop
Simulator code is copied.
