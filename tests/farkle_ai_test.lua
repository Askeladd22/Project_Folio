package.path = "./?.lua;./?/init.lua;" .. package.path

local Ai = require("src.gameplay.farkle.ai")
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

local function test_keeps_best_group_after_scoring_roll()
    local match = Match.new()
    match.current_player_index = 2

    local roll = match:applyRoll({1, 2, 3, 4, 5, 6})
    assert_true(roll.ok, "AI roll should be accepted")

    local decision = Ai.decide(match)

    assert_eq(decision.kind, "keep", "AI should keep a scoring group")
    assert_eq(decision.group_id, match.latest_groups[1].id, "AI should keep the best group id")
    assert_eq(decision.group_kind, "straight", "AI should keep the best group kind")
    assert_eq(decision.score, 2500, "AI should include the kept group score")
end

local function test_banks_at_threshold()
    local match = Match.new()
    match.current_player_index = 2
    match.phase = "can_bank_or_roll"
    match.turn_score = 700
    match.available_dice = 3

    local decision = Ai.decide(match)

    assert_eq(decision.kind, "bank", "AI should bank at threshold")
    assert_eq(decision.reason, "threshold", "AI should report threshold banking")
end

local function test_rerolls_below_threshold()
    local match = Match.new()
    match.current_player_index = 2
    match.phase = "can_bank_or_roll"
    match.turn_score = 300
    match.available_dice = 5

    local decision = Ai.decide(match)

    assert_eq(decision.kind, "reroll", "AI should reroll below threshold")
    assert_eq(decision.dice_count, 5, "AI should report available dice for reroll")
end

local function test_banks_if_it_wins()
    local match = Match.new({target_score = 5000})
    match.current_player_index = 2
    match.players[2].score = 4900
    match.phase = "can_bank_or_roll"
    match.turn_score = 100

    local decision = Ai.decide(match)

    assert_eq(decision.kind, "bank", "AI should bank when projected total wins")
    assert_eq(decision.reason, "wins", "AI should report winning bank")
end

local function test_threshold_is_lower_when_ahead_or_tied()
    local tied = Match.new()
    tied.players[1].score = 1200
    tied.players[2].score = 1200
    assert_eq(Ai.bank_threshold(tied), 450, "AI should use lower threshold when tied")

    local ahead = Match.new()
    ahead.players[1].score = 1000
    ahead.players[2].score = 1200
    assert_eq(Ai.bank_threshold(ahead), 450, "AI should use lower threshold when ahead")
end

local function test_threshold_is_higher_when_far_behind()
    local match = Match.new()
    match.players[1].score = 2000
    match.players[2].score = 900

    assert_eq(Ai.bank_threshold(match), 900, "AI should use higher threshold when behind by at least 1000")
end

local function test_waits_for_missing_or_invalid_match()
    local missing = Ai.decide(nil)
    assert_eq(missing.kind, "wait", "AI should wait without a match")
    assert_eq(missing.reason, "missing_match", "AI should report missing match")

    local invalid = Ai.decide({})
    assert_eq(invalid.kind, "wait", "AI should wait for invalid match")
    assert_eq(invalid.reason, "missing_match", "AI should report invalid match as missing")
end

local function test_rolls_when_awaiting_roll()
    local match = Match.new()
    match.current_player_index = 2
    match.available_dice = 4

    local decision = Ai.decide(match)

    assert_eq(decision.kind, "roll", "AI should roll when awaiting roll")
    assert_eq(decision.dice_count, 4, "AI should report available dice for roll")
end

local function test_waits_when_selecting_without_groups()
    local match = Match.new()
    match.current_player_index = 2
    match.phase = "selecting"
    match.latest_groups = {}

    local decision = Ai.decide(match)

    assert_eq(decision.kind, "wait", "AI should wait when no scoring group exists")
    assert_eq(decision.reason, "no_group", "AI should report missing group")
end

local function test_waits_on_unsupported_phase()
    local game_over = Match.new()
    game_over.phase = "game_over"
    local decision = Ai.decide(game_over)

    assert_eq(decision.kind, "wait", "AI should wait on game over")
    assert_eq(decision.reason, "unsupported_phase", "AI should report unsupported phase")
end

local tests = {
    {name = "keeps_best_group_after_scoring_roll", fn = test_keeps_best_group_after_scoring_roll},
    {name = "banks_at_threshold", fn = test_banks_at_threshold},
    {name = "rerolls_below_threshold", fn = test_rerolls_below_threshold},
    {name = "banks_if_it_wins", fn = test_banks_if_it_wins},
    {name = "threshold_is_lower_when_ahead_or_tied", fn = test_threshold_is_lower_when_ahead_or_tied},
    {name = "threshold_is_higher_when_far_behind", fn = test_threshold_is_higher_when_far_behind},
    {name = "waits_for_missing_or_invalid_match", fn = test_waits_for_missing_or_invalid_match},
    {name = "rolls_when_awaiting_roll", fn = test_rolls_when_awaiting_roll},
    {name = "waits_when_selecting_without_groups", fn = test_waits_when_selecting_without_groups},
    {name = "waits_on_unsupported_phase", fn = test_waits_on_unsupported_phase},
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
