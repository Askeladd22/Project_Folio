# Project Folio

*Project Folio* is a prototype about **an engraver in Renaissance Venice**. The creative direction is being reopened: dice roguelite, Farkle, dream encounters and the Opponent Duel are the **current playable baseline**, not fixed features for the final game. See the [living design brief](docs/project_vision.md).

## Play

**Opponent Duel** is the only player-facing mode. **New Game** enters the table directly. You and the Opponent take turns playing the same six-D6 Farkle rules. The first to bank **500 points** wins. A Farkle loses only unbanked turn points; previously secured scores carry between turns.

**Right-click** to grab a die, then move and release to throw it. **Left-drag** to select a group before grabbing, or click dice to choose a scoring combination. **A** sets selected scoring dice aside; they remain visible on the **rear of the 3D tabletop**. **Enter** banks points and **?** opens the rules.

The Opponent pauses between reading its roll, highlighting chosen dice, setting them aside and announcing whether to bank or reroll. The HUD shows its banked points, at-risk total, last set-aside gain and next action. No cards, health bars or automatic dice-launch button are required.

## Run locally

Install [LÖVE 11.x](https://love2d.org/). On Windows, run `run_game.cmd`; otherwise run `love .` from the repository root.

## Code and design

The production code comprises **30 Lua source files** under `src/`: [controller](src/farkle/controller.lua), [HUD](src/farkle/ui.lua), [Farkle rules](src/farkle/rules.lua), [3D dice](src/farkle/dice.lua), and [main menu](src/screens/frontend.lua). Historical research prototypes remain in `experiments/`, not as alternate playable modes.

[Technical map](docs/technical.md) · [Farkle rules / prototype baseline](docs/farkle_rules.md) · [Open creative brief](docs/project_vision.md) · [Changelog](CHANGELOG.md) · [Third-party licenses](lib/licenses/)
