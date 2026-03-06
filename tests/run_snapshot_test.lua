package.path = "./?.lua;./?/init.lua;" .. package.path

local Run = require("src.gameplay.run.run")

local function assert_true(value, message)
    if not value then
        error(message or "expected true")
    end
end

local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", message or "assert_eq failed", tostring(expected), tostring(actual)))
    end
end

local function test_when_snapshotting_then_run_can_be_restored_with_methods()
    local run = Run.new("BIFOLIO", 1337, {
        campaign_id = "commission_1",
    })
    run.coins = 77
    run.reputation = 11
    run.current_folio.turn_count = 3
    run.current_folio.turn_pushes = 1
    run.current_folio.parchment_configured = true
    run.current_folio.open_rows = {1, 2}

    local snapshot = run:toSaveData()
    assert_eq(snapshot.kind, "run_state", "snapshot should expose run_state kind")
    assert_eq(snapshot.version, Run.SAVE_VERSION, "snapshot should expose save version")
    assert_true(type(snapshot.data) == "table", "snapshot should include data table")

    local restored = Run.fromSaveData(snapshot)
    assert_true(type(restored) == "table", "restored run should be table")

    local status = restored:getStatus()
    assert_eq(status.coins, 77, "restored coins should match")
    assert_eq(status.reputation, 11, "restored reputation should match")
    assert_eq(status.seed, 1337, "restored seed should match")

    assert_true(type(restored.current_folio) == "table", "restored run should include current folio")
    assert_true(type(restored.current_folio.getStatus) == "function", "restored folio should retain methods")
    assert_eq(restored.current_folio.turn_count, 3, "restored folio turn count should match")
    assert_eq(restored.current_folio.turn_pushes, 1, "restored folio push count should match")
end

local function test_when_payload_is_invalid_then_restore_returns_nil()
    local restored = Run.fromSaveData(nil)
    assert_eq(restored, nil, "restore should fail on nil payload")
end

local tests = {
    {
        name = "when_snapshotting_then_run_can_be_restored_with_methods",
        fn = test_when_snapshotting_then_run_can_be_restored_with_methods,
    },
    {
        name = "when_payload_is_invalid_then_restore_returns_nil",
        fn = test_when_payload_is_invalid_then_restore_returns_nil,
    },
}

for _, test in ipairs(tests) do
    test.fn()
    print("ok - " .. test.name)
end
