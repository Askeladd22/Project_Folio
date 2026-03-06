package.path = "./?.lua;./?/init.lua;" .. package.path

local LuaTableStore = require("src.core.lua_table_store")

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

local function make_fs()
    local files = {}
    return {
        files = files,
        getInfo = function(path)
            if files[path] ~= nil then
                return {type = "file"}
            end
            return nil
        end,
        load = function(path)
            local source = files[path]
            if source == nil then
                return nil, "file not found"
            end
            return load(source, "@" .. tostring(path))
        end,
        write = function(path, text)
            files[path] = text
            return true
        end,
    }
end

local function test_when_saving_then_data_is_serialized_as_lua_chunk()
    local fs = make_fs()
    local path = "settings.lua"
    local ok, err = LuaTableStore.save(path, {
        c = true,
        a = 10,
        nested = {
            z = "ok",
        },
    }, {
        filesystem = fs,
    })

    assert_true(ok, "save should succeed")
    assert_eq(err, nil, "save error should be nil")
    assert_true(type(fs.files[path]) == "string", "filesystem should receive serialized content")
    assert_true(fs.files[path]:find("return%s+%{", 1) ~= nil, "serialized content should be lua chunk")

    local loaded, load_err = LuaTableStore.load(path, {
        filesystem = fs,
    })
    assert_eq(load_err, nil, "load should not return error")
    assert_eq(loaded.a, 10, "loaded numeric value should match")
    assert_true(loaded.c, "loaded boolean should match")
    assert_eq(loaded.nested.z, "ok", "loaded nested value should match")
end

local function test_when_loading_missing_file_then_status_is_missing()
    local fs = make_fs()
    local data, err, status = LuaTableStore.load("missing.lua", {
        filesystem = fs,
    })
    assert_eq(data, nil, "missing file should not return data")
    assert_eq(err, nil, "missing file should not return error")
    assert_eq(status, "missing", "missing file should return missing status")
end

local function test_when_chunk_does_not_return_table_then_load_fails()
    local fs = make_fs()
    fs.files["broken.lua"] = "return 42"
    local data, err, status = LuaTableStore.load("broken.lua", {
        filesystem = fs,
    })
    assert_eq(data, nil, "invalid payload should not return data")
    assert_eq(status, "invalid_data", "status should mark invalid data")
    assert_true(type(err) == "string" and err ~= "", "invalid payload should return error message")
end

local tests = {
    {
        name = "when_saving_then_data_is_serialized_as_lua_chunk",
        fn = test_when_saving_then_data_is_serialized_as_lua_chunk,
    },
    {
        name = "when_loading_missing_file_then_status_is_missing",
        fn = test_when_loading_missing_file_then_status_is_missing,
    },
    {
        name = "when_chunk_does_not_return_table_then_load_fails",
        fn = test_when_chunk_does_not_return_table_then_load_fails,
    },
}

for _, test in ipairs(tests) do
    test.fn()
    print("ok - " .. test.name)
end
