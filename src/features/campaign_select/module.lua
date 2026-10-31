local AudioManager = require("src.core.audio_manager")
local I18n = require("src.core.i18n")
local MenuParticles = require("src.core.menu_particles")
local Navigation = require("src.core.navigation")
local RuntimeUI = require("src.core.runtime_ui")
local MenuSurface = require("src.features.ui_v2.menu_surface")
local Schema = require("src.core.schema")
local CommissionMenu = require("src.data.commission_menu")
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
    local _,height = love.graphics.getDimensions()
    local scale = RuntimeUI.scale() * math.max(.63,math.min(1.15,height/1080))
        * (RuntimeUI.big_text() and 1.12 or 1)
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
        title_font = load_font({FONT_TEXT, FONT_UPPERCASE, FONT_FALLBACK}, math.max(24,math.floor(94*scale+.5)))
    end
    if not subtitle_font then
        subtitle_font = load_font({FONT_TEXT, FONT_UPPERCASE, FONT_FALLBACK}, math.max(18,math.floor(46*scale+.5)))
    end
    if not item_font then
        item_font = load_font({FONT_TEXT, FONT_UPPERCASE, FONT_FALLBACK}, math.max(18,math.floor(38*scale+.5)))
    end
    if not detail_font then
        detail_font = load_font({FONT_TEXT, FONT_UPPERCASE, FONT_FALLBACK}, math.max(13,math.floor(22*scale+.5)))
    end
end

local function reset_particles()
    particles = MenuParticles.create_default(34)
end

local function update_particles(dt)
    MenuParticles.update(particles, dt, RuntimeUI.reduced_animations())
end

local function build_layout()
    local w,h=love.graphics.getDimensions()
    local panel_w=math.min(math.floor(w*.78),RuntimeUI.sized(1100))
    local panel_x=(w-panel_w)*.5
    local pad=math.max(18,math.floor(panel_w*.07))
    local content_w=panel_w-2*pad
    local title_y=math.floor(h*.145)
    local subtitle_y=math.floor(h*.31)
    local item_face=item_font or love.graphics.getFont()
    local detail_face=detail_font or love.graphics.getFont()
    local item_h=item_face:getHeight()
    local detail_h=detail_face:getHeight()
    local row_h=math.max(item_h+detail_h+RuntimeUI.sized(14),
        math.floor(h*.080))
    local row_gap=math.max(10,math.floor(h*.018))
    local subtitle_h=(subtitle_font or love.graphics.getFont()):getHeight()
    local start_y=subtitle_y+subtitle_h+math.max(28,math.floor(h*.052))
    local entries=#campaigns+1
    local bottom_limit=h-math.max(26,math.floor(h*.09))
    local available=bottom_limit-start_y-30
    if row_h*entries+row_gap*(entries-1)>available then
        row_gap=math.max(6,math.floor(row_gap*.60))
        row_h=math.max(item_h+detail_h+4,
            math.floor((available-row_gap*(entries-1))/entries))
    end
    local items={}
    for i,campaign in ipairs(campaigns) do
        local label=campaign.title or campaign.id
        if campaign.subtitle and campaign.subtitle~="" then
            label=label.." - "..campaign.subtitle
        end
        items[#items+1]={
            id="campaign:"..tostring(i),kind="campaign",campaign_index=i,
            label=label,detail=campaign.detail,
            x=panel_x+pad,y=start_y+(i-1)*(row_h+row_gap),
            w=content_w,h=row_h,
        }
    end
    local back_y=start_y+#campaigns*(row_h+row_gap)
    items[#items+1]={
        id="back",kind="back",label=tr_entry(BACK_ENTRY),
        x=panel_x+pad,y=back_y,w=content_w,h=row_h,
    }
    local frame_top=math.max(18,title_y-math.max(34,math.floor(h*.052)))
    local frame_bottom=math.min(h-18,back_y+row_h+math.max(25,math.floor(h*.048)))
    return {
        w=w,h=h,center_x=w*.5,max_main_w=panel_w,
        title_y=title_y,subtitle_y=subtitle_y,items=items,
        frame={x=panel_x,y=frame_top,w=panel_w,h=frame_bottom-frame_top},
    }
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

    MenuSurface.backdrop(w,h,high_contrast,1)
    MenuSurface.panel(layout.frame,{high_contrast=high_contrast})

    MenuParticles.draw(particles, w, h, RuntimeUI.scale(), high_contrast)
end

local function draw_title(layout)
    local center_x = layout.center_x
    local high_contrast = RuntimeUI.high_contrast()
    local title_face = title_font or love.graphics.getFont()
    local subtitle_face = subtitle_font or love.graphics.getFont()

    love.graphics.setFont(title_face)
    local title_text=tr_entry(BRANDING_TITLE_ENTRY)
    love.graphics.setColor(.29,.18,.09,1)
    love.graphics.printf(title_text,center_x-layout.max_main_w*.5+20,
        layout.title_y,layout.max_main_w-40,"center")
    love.graphics.setFont(subtitle_face)
    love.graphics.setColor(.43,.29,.16,1)
    love.graphics.printf(tr_entry(SUBTITLE_ENTRY),
        center_x-layout.max_main_w*.5+30,layout.subtitle_y,
        layout.max_main_w-60,"center")
    local y=layout.subtitle_y+subtitle_face:getHeight()+math.max(8,layout.h*.012)
    MenuSurface.rule(center_x-170,y,340,1)
end

local function draw_items(layout)
    local face=item_font or love.graphics.getFont()
    local detail=detail_font or love.graphics.getFont()
    local item_h=face:getHeight()
    local detail_h=detail:getHeight()
    for i,item in ipairs(layout.items) do
        local progress=ease_out_cubic(get_entrance_progress(.14+(i-1)*.08,.55))
        local active=hovered_id==item.id or
           (item.kind=='campaign' and selected_index==item.campaign_index)
        local disabled=item.kind=='campaign' and
           not campaigns[item.campaign_index].implemented
        MenuSurface.item(item,{
            active=active,disabled=disabled,
            primary=item.kind=='campaign',alpha=progress})
        local ink=active and {.29,.18,.08} or {.35,.24,.13}
        local faded={.49,.36,.23}
        if disabled then ink={.56,.51,.43};faded=ink end
        local top=item.y+(item.h-item_h-(item.kind=='campaign' and
           (detail_h+RuntimeUI.sized(4)) or 0))*.5
        love.graphics.setFont(face)
        love.graphics.setColor(ink[1],ink[2],ink[3],progress)
        love.graphics.printf(item.label,item.x+20,top,item.w-40,"center")
        if item.kind=='campaign' then
            love.graphics.setFont(detail)
            love.graphics.setColor(faded[1],faded[2],faded[3],progress)
            love.graphics.printf(item.detail or "",item.x+20,
              top+item_h+RuntimeUI.sized(4),item.w-40,"center")
        end
    end
end

local function start_campaign(campaign_id)
    for _, item in ipairs(CommissionMenu) do
        if item.id == campaign_id and item.implemented then
            Navigation.go(CAMPAIGN_MODULE, {new_run = true})
            return
        end
    end
end

function CampaignSelect:enter()
    ensure_assets()
    campaigns = CommissionMenu
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
