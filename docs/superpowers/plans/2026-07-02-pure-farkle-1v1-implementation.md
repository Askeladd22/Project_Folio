# Pure Farkle 1v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable pure Farkle 1v1 match against a simple AI, using the existing dice roll pipeline and leaving `src/engine3d/*` untouched.

**Architecture:** Add pure Farkle gameplay modules for scoring, match state, and AI decisions, then add `src/features/farkle.lua` as the active playable feature. `main.lua` keeps owning physical dice rolling and forwards settled values to the active dice-game feature instead of hard-coding the legacy scriptorium module.

**Tech Stack:** Love2D, Lua modules, existing `SettingsState.GameManager`, existing `scripts/test.ps1` Lua test runner.

---

## File Structure

- Create: `tests/farkle_scoring_test.lua`
  - Tests pure scoring groups, busts, best group ordering, and valid dice normalization.
- Create: `src/gameplay/farkle/scoring.lua`
  - Pure functions for available scoring groups from one roll.
- Create: `tests/farkle_match_test.lua`
  - Tests turn flow, bank, bust, hot dice, and invalid actions.
- Create: `src/gameplay/farkle/match.lua`
  - Pure match state for two players, available dice, turn score, bank/reroll/bust.
- Create: `tests/farkle_ai_test.lua`
  - Tests simple AI choices are legal and threshold-based.
- Create: `src/gameplay/farkle/ai.lua`
  - Simple deterministic AI decision policy.
- Create: `src/features/farkle.lua`
  - Love2D feature module for the playable table, buttons, AI timing, and dice callbacks.
- Modify: `main.lua`
  - Register `farkle`, forward dice callbacks to the active dice-game feature, keep `legacy_scriptorium`.
- Modify: `src/core/settings_state.lua`
  - Configure the default dice pool as six d6 for pure Farkle.
- Modify: `src/data/settings_schema.lua`
  - Route main menu New Game and Continue to `farkle`.
- Create: `tests/farkle_config_test.lua`
  - Tests default dice config is six d6.

## Task 1: Pure Scoring Module

**Files:**
- Create: `tests/farkle_scoring_test.lua`
- Create: `src/gameplay/farkle/scoring.lua`

- [ ] **Step 1: Write the failing scoring tests**

Create `tests/farkle_scoring_test.lua`:

```lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local Scoring = require("src.gameplay.farkle.scoring")

local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", message or "assert_eq failed", tostring(expected), tostring(actual)))
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "expected true")
    end
end

local function find_group(groups, kind)
    for _, group in ipairs(groups or {}) do
        if group.kind == kind then
            return group
        end
    end
    return nil
end

local function test_singles_score_ones_and_fives()
    local groups = Scoring.get_scoring_groups({1, 2, 5, 3})
    assert_eq(#groups, 2, "one and five should create two single scoring groups")
    assert_true(find_group(groups, "single_one") ~= nil, "single one group should exist")
    assert_true(find_group(groups, "single_five") ~= nil, "single five group should exist")
end

local function test_triples_and_kinds_score()
    local triple = find_group(Scoring.get_scoring_groups({3, 3, 3, 2, 4}), "three_kind_3")
    assert_true(triple ~= nil, "three threes should score")
    assert_eq(triple.score, 300, "three threes score")

    local ones = find_group(Scoring.get_scoring_groups({1, 1, 1, 2, 4}), "three_kind_1")
    assert_true(ones ~= nil, "three ones should score")
    assert_eq(ones.score, 1000, "three ones score")

    local four = find_group(Scoring.get_scoring_groups({6, 6, 6, 6, 2}), "four_kind_6")
    assert_true(four ~= nil, "four sixes should score")
    assert_eq(four.score, 1000, "four of a kind score")

    local five = find_group(Scoring.get_scoring_groups({2, 2, 2, 2, 2}), "five_kind_2")
    assert_true(five ~= nil, "five twos should score")
    assert_eq(five.score, 2000, "five of a kind score")
end

local function test_six_kind_straight_and_three_pairs()
    local six = find_group(Scoring.get_scoring_groups({4, 4, 4, 4, 4, 4}), "six_kind_4")
    assert_true(six ~= nil, "six fours should score")
    assert_eq(six.score, 3000, "six of a kind score")

    local straight = find_group(Scoring.get_scoring_groups({1, 2, 3, 4, 5, 6}), "straight")
    assert_true(straight ~= nil, "straight should score")
    assert_eq(straight.score, 2500, "straight score")

    local pairs = find_group(Scoring.get_scoring_groups({2, 2, 3, 3, 6, 6}), "three_pairs")
    assert_true(pairs ~= nil, "three pairs should score")
    assert_eq(pairs.score, 1500, "three pairs score")
end

local function test_bust_detection()
    assert_true(Scoring.is_bust({2, 3, 4, 6}), "2 3 4 6 should bust")
    assert_true(not Scoring.is_bust({2, 3, 4, 5}), "single five prevents bust")
end

local function test_best_group_prefers_score_then_dice_count()
    local best = Scoring.best_group({1, 2, 3, 4, 5, 6})
    assert_true(best ~= nil, "best group should exist")
    assert_eq(best.kind, "straight", "straight should outrank singles")
    assert_eq(best.dice_count, 6, "straight uses all dice")
end

local function test_table_roll_entries_keep_source_indices()
    local groups = Scoring.get_scoring_groups({
        {value = 1, index = 11},
        {value = 5, index = 12},
        {value = 2, index = 13},
    })
    local one = find_group(groups, "single_one")
    assert_true(one ~= nil, "single one should exist")
    assert_eq(one.dice[1].source_index, 11, "source index should be preserved")
end

local tests = {
    {name = "singles_score_ones_and_fives", fn = test_singles_score_ones_and_fives},
    {name = "triples_and_kinds_score", fn = test_triples_and_kinds_score},
    {name = "six_kind_straight_and_three_pairs", fn = test_six_kind_straight_and_three_pairs},
    {name = "bust_detection", fn = test_bust_detection},
    {name = "best_group_prefers_score_then_dice_count", fn = test_best_group_prefers_score_then_dice_count},
    {name = "table_roll_entries_keep_source_indices", fn = test_table_roll_entries_keep_source_indices},
}

local failed = 0
for _, test_case in ipairs(tests) do
    local ok, err = pcall(test_case.fn)
    if ok then
        print("ok - " .. test_case.name)
    else
        failed = failed + 1
        io.stderr:write("not ok - " .. test_case.name .. ": " .. tostring(err) .. "\n")
    end
end

if failed > 0 then
    error(string.format("%d test(s) failed", failed))
end

print(string.format("all tests passed (%d)", #tests))
```

- [ ] **Step 2: Run the scoring tests to verify failure**

Run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Expected: FAIL loading `src.gameplay.farkle.scoring`.

- [ ] **Step 3: Add the scoring module**

Create `src/gameplay/farkle/scoring.lua`:

```lua
local Scoring = {}

local TRIPLE_SCORES = {
    [1] = 1000,
    [2] = 200,
    [3] = 300,
    [4] = 400,
    [5] = 500,
    [6] = 600,
}

local function normalize_roll(values)
    local entries = {}
    for roll_pos, item in ipairs(values or {}) do
        local value = item
        local source_index = roll_pos
        if type(item) == "table" then
            value = item.value
            source_index = item.index or roll_pos
        end
        value = tonumber(value)
        if value then
            value = math.floor(value)
            if value >= 1 and value <= 6 then
                entries[#entries + 1] = {
                    roll_pos = roll_pos,
                    source_index = source_index,
                    value = value,
                }
            end
        end
    end
    return entries
end

local function copy_dice(dice)
    local out = {}
    for i, die in ipairs(dice or {}) do
        out[i] = {
            roll_pos = die.roll_pos,
            source_index = die.source_index,
            value = die.value,
        }
    end
    return out
end

local function build_counts(entries)
    local counts = {}
    local dice_by_value = {}
    for _, die in ipairs(entries) do
        local value = die.value
        counts[value] = (counts[value] or 0) + 1
        dice_by_value[value] = dice_by_value[value] or {}
        dice_by_value[value][#dice_by_value[value] + 1] = die
    end
    return counts, dice_by_value
end

local function make_group(kind, label, score, dice)
    local copied = copy_dice(dice)
    return {
        id = kind,
        kind = kind,
        label = label,
        score = score,
        dice = copied,
        dice_count = #copied,
    }
end

local function has_straight(counts)
    for value = 1, 6 do
        if (counts[value] or 0) ~= 1 then
            return false
        end
    end
    return true
end

local function collect_all_dice(dice_by_value)
    local out = {}
    for value = 1, 6 do
        for _, die in ipairs(dice_by_value[value] or {}) do
            out[#out + 1] = die
        end
    end
    return out
end

local function count_pairs(counts)
    local pairs = 0
    for value = 1, 6 do
        if (counts[value] or 0) == 2 then
            pairs = pairs + 1
        end
    end
    return pairs
end

local function kind_score(count, value)
    if count >= 6 then
        return 3000
    end
    if count == 5 then
        return 2000
    end
    if count == 4 then
        return 1000
    end
    return TRIPLE_SCORES[value] or (value * 100)
end

local function kind_name(count)
    if count >= 6 then
        return "six"
    end
    if count == 5 then
        return "five"
    end
    if count == 4 then
        return "four"
    end
    return "three"
end

local function kind_label(count, value)
    if count >= 6 then
        return "Six " .. tostring(value) .. "s"
    end
    if count == 5 then
        return "Five " .. tostring(value) .. "s"
    end
    if count == 4 then
        return "Four " .. tostring(value) .. "s"
    end
    return "Three " .. tostring(value) .. "s"
end

function Scoring.normalize_roll(values)
    return normalize_roll(values)
end

function Scoring.get_scoring_groups(values)
    local entries = normalize_roll(values)
    local counts, dice_by_value = build_counts(entries)
    local groups = {}

    if #entries == 6 and has_straight(counts) then
        groups[#groups + 1] = make_group("straight", "Straight 1-6", 2500, collect_all_dice(dice_by_value))
    end

    if #entries == 6 and count_pairs(counts) == 3 then
        groups[#groups + 1] = make_group("three_pairs", "Three pairs", 1500, collect_all_dice(dice_by_value))
    end

    for value = 1, 6 do
        local count = counts[value] or 0
        if count >= 3 then
            local used_count = math.min(count, 6)
            local dice = {}
            for i = 1, used_count do
                dice[i] = dice_by_value[value][i]
            end
            local prefix = kind_name(used_count)
            groups[#groups + 1] = make_group(
                prefix .. "_kind_" .. tostring(value),
                kind_label(used_count, value),
                kind_score(used_count, value),
                dice
            )
        elseif value == 1 or value == 5 then
            local score = value == 1 and 100 or 50
            local kind = value == 1 and "single_one" or "single_five"
            local label = value == 1 and "Single 1" or "Single 5"
            for _, die in ipairs(dice_by_value[value] or {}) do
                groups[#groups + 1] = make_group(kind, label, score, {die})
            end
        end
    end

    table.sort(groups, function(a, b)
        if a.score == b.score then
            if a.dice_count == b.dice_count then
                return a.kind < b.kind
            end
            return a.dice_count > b.dice_count
        end
        return a.score > b.score
    end)

    for i, group in ipairs(groups) do
        group.id = group.kind .. ":" .. tostring(i)
    end

    return groups
end

function Scoring.is_bust(values)
    return #Scoring.get_scoring_groups(values) == 0
end

function Scoring.best_group(values)
    local groups = Scoring.get_scoring_groups(values)
    return groups[1]
end

function Scoring.find_group(groups, group_id)
    for _, group in ipairs(groups or {}) do
        if group.id == group_id or group.kind == group_id then
            return group
        end
    end
    return nil
end

return Scoring
```

- [ ] **Step 4: Run scoring tests to verify pass**

Run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Expected: PASS for `farkle_scoring_test.lua`.

- [ ] **Step 5: Commit scoring module**

Run:

```powershell
rtk git add tests/farkle_scoring_test.lua src/gameplay/farkle/scoring.lua
rtk git -c user.name=Codex -c user.email=codex@example.com commit -m "Add pure Farkle scoring"
```

Expected: commit succeeds.

## Task 2: Match State Module

**Files:**
- Create: `tests/farkle_match_test.lua`
- Create: `src/gameplay/farkle/match.lua`

- [ ] **Step 1: Write the failing match tests**

Create `tests/farkle_match_test.lua`:

```lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local Match = require("src.gameplay.farkle.match")

local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", message or "assert_eq failed", tostring(expected), tostring(actual)))
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "expected true")
    end
end

local function test_keep_bank_and_pass_turn()
    local match = Match.new({target_score = 5000})
    local roll = match:applyRoll({1, 2, 3, 4, 2, 3})
    assert_true(roll.ok, "roll should apply")
    assert_eq(match.phase, "selecting", "scoring roll should enter selecting")
    local kept = match:keepGroup("single_one")
    assert_true(kept.ok, kept.reason)
    assert_eq(match.turn_score, 100, "single one should add turn score")
    assert_eq(match.available_dice, 5, "one kept die leaves five dice")
    local banked = match:bank()
    assert_true(banked.ok, banked.reason)
    assert_eq(match.players[1].score, 100, "human score should bank")
    assert_eq(match.current_player_index, 2, "turn should pass to AI")
    assert_eq(match.turn_score, 0, "turn score should reset")
end

local function test_bust_clears_turn_and_passes()
    local match = Match.new()
    match:applyRoll({1, 2, 3, 4, 2, 3})
    match:keepGroup("single_one")
    assert_eq(match.turn_score, 100, "precondition turn score")
    match:reroll()
    local result = match:applyRoll({2, 3, 4, 6})
    assert_true(result.ok, "bust roll should apply")
    assert_true(result.bust, "roll should bust")
    assert_eq(match.players[1].score, 0, "bust should not bank")
    assert_eq(match.turn_score, 0, "bust clears turn score")
    assert_eq(match.current_player_index, 2, "bust passes turn")
end

local function test_hot_dice_resets_available_dice()
    local match = Match.new()
    local result = match:applyRoll({1, 2, 3, 4, 5, 6})
    assert_true(result.ok, "roll should apply")
    local kept = match:keepGroup("straight")
    assert_true(kept.ok, kept.reason)
    assert_true(kept.hot_dice, "straight should use all dice and trigger hot dice")
    assert_eq(match.available_dice, 6, "hot dice resets available dice")
    assert_eq(match.turn_score, 2500, "straight adds score")
end

local function test_rejects_invalid_actions()
    local match = Match.new()
    local banked = match:bank()
    assert_true(not banked.ok, "cannot bank zero score")
    local keep = match:keepGroup("single_one")
    assert_true(not keep.ok, "cannot keep before roll")
    match:applyRoll({1, 2, 3, 4, 2, 3})
    local missing = match:keepGroup("straight")
    assert_true(not missing.ok, "cannot keep unavailable group")
end

local function test_game_over_when_target_reached()
    local match = Match.new({target_score = 100})
    match:applyRoll({1, 2, 3, 4, 2, 3})
    match:keepGroup("single_one")
    local banked = match:bank()
    assert_true(banked.ok, banked.reason)
    assert_eq(match.phase, "game_over", "target should end match")
    assert_eq(match.winner_id, "human", "human should win")
end

local tests = {
    {name = "keep_bank_and_pass_turn", fn = test_keep_bank_and_pass_turn},
    {name = "bust_clears_turn_and_passes", fn = test_bust_clears_turn_and_passes},
    {name = "hot_dice_resets_available_dice", fn = test_hot_dice_resets_available_dice},
    {name = "rejects_invalid_actions", fn = test_rejects_invalid_actions},
    {name = "game_over_when_target_reached", fn = test_game_over_when_target_reached},
}

local failed = 0
for _, test_case in ipairs(tests) do
    local ok, err = pcall(test_case.fn)
    if ok then
        print("ok - " .. test_case.name)
    else
        failed = failed + 1
        io.stderr:write("not ok - " .. test_case.name .. ": " .. tostring(err) .. "\n")
    end
end

if failed > 0 then
    error(string.format("%d test(s) failed", failed))
end

print(string.format("all tests passed (%d)", #tests))
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Expected: FAIL loading `src.gameplay.farkle.match`.

- [ ] **Step 3: Add the match module**

Create `src/gameplay/farkle/match.lua`:

```lua
local Scoring = require("src.gameplay.farkle.scoring")

local Match = {}
Match.__index = Match

local function default_players()
    return {
        {id = "human", name = "You", score = 0, is_ai = false},
        {id = "ai", name = "Opponent", score = 0, is_ai = true},
    }
end

local function clone_group(group)
    if type(group) ~= "table" then
        return nil
    end
    local dice = {}
    for i, die in ipairs(group.dice or {}) do
        dice[i] = {
            roll_pos = die.roll_pos,
            source_index = die.source_index,
            value = die.value,
        }
    end
    return {
        id = group.id,
        kind = group.kind,
        label = group.label,
        score = group.score,
        dice = dice,
        dice_count = group.dice_count,
    }
end

local function clone_groups(groups)
    local out = {}
    for i, group in ipairs(groups or {}) do
        out[i] = clone_group(group)
    end
    return out
end

function Match.new(opts)
    local options = opts or {}
    local self = setmetatable({
        target_score = math.max(100, math.floor(tonumber(options.target_score) or 5000)),
        players = options.players or default_players(),
        current_player_index = 1,
        phase = "awaiting_roll",
        turn_score = 0,
        available_dice = 6,
        latest_roll = {},
        latest_groups = {},
        kept_dice = {},
        message = "Roll the dice.",
        winner_id = nil,
        last_event = nil,
    }, Match)
    return self
end

function Match:getCurrentPlayer()
    return self.players[self.current_player_index]
end

function Match:isCurrentPlayerAI()
    local player = self:getCurrentPlayer()
    return player and player.is_ai and true or false
end

function Match:passTurn(reason)
    self.current_player_index = self.current_player_index == 1 and 2 or 1
    self.phase = "awaiting_roll"
    self.turn_score = 0
    self.available_dice = 6
    self.latest_roll = {}
    self.latest_groups = {}
    self.kept_dice = {}
    self.last_event = reason or "pass"
    self.message = (self:getCurrentPlayer().name or "Player") .. " to roll."
end

function Match:applyRoll(values)
    if self.phase ~= "awaiting_roll" then
        return {ok = false, reason = "not_awaiting_roll"}
    end

    self.latest_roll = Scoring.normalize_roll(values)
    self.latest_groups = Scoring.get_scoring_groups(values)

    if #self.latest_groups == 0 then
        local player = self:getCurrentPlayer()
        local busted_name = player and player.name or "Player"
        self:passTurn("bust")
        self.message = busted_name .. " busts."
        return {ok = true, bust = true, groups = {}}
    end

    self.phase = "selecting"
    self.message = "Choose dice to keep."
    return {ok = true, bust = false, groups = clone_groups(self.latest_groups)}
end

function Match:keepGroup(group_id)
    if self.phase ~= "selecting" then
        return {ok = false, reason = "not_selecting"}
    end

    local group = Scoring.find_group(self.latest_groups, group_id)
    if not group then
        return {ok = false, reason = "group_not_available"}
    end

    self.turn_score = self.turn_score + group.score
    for _, die in ipairs(group.dice or {}) do
        self.kept_dice[#self.kept_dice + 1] = {
            value = die.value,
            source_index = die.source_index,
            score_group = group.kind,
        }
    end

    self.available_dice = self.available_dice - math.max(1, math.floor(tonumber(group.dice_count) or 1))
    local hot_dice = false
    if self.available_dice <= 0 then
        self.available_dice = 6
        hot_dice = true
    end

    self.latest_groups = {}
    self.phase = "can_bank_or_roll"
    self.last_event = hot_dice and "hot_dice" or "keep"
    self.message = group.label .. " for " .. tostring(group.score) .. "."

    return {
        ok = true,
        group = clone_group(group),
        hot_dice = hot_dice,
        turn_score = self.turn_score,
        available_dice = self.available_dice,
    }
end

function Match:reroll()
    if self.phase ~= "can_bank_or_roll" then
        return {ok = false, reason = "not_ready_to_reroll"}
    end
    if self.turn_score <= 0 then
        return {ok = false, reason = "no_turn_score"}
    end
    self.phase = "awaiting_roll"
    self.latest_roll = {}
    self.latest_groups = {}
    self.last_event = "reroll"
    self.message = "Rolling " .. tostring(self.available_dice) .. " dice."
    return {ok = true, dice_count = self.available_dice}
end

function Match:bank()
    if self.phase ~= "can_bank_or_roll" then
        return {ok = false, reason = "not_ready_to_bank"}
    end
    if self.turn_score <= 0 then
        return {ok = false, reason = "no_turn_score"}
    end

    local player = self:getCurrentPlayer()
    player.score = player.score + self.turn_score
    local banked_score = self.turn_score
    self.last_event = "bank"
    self.message = (player.name or "Player") .. " banks " .. tostring(banked_score) .. "."

    if player.score >= self.target_score then
        self.phase = "game_over"
        self.winner_id = player.id
        self.turn_score = 0
        self.latest_roll = {}
        self.latest_groups = {}
        return {ok = true, banked = banked_score, winner_id = player.id}
    end

    self:passTurn("bank")
    return {ok = true, banked = banked_score}
end

function Match:snapshot()
    return {
        target_score = self.target_score,
        players = {
            {id = self.players[1].id, name = self.players[1].name, score = self.players[1].score, is_ai = self.players[1].is_ai},
            {id = self.players[2].id, name = self.players[2].name, score = self.players[2].score, is_ai = self.players[2].is_ai},
        },
        current_player_index = self.current_player_index,
        phase = self.phase,
        turn_score = self.turn_score,
        available_dice = self.available_dice,
        latest_roll = Scoring.normalize_roll(self.latest_roll),
        latest_groups = clone_groups(self.latest_groups),
        kept_dice = self.kept_dice,
        winner_id = self.winner_id,
        message = self.message,
        last_event = self.last_event,
    }
end

return Match
```

- [ ] **Step 4: Run match tests**

Run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Expected: PASS for scoring and match tests.

- [ ] **Step 5: Commit match module**

Run:

```powershell
rtk git add tests/farkle_match_test.lua src/gameplay/farkle/match.lua
rtk git -c user.name=Codex -c user.email=codex@example.com commit -m "Add Farkle match flow"
```

Expected: commit succeeds.

## Task 3: Simple AI Module

**Files:**
- Create: `tests/farkle_ai_test.lua`
- Create: `src/gameplay/farkle/ai.lua`

- [ ] **Step 1: Write failing AI tests**

Create `tests/farkle_ai_test.lua`:

```lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local Match = require("src.gameplay.farkle.match")
local Ai = require("src.gameplay.farkle.ai")

local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", message or "assert_eq failed", tostring(expected), tostring(actual)))
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "expected true")
    end
end

local function make_ai_match()
    local match = Match.new({target_score = 5000})
    match.current_player_index = 2
    return match
end

local function test_ai_keeps_best_group_after_roll()
    local match = make_ai_match()
    match:applyRoll({1, 2, 3, 4, 5, 6})
    local decision = Ai.decide(match)
    assert_eq(decision.kind, "keep", "AI should keep after scoring roll")
    assert_eq(decision.group_kind, "straight", "AI should keep best group")
end

local function test_ai_banks_at_threshold()
    local match = make_ai_match()
    match.phase = "can_bank_or_roll"
    match.turn_score = 700
    match.available_dice = 3
    local decision = Ai.decide(match)
    assert_eq(decision.kind, "bank", "AI should bank at base threshold")
end

local function test_ai_rerolls_below_threshold()
    local match = make_ai_match()
    match.phase = "can_bank_or_roll"
    match.turn_score = 300
    match.available_dice = 5
    local decision = Ai.decide(match)
    assert_eq(decision.kind, "reroll", "AI should continue below threshold")
    assert_eq(decision.dice_count, 5, "AI should reroll available dice")
end

local function test_ai_banks_if_it_wins()
    local match = make_ai_match()
    match.players[2].score = 4900
    match.phase = "can_bank_or_roll"
    match.turn_score = 100
    local decision = Ai.decide(match)
    assert_eq(decision.kind, "bank", "AI should bank a winning turn")
end

local tests = {
    {name = "ai_keeps_best_group_after_roll", fn = test_ai_keeps_best_group_after_roll},
    {name = "ai_banks_at_threshold", fn = test_ai_banks_at_threshold},
    {name = "ai_rerolls_below_threshold", fn = test_ai_rerolls_below_threshold},
    {name = "ai_banks_if_it_wins", fn = test_ai_banks_if_it_wins},
}

local failed = 0
for _, test_case in ipairs(tests) do
    local ok, err = pcall(test_case.fn)
    if ok then
        print("ok - " .. test_case.name)
    else
        failed = failed + 1
        io.stderr:write("not ok - " .. test_case.name .. ": " .. tostring(err) .. "\n")
    end
end

if failed > 0 then
    error(string.format("%d test(s) failed", failed))
end

print(string.format("all tests passed (%d)", #tests))
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Expected: FAIL loading `src.gameplay.farkle.ai`.

- [ ] **Step 3: Add AI implementation**

Create `src/gameplay/farkle/ai.lua`:

```lua
local Ai = {}

local function get_scores(match)
    local ai = match and match.players and match.players[2] or {score = 0}
    local human = match and match.players and match.players[1] or {score = 0}
    return tonumber(ai.score) or 0, tonumber(human.score) or 0
end

function Ai.bank_threshold(match)
    local ai_score, human_score = get_scores(match)
    if ai_score >= human_score then
        return 450
    end
    if human_score - ai_score >= 1000 then
        return 900
    end
    return 700
end

function Ai.decide(match)
    if type(match) ~= "table" then
        return {kind = "wait", reason = "missing_match"}
    end

    if match.phase == "awaiting_roll" then
        return {kind = "roll", dice_count = match.available_dice or 6}
    end

    if match.phase == "selecting" then
        local group = match.latest_groups and match.latest_groups[1] or nil
        if not group then
            return {kind = "wait", reason = "no_group"}
        end
        return {
            kind = "keep",
            group_id = group.id,
            group_kind = group.kind,
            score = group.score,
        }
    end

    if match.phase == "can_bank_or_roll" then
        local player = match:getCurrentPlayer()
        local projected = (tonumber(player and player.score) or 0) + (tonumber(match.turn_score) or 0)
        if projected >= (tonumber(match.target_score) or 5000) then
            return {kind = "bank", reason = "wins"}
        end
        if (tonumber(match.turn_score) or 0) >= Ai.bank_threshold(match) then
            return {kind = "bank", reason = "threshold"}
        end
        return {kind = "reroll", dice_count = match.available_dice or 6}
    end

    return {kind = "wait", reason = "unsupported_phase"}
end

return Ai
```

- [ ] **Step 4: Run AI tests**

Run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Expected: PASS for scoring, match, and AI tests.

- [ ] **Step 5: Commit AI module**

Run:

```powershell
rtk git add tests/farkle_ai_test.lua src/gameplay/farkle/ai.lua
rtk git -c user.name=Codex -c user.email=codex@example.com commit -m "Add simple Farkle AI"
```

Expected: commit succeeds.

## Task 4: Farkle Feature UI

**Files:**
- Create: `src/features/farkle.lua`

- [ ] **Step 1: Create the feature module**

Create `src/features/farkle.lua`:

```lua
local Core = require("src.core.settings_state")
local Match = require("src.gameplay.farkle.match")
local Ai = require("src.gameplay.farkle.ai")
local UiText = require("src.features.ui_text")

local RuntimeUI = Core
local AudioManager = Core.AudioManager
local Navigation = Core.GameManager.Navigation
local UiMath = UiText.Math
local love = rawget(_G, "love")

local Farkle = {
    uses_dice_tray = true,
    onRollRequest = nil,
    dice_results = {},
    selected_die = nil,
    state = "waiting",
}

local buttons = {}
local fonts = {}
local ai_delay = 0
local message = "Roll the dice."
local message_timer = 0

local function set_message(text, duration)
    message = text or ""
    message_timer = tonumber(duration) or 2.0
end

local function ensure_fonts()
    if fonts.title then
        return
    end
    fonts.title = love.graphics.newFont(34)
    fonts.large = love.graphics.newFont(26)
    fonts.body = love.graphics.newFont(18)
    fonts.small = love.graphics.newFont(14)
end

local function normalize_d6_values(values)
    local out = {}
    for _, item in ipairs(values or {}) do
        local value = item
        local sides = 6
        local kind = "d6"
        local index = nil
        if type(item) == "table" then
            value = item.value
            sides = item.sides or 6
            kind = item.kind or "d6"
            index = item.index
        end
        if kind == "d6" or math.floor(tonumber(sides) or 6) == 6 then
            out[#out + 1] = {
                value = math.max(1, math.min(6, math.floor(tonumber(value) or 1))),
                sides = 6,
                kind = "d6",
                index = index,
            }
        end
    end
    return out
end

local function add_button(id, label, x, y, w, h, enabled, action)
    buttons[#buttons + 1] = {
        id = id,
        label = label,
        x = x,
        y = y,
        w = w,
        h = h,
        enabled = enabled and true or false,
        action = action,
    }
end

local function roll_now()
    if Farkle.match.phase ~= "awaiting_roll" then
        return
    end
    if type(Farkle.onRollRequest) ~= "function" then
        set_message("Dice roller unavailable.", 2)
        return
    end
    Farkle.state = "rolling"
    Farkle.dice_results = {}
    Farkle.selected_die = nil
    Farkle.onRollRequest(Farkle.match.available_dice)
end

local function keep_group(group_id)
    local result = Farkle.match:keepGroup(group_id)
    if result.ok then
        AudioManager.play_ui("confirm")
        set_message(Farkle.match.message, result.hot_dice and 2.2 or 1.6)
        if Farkle.match:isCurrentPlayerAI() then
            ai_delay = 0.9
        end
    else
        AudioManager.play_ui("back")
        set_message("Cannot keep that group: " .. tostring(result.reason), 1.8)
    end
end

local function bank_turn()
    local result = Farkle.match:bank()
    if result.ok then
        AudioManager.play_ui("confirm")
        set_message(Farkle.match.message, 2)
        ai_delay = Farkle.match:isCurrentPlayerAI() and 1.0 or 0.7
    else
        AudioManager.play_ui("back")
        set_message("Cannot bank: " .. tostring(result.reason), 1.8)
    end
end

local function reroll_turn()
    local result = Farkle.match:reroll()
    if result.ok then
        roll_now()
    else
        AudioManager.play_ui("back")
        set_message("Cannot reroll: " .. tostring(result.reason), 1.8)
    end
end

local function restart_match()
    Farkle.match = Match.new({target_score = 5000})
    Farkle.dice_results = {}
    Farkle.selected_die = nil
    Farkle.state = "waiting"
    ai_delay = 0
    set_message("New match. Roll the dice.", 2)
end

local function go_main_menu()
    Navigation.go("main_menu")
end

local function run_ai_step()
    if not Farkle.match or Farkle.match.phase == "game_over" then
        return
    end
    if not Farkle.match:isCurrentPlayerAI() then
        return
    end
    if Farkle.state == "rolling" then
        return
    end

    local decision = Ai.decide(Farkle.match)
    if decision.kind == "roll" then
        roll_now()
    elseif decision.kind == "keep" then
        keep_group(decision.group_id)
    elseif decision.kind == "bank" then
        bank_turn()
    elseif decision.kind == "reroll" then
        reroll_turn()
    end
end

function Farkle:enter()
    ensure_fonts()
    restart_match()
end

function Farkle:exit()
end

function Farkle:update(dt)
    if message_timer > 0 then
        message_timer = math.max(0, message_timer - (dt or 0))
    end
    if self.match and self.match:isCurrentPlayerAI() then
        ai_delay = math.max(0, ai_delay - (dt or 0))
        if ai_delay <= 0 then
            ai_delay = 0.8
            run_ai_step()
        end
    end
end

function Farkle:onDiceSettled(values)
    local d6_values = normalize_d6_values(values)
    self.dice_results = d6_values
    self.state = "waiting"
    local result = self.match:applyRoll(d6_values)
    if result.ok and result.bust then
        AudioManager.play_ui("back")
        set_message(self.match.message, 2.2)
        ai_delay = self.match:isCurrentPlayerAI() and 1.0 or 0
        return
    end
    if result.ok then
        AudioManager.play_ui("move")
        set_message(self.match.message, 1.6)
        ai_delay = self.match:isCurrentPlayerAI() and 0.9 or 0
    else
        set_message("Roll rejected: " .. tostring(result.reason), 2)
    end
end

local function draw_panel(rect, fill, line)
    love.graphics.setColor(fill[1], fill[2], fill[3], fill[4] or 1)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 8, 8)
    love.graphics.setColor(line[1], line[2], line[3], line[4] or 1)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 8, 8)
end

local function draw_button(button)
    local hover = UiMath.point_in_rect(Farkle.mouse_x or -1, Farkle.mouse_y or -1, button)
    local enabled = button.enabled
    local fill = enabled and (hover and {0.38, 0.28, 0.16, 0.96} or {0.28, 0.20, 0.12, 0.92}) or {0.12, 0.10, 0.08, 0.70}
    local line = enabled and {0.86, 0.66, 0.36, 0.88} or {0.42, 0.34, 0.25, 0.60}
    draw_panel(button, fill, line)
    love.graphics.setFont(fonts.body)
    love.graphics.setColor(enabled and {0.98, 0.92, 0.78, 1} or {0.60, 0.56, 0.50, 1})
    love.graphics.printf(button.label, button.x + 8, button.y + (button.h - fonts.body:getHeight()) * 0.5, button.w - 16, "center")
end

local function values_text(values)
    local parts = {}
    for _, die in ipairs(values or {}) do
        parts[#parts + 1] = tostring(die.value or die)
    end
    if #parts == 0 then
        return "-"
    end
    return table.concat(parts, "  ")
end

function Farkle:draw()
    ensure_fonts()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    buttons = {}
    self.mouse_x, self.mouse_y = love.mouse.getPosition()

    love.graphics.setColor(0.055, 0.040, 0.030, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(0.20, 0.12, 0.055, 0.92)
    love.graphics.rectangle("fill", 0, h * 0.58, w, h * 0.42)

    love.graphics.setFont(fonts.title)
    love.graphics.setColor(0.94, 0.76, 0.38, 1)
    love.graphics.printf("Farkle", 0, 28, w, "center")

    local margin = 42
    local score_w = math.min(430, (w - margin * 3) * 0.5)
    local score_h = 118
    local human = self.match.players[1]
    local ai = self.match.players[2]
    local current = self.match:getCurrentPlayer()

    draw_panel({x = margin, y = 92, w = score_w, h = score_h}, {0.12, 0.09, 0.06, 0.90}, {0.58, 0.42, 0.24, 0.70})
    draw_panel({x = w - margin - score_w, y = 92, w = score_w, h = score_h}, {0.12, 0.09, 0.06, 0.90}, {0.58, 0.42, 0.24, 0.70})

    love.graphics.setFont(fonts.large)
    love.graphics.setColor(current.id == "human" and {0.98, 0.88, 0.52, 1} or {0.82, 0.76, 0.68, 1})
    love.graphics.printf("You", margin, 112, score_w, "center")
    love.graphics.printf(tostring(human.score), margin, 152, score_w, "center")
    love.graphics.setColor(current.id == "ai" and {0.98, 0.88, 0.52, 1} or {0.82, 0.76, 0.68, 1})
    love.graphics.printf("Opponent", w - margin - score_w, 112, score_w, "center")
    love.graphics.printf(tostring(ai.score), w - margin - score_w, 152, score_w, "center")

    love.graphics.setFont(fonts.body)
    love.graphics.setColor(0.90, 0.84, 0.72, 1)
    love.graphics.printf("Target " .. tostring(self.match.target_score), 0, 222, w, "center")
    love.graphics.printf("Turn: " .. tostring(current.name) .. "   Turn score: " .. tostring(self.match.turn_score) .. "   Dice: " .. tostring(self.match.available_dice), 0, 252, w, "center")

    love.graphics.setFont(fonts.large)
    love.graphics.setColor(0.96, 0.90, 0.78, 1)
    love.graphics.printf("Roll: " .. values_text(self.dice_results), 0, 310, w, "center")
    love.graphics.setFont(fonts.body)
    love.graphics.printf("Kept: " .. values_text(self.match.kept_dice), 0, 352, w, "center")

    if self.match.phase == "game_over" then
        local winner = self.match.winner_id == "human" and "You win" or "Opponent wins"
        love.graphics.setFont(fonts.large)
        love.graphics.setColor(0.98, 0.82, 0.42, 1)
        love.graphics.printf(winner, 0, 410, w, "center")
    elseif message ~= "" then
        love.graphics.setFont(fonts.body)
        love.graphics.setColor(0.88, 0.80, 0.68, 1)
        love.graphics.printf(message, 0, 408, w, "center")
    end

    local action_y = h - 122
    local button_w = 190
    local button_h = 54
    local gap = 18
    local total_w = button_w * 4 + gap * 3
    local start_x = (w - total_w) * 0.5
    local human_turn = current.id == "human"

    add_button("roll", "ROLL", start_x, action_y, button_w, button_h, human_turn and self.match.phase == "awaiting_roll", roll_now)
    add_button("reroll", "REROLL", start_x + (button_w + gap), action_y, button_w, button_h, human_turn and self.match.phase == "can_bank_or_roll", reroll_turn)
    add_button("bank", "BANK", start_x + (button_w + gap) * 2, action_y, button_w, button_h, human_turn and self.match.phase == "can_bank_or_roll", bank_turn)
    add_button("restart", "RESTART", start_x + (button_w + gap) * 3, action_y, button_w, button_h, true, restart_match)

    local group_y = 462
    local group_w = 230
    local group_h = 44
    local group_gap = 12
    local max_per_row = math.max(1, math.floor((w - margin * 2) / (group_w + group_gap)))
    for i, group in ipairs(self.match.latest_groups or {}) do
        local col = (i - 1) % max_per_row
        local row = math.floor((i - 1) / max_per_row)
        local x = margin + col * (group_w + group_gap)
        local y = group_y + row * (group_h + group_gap)
        add_button("group:" .. group.id, group.label .. " +" .. tostring(group.score), x, y, group_w, group_h, human_turn and self.match.phase == "selecting", function()
            keep_group(group.id)
        end)
    end

    add_button("menu", "MENU", w - margin - 130, h - 62, 130, 38, true, go_main_menu)

    for _, button in ipairs(buttons) do
        draw_button(button)
    end
end

function Farkle:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end
    for _, hit in ipairs(buttons) do
        if hit.enabled and UiMath.point_in_rect(x, y, hit) then
            hit.action()
            return
        end
    end
end

function Farkle:keypressed(key)
    if key == "space" and self.match.phase == "awaiting_roll" and not self.match:isCurrentPlayerAI() then
        roll_now()
    elseif key == "b" and self.match.phase == "can_bank_or_roll" and not self.match:isCurrentPlayerAI() then
        bank_turn()
    elseif key == "r" and self.match.phase == "can_bank_or_roll" and not self.match:isCurrentPlayerAI() then
        reroll_turn()
    elseif key == "escape" then
        go_main_menu()
    end
end

return Farkle
```

- [ ] **Step 2: Run Lua syntax/tests**

Run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Expected: existing Farkle pure tests still pass. This does not require loading `src/features/farkle.lua` because Love2D globals are not available under plain Lua.

- [ ] **Step 3: Commit Farkle feature**

Run:

```powershell
rtk git add src/features/farkle.lua
rtk git -c user.name=Codex -c user.email=codex@example.com commit -m "Add playable Farkle feature"
```

Expected: commit succeeds.

## Task 5: Wire Farkle Into Boot And Dice Pipeline

**Files:**
- Modify: `main.lua`
- Modify: `src/data/settings_schema.lua`
- Modify: `src/core/settings_state.lua`
- Create: `tests/farkle_config_test.lua`

- [ ] **Step 1: Add failing dice config test**

Create `tests/farkle_config_test.lua`:

```lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local SettingsState = require("src.core.settings_state")

local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", message or "assert_eq failed", tostring(expected), tostring(actual)))
    end
end

local function test_default_dice_pool_is_six_d6()
    local config = SettingsState.DiceConfig.load()
    local d6_count = 0
    local d8_count = 0
    for _, entry in ipairs(config.pool or {}) do
        if entry.kind == "d6" then
            d6_count = d6_count + entry.count
        elseif entry.kind == "d8" then
            d8_count = d8_count + entry.count
        end
    end
    assert_eq(d6_count, 6, "pure Farkle should use six d6")
    assert_eq(d8_count, 0, "pure Farkle should not spawn d8 dice")
end

local tests = {
    {name = "default_dice_pool_is_six_d6", fn = test_default_dice_pool_is_six_d6},
}

local failed = 0
for _, test_case in ipairs(tests) do
    local ok, err = pcall(test_case.fn)
    if ok then
        print("ok - " .. test_case.name)
    else
        failed = failed + 1
        io.stderr:write("not ok - " .. test_case.name .. ": " .. tostring(err) .. "\n")
    end
end

if failed > 0 then
    error(string.format("%d test(s) failed", failed))
end

print(string.format("all tests passed (%d)", #tests))
```

- [ ] **Step 2: Run test to verify failure**

Run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Expected: FAIL because the current default pool is not six d6.

- [ ] **Step 3: Change default dice pool to six d6**

In `src/core/settings_state.lua`, inside `DefaultDiceSchema.roll.pool`, replace:

```lua
        pool = {
            {kind = "d6", count = 4, sides = 6},
            {kind = "d8", count = 3, sides = 8},
        },
```

with:

```lua
        pool = {
            {kind = "d6", count = 6, sides = 6},
        },
```

- [ ] **Step 4: Route menu to Farkle**

In `src/data/settings_schema.lua`, inside `ui_screens.main_menu.flow`, replace:

```lua
                navigation_new_game = "campaign_select",
                navigation_continue = "legacy_scriptorium",
```

with:

```lua
                navigation_new_game = "farkle",
                navigation_continue = "farkle",
```

Leave `ui_screens.campaign_select.flow.campaign_module = "legacy_scriptorium"` unchanged so the old route remains available if called directly.

- [ ] **Step 5: Add active dice-game helpers in `main.lua`**

In `main.lua`, after the existing local declarations:

```lua
local main_menu_module = nil
local run_module = nil
local scriptorium = nil
local settings_module = nil
local game_manager = nil
local app_events = nil
```

add:

```lua
local farkle_module = nil
```

Replace the whole `is_scriptorium_active` function with:

```lua
local function get_active_dice_game()
    local current = game_manager and game_manager.current or nil
    if current and current.uses_dice_tray then
        return current
    end
    return nil
end

local function is_scriptorium_active()
    return get_active_dice_game() ~= nil
end
```

The function name stays unchanged to keep the surrounding tray code small in this pass.

- [ ] **Step 6: Generalize usable dice map in `main.lua`**

In `main.lua`, replace the whole `get_usable_dice_map` function with:

```lua
local function get_usable_dice_map()
    local usable = {}
    local active = get_active_dice_game()
    if not active then
        return usable
    end
    if type(active.dice_results) ~= "table" then
        return usable
    end
    for _, die_state in ipairs(active.dice_results) do
        local idx = tonumber(die_state and die_state.index)
        if idx then
            idx = math.floor(idx)
            if idx >= 1 and idx <= #dice and (not die_state.used) and (not die_state.unusable) then
                usable[idx] = true
            end
        end
    end

    local selected_chip = tonumber(active.selected_die)
    if selected_chip then
        selected_chip = math.floor(selected_chip)
        local selected_state = active.dice_results[selected_chip]
        local selected_idx = tonumber(selected_state and selected_state.index)
        if selected_idx then
            selected_idx = math.floor(selected_idx)
            if selected_idx >= 1 and selected_idx <= #dice and (not selected_state.used) then
                usable[selected_idx] = true
            end
        end
    end

    return usable
end
```

- [ ] **Step 7: Register Farkle in `main.lua`**

In `load_feature_modules`, after:

```lua
    main_menu_module = require("src.features.main_menu")
    run_module = require("src.features.run").module
    scriptorium = Scriptorium
    settings_module = require("src.features.settings")
```

add:

```lua
    farkle_module = require("src.features.farkle")
```

In the returned table, add:

```lua
        farkle = farkle_module,
```

In `setup_game_manager`, after:

```lua
    game_manager:register("campaign_select", modules.campaign_select)
```

add:

```lua
    game_manager:register("farkle", modules.farkle)
```

- [ ] **Step 8: Forward roll callbacks to both active dice features**

In `love.load`, replace:

```lua
    setup_game_manager(load_feature_modules())
    register_execution_order_hooks()
    configure_navigation()
    Scriptorium.onRollRequest = function(max_dice, roll_indices)
        rollAllDice(max_dice, roll_indices)
    end
```

with:

```lua
    local modules = load_feature_modules()
    setup_game_manager(modules)
    register_execution_order_hooks()
    configure_navigation()
    modules.scriptorium.onRollRequest = function(max_dice, roll_indices)
        rollAllDice(max_dice, roll_indices)
    end
    modules.farkle.onRollRequest = function(max_dice, roll_indices)
        rollAllDice(max_dice, roll_indices)
    end
```

- [ ] **Step 9: Forward rolling state and settled dice to active dice game**

In `rollAllDice`, replace:

```lua
    if Scriptorium then
        Scriptorium.state = "rolling"
    end
```

with:

```lua
    local active = get_active_dice_game()
    if active then
        active.state = "rolling"
    end
```

In `onDiceSettled`, replace:

```lua
    if Scriptorium.onDiceSettled then
        Scriptorium:onDiceSettled(values)
    end
```

with:

```lua
    local active = get_active_dice_game()
    if active and active.onDiceSettled then
        active:onDiceSettled(values)
    end
```

- [ ] **Step 10: Run pure tests**

Run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Expected: PASS for scoring, match, AI, and config tests.

- [ ] **Step 11: Commit wiring**

Run:

```powershell
rtk git add main.lua src/data/settings_schema.lua src/core/settings_state.lua tests/farkle_config_test.lua
rtk git -c user.name=Codex -c user.email=codex@example.com commit -m "Wire Farkle as the active dice game"
```

Expected: commit succeeds.

## Task 6: Runtime Verification

**Files:**
- No planned code changes unless verification exposes a concrete failure.

- [ ] **Step 1: Run all Lua tests**

Run:

```powershell
rtk powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
```

Expected: every Farkle test prints `all tests passed`.

- [ ] **Step 2: Verify engine3d was not touched**

Run:

```powershell
rtk git diff --name-only HEAD~4..HEAD
```

Expected: no path under `src/engine3d/` appears.

- [ ] **Step 3: Smoke-run Love2D briefly**

Run:

```powershell
rtk love .
```

Expected: game launches. From the main menu, New Game opens Farkle. Player can roll, keep a scoring group, bank or reroll, and the AI takes its turn.

- [ ] **Step 4: Check worktree**

Run:

```powershell
rtk git status --short
```

Expected: only intentional files are modified. Existing unrelated dirty files must not be reverted.

- [ ] **Step 5: Final summary**

Report:

- Tests run and results.
- Whether Love2D launched.
- Whether `src/engine3d/*` stayed untouched.
- Commits created.

## Self-Review

Spec coverage:

- Pure Farkle scoring is covered by Task 1.
- 1v1 match state, banking, bust, reroll, and hot dice are covered by Task 2.
- Simple AI is covered by Task 3.
- Playable UI is covered by Task 4.
- Active Farkle routing and dice callbacks are covered by Task 5.
- Six d6 configuration is covered by Task 5.
- Runtime and no-engine3d verification is covered by Task 6.

Placeholder scan:

- The plan contains no unresolved placeholder markers.
- Each created source file has concrete code.
- Each test step includes exact commands and expected results.

Type consistency:

- Scoring groups use `id`, `kind`, `label`, `score`, `dice`, and `dice_count`.
- Match phases are `awaiting_roll`, `selecting`, `can_bank_or_roll`, and `game_over`.
- AI decisions use `kind = "roll" | "keep" | "bank" | "reroll" | "wait"`.
- Farkle exposes `uses_dice_tray`, `onRollRequest`, `onDiceSettled`, `dice_results`, and `selected_die` for `main.lua`.
