# Tabletop-style individual dice interaction

The original PR #15 mapped a mouse drag to an automatic launch of **all
six dice**. It did not implement the requested behavior.

This version uses **real physical bodies** and aims for the manipulation
model of Tabletop Simulator without importing FPS or replacing g3d.

## Controls

1. While **Lancia / Rilancia** is available, **right-click a physical die**.
   This starts one official Farkle roll containing all active dice, but
   leaves them queued rather than launching them automatically.
2. **Keep the button pressed** and move the mouse. The selected die's actual
   physics position follows the cursor above the book, and its real mesh
   vertices rotate continuously while held. The physics engine temporarily
   treats it as kinematic, so gravity does not pull it from your hand.
3. **Release right mouse**: only the grabbed die is given the bounded
   velocity and spin of the final mouse gesture. Gravity, contacts and
   rotation take over on the real board immediately.
4. Grab and release the remaining dice **one at a time**, in any order.
   Already thrown dice are in the normal physics simulation while you
   manipulate the remaining ones.
5. The game **waits until every active die was released** AND until all
   dice have genuinely settled. Only then does it classify the faces and
   resolve the *one original* Farkle roll, with the same scoring, hot dice,
   weighted modifier and technical retry policies as before.

Short/no-motion releases drop the selected die naturally. **Esc while
holding** cancels just that grab and restores the original die position
and orientation (the die remains in the queue). The left button still
selects scoring combinations *after the completed group roll*. Space
remains the normal automatic group throw **before** starting manual mode.

This feature deliberately does not:
- assign a face value before the physical bodies settle;
- add free rerolls or individually scored dice;
- move a kept/previously thrown die;
- require FPS or affect the upstream solver comparison lab.

## Manual QA

Test on Windows LÖVE with g3d (and F9 legacy):

- Pick die 2; move left and right while held; verify the **actual 3D
  orientation changes**, not merely a cosmetic copy of the die.
- Let go: only die 2 moves under physics; the others remain at rest.
- Pick die 5 and throw it toward die 2, check visual impacts.
- Verify that no points appear until **all eligible dice** have been
  individually thrown and settled.
- Make a very short stationary release, a vigorous swipe and Esc cancel.
- Verify Farkle point scoring, left-click selection, **A**, **Enter**,
  hot dice, technical retries, and the automatic Space throw.
- Repeat after selecting/keeping scoring dice, and in 1280×720 / 1920×1080
  layouts and F8 variants.
- Check that the GUI never permits picking an already thrown or kept die
  during the current Farkle roll.

**Draft until real input and physics QA**. Headless tests cannot prove the
feel, collision visuals or that actual player gestures are intuitive.

## Select and throw several dice in one gesture

A **marquee selection** is now available, separately from Farkle's score
selection. Left-click and **drag a rectangle across the dice on the tray**.
The pale-blue outline marks each physical die whose projected center is
inside the rectangle. Drag the rectangle across **all six** to select all.

Then **right-click one of the outlined dice**, hold, drag and release:
every selected and not-yet-thrown die is lifted, physically spun, moved
with the mouse and released together with the same hand velocity.
Each real die retains its own orientation and relative position.
Unselected dice remain where they were, waiting for a separate throw.

The same gesture works in multiple batches (e.g. three + three) or with a
single die. Right-clicking an **unselected** die handles only that die.
After any release, the selected group automatically loses its released
members so they cannot be picked up and thrown again.

**No Farkle scoring occurs until all active dice have been released and
physically settled.** Drag selection does not itself score dice, begin a
logical roll or count as a reroll. Ordinary *left-click without dragging*
retains its scoring-selection function. Esc while selecting cancels the
rectangle; Esc with an existing group clears the group selection; Esc
while holding returns all gripped dice to their queued positions.

### Real-screen checks

- Draw a rectangle starting at an empty area around all six dice and check
  exactly six outlines appear at different screen resolutions.
- Right-grab one outlined die, shake the group and throw it; all six should
  follow the real solver and settle; only one Farkle logical roll is counted.
- Select only two, throw them, then select the other four and throw them.
  Previously released dice must not be selectable.
- Left-click without dragging after the roll: the original scoring click
  must still work; Esc should clear an unthrown selection without quitting.
- At least one group throw should strike other moving dice; inspect overlap,
  stuck-in-air, floor penetration and valid final upper faces.
