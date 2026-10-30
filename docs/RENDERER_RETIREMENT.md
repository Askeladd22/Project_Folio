# Renderer retirement audit — Scriptorium

## Decision (2026-10-30)

**Do not delete `src/engine3d/render.lua` yet.** g3d is the production
renderer for the **book + six D6** scene, not for every renderer call site.
The legacy painter is still a live dependency in production, not simply an
unused experiment.

Verified active dependencies:
- `src/app/dice_runtime.lua` imports `src.engine3d.render` for the 2D
  board, optional projected shadows, old D6 rendering, z-buffer and fallback.
  The F9 toggle and the error path explicitly render via this module.
- `src/features/farkle/tray_workshop.lua` uses its z-buffer and border
  routines for F8 workshop layouts `current`, `A`, `B`, `C` and `book`
  on fallback.
- `src/features/farkle/hud_minimal.lua` still uses `render.tray_border`
  and `render.die` in layout and presentation paths.
- `experiments/g3d_lab/main.lua` uses the original painter for A/B
  comparisons with the same physical dice.

### Safe retirement checklist

1. Render all supported F8 variants, non-D6 geometries, and divided trays
   using the g3d path, including material/pip mapping and hitbox parity.
2. Move required 2D floor drawing/overlays to distinct 2D helpers without
   depending on `render.lua`; retain read-only geometry/physics utilities.
3. Replace the existing painter error fallback with a **verified** recovery
   mechanism that does not make a graphics failure fatal. Decide whether F9
   is still desirable for on-device diagnostics.
4. Port the renderer A/B tests to independent reference fixtures, or retain
   an explicit historical test-only painter outside runtime.
5. Search imports and direct calls across `src/`, `experiments/` and
   `tests/`; run both native and visual tests (at least two resolutions).
6. Only then remove the legacy production module and adjust docs. Keep
   upstream MIT licenses, old Git commits and historical comparison data.

This decision is separate from FPS evaluation: **do not replace
`src/engine3d/physics.lua` while testing alternate contact solvers.**

## Migration checkpoint — g3d F8, D8 and held-die portraits

The `feature/g3d-all-tray-variants-20261030` branch moves the active
three-dimensional rendering of all five F8 tray skins, the split divider,
triangular D8 bodies and accepted-die HUD portraits to g3d. The latter
captures the real physical die pose once per kept-die entry.

**Why the painter remains for now:**
- GPU rendering in these newly supported modes has not yet undergone
  Windows/LÖVE visual QA; static geometry and headless Lua tests cannot
  prove correct 3D appearance or pixel-aligned mouse interaction.
- A graphics error must still leave an existing run playable.
- Explicit F9 comparison and historical g3d A/B experiments require the
  independent painter implementation.
- The 2D parchment, overlays and HUD primitives remain 2D intentionally;
  they are not incomplete GPU migrations. The held-die painter snapshot is
  still an opt-in/error fallback, not the default when g3d draws successfully.

Retirement of `src/engine3d/render.lua` should occur only after all F8
variants, D6/D8, HUD held dice, GPU failure recovery and multiple
resolutions have passed screenshot and interaction parity. Removing the
module immediately would trade source-code tidiness for a fragile build.
