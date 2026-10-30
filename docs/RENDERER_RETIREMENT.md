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
