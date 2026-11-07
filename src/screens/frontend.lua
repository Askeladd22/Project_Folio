local Bundle = {}
Bundle.menu_surface = require('src.screens.folio_surface').menu_surface
Bundle.main_menu = (function()
local Typography = require('src.core.presentation').typography
local MainMenu = {}
local AudioManager = require("src.core.audio_manager")
local I18n = require('src.core.presentation').i18n
local MenuVisuals = require('src.core.presentation').menu_visuals
local Navigation = require("src.core.navigation")
local RuntimeUI = require('src.core.runtime_state').ui
local Version = require('src.core.presentation').version
local MenuSurface = Bundle.menu_surface
local Schema = require('src.core.config').schema
local SettingsState = require('src.core.runtime_state').settings
local MainMenuSchema = require('src.data.frontend_schema').menu
local Art = require('src.data.frontend_schema').palette

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
local ILLUSTRATED_BG_PATH = expect_string(ASSET_SCHEMA.illustrated_background_path, "assets.illustrated_background_path")
local MANUZIO_BG_PATH = expect_string(ASSET_SCHEMA.manuzio_background_path, "assets.manuzio_background_path")
local MENU_MUSIC_PATH = expect_string(ASSET_SCHEMA.music_path, "assets.music_path")
local FONT_TEXT = expect_string(ASSET_SCHEMA.font_text, "assets.font_text")
local FONT_UPPERCASE = expect_string(ASSET_SCHEMA.font_uppercase, "assets.font_uppercase")
local FONT_FALLBACK = expect_string(ASSET_SCHEMA.font_fallback, "assets.font_fallback")
local WISHLIST_URL = expect_string(LINKS_SCHEMA.wishlist_url, "links.wishlist_url")
local SUBTITLE_ENTRY = expect_entry(LABEL_SCHEMA.subtitle, "labels.subtitle")
local BRANDING_TITLE_ENTRY = expect_entry(LABEL_SCHEMA.branding_title, "labels.branding_title")
local MODAL_NO_SAVE_ENTRY = expect_entry(MODAL_SCHEMA.no_save, "modals.no_save")
local MODAL_WISHLIST_FALLBACK_ENTRY = expect_entry(MODAL_SCHEMA.wishlist_fallback, "modals.wishlist_fallback")
local CONFIRM_MOUSE_BUTTON = expect_number(FLOW_SCHEMA.confirm_mouse_button, "flow.confirm_mouse_button")
local AUDIO_TOGGLE_SFX = expect_string(FLOW_SCHEMA.audio_toggle, "flow.audio_toggle")
local AUDIO_CONFIRM_SFX = expect_string(FLOW_SCHEMA.audio_confirm, "flow.audio_confirm")
local AUDIO_HOVER_SFX = expect_string(FLOW_SCHEMA.audio_hover, "flow.audio_hover")
local NAVIGATION_NEW_GAME = expect_string(FLOW_SCHEMA.navigation_new_game, "flow.navigation_new_game")
local NAVIGATION_SETTINGS = expect_string(FLOW_SCHEMA.navigation_settings, "flow.navigation_settings")
local MUSIC_TRACK_ID = expect_string(FLOW_SCHEMA.music_track_id, "flow.music_track_id")
local MAIN_THEME_MIX_GAIN = expect_number(FLOW_SCHEMA.main_theme_mix_gain, "flow.main_theme_mix_gain")

local function tr(key, fallback, params)
    return I18n.t(key, fallback, params)
end

local function get_subtitle_label()
    return tr(SUBTITLE_ENTRY.key, SUBTITLE_ENTRY.default)
end

local function get_footer_version_label()
    return 'v' .. Version.current()
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
local menu_bg_path = nil
local function has_illustrated_background()
    return menu_bg_path == MANUZIO_BG_PATH or menu_bg_path == ILLUSTRATED_BG_PATH
end
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

local function set_art_color(role, alpha, scene_alpha)
    local c=Art.rgb(role)
    set_color(c[1],c[2],c[3],alpha,scene_alpha)
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
            local ok, f = pcall(function() return Typography.load(fname, size) end)
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
        -- Reconstructed Aldine Roman serves all headings and menu text;
        -- Cardo substitutes individual missing glyphs through LÖVE.
        title = RuntimeUI.sized((RuntimeUI.big_text() and 90 or 76) * res_scale),
        subtitle = RuntimeUI.sized((RuntimeUI.big_text() and 25 or 21) * res_scale),
        primary = RuntimeUI.sized((RuntimeUI.big_text() and 42 or 36) * res_scale),
        secondary = RuntimeUI.sized((RuntimeUI.big_text() and 35 or 29) * res_scale),
        footer = RuntimeUI.sized((RuntimeUI.big_text() and 22 or 18) * res_scale),
        modal = RuntimeUI.sized((RuntimeUI.big_text() and 30 or 25) * res_scale),
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
    fonts.subtitle = load_font({FONT_TEXT, FONT_FALLBACK}, sizes.subtitle)
    fonts.subtitle_upper = load_font({FONT_UPPERCASE, FONT_FALLBACK}, sizes.subtitle)
    fonts.primary = load_font({FONT_UPPERCASE, FONT_FALLBACK}, sizes.primary)
    fonts.primary_upper = load_font({FONT_UPPERCASE, FONT_FALLBACK}, sizes.primary)
    fonts.secondary = load_font({FONT_UPPERCASE, FONT_FALLBACK}, sizes.secondary)
    fonts.secondary_upper = load_font({FONT_UPPERCASE, FONT_FALLBACK}, sizes.secondary)
    -- Plain small print is easier to read than miniature blackletter.
    fonts.footer = load_font({FONT_TEXT, FONT_FALLBACK}, sizes.footer)
    fonts.footer_upper = fonts.footer
    fonts.modal = load_font({FONT_UPPERCASE, FONT_FALLBACK}, sizes.modal)
    fonts.modal_upper = fonts.modal
    fonts.sizes = sizes
end

local function get_audio_settings()
    local state = SettingsState.get()
    return state and state.audio or nil
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
    return MenuVisuals.cover_rect(menu_bg,window_w,window_h,
        has_illustrated_background())
end

local function reset_particles()
    particles = MenuVisuals.create_default(34)
end

local function update_particles(dt)
    MenuVisuals.update(particles, dt, RuntimeUI.reduced_animations())
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
        -- Register gain BEFORE playback: the main theme was originally
        -- started at full Music-slider level, overwhelming dice/UI SFX.
        -- This track-only attenuation leaves the user's sliders intact.
        pcall(function() music:setLooping(true) end)
        AudioManager.register_music_source(MUSIC_TRACK_ID, music, {
            volume_mul = MAIN_THEME_MIX_GAIN,
        })
        pcall(function()
            if not music:isPlaying() then music:play() end
        end)
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

local function continue_game()
    -- No Farkle resume format exists yet. Continue remains disabled.
end

local function compute_layout(w, h)
    ensure_fonts(h)
    local border = math.max(12, math.floor(h * .038))
    local left = math.max(border, math.floor(w * .045))
    local width_cap = RuntimeUI.sized(610) *
        (h > 1080 and math.min(1.2, h / 1080) or 1)
    local panel_w = math.min(math.floor(w * .45), math.floor(width_cap), w - left - border)
    if has_illustrated_background() then
        local safe=MenuVisuals.left_panel_limit(menu_bg,w,h,left)
        if safe then panel_w=math.min(panel_w,safe) end
    end
    local menu_x = left + math.max(21, math.floor(panel_w * .065))
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
        local emphasized = item.primary and item.enabled
        local face = pick_font_for_text(item.label,
            emphasized and fonts.primary or fonts.secondary,
            emphasized and fonts.primary_upper or fonts.secondary_upper)
        local nominal = emphasized and h * .059 or h * .049
        item_heights[i] = math.max(face:getHeight() + 8, math.floor(nominal))
        total_rows = total_rows + item_heights[i]
    end
    local title_gap = math.max(9, math.floor(h * .012))
    local header_gap = math.max(20, math.floor(h * .028))
    local divider_space = math.max(17, math.floor(h * .023))
    local footer_gap = math.max(21, math.floor(h * .035))
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
    -- Quiet colophon: canonical version on the left, sound toggle on
    -- the right. No duplicate "alpha"/development tag in the game UI.
    layout.mute_rect={
        x=menu_x+menu_w-34,
        y=layout.footer_y-4,w=32,h=28,
    }
    layout.frame={
        x=left, y=math.max(border,start_y-27), w=panel_w,
        h=math.min(h-border,start_y+content_h+28)-math.max(border,start_y-27)
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

local function draw_mute_icon(rect, is_muted, scene_alpha)
    if not rect then return end
    local cx = rect.x + rect.w * 0.5
    local cy = rect.y + rect.h * 0.5
    local size = rect.h * 0.65
    local line_w = math.max(1.0, RuntimeUI.scale() * 1.2)

    set_art_color('text_muted',0.92,scene_alpha)
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
        set_art_color('cinnabar',0.92,scene_alpha)
        love.graphics.line(cx + size * 0.16, cy - size * 0.48, cx + size * 0.58, cy - size * 0.06)
        love.graphics.line(cx + size * 0.16, cy - size * 0.06, cx + size * 0.58, cy - size * 0.48)
    else
        set_art_color('border',0.90,scene_alpha)
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

    if not menu_bg then
        -- Draw only background pixels here: logo, buttons and version are
        -- still rendered by LÖVE as independent interactive controls.
        menu_bg, menu_bg_path = MenuVisuals.load(MANUZIO_BG_PATH, ILLUSTRATED_BG_PATH, MENU_BG_PATH)
    end

    ensure_fonts()
    refresh_menu_labels()
    detect_continue_state()
    sync_mute_state()
    ensure_music()
    reset_particles()
end

function MainMenu:exit()
    -- maintitle.ogg belongs to the menu, not to the game's Farkle scene.
    -- Preserve playback position when returning via the menu, but never
    -- leave the theme running over grabbing, shaking or throwing dice.
    if music then
        pcall(function()
            if music:isPlaying() then music:pause() end
        end)
    end
    AudioManager.unregister_music_source(MUSIC_TRACK_ID)
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
        if has_illustrated_background() then
            -- Keep original illustration pigments; the legacy photo still
            -- receives its deliberate stone-coloured tint.
            set_color(1,1,1,1,scene_alpha)
        else
            set_art_color('stone',1,scene_alpha)
        end
        love.graphics.draw(menu_bg, bg_x, bg_y, 0, scale, scale)
    else
        set_art_color('ink',1,scene_alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    MenuSurface.backdrop(w,h,high_contrast,scene_alpha,{
        quiet=true,illustrated=has_illustrated_background()
    })
    MenuSurface.panel(cached_layout.frame,{high_contrast=high_contrast,alpha=scene_alpha,style="editorial"})

    -- Nearly imperceptible ambient dust; no floating fantasy sparkles.
    MenuVisuals.draw(particles, w, h, RuntimeUI.scale(), high_contrast, scene_alpha * .18)

    local title_p = ease_out_cubic(get_entrance_progress(0.10, 0.80))
    local title_x = cached_layout.menu_x
    local title_y = cached_layout.title_y + RuntimeUI.sized(20) * (1 - title_p)
    local title_label = tr_entry(BRANDING_TITLE_ENTRY)
    local title_font = pick_font_for_text(title_label, fonts.title, fonts.title_upper) or love.graphics.getFont()
    love.graphics.setFont(title_font)
    set_art_color('text',title_p,scene_alpha)
    local title_fit = math.min(1, cached_layout.menu_w /
        math.max(1, title_font:getWidth(title_label)))
    love.graphics.print(title_label, title_x, title_y, 0, title_fit, 1)

    local subtitle_label = get_subtitle_label()
    local subtitle_font = pick_font_for_text(subtitle_label, fonts.subtitle, fonts.subtitle_upper) or love.graphics.getFont()
    local subtitle_y = cached_layout.subtitle_y + RuntimeUI.sized(18) * (1 - title_p)
    -- A calm left-aligned subtitle reads like a colophon rather than a
    -- second ornamental masthead.
    local subtitle_x = cached_layout.menu_x + RuntimeUI.sized(2)
    love.graphics.setFont(subtitle_font)
    set_art_color('text_muted',title_p*0.90,scene_alpha)
    love.graphics.print(subtitle_label, subtitle_x, subtitle_y)

    for i, item in ipairs(menu_items) do
        local rect, item_p = get_item_rect(cached_layout, i)
        local hovered_item = mouse_has_moved and hovered == i
        local selected_item = selected == i

        MenuSurface.item(rect,{active=hovered_item or selected_item,
            primary=item.primary and item.enabled,disabled=not item.enabled,
            alpha=item_p*scene_alpha,style="editorial"})

        local emphasized = item.primary and item.enabled
        local font = pick_font_for_text(
            item.label,
            emphasized and fonts.primary or fonts.secondary,
            emphasized and fonts.primary_upper or fonts.secondary_upper
        ) or love.graphics.getFont()
        love.graphics.setFont(font or love.graphics.getFont())
        local th = (font and font:getHeight()) or love.graphics.getFont():getHeight()
        local tx = rect.x + RuntimeUI.sized(18)
        local ty = rect.y + (rect.h - th) * 0.5

        if not item.enabled then
            set_art_color('quiet',.68*item_p,scene_alpha)
        elseif selected_item or hovered_item then
            set_art_color('text',item_p,scene_alpha)
        elseif emphasized then
            set_art_color('text',.98*item_p,scene_alpha)
        else
            set_art_color('text_muted',.95*item_p,scene_alpha)
        end
        love.graphics.print(item.label, tx, ty)
    end

    local divider_p = ease_out_cubic(get_entrance_progress(0.24, 0.50))
    local dy = cached_layout.divider_y + RuntimeUI.sized(12) * (1 - divider_p)
    local dx = cached_layout.menu_x
    local dw = cached_layout.menu_w
    MenuSurface.rule(dx,dy,dw,divider_p*scene_alpha,{quiet=true})

    local footer_p = ease_out_cubic(get_entrance_progress(0.70, 0.60))
    local footer_version_label = get_footer_version_label()
    local footer_version_font = fonts.footer or love.graphics.getFont()
    local fy = cached_layout.footer_y + RuntimeUI.sized(2)
    love.graphics.setFont(footer_version_font)
    set_art_color('text_muted',0.88*footer_p,scene_alpha)
    love.graphics.print(footer_version_label, cached_layout.menu_x, fy)

    if hovered_mute then
        local r = cached_layout.mute_rect
        set_art_color('selection',0.16*footer_p,scene_alpha)
        love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 3, 3)
    end
    draw_mute_icon(cached_layout.mute_rect, muted, scene_alpha * (hovered_mute and 0.85 or 0.60) * footer_p)

    if modal_message then
        local bw = math.min(RuntimeUI.sized(560), w - RuntimeUI.sized(80))
        local bh = RuntimeUI.sized(140)
        local mx = (w - bw) * 0.5
        local my = (h - bh) * 0.5
        MenuSurface.panel({x=mx,y=my,w=bw,h=bh},
            {alpha=scene_alpha,high_contrast=high_contrast})
        set_art_color('text',.98,scene_alpha)
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
end)()
Bundle.campaign_select = (function()
local Typography = require('src.core.presentation').typography
local AudioManager = require("src.core.audio_manager")
local I18n = require('src.core.presentation').i18n
local MenuVisuals = require('src.core.presentation').menu_visuals
local Navigation = require("src.core.navigation")
local RuntimeUI = require('src.core.runtime_state').ui
local MenuSurface = Bundle.menu_surface
local Schema = require('src.core.config').schema
local CampaignSelectSchema = require('src.data.frontend_schema').campaign
local Campaigns = CampaignSelectSchema.campaigns or {}
local Art = require('src.data.frontend_schema').palette

local CampaignSelect = {}

local ASSET_SCHEMA = CampaignSelectSchema.assets or {}
local TEXT_SCHEMA = CampaignSelectSchema.text or {}
local FLOW_SCHEMA = CampaignSelectSchema.flow or {}

local expect_string = Schema.expect_string
local expect_number = Schema.expect_number
local expect_entry = Schema.expect_entry

local MENU_BG_PATH = expect_string(ASSET_SCHEMA.background_path, "assets.background_path")
local ILLUSTRATED_BG_PATH = expect_string(ASSET_SCHEMA.illustrated_background_path, "assets.illustrated_background_path")
local MANUZIO_BG_PATH = expect_string(ASSET_SCHEMA.manuzio_background_path, "assets.manuzio_background_path")
local FONT_TEXT = expect_string(ASSET_SCHEMA.font_text, "assets.font_text")
local FONT_UPPERCASE = expect_string(ASSET_SCHEMA.font_uppercase, "assets.font_uppercase")
local FONT_FALLBACK = expect_string(ASSET_SCHEMA.font_fallback, "assets.font_fallback")

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
local bg_image_path = nil
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
                    return Typography.load(path, size)
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

    if not bg_image then
        bg_image, bg_image_path = MenuVisuals.load(MANUZIO_BG_PATH, ILLUSTRATED_BG_PATH, MENU_BG_PATH)
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
    particles = MenuVisuals.create_default(34)
end

local function update_particles(dt)
    MenuVisuals.update(particles, dt, RuntimeUI.reduced_animations())
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
        local x,y,scale=MenuVisuals.cover_rect(bg_image,w,h,
            (bg_image_path == MANUZIO_BG_PATH or bg_image_path == ILLUSTRATED_BG_PATH))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bg_image,x,y,0,scale,scale)
    else
        love.graphics.setColor(Art.rgba("ink", 1))
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    MenuSurface.backdrop(w,h,high_contrast,1)
    MenuSurface.panel(layout.frame,{high_contrast=high_contrast})

    MenuVisuals.draw(particles, w, h, RuntimeUI.scale(), high_contrast)
end

local function draw_title(layout)
    local center_x = layout.center_x
    local high_contrast = RuntimeUI.high_contrast()
    local title_face = title_font or love.graphics.getFont()
    local subtitle_face = subtitle_font or love.graphics.getFont()

    love.graphics.setFont(title_face)
    local title_text=tr_entry(BRANDING_TITLE_ENTRY)
    love.graphics.setColor(Art.rgba("text",1))
    love.graphics.printf(title_text,center_x-layout.max_main_w*.5+20,
        layout.title_y,layout.max_main_w-40,"center")
    love.graphics.setFont(subtitle_face)
    love.graphics.setColor(Art.rgba("text_muted",1))
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
    for _, item in ipairs(Campaigns) do
        if item.id == campaign_id and item.implemented then
            Navigation.go(CAMPAIGN_MODULE, {new_run = true})
            return
        end
    end
end

function CampaignSelect:enter()
    AudioManager.play_ui("menu_open")
    ensure_assets()
    campaigns = Campaigns
    selected_index = nil
    hovered_id = nil
    layout_cache = nil
    view_clock = 0
    reset_particles()
end

function CampaignSelect:exit()
    AudioManager.play_ui("menu_close")
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
end)()
Bundle.settings = (function()
local Typography = require('src.core.presentation').typography

local Settings = {}
local SettingsState = require('src.core.runtime_state').settings
local AudioManager = require("src.core.audio_manager")
local I18n = require('src.core.presentation').i18n
local MenuVisuals = require('src.core.presentation').menu_visuals
local Navigation = require("src.core.navigation")
local RuntimeUI = require('src.core.runtime_state').ui
local MenuSurface = Bundle.menu_surface
local Schema = require('src.core.config').schema
local SettingsSchema = require('src.data.frontend_schema').settings
local Art = require('src.data.frontend_schema').palette

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

local tabs = deep_copy(SettingsSchema.tabs or {})
local content_actions = deep_copy(SettingsSchema.actions or {})
local UI_ASSET_SCHEMA = SettingsSchema.assets or {}
local UI_COLOR_SCHEMA = SettingsSchema.colors or {}
local UI_TEXT_SCHEMA = SettingsSchema.text or {}
local UI_FLOW_SCHEMA = SettingsSchema.flow or {}

local expect_string = Schema.expect_string
local expect_number = Schema.expect_number
local expect_entry = Schema.expect_entry
local expect_color3 = Schema.expect_color3

local TITLE_ENTRY = expect_entry(UI_TEXT_SCHEMA.branding_title, "text.branding_title")
local SUBTITLE_SECTIONS_ENTRY = expect_entry(UI_TEXT_SCHEMA.subtitle_sections, "text.subtitle_sections")
local ACTION_BACK_ENTRY = expect_entry(UI_TEXT_SCHEMA.action_back, "text.action_back")
local VALUE_YES_ENTRY = expect_entry(UI_TEXT_SCHEMA.value_yes, "text.value_yes")
local VALUE_NO_ENTRY = expect_entry(UI_TEXT_SCHEMA.value_no, "text.value_no")
local VIEW_MODE_SECTIONS = expect_string(UI_FLOW_SCHEMA.view_mode_sections, "flow.view_mode_sections")
local VIEW_MODE_CONTENT = expect_string(UI_FLOW_SCHEMA.view_mode_content, "flow.view_mode_content")
local CONFIRM_MOUSE_BUTTON = expect_number(UI_FLOW_SCHEMA.confirm_mouse_button, "flow.confirm_mouse_button")
local SLIDER_DRAG_MARGIN = expect_number(UI_FLOW_SCHEMA.slider_drag_margin, "flow.slider_drag_margin")
local AUDIO_TOGGLE_SFX = expect_string(UI_FLOW_SCHEMA.audio_toggle, "flow.audio_toggle")
local AUDIO_CONFIRM_SFX = expect_string(UI_FLOW_SCHEMA.audio_confirm, "flow.audio_confirm")
local AUDIO_BACK_SFX = expect_string(UI_FLOW_SCHEMA.audio_back, "flow.audio_back")
local AUDIO_HOVER_SFX = expect_string(UI_FLOW_SCHEMA.audio_hover, "flow.audio_hover")
local EXIT_MODULE = expect_string(UI_FLOW_SCHEMA.exit_module, "flow.exit_module")

local function tr(key, fallback, params)
    return I18n.t(key, fallback, params)
end

local function tr_entry(entry, params)
    if type(entry) ~= "table" then
        return ""
    end
    return tr(entry.key, entry.default, params)
end

local function refresh_localized_labels()
    for _, tab in ipairs(tabs) do
        tab.label = tr(tab.label_key, tab.default_label)
        for _, control in ipairs(tab.controls) do
            control.label = tr(control.label_key, control.default_label)
            if control.type == "choice" and type(control.options) == "table" then
                control.option_labels = control.option_labels or {}
                local keys = control.option_label_keys or {}
                local defaults = control.option_label_defaults or {}
                for i, option_value in ipairs(control.options) do
                    control.option_labels[i] = tr(keys[i], defaults[i] or tostring(option_value))
                end
            end
        end
    end
    for _, action in ipairs(content_actions) do
        action.label = tr(action.label_key, action.default_label)
    end
end

local MENU_BG_PATH = expect_string(UI_ASSET_SCHEMA.background_path, "assets.background_path")
local ILLUSTRATED_BG_PATH = expect_string(UI_ASSET_SCHEMA.illustrated_background_path, "assets.illustrated_background_path")
local MANUZIO_BG_PATH = expect_string(UI_ASSET_SCHEMA.manuzio_background_path, "assets.manuzio_background_path")
local FONT_TEXT = expect_string(UI_ASSET_SCHEMA.font_text, "assets.font_text")
local FONT_UPPERCASE = expect_string(UI_ASSET_SCHEMA.font_uppercase, "assets.font_uppercase")
local FONT_FALLBACK = expect_string(UI_ASSET_SCHEMA.font_fallback, "assets.font_fallback")

local MENU_TITLE_GOLD = expect_color3(UI_COLOR_SCHEMA.title_gold, "colors.title_gold")
local MENU_TEXT_SECONDARY = expect_color3(UI_COLOR_SCHEMA.text_secondary, "colors.text_secondary")

local bg_image = nil
local bg_image_path = nil
local title_font = nil
local subtitle_font = nil
local section_font = nil
local content_font = nil
local action_font = nil

local view_mode = VIEW_MODE_SECTIONS
local selected_tab = 1
local selected_content_index = 1
local hovered_id = nil
local layout_cache = nil
local cached_scale = nil
local view_anim_clock = 0
local particles = {}
local return_module = EXIT_MODULE

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

local function reset_particles()
    particles = MenuVisuals.create_default(34)
end

local function update_particles(dt)
    MenuVisuals.update(particles, dt, RuntimeUI.reduced_animations())
end

local function reset_view_animation()
    view_anim_clock = 0
end

local function get_entrance_progress(delay, duration)
    if RuntimeUI.reduced_animations() then
        return 1
    end
    return clamp01((view_anim_clock - delay) / math.max(0.001, duration))
end

local function point_in_rect(px, py, rect)
    return px >= rect.x and px <= rect.x + rect.w and py >= rect.y and py <= rect.y + rect.h
end

local function leave_to_main_menu()
    AudioManager.apply_audio_settings()
    Navigation.go(return_module)
end

local function load_font(candidates, size)
    if love.filesystem and love.filesystem.getInfo then
        for _, path in ipairs(candidates) do
            if love.filesystem.getInfo(path) then
                local ok, font = pcall(function()
                    return Typography.load(path, size)
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
    local height=love.graphics.getHeight()
    local scale=RuntimeUI.scale()*math.max(.64,math.min(1.18,height/1080))
      *(RuntimeUI.big_text() and 1.12 or 1)
    if cached_scale ~= scale then
        title_font = nil
        subtitle_font = nil
        section_font = nil
        content_font = nil
        action_font = nil
        cached_scale = scale
    end

    if not bg_image then
        bg_image, bg_image_path = MenuVisuals.load(MANUZIO_BG_PATH, ILLUSTRATED_BG_PATH, MENU_BG_PATH)
    end

    if not title_font then
        title_font = load_font({
            FONT_TEXT,
            FONT_UPPERCASE,
            FONT_FALLBACK,
        }, math.max(26,math.floor(94*scale+.5)))
    end

    if not subtitle_font then
        subtitle_font = load_font({
            FONT_TEXT,
            FONT_UPPERCASE,
            FONT_FALLBACK,
        }, math.max(18,math.floor(50*scale+.5)))
    end

    if not section_font then
        section_font = load_font({
            FONT_TEXT,
            FONT_UPPERCASE,
            FONT_FALLBACK,
        }, math.max(17,math.floor(40*scale+.5)))
    end

    if not content_font then
        content_font = load_font({
            FONT_TEXT,
            FONT_UPPERCASE,
            FONT_FALLBACK,
        }, math.max(15,math.floor(32*scale+.5)))
    end

    if not action_font then
        action_font = load_font({
            FONT_TEXT,
            FONT_UPPERCASE,
            FONT_FALLBACK,
        }, math.max(16,math.floor(38*scale+.5)))
    end
end

local function get_active_tab()
    return tabs[selected_tab]
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
    if #parts == 0 then return end
    local curr = tbl
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(curr[part]) ~= "table" then
            curr[part] = {}
        end
        curr = curr[part]
    end
    curr[parts[#parts]] = value
end

local function sync_controls_from_settings(state)
    for _, tab in ipairs(tabs) do
        for _, control in ipairs(tab.controls) do
            if control.setting then
                local raw = get_path_value(state, control.setting)
                if control.type == "slider" then
                    if type(raw) == "number" then
                        control.value = clamp(raw, 0, 1)
                    end
                elseif control.type == "toggle" then
                    if type(raw) == "boolean" then
                        control.value = raw
                    end
                elseif control.type == "choice" then
                    local idx = nil
                    if control.value_map then
                        for i, mapped in ipairs(control.value_map) do
                            if mapped == raw then
                                idx = i
                                break
                            end
                        end
                    else
                        local target = tostring(raw)
                        for i, option in ipairs(control.options) do
                            if option == target then
                                idx = i
                                break
                            end
                        end
                    end
                    if idx then
                        control.value_index = idx
                    end
                end
            end
        end
    end
end

local function build_settings_from_controls()
    local state = SettingsState.get()
    for _, tab in ipairs(tabs) do
        for _, control in ipairs(tab.controls) do
            if control.setting then
                local out_value = nil
                if control.type == "slider" then
                    out_value = clamp(control.value, 0, 1)
                elseif control.type == "toggle" then
                    out_value = control.value and true or false
                elseif control.type == "choice" then
                    if control.value_map then
                        out_value = control.value_map[control.value_index]
                    else
                        out_value = control.options[control.value_index]
                    end
                end
                if out_value ~= nil then
                    set_path_value(state, control.setting, out_value)
                end
            end
        end
    end
    return state
end

local function control_display_value(control)
    if control.type == "toggle" then
        return control.value
            and tr_entry(VALUE_YES_ENTRY)
            or tr_entry(VALUE_NO_ENTRY)
    end
    if control.type == "choice" then
        local labels = control.option_labels
        if type(labels) == "table" and labels[control.value_index] ~= nil then
            return tostring(labels[control.value_index])
        end
        return tostring(control.options[control.value_index])
    end
    if control.type == "slider" then
        return ""
    end
    return ""
end

local function adjust_control(control, dir)
    if control.type == "slider" then
        local step = control.step or 0.05
        control.value = clamp(control.value + (step * dir), 0, 1)
    elseif control.type == "toggle" then
        if dir == 0 then
            control.value = not control.value
        elseif dir > 0 then
            control.value = true
        else
            control.value = false
        end
    elseif control.type == "choice" then
        local count = #control.options
        if count > 0 then
            control.value_index = control.value_index + dir
            if control.value_index < 1 then control.value_index = count end
            if control.value_index > count then control.value_index = 1 end
        end
    end
end

local function is_audio_control(control)
    return control
        and type(control.setting) == "string"
        and control.setting:sub(1, 6) == "audio."
end

local function apply_live_audio_preview()
    if not AudioManager.apply_audio_settings then
        return
    end
    local preview_state = build_settings_from_controls()
    if preview_state and preview_state.audio then
        AudioManager.apply_audio_settings(preview_state.audio)
    end
end

local function reset_tab(tab)
    for _, control in ipairs(tab.controls) do
        if control.type == "slider" then
            control.value = control.default or 0
        elseif control.type == "toggle" then
            control.value = control.default and true or false
        elseif control.type == "choice" then
            control.value_index = control.default_index or 1
        end
    end
end

local function run_action(action)
    if action == "reset" then
        local active_tab = get_active_tab()
        reset_tab(active_tab)
        for _, control in ipairs(active_tab.controls) do
            if is_audio_control(control) then
                apply_live_audio_preview()
                break
            end
        end
        AudioManager.play_ui(AUDIO_TOGGLE_SFX)
    elseif action == "confirm" then
        local next_state = build_settings_from_controls()
        local applied_state = SettingsState.set(next_state)
        SettingsState.save()
        SettingsState.apply()
        refresh_localized_labels()
        if applied_state and applied_state.audio then
            AudioManager.apply_audio_settings(applied_state.audio)
        end
        sync_controls_from_settings(applied_state)
        AudioManager.play_ui(AUDIO_CONFIRM_SFX)
    elseif action == "back" then
        view_mode = VIEW_MODE_SECTIONS
        reset_view_animation()
        AudioManager.play_ui(AUDIO_BACK_SFX)
    end
end

local function set_slider_from_x(control, slider_rect, mouse_x)
    if not slider_rect or slider_rect.w <= 0 then return end
    local ratio = clamp((mouse_x - slider_rect.x) / slider_rect.w, 0, 1)
    local step = control.step or 0.05
    local steps = math.max(1, math.floor(1 / step + 0.5))
    local snapped = math.floor(ratio * steps + 0.5) / steps
    control.value = clamp(snapped, 0, 1)
end

local function build_layout()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local center_x = w * 0.5
    local max_main_w = math.min(980, w * 0.78)
    local base_row_h = math.max(52, math.floor(h * 0.053))
    local base_row_gap = math.max(8, math.floor(base_row_h * 0.22))

    local layout = {
        w = w,
        h = h,
        center_x = center_x,
        max_main_w = max_main_w,
        row_h = base_row_h,
        row_gap = base_row_gap,
        title_y = math.floor(h * 0.08),
        subtitle_y = math.floor(h * 0.31),
        section_items = {},
        controls = {},
        actions = {},
    }

    if view_mode == VIEW_MODE_SECTIONS then
        local entries = #tabs + 1
        local section_font_h = (section_font and section_font:getHeight()) or base_row_h
        local section_row_h = math.max(section_font_h + 8, math.floor(h * 0.060))
        local section_gap = math.max(14, math.floor(section_row_h * 0.30))
        local subtitle_h = (subtitle_font and subtitle_font:getHeight()) or math.floor(h * 0.05)
        local top_anchor = layout.subtitle_y + subtitle_h + 34
        local bottom_limit = h - math.floor(h * 0.16)
        local available = math.max(section_row_h, bottom_limit - top_anchor)
        local total_h = entries * section_row_h + (entries - 1) * section_gap
        if total_h > available and entries > 1 then
            local fitted_gap = math.floor((available - entries * section_row_h) / (entries - 1))
            section_gap = math.max(8, fitted_gap)
            total_h = entries * section_row_h + (entries - 1) * section_gap
            if total_h > available then
                section_row_h = math.max(section_font_h, math.floor((available - (entries - 1) * section_gap) / entries))
                total_h = entries * section_row_h + (entries - 1) * section_gap
            end
        end

        local start_y = top_anchor
        if total_h < available then
            start_y = top_anchor + math.floor((available - total_h) * 0.14)
        end

        local section_w = max_main_w * 0.92
        for i = 1, #tabs do
            local y = start_y + (i - 1) * (section_row_h + section_gap)
            layout.section_items[i] = {
                id = "section:" .. i,
                type = "tab",
                tab_index = i,
                label = tabs[i].label,
                x = center_x - section_w * 0.5,
                y = y,
                w = section_w,
                h = section_row_h,
            }
        end
        local back_y = start_y + (#tabs) * (section_row_h + section_gap)
        layout.section_items[#tabs + 1] = {
            id = "section:back",
            type = "back",
            label = tr_entry(ACTION_BACK_ENTRY),
            x = center_x - section_w * 0.5,
            y = back_y,
            w = section_w,
            h = section_row_h,
        }
    else
        local tab = get_active_tab()
        local subtitle_h = (subtitle_font and subtitle_font:getHeight()) or math.floor(h * 0.05)
        local content_font_h = (content_font and content_font:getHeight()) or base_row_h
        local action_font_h = (action_font and action_font:getHeight()) or base_row_h
        local top_anchor = layout.subtitle_y + subtitle_h + 20
        local bottom_limit = h - math.floor(h * 0.08)
        local available_h = math.max(120, bottom_limit - top_anchor)
        local controls_count = #tab.controls
        local actions_count = #content_actions

        local row_h = math.max(base_row_h, content_font_h + 4)
        local row_gap = math.max(6, math.floor(content_font_h * 0.16))
        local action_h = math.max(action_font_h + 4, math.floor(row_h * 1.02))
        local action_gap = math.max(4, math.floor(action_h * 0.10))
        local block_gap = math.max(12, math.floor(row_h * 0.24))

        local function total_height()
            local controls_h = controls_count > 0 and (controls_count * row_h + (controls_count - 1) * row_gap) or 0
            local actions_h = actions_count > 0 and (actions_count * action_h + (actions_count - 1) * action_gap) or 0
            local middle_h = (controls_h > 0 and actions_h > 0) and block_gap or 0
            return controls_h + middle_h + actions_h, controls_h, actions_h, middle_h
        end

        local total_h, controls_h, _, middle_h = total_height()
        while total_h > available_h and (row_gap > 4 or action_gap > 2 or block_gap > 8) do
            if row_gap >= action_gap and row_gap > 4 then
                row_gap = row_gap - 1
            elseif action_gap > 2 then
                action_gap = action_gap - 1
            elseif block_gap > 8 then
                block_gap = block_gap - 1
            end
            total_h, controls_h, _, middle_h = total_height()
        end

        local min_row_h = math.max(content_font_h + 2, math.floor(base_row_h * 0.74))
        while total_h > available_h and row_h > min_row_h do
            row_h = row_h - 1
            total_h, controls_h, _, middle_h = total_height()
        end

        local controls_top = top_anchor
        if total_h < available_h then
            controls_top = top_anchor + math.floor((available_h - total_h) * 0.14)
        end

        local row_w = max_main_w * 0.92
        local control_label_w = row_w * 0.62
        local control_value_w = row_w * 0.34

        for i, control in ipairs(tab.controls) do
            local y = controls_top + (i - 1) * (row_h + row_gap)
            local x = center_x - row_w * 0.5
            layout.controls[i] = {
                id = "control:" .. i,
                index = i,
                control = control,
                x = x,
                y = y,
                w = row_w,
                h = row_h,
                label_rect = {x = x + 12, y = y, w = control_label_w, h = row_h},
                value_rect = {x = x + row_w - control_value_w - 10, y = y, w = control_value_w, h = row_h},
            }

            if control.type == "slider" then
                layout.controls[i].slider_rect = {
                    x = x + row_w - control_value_w - 8,
                    y = y + math.floor(row_h * 0.24),
                    w = control_value_w - 8,
                    h = math.floor(row_h * 0.52),
                }
            end
        end

        local actions_top = controls_top + controls_h + middle_h
        local action_w = max_main_w * 0.56
        for i, action in ipairs(content_actions) do
            local y = actions_top + (i - 1) * (action_h + action_gap)
            layout.actions[i] = {
                id = "action:" .. i,
                index = i,
                action = action,
                x = center_x - action_w * 0.5,
                y = y,
                w = action_w,
                h = action_h,
            }
        end
    end

    local frame_top=math.max(14,layout.title_y-math.max(24,math.floor(h*.035)))
    local last_y=layout.subtitle_y+math.floor(h*.09)
    if view_mode==VIEW_MODE_SECTIONS then
        local item=layout.section_items[#layout.section_items]
        if item then last_y=item.y+item.h end
    else
        local item=layout.actions[#layout.actions]
        if item then last_y=item.y+item.h end
    end
    local frame_bottom=math.min(h-14,last_y+math.max(24,math.floor(h*.045)))
    layout.frame={
        x=center_x-math.min(w*.83,1160)*.5,
        y=frame_top,w=math.min(w*.83,1160),
        h=math.max(50,frame_bottom-frame_top),
    }
    return layout
end

local function draw_background(layout)
    local w, h = layout.w, layout.h
    local high_contrast = RuntimeUI.high_contrast()

    if bg_image then
        local x,y,scale=MenuVisuals.cover_rect(bg_image,w,h,
            (bg_image_path == MANUZIO_BG_PATH or bg_image_path == ILLUSTRATED_BG_PATH))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bg_image,x,y,0,scale,scale)
    else
        love.graphics.setColor(Art.rgba("ink", 1))
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    MenuSurface.backdrop(w,h,high_contrast,1)
    MenuSurface.panel(layout.frame,{high_contrast=high_contrast})

    MenuVisuals.draw(particles, w, h, RuntimeUI.scale(), high_contrast)
end

local function draw_title(layout)
    local center_x = layout.center_x
    local high_contrast = RuntimeUI.high_contrast()
    local title_face = title_font or love.graphics.getFont()
    local subtitle_face = subtitle_font or love.graphics.getFont()

    love.graphics.setFont(title_face)
    local title_text=tr_entry(TITLE_ENTRY)
    love.graphics.setColor(Art.rgba('text',1))
    love.graphics.printf(title_text,layout.frame.x+20,
        layout.title_y,layout.frame.w-40,'center')
    local subtitle=view_mode==VIEW_MODE_SECTIONS
      and tr_entry(SUBTITLE_SECTIONS_ENTRY) or get_active_tab().label
    love.graphics.setFont(subtitle_face)
    love.graphics.setColor(Art.rgba('text_muted',1))
    love.graphics.printf(subtitle,layout.frame.x+24,
        layout.subtitle_y,layout.frame.w-48,'center')
    MenuSurface.rule(center_x-165,
        layout.subtitle_y+subtitle_face:getHeight()+8,330,1)
end

local function draw_slider_gems(rect, value, selected, alpha_mul)
    alpha_mul = alpha_mul or 1
    local count = 10
    local filled = math.floor(value * count + 0.5)
    local gap = math.max(3, math.floor(rect.w * 0.020))
    local gem_w = math.max(8, math.floor((rect.w - (count - 1) * gap) / count))
    local gem_h = math.max(8, math.floor(rect.h * 0.74))
    local total_w = count * gem_w + (count - 1) * gap
    local start_x = rect.x + math.max(0, (rect.w - total_w) * 0.5)
    local mid_y = rect.y + rect.h * 0.5

    for i = 1, count do
        local x = start_x + (i - 1) * (gem_w + gap)
        local lit = i <= filled
        if lit then
            love.graphics.setColor(MENU_TITLE_GOLD[1], MENU_TITLE_GOLD[2], MENU_TITLE_GOLD[3], (selected and 1.0 or 0.9) * alpha_mul)
        else
            love.graphics.setColor(MENU_TEXT_SECONDARY[1], MENU_TEXT_SECONDARY[2], MENU_TEXT_SECONDARY[3], (selected and 0.9 or 0.75) * alpha_mul)
        end
        love.graphics.polygon("fill",
            x + gem_w * 0.5, mid_y - gem_h * 0.5,
            x + gem_w, mid_y,
            x + gem_w * 0.5, mid_y + gem_h * 0.5,
            x, mid_y
        )
    end
end

local function draw_sections(layout)
    local face=section_font or love.graphics.getFont()
    local height=face:getHeight()
    love.graphics.setFont(face)
    for i,item in ipairs(layout.section_items) do
        local progress=ease_out_cubic(get_entrance_progress(
            .14+(i-1)*.08,.55))
        local active=hovered_id==item.id
        MenuSurface.item(item,{active=active,alpha=progress,
            primary=item.type=='tab'})
        local y=item.y+(item.h-height)*.5
        love.graphics.setColor(Art.rgba(active and 'text' or 'text_muted',progress))
        love.graphics.printf(item.label,item.x+14,y,
            item.w-28,'center')
    end
end
local function draw_content(layout)
    local g=love.graphics
    local face=content_font or g.getFont()
    local face_h=face:getHeight()
    for i,row in ipairs(layout.controls) do
        local progress=ease_out_cubic(get_entrance_progress(
            .16+(i-1)*.06,.52))
        local active=selected_content_index==i or hovered_id==row.id
        MenuSurface.item(row,{active=active,alpha=progress})
        local y=row.label_rect.y+(row.label_rect.h-face_h)*.5
        g.setFont(face)
        g.setColor(Art.rgba('text',progress))
        g.print(row.control.label,row.label_rect.x,y)
        if row.control.type=='slider' then
            draw_slider_gems(row.slider_rect,row.control.value,
                active,progress)
        else
            local value=control_display_value(row.control)
            local val_y=row.value_rect.y+(row.value_rect.h-face_h)*.5
            g.setColor(Art.rgba('text_muted',progress))
            g.printf(value,row.value_rect.x,val_y,
                row.value_rect.w,'center')
        end
    end
    local action_face=action_font or g.getFont()
    local action_h=action_face:getHeight()
    for i,row in ipairs(layout.actions) do
        local progress=ease_out_cubic(get_entrance_progress(
            .18+#layout.controls*.05+(i-1)*.07,.52))
        local selected=selected_content_index==#layout.controls+i
        local active=selected or hovered_id==row.id
        MenuSurface.item(row,{active=active,alpha=progress,
            primary=row.action.action=='confirm'})
        g.setFont(action_face)
        g.setColor(Art.rgba('text',progress))
        g.printf(row.action.label,row.x+12,
            row.y+(row.h-action_h)*.5,row.w-24,'center')
    end
end

function Settings:enter(params)
    AudioManager.play_ui("menu_open")
    -- Return to the same active Farkle run after editing settings.
    return_module = params and params.return_to == 'scriptorium'
      and 'scriptorium' or EXIT_MODULE
    ensure_assets()
    refresh_localized_labels()
    local loaded = SettingsState.get()
    sync_controls_from_settings(loaded)
    if loaded and loaded.audio then
        AudioManager.apply_audio_settings(loaded.audio)
    end
    view_mode = VIEW_MODE_SECTIONS
    selected_content_index = 1
    hovered_id = nil
    layout_cache = nil
    reset_particles()
    reset_view_animation()
end

function Settings:exit()
    AudioManager.play_ui("menu_close")
end

function Settings:update(dt)
    view_anim_clock = view_anim_clock + (dt or 0)
    update_particles(dt or 0)
end

function Settings:draw()
    ensure_assets()
    layout_cache = build_layout()
    local layout = layout_cache

    draw_background(layout)
    draw_title(layout)

    if view_mode == VIEW_MODE_SECTIONS then
        draw_sections(layout)
    else
        draw_content(layout)
    end
end

function Settings:keypressed(key)
    if key ~= 'escape' then return end
    if view_mode == VIEW_MODE_CONTENT then
        view_mode = VIEW_MODE_SECTIONS
        reset_view_animation()
        AudioManager.play_ui("menu_close")
    else
        leave_to_main_menu()
    end
    AudioManager.play_ui(AUDIO_BACK_SFX)
end

function Settings:mousepressed(x, y, button)
    if button ~= CONFIRM_MOUSE_BUTTON then return end

    local layout = build_layout()
    layout_cache = layout

    if view_mode == VIEW_MODE_SECTIONS then
        for i, item in ipairs(layout.section_items) do
            if point_in_rect(x, y, item) then
                if item.type == "tab" then
                    selected_tab = item.tab_index
                    view_mode = VIEW_MODE_CONTENT
                    selected_content_index = 1
                    reset_view_animation()
                    AudioManager.play_ui("menu_open")
                    AudioManager.play_ui(AUDIO_CONFIRM_SFX)
                else
                    AudioManager.play_ui(AUDIO_BACK_SFX)
                    leave_to_main_menu()
                end
                return
            end
        end
        return
    end

    local tab = get_active_tab()

    for i, row in ipairs(layout.controls) do
        if point_in_rect(x, y, row) then
            selected_content_index = i
            local control = tab.controls[i]
            if control.type == "toggle" then
                adjust_control(control, 0)
                if is_audio_control(control) then
                    apply_live_audio_preview()
                end
                AudioManager.play_ui(AUDIO_TOGGLE_SFX)
            elseif control.type == "choice" then
                adjust_control(control, 1)
                if is_audio_control(control) then
                    apply_live_audio_preview()
                end
                AudioManager.play_ui(AUDIO_TOGGLE_SFX)
            elseif control.type == "slider" then
                set_slider_from_x(control, row.slider_rect, x)
                if is_audio_control(control) then
                    apply_live_audio_preview()
                end
                AudioManager.play_ui(AUDIO_TOGGLE_SFX)
            end
            return
        end
    end

    for i, row in ipairs(layout.actions) do
        if point_in_rect(x, y, row) then
            selected_content_index = #tab.controls + i
            run_action(row.action.action)
            return
        end
    end
end

function Settings:mousemoved(x, y, dx, dy, istouch)
    local layout = layout_cache or build_layout()
    local previous_hover = hovered_id
    hovered_id = nil

    if view_mode == VIEW_MODE_SECTIONS then
        for _, item in ipairs(layout.section_items) do
            if point_in_rect(x, y, item) then
                hovered_id = item.id
                break
            end
        end
        if hovered_id and previous_hover ~= hovered_id and not RuntimeUI.reduced_animations() then
            AudioManager.play_ui(AUDIO_HOVER_SFX)
        end
        return
    end

    local tab = get_active_tab()

    for _, row in ipairs(layout.controls) do
        if point_in_rect(x, y, row) then
            hovered_id = row.id
            break
        end
    end

    if not hovered_id then
        for _, row in ipairs(layout.actions) do
            if point_in_rect(x, y, row) then
                hovered_id = row.id
                break
            end
        end
    end

    if hovered_id and previous_hover ~= hovered_id and not RuntimeUI.reduced_animations() then
        AudioManager.play_ui(AUDIO_HOVER_SFX)
    end

    if love.mouse and love.mouse.isDown and love.mouse.isDown(CONFIRM_MOUSE_BUTTON) and selected_content_index <= #tab.controls then
        local control = tab.controls[selected_content_index]
        local row = layout.controls[selected_content_index]
        if control and control.type == "slider" and row and row.slider_rect then
            if y >= row.slider_rect.y - SLIDER_DRAG_MARGIN and y <= row.slider_rect.y + row.slider_rect.h + SLIDER_DRAG_MARGIN then
                set_slider_from_x(control, row.slider_rect, x)
                if is_audio_control(control) then
                    apply_live_audio_preview()
                end
            end
        end
    end
end

return Settings
end)()
Bundle.modules = {
    main_menu = Bundle.main_menu,
    campaign_select = Bundle.campaign_select,
    settings = Bundle.settings,
}
return Bundle
