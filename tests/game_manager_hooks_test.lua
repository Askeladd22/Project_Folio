package.path = "./?.lua;./?/init.lua;" .. package.path

local EventBus = require("src.core.event_bus")
local GameManager = require("src.core.game_manager")

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

local function assert_list_eq(actual, expected, message)
    assert_eq(#actual, #expected, (message or "list size mismatch"))
    for i = 1, #expected do
        if actual[i] ~= expected[i] then
            error(string.format(
                "%s (index %d expected %s, got %s)",
                message or "list mismatch",
                i,
                tostring(expected[i]),
                tostring(actual[i])
            ))
        end
    end
end

local function test_when_registering_hooks_then_phase_order_is_respected()
    local order = {}
    local manager = GameManager.new()
    manager:register("dummy", {
        enter = function() end,
        update = function()
            order[#order + 1] = "module.update"
        end,
        draw = function()
            order[#order + 1] = "module.draw"
        end,
    })
    manager:switch("dummy")

    manager:register_hook("pre_update", "b", function()
        order[#order + 1] = "pre_update.b"
    end, 200)
    manager:register_hook("pre_update", "a", function()
        order[#order + 1] = "pre_update.a"
    end, 100)
    manager:register_hook("post_update", "c", function()
        order[#order + 1] = "post_update.c"
    end, 100)
    manager:register_hook("pre_draw", "d", function()
        order[#order + 1] = "pre_draw.d"
    end, 100)
    manager:register_hook("post_draw", "e", function()
        order[#order + 1] = "post_draw.e"
    end, 100)

    manager:update(0.16)
    manager:draw()

    assert_list_eq(order, {
        "pre_update.a",
        "pre_update.b",
        "module.update",
        "post_update.c",
        "pre_draw.d",
        "module.draw",
        "post_draw.e",
    }, "hooks should run in deterministic order")
end

local function test_when_event_bus_is_injected_then_context_uses_same_instance()
    local injected = EventBus.new()
    local manager = GameManager.new({
        event_bus = injected,
    })
    assert_true(manager:get_event_bus() == injected, "manager should expose injected event bus")
    assert_true(manager:get_context().events == injected, "context.events should match injected event bus")
end

local function test_when_switching_modules_then_lifecycle_events_are_emitted()
    local manager = GameManager.new()
    local events = {}
    manager:on("module.will_exit", function(payload)
        events[#events + 1] = "will_exit:" .. tostring(payload.from) .. "->" .. tostring(payload.to)
    end)
    manager:on("module.will_enter", function(payload)
        events[#events + 1] = "will_enter:" .. tostring(payload.from) .. "->" .. tostring(payload.to)
    end)
    manager:on("module.did_enter", function(payload)
        events[#events + 1] = "did_enter:" .. tostring(payload.from) .. "->" .. tostring(payload.to)
    end)

    manager:register("one", {enter = function() end, exit = function() end})
    manager:register("two", {enter = function() end, exit = function() end})

    manager:switch("one")
    manager:switch("two")

    assert_list_eq(events, {
        "will_enter:nil->one",
        "did_enter:nil->one",
        "will_exit:one->two",
        "will_enter:one->two",
        "did_enter:one->two",
    }, "switch lifecycle events should be emitted in order")
end

local tests = {
    {
        name = "when_registering_hooks_then_phase_order_is_respected",
        fn = test_when_registering_hooks_then_phase_order_is_respected,
    },
    {
        name = "when_event_bus_is_injected_then_context_uses_same_instance",
        fn = test_when_event_bus_is_injected_then_context_uses_same_instance,
    },
    {
        name = "when_switching_modules_then_lifecycle_events_are_emitted",
        fn = test_when_switching_modules_then_lifecycle_events_are_emitted,
    },
}

for _, test in ipairs(tests) do
    test.fn()
    print("ok - " .. test.name)
end

