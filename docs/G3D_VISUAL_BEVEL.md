# Visual dice chamfers and engraved pips — g3d

This pass follows the illumination study in [G3D_DICE_SHADING.md](G3D_DICE_SHADING.md).
It adds physical-looking edges to the rendered D6 only, plus subtle pip
edge highlights in the warm-ivory material. **The actual D6 rigid-body
mesh, Farkle face mapping, collision resolution and mouse physics stay unchanged.**

## Controls and comparisons

- **F10**: original → unlit → normals → diffuse → ivory (unchanged).
- **F11**: toggle D6 *visual-only* edge chamfer on/off. Defaults **on**.
- **F9**: the historical painter fallback remains available.
- **MANUSCRIPT_G3D_DEBUG=1**: persistent material and bevel status.

To preserve a reliable control, `original` and `unlit` use
the unmodified box faces even with F11 enabled. `normals`, `diffuse`
and `ivory` display bevels whenever F11 is on. The colored D8 retains
its original triangular faces and palette.

## Geometry

`src/engine3d/g3d_bevel.lua` derives all visible geometry from the
existing eight physical D6 corners every frame:

1. Six flat, slightly inset, textured faces (unchanged pip ordering);
2. Twelve chamfer strips joining the original face planes;
3. Eight small triangular corner caps, closing the cube completely.

The inset is **11% of the half-width**. Chamfer strips and corner caps
use the existing shader and a white texture, with outward normals.
The pip-image UVs are cropped to the visible face rather than stretched
or rotated. The chamfer never writes to `body`; it is updated from
the actual body's positions and rotations, including when the player
grabs several dice and throws them.

In `ivory`, the shader samples the original pip texture's immediate
neighboring texels to create a small directional bright/dark rim at the
existing pip edges. This is a **lighting illusion**, not actual displaced
geometry: it creates no collision or new selectable shape. The
`diffuse` and `unlit` comparison modes omit that effect.

## GPU validation checklist (Windows LÖVE)

1. Compare **F10 Original**, **F10 Diffuse F11 OFF**, **F10 Diffuse F11 ON**,
   then **Ivory F11 ON** with exactly the same six stopped dice.
2. Inspect top and side faces: UVs must stay in their original orientation,
   the black pips must not deform, and 3D corners must have no cracks or
   visibly bright missing triangles.
3. With **Normals** and F11 ON, each flat face must retain a constant normal.
   Edge strips and caps should have their *own* appropriately oriented normals.
4. In **Ivory**, verify that the pip border highlights are subtle; the dots
   must remain crisp, dark, recognizable and correct.
5. Rotate one die while held, then all six at once (marquee). The corners
   and visible highlight must follow **each die's physical orientation**
   and must never split from their real bodies.
6. Test at 1280×720 and 1920×1080; verify occlusion on the parchment,
   shadow stability, frame time and picking over at least 30 rolls.
7. Check the **D8** remains flat/colored and the original F9 mode remains
   usable with the expected original material.
8. If the new shader fails compilation, the existing g3d fallback should
   select original shading, not break the game session.

**Do not merge solely based on CI:** the tests validate geometry and
Lua code, not real GPU image quality or shading artifacts. If bevels
look too round or cartoonish, the 11% inset can be reduced separately
without touching gameplay. HUD's cached 2D miniature rendering remains
as before in this first bevel study; visual parity for that small view
can be assessed separately after the live dice are approved.
