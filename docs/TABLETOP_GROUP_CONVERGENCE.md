# Group grip convergence & full-width board (31 Oct 2026)

This patch addresses the user's screenshots showing the actual six-D6
physics restricted to a smaller area of the parchment, plus a multi-die
selection that stayed spread out instead of gathering under the mouse.

## Grip mechanics
- Use **left-drag** to marquee-select two to six available physical dice.
- Press **right mouse** on one selected die **or on empty parchment** while
  there is a selected group. Their **real rigid bodies** travel smoothly
  toward a compact cursor-centered formation while remaining kinematic,
  and rotate in-hand. Convergence continues with the mouse held still.
- Each physical die stays distinct. The formation uses a 3-column grid
  for six, with spacing at least twice the largest collision radius plus
  a gap, and is clamped *as a group* at the box edges.
- Releasing applies the original physical mouse-driven impulse to
  **every die at once** from the gathered positions, with no auto-reroll
  or premature Farkle point allocation. Single-die manipulation is
  unchanged.
- Esc cancels and restores each held die's original real position and
  orientation. F9, F10, F11 still operate as before.

## Full-width gameplay
- The normal book tray displays **one continuous floor**. Previously,
  `Scriptorium.tray_divided ~= false` interpreted unset (`nil`) as a
  split D6/D8 mode. That created a restricted two-thirds D6 region even
  with a single visible board.
- Split mode is now **explicit opt-in** with
  `Scriptorium.tray_divided == true`. Special split/D8 testing remains
  possible; there is no invisible divider in the default six-D6 game.
- The unified physical region now reaches x ±8.70 and y ±3.55,
  leaving a small safety margin inside the existing x ±9.2 / y ±3.8
  collision box. Rendering/picking use the same full region.
- The camera, basic D6 dimensions, dice mass, fixed timestep and scoring
  rules are unchanged. The changes concern placement/containment, not
  the rigid-body collision solver or FPS experiment.

## Manual test on Windows
1. Start a six-D6 Farkle commission; press F9 to confirm g3d rendering.
2. Marquee-select all six with the left mouse, then press and hold right
   **on empty parchment**. They should gather beneath the pointer even
   without moving it, with visible gaps between the dice.
3. Move the group toward the extreme left/right/front/back. No dice
   should stack or pass through the displayed board walls.
4. Release with a strong mouse swipe; all six should fly/roll under
   existing physics and must be able to traverse most of the parchment.
5. Try 2+4 batches, a one-die grab, F8 scene changes and F9 fallback.
6. Esc during convergence restores original dice; normal left clicks
   must still select scoring combinations *after* a completed roll.
7. Compare 1280×720 and 1920×1080. Check the pointer alignment while
   holding and the result faces after 50+ official rolls.

The GitHub CI checks pure geometry, game-controller behavior, physics
safety and no-extra-Farkle-roll invariants. It does **not** validate
the Windows LÖVE GPU animation or actual tactile feel.
