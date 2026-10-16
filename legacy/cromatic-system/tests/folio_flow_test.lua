package.path = "./?.lua;./?/init.lua;" .. package.path

local Folio = require("src.gameplay.folio.model")
local FolioTurnReasons = require("src.data.folio_turn_reasons")

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

local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", message or "assert_eq failed", tostring(expected), tostring(actual)))
    end
end

local function table_contains(list, target)
    for _, value in ipairs(list or {}) do
        if value == target then
            return true
        end
    end
    return false
end

local function make_run_setup(overrides)
    local effects = {
        simple_sections = true,
        ignore_pattern_constraints = true,
        forbid_colors = {},
        quality_per_color = {},
        quality_per_section = {},
        risk_on_color = {},
        risk_on_value = {},
        risk_on_section = {},
        safe_wet_threshold_bonus = 0,
        push_risk_always = nil,
        first_stop_wet_left = 0,
        stop_risk_reduction = 0,
        tool_stop_risk_reduction = 0,
        force_borders_parity = "EVEN",
        tool_knife = false,
        tool_bonus_guard = 0,
    }

    if overrides then
        for k, v in pairs(overrides) do
            effects[k] = v
        end
    end

    return {
        cards = {},
        effects = effects,
    }
end

local function find_valid_move(folio, preferred_color)
    local palette = folio:getAvailableInkColors()
    local colors = {}
    if preferred_color then
        if folio:getInkDrops(preferred_color) > 0 then
            colors[#colors + 1] = preferred_color
        end
        for _, color in ipairs(palette) do
            if color ~= preferred_color then
                colors[#colors + 1] = color
            end
        end
    else
        colors = palette
    end

    for _, color in ipairs(colors) do
        for value = 1, 6 do
            local cells = folio:getValidPlacements("TEXT", value, color)
            if #cells > 0 then
                return {
                    row = cells[1].row,
                    col = cells[1].col,
                    value = value,
                    color = color,
                }
            end
        end
    end

    return nil
end

local function queue_one_wet_die(folio, preferred_color)
    local move = find_valid_move(folio, preferred_color)
    assert_true(move ~= nil, "expected at least one valid move")
    local ok = folio:addWetDie("TEXT", move.row, move.col, move.value, move.color, "TEST_PIGMENT")
    assert_true(ok, "addWetDie should succeed")
    return move
end

local function find_valid_move_for_cell(folio, row, col)
    local colors = folio:getAvailableInkColors()
    for _, color in ipairs(colors) do
        for value = 1, 6 do
            local ok = folio:canPlaceDie("TEXT", row, col, value, color)
            if ok then
                return {
                    row = row,
                    col = col,
                    value = value,
                    color = color,
                }
            end
        end
    end
    return nil
end

local function test_when_pushing_then_stop_commits_wet_buffer()
    local folio = Folio.new("BIFOLIO", 101, make_run_setup())
    local move = queue_one_wet_die(folio)

    local push_ok = folio:registerPush("all")
    assert_true(push_ok, "first push should succeed")
    assert_eq(folio:getWetSummary().pushes, 1, "push counter should increment")

    local result = folio:commitWetBuffer()
    assert_eq(result.committed, 1, "commit should dry one wet die")
    assert_eq(result.stains_added, 0, "commit should not add stains in MVP")
    assert_eq(folio:getWetCount(), 0, "wet buffer should be empty after commit")
    assert_eq(folio:getWetSummary().pushes, 0, "push counter should reset at commit")

    local state = folio:getCellState("TEXT", move.row, move.col)
    assert_true(state and state.placed ~= nil, "cell should contain committed die")
    assert_false(state.wet, "committed die should not remain wet")
end

local function test_when_reroll_limit_is_reached_then_register_push_fails()
    local folio = Folio.new("BIFOLIO", 102, make_run_setup())
    assert_eq(folio.reroll_max, 2, "default reroll cap should be 2")

    local ok1 = folio:registerPush("all")
    local ok2 = folio:registerPush("one")
    local ok3, reason3 = folio:registerPush("all")

    assert_true(ok1, "first push should succeed")
    assert_true(ok2, "second push should succeed")
    assert_false(ok3, "third push should fail at reroll cap")
    assert_eq(reason3, FolioTurnReasons.reroll_limit_reached, "failure should expose cap reason code")
    assert_eq(folio:getWetSummary().pushes, 2, "push counter should stay capped at 2")
end

local function test_when_adding_wet_die_then_ink_is_spent_immediately()
    local folio = Folio.new("BIFOLIO", 103, make_run_setup())
    local move = find_valid_move(folio)
    assert_true(move ~= nil, "expected a valid move")

    local drops_before = folio:getInkDrops(move.color)
    assert_true(drops_before > 0, "selected color should have ink")

    local ok = folio:addWetDie("TEXT", move.row, move.col, move.value, move.color, "TEST_PIGMENT")
    assert_true(ok, "addWetDie should succeed")
    assert_eq(folio:getInkDrops(move.color), drops_before - 1, "successful wet placement should consume one drop")
end

local function test_when_undoing_a_wet_die_then_spent_ink_is_restored()
    local folio = Folio.new("BIFOLIO", 110, make_run_setup())
    local move = find_valid_move(folio)
    assert_true(move ~= nil, "expected a valid move")

    local drops_before = folio:getInkDrops(move.color)
    assert_true(drops_before > 0, "selected color should have available ink")

    local ok = folio:addWetDie("TEXT", move.row, move.col, move.value, move.color, "TEST_PIGMENT")
    assert_true(ok, "addWetDie should succeed before undo")
    assert_eq(folio:getInkDrops(move.color), drops_before - 1, "wet placement should spend one drop")

    local removed = folio:removeWetPlacementAt(1)
    assert_true(removed ~= nil, "removeWetPlacementAt should return removed placement")
    assert_eq(folio:getInkDrops(move.color), drops_before, "undo should restore the spent drop")
    assert_eq(folio:getWetCount(), 0, "wet buffer should be empty after undo")
end

local function test_when_color_is_depleted_then_turn_palette_excludes_it()
    local folio = Folio.new("BIFOLIO", 104, make_run_setup())
    local colors = folio:getAvailableInkColors()
    assert_true(#colors > 0, "inkwell should expose at least one color")
    local target_color = colors[#colors]

    while folio:getInkDrops(target_color) > 0 do
        local spent = folio:spendInk(target_color, 1)
        assert_true(spent, "spending available ink should succeed")
    end
    assert_eq(folio:getInkDrops(target_color), 0, "target color should be depleted")

    for _ = 1, 30 do
        local turn_palette = folio:drawTurnPalette(3)
        assert_false(table_contains(turn_palette, target_color), "depleted color must not appear in turn palette")
    end
end

local function test_when_folio_starts_then_inkwell_budget_matches_mvp_distribution()
    local folio = Folio.new("BIFOLIO", 111, make_run_setup())
    local colors = folio:getInkColors()
    assert_eq(#colors, 8, "MVP inkwell should expose exactly 8 colors")

    assert_eq(folio:getInkCap("NERO"), 4, "black should start at cap 4")
    assert_eq(folio:getInkCap("MARRONE"), 4, "brown should start at cap 4")
    assert_eq(folio:getInkDrops("NERO"), 4, "black should start full")
    assert_eq(folio:getInkDrops("MARRONE"), 4, "brown should start full")

    local common_count = 0
    local rare_count = 0
    local total = 0
    for _, color in ipairs(colors) do
        local cap = folio:getInkCap(color)
        local drops = folio:getInkDrops(color)
        assert_eq(drops, cap, "all colors should start full in MVP")
        total = total + drops
        if color ~= "NERO" and color ~= "MARRONE" then
            if cap == 3 then
                common_count = common_count + 1
            elseif cap == 2 then
                rare_count = rare_count + 1
            else
                error("non-base color cap must be 2 or 3")
            end
        end
    end

    assert_eq(common_count, 3, "exactly three non-base colors should be common (3 drops)")
    assert_eq(rare_count, 3, "exactly three non-base colors should be rare (2 drops)")
    assert_eq(total, 23, "MVP inkwell should start with total 23 drops")
end

local function test_when_folio_starts_then_two_guided_rows_are_open()
    local folio = Folio.new("BIFOLIO", 112, make_run_setup())
    local guided = folio:getGuidedRows()
    local open = folio:getOpenRows()

    assert_eq(#guided, 2, "MVP folio should have exactly 2 guided rows")
    assert_eq(#open, 2, "MVP folio should start with exactly 2 open rows")
    for _, row in ipairs(open) do
        assert_true(table_contains(guided, row), "every open row at start should be guided")
    end
end

local function test_when_bust_candidates_are_open_rows_only_then_closed_rows_are_excluded()
    local folio = Folio.new(
        "BIFOLIO",
        105,
        make_run_setup(),
        {
            bust_open_rows_only = true,
            bust_choice_count = 2,
        }
    )

    local open_rows = folio:getOpenRows()
    assert_true(#open_rows > 0, "folio should start with open rows")
    local candidates = folio:getBustStainCandidates(2)
    assert_true(#candidates > 0, "fresh folio should have bust stain candidates")
    for _, candidate in ipairs(candidates) do
        assert_true(table_contains(open_rows, candidate.row), "candidate row should be open when open_rows_only is enabled")
    end
end

local function test_when_bust_is_salvaged_then_wet_is_discarded_and_stains_follow_wet_count()
    local folio = Folio.new("BIFOLIO", 106, make_run_setup())

    queue_one_wet_die(folio)
    queue_one_wet_die(folio)
    assert_eq(folio:getWetCount(), 2, "two wet placements should be queued before salvage")

    local outcome = folio:salvageWetBufferOnBust()
    assert_true(outcome ~= nil, "salvage should return an outcome")
    assert_eq(outcome.saved, nil, "MVP salvage should not keep one wet placement")
    assert_eq(outcome.discarded, 2, "salvage should discard all wet placements")
    assert_eq(outcome.stains_added, 2, "salvage should add stains equal to discarded wet count")
    assert_eq(folio:getWetCount(), 0, "wet buffer should be empty after salvage")
    assert_eq(folio.stain_count, 2, "folio stain count should be updated")
end

local function test_when_preparation_is_requested_then_it_is_disabled_in_mvp()
    local folio = Folio.new("BIFOLIO", 107, make_run_setup())

    assert_false(folio:canUsePreparation(), "preparation should be disabled in MVP")
    local prep_ok, prep_reason = folio:applyPreparation("guard")
    assert_false(prep_ok, "applyPreparation should fail in MVP")
    assert_eq(prep_reason, FolioTurnReasons.preparation_disabled_in_mvp, "disabled reason should be explicit")
    assert_eq(folio:getPreparationGuard(), 0, "preparation guard should stay at zero")
end

local function test_when_commit_is_called_with_empty_wet_buffer_then_summary_is_zeroed()
    local folio = Folio.new("BIFOLIO", 108, make_run_setup())
    local result = folio:commitWetBuffer()

    assert_eq(result.committed, 0, "empty commit should not commit placements")
    assert_eq(result.still_wet, 0, "empty commit should leave no wet placements")
    assert_eq(result.stains_added, 0, "empty commit should add no stains")
    assert_eq(result.ink_recovery_available, 0, "empty commit should not grant row recovery")
    assert_eq(#result.rows_completed, 0, "empty commit should report no completed rows")
end

local function test_when_a_row_is_completed_then_commit_grants_one_ink_recovery()
    local folio = Folio.new("BIFOLIO", 109, make_run_setup())
    local elem = folio.elements and folio.elements.TEXT
    assert_true(elem and elem.pattern, "expected TEXT pattern to exist")
    local pattern = elem.pattern

    for i = 1, (pattern.rows * pattern.cols) do
        pattern.grid[i] = nil
    end

    local open_rows = folio:getOpenRows()
    local target_row = open_rows[1] or 1
    for col = 1, (pattern.cols or 5) do
        local move = find_valid_move_for_cell(folio, target_row, col)
        assert_true(move ~= nil, string.format("expected move at row %d col %d", target_row, col))
        local ok = folio:addWetDie("TEXT", move.row, move.col, move.value, move.color, "TEST_PIGMENT")
        assert_true(ok, "expected wet placement to succeed while completing row")
    end

    local result = folio:commitWetBuffer()
    assert_eq(result.committed, pattern.cols or 5, "commit should dry all placements used for row completion")
    assert_eq(result.ink_recovery_available, 1, "one completed row should grant one ink recovery")
    assert_true(table_contains(result.rows_completed, target_row), "completed row should be reported in commit result")
end

local tests = {
    { name = "when_pushing_then_stop_commits_wet_buffer", fn = test_when_pushing_then_stop_commits_wet_buffer },
    {
        name = "when_reroll_limit_is_reached_then_register_push_fails",
        fn = test_when_reroll_limit_is_reached_then_register_push_fails,
    },
    {
        name = "when_adding_wet_die_then_ink_is_spent_immediately",
        fn = test_when_adding_wet_die_then_ink_is_spent_immediately,
    },
    {
        name = "when_undoing_a_wet_die_then_spent_ink_is_restored",
        fn = test_when_undoing_a_wet_die_then_spent_ink_is_restored,
    },
    {
        name = "when_color_is_depleted_then_turn_palette_excludes_it",
        fn = test_when_color_is_depleted_then_turn_palette_excludes_it,
    },
    {
        name = "when_folio_starts_then_inkwell_budget_matches_mvp_distribution",
        fn = test_when_folio_starts_then_inkwell_budget_matches_mvp_distribution,
    },
    {
        name = "when_folio_starts_then_two_guided_rows_are_open",
        fn = test_when_folio_starts_then_two_guided_rows_are_open,
    },
    {
        name = "when_bust_candidates_are_open_rows_only_then_closed_rows_are_excluded",
        fn = test_when_bust_candidates_are_open_rows_only_then_closed_rows_are_excluded,
    },
    {
        name = "when_bust_is_salvaged_then_wet_is_discarded_and_stains_follow_wet_count",
        fn = test_when_bust_is_salvaged_then_wet_is_discarded_and_stains_follow_wet_count,
    },
    {
        name = "when_preparation_is_requested_then_it_is_disabled_in_mvp",
        fn = test_when_preparation_is_requested_then_it_is_disabled_in_mvp,
    },
    {
        name = "when_commit_is_called_with_empty_wet_buffer_then_summary_is_zeroed",
        fn = test_when_commit_is_called_with_empty_wet_buffer_then_summary_is_zeroed,
    },
    {
        name = "when_a_row_is_completed_then_commit_grants_one_ink_recovery",
        fn = test_when_a_row_is_completed_then_commit_grants_one_ink_recovery,
    },
}

local failed = 0
for _, test_case in ipairs(tests) do
    local ok, err = pcall(test_case.fn)
    if ok then
        print(string.format("ok - %s", test_case.name))
    else
        failed = failed + 1
        io.stderr:write(string.format("not ok - %s: %s\n", test_case.name, tostring(err)))
    end
end

if failed > 0 then
    error(string.format("%d test(s) failed", failed))
end

print(string.format("all tests passed (%d)", #tests))
