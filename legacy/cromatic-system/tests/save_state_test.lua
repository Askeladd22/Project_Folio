package.path = "./?.lua;./?/init.lua;" .. package.path

local SaveState = require("src.core.save_state")

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
        remove = function(path)
            if files[path] == nil then
                return false, "file not found"
            end
            files[path] = nil
            return true
        end,
    }
end

local function test_when_no_save_file_exists_then_exists_returns_false()
    local fs = make_fs()
    local exists, path = SaveState.exists({
        filesystem = fs,
    })
    assert_true(not exists, "exists should be false without files")
    assert_eq(path, nil, "path should be nil when file is missing")
end

local function test_when_legacy_save_file_exists_then_exists_returns_legacy_path()
    local fs = make_fs()
    fs.files["scriptorium_save.dat"] = "return { legacy = true }"

    local exists, path = SaveState.exists({
        filesystem = fs,
    })
    assert_true(exists, "exists should be true with legacy file")
    assert_eq(path, "scriptorium_save.dat", "exists should report first found legacy path")
end

local function test_when_saving_then_load_returns_payload_data()
    local fs = make_fs()
    local ok, err = SaveState.save({
        run = {
            seed = 123,
        },
    }, {
        filesystem = fs,
    })
    assert_true(ok, "save should succeed")
    assert_eq(err, nil, "save error should be nil")

    local data, load_err, path = SaveState.load({
        filesystem = fs,
    })
    assert_eq(load_err, nil, "load error should be nil")
    assert_eq(path, SaveState.FILE_PATH, "load should use canonical file path")
    assert_true(type(data) == "table", "load should return table payload")
    assert_eq(data.run.seed, 123, "load should return saved payload data")
end

local function test_when_loading_legacy_raw_table_then_data_is_returned()
    local fs = make_fs()
    fs.files["save.lua"] = "return { chapter = 2, run = { seed = 99 } }"

    local data, load_err, path = SaveState.load({
        filesystem = fs,
    })
    assert_eq(load_err, nil, "legacy load should not return error")
    assert_eq(path, "save.lua", "load should report legacy source path")
    assert_eq(data.chapter, 2, "legacy raw data should be returned")
    assert_eq(data.run.seed, 99, "legacy nested data should be returned")
end

local function test_when_clearing_then_all_candidate_files_are_removed()
    local fs = make_fs()
    fs.files[SaveState.FILE_PATH] = "return { version = 1, data = { ok = true } }"
    fs.files["save.lua"] = "return { chapter = 2 }"

    local ok, err = SaveState.clear({
        filesystem = fs,
    })
    assert_true(ok, "clear should succeed")
    assert_eq(err, nil, "clear error should be nil")

    local exists = SaveState.exists({
        filesystem = fs,
    })
    assert_true(not exists, "exists should be false after clear")
end

local tests = {
    {
        name = "when_no_save_file_exists_then_exists_returns_false",
        fn = test_when_no_save_file_exists_then_exists_returns_false,
    },
    {
        name = "when_legacy_save_file_exists_then_exists_returns_legacy_path",
        fn = test_when_legacy_save_file_exists_then_exists_returns_legacy_path,
    },
    {
        name = "when_saving_then_load_returns_payload_data",
        fn = test_when_saving_then_load_returns_payload_data,
    },
    {
        name = "when_loading_legacy_raw_table_then_data_is_returned",
        fn = test_when_loading_legacy_raw_table_then_data_is_returned,
    },
    {
        name = "when_clearing_then_all_candidate_files_are_removed",
        fn = test_when_clearing_then_all_candidate_files_are_removed,
    },
}

for _, test in ipairs(tests) do
    test.fn()
    print("ok - " .. test.name)
end
