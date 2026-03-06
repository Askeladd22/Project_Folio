package.path = "./?.lua;./?/init.lua;" .. package.path

local EventBus = require("src.core.event_bus")

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

local function test_when_emitting_then_handlers_receive_payload_and_event_name()
    local bus = EventBus.new()
    local received_payload = nil
    local received_name = nil
    bus:on("test.event", function(payload, event_name)
        received_payload = payload
        received_name = event_name
    end)
    local called = bus:emit("test.event", {value = 42})
    assert_eq(called, 1, "emit should call one handler")
    assert_true(type(received_payload) == "table", "handler should receive payload")
    assert_eq(received_payload.value, 42, "payload value should match")
    assert_eq(received_name, "test.event", "event name should match")
end

local function test_when_once_handler_is_registered_then_it_runs_once()
    local bus = EventBus.new()
    local count = 0
    bus:once("test.once", function()
        count = count + 1
    end)
    bus:emit("test.once")
    bus:emit("test.once")
    assert_eq(count, 1, "once handler should run only one time")
end

local function test_when_off_is_called_with_slot_then_handler_is_removed()
    local bus = EventBus.new()
    local count = 0
    local slot = bus:on("test.off.slot", function()
        count = count + 1
    end)
    local removed = bus:off(slot)
    assert_true(removed, "off(slot) should report removal")
    local called = bus:emit("test.off.slot")
    assert_eq(called, 0, "emit should not call removed handler")
    assert_eq(count, 0, "removed handler should not run")
end

local function test_when_off_is_called_with_event_name_then_event_is_cleared()
    local bus = EventBus.new()
    local count = 0
    bus:on("test.off.event", function() count = count + 1 end)
    bus:on("test.off.event", function() count = count + 1 end)
    local removed = bus:off("test.off.event")
    assert_true(removed, "off(event) should report removal")
    local called = bus:emit("test.off.event")
    assert_eq(called, 0, "emit should not call handlers after clear")
    assert_eq(count, 0, "handlers should be removed")
end

local tests = {
    {
        name = "when_emitting_then_handlers_receive_payload_and_event_name",
        fn = test_when_emitting_then_handlers_receive_payload_and_event_name,
    },
    {
        name = "when_once_handler_is_registered_then_it_runs_once",
        fn = test_when_once_handler_is_registered_then_it_runs_once,
    },
    {
        name = "when_off_is_called_with_slot_then_handler_is_removed",
        fn = test_when_off_is_called_with_slot_then_handler_is_removed,
    },
    {
        name = "when_off_is_called_with_event_name_then_event_is_cleared",
        fn = test_when_off_is_called_with_event_name_then_event_is_cleared,
    },
}

for _, test in ipairs(tests) do
    test.fn()
    print("ok - " .. test.name)
end

