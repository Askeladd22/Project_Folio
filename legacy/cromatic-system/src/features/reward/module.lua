local AudioManager = require("src.core.audio_manager")
local I18n = require("src.core.i18n")
local Navigation = require("src.core.navigation")
local RuntimeUI = require("src.core.runtime_ui")
local Schema = require("src.core.schema")
local RewardFlowSchema = require("src.data.reward_flow_schema")
local RewardUISchema = require("src.data.reward_ui_schema")
local RewardToolsData = require("src.data.reward_tools")

local RewardModule = {}

local SELECTION_SCHEMA = RewardFlowSchema.selection or {}
local INPUT_SCHEMA = RewardFlowSchema.input or {}
local AUDIO_SCHEMA = RewardFlowSchema.audio or {}
local NAVIGATION_SCHEMA = RewardFlowSchema.navigation or {}

local expect_string = Schema.expect_string
local expect_number = Schema.expect_number
local expect_boolean = Schema.expect_boolean
local expect_entry = Schema.expect_entry
local expect_color4 = Schema.expect_color4

local CHOICES_COUNT = math.max(1, expect_number(SELECTION_SCHEMA.choices_count, "selection.choices_count"))
local SELECTION_SHUFFLE = expect_boolean(SELECTION_SCHEMA.shuffle, "selection.shuffle")
local CONFIRM_MOUSE_BUTTON = expect_number(INPUT_SCHEMA.confirm_mouse_button, "input.confirm_mouse_button")
local CONFIRM_SFX = expect_string(AUDIO_SCHEMA.confirm_sfx, "audio.confirm_sfx")
local HOVER_SFX = expect_string(AUDIO_SCHEMA.hover_sfx, "audio.hover_sfx")
local NEXT_MODULE = expect_string(NAVIGATION_SCHEMA.next_module, "navigation.next_module")

local COLOR_SCHEMA = RewardUISchema.colors or {}
local LAYOUT_SCHEMA = RewardUISchema.layout or {}
local TEXT_SCHEMA = RewardUISchema.text or {}

local COLORS = {
    panel = expect_color4(COLOR_SCHEMA.panel, "colors.panel", 0.95),
    border = expect_color4(COLOR_SCHEMA.border, "colors.border", 1),
    text = expect_color4(COLOR_SCHEMA.text, "colors.text", 1),
    selected = expect_color4(COLOR_SCHEMA.selected, "colors.selected", 1),
    icon = expect_color4(COLOR_SCHEMA.icon, "colors.icon", 1),
}

local PANEL_MARGIN = expect_number(LAYOUT_SCHEMA.panel_margin, "layout.panel_margin")
local PANEL_MAX_WIDTH = expect_number(LAYOUT_SCHEMA.panel_max_width, "layout.panel_max_width")
local PANEL_MAX_HEIGHT = expect_number(LAYOUT_SCHEMA.panel_max_height, "layout.panel_max_height")
local PANEL_PADDING = expect_number(LAYOUT_SCHEMA.padding, "layout.padding")
local TITLE_HEIGHT = expect_number(LAYOUT_SCHEMA.title_height, "layout.title_height")
local ROW_GAP = expect_number(LAYOUT_SCHEMA.row_gap, "layout.row_gap")
local ROW_TOP_MARGIN = expect_number(LAYOUT_SCHEMA.row_top_margin, "layout.row_top_margin")
local ROW_BOTTOM_MARGIN = expect_number(LAYOUT_SCHEMA.row_bottom_margin, "layout.row_bottom_margin")
local CARD_MIN_WIDTH = expect_number(LAYOUT_SCHEMA.card_min_width, "layout.card_min_width")
local CARD_HOVER_OUTLINE = expect_number(LAYOUT_SCHEMA.card_hover_outline, "layout.card_hover_outline")
local TITLE_TOP_MARGIN = expect_number(LAYOUT_SCHEMA.title_top_margin, "layout.title_top_margin")
local ICON_TOP_MARGIN = expect_number(LAYOUT_SCHEMA.icon_top_margin, "layout.icon_top_margin")
local NAME_TOP_MARGIN = expect_number(LAYOUT_SCHEMA.name_top_margin, "layout.name_top_margin")
local BODY_TOP_MARGIN = expect_number(LAYOUT_SCHEMA.body_top_margin, "layout.body_top_margin")
local BODY_PADDING_X = expect_number(LAYOUT_SCHEMA.body_padding_x, "layout.body_padding_x")
local USES_BOTTOM_MARGIN = expect_number(LAYOUT_SCHEMA.uses_bottom_margin, "layout.uses_bottom_margin")
local CARD_INNER_PADDING = expect_number(LAYOUT_SCHEMA.card_inner_padding, "layout.card_inner_padding")
local CARD_OUTER_PADDING = expect_number(LAYOUT_SCHEMA.card_outer_padding, "layout.card_outer_padding")
local BORDER_WIDTH = expect_number(LAYOUT_SCHEMA.border_width, "layout.border_width")
local RADIUS = expect_number(LAYOUT_SCHEMA.radius, "layout.radius")

local TITLE_CHOOSE_ENTRY = expect_entry(TEXT_SCHEMA.title_choose, "text.title_choose")
local CARD_NAME_FALLBACK_ENTRY = expect_entry(TEXT_SCHEMA.card_name_fallback, "text.card_name_fallback")
local CARD_USES_ENTRY = expect_entry(TEXT_SCHEMA.card_uses, "text.card_uses")

local function tr(key, fallback, params)
    return I18n.t(key, fallback, params)
end

local font_cache = {}
local selected = 1
local candidate_tools = {}
local run = nil
local layout_cache = nil

local function get_font(px)
    local size = RuntimeUI.sized(px)
    if not font_cache[size] then
        local ok, font = pcall(function()
            return love.graphics.newFont(size)
        end)
        font_cache[size] = ok and font or love.graphics.getFont()
    end
    return font_cache[size]
end

local function build_layout(tool_count)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local panel_w = math.min(w - RuntimeUI.sized(PANEL_MARGIN), RuntimeUI.sized(PANEL_MAX_WIDTH))
    local panel_h = math.min(h - RuntimeUI.sized(PANEL_MARGIN), RuntimeUI.sized(PANEL_MAX_HEIGHT))
    local x = math.floor((w - panel_w) * 0.5)
    local y = math.floor((h - panel_h) * 0.5)
    local padding = RuntimeUI.sized(PANEL_PADDING)
    local title_h = RuntimeUI.sized(TITLE_HEIGHT)
    local gap = RuntimeUI.sized(ROW_GAP)
    local count = math.max(1, tool_count)
    local row_x = x + padding
    local row_y = y + title_h + RuntimeUI.sized(ROW_TOP_MARGIN)
    local row_w = panel_w - padding * 2
    local row_h = panel_h - title_h - RuntimeUI.sized(ROW_BOTTOM_MARGIN)
    local card_w = math.max(RuntimeUI.sized(CARD_MIN_WIDTH), math.floor((row_w - gap * (count - 1)) / count))
    local card_h = row_h
    local cards = {}
    for i = 1, count do
        cards[i] = {
            x = row_x + (i - 1) * (card_w + gap),
            y = row_y,
            w = card_w,
            h = card_h,
        }
    end
    return {
        panel = {x = x, y = y, w = panel_w, h = panel_h},
        cards = cards,
    }
end

local function get_layout(tools)
    return build_layout(tools and #tools or 0)
end

local function draw_ui(tools, selected_index)
    local high_contrast = RuntimeUI.high_contrast()
    local reduced_motion = RuntimeUI.reduced_animations()
    local layout = get_layout(tools)
    local panel = layout.panel
    local radius = RuntimeUI.sized(RADIUS)

    love.graphics.setColor(COLORS.panel[1], COLORS.panel[2], COLORS.panel[3], high_contrast and 0.98 or COLORS.panel[4])
    love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, radius, radius)
    love.graphics.setColor(high_contrast and 1.0 or COLORS.border[1], high_contrast and 0.85 or COLORS.border[2], high_contrast and 0.32 or COLORS.border[3], 1)
    love.graphics.setLineWidth(RuntimeUI.sized(BORDER_WIDTH))
    love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, radius, radius)
    love.graphics.setLineWidth(1)

    local previous_font = love.graphics.getFont()
    local title_font = get_font(36)
    local name_font = get_font(24)
    local body_font = get_font(16)
    local uses_font = get_font(15)
    local icon_font = get_font(34)

    love.graphics.setFont(title_font)
    love.graphics.setColor(high_contrast and 1.0 or COLORS.text[1], high_contrast and 0.96 or COLORS.text[2], high_contrast and 0.86 or COLORS.text[3], 1)
    love.graphics.printf(tr(TITLE_CHOOSE_ENTRY.key, TITLE_CHOOSE_ENTRY.default), panel.x, panel.y + RuntimeUI.sized(TITLE_TOP_MARGIN), panel.w, "center")

    for i, tool in ipairs(tools) do
        local card = layout.cards[i]
        local cx = card.x
        local cy = card.y
        local card_w = card.w
        local card_h = card.h
        local active = (i == selected_index)

        if active and not reduced_motion and love.timer and love.timer.getTime then
            local t = love.timer.getTime()
            local pulse = 0.20 + 0.08 * math.sin(t * 5.8)
            love.graphics.setColor(COLORS.selected[1], COLORS.selected[2], COLORS.selected[3], pulse)
            local outline = RuntimeUI.sized(CARD_HOVER_OUTLINE)
            love.graphics.rectangle("fill", cx - outline, cy - outline, card_w + outline * 2, card_h + outline * 2, radius, radius)
        end

        if active then
            love.graphics.setColor(COLORS.selected[1], COLORS.selected[2], COLORS.selected[3], high_contrast and 0.34 or 0.26)
        else
            love.graphics.setColor(0.18, 0.14, 0.10, high_contrast and 0.92 or 0.84)
        end
        love.graphics.rectangle("fill", cx, cy, card_w, card_h, radius, radius)
        love.graphics.setColor(high_contrast and 1.0 or COLORS.border[1], high_contrast and 0.86 or COLORS.border[2], high_contrast and 0.36 or COLORS.border[3], active and 1 or 0.85)
        love.graphics.rectangle("line", cx, cy, card_w, card_h, radius, radius)

        love.graphics.setFont(icon_font)
        love.graphics.setColor(COLORS.icon)
        love.graphics.printf(tool.icon or "?", cx, cy + RuntimeUI.sized(ICON_TOP_MARGIN), card_w, "center")

        love.graphics.setFont(name_font)
        love.graphics.setColor(high_contrast and 1.0 or COLORS.text[1], high_contrast and 0.96 or COLORS.text[2], high_contrast and 0.88 or COLORS.text[3], 1)
        love.graphics.printf(
            tool.name or tr(CARD_NAME_FALLBACK_ENTRY.key, CARD_NAME_FALLBACK_ENTRY.default),
            cx + RuntimeUI.sized(CARD_INNER_PADDING),
            cy + RuntimeUI.sized(NAME_TOP_MARGIN),
            card_w - RuntimeUI.sized(CARD_OUTER_PADDING),
            "center"
        )

        love.graphics.setFont(body_font)
        love.graphics.setColor(high_contrast and 1.0 or COLORS.text[1], high_contrast and 0.95 or COLORS.text[2], high_contrast and 0.87 or COLORS.text[3], high_contrast and 1 or 0.95)
        love.graphics.printf(
            tool.description or "",
            cx + RuntimeUI.sized(BODY_PADDING_X),
            cy + RuntimeUI.sized(BODY_TOP_MARGIN),
            card_w - RuntimeUI.sized(BODY_PADDING_X * 2),
            "left"
        )

        love.graphics.setFont(uses_font)
        love.graphics.setColor(COLORS.icon)
        love.graphics.printf(
            tr(CARD_USES_ENTRY.key, CARD_USES_ENTRY.default, {count = tostring(tool.uses or 0)}),
            cx,
            cy + card_h - RuntimeUI.sized(USES_BOTTOM_MARGIN),
            card_w,
            "center"
        )
    end

    love.graphics.setFont(previous_font)
    return layout
end

local function build_available_tools()
    local tools = {}
    for i, src in ipairs(RewardToolsData) do
        tools[i] = {
            id = src.id,
            name = tr(src.name_key, src.name_default),
            description = tr(src.description_key, src.description_default),
            uses = src.uses,
            icon = src.icon,
        }
    end
    return tools
end

local function pick_candidate_tools(available_tools)
    local tools = {}
    for i, tool in ipairs(available_tools) do
        tools[i] = tool
    end

    if SELECTION_SHUFFLE then
        for i = #tools, 2, -1 do
            local j = math.random(i)
            tools[i], tools[j] = tools[j], tools[i]
        end
    end

    local picked = {}
    local max_count = math.min(CHOICES_COUNT, #tools)
    for i = 1, max_count do
        picked[i] = tools[i]
    end
    return picked
end

local function choose_selected_tool()
    AudioManager.play_ui(CONFIRM_SFX)
    if run and candidate_tools[selected] and run.addTool then
        run:addTool(candidate_tools[selected])
    end
    Navigation.go(NEXT_MODULE, {run = run})
end

function RewardModule:enter(params)
    run = params and params.run or nil
    candidate_tools = pick_candidate_tools(build_available_tools())
    selected = 1
    layout_cache = nil
end

function RewardModule:update(dt)
end

function RewardModule:draw()
    layout_cache = draw_ui(candidate_tools, selected)
end

function RewardModule:keypressed(_key)
end

function RewardModule:mousemoved(x, y, _dx, _dy)
    local layout = layout_cache or get_layout(candidate_tools)
    local previous = selected
    for i, rect in ipairs(layout.cards or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            selected = i
            break
        end
    end
    if selected ~= previous then
        AudioManager.play_ui(HOVER_SFX)
    end
end

function RewardModule:mousepressed(x, y, button)
    if button ~= CONFIRM_MOUSE_BUTTON then
        return
    end
    local layout = layout_cache or get_layout(candidate_tools)
    for i, rect in ipairs(layout.cards or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            selected = i
            choose_selected_tool()
            return
        end
    end
end

return RewardModule
