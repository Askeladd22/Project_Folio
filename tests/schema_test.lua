package.path = "./?.lua;./?/init.lua;" .. package.path

local Schema = require("src.core.schema")

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

local function assert_error(fn, message)
    local ok = pcall(fn)
    if ok then
        error(message or "expected error")
    end
end

local function test_when_values_are_valid_then_schema_helpers_return_parsed_values()
    local n = Schema.expect_number("42", "test.number")
    local s = Schema.expect_string("abc", "test.string")
    local b = Schema.expect_boolean(true, "test.bool")
    local entry = Schema.expect_entry({key = "x.y", default = "Y"}, "test.entry")
    local c3 = Schema.expect_color3({0.1, "0.2", 0.3}, "test.color3")
    local c4 = Schema.expect_color4({0.1, 0.2, 0.3}, "test.color4", 0.8)
    local list = Schema.expect_string_list({"a", "b"}, "test.list")

    assert_eq(n, 42, "expect_number should coerce numeric strings")
    assert_eq(s, "abc", "expect_string should return original value")
    assert_true(b, "expect_boolean should return true")
    assert_eq(entry.key, "x.y", "expect_entry should keep key")
    assert_eq(c3[2], 0.2, "expect_color3 should coerce numeric values")
    assert_eq(c4[4], 0.8, "expect_color4 should apply default alpha")
    assert_eq(#list, 2, "expect_string_list should return list")
end

local function test_when_values_are_invalid_then_schema_helpers_raise_errors()
    assert_error(function()
        Schema.expect_table(nil, "bad.table")
    end, "expect_table should fail on nil")
    assert_error(function()
        Schema.expect_non_empty_list({}, "bad.list")
    end, "expect_non_empty_list should fail on empty list")
    assert_error(function()
        Schema.expect_string("", "bad.string")
    end, "expect_string should fail on empty string")
    assert_error(function()
        Schema.expect_number("not-a-number", "bad.number")
    end, "expect_number should fail on invalid number")
    assert_error(function()
        Schema.expect_boolean("true", "bad.bool")
    end, "expect_boolean should fail on non-boolean")
    assert_error(function()
        Schema.expect_entry({default = "x"}, "bad.entry")
    end, "expect_entry should fail when key is missing")
    assert_error(function()
        Schema.expect_color3({1, 2}, "bad.color3")
    end, "expect_color3 should fail on invalid component count")
    assert_error(function()
        Schema.expect_string_list({"a", ""}, "bad.list")
    end, "expect_string_list should fail on empty item")
end

local tests = {
    {
        name = "when_values_are_valid_then_schema_helpers_return_parsed_values",
        fn = test_when_values_are_valid_then_schema_helpers_return_parsed_values,
    },
    {
        name = "when_values_are_invalid_then_schema_helpers_raise_errors",
        fn = test_when_values_are_invalid_then_schema_helpers_raise_errors,
    },
}

for _, test in ipairs(tests) do
    test.fn()
    print("ok - " .. test.name)
end

