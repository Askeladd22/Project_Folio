# Pure Farkle 1v1 Design

## Status

Approved direction from chat on 2026-07-02: pivot the current game into a pure, playable Farkle base inspired by Kingdom Come: Deliverance II dice, then later rebuild or relaunch the scriptorium concept on top of that cleaner base.

This replaces the previous hybrid direction for the next implementation pass. The old scriptorium work remains available as legacy code.

## Goal

Create a solid 1v1 Farkle game with a simple AI opponent.

The first playable version should answer one question well:

"Can I play a full, understandable dice match against an opponent, with bank, reroll, bust, and hot-dice decisions working reliably?"

The v0 does not need loaded dice, badges, scriptorium folios, ink, stains, reward economy, campaign structure, or final visual polish.

## Non-Negotiable Constraints

- Do not modify `src/engine3d/*`.
- Keep the scriptorium feature in `src/features/legacy/`.
- Build new Farkle gameplay in new modules instead of adding more logic to the legacy scriptorium file.
- Reuse the existing physical dice roll pipeline in `main.lua` as the source of rolled values.
- Keep the implementation testable with pure Lua modules for scoring and match flow.

## Existing Context

The current refactor has already moved the scriptorium into `src/features/legacy/scriptorium.lua`.

The project still has:

- A Love2D entrypoint in `main.lua`.
- A physical 3D dice tray and roll settlement callback.
- A feature registration system through `SettingsState.GameManager`.
- A compact set of current feature modules under `src/features/`.
- Gameplay modules under `src/gameplay/`.
- Existing tests run through `scripts/test.ps1`.

The main work is to introduce a clean Farkle feature and point the default play route at it, while preserving legacy scriptorium code for later reference.

## Proposed Architecture

Add a new gameplay namespace:

- `src/gameplay/farkle/scoring.lua`
- `src/gameplay/farkle/match.lua`
- `src/gameplay/farkle/ai.lua`

Add a new feature module:

- `src/features/farkle.lua`

Update boot/navigation:

- Register `farkle` in the feature manager.
- Route the game start path to `farkle`.
- Keep `legacy_scriptorium` registered or loadable, but no longer make it the main active gameplay route.

Keep `main.lua` responsible for:

- Spawning and rolling dice.
- Detecting settled dice.
- Reading face values.
- Emitting settled roll values to the active dice-game feature.

The Farkle feature should expose the same minimal callbacks that `main.lua` needs:

- `onRollRequest(max_dice, roll_indices)`
- `onDiceSettled(values)`
- `dice_results`
- `selected_die`

If the existing tray selection code depends on scriptorium-specific state names, adapt only the feature-facing references in `main.lua`. Do not touch `engine3d`.

## Gameplay Rules

Use six d6.

Each match has two players:

- Human
- AI opponent

Default target score: 5000 for short testable matches.

Turn flow:

1. Current player rolls available dice.
2. If the roll has no scoring dice, the player busts and loses the current turn score.
3. The player must keep at least one scoring die or scoring combination.
4. Kept dice add to the current turn score.
5. The player may bank the turn score or reroll the remaining dice.
6. If all six dice have been kept, hot dice resets available dice to six and the player may continue.
7. Banking adds turn score to total score and passes the turn.
8. First player to reach or exceed the target wins after the current turn resolves.

For v0, there is no final equalizing turn. This keeps the prototype brisk and easier to reason about.

## Scoring Rules

Use a standard readable Farkle table:

| Combination | Score |
| --- | ---: |
| Single 1 | 100 |
| Single 5 | 50 |
| Three 1s | 1000 |
| Three 2s | 200 |
| Three 3s | 300 |
| Three 4s | 400 |
| Three 5s | 500 |
| Three 6s | 600 |
| Four of a kind | 1000 |
| Five of a kind | 2000 |
| Six of a kind | 3000 |
| Three pairs | 1500 |
| Straight 1-6 | 2500 |

The scoring module should produce available scoring selections for a roll, not only one total. The UI can start with a conservative auto-selection if necessary, but the rules layer should support manual selection.

Selection rules:

- A selected group must be valid within the current roll.
- Points from previous throws in the same turn do not combine into new triples.
- A roll can score multiple groups if all selected dice are used by valid groups.
- If no valid scoring group exists in the roll, it is a bust.

## Human Interaction

The human should be able to:

- Roll.
- Click dice or scoring groups to keep them.
- Bank when the current turn score is greater than zero.
- Reroll when at least one valid scoring selection has been kept.
- Restart the match from the UI.

For v0, if direct dice clicking is too expensive because of the current tray hit model, the first implementation may provide buttons for scoring groups generated from the latest roll. This keeps the Farkle rules playable without rewriting the 3D picker.

## AI Behavior

The AI should be simple and legible, not optimal.

Decision policy:

- Always keep the highest-value safe scoring selection from the current roll.
- Bank if turn score is at least 700.
- Bank if banking would reach the target.
- Lower the bank threshold to 450 when ahead.
- Raise the threshold to 900 when behind by 1000 or more.
- Continue on hot dice unless banking wins immediately or the turn score is already very high.

The AI should run with short pauses between roll, keep, and bank decisions so the player can follow what happened.

## UI Design

The first screen after startup should be the playable Farkle table, not a marketing or landing page.

Required visible information:

- Human total score.
- AI total score.
- Target score.
- Current player.
- Current turn score.
- Available dice count.
- Latest roll values.
- Kept dice for the current turn.
- Available scoring groups for the latest roll.
- Clear bank/reroll/bust/hot-dice feedback.

The visual tone should be restrained medieval tavern dice:

- Dark table or parchment/felt surface.
- Clear dice values.
- Compact score panels.
- Large, obvious action buttons.

Do not recreate the old scriptorium folio UI in v0.

## Legacy Boundary

All old folio, ink, stain, row, reward, and campaign systems are out of the active Farkle route.

They may remain in the repository for future salvage, but they should not be required to start or complete a Farkle match.

Acceptable legacy references:

- `src/features/legacy/scriptorium.lua`
- legacy registration as `legacy_scriptorium`
- old docs and analysis files

Avoid new active dependencies from Farkle modules to:

- `src/gameplay/folio/*`
- old scriptorium layout/config schema
- reward tools
- campaign select flow

## Error Handling

The scoring and match modules should be defensive:

- Invalid dice values are ignored or rejected by pure functions.
- Attempting to keep an invalid selection returns `{ok = false, reason = ...}`.
- Banking with zero turn score is rejected.
- Rerolling before keeping a scoring selection is rejected.
- Bust clears turn score and passes the turn.
- AI must not hang if a roll has no scoring groups.

## Testing

Add focused tests before UI-heavy work:

- Scoring singles, triples, four/five/six of a kind, straight, and three pairs.
- Bust detection.
- Best scoring selections.
- Match turn flow: roll, keep, bank, pass.
- Bust clears turn score.
- Hot dice resets available dice to six.
- AI chooses a legal scoring selection and eventually banks or busts.

Existing legacy tests may be absent or failing because the refactor already removed many old files. The Farkle tests should be self-contained and should not require legacy scriptorium modules.

## Out Of Scope For V0

- Loaded dice.
- KCD2-style badges.
- Dice inventory.
- Wagers and groschen economy.
- Multiple opponents.
- Campaign progression.
- Scriptorium folios, ink, stains, and row placement.
- Engine3D changes.
- Perfect AI strategy.
- Final art pass.

## Success Criteria

The prototype succeeds when:

- Launching the game starts a playable Farkle match.
- The player can complete a full match against AI.
- Banking, rerolling, busting, and hot dice behave consistently.
- The scoring table is visible or inferable from the scoring group labels.
- The scriptorium remains available as legacy code but is no longer the active gameplay foundation.
- `src/engine3d/*` remains untouched by this work.

