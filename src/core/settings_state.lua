
local SettingsState = {}
local Logger = require("src.core.logger")
local RuntimeState = require("src.core.runtime_state")
local LuaTableStore = require("src.core.lua_table_store")
local Schema = require("src.core.schema")
local SettingsSchema = require("src.data.settings_schema")
local SettingsPersistenceSchema = require("src.data.settings_persistence_schema")

local expect_string = Schema.expect_string
local FILE_PATH = expect_string(SettingsPersistenceSchema.file_path, "settings_persistence_schema.file_path")
local FILE_FORMAT = expect_string(SettingsPersistenceSchema.format, "settings_persistence_schema.format")
local LEGACY_PATH = expect_string(SettingsPersistenceSchema.legacy_file_path, "settings_persistence_schema.legacy_file_path")

if FILE_FORMAT ~= "json" then
    error("Unsupported settings persistence format: " .. tostring(FILE_FORMAT))
end

local BASE_DEFAULTS = {
    game = {
        language = "English",
        verbose_logs = false,
    },
    controls = {
        mouse_sensitivity = 0.55,
        invert_y = false,
        prompt_input = "Keyboard",
    },
    accessibility = {
        big_text = false,
        high_contrast = false,
        reduced_animations = false,
    },
    video = {
        window_mode = "Borderless",
        fps_limit = 0,
        show_fps = false,
    },
    audio = {
        master_volume = 0.8,
        sfx_volume = 0.7,
        music_volume = 0.6,
        mute_sfx = false,
        mute_music = false,
    },
}

local current = nil
local last_windowed_w = nil
local last_windowed_h = nil

local function clamp(v, min_v, max_v)
    if v < min_v then return min_v end
    if v > max_v then return max_v end
    return v
end

local function deep_copy(value)
    if type(value) ~= "table" then
        return value
    end

    local out = {}
    for k, v in pairs(value) do
        out[k] = deep_copy(v)
    end
    return out
end

local function copy_table(tbl)
    local out = {}
    if type(tbl) ~= "table" then
        return out
    end
    for k, v in pairs(tbl) do
        out[k] = v
    end
    return out
end

local function split_path(path)
    local parts = {}
    for part in string.gmatch(path or "", "[^%.]+") do
        parts[#parts + 1] = part
    end
    return parts
end

local function get_path_value(tbl, path)
    local curr = tbl
    for _, part in ipairs(split_path(path)) do
        if type(curr) ~= "table" then
            return nil
        end
        curr = curr[part]
    end
    return curr
end

local function set_path_value(tbl, path, value)
    local parts = split_path(path)
    if #parts == 0 then
        return
    end
    local curr = tbl
    for i = 1, #parts - 1 do
        local key = parts[i]
        if type(curr[key]) ~= "table" then
            curr[key] = {}
        end
        curr = curr[key]
    end
    curr[parts[#parts]] = value
end

local function merge_with_defaults(default_value, loaded_value)
    if type(default_value) ~= "table" then
        if type(loaded_value) == type(default_value) then
            return loaded_value
        end
        return default_value
    end

    local out = {}
    for k, dv in pairs(default_value) do
        local lv = nil
        if type(loaded_value) == "table" then
            lv = loaded_value[k]
        end
        out[k] = merge_with_defaults(dv, lv)
    end
    return out
end

local function merge_tables_union(primary, fallback)
    if type(primary) ~= "table" then
        if primary ~= nil then
            return primary
        end
        return deep_copy(fallback)
    end

    local out = {}
    if type(fallback) == "table" then
        for key, value in pairs(fallback) do
            out[key] = deep_copy(value)
        end
    end

    for key, value in pairs(primary) do
        if type(value) == "table" and type(out[key]) == "table" then
            out[key] = merge_tables_union(value, out[key])
        else
            out[key] = deep_copy(value)
        end
    end

    return out
end

local function build_defaults_from_schema(schema)
    local out = {}
    local tabs = type(schema) == "table" and schema.tabs or {}

    for _, tab in ipairs(tabs or {}) do
        local controls = type(tab) == "table" and tab.controls or {}
        for _, control in ipairs(controls or {}) do
            local setting = type(control) == "table" and control.setting or nil
            if type(setting) == "string" and setting ~= "" then
                local default_value = nil
                if control.type == "choice" then
                    local idx = math.floor(tonumber(control.default_index) or tonumber(control.value_index) or 1)
                    if idx < 1 then
                        idx = 1
                    end
                    if type(control.value_map) == "table" and control.value_map[idx] ~= nil then
                        default_value = control.value_map[idx]
                    elseif type(control.options) == "table" and control.options[idx] ~= nil then
                        default_value = control.options[idx]
                    end
                elseif control.default ~= nil then
                    default_value = control.default
                elseif control.value ~= nil then
                    default_value = control.value
                end

                if default_value ~= nil then
                    set_path_value(out, setting, default_value)
                end
            end
        end
    end

    return out
end

local function build_choice_validators(schema)
    local out = {}
    local tabs = type(schema) == "table" and schema.tabs or {}

    for _, tab in ipairs(tabs or {}) do
        local controls = type(tab) == "table" and tab.controls or {}
        for _, control in ipairs(controls or {}) do
            if control.type == "choice" and type(control.setting) == "string" then
                local allowed = {}
                if type(control.value_map) == "table" then
                    for _, value in ipairs(control.value_map) do
                        allowed[value] = true
                    end
                elseif type(control.options) == "table" then
                    for _, value in ipairs(control.options) do
                        allowed[value] = true
                    end
                end

                if next(allowed) then
                    out[control.setting] = allowed
                end
            end
        end
    end

    return out
end

local SCHEMA_DEFAULTS = build_defaults_from_schema(SettingsSchema)
local DEFAULTS = merge_tables_union(SCHEMA_DEFAULTS, BASE_DEFAULTS)
local CHOICE_VALIDATORS = build_choice_validators(SettingsSchema)

local function normalize_choice(out, path)
    local allowed = CHOICE_VALIDATORS[path]
    if type(allowed) ~= "table" then
        return
    end

    local value = get_path_value(out, path)
    if allowed[value] then
        return
    end

    set_path_value(out, path, get_path_value(DEFAULTS, path))
end

local function normalize(data)
    local out = merge_with_defaults(DEFAULTS, data)

    normalize_choice(out, "game.language")
    out.game.verbose_logs = out.game.verbose_logs and true or false

    normalize_choice(out, "controls.prompt_input")
    out.controls.mouse_sensitivity = clamp(tonumber(out.controls.mouse_sensitivity) or DEFAULTS.controls.mouse_sensitivity, 0, 1)
    out.controls.invert_y = out.controls.invert_y and true or false

    out.accessibility.big_text = out.accessibility.big_text and true or false
    out.accessibility.high_contrast = out.accessibility.high_contrast and true or false
    out.accessibility.reduced_animations = out.accessibility.reduced_animations and true or false

    normalize_choice(out, "video.window_mode")
    out.video.fps_limit = tonumber(out.video.fps_limit) or DEFAULTS.video.fps_limit
    normalize_choice(out, "video.fps_limit")
    out.video.show_fps = out.video.show_fps and true or false

    out.audio.master_volume = clamp(tonumber(out.audio.master_volume) or DEFAULTS.audio.master_volume, 0, 1)
    out.audio.sfx_volume = clamp(tonumber(out.audio.sfx_volume) or DEFAULTS.audio.sfx_volume, 0, 1)
    out.audio.music_volume = clamp(tonumber(out.audio.music_volume) or DEFAULTS.audio.music_volume, 0, 1)
    out.audio.mute_sfx = out.audio.mute_sfx and true or false
    out.audio.mute_music = out.audio.mute_music and true or false

    return out
end

local function ensure_current()
    if not current then
        current = deep_copy(DEFAULTS)
    end
end

local function sanitize_dimension(v, fallback)
    local n = math.floor(tonumber(v) or fallback or 0)
    if n < 1 then
        return math.floor(fallback or 1)
    end
    return n
end

local function get_desktop_dimensions(flags, fallback_w, fallback_h)
    local out_w = sanitize_dimension(fallback_w, 1280)
    local out_h = sanitize_dimension(fallback_h, 720)

    if not (love and love.window and love.window.getDesktopDimensions) then
        return out_w, out_h
    end

    local display_index = 1
    if type(flags) == "table" and type(flags.display) == "number" then
        display_index = flags.display
    end

    local ok, dw, dh = pcall(love.window.getDesktopDimensions, display_index)
    if ok and type(dw) == "number" and type(dh) == "number" and dw > 0 and dh > 0 then
        return math.floor(dw), math.floor(dh)
    end

    return out_w, out_h
end

local function default_windowed_size(desktop_w, desktop_h)
    local min_w = math.min(960, desktop_w)
    local min_h = math.min(540, desktop_h)
    local w = clamp(math.floor(desktop_w * 0.84), min_w, desktop_w)
    local h = clamp(math.floor(desktop_h * 0.84), min_h, desktop_h)
    return w, h
end

function SettingsState.get_defaults()
    return deep_copy(DEFAULTS)
end

function SettingsState.get()
    ensure_current()
    return deep_copy(current)
end

function SettingsState.set(next_settings)
    current = normalize(next_settings)
    return deep_copy(current)
end

function SettingsState.reset()
    current = deep_copy(DEFAULTS)
    return deep_copy(current)
end

function SettingsState.load()
    local loaded, err, status = LuaTableStore.load(FILE_PATH)
    if status == "invalid_data" or status == "load_error" then
        Logger.debug("[SettingsState] primary data damaged: "..tostring(err))
        loaded = LuaTableStore.load(FILE_PATH..".bak")
    elseif status == "missing" then
        -- Restricted parser: reads only table literals, NEVER executes Lua.
        local legacy,legacy_err = LuaTableStore.load(LEGACY_PATH,{legacy=true})
        if legacy then
            loaded = legacy
            local ok,write_err = LuaTableStore.save(FILE_PATH,normalize(legacy))
            if not ok then
                Logger.debug("[SettingsState] migration pending: "..tostring(write_err))
            end
        elseif legacy_err then
            Logger.debug("[SettingsState] legacy data rejected: "..tostring(legacy_err))
        end
    end
    current = normalize(loaded)
    return deep_copy(current)
end

function SettingsState.save()
    ensure_current()
    local ok, err = LuaTableStore.save(FILE_PATH, current)
    return ok, err
end

function SettingsState.apply()
    ensure_current()
    Logger.set_enabled(current.game and current.game.verbose_logs)

    if love and love.audio and love.audio.setVolume then
        pcall(function()
            love.audio.setVolume(current.audio.master_volume)
        end)
    end

    if love and love.window and love.window.getMode and love.window.setMode then
        local mode = current.video.window_mode
        local curr_w, curr_h, curr_flags = love.window.getMode()
        curr_w = sanitize_dimension(curr_w, 1280)
        curr_h = sanitize_dimension(curr_h, 720)
        curr_flags = curr_flags or {}

        local desktop_w, desktop_h = get_desktop_dimensions(curr_flags, curr_w, curr_h)
        local target_w
        local target_h
        local flags = copy_table(curr_flags)

        if not curr_flags.fullscreen and not curr_flags.borderless then
            if curr_w < desktop_w or curr_h < desktop_h then
                last_windowed_w = curr_w
                last_windowed_h = curr_h
            end
        end

        flags.resizable = true
        local fps_limit = tonumber(current.video.fps_limit) or 0
        if fps_limit <= 0 then
            -- Unlimited FPS requires disabling VSync, otherwise refresh rate still caps frames.
            flags.vsync = 0
        elseif flags.vsync == nil or flags.vsync == 0 then
            flags.vsync = 1
        end

        if mode == "Fullscreen" then
            flags.fullscreen = true
            flags.fullscreentype = "desktop"
            flags.borderless = false
            target_w = desktop_w
            target_h = desktop_h
            flags.x = nil
            flags.y = nil
        elseif mode == "Borderless" then
            flags.fullscreen = false
            flags.fullscreentype = "desktop"
            flags.borderless = true
            target_w = desktop_w
            target_h = desktop_h
            flags.x = 0
            flags.y = 0
        else
            flags.fullscreen = false
            flags.fullscreentype = "desktop"
            flags.borderless = false
            local default_w, default_h = default_windowed_size(desktop_w, desktop_h)
            local min_w = math.min(960, desktop_w)
            local min_h = math.min(540, desktop_h)
            local can_use_saved = (type(last_windowed_w) == "number" and type(last_windowed_h) == "number")
            if can_use_saved and last_windowed_w >= desktop_w and last_windowed_h >= desktop_h then
                can_use_saved = false
            end

            local source_w = can_use_saved and last_windowed_w or default_w
            local source_h = can_use_saved and last_windowed_h or default_h
            target_w = clamp(sanitize_dimension(source_w, default_w), min_w, desktop_w)
            target_h = clamp(sanitize_dimension(source_h, default_h), min_h, desktop_h)
            flags.x = nil
            flags.y = nil
        end

        local ok, success = pcall(love.window.setMode, target_w, target_h, flags)
        if (not ok) or (success == false) then
            local fallback_flags = {
                resizable = true,
                vsync = flags.vsync or 1,
                fullscreen = false,
                fullscreentype = "desktop",
                borderless = false,
            }
            pcall(love.window.setMode, target_w, target_h, fallback_flags)
            Logger.debug("[SettingsState] window mode apply failed, fallback to windowed.")
        elseif mode == "Windowed" then
            last_windowed_w = target_w
            last_windowed_h = target_h
        end
    end

    RuntimeState.apply_settings(current)
end

SettingsState.FILE_PATH = FILE_PATH

return SettingsState
