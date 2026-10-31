# D6 visual refinement after Windows screenshots (2026-10-31)

The close-up of the six dice on the parchment highlighted several issues:
the bright flat top face looked like a separate plate above the darker
side, pip highlights resembled shiny beads, and contact shadows were
too weak to convey physical weight. This follow-up is deliberately
**narrower than a complete mesh redesign**: the screenshots do not prove
an underlying physical face or depth mismatch.

## Rendering changes

- **Bevel:** the D6 **visual-only** inset is reduced from 11% to **5.5%**.
  The six original physical faces and eight physical corners are never
  changed; this removes much of the overly thick raised-outline appearance.
- **Ivory lighting:** slightly stronger ambient contribution and lower key
  contrast help keep side faces readable without making all faces flat.
  Specular intensity is reduced from 0.14 to **0.075**.
- **Pips:** use the pip texture luminance to suppress *ivory* specular
  reflections on nearly black ink pixels. Pip relief strength drops from
  0.11 to **0.045**. This should avoid the shiny, bead-like look without
  changing the number or position of pip dots.
- **Floor contact:** calculate shadow fading from estimated distance
  between the die's bottom and the floor, rather than the die center.
  Slightly broaden and offset the feathered radial footprint.

The original/new F10 modes and F11 bevel toggle remain available.
D8 geometry and colors, Farkle face-value map, tabletop mouse movement,
the shipped rigid-body solver and FPS experiments are untouched.

## Compare on Windows

1. Take the same close-up at **F10 Ivory, F11 ON** and **F11 OFF**.
2. Capture a stationary die viewed obliquely and a die held aloft. Its
   floor shadow should be more pronounced when the die is on the board
   and fade as it rises.
3. Compare **F10 Unlit** to Ivory: if an apparent 'double cube' remains
   in Unlit and with F11 OFF, the remaining issue is **not** the new
   bevel or ivory shader. Inspect camera projection, the original
   pip artwork and depth/face ordering before another material pass.
4. Inspect the black pips: they must be dark and flat-looking rather than
   displaying bright specular glints.
5. Rotate one and all six dice with mouse drag, check correct displayed
   face numbers and no z-fighting. Also test F9 fallback.

These are shader/visual tuning values subject to **actual Windows
LÖVE GPU validation**, not proof of a completed renderer.
