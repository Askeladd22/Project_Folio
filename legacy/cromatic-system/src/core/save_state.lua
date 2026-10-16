local Schema = require("src.core.schema")
local LuaTableStore = require("src.core.lua_table_store")
local SavePersistenceSchema = require("src.data.save_persistence_schema")

local SaveState = {}

local expect_non_empty_list = Schema.expect_non_empty_list
local expect_string = Schema.expect_string
local expect_number = Schema.expect_number

local FILE_PATH = expect_string(SavePersistenceSchema.file_path, "save_persistence_schema.file_path")
local FILE_FORMAT = expect_string(SavePersistenceSchema.format, "save_persistence_schema.format")
local SAVE_VERSION = math.max(1, math.floor(expect_number(SavePersistenceSchema.version, "save_persistence_schema.version")))
local LEGACY_FILE_CANDIDATES = expect_non_empty_list(
    SavePersistenceSchema.legacy_file_candidates,
    "save_persistence_schema.legacy_file_candidates"
)

if FILE_FORMAT ~= "lua_table" then
    error("Unsupported save persistence format: " .. tostring(FILE_FORMAT))
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

local function resolve_filesystem(options)
    local opts = options or {}
    if opts.filesystem then
        return opts.filesystem
    end
    if love and love.filesystem then
        return love.filesystem
    end
    return nil
end

local function build_candidate_paths()
    local seen = {}
    local out = {}

    local function push(path)
        if type(path) ~= "string" or path == "" then
            return
        end
        if seen[path] then
            return
        end
        seen[path] = true
        out[#out + 1] = path
    end

    push(FILE_PATH)
    for _, candidate in ipairs(LEGACY_FILE_CANDIDATES) do
        push(candidate)
    end

    return out
end

local CANDIDATE_PATHS = build_candidate_paths()

function SaveState.exists(options)
    local fs = resolve_filesystem(options)
    if not fs or type(fs.getInfo) ~= "function" then
        return false, nil
    end

    for _, path in ipairs(CANDIDATE_PATHS) do
        if fs.getInfo(path) then
            return true, path
        end
    end

    return false, nil
end

function SaveState.load(options)
    local first_err = nil

    for _, path in ipairs(CANDIDATE_PATHS) do
        local payload, err, status = LuaTableStore.load(path, options)
        if payload then
            if type(payload.data) == "table" then
                return deep_copy(payload.data), nil, path
            end
            return deep_copy(payload), nil, path
        end

        if err and status ~= "missing" and status ~= "unavailable" and not first_err then
            first_err = err
        end
    end

    return nil, first_err, nil
end

function SaveState.save(data, options)
    if type(data) ~= "table" then
        return false, "SaveState.save expects table data"
    end

    local payload = {
        version = SAVE_VERSION,
        saved_at = os.time(),
        data = deep_copy(data),
    }
    return LuaTableStore.save(FILE_PATH, payload, options)
end

function SaveState.clear(options)
    local fs = resolve_filesystem(options)
    if not fs or type(fs.remove) ~= "function" then
        return false, "filesystem remove unavailable"
    end

    local first_err = nil
    for _, path in ipairs(CANDIDATE_PATHS) do
        local should_remove = (type(fs.getInfo) ~= "function") or (fs.getInfo(path) ~= nil)

        if should_remove then
            local ok, err = fs.remove(path)
            if (not ok) and (not first_err) then
                first_err = err
            end
        end
    end

    if first_err then
        return false, first_err
    end
    return true, nil
end

SaveState.FILE_PATH = FILE_PATH
SaveState.FILE_FORMAT = FILE_FORMAT
SaveState.VERSION = SAVE_VERSION
SaveState.CANDIDATE_PATHS = deep_copy(CANDIDATE_PATHS)

return SaveState
