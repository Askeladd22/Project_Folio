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

local function assert_false(value, message)
    if value then
        error(message or "expected false")
    end
end

local function prepare_turn_with_one_kept()
    local match = Match.new()
    assert_true(match:applyRoll({1, 2, 3, 4, 2, 3}).ok, "initial roll should be accepted")
    assert_true(match:keepGroup("single_one").ok, "single one should be kept")
    assert_true(match:reroll().ok, "reroll should be accepted after keeping")
    return match
end

local function test_keep_bank_and_pass_turn()
    local match = Match.new()

    local roll = match:applyRoll({1, 2, 3, 4, 2, 3})
    assert_true(roll.ok, "roll should be accepted")
    assert_false(roll.bust, "roll should not bust")

    local keep = match:keepGroup("single_one")
    assert_true(keep.ok, "single one should be keepable")
    assert_eq(match.turn_score, 100, "turn score after keeping single one")
    assert_eq(match.available_dice, 5, "available dice after keeping one die")

    local bank = match:bank()
    assert_true(bank.ok, "bank should be accepted")
    assert_eq(match.players[1].score, 100, "human banked score")
    assert_eq(match.current_player_index, 2, "turn should pass to AI")
    assert_eq(match.turn_score, 0, "turn score should reset after bank")
    assert_eq(match.phase, "awaiting_roll", "next player should await roll")
end

local function test_bust_clears_turn_and_passes()
    local match = Match.new()

    local match = prepare_turn_with_one_kept()

    local bust = match:applyRoll({2, 2, 3, 3, 4})
    assert_true(bust.ok, "bust roll should be accepted")
    assert_true(bust.bust, "roll should bust")
    assert_eq(match.players[1].score, 0, "bust should not bank score")
    assert_eq(match.turn_score, 0, "bust should clear turn score")
    assert_eq(match.current_player_index, 2, "bust should pass to AI")
    assert_eq(match.phase, "awaiting_roll", "AI should be awaiting roll")
end

local function test_hot_dice_resets_available_dice()
    local match = Match.new()

    assert_true(match:applyRoll({1, 2, 3, 4, 5, 6}).ok, "straight roll should be accepted")
    local keep = match:keepGroup("straight")

    assert_true(keep.ok, "straight should be keepable")
    assert_true(keep.hot_dice, "using all dice should report hot dice")
    assert_eq(match.available_dice, 6, "hot dice should reset available dice")
    assert_eq(match.turn_score, 2500, "straight should add to turn score")
    assert_eq(match.phase, "can_bank_or_roll", "player should be able to bank or roll")
end

local function test_rejects_invalid_actions()
    local match = Match.new()

    local bank_zero = match:bank()
    assert_false(bank_zero.ok, "cannot bank zero score")
    assert_eq(bank_zero.reason, "cannot_bank", "bank zero rejection reason")

    local keep_before_roll = match:keepGroup("single_one")
    assert_false(keep_before_roll.ok, "cannot keep before roll")
    assert_eq(keep_before_roll.reason, "invalid_phase", "keep before roll rejection reason")

    assert_true(match:applyRoll({1, 2, 3, 4, 2, 3}).ok, "roll should be accepted")
    local keep_missing = match:keepGroup("straight")
    assert_false(keep_missing.ok, "cannot keep unavailable group")
    assert_eq(keep_missing.reason, "group_unavailable", "missing group rejection reason")
    assert_eq(match.turn_score, 0, "failed keep should not mutate turn score")
end

local function test_reroll_rejects_too_few_dice_without_mutating_state()
    local match = prepare_turn_with_one_kept()

    local result = match:applyRoll({2, 2, 3, 3})

    assert_false(result.ok, "too few dice should be rejected")
    assert_eq(result.reason, "invalid_roll", "too few dice rejection reason")
    assert_eq(match.current_player_index, 1, "invalid roll should not pass turn")
    assert_eq(match.phase, "awaiting_roll", "invalid roll should keep awaiting roll")
    assert_eq(match.turn_score, 100, "invalid roll should keep turn score")
    assert_eq(match.available_dice, 5, "invalid roll should keep available dice")
    assert_eq(#match.latest_roll, 0, "invalid roll should not store latest roll")
    assert_eq(#match.latest_groups, 0, "invalid roll should not store latest groups")
    assert_eq(#match.kept_dice, 1, "invalid roll should keep already kept dice")
end

local function test_reroll_rejects_too_many_dice_without_mutating_state()
    local match = prepare_turn_with_one_kept()

    local result = match:applyRoll({1, 2, 3, 4, 5, 6})

    assert_false(result.ok, "too many dice should be rejected")
    assert_eq(result.reason, "invalid_roll", "too many dice rejection reason")
    assert_eq(match.current_player_index, 1, "invalid roll should not pass turn")
    assert_eq(match.phase, "awaiting_roll", "invalid roll should keep awaiting roll")
    assert_eq(match.turn_score, 100, "invalid roll should keep turn score")
    assert_eq(match.available_dice, 5, "invalid roll should keep available dice")
    assert_eq(#match.latest_roll, 0, "invalid roll should not store latest roll")
    assert_eq(#match.latest_groups, 0, "invalid roll should not store latest groups")
    assert_eq(#match.kept_dice, 1, "invalid roll should keep already kept dice")
end

local function test_returned_groups_are_cloned()
    local match = Match.new()

    local roll = match:applyRoll({1, 2, 3, 4, 2, 3})
    assert_true(roll.ok, "roll should be accepted")
    assert_true(roll.groups[1] ~= nil, "roll should return at least one group")
    assert_true(roll.groups[1].dice[1] ~= nil, "returned group should include dice")

    roll.groups[1].score = 9999
    roll.groups[1].dice[1].value = 6

    assert_eq(match.latest_groups[1].score, 100, "mutating returned group should not mutate stored group")
    assert_eq(match.latest_groups[1].dice[1].value, 1, "mutating returned die should not mutate stored die")
end

local function test_game_over_when_target_reached()
    local match = Match.new({target_score = 100})

    assert_true(match:applyRoll({1, 2, 3, 4, 2, 3}).ok, "roll should be accepted")
    assert_true(match:keepGroup("single_one").ok, "single one should be kept")

    local bank = match:bank()
    assert_true(bank.ok, "bank should be accepted")
    assert_eq(match.players[1].score, 100, "human should reach target")
    assert_eq(match.phase, "game_over", "match should end")
    assert_eq(match.winner_id, "human", "human should be winner")
    assert_eq(match.current_player_index, 1, "winner should remain current player")
    assert_eq(match.turn_score, 0, "turn score should reset at game over")
end

local tests = {
    {name = "keep_bank_and_pass_turn", fn = test_keep_bank_and_pass_turn},
    {name = "bust_clears_turn_and_passes", fn = test_bust_clears_turn_and_passes},
    {name = "hot_dice_resets_available_dice", fn = test_hot_dice_resets_available_dice},
    {name = "rejects_invalid_actions", fn = test_rejects_invalid_actions},
    {name = "reroll_rejects_too_few_dice_without_mutating_state", fn = test_reroll_rejects_too_few_dice_without_mutating_state},
    {name = "reroll_rejects_too_many_dice_without_mutating_state", fn = test_reroll_rejects_too_many_dice_without_mutating_state},
    {name = "returned_groups_are_cloned", fn = test_returned_groups_are_cloned},
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
