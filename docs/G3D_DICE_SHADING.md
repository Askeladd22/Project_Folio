# Dice shading study — g3d (first implementation)

This is a controlled **presentation-only** experiment in the real
Scriptorium gameplay renderer. The purpose is to make the physical
six-faced dice legible, detect erroneous normals/depth and compare a
simple warm-ivory material against the original output.

**Gameplay, the official D6/D8 face numbering, physics positions, RNG,
Farkle scoring, mouse grabbing and the vendor g3d library are unchanged.**

## On-screen comparison: F10

While playing in the g3d tray, press **F10** to cycle through:

| Mode | What it displays | Diagnostic purpose |
|---|---|---|
| `original` | Previously shipped baked-vertex lighting | Baseline |
| `unlit` | Original pip textures and vertex tints, no light | Isolate texture/UV trouble |
| `normals` | Face normals mapped to RGB | Check winding, flipped faces and overlap |
| `diffuse` | Warm key + weak fill, no gloss or ivory tint | Study true volume and light |
| `ivory` | Warm ivory tint and subtle specular response | First material candidate |

The in-game label appears briefly after pressing F10. Use
`MANUSCRIPT_G3D_DEBUG=1` for a persistent label. Forcing an initial
preset is possible with `MANUSCRIPT_DICE_MATERIAL=normals` (or another
mode name). The default g3d mode is **ivory**; F9 still switches to the
unchanged historical renderer.

## Implementation boundaries

- `src/engine3d/g3d_mesh.lua`: physical outward normals, unchanged UV
  orientation, optional *unshaded* vertex color for shader-driven passes.
  The old baked shading path remains intact for `original`.
- `resources/shaders/dice_lit.glsl`: LÖVE 11.x pixel shader paired with
  unchanged `lib/g3d/g3d.vert`. Directional key/fill, modest specular,
  normal debug, unlit comparison. The fragment receives LÖVE's interpolated
  vertex color once: **never double-multiply VertexColor**.
- `src/engine3d/g3d_materials.lua`: pure style presets and camera-facing
  direction; D8 multicolored faces remain color-neutral.
- `src/engine3d/g3d_live.lua`: shader loads lazily only when needed.
  Failed optional shader compilation reverts to g3d's known-good
  `original` material rather than permanently disabling 3D.

No bevels, pip geometry, texture replacements, new collision shapes,
or fake face animations have been introduced. Those are separate
decisions after screenshot diagnosis.

## Visual acceptance checklist

1. Open a normal Farkle commission with six D6; capture the same still
   scene in all five F10 modes, especially a normal and an upside-down die.
2. In `normals`, each flat face should show a uniform solid color and
   change by orientation. Flickering, mixed colors *within one face*, or
   missing triangles indicate a geometry/depth bug that materials cannot fix.
3. In `unlit`, all black pips should remain crisp and properly registered
   on the correct physical face. This isolates the texture from lighting.
4. In `diffuse`, a top face and side faces should receive visibly
   different illumination. The dice must be distinguishable from the floor.
5. In `ivory`, a subtle warm surface and narrow soft specular highlight
   should appear without plastic gloss or crushed pip contrast.
6. Grab, spin and throw each die, then use the group marquee throw. Confirm
   illumination and face orientation track **the actual moving physics body**.
7. Test D8 and all F8 tray skins. The shader should tint **only the
   D6**, not recolor the D8 face-color cycle.
8. Test 1280×720 and 1920×1080, F9 fallback, GPU failure recovery, and
   ordinary mouse picking/scoring after a completed roll.

**Headless CI cannot verify shader compilation or rendered images on a
Windows GPU.** Do not merge based solely on passing Lua syntax and unit
tests; provide real LÖVE screenshots first.
