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
    local one = find_group(groups, "single_one")
    local five = find_group(groups, "single_five")

    assert_eq(#groups, 2, "one and five should create two single scoring groups")
    assert_true(one ~= nil, "single one group should exist")
    assert_true(five ~= nil, "single five group should exist")
    assert_eq(one.score, 100, "single one score")
    assert_eq(five.score, 50, "single five score")
end

local function test_three_of_a_kind_scores()
    local triple = find_group(Scoring.get_scoring_groups({3, 3, 3, 2, 4}), "three_kind_3")
    assert_true(triple ~= nil, "three threes should score")
    assert_eq(triple.score, 300, "three threes score")

    local ones = find_group(Scoring.get_scoring_groups({1, 1, 1, 2, 4}), "three_kind_1")
    assert_true(ones ~= nil, "three ones should score")
    assert_eq(ones.score, 1000, "three ones score")
end

local function test_four_five_and_six_of_a_kind_score()
    local four = find_group(Scoring.get_scoring_groups({6, 6, 6, 6, 2}), "four_kind_6")
    assert_true(four ~= nil, "four sixes should score")
    assert_eq(four.score, 1000, "four of a kind score")

    local five = find_group(Scoring.get_scoring_groups({2, 2, 2, 2, 2}), "five_kind_2")
    assert_true(five ~= nil, "five twos should score")
    assert_eq(five.score, 2000, "five of a kind score")

    local six = find_group(Scoring.get_scoring_groups({4, 4, 4, 4, 4, 4}), "six_kind_4")
    assert_true(six ~= nil, "six fours should score")
    assert_eq(six.score, 3000, "six of a kind score")
end

local function test_straight_scores()
    local straight = find_group(Scoring.get_scoring_groups({1, 2, 3, 4, 5, 6}), "straight")
    assert_true(straight ~= nil, "straight should score")
    assert_eq(straight.score, 2500, "straight score")
end

local function test_three_pairs_score()
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

local function test_normalize_roll_ignores_invalid_values()
    local entries = Scoring.normalize_roll({0, 1, 7, "5", {value = 6, index = 42}, {value = "bad", index = 99}})
    assert_eq(#entries, 3, "only valid dice should be normalized")
    assert_eq(entries[1].roll_pos, 2, "roll position should reflect original list position")
    assert_eq(entries[1].source_index, 2, "plain values should use roll position as source index")
    assert_eq(entries[2].value, 5, "numeric strings should normalize")
    assert_eq(entries[3].source_index, 42, "table index should become source index")
end

local function test_normalize_roll_ignores_outside_range_non_integers()
    local entries = Scoring.normalize_roll({6.9, 0.9, 1, 5})
    assert_eq(#entries, 2, "outside-range non-integers should be ignored")
    assert_eq(entries[1].value, 1, "valid one should remain")
    assert_eq(entries[2].value, 5, "valid five should remain")
end

local function test_normalize_roll_preserves_source_index()
    local entries = Scoring.normalize_roll({{value = 5, source_index = 42}})
    assert_eq(#entries, 1, "valid table entry should be normalized")
    assert_eq(entries[1].source_index, 42, "source_index should be preserved")
end

local function test_find_group_matches_id_or_kind()
    local groups = Scoring.get_scoring_groups({1, 2, 5, 3})
    local one = find_group(groups, "single_one")

    assert_true(one ~= nil, "single one group should exist")
    assert_eq(Scoring.find_group(groups, one.id), one, "find_group should match exact id")
    assert_eq(Scoring.find_group(groups, "single_one"), one, "find_group should match kind")
end

local tests = {
    {name = "singles_score_ones_and_fives", fn = test_singles_score_ones_and_fives},
    {name = "three_of_a_kind_scores", fn = test_three_of_a_kind_scores},
    {name = "four_five_and_six_of_a_kind_score", fn = test_four_five_and_six_of_a_kind_score},
    {name = "straight_scores", fn = test_straight_scores},
    {name = "three_pairs_score", fn = test_three_pairs_score},
    {name = "bust_detection", fn = test_bust_detection},
    {name = "best_group_prefers_score_then_dice_count", fn = test_best_group_prefers_score_then_dice_count},
    {name = "table_roll_entries_keep_source_indices", fn = test_table_roll_entries_keep_source_indices},
    {name = "normalize_roll_ignores_invalid_values", fn = test_normalize_roll_ignores_invalid_values},
    {name = "normalize_roll_ignores_outside_range_non_integers", fn = test_normalize_roll_ignores_outside_range_non_integers},
    {name = "normalize_roll_preserves_source_index", fn = test_normalize_roll_preserves_source_index},
    {name = "find_group_matches_id_or_kind", fn = test_find_group_matches_id_or_kind},
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
