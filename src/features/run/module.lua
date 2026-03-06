local Run = require("src.gameplay.run.run")
local I18n = require("src.core.i18n")
local Navigation = require("src.core.navigation")
local RuntimeUI = require("src.core.runtime_ui")
local Schema = require("src.core.schema")
local Json = require("src.core.json")
local Logger = require("src.core.logger")
local RunSchema = require("src.data.run_schema")

local GAMEPLAY_SCHEMA = RunSchema.gameplay or {}
local FLOW_SCHEMA = RunSchema.flow or {}
local UI_SCHEMA = RunSchema.ui or {}
local UI_LAYOUT_SCHEMA = UI_SCHEMA.layout or {}
local UI_COLORS_SCHEMA = UI_SCHEMA.colors or {}

local expect_string = Schema.expect_string
local expect_number = Schema.expect_number
local expect_color4 = Schema.expect_color4

local DEFAULT_FOLIO_SET = expect_string(GAMEPLAY_SCHEMA.default_folio_set, "gameplay.default_folio_set")
local CONFIRM_MOUSE_BUTTON = expect_number(FLOW_SCHEMA.confirm_mouse_button, "flow.confirm_mouse_button")
local MENU_MODULE = expect_string(FLOW_SCHEMA.menu_module, "flow.menu_module")
local REWARD_MODULE = expect_string(FLOW_SCHEMA.reward_module, "flow.reward_module")

local TITLE_FONT_SIZE = expect_number(UI_LAYOUT_SCHEMA.title_font_size, "ui.layout.title_font_size")
local BODY_FONT_SIZE = expect_number(UI_LAYOUT_SCHEMA.body_font_size, "ui.layout.body_font_size")
local TITLE_X = expect_number(UI_LAYOUT_SCHEMA.title_x, "ui.layout.title_x")
local TITLE_Y = expect_number(UI_LAYOUT_SCHEMA.title_y, "ui.layout.title_y")
local STATUS_X = expect_number(UI_LAYOUT_SCHEMA.status_x, "ui.layout.status_x")
local STATUS_Y = expect_number(UI_LAYOUT_SCHEMA.status_y, "ui.layout.status_y")
local STATUS_LINE_GAP = expect_number(UI_LAYOUT_SCHEMA.status_line_gap, "ui.layout.status_line_gap")
local STATUS_OUTCOME_Y = expect_number(UI_LAYOUT_SCHEMA.status_outcome_y, "ui.layout.status_outcome_y")
local BUTTON_X = expect_number(UI_LAYOUT_SCHEMA.button_x, "ui.layout.button_x")
local BUTTON_Y = expect_number(UI_LAYOUT_SCHEMA.button_y, "ui.layout.button_y")
local BUTTON_WIDTH = expect_number(UI_LAYOUT_SCHEMA.button_width, "ui.layout.button_width")
local BUTTON_HEIGHT = expect_number(UI_LAYOUT_SCHEMA.button_height, "ui.layout.button_height")
local BUTTON_GAP = expect_number(UI_LAYOUT_SCHEMA.button_gap, "ui.layout.button_gap")
local BUTTON_CORNER_RADIUS = expect_number(UI_LAYOUT_SCHEMA.button_corner_radius, "ui.layout.button_corner_radius")
local BUTTON_TEXT_OFFSET_Y = expect_number(UI_LAYOUT_SCHEMA.button_text_offset_y, "ui.layout.button_text_offset_y")
local HINT_X = expect_number(UI_LAYOUT_SCHEMA.hint_x, "ui.layout.hint_x")
local HINT_Y = expect_number(UI_LAYOUT_SCHEMA.hint_y, "ui.layout.hint_y")

local BACKGROUND_COLOR = expect_color4(UI_COLORS_SCHEMA.background, "ui.colors.background")
local BACKGROUND_COLOR_HIGH_CONTRAST = expect_color4(UI_COLORS_SCHEMA.background_high_contrast, "ui.colors.background_high_contrast")
local TEXT_COLOR = expect_color4(UI_COLORS_SCHEMA.text, "ui.colors.text")
local TEXT_COLOR_HIGH_CONTRAST = expect_color4(UI_COLORS_SCHEMA.text_high_contrast, "ui.colors.text_high_contrast")
local BUTTON_FILL_COLOR = expect_color4(UI_COLORS_SCHEMA.button_fill, "ui.colors.button_fill")
local BUTTON_OUTLINE_COLOR = expect_color4(UI_COLORS_SCHEMA.button_outline, "ui.colors.button_outline")
local BUTTON_TEXT_COLOR = expect_color4(UI_COLORS_SCHEMA.button_text, "ui.colors.button_text")

local function tr(key, fallback, params)
    return I18n.t(key, fallback, params)
end

Run.configure({
    translate = function(key, fallback, params)
        return I18n.t(key, fallback, params)
    end,
    get_language = I18n.get_language,
    json_decode = Json.decode,
    log_debug = Logger.debug,
})

local function point_in_rect(x, y, rect)
    if not rect then
        return false
    end
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local run_module = {}
local current_run = nil
local run_title_font = nil
local run_body_font = nil
local run_title_size = 0
local run_body_size = 0
local run_ui = {}

function run_module:enter(params)
    if params and params.run then
        current_run = params.run
    else
        local opts = type(params) == "table" and params or {}
        current_run = Run.new(opts.folio_set or DEFAULT_FOLIO_SET, opts.seed or os.time(), opts)
    end
end

function run_module:exit()
    current_run = nil
end

function run_module:update(_dt)
end

function run_module:draw()
    local high_contrast = RuntimeUI.high_contrast()
    local ui = UI_SCHEMA
    local bg = high_contrast and BACKGROUND_COLOR_HIGH_CONTRAST or BACKGROUND_COLOR
    local text_color = high_contrast and TEXT_COLOR_HIGH_CONTRAST or TEXT_COLOR
    local title_size = RuntimeUI.sized(TITLE_FONT_SIZE)
    local body_size = RuntimeUI.sized(BODY_FONT_SIZE)
    if not run_title_font or run_title_size ~= title_size then
        local ok, f = pcall(function() return love.graphics.newFont(title_size) end)
        run_title_font = (ok and f) or love.graphics.getFont()
        run_title_size = title_size
    end
    if not run_body_font or run_body_size ~= body_size then
        local ok, f = pcall(function() return love.graphics.newFont(body_size) end)
        run_body_font = (ok and f) or love.graphics.getFont()
        run_body_size = body_size
    end

    love.graphics.setBackgroundColor(bg[1], bg[2], bg[3], bg[4] or 1)
    love.graphics.setColor(text_color[1], text_color[2], text_color[3], text_color[4] or 1)
    love.graphics.setFont(run_title_font)
    love.graphics.print(tr(ui.title_key, ui.title_default), TITLE_X, TITLE_Y)

    if current_run then
        local status = current_run:getStatus()
        love.graphics.setFont(run_body_font)
        love.graphics.print(
            tr(ui.label_folio_set_key, ui.label_folio_set_default, {value = tostring(status.folio_set)}),
            STATUS_X,
            STATUS_Y
        )
        love.graphics.print(
            tr(ui.label_folio_key, ui.label_folio_default, {value = tostring(status.folio)}),
            STATUS_X,
            STATUS_Y + STATUS_LINE_GAP
        )
        love.graphics.print(
            tr(ui.label_reputation_key, ui.label_reputation_default, {value = tostring(status.reputation)}),
            STATUS_X,
            STATUS_Y + STATUS_LINE_GAP * 2
        )
        love.graphics.print(
            tr(ui.label_coins_key, ui.label_coins_default, {value = tostring(status.coins)}),
            STATUS_X,
            STATUS_Y + STATUS_LINE_GAP * 3
        )
        love.graphics.print(
            tr(ui.label_seed_key, ui.label_seed_default, {value = tostring(status.seed)}),
            STATUS_X,
            STATUS_Y + STATUS_LINE_GAP * 4
        )
        if status.game_over then
            love.graphics.print(tr(ui.status_game_over_key, ui.status_game_over_default), STATUS_X, STATUS_OUTCOME_Y)
        elseif status.victory then
            love.graphics.print(tr(ui.status_victory_key, ui.status_victory_default), STATUS_X, STATUS_OUTCOME_Y)
        end
    end

    local menu_rect = {x = BUTTON_X, y = BUTTON_Y, w = BUTTON_WIDTH, h = BUTTON_HEIGHT}
    local next_rect = {x = BUTTON_X + BUTTON_WIDTH + BUTTON_GAP, y = BUTTON_Y, w = BUTTON_WIDTH, h = BUTTON_HEIGHT}
    run_ui.menu = menu_rect
    run_ui.next = next_rect

    love.graphics.setColor(BUTTON_FILL_COLOR[1], BUTTON_FILL_COLOR[2], BUTTON_FILL_COLOR[3], BUTTON_FILL_COLOR[4] or 1)
    love.graphics.rectangle("fill", menu_rect.x, menu_rect.y, menu_rect.w, menu_rect.h, BUTTON_CORNER_RADIUS, BUTTON_CORNER_RADIUS)
    love.graphics.rectangle("fill", next_rect.x, next_rect.y, next_rect.w, next_rect.h, BUTTON_CORNER_RADIUS, BUTTON_CORNER_RADIUS)
    love.graphics.setColor(
        BUTTON_OUTLINE_COLOR[1],
        BUTTON_OUTLINE_COLOR[2],
        BUTTON_OUTLINE_COLOR[3],
        BUTTON_OUTLINE_COLOR[4] or 1
    )
    love.graphics.rectangle("line", menu_rect.x, menu_rect.y, menu_rect.w, menu_rect.h, BUTTON_CORNER_RADIUS, BUTTON_CORNER_RADIUS)
    love.graphics.rectangle("line", next_rect.x, next_rect.y, next_rect.w, next_rect.h, BUTTON_CORNER_RADIUS, BUTTON_CORNER_RADIUS)

    love.graphics.setFont(run_body_font)
    love.graphics.setColor(BUTTON_TEXT_COLOR[1], BUTTON_TEXT_COLOR[2], BUTTON_TEXT_COLOR[3], BUTTON_TEXT_COLOR[4] or 1)
    love.graphics.printf(
        tr(ui.action_menu_key, ui.action_menu_default),
        menu_rect.x,
        menu_rect.y + BUTTON_TEXT_OFFSET_Y,
        menu_rect.w,
        "center"
    )
    love.graphics.printf(
        tr(ui.action_next_folio_key, ui.action_next_folio_default),
        next_rect.x,
        next_rect.y + BUTTON_TEXT_OFFSET_Y,
        next_rect.w,
        "center"
    )
    love.graphics.print(tr(ui.hint_mouse_only_key, ui.hint_mouse_only_default), HINT_X, HINT_Y)
    love.graphics.setColor(1, 1, 1, 1)
end

function run_module:keypressed(_key, _scancode, _isrepeat)
end

function run_module:mousepressed(x, y, button)
    if button ~= CONFIRM_MOUSE_BUTTON then
        return
    end

    if point_in_rect(x, y, run_ui.menu) then
        local ok = Navigation.go(MENU_MODULE)
        if (not ok) and run_module.onExit then
            run_module.onExit()
        end
        return
    end

    if point_in_rect(x, y, run_ui.next) then
        if current_run then
            local completed, status = current_run:nextFolio()
            if completed and status == "victory" then
                Navigation.go(REWARD_MODULE, {run = current_run})
            end
        end
    end
end

return {
    Run = Run,
    module = run_module,
}
