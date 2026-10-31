
local Settings = {}
local SettingsState = require("src.core.settings_state")
local AudioManager = require("src.core.audio_manager")
local I18n = require("src.core.i18n")
local MenuParticles = require("src.core.menu_particles")
local Navigation = require("src.core.navigation")
local RuntimeUI = require("src.core.runtime_ui")
local MenuSurface = require("src.features.ui_v2.menu_surface")
local Schema = require("src.core.schema")
local SettingsSchema = require("src.data.settings_schema")
local SettingsUISchema = require("src.data.settings_ui_schema")

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
local UI_ASSET_SCHEMA = SettingsUISchema.assets or {}
local UI_COLOR_SCHEMA = SettingsUISchema.colors or {}
local UI_TEXT_SCHEMA = SettingsUISchema.text or {}
local UI_FLOW_SCHEMA = SettingsUISchema.flow or {}

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
local FONT_TEXT = expect_string(UI_ASSET_SCHEMA.font_text, "assets.font_text")
local FONT_UPPERCASE = expect_string(UI_ASSET_SCHEMA.font_uppercase, "assets.font_uppercase")
local FONT_FALLBACK = expect_string(UI_ASSET_SCHEMA.font_fallback, "assets.font_fallback")

local MENU_TITLE_GOLD = expect_color3(UI_COLOR_SCHEMA.title_gold, "colors.title_gold")
local MENU_TEXT_SECONDARY = expect_color3(UI_COLOR_SCHEMA.text_secondary, "colors.text_secondary")

local bg_image = nil
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
    particles = MenuParticles.create_default(34)
end

local function update_particles(dt)
    MenuParticles.update(particles, dt, RuntimeUI.reduced_animations())
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
    Navigation.go(EXIT_MODULE)
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

    if not bg_image and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(MENU_BG_PATH) then
        pcall(function()
            bg_image = love.graphics.newImage(MENU_BG_PATH)
        end)
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
    local title_text=tr_entry(TITLE_ENTRY)
    love.graphics.setColor(.29,.18,.09,1)
    love.graphics.printf(title_text,layout.frame.x+20,
        layout.title_y,layout.frame.w-40,'center')
    local subtitle=view_mode==VIEW_MODE_SECTIONS
      and tr_entry(SUBTITLE_SECTIONS_ENTRY) or get_active_tab().label
    love.graphics.setFont(subtitle_face)
    love.graphics.setColor(.44,.30,.17,1)
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
        love.graphics.setColor(active and .26 or .37,
            active and .16 or .25,.12,progress)
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
        g.setColor(.29,.18,.10,progress)
        g.print(row.control.label,row.label_rect.x,y)
        if row.control.type=='slider' then
            draw_slider_gems(row.slider_rect,row.control.value,
                active,progress)
        else
            local value=control_display_value(row.control)
            local val_y=row.value_rect.y+(row.value_rect.h-face_h)*.5
            g.setColor(.46,.31,.17,progress)
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
        g.setColor(.31,.20,.11,progress)
        g.printf(row.action.label,row.x+12,
            row.y+(row.h-action_h)*.5,row.w-24,'center')
    end
end

function Settings:enter()
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

function Settings:keypressed(_key)
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
