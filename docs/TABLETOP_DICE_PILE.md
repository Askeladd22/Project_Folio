# Tabletop dice heap and held-group camera framing

**Goal:** selected dice should look like a loose handful, not six keys
arranged in a flat 3×2 grid. The held group should occupy less of the
screen without changing dice collision dimensions, pips, or Farkle rules.

## Implementation

- `src/features/farkle/group_throw.lua`: a set of intentionally offset,
  irregular **3D** arrangements for 2–6 selected dice. Six dice are held
  in two interleaved triangular layers (3 lower / 3 upper).
- The **actual physics-body positions**, not g3d visual proxies, converge
  toward these targets. The spacing is based on the largest selected
  collision radius; the minimum Euclidean center-to-center distance in
  three dimensions is checked by deterministic tests. All bodies stay
  beneath the box ceiling.
- The group follows the pointer, rotates while held, and resumes
  gravity/physical collisions on mouse release as before. Esc restores
  the original six body positions/rotations; no new Farkle turn is spent.
- `src/features/farkle/group_hold_projection.lua`: a smooth **10% wider
  view only while a multi-die hold is active**, easing back when released.
  The new factor modifies the **fitted tray projection's final scale**.
  Simply raising `view.distance` would be canceled by the fitter.
- That same final scale feeds **g3d, legacy painter, projected die hit
  centers/radii, tray visual bounds, and mouse-to-world mapping**. It is
  never an isolated visual zoom that leaves the input camera misaligned.
- No changes to physical dice dimensions, F9/F10/F11 visual controls,
  face values, collision solver, FPS experiments, or Farkle scoring.
- Other tray styles and non-group interactions retain their base framing.

## Windows LÖVE acceptance test

1. Select all 6 dice with left-drag marquee, right-grab an outlined die
   **or empty parchment**. Hold still: the dice should converge under
   the pointer into a visible 3+3 **two-level** heap, not 3×2 flat keys.
2. Gently rotate/shake them. Every distinct die should turn and remain
   a real body without interpenetrating.
3. Observe the camera ease outward subtly during the group hold; it
   should restore smoothly after release rather than snapping.
4. Fling the entire group: the die bodies should spread, collide,
   bounce and settle with valid top faces under the existing solver.
5. Repeat with a partial group (2, 3, 4, 5), and an individual die.
   The normal one-die grab and Farkle after-roll scoring must be unchanged.
6. Test near each boundary. Esc should return **all** held dice to
   their original positions, with the framing returning to normal.
7. Capture comparison screenshots at 1280×720 and 1920×1080, and check
   F9 g3d/legacy switching and F10/F11 diagnostics.

Headless Lua5.4/LuaJIT tests assert 3D pair distances, formation
centering, two-layer structure, smooth zoom and source wiring.
**Visual quality and physical collisions during a full run still require
direct Windows testing**; therefore the PR is intentionally a draft.
