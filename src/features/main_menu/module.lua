local MainMenu = {}
local AudioManager = require("src.core.audio_manager")
local I18n = require("src.core.i18n")
local MenuParticles = require("src.core.menu_particles")
local Navigation = require("src.core.navigation")
local RuntimeUI = require("src.core.runtime_ui")
local Version = require("src.core.version")
local MenuSurface = require("src.features.ui_v2.menu_surface")
local Schema = require("src.core.schema")
local SettingsState = require("src.core.settings_state")
local MainMenuSchema = require("src.data.main_menu_schema")

local ASSET_SCHEMA = MainMenuSchema.assets or {}
local LABEL_SCHEMA = MainMenuSchema.labels or {}
local MODAL_SCHEMA = MainMenuSchema.modals or {}
local LINKS_SCHEMA = MainMenuSchema.links or {}
local TRANSITION_SCHEMA = MainMenuSchema.transitions or {}
local FLOW_SCHEMA = MainMenuSchema.flow or {}
local MENU_ITEMS_SCHEMA = MainMenuSchema.menu_items or {}

local expect_string = Schema.expect_string
local expect_number = Schema.expect_number
local expect_entry = Schema.expect_entry

local MENU_BG_PATH = expect_string(ASSET_SCHEMA.background_path, "assets.background_path")
local MENU_MUSIC_PATH = expect_string(ASSET_SCHEMA.music_path, "assets.music_path")
local FONT_TEXT = expect_string(ASSET_SCHEMA.font_text, "assets.font_text")
local FONT_UPPERCASE = expect_string(ASSET_SCHEMA.font_uppercase, "assets.font_uppercase")
local FONT_FALLBACK = expect_string(ASSET_SCHEMA.font_fallback, "assets.font_fallback")
local WISHLIST_URL = expect_string(LINKS_SCHEMA.wishlist_url, "links.wishlist_url")
local SUBTITLE_ENTRY = expect_entry(LABEL_SCHEMA.subtitle, "labels.subtitle")
local FOOTER_ALPHA_ENTRY = expect_entry(LABEL_SCHEMA.footer_alpha, "labels.footer_alpha")
local BRANDING_TITLE_ENTRY = expect_entry(LABEL_SCHEMA.branding_title, "labels.branding_title")
local MODAL_NO_SAVE_ENTRY = expect_entry(MODAL_SCHEMA.no_save, "modals.no_save")
local MODAL_WISHLIST_FALLBACK_ENTRY = expect_entry(MODAL_SCHEMA.wishlist_fallback, "modals.wishlist_fallback")
local CONFIRM_MOUSE_BUTTON = expect_number(FLOW_SCHEMA.confirm_mouse_button, "flow.confirm_mouse_button")
local AUDIO_TOGGLE_SFX = expect_string(FLOW_SCHEMA.audio_toggle, "flow.audio_toggle")
local AUDIO_CONFIRM_SFX = expect_string(FLOW_SCHEMA.audio_confirm, "flow.audio_confirm")
local AUDIO_HOVER_SFX = expect_string(FLOW_SCHEMA.audio_hover, "flow.audio_hover")
local NAVIGATION_NEW_GAME = expect_string(FLOW_SCHEMA.navigation_new_game, "flow.navigation_new_game")
local NAVIGATION_CONTINUE = expect_string(FLOW_SCHEMA.navigation_continue, "flow.navigation_continue")
local NAVIGATION_SETTINGS = expect_string(FLOW_SCHEMA.navigation_settings, "flow.navigation_settings")
local MUSIC_TRACK_ID = expect_string(FLOW_SCHEMA.music_track_id, "flow.music_track_id")

local function tr(key, fallback, params)
    return I18n.t(key, fallback, params)
end

local function get_subtitle_label()
    return tr(SUBTITLE_ENTRY.key, SUBTITLE_ENTRY.default)
end

local function get_footer_version_label()
    return 'v' .. Version.current()
end

local function get_footer_alpha_label()
    return tr(FOOTER_ALPHA_ENTRY.key, FOOTER_ALPHA_ENTRY.default)
end

local function tr_entry(entry, params)
    if type(entry) ~= "table" then
        return ""
    end
    return tr(entry.key, entry.default, params)
end

local TRANSITION_FADE_DURATION = expect_number(TRANSITION_SCHEMA.fade_duration, "transitions.fade_duration")
local TRANSITION_SWITCH_DELAY = expect_number(TRANSITION_SCHEMA.switch_delay, "transitions.switch_delay")

local menu_items = {}

local function build_menu_items()
    local items = {}
    for _, source in ipairs(MENU_ITEMS_SCHEMA) do
        local label_entry = source.label or {}
        items[#items + 1] = {
            id = source.id,
            label_entry = label_entry,
            label = tr(label_entry.key, label_entry.default),
            primary = source.primary and true or false,
            enabled = source.enabled and true or false,
            delay = tonumber(source.delay) or 0,
        }
    end
    return items
end

local function find_menu_item(item_id)
    for _, item in ipairs(menu_items) do
        if item.id == item_id then
            return item
        end
    end
    return nil
end

local function refresh_menu_labels()
    for _, item in ipairs(menu_items) do
        item.label = tr_entry(item.label_entry)
    end
end

local fonts = {
    title = nil,
    title_upper = nil,
    subtitle = nil,
    subtitle_upper = nil,
    primary = nil,
    primary_upper = nil,
    secondary = nil,
    secondary_upper = nil,
    footer = nil,
    footer_upper = nil,
    modal = nil,
    modal_upper = nil,
    sizes = nil,
}

local menu_bg = nil
local music = nil
local music_play_attempted = false
local has_save_data = false
local modal_message = nil
local modal_timer = 0
local selected = nil
local hovered = nil
local hovered_mute = false
local mouse_has_moved = false
local menu_clock = 0
local transition_clock = 0
local pending_action = nil
local muted = false
local particles = {}
local cached_layout = nil

menu_items = build_menu_items()

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

local function point_in_rect(x, y, rect)
    return rect and x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function set_color(r, g, b, a, scene_alpha)
    love.graphics.setColor(r, g, b, (a or 1) * (scene_alpha or 1))
end

local function is_uppercase_text(text)
    if type(text) ~= "string" or text == "" then
        return false
    end
    local has_upper = text:find("%u") ~= nil
    local has_lower = text:find("%l") ~= nil
    return has_upper and (not has_lower)
end

local function pick_font_for_text(text, text_font, uppercase_font)
    if is_uppercase_text(text) and uppercase_font then
        return uppercase_font
    end
    return text_font
end

local function load_font(candidates, size)
    for _, fname in ipairs(candidates) do
        if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(fname) then
            local ok, f = pcall(function() return love.graphics.newFont(fname, size) end)
            if ok and f then
                return f
            end
        end
    end
    local ok, fallback = pcall(function() return love.graphics.newFont(size) end)
    return (ok and fallback) or love.graphics.getFont()
end

local function get_resolution_text_scale(view_h)
    local h = tonumber(view_h) or 1080
    return clamp(h / 1080, 0.62, 1.15)
end

local function ensure_fonts(view_h)
    local res_scale = get_resolution_text_scale(view_h)
    local sizes = {
        title = RuntimeUI.sized((RuntimeUI.big_text() and 108 or 92) * res_scale),
        subtitle = RuntimeUI.sized((RuntimeUI.big_text() and 26 or 22) * res_scale),
        primary = RuntimeUI.sized((RuntimeUI.big_text() and 56 or 48) * res_scale),
        secondary = RuntimeUI.sized((RuntimeUI.big_text() and 40 or 34) * res_scale),
        footer = RuntimeUI.sized((RuntimeUI.big_text() and 22 or 18) * res_scale),
        modal = RuntimeUI.sized((RuntimeUI.big_text() and 30 or 24) * res_scale),
    }

    local dirty = not fonts.sizes
    if not dirty then
        for k, v in pairs(sizes) do
            if fonts.sizes[k] ~= v then
                dirty = true
                break
            end
        end
    end
    if not dirty then
        return
    end

    fonts.title = load_font({FONT_TEXT, FONT_FALLBACK, FONT_UPPERCASE}, sizes.title)
    fonts.title_upper = load_font({FONT_UPPERCASE, FONT_TEXT, FONT_FALLBACK}, sizes.title)
    fonts.subtitle = load_font({FONT_TEXT, FONT_FALLBACK, FONT_UPPERCASE}, sizes.subtitle)
    fonts.subtitle_upper = load_font({FONT_UPPERCASE, FONT_TEXT, FONT_FALLBACK}, sizes.subtitle)
    fonts.primary = load_font({FONT_TEXT, FONT_FALLBACK, FONT_UPPERCASE}, sizes.primary)
    fonts.primary_upper = load_font({FONT_UPPERCASE, FONT_TEXT, FONT_FALLBACK}, sizes.primary)
    fonts.secondary = load_font({FONT_TEXT, FONT_FALLBACK, FONT_UPPERCASE}, sizes.secondary)
    fonts.secondary_upper = load_font({FONT_UPPERCASE, FONT_TEXT, FONT_FALLBACK}, sizes.secondary)
    fonts.footer = load_font({FONT_TEXT, FONT_FALLBACK, FONT_UPPERCASE}, sizes.footer)
    fonts.footer_upper = load_font({FONT_UPPERCASE, FONT_TEXT, FONT_FALLBACK}, sizes.footer)
    fonts.modal = load_font({FONT_TEXT, FONT_FALLBACK, FONT_UPPERCASE}, sizes.modal)
    fonts.modal_upper = load_font({FONT_UPPERCASE, FONT_TEXT, FONT_FALLBACK}, sizes.modal)
    fonts.sizes = sizes
end

local function get_audio_settings()
    local state = SettingsState.get()
    return state and state.audio or nil
end

local function get_menu_music_volume()
    local audio = get_audio_settings()
    if not audio then return 0.2 end
    if audio.mute_music then return 0 end
    return clamp(tonumber(audio.music_volume) or 0.6, 0, 1)
end

local function sync_mute_state()
    local audio = get_audio_settings()
    muted = audio and audio.mute_music and true or false
end

local function toggle_music_mute()
    local state = SettingsState.get()
    if type(state) ~= "table" then return end
    state.audio = state.audio or {}
    state.audio.mute_music = not (state.audio.mute_music and true or false)
    SettingsState.set(state)
    pcall(function() SettingsState.save() end)
    pcall(function() SettingsState.apply() end)
    AudioManager.apply_audio_settings()
    sync_mute_state()
end

local function get_background_rect(window_w, window_h)
    if not menu_bg then
        return nil
    end
    local bw, bh = menu_bg:getWidth(), menu_bg:getHeight()
    local scale = math.max(window_w / bw, window_h / bh)
    local draw_w = bw * scale
    local draw_h = bh * scale
    local draw_x = window_w * 0.5 - draw_w * 0.5
    local draw_y = window_h * 0.5 - draw_h * 0.5
    return draw_x, draw_y, scale
end

local function reset_particles()
    particles = MenuParticles.create_default(34)
end

local function update_particles(dt)
    MenuParticles.update(particles, dt, RuntimeUI.reduced_animations())
end

local function get_entrance_progress(delay, duration)
    if RuntimeUI.reduced_animations() then
        return 1
    end
    return clamp01((menu_clock - delay) / math.max(0.001, duration))
end

local function get_scene_alpha()
    if not pending_action or RuntimeUI.reduced_animations() then
        return 1
    end
    return 1 - clamp01(transition_clock / TRANSITION_FADE_DURATION)
end

local function detect_continue_state()
    has_save_data = false
    local item = find_menu_item("continue")
    if item then item.enabled = false end
end

local function ensure_music()
    if not music and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(MENU_MUSIC_PATH) then
        local ok, src = pcall(function() return love.audio.newSource(MENU_MUSIC_PATH, "stream") end)
        if ok and src then
            music = src
        elseif love.sound and love.sound.newSoundData then
            local ok_sd, sd = pcall(function() return love.sound.newSoundData(MENU_MUSIC_PATH) end)
            if ok_sd and sd then
                local ok_static, static_src = pcall(function() return love.audio.newSource(sd, "static") end)
                if ok_static and static_src then
                    music = static_src
                end
            end
        end
    end

    if music then
        pcall(function()
            music:setLooping(true)
            music:setVolume(get_menu_music_volume())
            if not music:isPlaying() then
                music:play()
            end
        end)
        AudioManager.register_music_source(MUSIC_TRACK_ID, music)
    end
end

local function queue_transition(action_fn)
    if RuntimeUI.reduced_animations() then
        action_fn()
        return
    end
    pending_action = action_fn
    transition_clock = 0
end

local function begin_new_game()
    local seed = os.time()
    pcall(function()
        if love.math and love.math.setRandomSeed then
            love.math.setRandomSeed(seed)
        end
    end)
    Navigation.go(NAVIGATION_NEW_GAME)
end

local function begin_bot_duel()
    -- Independent opponent uses official scoring; human still throws physical D6.
    local seed = os.time()
    pcall(function()
        if love.math and love.math.setRandomSeed then
            love.math.setRandomSeed(seed)
        end
    end)
    Navigation.go(NAVIGATION_CONTINUE, {new_run = true, bot_duel = true})
end

local function continue_game()
    -- No Farkle resume format exists yet. Continue remains disabled.
end

local function compute_layout(w, h)
    ensure_fonts(h)
    local border = math.max(12, math.floor(h * .038))
    local left = math.max(border, math.floor(w * .045))
    local panel_w = math.min(math.floor(w * .48), RuntimeUI.sized(670), w - left - border)
    local menu_x = left + math.max(18, math.floor(panel_w * .060))
    local menu_w = panel_w - (menu_x - left) * 2
    local title_text = tr_entry(BRANDING_TITLE_ENTRY)
    local title_font = pick_font_for_text(title_text, fonts.title, fonts.title_upper)
    local subtitle_text = get_subtitle_label()
    local subtitle_font = pick_font_for_text(subtitle_text, fonts.subtitle, fonts.subtitle_upper)
    local title_h = title_font:getHeight()
    local subtitle_h = subtitle_font:getHeight()
    local row_gap = math.max(5, math.floor(h * .008))
    local item_heights = {}
    local total_rows = 0
    for i, item in ipairs(menu_items) do
        local face = pick_font_for_text(item.label,
            item.primary and fonts.primary or fonts.secondary,
            item.primary and fonts.primary_upper or fonts.secondary_upper)
        local nominal = item.primary and h * .061 or h * .052
        item_heights[i] = math.max(face:getHeight() + 8, math.floor(nominal))
        total_rows = total_rows + item_heights[i]
    end
    local title_gap = math.max(7, math.floor(h * .010))
    local header_gap = math.max(13, math.floor(h * .020))
    local divider_space = math.max(14, math.floor(h * .023))
    local footer_gap = math.max(16, math.floor(h * .027))
    local footer_h = fonts.footer:getHeight() + 7
    local content_h = title_h + title_gap + subtitle_h +
        header_gap + divider_space + total_rows +
        (#menu_items-1) * row_gap + footer_gap + footer_h
    -- Keep all six menu entries and the mute control within the window
    -- at both 720p and 1080p. Accessibility scale is not ignored.
    local max_h = h - 2*border - 44
    if content_h > max_h then
        local scale = max_h / content_h
        for i=1,#item_heights do
            item_heights[i] = math.max(20,math.floor(item_heights[i]*scale))
        end
        row_gap = math.max(3,math.floor(row_gap*scale))
        title_gap = math.floor(title_gap*scale)
        header_gap = math.floor(header_gap*scale)
        divider_space = math.floor(divider_space*scale)
        footer_gap = math.floor(footer_gap*scale)
        content_h = title_h + title_gap + subtitle_h + header_gap +
            divider_space + footer_gap + footer_h
        for _,height in ipairs(item_heights) do content_h = content_h + height end
        content_h = content_h + (#menu_items-1)*row_gap
    end
    local start_y = math.floor((h-content_h)*.5)
    local layout = {
        panel_x=left, menu_x=menu_x, menu_w=menu_w,
        title_y=start_y, subtitle_y=start_y+title_h+title_gap,
        divider_y=0, footer_y=0, mute_rect=nil, item_rects={},
    }
    layout.divider_y = layout.subtitle_y + subtitle_h + header_gap
    local y = layout.divider_y + divider_space
    for i,item in ipairs(menu_items) do
        layout.item_rects[i] = {x=menu_x,y=y,w=menu_w,h=item_heights[i]}
        y = y + item_heights[i] + row_gap
    end
    layout.footer_y = y - row_gap + footer_gap
    local version_label = get_footer_version_label()
    local alpha_label = get_footer_alpha_label()
    local face=pick_font_for_text(version_label,fonts.footer,fonts.footer_upper)
    local alpha_face=pick_font_for_text(alpha_label,fonts.footer,fonts.footer_upper)
    local text_w=face:getWidth(version_label)+alpha_face:getWidth(alpha_label)+20
    layout.mute_rect={
        x=math.min(menu_x+menu_w-32,menu_x+text_w+18),
        y=layout.footer_y-4,w=32,h=28,
    }
    layout.frame={
        x=left, y=math.max(border,start_y-26), w=panel_w,
        h=math.min(h-border,start_y+content_h+25)-math.max(border,start_y-26)
    }
    return layout
end
local function get_item_rect(layout, idx)
    local base = layout and layout.item_rects and layout.item_rects[idx]
    local item = menu_items[idx]
    if not base or not item then
        return nil, 0
    end
    local progress = ease_out_cubic(get_entrance_progress(item.delay, 0.60))
    local offset = RuntimeUI.sized(22) * (1 - progress)
    return {x = base.x - offset, y = base.y, w = base.w, h = base.h}, progress
end

local function draw_diamond(cx, cy, size, r, g, b, a, scene_alpha)
    set_color(r, g, b, a, scene_alpha)
    love.graphics.polygon("fill", cx, cy - size, cx + size, cy, cx, cy + size, cx - size, cy)
end

local function draw_mute_icon(rect, is_muted, scene_alpha)
    if not rect then return end
    local cx = rect.x + rect.w * 0.5
    local cy = rect.y + rect.h * 0.5
    local size = rect.h * 0.65
    local line_w = math.max(1.0, RuntimeUI.scale() * 1.2)

    set_color(0.35, 0.24, 0.13, 0.92, scene_alpha)
    love.graphics.setLineWidth(line_w)
    love.graphics.polygon("line",
        cx - size * 0.58, cy - size * 0.30,
        cx - size * 0.20, cy - size * 0.30,
        cx + size * 0.05, cy - size * 0.55,
        cx + size * 0.05, cy + size * 0.55,
        cx - size * 0.20, cy + size * 0.30,
        cx - size * 0.58, cy + size * 0.30
    )
    if is_muted then
        set_color(0.90, 0.64, 0.56, 0.92, scene_alpha)
        love.graphics.line(cx + size * 0.16, cy - size * 0.48, cx + size * 0.58, cy - size * 0.06)
        love.graphics.line(cx + size * 0.16, cy - size * 0.06, cx + size * 0.58, cy - size * 0.48)
    else
        set_color(0.44, 0.31, 0.17, 0.90, scene_alpha)
        love.graphics.arc("line", "open", cx + size * 0.10, cy, size * 0.34, -0.75, 0.75)
        love.graphics.arc("line", "open", cx + size * 0.10, cy, size * 0.52, -0.75, 0.75)
    end
    love.graphics.setLineWidth(1)
end

local function find_hovered_item(layout, x, y)
    for i, item in ipairs(menu_items) do
        local rect = get_item_rect(layout, i)
        if point_in_rect(x, y, rect) then
            return item.enabled and i or nil
        end
    end
    return nil
end

function MainMenu:enter()
    selected = nil
    hovered = nil
    hovered_mute = false
    mouse_has_moved = false
    modal_message = nil
    modal_timer = 0
    menu_clock = 0
    transition_clock = 0
    pending_action = nil
    cached_layout = nil
    music_play_attempted = false

    if not menu_bg and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(MENU_BG_PATH) then
        pcall(function() menu_bg = love.graphics.newImage(MENU_BG_PATH) end)
    end

    ensure_fonts()
    refresh_menu_labels()
    detect_continue_state()
    sync_mute_state()
    ensure_music()
    reset_particles()
end

function MainMenu:exit()
end

function MainMenu:update(dt)
    menu_clock = menu_clock + dt
    update_particles(dt)

    if music and not music:isPlaying() and not music_play_attempted then
        music_play_attempted = true
        pcall(function() music:play() end)
    end
    AudioManager.refresh_music()

    if modal_timer > 0 then
        modal_timer = modal_timer - dt
        if modal_timer <= 0 then
            modal_timer = 0
            modal_message = nil
        end
    end

    if pending_action then
        transition_clock = transition_clock + dt
        if transition_clock >= TRANSITION_SWITCH_DELAY then
            local action_fn = pending_action
            pending_action = nil
            transition_clock = 0
            action_fn()
        end
    end
end

function MainMenu:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    ensure_fonts(h)
    local high_contrast = RuntimeUI.high_contrast()
    local scene_alpha = get_scene_alpha()

    if love.graphics.setScissor then
        love.graphics.setScissor()
    end
    cached_layout = compute_layout(w, h)

    if menu_bg then
        local bg_x, bg_y, scale = get_background_rect(w, h)
        set_color(1, 1, 1, 1, scene_alpha)
        love.graphics.draw(menu_bg, bg_x, bg_y, 0, scale, scale)
    else
        set_color(0.05, 0.04, 0.03, 1, scene_alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    MenuSurface.backdrop(w,h,high_contrast,scene_alpha)
    MenuSurface.panel(cached_layout.frame,{high_contrast=high_contrast,alpha=scene_alpha})

    MenuParticles.draw(particles, w, h, RuntimeUI.scale(), high_contrast, scene_alpha)

    local title_p = ease_out_cubic(get_entrance_progress(0.10, 0.80))
    local title_x = cached_layout.panel_x
    local title_y = cached_layout.title_y + RuntimeUI.sized(20) * (1 - title_p)
    local title_label = tr_entry(BRANDING_TITLE_ENTRY)
    local title_font = pick_font_for_text(title_label, fonts.title, fonts.title_upper) or love.graphics.getFont()
    love.graphics.setFont(title_font)
    set_color(0.30, 0.17, 0.08, title_p, scene_alpha)
    love.graphics.print(title_label, title_x, title_y)

    local subtitle_label = get_subtitle_label()
    local subtitle_font = pick_font_for_text(subtitle_label, fonts.subtitle, fonts.subtitle_upper) or love.graphics.getFont()
    local subtitle_y = cached_layout.subtitle_y + RuntimeUI.sized(18) * (1 - title_p)
    local title_w = title_font:getWidth(title_label)
    local subtitle_w = subtitle_font:getWidth(subtitle_label)
    local subtitle_x = title_x + (title_w - subtitle_w) * 0.5
    love.graphics.setFont(subtitle_font)
    set_color(0.42, 0.28, 0.15, title_p * 0.88, scene_alpha)
    love.graphics.print(subtitle_label, subtitle_x, subtitle_y)

    for i, item in ipairs(menu_items) do
        local rect, item_p = get_item_rect(cached_layout, i)
        local hovered_item = mouse_has_moved and hovered == i
        local selected_item = selected == i

        MenuSurface.item(rect,{active=hovered_item or selected_item,
            primary=item.primary,disabled=not item.enabled,
            alpha=item_p*scene_alpha})

        local font = pick_font_for_text(
            item.label,
            item.primary and fonts.primary or fonts.secondary,
            item.primary and fonts.primary_upper or fonts.secondary_upper
        ) or love.graphics.getFont()
        love.graphics.setFont(font or love.graphics.getFont())
        local th = (font and font:getHeight()) or love.graphics.getFont():getHeight()
        local tx = rect.x + RuntimeUI.sized(12)
        local ty = rect.y + (rect.h - th) * 0.5

        if not item.enabled then
            set_color(.49,.43,.34,.75*item_p,scene_alpha)
        elseif selected_item or hovered_item then
            set_color(.30,.18,.07,item_p,scene_alpha)
        elseif item.primary then
            set_color(.25,.15,.09,.97*item_p,scene_alpha)
        else
            set_color(.38,.26,.15,.92*item_p,scene_alpha)
        end
        love.graphics.print(item.label, tx, ty)
    end

    local divider_p = ease_out_cubic(get_entrance_progress(0.24, 0.50))
    local dy = cached_layout.divider_y + RuntimeUI.sized(12) * (1 - divider_p)
    local dx = cached_layout.menu_x
    local dw = cached_layout.menu_w
    local cx = dx + dw * 0.5
    MenuSurface.rule(dx+RuntimeUI.sized(12),dy,dw-RuntimeUI.sized(24),
        divider_p*scene_alpha)

    local footer_p = ease_out_cubic(get_entrance_progress(0.70, 0.60))
    local footer_version_label = get_footer_version_label()
    local footer_alpha_label = get_footer_alpha_label()
    local footer_version_font = pick_font_for_text(footer_version_label, fonts.footer, fonts.footer_upper) or love.graphics.getFont()
    local footer_alpha_font = pick_font_for_text(footer_alpha_label, fonts.footer, fonts.footer_upper) or love.graphics.getFont()
    local fy = cached_layout.footer_y + RuntimeUI.sized(2)
    local footer_sep_gap = RuntimeUI.sized(8)
    local version_w = footer_version_font:getWidth(footer_version_label)
    local divider_x = cached_layout.menu_x + version_w + footer_sep_gap
    local alpha_x = divider_x + footer_sep_gap + 1

    love.graphics.setFont(footer_version_font)
    set_color(0.38, 0.27, 0.17, 0.88 * footer_p, scene_alpha)
    love.graphics.print(footer_version_label, cached_layout.menu_x, fy)
    set_color(0.46, 0.34, 0.21, 0.5 * footer_p, scene_alpha)
    love.graphics.rectangle("fill", divider_x, fy + RuntimeUI.sized(1), 1, RuntimeUI.sized(12))
    love.graphics.setFont(footer_alpha_font)
    set_color(0.38, 0.27, 0.17, 0.88 * footer_p, scene_alpha)
    love.graphics.print(footer_alpha_label, alpha_x, fy)

    if hovered_mute then
        local r = cached_layout.mute_rect
        set_color(0.92, 0.78, 0.38, 0.08 * footer_p, scene_alpha)
        love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 3, 3)
    end
    draw_mute_icon(cached_layout.mute_rect, muted, scene_alpha * (hovered_mute and 0.85 or 0.60) * footer_p)

    if modal_message then
        local bw = math.min(RuntimeUI.sized(560), w - RuntimeUI.sized(80))
        local bh = RuntimeUI.sized(140)
        local mx = (w - bw) * 0.5
        local my = (h - bh) * 0.5
        set_color(0, 0, 0, high_contrast and 0.88 or 0.74, scene_alpha)
        love.graphics.rectangle("fill", mx, my, bw, bh, 8, 8)
        set_color(0.96, 0.90, 0.80, 0.96, scene_alpha)
        local modal_font = pick_font_for_text(modal_message, fonts.modal, fonts.modal_upper) or love.graphics.getFont()
        love.graphics.setFont(modal_font)
        love.graphics.printf(modal_message, mx + RuntimeUI.sized(18), my + RuntimeUI.sized(24), bw - RuntimeUI.sized(36), "center")
    end
end

function MainMenu:keypressed(_key)
end

function MainMenu:mousepressed(x, y, button)
    if button ~= CONFIRM_MOUSE_BUTTON or pending_action then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local layout = cached_layout or compute_layout(w, h)
    cached_layout = layout

    if point_in_rect(x, y, layout.mute_rect) then
        toggle_music_mute()
        AudioManager.play_ui(AUDIO_TOGGLE_SFX)
        return
    end

    local idx = find_hovered_item(layout, x, y)
    if not idx then return end
    selected = idx
    hovered = idx
    AudioManager.play_ui(AUDIO_CONFIRM_SFX)
    MainMenu:activate(idx)
end

function MainMenu:mousemoved(x, y, _dx, _dy)
    mouse_has_moved = true
    if pending_action then return end
    local prev_hovered = hovered
    local prev_mute = hovered_mute

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local layout = cached_layout or compute_layout(w, h)
    cached_layout = layout

    hovered = find_hovered_item(layout, x, y)
    hovered_mute = point_in_rect(x, y, layout.mute_rect)

    if hovered and hovered ~= prev_hovered and not RuntimeUI.reduced_animations() then
        AudioManager.play_ui(AUDIO_HOVER_SFX)
    elseif hovered_mute and not prev_mute and not RuntimeUI.reduced_animations() then
        AudioManager.play_ui(AUDIO_HOVER_SFX)
    end
end

function MainMenu:activate(idx)
    local item = menu_items[idx]
    if not item or not item.enabled then return end

    if item.id == "new-game" then
        queue_transition(begin_new_game)
    elseif item.id == "bot-duel" then
        queue_transition(begin_bot_duel)
    elseif item.id == "continue" then
        queue_transition(continue_game)
    elseif item.id == "settings" then
        Navigation.go(NAVIGATION_SETTINGS)
    elseif item.id == "wishlist" then
        if love.system and love.system.openURL then
            pcall(function() love.system.openURL(WISHLIST_URL) end)
        else
            modal_message = tr_entry(MODAL_WISHLIST_FALLBACK_ENTRY, {
                url = WISHLIST_URL,
            })
            modal_timer = 5
        end
    elseif item.id == "quit" then
        love.event.quit()
    end
end

return MainMenu
