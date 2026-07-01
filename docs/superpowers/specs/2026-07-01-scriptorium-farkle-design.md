# Scriptorium Farkle v0 Design

## Status

Approved direction from chat: build an hybrid between the current scriptorium folio loop and the push-your-luck dice structure of Kingdom Come: Deliverance II Farkle.

This design is for a focused prototype. It does not replace the folio, ink, row, stain, or wet-buffer systems already in the project. It adds a scoring/combination layer and a small set of tool-badges on top of them.

## Goal

Make each roll feel less like raw placement supply and more like a manuscript hand: the player reads dice patterns, chooses which result to preserve, then decides whether to dry the work or push for a stronger flourish.

The desired player question is:

"Do I dry this useful but modest hand now, or risk another throw for a cleaner, richer, more beautiful line?"

## Existing Context

The project already has:

- Physical dice in Love2D, configured through `src/data/dice_roll_schema.lua`.
- A folio model with wet buffer, ink drops, stains, row rules, and objective progress in `src/gameplay/folio/model.lua`.
- Turn helpers for push count, wet summary, seals, tools, and bust handling in `src/gameplay/folio/turn.lua`.
- Reward-tool data in `src/data/reward_tools.lua`, currently suitable for expansion into badge-like tools.
- Italian loaded-die source material in `C:\Users\Davide\Desktop\luck_laid_bare.xml`.

KCD2 references used for inspiration:

- Six-sided dice, hold/scoring decisions, score-and-continue, pass, bust, and hot-dice continuation.
- Loaded dice with different face probabilities.
- Badges that modify rules, rerolls, scoring, or dice count.

## Core Design

### Turn Flow

The turn keeps the current scriptorium structure:

1. Roll dice.
2. Select one or more dice results.
3. Use selected dice to place wet ink on valid folio cells.
4. Optional: claim a scriptorium hand if the selected or rolled dice form a known combination.
5. Choose to dry the wet buffer or push.
6. On push, reroll available dice within the folio's `reroll_max`.
7. On bust, discard wet work and add stains.

The main change is step 4. A placement can now carry a hand bonus, so a roll is evaluated both spatially and combinatorially.

### Wet Buffer As Unbanked Score

KCD2's unbanked turn score maps to the current wet buffer:

- Drying equals banking.
- Pushing keeps the wet buffer exposed.
- Bust discards the wet buffer and adds stains.
- Bigger hands are more tempting because they improve quality or resources, but they usually require committing more dice before drying.

This preserves the scriptorium fiction: unfinished ink is valuable, fragile, and dangerous to overwork.

### Scriptorium Hands

Hands should be few, readable, and thematic in v0:

| Hand | Dice Pattern | Effect |
| --- | --- | --- |
| Single Initial | one `1` or one `5` | small quality gain on dry |
| Pair Mark | two equal values | gain 1 seal, once per turn |
| Trinity | three equal values | quality gain based on value |
| Rubric | three values in sequence | recover 1 scarce ink on dry |
| Flourish | four or more equal values | quality gain and ignore next stain |
| Full Line | five-value straight or six-value straight | complete one dry bonus trigger, if any row was advanced |

The exact numeric values should stay modest for v0. The prototype is about deciding whether the layer feels good, not about final balance.

### Tool-Badges

Tools are the scriptorium version of KCD2 badges. They should be visible, limited-use, and easy to explain.

Initial v0 tools:

| Tool | Source Idea | Effect |
| --- | --- | --- |
| Spare Quill | extra die badge | add one temporary d6 to the next roll |
| Sand Shaker | anti-bust badge | once per folio, convert a bust into dry 1 wet placement and add no stain |
| Scraper Knife | existing reward tool | remove 1 stain or ignore the next stain |
| Ruling Cord | new formation badge | unlock Rubric as a valid hand for this folio |
| Gold Leaf | score multiplier badge | double the quality from the next Trinity or Flourish |
| Seal Press | reroll/support badge | spend 1 seal to reroll one chosen die |

Existing `extra_ink`, `scraper_knife`, and `steady_hand` can either be kept as separate rewards or rethemed into this tool-badge layer. For v0, prefer adding only the tools needed to test the loop.

### Loaded Dice

Loaded dice are not required for the first implementation step. The XML file can feed a later "dice catalog" once the hand system is fun with normal dice.

When added, a loaded die should have:

- `id`
- display name
- description
- face weights for 1-6
- optional tag, such as `odd`, `even`, `one`, `three`, `lucky`, `cursed`

The player should not need to understand all probabilities at once. Start with 3-5 named dice, then expand.

## Data Model

Add small, isolated data modules rather than growing `model.lua` directly:

- `src/data/folio_hands.lua`: definitions for v0 hand ids, names, patterns, and effects.
- `src/gameplay/folio/hands.lua`: pure evaluator for dice values and available hand definitions.
- `src/data/tool_badges.lua`: badge/tool definitions, uses, names, and effects.

The folio model should call into these modules through narrow functions:

- evaluate rolled/selected dice into hand candidates.
- apply a chosen hand effect to folio state.
- consume a tool-badge use and apply its effect.

This keeps tests simple and avoids making the already-large folio model harder to reason about.

## UI Design

The UI should not explain the whole system with long text. It should show:

- Current hand candidates near the dice tray.
- A small icon/name/effect preview for the best hand.
- Tool-badges as compact buttons with remaining uses.
- A clear dry/push risk display: wet count, pushes used, and stain consequence.
- Bust feedback that names what was lost.

The first playable version can be plain but must answer "why should I care about this roll?" before visual polish.

## Error Handling

The evaluator should be tolerant:

- Invalid dice values produce no hands.
- Empty selections produce no hand candidates.
- Tool use with no remaining uses returns a reason instead of mutating state.
- Locked or unavailable hands are hidden or marked unavailable, never applied silently.
- Bust recovery tools must run before wet buffer discard.

## Testing

Add focused Lua tests before UI work:

- Hand evaluator detects singles, pairs, triples, sequences, and full-line straights.
- Locked hands are not returned unless the right tool unlocks them.
- Drying with a hand applies the expected resource or quality effect.
- Bust discards wet buffer and adds stains as before.
- Sand Shaker or equivalent anti-bust tool prevents one bust and consumes a use.
- Existing folio flow tests still pass.

Balance tests can come later through the existing gameplay simulation tests.

## Out Of Scope For v0

- Opponent AI or tavern-style two-player Farkle.
- Full KCD2 scoring table.
- Importing every die from `luck_laid_bare.xml`.
- Final UI art for every tool.
- Long-term economy balance.
- New campaign structure.

## Success Criteria

The prototype succeeds if:

- A roll can generate at least one readable hand candidate.
- The player has a meaningful dry-or-push choice.
- Bust feels like losing wet manuscript work, not just failing a dice minigame.
- One or two tool-badges noticeably change a turn without overwhelming it.
- The current folio/ink/stain identity remains stronger than the borrowed Farkle structure.

