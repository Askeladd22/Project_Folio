local FolioTurn = require("src.gameplay.folio.turn")
local WindowPatterns = require("src.gameplay.folio.window_patterns")
local Colors = require("src.data.colors")
local FolioSchema = require("src.data.folio_schema")

local Folio = {}
Folio.__index = Folio

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

Folio.ELEMENTS = {"TEXT"}

Folio.BONUS = {
    TEXT = {coins = 20, reputation = 1},
}

local GRID_ROWS = 4
local GRID_COLS = 5
local PRICKING_GUIDED_ROWS = 2
local DEFAULT_MAX_OPEN_ROWS = 2
local DEFAULT_REROLL_MAX = 2
local DEFAULT_OBJECTIVE_ROWS = 2
local BUST_STAIN_CHOICES = 2
local DEFAULT_WET_BUFFER_MAX = 3
local TURN_PALETTE_SIZE = 3

local INKWELL_COLORS = Colors.inkwell_order
local INK_BASE_COLOR_A = "NERO"
local INK_BASE_COLOR_B = "MARRONE"
local INK_BASE_CAP = 4
local INK_COMMON_CAP = 3
local INK_RARE_CAP = 2

local VALUE_TO_COLOR = Colors.value_to_color
local COLOR_ALIASES = Colors.aliases

function Folio.configure(opts)
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

    if WindowPatterns and WindowPatterns.configure then
        WindowPatterns.configure({
            translate = dependencies.translate,
            get_language = dependencies.get_language,
            json_decode = dependencies.json_decode,
            log_debug = dependencies.log_debug,
        })
    end
end

local function random_int(min_v, max_v)
    local rnd = (love and love.math and love.math.random) or math.random
    return rnd(min_v, max_v)
end

local function row_col_to_index(pattern, row, col)
    return (row - 1) * pattern.cols + col
end

local function index_to_row_col(pattern, index)
    local row = math.floor((index - 1) / pattern.cols) + 1
    local col = ((index - 1) % pattern.cols) + 1
    return row, col
end

local function shallow_copy_array(values)
    local out = {}
    for i = 1, #values do
        out[i] = values[i]
    end
    return out
end

local function shallow_copy_table(src)
    local out = {}
    for k, v in pairs(src or {}) do
        out[k] = v
    end
    return out
end

local function list_contains(values, target)
    for _, value in ipairs(values or {}) do
        if value == target then
            return true
        end
    end
    return false
end

local function clamp_row(row, max_rows)
    local n = tonumber(row)
    if not n then
        return nil
    end
    n = math.floor(n)
    if n < 1 or n > max_rows then
        return nil
    end
    return n
end

local function normalized_unique_rows(rows, max_rows)
    local out = {}
    local seen = {}
    for _, row in ipairs(rows or {}) do
        local r = clamp_row(row, max_rows)
        if r and not seen[r] then
            seen[r] = true
            out[#out + 1] = r
        end
    end
    table.sort(out)
    return out
end

local function clamp_integer(value, fallback, min_v, max_v)
    local n = tonumber(value)
    if n == nil then
        n = fallback
    end
    n = math.floor(tonumber(n) or fallback or 0)
    if min_v ~= nil and n < min_v then
        n = min_v
    end
    if max_v ~= nil and n > max_v then
        n = max_v
    end
    return n
end

local function build_default_guided_rows(row_count, required_guided_rows)
    local rows = math.max(1, math.floor(tonumber(row_count) or GRID_ROWS))
    local required = math.max(1, math.floor(tonumber(required_guided_rows) or PRICKING_GUIDED_ROWS))
    if required > rows then
        required = rows
    end

    local out = {}
    if required <= 1 then
        out[1] = 1
        return out
    end

    out[#out + 1] = 1
    out[#out + 1] = math.min(rows, 3)
    while #out < required do
        local candidate = math.min(rows, #out + 1)
        if not list_contains(out, candidate) then
            out[#out + 1] = candidate
        else
            break
        end
    end
    table.sort(out)
    return out
end

local function normalize_color_key(color)
    if type(color) ~= "string" then
        return nil
    end
    local key = color:upper()
    return COLOR_ALIASES[key] or key
end

local function normalize_constraint(constraint)
    local numeric = tonumber(constraint)
    if numeric then
        numeric = math.floor(numeric)
        if numeric >= 1 and numeric <= 6 then
            return numeric
        end
        return nil
    end
    return normalize_color_key(constraint)
end

local function normalize_row_rule(rule)
    if type(rule) == "table" then
        local entry = shallow_copy_table(rule)
        local raw = entry.type or entry.kind or entry.id
        if raw ~= nil then
            entry.type = tostring(raw):upper()
        else
            entry.type = "UNKNOWN"
        end
        return entry
    end
    if rule == nil then
        return nil
    end
    return {type = tostring(rule):upper()}
end

local function normalize_row_rules(row_rules, row_count)
    local out = {}
    if type(row_rules) ~= "table" then
        return out
    end
    for row, rules in pairs(row_rules) do
        local r = clamp_row(row, row_count)
        if r then
            local list = {}
            if type(rules) ~= "table" or (#rules == 0 and rules.type) then
                rules = {rules}
            end
            for _, rule in ipairs(rules or {}) do
                local entry = normalize_row_rule(rule)
                if entry and entry.type and entry.type ~= "" then
                    list[#list + 1] = entry
                end
            end
            if #list > 0 then
                out[r] = list
            end
        end
    end
    return out
end

local function shuffled_copy(values)
    local out = shallow_copy_array(values or {})
    for i = #out, 2, -1 do
        local j = random_int(1, i)
        out[i], out[j] = out[j], out[i]
    end
    return out
end

local function build_inkwell()
    local caps = {}
    local drops = {}
    for _, color in ipairs(INKWELL_COLORS) do
        caps[color] = INK_RARE_CAP
        drops[color] = INK_RARE_CAP
    end

    caps[INK_BASE_COLOR_A] = INK_BASE_CAP
    drops[INK_BASE_COLOR_A] = INK_BASE_CAP
    caps[INK_BASE_COLOR_B] = INK_BASE_CAP
    drops[INK_BASE_COLOR_B] = INK_BASE_CAP

    local variable_colors = {}
    for _, color in ipairs(INKWELL_COLORS) do
        if color ~= INK_BASE_COLOR_A and color ~= INK_BASE_COLOR_B then
            variable_colors[#variable_colors + 1] = color
        end
    end

    local shuffled = shuffled_copy(variable_colors)
    for i, color in ipairs(shuffled) do
        local cap = (i <= 3) and INK_COMMON_CAP or INK_RARE_CAP
        caps[color] = cap
        drops[color] = cap
    end

    return caps, drops, shallow_copy_array(INKWELL_COLORS)
end

local function get_pattern_from_windows(seed, scenario)
    local picked = nil
    if type(scenario) == "table" then
        picked = WindowPatterns.findByNameToken(scenario.pattern_name, scenario.token)
    end
    if not picked then
        picked = WindowPatterns.pick(seed)
    end
    if not picked then
        picked = WindowPatterns.pick(os.time())
    end
    picked.rows = GRID_ROWS
    picked.cols = GRID_COLS
    for i = 1, GRID_ROWS * GRID_COLS do
        picked.grid[i] = normalize_constraint(picked.grid[i])
    end
    return picked
end

---@param folio_set_type string
---@param seed? number
---@param run_setup? table
---@param scenario? table
---@return table
function Folio.new(folio_set_type, seed, run_setup, scenario)
    local self = setmetatable({}, Folio)

    self.folio_set = folio_set_type or "BIFOLIO"
    self.seed = tonumber(seed) or os.time()
    self.run_setup = run_setup or {cards = {}, effects = {}}
    self.rule_cards = self.run_setup.cards or {}
    self.rule_effects = self.run_setup.effects or {}

    local active_scenario = scenario
    if type(active_scenario) ~= "table" then
        active_scenario = type(self.run_setup.scenario) == "table" and self.run_setup.scenario or {}
    end
    self.scenario = active_scenario

    local pattern = get_pattern_from_windows(self.seed, active_scenario)
    local row_count = tonumber(pattern.rows) or GRID_ROWS
    local objective_target = clamp_integer(active_scenario.objective_rows, DEFAULT_OBJECTIVE_ROWS, 1, row_count)
    local objective_kind = tostring(active_scenario.objective_kind or "complete_rows")
    local objective_stain_cap = clamp_integer(active_scenario.objective_stain_cap, 2, 0, self:getStainThreshold())
    self.objective = {
        kind = objective_kind,
        target = objective_target,
        stain_cap = objective_stain_cap,
    }

    local total_cells = (pattern.rows or GRID_ROWS) * (pattern.cols or GRID_COLS)

    self.elements = {
        TEXT = {
            pattern = pattern,
            placed = {},
            wet = {},
            stained = {},
            cells_filled = 0,
            cells_total = total_cells,
            unlocked = true,
            completed = false,
        },
    }

    for i = 1, total_cells do
        self.elements.TEXT.placed[i] = nil
        self.elements.TEXT.wet[i] = nil
        self.elements.TEXT.stained[i] = nil
    end

    self.active_element = "TEXT"
    self.ink_caps, self.ink_drops, self.ink_colors = build_inkwell()

    self.required_guided_rows = clamp_integer(active_scenario.required_guided_rows, PRICKING_GUIDED_ROWS, 1, row_count)
    self.max_open_rows = clamp_integer(active_scenario.max_open_rows, DEFAULT_MAX_OPEN_ROWS, 1, row_count)
    self.bust_choice_count = clamp_integer(active_scenario.bust_choice_count, BUST_STAIN_CHOICES, 1, total_cells)
    self.bust_open_rows_only = active_scenario.bust_open_rows_only and true or false
    self.reroll_max = clamp_integer(active_scenario.reroll_max, DEFAULT_REROLL_MAX, 0, 99)
    self.row_rules = active_scenario.enable_row_rules and normalize_row_rules(active_scenario.row_rules, row_count) or {}
    self.guided_rows = {}
    self.open_rows = {}
    self.parchment_configured = false

    self.stain_count = 0
    self.stain_threshold = self:getStainThreshold()
    self.busted = false

    self.wet_buffer = {}
    self.turn_risk = 0
    self.turn_pushes = 0
    self.turn_flags = {}
    self.turn_count = 0
    self.bust_count = 0
    self.turn_palette = nil
    self.wet_buffer_max = DEFAULT_WET_BUFFER_MAX

    self.quality = 0
    self.completed = false

    local prep_enabled = (active_scenario.enable_preparation == true)
        or (self.rule_effects and self.rule_effects.preparation_enabled == true)
    local default_tool_uses = (self.rule_effects and self.rule_effects.tool_knife) and 1 or 0
    local default_starting_seals = clamp_integer(self.rule_effects and self.rule_effects.starting_seals, 0, 0, 99)

    self.shield = 0
    self.preparation_enabled = prep_enabled and true or false
    self.preparation_guard = 0
    self.tool_uses_left = clamp_integer(active_scenario.tool_uses, default_tool_uses, 0, 99)
    self.seals = clamp_integer(active_scenario.starting_seals, default_starting_seals, 0, 99)

    local default_guided = build_default_guided_rows(row_count, self.required_guided_rows)
    self:configureParchment(default_guided, default_guided[1], self.max_open_rows)

    return self
end

function Folio:getStainThreshold()
    local thresholds = {
        BIFOLIO = 5,
        DUERNO = 6,
        TERNIONE = 6,
        QUATERNIONE = 7,
        QUINTERNO = 7,
        SESTERNO = 8,
    }
    return thresholds[self.folio_set] or 6
end

function Folio:getPatternName()
    local elem = self.elements[self.active_element]
    if elem and elem.pattern and elem.pattern.name then
        return elem.pattern.name
    end
    local pattern_schema = FolioSchema.pattern or {}
    return tr(pattern_schema.fallback_name_key, pattern_schema.fallback_name_default or "Window")
end

function Folio:getPatternToken()
    local elem = self.elements[self.active_element]
    return elem and elem.pattern and (elem.pattern.token or 0) or 0
end

function Folio:getObjectiveProgress()
    local objective_schema = FolioSchema.objective or {}
    local completed_rows = self:getCompletedRowsCount(self.active_element)
    local target = self.objective and self.objective.target or DEFAULT_OBJECTIVE_ROWS
    local kind = self.objective and tostring(self.objective.kind or "complete_rows") or "complete_rows"
    if kind == "clean_rows" then
        local cap = self.objective and tonumber(self.objective.stain_cap) or 2
        local label = tr(
            objective_schema.clean_rows_label_key,
            objective_schema.clean_rows_label_default or "Complete rows (<= {cap} stains)",
            {cap = tostring(cap)}
        )
        return completed_rows, target, label
    end
    return completed_rows, target, tr(
        objective_schema.complete_rows_label_key,
        objective_schema.complete_rows_label_default or "Complete rows"
    )
end

function Folio:getRowCount(element)
    local _, elem = self:_resolveElement(element)
    if not elem or not elem.pattern then
        return GRID_ROWS
    end
    return tonumber(elem.pattern.rows) or GRID_ROWS
end

function Folio:isParchmentConfigured()
    return self.parchment_configured and true or false
end

function Folio:getGuidedRows()
    return shallow_copy_array(self.guided_rows or {})
end

function Folio:getOpenRows()
    return shallow_copy_array(self.open_rows or {})
end

function Folio:getInkColors()
    return shallow_copy_array(self.ink_colors or INKWELL_COLORS)
end

function Folio:getInkDrops(color)
    local key = normalize_color_key(color)
    if not key then
        return 0
    end
    return math.max(0, math.floor(tonumber(self.ink_drops and self.ink_drops[key]) or 0))
end

function Folio:getInkCap(color)
    local key = normalize_color_key(color)
    if not key then
        return 0
    end
    return math.max(0, math.floor(tonumber(self.ink_caps and self.ink_caps[key]) or 0))
end

function Folio:getAvailableInkColors()
    local colors = self:getInkColors()
    local out = {}
    for _, color in ipairs(colors) do
        if self:getInkDrops(color) > 0 then
            out[#out + 1] = color
        end
    end
    return out
end

function Folio:getRecoverableInkColors()
    local colors = self:getInkColors()
    local out = {}
    for _, color in ipairs(colors) do
        if self:getInkDrops(color) < self:getInkCap(color) then
            out[#out + 1] = color
        end
    end
    return out
end

function Folio:getInkwellState()
    local state = {}
    for _, color in ipairs(self:getInkColors()) do
        local drops = self:getInkDrops(color)
        local cap = self:getInkCap(color)
        state[#state + 1] = {
            color = color,
            drops = drops,
            cap = cap,
            depleted = drops <= 0,
            recoverable = drops < cap,
        }
    end
    return state
end

function Folio:canSpendInk(color, amount)
    local key = normalize_color_key(color)
    if not key then
        return false
    end
    local qty = math.max(1, math.floor(tonumber(amount) or 1))
    return self:getInkDrops(key) >= qty
end

function Folio:spendInk(color, amount)
    local key = normalize_color_key(color)
    if not key then
        return false, "Invalid color"
    end
    local qty = math.max(1, math.floor(tonumber(amount) or 1))
    local current = self:getInkDrops(key)
    if current < qty then
        return false, "Pigment depleted"
    end
    self.ink_drops[key] = current - qty
    return true
end

function Folio:recoverInk(color, amount)
    local key = normalize_color_key(color)
    if not key then
        return 0, "Invalid color"
    end
    local qty = math.max(1, math.floor(tonumber(amount) or 1))
    local current = self:getInkDrops(key)
    local cap = self:getInkCap(key)
    local next_value = math.min(cap, current + qty)
    local recovered = next_value - current
    self.ink_drops[key] = next_value
    return recovered, nil
end

function Folio:isGuidedRow(row)
    local row_count = self:getRowCount(self.active_element)
    local normalized = clamp_row(row, row_count)
    if not normalized then
        return false
    end
    return list_contains(self.guided_rows, normalized)
end

function Folio:isRowOpen(row)
    local row_count = self:getRowCount(self.active_element)
    local normalized = clamp_row(row, row_count)
    if not normalized then
        return false
    end
    return list_contains(self.open_rows, normalized)
end

function Folio:canRowBeOpened(row)
    local row_count = self:getRowCount(self.active_element)
    local normalized = clamp_row(row, row_count)
    if not normalized then
        return false, "Invalid row"
    end
    return true
end

function Folio:configureParchment(guided_rows, initial_open_row, max_open_rows)
    local row_count = self:getRowCount(self.active_element)
    local normalized_guided = normalized_unique_rows(guided_rows, row_count)
    if #normalized_guided ~= self.required_guided_rows then
        return false, string.format("Pick exactly %d guided rows", self.required_guided_rows)
    end

    local max_rows = tonumber(max_open_rows) and math.floor(tonumber(max_open_rows)) or self.max_open_rows
    if max_rows < 1 then
        max_rows = 1
    end
    self.max_open_rows = max_rows
    self.guided_rows = normalized_guided

    local preferred_initial = clamp_row(initial_open_row, row_count)
    local open_rows = {}
    if preferred_initial and list_contains(normalized_guided, preferred_initial) then
        open_rows[#open_rows + 1] = preferred_initial
    end
    for _, row in ipairs(normalized_guided) do
        if #open_rows >= self.max_open_rows then
            break
        end
        if not list_contains(open_rows, row) then
            open_rows[#open_rows + 1] = row
        end
    end
    if #open_rows == 0 then
        open_rows[1] = normalized_guided[1]
    end
    table.sort(open_rows)

    self.open_rows = open_rows
    self.parchment_configured = true
    return true
end

function Folio:openRow(row)
    if not self:isParchmentConfigured() then
        return false, "Prepare parchment first"
    end

    local row_count = self:getRowCount(self.active_element)
    local normalized = clamp_row(row, row_count)
    if not normalized then
        return false, "Invalid row"
    end
    if self:isRowOpen(normalized) then
        return true, "Row already open"
    end
    local can_open, reason = self:canRowBeOpened(normalized)
    if not can_open then
        return false, reason
    end
    if #self.open_rows >= self.max_open_rows then
        return false, "Max open rows reached. Close one row first."
    end
    self.open_rows[#self.open_rows + 1] = normalized
    table.sort(self.open_rows)
    return true
end

function Folio:closeRow(row, _skip_adjacency_check)
    if not self:isParchmentConfigured() then
        return false, "Prepare parchment first"
    end

    local row_count = self:getRowCount(self.active_element)
    local normalized = clamp_row(row, row_count)
    if not normalized then
        return false, "Invalid row"
    end
    if not self:isRowOpen(normalized) then
        return false, "Row already closed"
    end
    if #self.open_rows <= 1 then
        return false, "At least one row must stay open"
    end
    for i, opened in ipairs(self.open_rows) do
        if opened == normalized then
            table.remove(self.open_rows, i)
            return true
        end
    end
    return false, "Row already closed"
end

function Folio:getRowManagementState()
    return {
        row_count = self:getRowCount(self.active_element),
        required_guided_rows = self.required_guided_rows,
        max_open_rows = self.max_open_rows,
        guided_rows = self:getGuidedRows(),
        open_rows = self:getOpenRows(),
        configured = self:isParchmentConfigured(),
        row_rules = self:getRowRules(),
    }
end

function Folio:getRowRules(row)
    local row_count = self:getRowCount(self.active_element)
    if row ~= nil then
        local normalized = clamp_row(row, row_count)
        if not normalized then
            return {}
        end
        local rules = self.row_rules and self.row_rules[normalized] or nil
        return shallow_copy_array(rules or {})
    end
    local out = {}
    for i = 1, row_count do
        local rules = self.row_rules and self.row_rules[i] or nil
        if rules and #rules > 0 then
            out[i] = shallow_copy_array(rules)
        end
    end
    return out
end

function Folio:_resolveElement(element)
    local key = element or self.active_element
    local elem = self.elements[key]
    return key, elem
end

function Folio:_normalizePlacementColor(dice_value, dice_color)
    local color = normalize_color_key(dice_color)
    if color then
        return color
    end
    return VALUE_TO_COLOR[dice_value]
end

function Folio:_canPlaceInBounds(pattern, row, col)
    if row < 1 or col < 1 then
        return false
    end
    if row > (pattern.rows or GRID_ROWS) or col > (pattern.cols or GRID_COLS) then
        return false
    end
    return true
end

function Folio:_matchesConstraint(constraint, dice_value, dice_color)
    if constraint == nil then
        return true, nil
    end
    if type(constraint) == "number" then
        if dice_value == constraint then
            return true, nil
        end
        return false, string.format("Requires value %d", constraint)
    end
    if type(constraint) == "string" then
        if dice_color == constraint then
            return true, nil
        end
        return false, "Requires color " .. tostring(constraint)
    end
    return false, "Invalid constraint"
end

function Folio:_rowHasColor(elem, row, color)
    if not elem or not elem.pattern then
        return false
    end
    local cols = elem.pattern.cols or GRID_COLS
    for col = 1, cols do
        local idx = row_col_to_index(elem.pattern, row, col)
        local placed = elem.placed[idx] or elem.wet[idx]
        if placed and placed.color == color then
            return true
        end
    end
    return false
end

function Folio:_rowHasValue(elem, row, value)
    if not elem or not elem.pattern then
        return false
    end
    local cols = elem.pattern.cols or GRID_COLS
    for col = 1, cols do
        local idx = row_col_to_index(elem.pattern, row, col)
        local placed = elem.placed[idx] or elem.wet[idx]
        if placed and placed.value == value then
            return true
        end
    end
    return false
end

function Folio:_matchesRowRules(elem, row, col, value, color)
    local rules = self.row_rules and self.row_rules[row] or nil
    if not rules or #rules == 0 then
        return true, nil, nil
    end
    for _, rule in ipairs(rules) do
        local kind = rule and rule.type or nil
        if kind == "ODD_ONLY" then
            if value % 2 == 0 then
                return false, "Row requires odd values", "value"
            end
        elseif kind == "EVEN_ONLY" then
            if value % 2 ~= 0 then
                return false, "Row requires even values", "value"
            end
        elseif kind == "NO_COLOR_REPEAT" then
            if self:_rowHasColor(elem, row, color) then
                return false, "Row forbids repeated colors", "color"
            end
        elseif kind == "NO_VALUE_REPEAT" then
            if self:_rowHasValue(elem, row, value) then
                return false, "Row forbids repeated values", "value"
            end
        end
    end
    return true, nil, nil
end

function Folio:_rowsHaveOpenSpace(rows)
    local _, elem = self:_resolveElement(self.active_element)
    if not elem or not elem.pattern then
        return false
    end
    local cols = elem.pattern.cols or GRID_COLS
    for _, row in ipairs(rows or {}) do
        for col = 1, cols do
            local idx = row_col_to_index(elem.pattern, row, col)
            if not (elem.stained and elem.stained[idx]) and (not elem.placed[idx]) and (not elem.wet[idx]) then
                return true
            end
        end
    end
    return false
end

function Folio:canOpenAnyRowWithSpace()
    if not self:isParchmentConfigured() then
        return false
    end
    local open_rows = self:getOpenRows()
    if self:_rowsHaveOpenSpace(open_rows) then
        return true
    end

    local row_count = self:getRowCount(self.active_element)
    for row = 1, row_count do
        if (not self:isRowOpen(row)) and self:_rowsHaveOpenSpace({row}) then
            return true
        end
    end

    return false
end

function Folio:_canPlaceWithMeta(element, row, col, dice_value, dice_color)
    local key, elem = self:_resolveElement(element)
    if not elem then
        return false, "Invalid element", nil
    end
    if self.completed then
        return false, "Folio completed", nil
    end
    if self.busted then
        return false, "Folio busted", nil
    end
    if not elem.unlocked then
        return false, "Locked", nil
    end
    if not self:isParchmentConfigured() then
        return false, "Prepare parchment first", nil
    end

    local value = tonumber(dice_value)
    if not value then
        return false, "Invalid die value", nil
    end
    value = math.floor(value)
    if value < 1 or value > 6 then
        return false, "Invalid die value", nil
    end

    local color = self:_normalizePlacementColor(value, dice_color)
    if not color then
        return false, "Invalid die color", nil
    end

    local pattern = elem.pattern
    if not self:_canPlaceInBounds(pattern, row, col) then
        return false, "Out of bounds", nil
    end
    if not self:isRowOpen(row) then
        return false, "Row is closed", nil
    end

    local index = row_col_to_index(pattern, row, col)
    if elem.stained and elem.stained[index] then
        return false, "Cell is stained", nil
    end
    if elem.placed[index] or elem.wet[index] then
        return false, "Occupied", nil
    end

    local constraint = pattern.grid and pattern.grid[index] or nil
    local ok_constraint, reason = self:_matchesConstraint(constraint, value, color)
    if not ok_constraint then
        return false, reason, nil
    end

    local ok_row_rule, row_rule_reason = self:_matchesRowRules(elem, row, col, value, color)
    if not ok_row_rule then
        return false, row_rule_reason, nil
    end

    if not self:canSpendInk(color, 1) then
        return false, "Pigment depleted", nil
    end

    return true, nil, {
        element = key,
        row = row,
        col = col,
        index = index,
        value = value,
        color = color,
    }
end

function Folio:canPlaceDie(element, row, col, dice_value, dice_color)
    local ok, reason = self:_canPlaceWithMeta(element, row, col, dice_value, dice_color)
    return ok, reason
end

function Folio:getPlacementBlockReason(element, row, col, dice_value, palette)
    local key, elem = self:_resolveElement(element)
    if not elem or not elem.pattern then
        return nil
    end
    if not self:isParchmentConfigured() then
        return nil
    end
    local pattern = elem.pattern
    if not self:_canPlaceInBounds(pattern, row, col) then
        return nil
    end
    if not self:isRowOpen(row) then
        return nil
    end
    local index = row_col_to_index(pattern, row, col)
    if elem.stained and elem.stained[index] then
        return nil
    end
    if elem.placed[index] or elem.wet[index] then
        return nil
    end

    local value = tonumber(dice_value)
    if not value then
        return "value"
    end
    value = math.floor(value)
    if value < 1 or value > 6 then
        return "value"
    end

    local palette_colors = {}
    for _, color in ipairs(palette or {}) do
        local key_color = normalize_color_key(color)
        if key_color then
            palette_colors[#palette_colors + 1] = key_color
        end
    end
    if #palette_colors <= 0 then
        palette_colors = self:getAvailableInkColors()
    end

    local palette_with_ink = {}
    for _, color in ipairs(palette_colors) do
        if self:canSpendInk(color, 1) then
            palette_with_ink[#palette_with_ink + 1] = color
        end
    end
    if #palette_with_ink <= 0 then
        return "ink"
    end

    for _, color in ipairs(palette_with_ink) do
        local ok = self:canPlaceDie(key, row, col, value, color)
        if ok then
            return nil
        end
    end

    local constraint = pattern.grid and pattern.grid[index] or nil
    if type(constraint) == "number" and value ~= constraint then
        return "value"
    end
    if type(constraint) == "string" then
        local has_color = false
        for _, color in ipairs(palette_with_ink) do
            if color == constraint then
                has_color = true
                break
            end
        end
        if not has_color then
            return "color"
        end
        if not self:canSpendInk(constraint, 1) then
            return "ink"
        end
    end

    return "value"
end

function Folio:_applyCommittedPlacement(entry)
    local key, elem = self:_resolveElement(entry.element)
    if not elem then
        return false
    end
    local placement = {
        element = key,
        row = entry.row,
        col = entry.col,
        index = entry.index,
        value = entry.value,
        color = entry.color,
        pigment = entry.pigment,
        wet = false,
    }
    if elem.placed[placement.index] then
        return false
    end
    elem.placed[placement.index] = placement
    elem.cells_filled = (elem.cells_filled or 0) + 1
    return true
end

function Folio:_updateCompletionState()
    local elem = self.elements[self.active_element]
    local completed_rows = self:getCompletedRowsCount(self.active_element)
    local target = self.objective and self.objective.target or DEFAULT_OBJECTIVE_ROWS
    local kind = self.objective and tostring(self.objective.kind or "complete_rows") or "complete_rows"
    local done
    if kind == "clean_rows" then
        local cap = self.objective and tonumber(self.objective.stain_cap) or 2
        done = (completed_rows >= target) and ((self.stain_count or 0) <= cap)
    else
        done = completed_rows >= target
    end
    if done then
        elem.completed = true
        self.completed = true
    end
    self.quality = self:calculateQuality()
end

function Folio:getCompletedRowsCount(element)
    local _, elem = self:_resolveElement(element)
    if not elem then
        return 0
    end
    local pattern = elem.pattern
    local rows = pattern and (pattern.rows or GRID_ROWS) or GRID_ROWS
    local cols = pattern and (pattern.cols or GRID_COLS) or GRID_COLS
    local completed = 0
    for row = 1, rows do
        local row_done = true
        for col = 1, cols do
            local index = row_col_to_index(pattern, row, col)
            if not elem.placed[index] then
                row_done = false
                break
            end
        end
        if row_done then
            completed = completed + 1
        end
    end
    return completed
end

function Folio:getCompletedRowsMap(element)
    local _, elem = self:_resolveElement(element)
    if not elem then
        return {}
    end
    local pattern = elem.pattern
    local rows = pattern and (pattern.rows or GRID_ROWS) or GRID_ROWS
    local cols = pattern and (pattern.cols or GRID_COLS) or GRID_COLS
    local completed = {}
    for row = 1, rows do
        local row_done = true
        for col = 1, cols do
            local index = row_col_to_index(pattern, row, col)
            if not elem.placed[index] then
                row_done = false
                break
            end
        end
        if row_done then
            completed[row] = true
        end
    end
    return completed
end

function Folio:placeDie(element, row, col, dice_value, dice_color, pigment_name)
    local ok, reason, meta = self:_canPlaceWithMeta(element, row, col, dice_value, dice_color)
    if not ok or not meta then
        return false, reason or "Cannot place die"
    end

    local spent_ok, spend_reason = self:spendInk(meta.color, 1)
    if not spent_ok then
        return false, spend_reason or "Pigment depleted"
    end

    local entry = {
        element = meta.element,
        row = meta.row,
        col = meta.col,
        index = meta.index,
        value = meta.value,
        color = meta.color,
        pigment = pigment_name,
        ink_spent = 1,
        wet = false,
    }

    local applied = self:_applyCommittedPlacement(entry)
    if not applied then
        self:recoverInk(meta.color, 1)
        return false, "Cannot place die"
    end
    self:_updateCompletionState()
    return true, "Placed"
end

function Folio:addWetDie(element, row, col, dice_value, dice_color, pigment_name)
    local ok, reason, meta = self:_canPlaceWithMeta(element, row, col, dice_value, dice_color)
    if not ok or not meta then
        return false, reason or "Cannot queue die", nil
    end

    local spent_ok, spend_reason = self:spendInk(meta.color, 1)
    if not spent_ok then
        return false, spend_reason or "Pigment depleted", nil
    end

    local _, elem = self:_resolveElement(meta.element)
    local placement = {
        element = meta.element,
        row = meta.row,
        col = meta.col,
        index = meta.index,
        value = meta.value,
        color = meta.color,
        pigment = pigment_name,
        ink_spent = 1,
        wet = true,
    }

    elem.wet[placement.index] = placement
    self.wet_buffer[#self.wet_buffer + 1] = placement

    return true, "Queued in wet buffer", placement, {}
end

function Folio:getCellState(element, row, col)
    local key, elem = self:_resolveElement(element)
    if not elem then
        return nil
    end

    local pattern = elem.pattern
    if not self:_canPlaceInBounds(pattern, row, col) then
        return nil
    end

    local index = row_col_to_index(pattern, row, col)
    local placed = elem.wet[index] or elem.placed[index]
    return {
        element = key,
        row = row,
        col = col,
        constraint = pattern.grid and pattern.grid[index] or nil,
        placed = placed,
        wet = placed and placed.wet or false,
        stained = elem.stained and elem.stained[index] or false,
        unlocked = elem.unlocked,
    }
end

function Folio:getAllCells(element)
    local _, elem = self:_resolveElement(element)
    if not elem then
        return {}
    end

    local out = {}
    for row = 1, elem.pattern.rows do
        for col = 1, elem.pattern.cols do
            out[#out + 1] = self:getCellState(element, row, col)
        end
    end
    return out
end

function Folio:getValidPlacements(element, dice_value, dice_color)
    local key, elem = self:_resolveElement(element)
    if not elem or not elem.unlocked or self.completed or self.busted then
        return {}
    end

    local valid = {}
    for row = 1, elem.pattern.rows do
        for col = 1, elem.pattern.cols do
            local ok = self:canPlaceDie(key, row, col, dice_value, dice_color)
            if ok then
                valid[#valid + 1] = {row = row, col = col}
            end
        end
    end
    return valid
end

function Folio:getAllValidPlacements(dice_value, dice_color)
    local out = {}
    for _, element in ipairs(Folio.ELEMENTS) do
        local placements = self:getValidPlacements(element, dice_value, dice_color)
        if #placements > 0 then
            out[element] = placements
        end
    end
    return out
end

function Folio:getPlacementDecisionPreview(element, row, col, dice_value, dice_color)
    local ok, reason = self:_canPlaceWithMeta(element, row, col, dice_value, dice_color)
    if not ok then
        return {
            can_place = false,
            reason = reason,
            quality_gain = 0,
            risk_gain = 0,
            projected_risk = 0,
            score = 0,
        }
    end

    return {
        can_place = true,
        quality_gain = 1,
        risk_gain = 0,
        projected_risk = 0,
        score = 1,
    }
end

function Folio:pickBestWetPlacement()
    local best = self.wet_buffer[1]
    if not best then
        return nil
    end
    return {
        element = best.element,
        row = best.row,
        col = best.col,
        index = best.index,
        value = best.value,
        color = best.color,
        score = 1,
        quality_gain = 1,
        risk_gain = 0,
    }
end

function Folio:drawTurnPalette(count)
    local target = math.max(1, math.floor(tonumber(count) or TURN_PALETTE_SIZE))
    local bag = self:getAvailableInkColors()
    local selected = {}
    local seen = {}

    while #selected < target and #bag > 0 do
        local idx = random_int(1, #bag)
        local color = bag[idx]
        if color and not seen[color] then
            seen[color] = true
            selected[#selected + 1] = color
        end
        table.remove(bag, idx)
    end

    self.turn_palette = shallow_copy_array(selected)
    return selected
end

function Folio:markTurnStarted(palette)
    self.turn_count = (self.turn_count or 0) + 1
    self.turn_palette = palette and shallow_copy_array(palette) or self.turn_palette
end

function Folio:getBustStainCandidates(count)
    local elem = self.elements[self.active_element]
    if not elem then
        return {}
    end

    local target = math.max(1, math.floor(tonumber(count) or self.bust_choice_count or BUST_STAIN_CHOICES))
    local open_rows_only = self.bust_open_rows_only and true or false
    local preferred = {}
    local fallback = {}
    for index = 1, elem.cells_total do
        if (not elem.placed[index]) and (not elem.wet[index]) and (not elem.stained[index]) then
            local row, col = index_to_row_col(elem.pattern, index)
            local item = {
                element = self.active_element,
                row = row,
                col = col,
                index = index,
            }
            if self:isRowOpen(row) then
                preferred[#preferred + 1] = item
            else
                fallback[#fallback + 1] = item
            end
        end
    end

    local out = {}
    local function pull_random(list)
        while #out < target and #list > 0 do
            local pick = random_int(1, #list)
            out[#out + 1] = list[pick]
            table.remove(list, pick)
        end
    end
    pull_random(preferred)
    if not open_rows_only then
        pull_random(fallback)
    end
    return out
end

function Folio:applyStainChoice(choice)
    local element = choice and choice.element or self.active_element
    local _, elem = self:_resolveElement(element)
    if not elem then
        return false, "Invalid element", nil
    end
    local index = choice and choice.index or nil
    if not index then
        local row = choice and choice.row or nil
        local col = choice and choice.col or nil
        if not row or not col then
            return false, "Invalid stain cell", nil
        end
        if not self:_canPlaceInBounds(elem.pattern, row, col) then
            return false, "Invalid stain cell", nil
        end
        index = row_col_to_index(elem.pattern, row, col)
    end
    index = math.floor(tonumber(index) or -1)
    if index < 1 or index > elem.cells_total then
        return false, "Invalid stain cell", nil
    end
    if elem.placed[index] or elem.wet[index] or elem.stained[index] then
        return false, "Cell unavailable", nil
    end

    elem.stained[index] = true
    self.stain_count = self.stain_count + 1
    if self.stain_count >= self.stain_threshold then
        self.busted = true
    end
    self:_checkObjectiveFailure()
    self.quality = self:calculateQuality()
    local row, col = index_to_row_col(elem.pattern, index)
    return true, nil, {
        element = element,
        row = row,
        col = col,
        index = index,
        busted = self.busted,
    }
end

function Folio:addStain(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 1))
    local busted = self.busted and true or false
    for _ = 1, amount do
        local candidates = self:getBustStainCandidates(self.bust_choice_count)
        if #candidates > 0 then
            local pick = random_int(1, #candidates)
            local ok, _, result = self:applyStainChoice(candidates[pick])
            if ok and result and result.busted then
                busted = true
            end
        else
            self.stain_count = self.stain_count + 1
            if self.stain_count >= self.stain_threshold then
                self.busted = true
                busted = true
            end
        end
    end
    self.quality = self:calculateQuality()
    if self:_checkObjectiveFailure() then
        busted = true
    end
    return busted
end

function Folio:_checkObjectiveFailure()
    local kind = self.objective and tostring(self.objective.kind or "") or ""
    if kind == "clean_rows" then
        local cap = tonumber(self.objective.stain_cap) or 0
        if (self.stain_count or 0) > cap then
            self.busted = true
            return true
        end
    end
    return false
end

function Folio:removeStain(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 1))
    if amount <= 0 then
        return
    end

    local elem = self.elements[self.active_element]
    if elem then
        local stained_indexes = {}
        for index = 1, elem.cells_total do
            if elem.stained[index] then
                stained_indexes[#stained_indexes + 1] = index
            end
        end
        while amount > 0 and #stained_indexes > 0 do
            local pick = random_int(1, #stained_indexes)
            local idx = stained_indexes[pick]
            elem.stained[idx] = nil
            table.remove(stained_indexes, pick)
            amount = amount - 1
            self.stain_count = math.max(0, self.stain_count - 1)
        end
    end

    if self.stain_count < self.stain_threshold then
        self.busted = false
    end
end

function Folio:hasAnyLegalPlacement(dice_values, palette)
    local list = dice_values or {}
    local colors = palette or self.turn_palette or {}
    if #colors == 0 then
        colors = self:drawTurnPalette(TURN_PALETTE_SIZE)
    end

    for _, die in ipairs(list) do
        local value = (type(die) == "table") and die.value or die
        value = tonumber(value)
        if value then
            value = math.floor(value)
            for _, color in ipairs(colors) do
                local placements = self:getValidPlacements(self.active_element, value, color)
                if #placements > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function Folio:hasAnyMove(dice_values, palette)
    return self:hasAnyLegalPlacement(dice_values, palette)
end

function Folio:onElementCompleted(element)
    local _, elem = self:_resolveElement(element)
    if elem then
        elem.completed = true
    end
    self.completed = true
end

function Folio:calculateQuality()
    local elem = self.elements[self.active_element]
    if not elem then
        return 0
    end
    local committed = elem.cells_filled or 0
    return math.max(0, committed * 2 - self.stain_count)
end

function Folio:getQualityTier()
    local quality_schema = FolioSchema.quality_tier or {}
    local completed_rows = self:getCompletedRowsCount(self.active_element)
    local objective_target = tonumber(self.objective and self.objective.target) or DEFAULT_OBJECTIVE_ROWS
    local complete_threshold = math.max(1, objective_target)
    local excellent_threshold = math.max(3, complete_threshold + 1)
    if completed_rows >= excellent_threshold then
        return tr(quality_schema.excellent_key, quality_schema.excellent_default or "Excellent")
    end
    if completed_rows >= complete_threshold then
        if (self.stain_count or 0) <= 2 then
            return tr(quality_schema.good_key, quality_schema.good_default or "Good")
        end
        return tr(quality_schema.complete_key, quality_schema.complete_default or "Complete")
    end
    return tr(quality_schema.working_key, quality_schema.working_default or "Working")
end

function Folio:getCompletionStats()
    return {
        turns = self.turn_count or 0,
        busts = self.bust_count or 0,
        stains = self.stain_count or 0,
    }
end

function Folio:getStatus()
    local elem = self.elements[self.active_element]
    local filled, target = self:getObjectiveProgress()
    local pattern_schema = FolioSchema.pattern or {}
    return {
        folio_set = self.folio_set,
        stains = string.format("%d/%d", self.stain_count, self.stain_threshold),
        quality = self.quality,
        quality_tier = self:getQualityTier(),
        wet = #self.wet_buffer,
        completed = self.completed,
        busted = self.busted,
        objective = string.format("%d/%d", filled, target),
        open_rows = self:getOpenRows(),
        guided_rows = self:getGuidedRows(),
        max_open_rows = self.max_open_rows,
        required_guided_rows = self.required_guided_rows,
        reroll_max = self.reroll_max,
        bust_choice_count = self.bust_choice_count,
        bust_open_rows_only = self.bust_open_rows_only and true or false,
        wet_buffer_max = self.wet_buffer_max,
        inkwell = self:getInkwellState(),
        pattern = (elem and elem.pattern and elem.pattern.name)
            or tr(pattern_schema.fallback_name_key, pattern_schema.fallback_name_default or "Window"),
        token = elem and elem.pattern and elem.pattern.token or 0,
    }
end

function Folio:debugPrint()
    local filled, target = self:getObjectiveProgress()
    debug_log(string.format(
        "[Folio] %s | Pattern=%s | ObjectiveRows=%d/%d | Stains=%d/%d | Wet=%d | Busted=%s | Completed=%s",
        tostring(self.folio_set),
        tostring(self:getPatternName()),
        filled,
        target,
        self.stain_count,
        self.stain_threshold,
        #self.wet_buffer,
        tostring(self.busted),
        tostring(self.completed)
    ))
end

Folio.registerPush = FolioTurn.registerPush
Folio.getWetCount = FolioTurn.getWetCount
Folio.getTurnRisk = FolioTurn.getTurnRisk
Folio.getPreparationGuard = FolioTurn.getPreparationGuard
Folio.canUsePreparation = FolioTurn.canUsePreparation
Folio.applyPreparation = FolioTurn.applyPreparation
Folio.getRuleCards = FolioTurn.getRuleCards
Folio.getRuleEffects = FolioTurn.getRuleEffects
Folio.getToolUsesLeft = FolioTurn.getToolUsesLeft
Folio.getSeals = FolioTurn.getSeals
Folio.canSpendSeal = FolioTurn.canSpendSeal
Folio.spendSeal = FolioTurn.spendSeal
Folio.canUseTool = FolioTurn.canUseTool
Folio.consumeToolUse = FolioTurn.consumeToolUse
Folio.getWetSummary = FolioTurn.getWetSummary
Folio.hasWetPair = FolioTurn.hasWetPair
Folio.tryAwardDoubleSeal = FolioTurn.tryAwardDoubleSeal
Folio.discardWetBuffer = FolioTurn.discardWetBuffer
Folio.salvageWetBufferOnBust = FolioTurn.salvageWetBufferOnBust
Folio.commitWetBuffer = FolioTurn.commitWetBuffer
Folio.removeWetPlacementAt = FolioTurn.removeWetPlacementAt

return Folio
