package.path = "./?.lua;./?/init.lua;" .. package.path

local DiceConfig = require("src.core.dice_config")
local DiceRollSchema = require("src.data.dice_roll_schema")

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

local function deep_copy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for key, nested in pairs(value) do
        out[key] = deep_copy(nested)
    end
    return out
end

local function test_when_loading_default_schemas_then_expected_values_are_exposed()
    local config = DiceConfig.load()

    assert_eq(config.sizes.base, 0.80, "sizes.base should come from schema")
    assert_eq(config.pool[1].kind, "d6", "pool first kind should be d6")
    assert_eq(config.visual.glow.shader_path, "lib/dice_glow.glsl", "glow shader path should come from schema")
    assert_true(config.scene.camera.locked, "tray camera lock flag should come from schema")
    assert_eq(config.scene.regions.main.parent, "unified", "main region should point to unified parent")
end

local function test_when_pool_kind_is_invalid_then_load_fails()
    local invalid_roll = deep_copy(DiceRollSchema)
    invalid_roll.pool[1].kind = "d10"

    local ok, err = pcall(function()
        DiceConfig.load({
            roll_schema = invalid_roll,
        })
    end)

    assert_true(not ok, "invalid kind should fail")
    assert_true(type(err) == "string" and err:find("dice_roll_schema.pool%[1%]%.kind", 1, false) ~= nil, "error should include path")
end

local tests = {
    {
        name = "when_loading_default_schemas_then_expected_values_are_exposed",
        fn = test_when_loading_default_schemas_then_expected_values_are_exposed,
    },
    {
        name = "when_pool_kind_is_invalid_then_load_fails",
        fn = test_when_pool_kind_is_invalid_then_load_fails,
    },
}

for _, test in ipairs(tests) do
    test.fn()
    print("ok - " .. test.name)
end
