# g3d — clean book-tray visual pass

The previous Scriptorium screenshot (2026-10-30) showed thick book walls,
huge rubricated crosses and floor panels competing with the actual dice. The
GPU scene was still drawing **the painter's 2D floor first** and g3d dice
on top. The old rubrics also used 1–2 world-unit line widths inside a
scaled 2D transform, becoming very wide pixel bars.

## Design decision

Keep the historical manuscript **context**, not a busy floor illustration.
The default scene now uses an opaque, single-color g3d parchment plane at
physical `z=0`, thinner decorative side panels, a slightly angled view
and the existing physically transformed, textured dice. Page ornaments
are omitted inside the tray. **Physics, scoring, Farkle and input are unchanged.**

g3d draws floor → soft contact shadows → walls/divider → dice against a
single GPU depth attachment. The 2D legacy floor is drawn **only** if the
GPU renderer is disabled or a scene fails. This prevents duplicate
floor graphics during normal play. The F9 legacy fallback also uses
restrained parchment instead of cross-shaped rubrication.

The renderer still retains GPU shadows and existing die highlights.
A legacy toggle or GPU failure must not reset the painter's translated
and scaled tray transform.

## Verify on Windows

```powershell
git fetch origin
git switch fix/g3d-clean-tray-depth-20261030
.\Avvia.cmd
```

Compare the same run in g3d (default) and painter (**F9**). In the
book layout, check:

- The center is a **clear parchment field** without crosses, stacked
  translucent rectangles or page rules drawn over dice.
- Six **single** physical D6 render with correct, legible pips and
  consistent face values. The slight yaw should make lateral cube
  faces clearer.
- Dice remain inside the physical tray. Shadows lie on the paper, not
  above the dice; near/far rim segments correctly occlude dice.
- The book frame is noticeably thinner than in the original screenshot.
- F8 alternatives, D8 split dividers and six accepted-die HUD portraits
  remain functional. F9 and error fallback restore normal visuals.
- Clicking and keyboard selection hit the same dice at **1920×1080**
  and **1280×720**, with no leaking stencil or cropped front walls.
- Test moving dice as well as settled dice, then inspect 50 accepted rolls
  and record any displayed face-versus-scored-face mismatch.

**CI only validates geometry and state routing**; it cannot verify
live LÖVE GPU output or performance. Do not remove the historical painter
from production until that visual test passes.
