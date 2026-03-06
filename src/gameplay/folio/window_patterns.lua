local WindowPatternsSchema = require("src.data.window_patterns_schema")

local WindowPatterns = {}

local WINDOWS_JSON_PATH = WindowPatternsSchema.windows_json_path or "resources/tiles/Windows.json"
local GRID_ROWS = tonumber(WindowPatternsSchema.grid_rows) or 4
local GRID_COLS = tonumber(WindowPatternsSchema.grid_cols) or 5
local COLOR_MAP = WindowPatternsSchema.color_map or {}
local COMMON_COLORS = WindowPatternsSchema.common_colors or {}
local FALLBACK_PATTERN = WindowPatternsSchema.fallback_pattern or {}
local LOCALIZED_NAMES = WindowPatternsSchema.localized_names or {}

local cached_raw_patterns = nil
local cached_patterns = nil
local cached_language = nil

local function apply_params(text, params)
    local value = type(text) == "string" and text or ""
    if type(params) ~= "table" then
        return value
    end
    for token, replacement in pairs(params) do
        value = value:gsub("{" .. tostring(token) .. "}", tostring(replacement))
    end
    return value
end

local function default_translate(key, fallback, params)
    local base = fallback
    if type(base) ~= "string" or base == "" then
        base = tostring(key or "")
    end
    return apply_params(base, params)
end

local dependencies = {
    translate = default_translate,
    get_language = function()
        return "English"
    end,
    json_decode = nil,
    log_debug = function(_msg)
    end,
}

local function tr(key, fallback, params)
    return dependencies.translate(key, fallback, params)
end

local function debug_log(msg)
    if dependencies.log_debug then
        dependencies.log_debug(msg)
    end
end

local function read_file(path)
    if love and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(path) then
        local ok, content = pcall(function()
            return love.filesystem.read(path)
        end)
        if ok and type(content) == "string" then
            return content
        end
    end

    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

local function normalize_constraint(raw)
    if raw == nil then
        return nil
    end
    local numeric = tonumber(raw)
    if numeric then
        numeric = math.floor(numeric)
        if numeric >= 1 and numeric <= 6 then
            return numeric
        end
        return nil
    end
    if type(raw) ~= "string" then
        return nil
    end
    local key = raw:upper()
    return COLOR_MAP[key] or key
end

local function empty_grid(rows, cols)
    local grid = {}
    for i = 1, rows * cols do
        grid[i] = nil
    end
    return grid
end

local function copy_array_with_size(values, size)
    local out = {}
    local source = type(values) == "table" and values or {}
    local count = math.max(0, math.floor(tonumber(size) or #source))
    for i = 1, count do
        out[i] = source[i]
    end
    return out
end

local function normalize_name(name)
    if type(name) ~= "string" then
        return nil
    end
    local compact = name:gsub("^%s+", ""):gsub("%s+$", "")
    if compact == "" then
        return nil
    end
    return compact:lower()
end

local function deep_copy_pattern(src)
    if not src then
        return nil
    end
    return {
        id = src.id,
        name = src.name,
        raw_name = src.raw_name,
        token = src.token,
        source_card_id = src.source_card_id,
        rows = src.rows,
        cols = src.cols,
        grid = copy_array_with_size(src.grid, (src.rows or GRID_ROWS) * (src.cols or GRID_COLS)),
        tile_keys = src.tile_keys and copy_array_with_size(src.tile_keys, (src.rows or GRID_ROWS) * (src.cols or GRID_COLS)) or nil,
        tile_markers = src.tile_markers and copy_array_with_size(src.tile_markers, (src.rows or GRID_ROWS) * (src.cols or GRID_COLS)) or nil,
    }
end

local function localize_pattern_name(raw_name)
    local normalized = normalize_name(raw_name)
    local localization = normalized and LOCALIZED_NAMES[normalized] or nil
    if type(localization) == "table" and type(localization.key) == "string" then
        return tr(localization.key, localization.default or raw_name)
    end
    return raw_name
end

local function get_fallback_pattern_raw()
    local grid = empty_grid(GRID_ROWS, GRID_COLS)
    return {
        id = FALLBACK_PATTERN.id or "fallback_window",
        name = FALLBACK_PATTERN.name_default or "Fallback Window",
        raw_name = FALLBACK_PATTERN.name_default or "Fallback Window",
        token = tonumber(FALLBACK_PATTERN.token) or 0,
        source_card_id = tonumber(FALLBACK_PATTERN.source_card_id) or -1,
        rows = GRID_ROWS,
        cols = GRID_COLS,
        grid = grid,
        tile_keys = nil,
        tile_markers = nil,
    }
end

local function localize_pattern(pattern)
    local out = deep_copy_pattern(pattern)
    local raw_name = out.raw_name or out.name

    if type(raw_name) == "string" and type(FALLBACK_PATTERN.name_key) == "string" and raw_name == (FALLBACK_PATTERN.name_default or "Fallback Window") then
        out.name = tr(FALLBACK_PATTERN.name_key, FALLBACK_PATTERN.name_default or raw_name)
    else
        out.name = localize_pattern_name(raw_name)
    end

    return out
end

local function localize_patterns(patterns)
    local out = {}
    for i, pattern in ipairs(patterns or {}) do
        out[i] = localize_pattern(pattern)
    end
    return out
end

local function parse_windows(decoded)
    if type(decoded) ~= "table" then
        return {}
    end

    local out = {}
    for _, card in ipairs(decoded) do
        local card_id = card and card.card_id or nil
        local windows = card and card.windows or nil
        if type(windows) == "table" then
            for _, window in ipairs(windows) do
                local grid = empty_grid(GRID_ROWS, GRID_COLS)
                local panes = window and (window.panes or window.cells) or nil
                if type(panes) == "table" then
                    for _, pane in ipairs(panes) do
                        local x = tonumber(pane and pane.x)
                        local y = tonumber(pane and pane.y)
                        if x and y then
                            local col = math.floor(x) + 1
                            local row = math.floor(y) + 1
                            if row >= 1 and row <= GRID_ROWS and col >= 1 and col <= GRID_COLS then
                                local idx = (row - 1) * GRID_COLS + col
                                grid[idx] = normalize_constraint(pane.constraint)
                            end
                        end
                    end
                end

                local raw_name = tostring(window and window.name or "Unnamed Window")

                out[#out + 1] = {
                    id = tostring(window and window.name or ("window_" .. tostring(#out + 1))),
                    name = raw_name,
                    raw_name = raw_name,
                    token = tonumber(window and window.token) or 0,
                    source_card_id = card_id,
                    rows = GRID_ROWS,
                    cols = GRID_COLS,
                    grid = grid,
                    tile_keys = nil,
                    tile_markers = nil,
                }
            end
        end
    end

    return out
end

function WindowPatterns.load(path)
    local content = read_file(path or WINDOWS_JSON_PATH)
    if type(content) ~= "string" or content == "" then
        debug_log("[WindowPatterns] Windows.json not found, using fallback pattern")
        return {get_fallback_pattern_raw()}
    end

    local decode = dependencies.json_decode
    if type(decode) ~= "function" then
        debug_log("[WindowPatterns] JSON decoder not configured, using fallback pattern")
        return {get_fallback_pattern_raw()}
    end

    local ok, decoded = pcall(decode, content)
    if not ok then
        debug_log("[WindowPatterns] JSON decode failed: " .. tostring(decoded))
        return {get_fallback_pattern_raw()}
    end

    local patterns = parse_windows(decoded)
    if #patterns == 0 then
        debug_log("[WindowPatterns] No windows found in JSON, using fallback pattern")
        return {get_fallback_pattern_raw()}
    end
    return patterns
end

function WindowPatterns.configure(opts)
    local options = type(opts) == "table" and opts or {}
    if type(options.translate) == "function" then
        dependencies.translate = options.translate
    end
    if type(options.get_language) == "function" then
        dependencies.get_language = options.get_language
    end
    if type(options.json_decode) == "function" then
        dependencies.json_decode = options.json_decode
    end
    if type(options.log_debug) == "function" then
        dependencies.log_debug = options.log_debug
    end
    WindowPatterns.invalidate_cache()
end

function WindowPatterns.getAll()
    if not cached_raw_patterns then
        cached_raw_patterns = WindowPatterns.load()
    end

    local language = dependencies.get_language and dependencies.get_language() or "English"
    if not cached_patterns or cached_language ~= language then
        cached_patterns = localize_patterns(cached_raw_patterns)
        cached_language = language
    end

    return cached_patterns
end

function WindowPatterns.pick(seed)
    local all = WindowPatterns.getAll()
    if #all == 0 then
        return localize_pattern(get_fallback_pattern_raw())
    end
    local n = math.floor(tonumber(seed) or os.time())
    local idx = (math.abs(n) % #all) + 1
    return deep_copy_pattern(all[idx])
end

function WindowPatterns.findByNameToken(name, token)
    local all = WindowPatterns.getAll()
    if #all <= 0 then
        return nil
    end

    local target_name = normalize_name(name)
    local target_token = tonumber(token)
    if target_token then
        target_token = math.floor(target_token)
    end

    if target_name and target_token ~= nil then
        for _, pattern in ipairs(all) do
            local pattern_name = normalize_name(pattern and pattern.name)
            local pattern_raw_name = normalize_name(pattern and pattern.raw_name)
            local pattern_token = tonumber(pattern and pattern.token)
            if pattern_token then
                pattern_token = math.floor(pattern_token)
            end
            local names_match = (pattern_name == target_name) or (pattern_raw_name == target_name)
            if names_match and pattern_token == target_token then
                return deep_copy_pattern(pattern)
            end
        end
    end

    if target_name then
        for _, pattern in ipairs(all) do
            local pattern_name = normalize_name(pattern and pattern.name)
            local pattern_raw_name = normalize_name(pattern and pattern.raw_name)
            if pattern_name == target_name or pattern_raw_name == target_name then
                return deep_copy_pattern(pattern)
            end
        end
    end

    if target_token ~= nil then
        for _, pattern in ipairs(all) do
            local pattern_token = tonumber(pattern and pattern.token)
            if pattern_token and math.floor(pattern_token) == target_token then
                return deep_copy_pattern(pattern)
            end
        end
    end

    return nil
end

function WindowPatterns.getCommonColors()
    return copy_array_with_size(COMMON_COLORS, #COMMON_COLORS)
end

function WindowPatterns.invalidate_cache()
    cached_raw_patterns = nil
    cached_patterns = nil
    cached_language = nil
end

return WindowPatterns
