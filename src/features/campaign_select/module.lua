local AudioManager = require("src.core.audio_manager")
local I18n = require("src.core.i18n")
local MenuParticles = require("src.core.menu_particles")
local Navigation = require("src.core.navigation")
local RuntimeUI = require("src.core.runtime_ui")
local Schema = require("src.core.schema")
local Commissions = require("src.content.commissions")
local CampaignSelectSchema = require("src.data.campaign_select_schema")

local CampaignSelect = {}

local ASSET_SCHEMA = CampaignSelectSchema.assets or {}
local COLOR_SCHEMA = CampaignSelectSchema.colors or {}
local TEXT_SCHEMA = CampaignSelectSchema.text or {}
local FLOW_SCHEMA = CampaignSelectSchema.flow or {}

local expect_string = Schema.expect_string
local expect_number = Schema.expect_number
local expect_entry = Schema.expect_entry
local expect_color3 = Schema.expect_color3

local MENU_BG_PATH = expect_string(ASSET_SCHEMA.background_path, "assets.background_path")
local FONT_TEXT = expect_string(ASSET_SCHEMA.font_text, "assets.font_text")
local FONT_UPPERCASE = expect_string(ASSET_SCHEMA.font_uppercase, "assets.font_uppercase")
local FONT_FALLBACK = expect_string(ASSET_SCHEMA.font_fallback, "assets.font_fallback")

local MENU_TITLE_GOLD = expect_color3(COLOR_SCHEMA.title_gold, "colors.title_gold")
local MENU_SUBTITLE_IVORY = expect_color3(COLOR_SCHEMA.subtitle_ivory, "colors.subtitle_ivory")
local MENU_TEXT_ACTIVE = expect_color3(COLOR_SCHEMA.text_active, "colors.text_active")
local MENU_TEXT_PRIMARY = expect_color3(COLOR_SCHEMA.text_primary, "colors.text_primary")
local MENU_TEXT_SECONDARY = expect_color3(COLOR_SCHEMA.text_secondary, "colors.text_secondary")
local MENU_TEXT_SHADOW = expect_color3(COLOR_SCHEMA.text_shadow, "colors.text_shadow")
local MENU_ACCENT_FILL = expect_color3(COLOR_SCHEMA.accent_fill, "colors.accent_fill")

local BRANDING_TITLE_ENTRY = expect_entry(TEXT_SCHEMA.branding_title, "text.branding_title")
local SUBTITLE_ENTRY = expect_entry(TEXT_SCHEMA.subtitle, "text.subtitle")
local BACK_ENTRY = expect_entry(TEXT_SCHEMA.item_back, "text.item_back")
local FOLIOS_DETAIL_ENTRY = expect_entry(TEXT_SCHEMA.detail_folios, "text.detail_folios")
local DIRTY_THRESHOLD_ENTRY = expect_entry(TEXT_SCHEMA.detail_dirty_threshold, "text.detail_dirty_threshold")
local STANDARD_SCORING_ENTRY = expect_entry(TEXT_SCHEMA.detail_standard_scoring, "text.detail_standard_scoring")
local CONFIRM_MOUSE_BUTTON = expect_number(FLOW_SCHEMA.confirm_mouse_button, "flow.confirm_mouse_button")
local AUDIO_HOVER_SFX = expect_string(FLOW_SCHEMA.audio_hover, "flow.audio_hover")
local AUDIO_CONFIRM_SFX = expect_string(FLOW_SCHEMA.audio_confirm, "flow.audio_confirm")
local AUDIO_BACK_SFX = expect_string(FLOW_SCHEMA.audio_back, "flow.audio_back")
local BACK_MODULE = expect_string(FLOW_SCHEMA.back_module, "flow.back_module")
local CAMPAIGN_MODULE = expect_string(FLOW_SCHEMA.campaign_module, "flow.campaign_module")

local campaigns = {}
local selected_index = nil
local hovered_id = nil
local view_clock = 0
local layout_cache = nil
local particles = {}

local bg_image = nil
local title_font = nil
local subtitle_font = nil
local item_font = nil
local detail_font = nil
local cached_scale = nil

local function tr(key, fallback, params)
    return I18n.t(key, fallback, params)
end

local function tr_entry(entry, params)
    if type(entry) ~= "table" then
        return ""
    end
    return tr(entry.key, entry.default, params)
end

local function clamp(v, min_v, max_v)
    if v < min_v then return min_v end
    if v > max_v then return max_v end
    return v
end

local function clamp01(v)
    return clamp(v, 0, 1)
end

local function ease_out_cubic(t)
    local inv = 1 - clamp01(t)
    return 1 - inv * inv * inv
end

local function get_entrance_progress(delay, duration)
    if RuntimeUI.reduced_animations() then
        return 1
    end
    return clamp01((view_clock - delay) / math.max(0.001, duration))
end

local function point_in_rect(px, py, rect)
    return rect and px >= rect.x and px <= rect.x + rect.w and py >= rect.y and py <= rect.y + rect.h
end

local function load_font(candidates, size)
    if love.filesystem and love.filesystem.getInfo then
        for _, path in ipairs(candidates) do
            if love.filesystem.getInfo(path) then
                local ok, font = pcall(function()
                    return love.graphics.newFont(path, size)
                end)
                if ok and font then
                    return font
                end
            end
        end
    end
    local ok, fallback = pcall(function()
        return love.graphics.newFont(size)
    end)
    if ok and fallback then
        return fallback
    end
    return love.graphics.getFont()
end

local function ensure_assets()
    local scale = RuntimeUI.scale()
    if cached_scale ~= scale then
        title_font = nil
        subtitle_font = nil
        item_font = nil
        detail_font = nil
        cached_scale = scale
    end

    if not bg_image and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(MENU_BG_PATH) then
        pcall(function()
            bg_image = love.graphics.newImage(MENU_BG_PATH)
        end)
    end

    if not title_font then
        title_font = load_font({FONT_TEXT, FONT_UPPERCASE, FONT_FALLBACK}, RuntimeUI.sized(94))
    end
    if not subtitle_font then
        subtitle_font = load_font({FONT_TEXT, FONT_UPPERCASE, FONT_FALLBACK}, RuntimeUI.sized(46))
    end
    if not item_font then
        item_font = load_font({FONT_TEXT, FONT_UPPERCASE, FONT_FALLBACK}, RuntimeUI.sized(38))
    end
    if not detail_font then
        detail_font = load_font({FONT_TEXT, FONT_UPPERCASE, FONT_FALLBACK}, RuntimeUI.sized(22))
    end
end

local function reset_particles()
    particles = MenuParticles.create_default(34)
end

local function update_particles(dt)
    MenuParticles.update(particles, dt, RuntimeUI.reduced_animations())
end

local function build_layout()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local center_x = w * 0.5
    local max_main_w = math.min(980, w * 0.78)

    local layout = {
        w = w,
        h = h,
        center_x = center_x,
        max_main_w = max_main_w,
        title_y = math.floor(h * 0.08),
        subtitle_y = math.floor(h * 0.31),
        items = {},
    }

    local entries = #campaigns + 1
    local item_face = item_font or love.graphics.getFont()
    local detail_face = detail_font or love.graphics.getFont()
    local item_h = item_face:getHeight()
    local detail_h = detail_face:getHeight()
    local row_h = math.max(item_h + detail_h + RuntimeUI.sized(12), math.floor(h * 0.065))
    local row_gap = math.max(14, math.floor(row_h * 0.30))
    local subtitle_h = (subtitle_font and subtitle_font:getHeight()) or math.floor(h * 0.05)
    local top_anchor = layout.subtitle_y + subtitle_h + 34
    local bottom_limit = h - math.floor(h * 0.16)
    local available = math.max(row_h, bottom_limit - top_anchor)
    local total_h = entries * row_h + (entries - 1) * row_gap

    if total_h > available and entries > 1 then
        local fitted_gap = math.floor((available - entries * row_h) / (entries - 1))
        row_gap = math.max(8, fitted_gap)
        total_h = entries * row_h + (entries - 1) * row_gap
        if total_h > available then
            row_h = math.max(item_h + detail_h + 8, math.floor((available - (entries - 1) * row_gap) / entries))
            total_h = entries * row_h + (entries - 1) * row_gap
        end
    end

    local start_y = top_anchor
    if total_h < available then
        start_y = top_anchor + math.floor((available - total_h) * 0.14)
    end

    local row_w = max_main_w * 0.92

    for i, campaign in ipairs(campaigns) do
        local y = start_y + (i - 1) * (row_h + row_gap)
        local label = campaign.title or campaign.id
        if campaign.subtitle and campaign.subtitle ~= "" then
            label = label .. " - " .. campaign.subtitle
        end
        local folios_count = #(campaign.folios or {})
        local folios_detail = tr_entry(FOLIOS_DETAIL_ENTRY, {
            count = folios_count,
        })
        local detail
        if campaign.dirty_stains_threshold then
            detail = tr_entry(DIRTY_THRESHOLD_ENTRY, {
                folios = folios_detail,
                threshold = campaign.dirty_stains_threshold,
            })
        else
            detail = tr_entry(STANDARD_SCORING_ENTRY, {
                folios = folios_detail,
            })
        end
        layout.items[#layout.items + 1] = {
            id = "campaign:" .. tostring(i),
            kind = "campaign",
            campaign_index = i,
            label = label,
            detail = detail,
            x = center_x - row_w * 0.5,
            y = y,
            w = row_w,
            h = row_h,
        }
    end

    local back_y = start_y + (#campaigns) * (row_h + row_gap)
    layout.items[#layout.items + 1] = {
        id = "back",
        kind = "back",
        label = tr_entry(BACK_ENTRY),
        x = center_x - row_w * 0.5,
        y = back_y,
        w = row_w,
        h = row_h,
    }

    return layout
end

local function draw_background(layout)
    local w, h = layout.w, layout.h
    local high_contrast = RuntimeUI.high_contrast()

    if bg_image then
        local bw, bh = bg_image:getWidth(), bg_image:getHeight()
        local scale = math.max(w / bw, h / bh)
        local dw, dh = bw * scale, bh * scale
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bg_image, (w - dw) * 0.5, (h - dh) * 0.5, 0, scale, scale)
    else
        love.graphics.setColor(0.05, 0.04, 0.03, 1)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    love.graphics.setColor(0, 0, 0, high_contrast and 0.90 or 0.83)
    love.graphics.rectangle("fill", 0, 0, w * 0.52, h)
    love.graphics.setColor(0, 0, 0, high_contrast and 0.52 or 0.38)
    love.graphics.rectangle("fill", w * 0.52, 0, w * 0.24, h)
    love.graphics.setColor(0, 0, 0, high_contrast and 0.58 or 0.50)
    love.graphics.rectangle("fill", 0, 0, w, h * 0.16)
    love.graphics.setColor(0, 0, 0, high_contrast and 0.80 or 0.68)
    love.graphics.rectangle("fill", 0, h * 0.84, w, h * 0.16)
    love.graphics.setColor(0.36, 0.20, 0.06, high_contrast and 0.12 or 0.08)
    love.graphics.rectangle("fill", 0, 0, w, h)

    MenuParticles.draw(particles, w, h, RuntimeUI.scale(), high_contrast)
end

local function draw_title(layout)
    local center_x = layout.center_x
    local high_contrast = RuntimeUI.high_contrast()
    local title_face = title_font or love.graphics.getFont()
    local subtitle_face = subtitle_font or love.graphics.getFont()

    love.graphics.setFont(title_face)
    love.graphics.setColor(MENU_TEXT_SHADOW[1], MENU_TEXT_SHADOW[2], MENU_TEXT_SHADOW[3], high_contrast and 0.74 or 0.54)
    local title_text = tr_entry(BRANDING_TITLE_ENTRY)
    love.graphics.printf(title_text, center_x - 500 + 3, layout.title_y + 3, 1000, "center")
    love.graphics.setColor(MENU_TITLE_GOLD[1], MENU_TITLE_GOLD[2], MENU_TITLE_GOLD[3], 1)
    love.graphics.printf(title_text, center_x - 500, layout.title_y, 1000, "center")

    love.graphics.setFont(subtitle_face)
    love.graphics.setColor(
        high_contrast and 1.00 or MENU_SUBTITLE_IVORY[1],
        high_contrast and 0.96 or MENU_SUBTITLE_IVORY[2],
        high_contrast and 0.88 or MENU_SUBTITLE_IVORY[3],
        high_contrast and 1.00 or 0.92
    )
    love.graphics.printf(tr_entry(SUBTITLE_ENTRY), center_x - 450, layout.subtitle_y, 900, "center")

    local y = layout.subtitle_y + subtitle_face:getHeight() + 8
    love.graphics.setColor(0.92, 0.74, 0.32, high_contrast and 0.50 or 0.34)
    love.graphics.rectangle("fill", center_x - 210, y, 180, 2)
    love.graphics.rectangle("fill", center_x + 30, y, 180, 2)
    love.graphics.polygon("fill", center_x, y + 6, center_x + 6, y, center_x, y - 6, center_x - 6, y)
end

local function draw_items(layout)
    local item_face = item_font or love.graphics.getFont()
    local detail_face = detail_font or love.graphics.getFont()
    local item_h = item_face:getHeight()
    local detail_h = detail_face:getHeight()

    for i, item in ipairs(layout.items) do
        local item_progress = ease_out_cubic(get_entrance_progress(0.14 + (i - 1) * 0.08, 0.55))
        local x_offset = RuntimeUI.sized(24) * (1 - item_progress)
        local draw_x = item.x - x_offset
        local is_hovered = hovered_id == item.id
        local is_selected = item.kind == "campaign" and selected_index == item.campaign_index
        local active = is_hovered or is_selected

        if active then
            love.graphics.setColor(MENU_ACCENT_FILL[1], MENU_ACCENT_FILL[2], MENU_ACCENT_FILL[3], 0.16 * item_progress)
            love.graphics.rectangle("fill", draw_x, item.y + 2, item.w, item.h - 4, 8, 8)
        end

        local label_color = active and MENU_TEXT_ACTIVE or MENU_TEXT_PRIMARY
        local detail_color = active and MENU_TEXT_ACTIVE or MENU_TEXT_SECONDARY
        if item.kind == "back" then
            label_color = active and MENU_TEXT_ACTIVE or MENU_TEXT_PRIMARY
        end

        if item.kind == "campaign" then
            local text_block_h = item_h + detail_h + RuntimeUI.sized(4)
            local text_top = item.y + math.floor((item.h - text_block_h) * 0.5)
            local label_w = item_face:getWidth(item.label)
            local label_x = draw_x + (item.w - label_w) * 0.5
            local detail_w = detail_face:getWidth(item.detail)
            local detail_x = draw_x + (item.w - detail_w) * 0.5

            love.graphics.setFont(item_face)
            love.graphics.setColor(MENU_TEXT_SHADOW[1], MENU_TEXT_SHADOW[2], MENU_TEXT_SHADOW[3], 0.56 * item_progress)
            love.graphics.print(item.label, label_x + 1, text_top + 1)
            love.graphics.setColor(label_color[1], label_color[2], label_color[3], (active and 1.0 or 0.95) * item_progress)
            love.graphics.print(item.label, label_x, text_top)

            love.graphics.setFont(detail_face)
            love.graphics.setColor(MENU_TEXT_SHADOW[1], MENU_TEXT_SHADOW[2], MENU_TEXT_SHADOW[3], 0.46 * item_progress)
            love.graphics.print(item.detail, detail_x + 1, text_top + item_h + RuntimeUI.sized(4) + 1)
            love.graphics.setColor(detail_color[1], detail_color[2], detail_color[3], (active and 0.95 or 0.85) * item_progress)
            love.graphics.print(item.detail, detail_x, text_top + item_h + RuntimeUI.sized(4))
        else
            local label_w = item_face:getWidth(item.label)
            local label_x = draw_x + (item.w - label_w) * 0.5
            local label_y = item.y + math.floor((item.h - item_h) * 0.5)

            love.graphics.setFont(item_face)
            love.graphics.setColor(MENU_TEXT_SHADOW[1], MENU_TEXT_SHADOW[2], MENU_TEXT_SHADOW[3], 0.56 * item_progress)
            love.graphics.print(item.label, label_x + 1, label_y + 1)
            love.graphics.setColor(label_color[1], label_color[2], label_color[3], (active and 1.0 or 0.95) * item_progress)
            love.graphics.print(item.label, label_x, label_y)
        end
    end
end

local function start_campaign(campaign_id)
    Navigation.go(CAMPAIGN_MODULE, {
        campaign_id = campaign_id,
        seed = os.time(),
    })
end

function CampaignSelect:enter()
    ensure_assets()
    campaigns = Commissions.getAll()
    selected_index = nil
    hovered_id = nil
    layout_cache = nil
    view_clock = 0
    reset_particles()
end

function CampaignSelect:exit()
end

function CampaignSelect:update(dt)
    view_clock = view_clock + (dt or 0)
    update_particles(dt or 0)
end

function CampaignSelect:draw()
    ensure_assets()
    layout_cache = build_layout()
    local layout = layout_cache

    draw_background(layout)
    draw_title(layout)
    draw_items(layout)
end

function CampaignSelect:keypressed(_key, _scancode, _isrepeat)
end

function CampaignSelect:mousemoved(x, y, _dx, _dy)
    local layout = layout_cache or build_layout()
    local previous_hover = hovered_id
    hovered_id = nil

    for _, item in ipairs(layout.items) do
        if point_in_rect(x, y, item) then
            hovered_id = item.id
            break
        end
    end

    if hovered_id and previous_hover ~= hovered_id and not RuntimeUI.reduced_animations() then
        AudioManager.play_ui(AUDIO_HOVER_SFX)
    end
end

function CampaignSelect:mousepressed(x, y, button)
    if button ~= CONFIRM_MOUSE_BUTTON then
        return
    end

    local layout = layout_cache or build_layout()
    layout_cache = layout

    for _, item in ipairs(layout.items) do
        if point_in_rect(x, y, item) then
            if item.kind == "back" then
                AudioManager.play_ui(AUDIO_BACK_SFX)
                Navigation.go(BACK_MODULE)
            else
                selected_index = item.campaign_index
                AudioManager.play_ui(AUDIO_CONFIRM_SFX)
                local campaign = campaigns[item.campaign_index]
                if campaign and campaign.id then
                    start_campaign(campaign.id)
                end
            end
            return
        end
    end
end

return CampaignSelect
