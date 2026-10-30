# Mouse grab and throw — Manuscript

The [Free Physics Solver (FPS)](https://github.com/0x1ED1CE/FPS)
screenshots illustrate hands-on rigid-body interaction. The mouse
controller is **not** provided by the upstream FPS library or its public
`fps.h` API. Manuscript implements the gesture using its own
LÖVE mouse events, existing g3d renderer and current production physics.

## Interaction

When **Lancia/Rilancia** is enabled, hold **right mouse button on an
available die**, drag across the tray, and release. The grabbed die
follows the hand visually in g3d; the other dice remain in place until
release. Mouse direction and speed provide an additional **bounded**
horizontal velocity and slight angular impulse to the *normal official
Farkle throw*. All active dice are rolled, never an illegally isolated
die. Releasing after a small accidental movement does nothing.

This is an alternative to pressing **Space** or the **Lancia** button:
Farkle selection, accepted faces, score calculation, kept dice and physical
retry machinery remain unchanged. The right button is deliberately
separate from the **left click** used for scoring dice. A medal retry,
technical retry, modal, disabled roll or already rolling die cannot be
manually thrown. **Esc** cancels a held grab without exiting the game.

The held-die preview shifts only GPU vertices. It does not move the
underlying physics body before the actual roll, avoiding desynchronization
between collider, picking hitbox and game state. F9 legacy fallback still
allows the right-drag roll; the previewed cube follows the cursor only
in g3d. The input path uses no FPS libraries.

## Verify in Windows LÖVE

1. Start a fresh Farkle commission and hover a visible unkept die.
2. Right-click, drag at least 28 screen pixels, release; verify the
   *same official six-die launch* and the directional influence.
3. Repeat with gentle/fast and up/down/sideways gestures. Try a tiny
   right-click without dragging: it must not start a roll.
4. Select a scoring die using left mouse, then bank/take as before.
5. Confirm a non-scoring / not-yet-ready phase refuses the drag.
6. Re-roll after keeping dice: no kept dice should be relaunched.
7. Use F9 and F8, resize to 1280×720, and check right-button release
   beyond the tray, and Esc cancel during a held drag.
8. Let a physical retry occur: it must use the standard spawn/solver and
   must not replay the initial gesture as a second logical Farkle roll.

This feature is **subject to live GPU/physical input QA** before release.
Unit tests only cover gesture mapping, bounds and source integration.
