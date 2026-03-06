
local Run = require("src.gameplay.run.run")
local Logger = require("src.core.logger")
local RuntimeUI = require("src.core.runtime_ui")
local ResolutionManager = require("src.core.resolution_manager")
local EngineBridge = require("src.core.engine_bridge")
local I18n = require("src.core.i18n")
local Json = require("src.core.json")
local SaveState = require("src.core.save_state")
local Schema = require("src.core.schema")
local Colors = require("src.data.colors")
local ScriptoriumUISchema = require("src.data.scriptorium_ui_schema")
local ScriptoriumLayoutData = require("src.data.scriptorium_layout")
local ScriptoriumModuleConfig = require("src.data.scriptorium_module_config")
local Helpers = require("src.features.scriptorium.helpers")
local ScriptoriumActions = require("src.features.scriptorium.actions")
local ScriptoriumHud = require("src.features.scriptorium.hud")
local ScriptoriumOverlays = require("src.features.scriptorium.overlays")

local Scriptorium = {
    run = nil,
    dice_results = {},
    turn_palette = nil,
    palette_picker = nil,
    state = "waiting",
    message = nil,
    message_timer = 0,
    selected_cell = nil,
    selected_die = nil,
    ui_hit = {},
    lock_badges = {},
    mouse_x = 0,
    mouse_y = 0,
    hovered_lock = nil,
    view_mode = "overview",
    zoom_element = nil,
    show_run_setup = false,
    show_system_menu = false,
    setup_guided_rows = nil,
    setup_initial_row = nil,
    pending_stain_choices = nil,
    pending_stain_total = nil,
    pending_stain_remaining = nil,
    pending_ink_recovery = nil,
    pending_ink_recovery_rows = nil,
    pending_row_swap = nil,
    ruling_actions_left = 0,
    value_to_color = nil,
    current_focus = nil,
    hover_constraint_color = nil,
    show_folio_result = false,
    folio_result = nil,
    show_ruling_overlay = false,
    row_ruling_animations = {},
}

local expect_table = Schema.expect_table
local expect_string = Schema.expect_string
local expect_number = Schema.expect_number
local expect_boolean = Schema.expect_boolean

local FONT_CONFIG = expect_table(ScriptoriumModuleConfig.fonts, "ScriptoriumModuleConfig.fonts")
local REFERENCE_RESOLUTION = expect_table(ScriptoriumModuleConfig.reference_resolution, "ScriptoriumModuleConfig.reference_resolution")
local WORKSPACE_STYLE = expect_table(ScriptoriumModuleConfig.workspace, "ScriptoriumModuleConfig.workspace")
local ZOOM_HEADER_LAYOUT = expect_table(ScriptoriumLayoutData.zoom_header, "ScriptoriumLayoutData.zoom_header")
local HINT_BAR_LAYOUT = expect_table(ScriptoriumLayoutData.hint_bar, "ScriptoriumLayoutData.hint_bar")
local LEGEND_PANEL_LAYOUT = expect_table(ScriptoriumLayoutData.legend_panel, "ScriptoriumLayoutData.legend_panel")
local HUD_LAYOUT = expect_table(ScriptoriumLayoutData.hud, "ScriptoriumLayoutData.hud")
local OVERLAYS_LAYOUT = expect_table(ScriptoriumLayoutData.overlays, "ScriptoriumLayoutData.overlays")
local LOCK_BADGE_LAYOUT = expect_table(ScriptoriumLayoutData.lock_badge, "ScriptoriumLayoutData.lock_badge")
local GRID_PANEL_LAYOUT = expect_table(ScriptoriumLayoutData.overview_grid_panel, "ScriptoriumLayoutData.overview_grid_panel")
local OVERVIEW_CARD_LAYOUT = expect_table(ScriptoriumLayoutData.overview_card, "ScriptoriumLayoutData.overview_card")
local UNIFIED_OVERVIEW_LAYOUT = expect_table(ScriptoriumLayoutData.unified_overview, "ScriptoriumLayoutData.unified_overview")
local TILE_CELL_LAYOUT = expect_table(ScriptoriumLayoutData.tile_cell, "ScriptoriumLayoutData.tile_cell")
local ZONE_GRID_LAYOUT = expect_table(ScriptoriumLayoutData.zone_grid, "ScriptoriumLayoutData.zone_grid")

local BG_PATH = expect_string(ScriptoriumModuleConfig.background_path, "ScriptoriumModuleConfig.background_path")
local PROTOTYPE_NO_BACKGROUND = expect_boolean(ScriptoriumModuleConfig.prototype_no_background, "ScriptoriumModuleConfig.prototype_no_background")
local DECORATIVE_FONT_CANDIDATES = expect_table(FONT_CONFIG.decorative_candidates, "ScriptoriumModuleConfig.fonts.decorative_candidates")
local BODY_FONT_CANDIDATES = expect_table(FONT_CONFIG.body_candidates, "ScriptoriumModuleConfig.fonts.body_candidates")
local MICRO_FONT_CANDIDATES = expect_table(FONT_CONFIG.micro_candidates, "ScriptoriumModuleConfig.fonts.micro_candidates")
local MIN_UI_FONT_SIZE = expect_number(FONT_CONFIG.min_ui_size, "ScriptoriumModuleConfig.fonts.min_ui_size")
local MIN_UI_FONT_SIZE_BIG_TEXT = expect_number(FONT_CONFIG.min_size_big_text, "ScriptoriumModuleConfig.fonts.min_size_big_text")
local DECORATIVE_MIN_SIZE = expect_number(FONT_CONFIG.decorative_min_size, "ScriptoriumModuleConfig.fonts.decorative_min_size")
local MICRO_MAX_SIZE = expect_number(FONT_CONFIG.micro_max_size, "ScriptoriumModuleConfig.fonts.micro_max_size")

local REF_W = expect_number(REFERENCE_RESOLUTION.width, "ScriptoriumModuleConfig.reference_resolution.width")
local REF_H = expect_number(REFERENCE_RESOLUTION.height, "ScriptoriumModuleConfig.reference_resolution.height")

local function tr(entry, params)
    if type(entry) ~= "table" then
        return ""
    end
    return I18n.t(entry.key, entry.default, params)
end

Run.configure({
    translate = function(key, fallback, params)
        return I18n.t(key, fallback, params)
    end,
    get_language = I18n.get_language,
    json_decode = Json.decode,
    log_debug = Logger.debug,
})

local MODULE_UI = ScriptoriumUISchema.module or {}

local function get_constraint_lines()
    local entries = MODULE_UI.constraint_lines or {}
    local lines = {}
    for i, entry in ipairs(entries) do
        lines[i] = tr(entry)
    end
    return lines
end

local function get_row_rule_label(rule_type)
    if type(rule_type) ~= "string" then
        return nil
    end
    local labels = MODULE_UI.row_rule_labels or {}
    local entry = labels[rule_type]
    if not entry then
        return nil
    end
    return tr(entry)
end

local VALUE_TO_COLOR = Colors.value_to_color
local COLOR_TO_VALUE = Colors.color_to_value
local COLOR_SWATCH = Colors.swatch

Scriptorium.value_to_color = VALUE_TO_COLOR

local clamp = Helpers.clamp
local point_in_rect = Helpers.point_in_rect
local project_rect = Helpers.project_rect
local get_panels_bounds = Helpers.get_panels_bounds
local get_section_progress = Helpers.get_section_progress
local find_panel_by_element = Helpers.find_panel_by_element
local get_unlock_tooltip = Helpers.get_unlock_tooltip
local draw_text_center = Helpers.draw_text_center
local get_remaining_dice_count = Helpers.get_remaining_dice_count
local get_unusable_dice_count = Helpers.get_unusable_dice_count

local layout_methods
local hud_methods
local overlay_methods

local bg_img = nil
local font_cache = {}

local function ui_dimensions()
    return ResolutionManager.get_virtual_size()
end

local function new_layout_methods(deps)
    local RuntimeUIDeps = deps.RuntimeUI
    local ResolutionManagerDeps = deps.ResolutionManager
    local ui_dimensions_fn = deps.ui_dimensions
    local clamp_fn = deps.clamp
    local find_panel_by_element_fn = deps.find_panel_by_element
    local controls = expect_table(ScriptoriumLayoutData.controls, "ScriptoriumLayoutData.controls")
    local tray_fallback = expect_table(ScriptoriumLayoutData.tray_fallback, "ScriptoriumLayoutData.tray_fallback")
    local unified_page = expect_table(ScriptoriumLayoutData.unified_page, "ScriptoriumLayoutData.unified_page")
    local unified_zone_main = expect_table(ScriptoriumLayoutData.unified_zone_main, "ScriptoriumLayoutData.unified_zone_main")
    local zoom_panel = expect_table(ScriptoriumLayoutData.zoom_panel, "ScriptoriumLayoutData.zoom_panel")

    local methods = {}

    local function get_controls_dock_height()
        return RuntimeUIDeps.sized(controls.dock_height or 136)
    end

    function methods.getControlsDockHeight(self)
        return get_controls_dock_height()
    end

    function methods._getTrayRect(self)
        local rect = EngineBridge.getDiceTrayRect()
        if rect and rect.w and rect.h then
            local x1, y1 = ResolutionManagerDeps.to_virtual(rect.x, rect.y)
            local x2, y2 = ResolutionManagerDeps.to_virtual(rect.x + rect.w, rect.y + rect.h)
            return {
                x = x1,
                y = y1,
                w = x2 - x1,
                h = y2 - y1,
            }
        end
        local w, h = ui_dimensions_fn()
        local tray_w = math.max(
            RuntimeUIDeps.sized(tray_fallback.min_width or 680),
            w * (tray_fallback.width_ratio or 0.70)
        )
        local tray_h = math.max(
            RuntimeUIDeps.sized(tray_fallback.min_height or 250),
            h * (tray_fallback.height_ratio or 0.32)
        )
        return {
            x = (w - tray_w) * 0.5,
            y = h - tray_h + RuntimeUIDeps.sized(tray_fallback.y_offset or 16),
            w = tray_w,
            h = tray_h,
        }
    end

    function methods.getUnifiedPagePanel(self, screen_w, screen_h)
        local side = clamp_fn(
            screen_w * (unified_page.side_ratio or 0.010),
            RuntimeUIDeps.sized(unified_page.side_min or 8),
            RuntimeUIDeps.sized(unified_page.side_max or 20)
        )
        local top = RuntimeUIDeps.sized(unified_page.top or 160)
        local tray = self:_getTrayRect()
        local dock_h = self:getControlsDockHeight()
        local gap_page_dock = RuntimeUIDeps.sized(unified_page.gap_page_dock or 8)
        local gap_dock_tray = RuntimeUIDeps.sized(unified_page.gap_dock_tray or 8)
        local bottom_limit = tray.y - dock_h - gap_page_dock - gap_dock_tray
        local available_h = math.floor(bottom_limit - top)
        if available_h < 1 then
            available_h = 1
        end
        local min_page_h = RuntimeUIDeps.sized(unified_page.min_height or 360)
        local page_h = clamp_fn(available_h, min_page_h, RuntimeUIDeps.sized(unified_page.max_height or 1040))
        if page_h > available_h then
            page_h = available_h
        end

        local max_page_w = screen_w - RuntimeUIDeps.sized(unified_page.max_width_margin or 16)
        if max_page_w < 1 then
            max_page_w = 1
        end
        local min_page_w = RuntimeUIDeps.sized(unified_page.min_width or 960)
        if min_page_w > max_page_w then
            min_page_w = max_page_w
        end
        local page_w = clamp_fn(screen_w - side * 2, min_page_w, max_page_w)

        return {
            x = math.floor((screen_w - page_w) * 0.5),
            y = top,
            w = page_w,
            h = page_h,
        }
    end

    function methods.getUnifiedZones(self, page)
        local x = page.x
        local y = page.y
        local w = page.w
        local h = page.h

        local main = {
            element = "TEXT",
            title = tr(MODULE_UI.element_display_folio),
            show_title = false,
            rect = {
                x = x + w * (unified_zone_main.x_ratio or 0.02),
                y = y + h * (unified_zone_main.y_ratio or 0.025),
                w = w * (unified_zone_main.width_ratio or 0.96),
                h = h * (unified_zone_main.height_ratio or 0.93),
            }
        }

        return {
            main = main,
            ordered = {main},
        }
    end

    function methods.getZoomPanelLayout(self, screen_w, screen_h, panels, zoom_element)
        local base = find_panel_by_element_fn and find_panel_by_element_fn(panels, zoom_element) or nil
        if (not base) and panels then
            base = panels[1]
        end
        if not base then
            return nil
        end

        local top = RuntimeUIDeps.sized(zoom_panel.top or 112)
        local side = RuntimeUIDeps.sized(zoom_panel.side or 128)
        local bottom_reserved = RuntimeUIDeps.sized(zoom_panel.bottom_reserved or 300)
        local panel_w = clamp_fn(
            screen_w - side * 2,
            RuntimeUIDeps.sized(zoom_panel.min_width or 760),
            screen_w - RuntimeUIDeps.sized(zoom_panel.width_margin or 42)
        )
        local panel_h = clamp_fn(
            screen_h - top - bottom_reserved,
            RuntimeUIDeps.sized(zoom_panel.min_height or 420),
            screen_h - top - RuntimeUIDeps.sized(zoom_panel.height_margin or 112)
        )

        return {
            element = base.element,
            title = base.title,
            x = math.floor((screen_w - panel_w) * 0.5),
            y = top,
            w = panel_w,
            h = panel_h,
            screen_space = true,
        }
    end

    return methods
end

local function ensure_bg()
    if bg_img then
        return
    end
    if love and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(BG_PATH) then
        local ok, img = pcall(function()
            return love.graphics.newImage(BG_PATH)
        end)
        if ok and img then
            bg_img = img
        end
    end
end

local function get_font(px, decorative)
    local size = math.max(
        RuntimeUI.sized(px),
        RuntimeUI.big_text() and MIN_UI_FONT_SIZE_BIG_TEXT or MIN_UI_FONT_SIZE
    )
    local use_decorative = decorative and size >= RuntimeUI.sized(DECORATIVE_MIN_SIZE)
    local use_micro = (not use_decorative) and size <= RuntimeUI.sized(MICRO_MAX_SIZE)
    local key_prefix = use_decorative and "dec-" or (use_micro and "micro-" or "body-")
    local key = key_prefix .. tostring(size)
    if font_cache[key] then
        return font_cache[key]
    end

    local selected = nil
    local candidates = DECORATIVE_FONT_CANDIDATES
    if not use_decorative then
        candidates = use_micro and MICRO_FONT_CANDIDATES or BODY_FONT_CANDIDATES
    end
    for _, path in ipairs(candidates) do
        if not path then
            local ok, font = pcall(function()
                return love.graphics.newFont(size, "normal")
            end)
            if ok and font then
                selected = font
                break
            end
        elseif love.filesystem.getInfo(path) then
            local ok, font = pcall(function()
                return love.graphics.newFont(path, size, "normal")
            end)
            if ok and font then
                selected = font
                break
            end
        end
    end

    if not selected then
        local ok, font = pcall(function()
            return love.graphics.newFont(size, "normal")
        end)
        selected = (ok and font) or love.graphics.getFont()
    end

    font_cache[key] = selected
    return selected
end

layout_methods = new_layout_methods({
    RuntimeUI = RuntimeUI,
    ResolutionManager = ResolutionManager,
    ui_dimensions = ui_dimensions,
    clamp = clamp,
    find_panel_by_element = find_panel_by_element,
})

hud_methods = ScriptoriumHud.new({
    RuntimeUI = RuntimeUI,
    PROTOTYPE_NO_BACKGROUND = PROTOTYPE_NO_BACKGROUND,
    HUD_LAYOUT = HUD_LAYOUT,
    project_rect = project_rect,
    clamp = clamp,
    point_in_rect = point_in_rect,
    draw_text_center = draw_text_center,
    get_font = get_font,
    get_remaining_dice_count = get_remaining_dice_count,
    get_unusable_dice_count = get_unusable_dice_count,
    ui_dimensions = ui_dimensions,
})

overlay_methods = ScriptoriumOverlays.new({
    RuntimeUI = RuntimeUI,
    ResolutionManager = ResolutionManager,
    OVERLAY_LAYOUT = OVERLAYS_LAYOUT,
    ui_dimensions = ui_dimensions,
    get_font = get_font,
    draw_text_center = draw_text_center,
    point_in_rect = point_in_rect,
    clamp = clamp,
    color_swatch = COLOR_SWATCH,
})

local function get_bg_rect(window_w, window_h)
    if not bg_img then
        return {
            x = 0,
            y = 0,
            w = window_w,
            h = window_h,
            sx = window_w / REF_W,
            sy = window_h / REF_H,
        }
    end

    local bw, bh = bg_img:getWidth(), bg_img:getHeight()
    local scale = math.min(window_w / bw, window_h / bh)
    local draw_w = bw * scale
    local draw_h = bh * scale
    local draw_x = (window_w - draw_w) * 0.5
    local draw_y = (window_h - draw_h) * 0.5

    return {
        x = draw_x,
        y = draw_y,
        w = draw_w,
        h = draw_h,
        sx = draw_w / REF_W,
        sy = draw_h / REF_H,
        scale = scale,
    }
end

function Scriptorium:persistRunSnapshot(reason)
    if not self.run or type(self.run.toSaveData) ~= "function" then
        return false
    end

    local ok_snapshot, snapshot = pcall(function()
        return self.run:toSaveData()
    end)
    if not ok_snapshot or type(snapshot) ~= "table" then
        Logger.debug("[Scriptorium] Save snapshot failed to build: " .. tostring(snapshot))
        return false
    end

    local ok_save, err = SaveState.save({
        run = snapshot,
    })
    if not ok_save then
        Logger.debug("[Scriptorium] Save snapshot write failed: " .. tostring(err))
        return false
    end

    if reason then
        Logger.debug("[Scriptorium] Run saved (" .. tostring(reason) .. ").")
    end
    return true
end

function Scriptorium:clearPersistedRun(reason)
    local ok, err = SaveState.clear()
    if not ok then
        Logger.debug("[Scriptorium] Save clear failed: " .. tostring(err))
        return false
    end
    if reason then
        Logger.debug("[Scriptorium] Save cleared (" .. tostring(reason) .. ").")
    end
    return true
end

function Scriptorium:drawDiegeticWorkspace(panels, high_contrast)
    if not PROTOTYPE_NO_BACKGROUND then
        return
    end
    local bounds = get_panels_bounds(panels)
    if not bounds then
        return
    end

    local frame_padding = WORKSPACE_STYLE.frame_padding or {}
    local shadow_style = WORKSPACE_STYLE.shadow or {}
    local outer_style = WORKSPACE_STYLE.outer or {}
    local inner_style = WORKSPACE_STYLE.inner or {}
    local seam_style = inner_style.seam or {}
    local binder_style = WORKSPACE_STYLE.binder or {}
    local clip_style = WORKSPACE_STYLE.clip or {}
    local bridge_style = WORKSPACE_STYLE.bridge or {}
    local support_style = WORKSPACE_STYLE.support or {}
    local outline_style = WORKSPACE_STYLE.outline or {}
    local outer_outline_style = outline_style.outer or {}
    local inner_outline_style = outline_style.inner or {}

    local frame_pad_x = RuntimeUI.sized(frame_padding.x or 40)
    local frame_pad_y = RuntimeUI.sized(frame_padding.y or 28)
    local outer = {
        x = bounds.x - frame_pad_x,
        y = bounds.y - frame_pad_y,
        w = bounds.w + frame_pad_x * 2,
        h = bounds.h + frame_pad_y * 2,
    }

    local shadow_color = shadow_style.color or {0.03, 0.02, 0.01}
    local shadow_alpha = high_contrast and (shadow_style.alpha_high_contrast or 0.42) or (shadow_style.alpha_normal or 0.30)
    local shadow_inset = shadow_style.inset or {}
    local shadow_radius = shadow_style.radius or 10
    love.graphics.setColor(shadow_color[1] or 0.03, shadow_color[2] or 0.02, shadow_color[3] or 0.01, shadow_alpha)
    love.graphics.rectangle(
        "fill",
        outer.x - RuntimeUI.sized(shadow_inset.x or 6),
        outer.y - RuntimeUI.sized(shadow_inset.y or 7),
        outer.w + RuntimeUI.sized(shadow_inset.w or 12),
        outer.h + RuntimeUI.sized(shadow_inset.h or 16),
        shadow_radius, shadow_radius
    )

    local outer_fill = outer_style.fill_color or {0.27, 0.18, 0.10}
    local outer_fill_alpha = high_contrast and (outer_style.fill_alpha_high_contrast or 0.98) or (outer_style.fill_alpha_normal or 0.94)
    local outer_line = outer_style.line_color or {0.52, 0.37, 0.22}
    local outer_line_alpha = outer_style.line_alpha or 0.64
    local outer_radius = outer_style.radius or 8
    love.graphics.setColor(outer_fill[1] or 0.27, outer_fill[2] or 0.18, outer_fill[3] or 0.10, outer_fill_alpha)
    love.graphics.rectangle("fill", outer.x, outer.y, outer.w, outer.h, outer_radius, outer_radius)
    love.graphics.setColor(outer_line[1] or 0.52, outer_line[2] or 0.37, outer_line[3] or 0.22, outer_line_alpha)
    love.graphics.rectangle("line", outer.x, outer.y, outer.w, outer.h, outer_radius, outer_radius)

    local inner_pad = RuntimeUI.sized(inner_style.padding or 13)
    local inner = {
        x = outer.x + inner_pad,
        y = outer.y + inner_pad,
        w = outer.w - inner_pad * 2,
        h = outer.h - inner_pad * 2,
    }
    local left_page_w = math.floor(inner.w * 0.5)
    local right_page_w = inner.w - left_page_w

    local page_corner_radius = inner_style.page_corner_radius or 6
    local left_page_color = inner_style.left_page_color or {0.86, 0.78, 0.64}
    local left_page_alpha = high_contrast and (inner_style.left_page_alpha_high_contrast or 0.60) or (inner_style.left_page_alpha_normal or 0.46)
    local right_page_color = inner_style.right_page_color or {0.82, 0.74, 0.60}
    local right_page_alpha = high_contrast and (inner_style.right_page_alpha_high_contrast or 0.58) or (inner_style.right_page_alpha_normal or 0.42)
    love.graphics.setColor(left_page_color[1] or 0.86, left_page_color[2] or 0.78, left_page_color[3] or 0.64, left_page_alpha)
    love.graphics.rectangle("fill", inner.x, inner.y, left_page_w, inner.h, page_corner_radius, page_corner_radius)
    love.graphics.setColor(right_page_color[1] or 0.82, right_page_color[2] or 0.74, right_page_color[3] or 0.60, right_page_alpha)
    love.graphics.rectangle("fill", inner.x + left_page_w, inner.y, right_page_w, inner.h, page_corner_radius, page_corner_radius)

    local seam_x = inner.x + left_page_w
    local seam_color = seam_style.color or {0.30, 0.21, 0.14}
    local seam_alpha = seam_style.alpha or 0.38
    local seam_line_width = seam_style.line_width or 2
    local seam_y_padding = seam_style.y_padding or 10
    love.graphics.setColor(seam_color[1] or 0.30, seam_color[2] or 0.21, seam_color[3] or 0.14, seam_alpha)
    love.graphics.setLineWidth(seam_line_width)
    love.graphics.line(seam_x, inner.y + RuntimeUI.sized(seam_y_padding), seam_x, inner.y + inner.h - RuntimeUI.sized(seam_y_padding))
    love.graphics.setLineWidth(1)

    local binder_w = RuntimeUI.sized(binder_style.width or 16)
    local binder_y_offset = RuntimeUI.sized(binder_style.y_offset or 6)
    local binder_y_padding = RuntimeUI.sized(binder_style.y_padding or 12)
    local binder_radius = binder_style.corner_radius or 4
    local binder_color = binder_style.fill_color or {0.29, 0.18, 0.10}
    love.graphics.setColor(binder_color[1] or 0.29, binder_color[2] or 0.18, binder_color[3] or 0.10, binder_style.fill_alpha or 0.78)
    love.graphics.rectangle("fill", seam_x - binder_w * 0.5, inner.y + binder_y_offset, binder_w, inner.h - binder_y_padding, binder_radius, binder_radius)

    local clip_w = RuntimeUI.sized(clip_style.width or 64)
    local clip_h = RuntimeUI.sized(clip_style.height or 14)
    local clip_radius = clip_style.corner_radius or 4
    local clip_color = clip_style.fill_color or {0.63, 0.47, 0.30}
    local clip_y_offset_ratio = clip_style.y_offset_ratio or -0.5
    love.graphics.setColor(clip_color[1] or 0.63, clip_color[2] or 0.47, clip_color[3] or 0.30, clip_style.fill_alpha or 0.88)
    love.graphics.rectangle("fill", seam_x - clip_w * 0.5, outer.y + clip_h * clip_y_offset_ratio, clip_w, clip_h, clip_radius, clip_radius)

    local bridge_w = outer.w * (bridge_style.width_ratio or 0.34)
    local bridge_h = RuntimeUI.sized(bridge_style.height or 30)
    local bridge_x = outer.x + (outer.w - bridge_w) * 0.5
    local bridge_y = outer.y + outer.h + RuntimeUI.sized(bridge_style.y_offset or -2)
    local bridge_radius = bridge_style.corner_radius or 6
    local bridge_fill = bridge_style.fill_color or {0.26, 0.17, 0.10}
    local bridge_line = bridge_style.line_color or {0.62, 0.45, 0.28}
    love.graphics.setColor(bridge_fill[1] or 0.26, bridge_fill[2] or 0.17, bridge_fill[3] or 0.10, bridge_style.fill_alpha or 0.94)
    love.graphics.rectangle("fill", bridge_x, bridge_y, bridge_w, bridge_h, bridge_radius, bridge_radius)
    love.graphics.setColor(bridge_line[1] or 0.62, bridge_line[2] or 0.45, bridge_line[3] or 0.28, bridge_style.line_alpha or 0.66)
    love.graphics.rectangle("line", bridge_x, bridge_y, bridge_w, bridge_h, bridge_radius, bridge_radius)

    local support_w = RuntimeUI.sized(support_style.width or 24)
    local support_h = RuntimeUI.sized(support_style.height or 68)
    local support_x = seam_x - support_w * 0.5
    local support_y = bridge_y + bridge_h + RuntimeUI.sized(support_style.y_offset or -1)
    local support_radius = support_style.corner_radius or 4
    local support_fill = support_style.fill_color or {0.22, 0.14, 0.08}
    local support_line = support_style.line_color or {0.52, 0.36, 0.22}
    love.graphics.setColor(support_fill[1] or 0.22, support_fill[2] or 0.14, support_fill[3] or 0.08, support_style.fill_alpha or 0.90)
    love.graphics.rectangle("fill", support_x, support_y, support_w, support_h, support_radius, support_radius)
    love.graphics.setColor(support_line[1] or 0.52, support_line[2] or 0.36, support_line[3] or 0.22, support_style.line_alpha or 0.58)
    love.graphics.rectangle("line", support_x, support_y, support_w, support_h, support_radius, support_radius)

    local outer_outline = outer_outline_style.color or {0.71, 0.55, 0.38}
    local inner_outline = inner_outline_style.color or {0.40, 0.30, 0.20}
    love.graphics.setColor(outer_outline[1] or 0.71, outer_outline[2] or 0.55, outer_outline[3] or 0.38, outer_outline_style.alpha or 0.78)
    love.graphics.rectangle("line", outer.x, outer.y, outer.w, outer.h, outer_outline_style.corner_radius or 8, outer_outline_style.corner_radius or 8)
    love.graphics.setColor(inner_outline[1] or 0.40, inner_outline[2] or 0.30, inner_outline[3] or 0.20, inner_outline_style.alpha or 0.55)
    love.graphics.rectangle("line", inner.x, inner.y, inner.w, inner.h, inner_outline_style.corner_radius or 6, inner_outline_style.corner_radius or 6)
end

local function get_tile_color_for_constraint(constraint)
    if type(constraint) == "string" then
        return COLOR_SWATCH[constraint]
    end
    return nil
end

local function get_tile_key_for_constraint(constraint)
    if type(constraint) == "number" then
        local n = math.floor(constraint)
        if n >= 1 and n <= 6 then
            return tostring(n)
        end
    elseif type(constraint) == "string" then
        local mapped = COLOR_TO_VALUE[constraint]
        if mapped then
            return tostring(mapped)
        end
    end
    return nil
end

function Scriptorium:buildPlacementFocus()
    if self.state ~= "placing" or not self.run or not self.run.current_folio then
        return nil
    end
    local die = self.getSelectedDie and self:getSelectedDie() or nil
    if not die or die.used then
        return nil
    end

    local folio = self.run.current_folio
    local palette = (self.getTurnPalette and self:getTurnPalette()) or {}
    local focus = {
        active = true,
        die_index = self.selected_die,
        die_value = die.value,
        die_color = nil,
        palette = palette,
        legal_by_element = {},
        blocked_by_element = {},
        best_element = nil,
        best_entry = nil,
        total_legal = 0,
    }

    local best_element_count = -1
    local best_element_score = -math.huge
    for _, element in ipairs(folio.ELEMENTS) do
        local zone_info = {
            count = 0,
            by_key = {},
        }

        local element_best_score = -math.huge
        for _, color in ipairs(palette) do
            local placements = folio:getValidPlacements(element, die.value, color)
            for _, placement in ipairs(placements) do
                local preview = folio.getPlacementDecisionPreview
                        and folio:getPlacementDecisionPreview(element, placement.row, placement.col, die.value, color)
                    or {quality_gain = 0, risk_gain = 0, score = 0}
                local key = tostring(placement.row) .. ":" .. tostring(placement.col)
                local entry = zone_info.by_key[key]
                if not entry then
                    entry = {
                        element = element,
                        row = placement.row,
                        col = placement.col,
                        quality_gain = preview.quality_gain or 0,
                        risk_gain = preview.risk_gain or 0,
                        score = preview.score or 0,
                        palette_colors = {color},
                    }
                    zone_info.by_key[key] = entry
                    zone_info.count = zone_info.count + 1
                else
                    if not entry.palette_colors then
                        entry.palette_colors = {}
                    end
                    local has_color = false
                    for _, existing in ipairs(entry.palette_colors) do
                        if existing == color then
                            has_color = true
                            break
                        end
                    end
                    if not has_color then
                        entry.palette_colors[#entry.palette_colors + 1] = color
                    end
                    if (preview.score or 0) > (entry.score or -math.huge) then
                        entry.quality_gain = preview.quality_gain or 0
                        entry.risk_gain = preview.risk_gain or 0
                        entry.score = preview.score or 0
                    end
                end
                if (entry.score or -math.huge) > element_best_score then
                    element_best_score = entry.score or 0
                end
                if not focus.best_entry or (entry.score or -math.huge) > (focus.best_entry.score or -math.huge) then
                    focus.best_entry = entry
                end
            end
        end

        if zone_info.count > 0 then
            focus.total_legal = focus.total_legal + zone_info.count
            focus.legal_by_element[element] = zone_info
            if zone_info.count > best_element_count or (zone_info.count == best_element_count and element_best_score > best_element_score) then
                best_element_count = zone_info.count
                best_element_score = element_best_score
                focus.best_element = element
            end
        end
    end

    for _, element in ipairs(folio.ELEMENTS) do
        local _, elem = folio:_resolveElement(element)
        if elem and elem.pattern then
            local pattern = elem.pattern
            local rows = pattern.rows or 0
            local cols = pattern.cols or 0
            for row = 1, rows do
                if folio.isRowOpen and folio:isRowOpen(row) then
                    for col = 1, cols do
                        local reason = folio.getPlacementBlockReason
                            and folio:getPlacementBlockReason(element, row, col, die.value, palette)
                            or nil
                        if reason then
                            if not focus.blocked_by_element[element] then
                                focus.blocked_by_element[element] = {}
                            end
                            focus.blocked_by_element[element][tostring(row) .. ":" .. tostring(col)] = reason
                        end
                    end
                end
            end
        end
    end

    return focus
end

local function build_setup_defaults(row_count, required)
    local rows = {}
    local max_rows = math.max(1, math.floor(tonumber(row_count) or 4))
    local need = clamp(math.floor(tonumber(required) or 2), 1, max_rows)
    for row = 1, max_rows do
        rows[#rows + 1] = row
        if #rows >= need then
            break
        end
    end
    return rows
end

function Scriptorium:resetSetupStateForCurrentFolio()
    local folio = self.run and self.run.current_folio or nil
    local row_count = (folio and folio.getRowCount and folio:getRowCount("TEXT")) or 4
    local required_guided = clamp(math.floor(tonumber(folio and folio.required_guided_rows) or 2), 1, math.max(1, row_count))
    local guided = (folio and folio.getGuidedRows and folio:getGuidedRows()) or {}

    if type(guided) ~= "table" then
        guided = {}
    end
    while #guided > required_guided do
        table.remove(guided)
    end
    if #guided < required_guided then
        guided = build_setup_defaults(row_count, required_guided)
    end

    local open_rows = (folio and folio.getOpenRows and folio:getOpenRows()) or {}
    local initial = open_rows[1]
    local has_initial = false
    if initial then
        for _, row in ipairs(guided) do
            if row == initial then
                has_initial = true
                break
            end
        end
    end
    if not has_initial then
        initial = guided[1]
    end

    self.setup_guided_rows = guided
    self.setup_initial_row = initial
end

function Scriptorium:enter(folio_set_type_or_params, seed)
    local params
    if type(folio_set_type_or_params) == "table" then
        params = folio_set_type_or_params
    else
        params = {
            folio_set = folio_set_type_or_params,
            seed = seed,
        }
    end

    local resumed_from_save = false
    if params.run then
        self.run = params.run
    elseif type(params.run_data) == "table" and type(Run.fromSaveData) == "function" then
        local ok_restored, restored_or_err = pcall(function()
            return Run.fromSaveData(params.run_data)
        end)
        if ok_restored and restored_or_err then
            self.run = restored_or_err
            resumed_from_save = true
            Logger.debug("[Scriptorium] Restored run from saved snapshot.")
        else
            Logger.debug("[Scriptorium] Failed to restore saved run, starting fresh: " .. tostring(restored_or_err))
            self:clearPersistedRun("restore_failed")
        end
    else
        self.run = Run.new(
            params.folio_set or "BIFOLIO",
            params.seed,
            {
                campaign_id = params.campaign_id,
                commission_id = params.commission_id,
                folio_set = params.folio_set,
                seed = params.seed,
            }
        )
    end

    self.start_params = {
        folio_set = self.run and self.run.folio_set or (params.folio_set or "BIFOLIO"),
        campaign_id = (self.run and self.run.campaign_id) or params.campaign_id or params.commission_id,
    }

    self.value_to_color = VALUE_TO_COLOR
    self.dice_results = {}
    self.turn_palette = nil
    self.palette_picker = nil
    self.state = "waiting"
    self.message = nil
    self.message_timer = 0
    self.selected_cell = nil
    self.selected_die = nil
    self.ui_hit = {}
    self.lock_badges = {}
    self.hovered_lock = nil
    self.view_mode = "overview"
    self.zoom_element = nil
    self.show_run_setup = false
    self.show_system_menu = false
    self.setup_guided_rows = nil
    self.setup_initial_row = nil
    self.pending_stain_choices = nil
    self.pending_stain_total = nil
    self.pending_stain_remaining = nil
    self.pending_ink_recovery = nil
    self.pending_ink_recovery_rows = nil
    self.pending_row_swap = nil
    self.ruling_actions_left = 0
    self.current_focus = nil
    self.hover_constraint_color = nil
    self.show_folio_result = false
    self.folio_result = nil
    self.show_ruling_overlay = false
    self:resetSetupStateForCurrentFolio()
    self:persistRunSnapshot("enter")

    if resumed_from_save then
        Logger.debug("[Scriptorium] Resumed run: " .. tostring(self.run.folio_set))
    else
        Logger.debug("[Scriptorium] New run started: " .. tostring(self.run.folio_set))
    end
end

function Scriptorium:exit()
    self.run = nil
    self.dice_results = {}
    self.turn_palette = nil
    self.palette_picker = nil
    self.state = "waiting"
    self.message = nil
    self.message_timer = 0
    self.ui_hit = {}
    self.lock_badges = {}
    self.hovered_lock = nil
    self.view_mode = "overview"
    self.zoom_element = nil
    self.show_run_setup = false
    self.show_system_menu = false
    self.setup_guided_rows = nil
    self.setup_initial_row = nil
    self.pending_stain_choices = nil
    self.pending_stain_total = nil
    self.pending_stain_remaining = nil
    self.pending_ink_recovery = nil
    self.pending_ink_recovery_rows = nil
    self.pending_row_swap = nil
    self.ruling_actions_left = 0
    self.current_focus = nil
    self.hover_constraint_color = nil
    self.show_folio_result = false
    self.folio_result = nil
    self.show_ruling_overlay = false
    self.start_params = nil
end

function Scriptorium:update(dt)
    if self.message_timer > 0 then
        self.message_timer = self.message_timer - dt
        if self.message_timer <= 0 then
            self.message_timer = 0
            self.message = nil

            self:advanceRunIfResolved()
        end
    end
end

function Scriptorium:advanceRunIfResolved()
    if not self.run or self.run.victory or self.run.game_over then
        return false
    end
    if self.show_folio_result then
        return false
    end
    local folio = self.run.current_folio
    if not folio or (not folio.completed and not folio.busted) then
        return false
    end

    local _, result = self.run:nextFolio()
    self.dice_results = {}
    self.turn_palette = nil
    self.palette_picker = nil
    self.state = "waiting"
    self.selected_die = nil
    self.selected_cell = nil
    self.pending_stain_choices = nil
    self.pending_stain_total = nil
    self.pending_stain_remaining = nil
    self.pending_ink_recovery = nil
    self.pending_ink_recovery_rows = nil
    self.pending_row_swap = nil
    self.ruling_actions_left = 0
    self.current_focus = nil
    self.hover_constraint_color = nil
    self.show_folio_result = false
    self.folio_result = nil
    self.show_ruling_overlay = false

    if result == "next" then
        local index = tonumber(self.run.current_folio_index) or 1
        local total = tonumber(self.run.total_folios) or 1
        self.show_run_setup = false
        self:resetSetupStateForCurrentFolio()
        self:persistRunSnapshot("next_folio")
        self:showMessage(
            tr(MODULE_UI.flow_message_folio_title, {
                index = index,
                total = total,
            }),
            tr(MODULE_UI.flow_message_next_ready_subtitle),
            2.0
        )
    elseif result == "victory" then
        self:clearPersistedRun("victory")
        local outcome = self.run.commission_result
        if outcome and outcome.dirty then
            self:showMessage(
                tr(MODULE_UI.flow_message_commission_complete_title),
                tr(MODULE_UI.flow_message_dirty_finish_subtitle, {
                    stains = outcome.stains or 0,
                    threshold = outcome.threshold or 0,
                }),
                5
            )
        else
            self:showMessage(tr(MODULE_UI.flow_message_victory_title), nil, 5)
        end
    elseif result == "game_over" then
        self:clearPersistedRun("game_over")
        self:showMessage(tr(MODULE_UI.flow_message_game_over_title), nil, 5)
    end
    return true
end

function Scriptorium:openFolioResult()
    local folio = self.run and self.run.current_folio or nil
    if not folio or (not folio.completed and not folio.busted) then
        return false
    end
    local failed = folio.busted and (not folio.completed)
    self.show_folio_result = true
    self.folio_result = {
        completed_rows = folio.getCompletedRowsCount and folio:getCompletedRowsCount("TEXT") or 0,
        stains = folio.stain_count or 0,
        turns = folio.turn_count or 0,
        quality = failed
            and tr(MODULE_UI.result_quality_failed)
            or (folio.getQualityTier and folio:getQualityTier() or tr(MODULE_UI.result_quality_working)),
        failed = failed,
    }
    self.show_ruling_overlay = false
    self.message = nil
    self.message_timer = 0
    return true
end

local function fract(v)
    return v - math.floor(v)
end

local function hash11(v)
    return fract(math.sin(v * 12.9898 + 78.233) * 43758.5453)
end

local function draw_dust_particles(screen_w, screen_h, high_contrast)
    if RuntimeUI.reduced_animations and RuntimeUI.reduced_animations() then
        return
    end
    local now = (love and love.timer and love.timer.getTime and love.timer.getTime()) or 0
    local count = high_contrast and 26 or 44
    local base_radius = math.max(0.30, math.min(screen_w, screen_h) * 0.00062)
    for i = 1, count do
        local seed = i * 1.327
        local depth = 0.55 + hash11(seed + 11.0) * 0.90
        local drift_x = (hash11(seed + 23.0) - 0.5) * 0.026
        local drift_y = 0.010 + hash11(seed + 31.0) * 0.018
        local x = fract(hash11(seed + 5.0) + now * drift_x * depth) * screen_w
        local y = fract(hash11(seed + 7.0) + now * drift_y * depth) * screen_h
        local pulse = 0.76 + 0.24 * math.sin(now * (0.8 + depth * 0.3) + seed * 1.7)
        local radius = base_radius * (0.55 + hash11(seed + 17.0) * 0.95)
        local alpha = (0.07 + hash11(seed + 29.0) * 0.12) * pulse
        love.graphics.setColor(0.92, 0.85, 0.73, alpha)
        love.graphics.circle("fill", x, y, radius)
    end
end

function Scriptorium:drawBackground(bg, high_contrast)
    local w, h = ui_dimensions()
    local image_drawn = false

    if bg_img then
        if PROTOTYPE_NO_BACKGROUND then
            local bw, bh = bg_img:getWidth(), bg_img:getHeight()
            local scale = math.max(w / bw, h / bh)
            local draw_w = bw * scale
            local draw_h = bh * scale
            local draw_x = (w - draw_w) * 0.5
            local draw_y = (h - draw_h) * 0.5
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(bg_img, draw_x, draw_y, 0, scale, scale)
            image_drawn = true
        else
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(bg_img, bg.x, bg.y, 0, bg.scale, bg.scale)
            image_drawn = true
        end
    end

    if PROTOTYPE_NO_BACKGROUND then
        if not image_drawn then
            love.graphics.setColor(0.10, 0.07, 0.05, 1)
            love.graphics.rectangle("fill", 0, 0, w, h)
        end

        love.graphics.setColor(0.05, 0.04, 0.03, high_contrast and 0.34 or 0.44)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(0.16, 0.11, 0.08, high_contrast and 0.10 or 0.18)
        love.graphics.rectangle("fill", 0, 0, w * 0.44, h)
        love.graphics.setColor(0.22, 0.15, 0.09, high_contrast and 0.07 or 0.11)
        love.graphics.rectangle("fill", w * 0.32, 0, w * 0.36, h)

        local top_bottom = math.floor(h * 0.062)
        local side = math.floor(w * 0.032)
        love.graphics.setColor(0.03, 0.02, 0.01, high_contrast and 0.36 or 0.50)
        love.graphics.rectangle("fill", 0, 0, w, top_bottom)
        love.graphics.rectangle("fill", 0, h - top_bottom, w, top_bottom)
        love.graphics.rectangle("fill", 0, 0, side, h)
        love.graphics.rectangle("fill", w - side, 0, side, h)

        draw_dust_particles(w, h, high_contrast)
        return
    end

    if not image_drawn then
        love.graphics.setColor(0.10, 0.08, 0.06, 1)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    love.graphics.setColor(0.11, 0.08, 0.05, high_contrast and 0.12 or 0.24)
    love.graphics.rectangle("fill", bg.x, bg.y, bg.w, bg.h)
    draw_dust_particles(w, h, high_contrast)
end

function Scriptorium:drawLegendPanel(bg, high_contrast)
    local rect_layout = LEGEND_PANEL_LAYOUT.rect or {}
    local panel_layout = LEGEND_PANEL_LAYOUT.panel or {}
    local border_layout = LEGEND_PANEL_LAYOUT.border or {}
    local title_layout = LEGEND_PANEL_LAYOUT.title or {}
    local body_layout = LEGEND_PANEL_LAYOUT.body or {}
    local bullet_layout = LEGEND_PANEL_LAYOUT.bullet or {}

    local panel = project_rect(
        bg,
        rect_layout.x or 18,
        rect_layout.y or 156,
        rect_layout.w or 148,
        rect_layout.h or 436
    )
    local panel_fill = panel_layout.fill_color or {0.38, 0.26, 0.18}
    local panel_fill_alpha = high_contrast
        and (panel_layout.fill_alpha_high_contrast or 0.95)
        or (panel_layout.fill_alpha_normal or 0.90)
    love.graphics.setColor(panel_fill[1] or 0.38, panel_fill[2] or 0.26, panel_fill[3] or 0.18, panel_fill_alpha)
    love.graphics.rectangle(
        "fill",
        panel.x,
        panel.y,
        panel.w,
        panel.h,
        panel_layout.corner_radius or 10,
        panel_layout.corner_radius or 10
    )
    local border_color = border_layout.line_color or {0.76, 0.58, 0.40}
    love.graphics.setColor(
        border_color[1] or 0.76,
        border_color[2] or 0.58,
        border_color[3] or 0.40,
        border_layout.line_alpha or 0.9
    )
    love.graphics.setLineWidth(border_layout.line_width or 2)
    love.graphics.rectangle(
        "line",
        panel.x,
        panel.y,
        panel.w,
        panel.h,
        border_layout.corner_radius or 10,
        border_layout.corner_radius or 10
    )
    love.graphics.setLineWidth(1)

    local title_font = get_font(title_layout.text_size or 16, false)
    local body_font = get_font(
        RuntimeUI.big_text() and (body_layout.text_size_big_text or 13) or (body_layout.text_size or 12),
        false
    )
    draw_text_center(
        tr(MODULE_UI.legend_title),
        {
            x = panel.x,
            y = panel.y + RuntimeUI.sized(title_layout.y_offset or 10),
            w = panel.w,
            h = RuntimeUI.sized(title_layout.height or 20),
        },
        title_font,
        title_layout.text_color or {0.95, 0.82, 0.52, 1}
    )

    local line_y = panel.y + RuntimeUI.sized(body_layout.line_start or 46)
    local line_step = RuntimeUI.sized(
        RuntimeUI.big_text() and (body_layout.line_step_big_text or 30) or (body_layout.line_step or 28)
    )
    local constraint_lines = get_constraint_lines()
    for i, text in ipairs(constraint_lines) do
        local bullet_color = (i == #constraint_lines)
            and (bullet_layout.color_last or {0.95, 0.82, 0.52, 1})
            or (bullet_layout.color_default or {0.96, 0.61, 0.24, 1})
        love.graphics.setColor(bullet_color[1], bullet_color[2], bullet_color[3], 1)
        love.graphics.circle(
            "fill",
            panel.x + RuntimeUI.sized(bullet_layout.x or 12),
            line_y + RuntimeUI.sized(bullet_layout.y or 7),
            RuntimeUI.sized(bullet_layout.radius or 3)
        )
        local body_color = body_layout.text_color or {0.96, 0.90, 0.82, 1}
        love.graphics.setColor(body_color[1] or 0.96, body_color[2] or 0.90, body_color[3] or 0.82, body_color[4] or 1)
        love.graphics.setFont(body_font)
        love.graphics.print(text, panel.x + RuntimeUI.sized(22), line_y)
        line_y = line_y + line_step
    end
end

function Scriptorium:drawTileCell(x, y, size, constraint, marker, placed, tile_key, high_contrast, visual)
    local base_layout = TILE_CELL_LAYOUT.base or {}
    local placed_layout = TILE_CELL_LAYOUT.placed or {}
    local constraint_number_layout = TILE_CELL_LAYOUT.constraint_number or {}
    local constraint_color_layout = TILE_CELL_LAYOUT.constraint_color or {}
    local marker_layout = TILE_CELL_LAYOUT.marker or {}
    local visual_layout = TILE_CELL_LAYOUT.visual or {}
    local visual_dim_layout = visual_layout.dim or {}
    local visual_closed_row_layout = visual_layout.closed_row or {}
    local visual_highlight_layout = visual_layout.highlight or {}
    local visual_hover_preview_layout = visual_layout.hover_preview or {}
    local visual_preview_layout = visual_layout.preview or {}
    local visual_stained_layout = visual_layout.stained or {}
    local visual_stain_choice_layout = visual_layout.stain_choice or {}

    local base_fill = base_layout.fill_color or {0.34, 0.29, 0.20}
    local base_line = base_layout.line_color or {0.62, 0.43, 0.23}
    local base_corner = base_layout.corner_radius or 2
    love.graphics.setColor(base_fill[1] or 0.34, base_fill[2] or 0.29, base_fill[3] or 0.20, base_layout.fill_alpha or 0.80)
    love.graphics.rectangle("fill", x, y, size, size, base_corner, base_corner)
    love.graphics.setColor(base_line[1] or 0.62, base_line[2] or 0.43, base_line[3] or 0.23, base_layout.line_alpha or 0.28)
    love.graphics.rectangle("line", x, y, size, size, base_corner, base_corner)

    if placed then
        local die_color = COLOR_SWATCH[placed.color] or {0.75, 0.75, 0.75}
        local dry_alpha = placed_layout.fill_alpha_dry or 0.82
        local fill_alpha = placed.wet and (placed_layout.fill_alpha_wet or 0.58) or dry_alpha
        if (not placed.wet) and placed.committed_at and love.timer and love.timer.getTime then
            local flash_duration = placed_layout.flash_duration or 0.55
            local dt = love.timer.getTime() - placed.committed_at
            if dt < flash_duration then
                local t = math.max(0, math.min(1, dt / flash_duration))
                local flash_from = placed_layout.flash_alpha_from or 0.30
                fill_alpha = flash_from + (dry_alpha - flash_from) * t
                local flash_fill = placed_layout.flash_fill_color or {0.98, 0.92, 0.76}
                local flash_alpha = (placed_layout.flash_alpha_base or 0.20) + (placed_layout.flash_alpha_pulse or 0.20) * (1 - t)
                love.graphics.setColor(flash_fill[1] or 0.98, flash_fill[2] or 0.92, flash_fill[3] or 0.76, flash_alpha)
                love.graphics.rectangle(
                    "fill",
                    x + 1,
                    y + 1,
                    size - 2,
                    size - 2,
                    placed_layout.corner_radius or 2,
                    placed_layout.corner_radius or 2
                )
            else
                placed.committed_at = nil
            end
        end
        local inset = placed_layout.inset or 2
        local inset_total = placed_layout.inset_total or 4
        local placed_corner = placed_layout.corner_radius or 2
        love.graphics.setColor(die_color[1], die_color[2], die_color[3], fill_alpha)
        love.graphics.rectangle("fill", x + inset, y + inset, size - inset_total, size - inset_total, placed_corner, placed_corner)
        local border = placed_layout.border_color or {0.97, 0.86, 0.56}
        local border_alpha = placed.wet and (placed_layout.border_alpha_wet or 0.45) or (placed_layout.border_alpha_dry or 0.28)
        love.graphics.setColor(border[1] or 0.97, border[2] or 0.86, border[3] or 0.56, border_alpha)
        love.graphics.rectangle("line", x + inset, y + inset, size - inset_total, size - inset_total, placed_corner, placed_corner)

        local value_font_min = placed_layout.value_font_min or 11
        local value_font_ratio = placed_layout.value_font_ratio or 0.42
        local value_color = placed_layout.value_color or {0.12, 0.08, 0.05, 1}
        love.graphics.setFont(get_font(math.max(value_font_min, math.floor(size * value_font_ratio)), true))
        love.graphics.setColor(value_color[1] or 0.12, value_color[2] or 0.08, value_color[3] or 0.05, value_color[4] or 1)
        love.graphics.printf(tostring(placed.value), x, y + (size * (placed_layout.value_y_ratio or 0.24)), size, "center")

        if placed.wet then
            local wet_dot = placed_layout.wet_dot or {}
            local dot = math.max(wet_dot.radius_min or 3, math.floor(size * (wet_dot.radius_ratio or 0.10)))
            local dot_inset = wet_dot.inset or 3
            local dot_fill = wet_dot.fill_color or {0.96, 0.90, 0.70}
            local dot_line = wet_dot.line_color or {0.32, 0.22, 0.12}
            love.graphics.setColor(dot_fill[1] or 0.96, dot_fill[2] or 0.90, dot_fill[3] or 0.70, wet_dot.fill_alpha or 0.92)
            love.graphics.circle("fill", x + size - dot - dot_inset, y + size - dot - dot_inset, dot)
            love.graphics.setColor(dot_line[1] or 0.32, dot_line[2] or 0.22, dot_line[3] or 0.12, wet_dot.line_alpha or 0.82)
            love.graphics.circle("line", x + size - dot - dot_inset, y + size - dot - dot_inset, dot)
        end
    end

    if constraint and not placed then
        if type(constraint) == "number" then
            local font_size = math.max(constraint_number_layout.font_min or 12, math.floor(size * (constraint_number_layout.font_ratio or 0.60)))
            local number_color = constraint_number_layout.color or {0.20, 0.14, 0.09}
            love.graphics.setFont(get_font(font_size, true))
            love.graphics.setColor(number_color[1] or 0.20, number_color[2] or 0.14, number_color[3] or 0.09, constraint_number_layout.alpha or 0.38)
            love.graphics.printf(tostring(constraint), x, y + (size * (constraint_number_layout.y_ratio or 0.16)), size, "center")
        elseif type(constraint) == "string" then
            local c = get_tile_color_for_constraint(constraint) or {0.82, 0.82, 0.82}
            local dot = math.max(constraint_color_layout.radius_min or 4, math.floor(size * (constraint_color_layout.radius_ratio or 0.18)))
            local dot_inset = constraint_color_layout.inset or 3
            local dot_line = constraint_color_layout.line_color or {0.08, 0.08, 0.08}
            love.graphics.setColor(c[1], c[2], c[3], constraint_color_layout.fill_alpha or 0.96)
            love.graphics.circle("fill", x + size - dot - dot_inset, y + dot + dot_inset, dot)
            love.graphics.setColor(dot_line[1] or 0.08, dot_line[2] or 0.08, dot_line[3] or 0.08, constraint_color_layout.line_alpha or 0.9)
            love.graphics.circle("line", x + size - dot - dot_inset, y + dot + dot_inset, dot)
        end
    end

    if marker then
        local marker_key = tostring(marker)
        local marker_fill = marker_layout.fill_color or {0.58, 0.34, 0.16}
        local marker_text_normal = marker_layout.text_color_normal or {0.94, 0.86, 0.62, 1}
        local marker_text_hc = marker_layout.text_color_high_contrast or {0.98, 0.92, 0.70, 1}
        local marker_text = high_contrast and marker_text_hc or marker_text_normal
        local marker_text_rect = marker_layout.text_rect or {}
        love.graphics.setColor(marker_fill[1] or 0.58, marker_fill[2] or 0.34, marker_fill[3] or 0.16, marker_layout.fill_alpha or 0.92)
        love.graphics.circle("fill", x + RuntimeUI.sized(marker_layout.x or 6), y + RuntimeUI.sized(marker_layout.y or 6), RuntimeUI.sized(marker_layout.radius or 5))
        love.graphics.setColor(marker_text[1] or 0.94, marker_text[2] or 0.86, marker_text[3] or 0.62, marker_text[4] or 1)
        love.graphics.setFont(get_font(marker_layout.text_size or 9, false))
        love.graphics.printf(
            marker_key,
            x + RuntimeUI.sized(marker_text_rect.x or 1),
            y + RuntimeUI.sized(marker_text_rect.y or 1),
            RuntimeUI.sized(marker_text_rect.w or 10),
            "center"
        )
    end

    if visual and visual.dim then
        local dim_color = visual_dim_layout.color or {0.07, 0.05, 0.04}
        love.graphics.setColor(dim_color[1] or 0.07, dim_color[2] or 0.05, dim_color[3] or 0.04, visual_dim_layout.alpha or 0.52)
        love.graphics.rectangle(
            "fill",
            x + (visual_dim_layout.inset or 1),
            y + (visual_dim_layout.inset or 1),
            size - (visual_dim_layout.inset_total or 2),
            size - (visual_dim_layout.inset_total or 2),
            visual_dim_layout.corner_radius or 2,
            visual_dim_layout.corner_radius or 2
        )
    end

    if visual and visual.closed_row and not placed then
        local closed_fill = visual_closed_row_layout.fill_color or {0.10, 0.09, 0.08}
        local closed_line = visual_closed_row_layout.line_color or {0.50, 0.40, 0.28}
        love.graphics.setColor(closed_fill[1] or 0.10, closed_fill[2] or 0.09, closed_fill[3] or 0.08, visual_closed_row_layout.fill_alpha or 0.90)
        love.graphics.rectangle(
            "fill",
            x + (visual_closed_row_layout.fill_inset or 1),
            y + (visual_closed_row_layout.fill_inset or 1),
            size - (visual_closed_row_layout.fill_inset_total or 2),
            size - (visual_closed_row_layout.fill_inset_total or 2),
            visual_closed_row_layout.fill_corner_radius or 2,
            visual_closed_row_layout.fill_corner_radius or 2
        )
        love.graphics.setColor(closed_line[1] or 0.50, closed_line[2] or 0.40, closed_line[3] or 0.28, visual_closed_row_layout.line_alpha or 0.36)
        love.graphics.setLineWidth(visual_closed_row_layout.line_width or 2)
        local line_inset = RuntimeUI.sized(visual_closed_row_layout.line_x_inset or 4)
        love.graphics.line(x + line_inset, y + size * 0.5, x + size - line_inset, y + size * 0.5)
        love.graphics.setLineWidth(1)
    end

    if visual and visual.highlight then
        local pulse_speed = visual_highlight_layout.pulse_speed or 5.0
        local pulse = (love.timer and love.timer.getTime and (0.5 + 0.5 * math.sin(love.timer.getTime() * pulse_speed))) or 0.5
        local highlight_fill = visual_highlight_layout.fill_color or {0.98, 0.86, 0.56}
        local highlight_line = visual_highlight_layout.line_color or {0.98, 0.84, 0.52}
        love.graphics.setColor(
            highlight_fill[1] or 0.98,
            highlight_fill[2] or 0.86,
            highlight_fill[3] or 0.56,
            (visual_highlight_layout.fill_alpha_base or 0.34) + pulse * (visual_highlight_layout.fill_alpha_pulse or 0.22)
        )
        love.graphics.rectangle(
            "fill",
            x + (visual_highlight_layout.inset or 1),
            y + (visual_highlight_layout.inset or 1),
            size - (visual_highlight_layout.inset_total or 2),
            size - (visual_highlight_layout.inset_total or 2),
            visual_highlight_layout.corner_radius or 3,
            visual_highlight_layout.corner_radius or 3
        )
        love.graphics.setColor(
            highlight_line[1] or 0.98,
            highlight_line[2] or 0.84,
            highlight_line[3] or 0.52,
            (visual_highlight_layout.line_alpha_base or 0.80) + pulse * (visual_highlight_layout.line_alpha_pulse or 0.18)
        )
        love.graphics.setLineWidth(visual_highlight_layout.line_width or 4)
        love.graphics.rectangle(
            "line",
            x + (visual_highlight_layout.inset or 1),
            y + (visual_highlight_layout.inset or 1),
            size - (visual_highlight_layout.inset_total or 2),
            size - (visual_highlight_layout.inset_total or 2),
            visual_highlight_layout.corner_radius or 3,
            visual_highlight_layout.corner_radius or 3
        )
        love.graphics.setLineWidth(1)
    end

    if visual and visual.hover_preview and not placed then
        local hover_fill = visual_hover_preview_layout.fill_color or {0.96, 0.90, 0.72}
        local hover_dot = visual_hover_preview_layout.dot or {}
        local hover_dot_fill = hover_dot.fill_color or {0.96, 0.90, 0.70}
        local hover_dot_line = hover_dot.line_color or {0.32, 0.22, 0.12}
        love.graphics.setColor(hover_fill[1] or 0.96, hover_fill[2] or 0.90, hover_fill[3] or 0.72, visual_hover_preview_layout.fill_alpha or 0.18)
        love.graphics.rectangle(
            "fill",
            x + (visual_hover_preview_layout.fill_inset or 2),
            y + (visual_hover_preview_layout.fill_inset or 2),
            size - (visual_hover_preview_layout.fill_inset_total or 4),
            size - (visual_hover_preview_layout.fill_inset_total or 4),
            visual_hover_preview_layout.fill_corner_radius or 3,
            visual_hover_preview_layout.fill_corner_radius or 3
        )
        local dot = math.max(hover_dot.radius_min or 3, math.floor(size * (hover_dot.radius_ratio or 0.11)))
        local dot_inset = hover_dot.inset or 4
        love.graphics.setColor(hover_dot_fill[1] or 0.96, hover_dot_fill[2] or 0.90, hover_dot_fill[3] or 0.70, hover_dot.fill_alpha or 0.90)
        love.graphics.circle("fill", x + size - dot - dot_inset, y + size - dot - dot_inset, dot)
        love.graphics.setColor(hover_dot_line[1] or 0.32, hover_dot_line[2] or 0.22, hover_dot_line[3] or 0.12, hover_dot.line_alpha or 0.82)
        love.graphics.circle("line", x + size - dot - dot_inset, y + size - dot - dot_inset, dot)
    end

    if visual and visual.preview and not placed then
        local quality = visual.preview.quality_gain or 0
        local risk = visual.preview.risk_gain or 0
        local txt = tr(MODULE_UI.tile_preview_delta, {
            quality = quality,
            risk = risk,
        })
        local preview_bg = visual_preview_layout.bg_color or {0.10, 0.08, 0.06}
        local text_color = visual_preview_layout.text_color or {0.96, 0.90, 0.78}
        love.graphics.setColor(preview_bg[1] or 0.10, preview_bg[2] or 0.08, preview_bg[3] or 0.06, visual_preview_layout.bg_alpha or 0.78)
        love.graphics.rectangle(
            "fill",
            x + (visual_preview_layout.bg_x_inset or 2),
            y + size - RuntimeUI.sized(visual_preview_layout.bg_y_offset or 13),
            size - (visual_preview_layout.bg_width_inset or 4),
            RuntimeUI.sized(visual_preview_layout.bg_height or 11),
            visual_preview_layout.bg_corner_radius or 2,
            visual_preview_layout.bg_corner_radius or 2
        )
        love.graphics.setFont(get_font(
            math.max(visual_preview_layout.text_size_min or 7, math.floor(size * (visual_preview_layout.text_size_ratio or 0.14))),
            false
        ))
        love.graphics.setColor(text_color[1] or 0.96, text_color[2] or 0.90, text_color[3] or 0.78, visual_preview_layout.text_alpha or 0.96)
        love.graphics.printf(
            txt,
            x + (visual_preview_layout.bg_x_inset or 2),
            y + size - RuntimeUI.sized(visual_preview_layout.text_y_offset or 12),
            size - (visual_preview_layout.bg_width_inset or 4),
            "center"
        )
    end

    if visual and visual.stained and not placed then
        local stained_overlay = visual_stained_layout.overlay_color or {0.14, 0.08, 0.06}
        local blot_color = visual_stained_layout.blot_color or {0.54, 0.18, 0.14}
        local blot_a = visual_stained_layout.blot_a or {x = 0.38, y = 0.40, r = 1.00}
        local blot_b = visual_stained_layout.blot_b or {x = 0.62, y = 0.56, r = 0.85}
        local blot_c = visual_stained_layout.blot_c or {x = 0.52, y = 0.32, r = 0.65}
        love.graphics.setColor(stained_overlay[1] or 0.14, stained_overlay[2] or 0.08, stained_overlay[3] or 0.06, visual_stained_layout.overlay_alpha or 0.50)
        love.graphics.rectangle(
            "fill",
            x + (visual_stained_layout.overlay_inset or 1),
            y + (visual_stained_layout.overlay_inset or 1),
            size - (visual_stained_layout.overlay_inset_total or 2),
            size - (visual_stained_layout.overlay_inset_total or 2),
            visual_stained_layout.overlay_corner_radius or 2,
            visual_stained_layout.overlay_corner_radius or 2
        )
        local blot_r = math.max(visual_stained_layout.blot_radius_min or 4, math.floor(size * (visual_stained_layout.blot_radius_ratio or 0.18)))
        love.graphics.setColor(blot_color[1] or 0.54, blot_color[2] or 0.18, blot_color[3] or 0.14, visual_stained_layout.blot_alpha or 0.86)
        love.graphics.circle("fill", x + size * (blot_a.x or 0.38), y + size * (blot_a.y or 0.40), blot_r * (blot_a.r or 1.00))
        love.graphics.circle("fill", x + size * (blot_b.x or 0.62), y + size * (blot_b.y or 0.56), blot_r * (blot_b.r or 0.85))
        love.graphics.circle("fill", x + size * (blot_c.x or 0.52), y + size * (blot_c.y or 0.32), blot_r * (blot_c.r or 0.65))
    end

    if visual and visual.stain_choice then
        local pulse_speed = visual_stain_choice_layout.pulse_speed or 4.5
        local pulse = (love.timer and love.timer.getTime and (0.5 + 0.5 * math.sin(love.timer.getTime() * pulse_speed))) or 0.5
        local stain_choice_fill = visual_stain_choice_layout.fill_color or {0.88, 0.30, 0.20}
        local stain_choice_line = visual_stain_choice_layout.line_color or {0.96, 0.46, 0.30}
        love.graphics.setColor(
            stain_choice_fill[1] or 0.88,
            stain_choice_fill[2] or 0.30,
            stain_choice_fill[3] or 0.20,
            (visual_stain_choice_layout.fill_alpha_base or 0.20) + pulse * (visual_stain_choice_layout.fill_alpha_pulse or 0.20)
        )
        love.graphics.rectangle(
            "fill",
            x + (visual_stain_choice_layout.inset or 1),
            y + (visual_stain_choice_layout.inset or 1),
            size - (visual_stain_choice_layout.inset_total or 2),
            size - (visual_stain_choice_layout.inset_total or 2),
            visual_stain_choice_layout.corner_radius or 3,
            visual_stain_choice_layout.corner_radius or 3
        )
        love.graphics.setColor(
            stain_choice_line[1] or 0.96,
            stain_choice_line[2] or 0.46,
            stain_choice_line[3] or 0.30,
            (visual_stain_choice_layout.line_alpha_base or 0.62) + pulse * (visual_stain_choice_layout.line_alpha_pulse or 0.28)
        )
        love.graphics.setLineWidth(visual_stain_choice_layout.line_width or 3)
        love.graphics.rectangle(
            "line",
            x + (visual_stain_choice_layout.inset or 1),
            y + (visual_stain_choice_layout.inset or 1),
            size - (visual_stain_choice_layout.inset_total or 2),
            size - (visual_stain_choice_layout.inset_total or 2),
            visual_stain_choice_layout.corner_radius or 3,
            visual_stain_choice_layout.corner_radius or 3
        )
        love.graphics.setLineWidth(1)
    end
end

local function resolve_panel_rect(bg, def)
    if def.screen_space then
        return {x = def.x, y = def.y, w = def.w, h = def.h}
    end
    return project_rect(bg, def.x, def.y, def.w, def.h)
end

function Scriptorium:drawZoneGrid(bg, zone, high_contrast)
    if not self.run or not self.run.current_folio then
        return
    end
    local folio = self.run.current_folio
    local elem = folio.elements[zone.element]
    if not elem then
        return
    end

    local panel_layout = ZONE_GRID_LAYOUT.panel or {}
    local best_outline_layout = ZONE_GRID_LAYOUT.best_outline or {}
    local title_layout = ZONE_GRID_LAYOUT.title or {}
    local grid_layout = ZONE_GRID_LAYOUT.grid or {}
    local stain_hint_layout = ZONE_GRID_LAYOUT.stain_hint or {}
    local row_stripe_layout = ZONE_GRID_LAYOUT.row_stripe or {}
    local row_open_line_layout = row_stripe_layout.open_center_line or {}
    local row_ruling_layout = row_stripe_layout.ruling_anim or {}
    local row_closed_overlay_layout = row_stripe_layout.closed_overlay or {}
    local row_hatch_layout = row_stripe_layout.hatch or {}
    local guided_holes_layout = ZONE_GRID_LAYOUT.guided_holes or {}
    local row_rules_badge_layout = ZONE_GRID_LAYOUT.row_rules_badge or {}
    local blocked_icon_layout = ZONE_GRID_LAYOUT.blocked_icon or {}
    local locked_zone_layout = ZONE_GRID_LAYOUT.locked_zone or {}

    local function rgba(source, fallback)
        source = source or fallback
        return {
            source[1] or fallback[1],
            source[2] or fallback[2],
            source[3] or fallback[3],
            source[4] or fallback[4],
        }
    end

    local rect = zone.rect
    local hover = point_in_rect(self.mouse_x, self.mouse_y, rect)
    local focus = self.current_focus
    local spotlight = focus and focus.active
    local zone_focus = spotlight and focus.legal_by_element and focus.legal_by_element[zone.element] or nil
    local zone_has_legal = zone_focus and zone_focus.count and zone_focus.count > 0
    local zone_is_best = spotlight and focus.best_element == zone.element
    local zone_dim = spotlight and (not zone_has_legal)

    local fill_alpha = hover
        and (panel_layout.fill_alpha_hover or 0.24)
        or (panel_layout.fill_alpha_normal or 0.16)
    local line_alpha = hover
        and (panel_layout.line_alpha_hover or 0.62)
        or (panel_layout.line_alpha_normal or 0.44)
    if zone_dim then
        fill_alpha = panel_layout.fill_alpha_dim or 0.08
        line_alpha = panel_layout.line_alpha_dim or 0.24
    elseif zone_has_legal then
        fill_alpha = math.max(fill_alpha, panel_layout.fill_alpha_legal_min or 0.28)
        line_alpha = math.max(line_alpha, panel_layout.line_alpha_legal_min or 0.58)
    end

    local panel_fill = panel_layout.fill_color or {0.20, 0.14, 0.09}
    local panel_line = panel_layout.line_color or {0.64, 0.47, 0.30}
    local panel_corner = panel_layout.corner_radius or 6
    love.graphics.setColor(panel_fill[1] or 0.20, panel_fill[2] or 0.14, panel_fill[3] or 0.09, fill_alpha)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, panel_corner, panel_corner)
    love.graphics.setColor(panel_line[1] or 0.64, panel_line[2] or 0.47, panel_line[3] or 0.30, line_alpha)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, panel_corner, panel_corner)
    if zone_is_best then
        local best_color = best_outline_layout.color or {0.96, 0.84, 0.54}
        love.graphics.setColor(
            best_color[1] or 0.96,
            best_color[2] or 0.84,
            best_color[3] or 0.54,
            best_outline_layout.alpha or 0.80
        )
        love.graphics.setLineWidth(best_outline_layout.line_width or 2)
        love.graphics.rectangle(
            "line",
            rect.x - RuntimeUI.sized(best_outline_layout.inset or 2),
            rect.y - RuntimeUI.sized(best_outline_layout.inset or 2),
            rect.w + RuntimeUI.sized(best_outline_layout.inset_total or 4),
            rect.h + RuntimeUI.sized(best_outline_layout.inset_total or 4),
            best_outline_layout.corner_radius or 7,
            best_outline_layout.corner_radius or 7
        )
        love.graphics.setLineWidth(1)
    end

    if zone.show_title ~= false then
        local title_rect = {
            x = rect.x,
            y = rect.y - RuntimeUI.sized(title_layout.y_offset or 24),
            w = rect.w,
            h = RuntimeUI.sized(title_layout.height or 18),
        }
        local title_color = zone_dim
            and (title_layout.color_dim or {0.50, 0.38, 0.24, 0.70})
            or (title_layout.color or {0.70, 0.51, 0.30, 1})
        draw_text_center(zone.title, title_rect, get_font(title_layout.text_size or 15, false), title_color)
    end

    local rows = elem.pattern.rows or 4
    local cols = elem.pattern.cols or 5
    local gap = math.max(grid_layout.gap_min or 3, math.floor(rect.w * (grid_layout.gap_ratio or 0.006)))
    local side_pad = math.floor(rect.w * (grid_layout.side_padding_ratio or 0.012))
    local top_pad = math.floor(rect.h * (grid_layout.top_padding_ratio or 0.02))
    local small_rows_threshold = grid_layout.small_rows_threshold or 2
    local bottom_ratio = (rows <= small_rows_threshold)
        and (grid_layout.bottom_padding_ratio_small_rows or 0.05)
        or (grid_layout.bottom_padding_ratio_default or 0.06)
    local bottom_pad = math.floor(rect.h * bottom_ratio)
    local usable_w = rect.w - side_pad * 2
    local usable_h = rect.h - top_pad - bottom_pad
    local cell = math.floor(math.min((usable_w - gap * (cols - 1)) / cols, (usable_h - gap * (rows - 1)) / rows))
    local min_cell = RuntimeUI.sized(grid_layout.min_cell or 20)
    if cell < min_cell then
        cell = min_cell
    end
    local grid_w = cell * cols + gap * (cols - 1)
    local grid_h = cell * rows + gap * (rows - 1)
    local gx = rect.x + (rect.w - grid_w) * 0.5
    local gy = rect.y + top_pad + math.max(0, (usable_h - grid_h) * 0.5)
    local selected_die = self.getSelectedDie and self:getSelectedDie() or nil
    local stain_pick = (self.state == "stain_pick") and (type(self.pending_stain_choices) == "table") and (#self.pending_stain_choices > 0)
    local stain_choice_map = {}
    if stain_pick then
        for _, choice in ipairs(self.pending_stain_choices) do
            if choice and choice.element == zone.element then
                stain_choice_map[tostring(choice.row) .. ":" .. tostring(choice.col)] = choice
            end
        end
    end
    if stain_pick then
        local stain_hint = {
            x = rect.x + RuntimeUI.sized(stain_hint_layout.x_padding or 10),
            y = rect.y + RuntimeUI.sized(stain_hint_layout.y_offset or 6),
            w = rect.w - RuntimeUI.sized(stain_hint_layout.width_padding or 20),
            h = RuntimeUI.sized(stain_hint_layout.height or 20),
        }
        local stain_hint_fill = stain_hint_layout.fill_color or {0.30, 0.10, 0.08}
        local stain_hint_line = stain_hint_layout.line_color or {0.88, 0.42, 0.30}
        local stain_hint_corner = stain_hint_layout.corner_radius or 5
        love.graphics.setColor(
            stain_hint_fill[1] or 0.30,
            stain_hint_fill[2] or 0.10,
            stain_hint_fill[3] or 0.08,
            stain_hint_layout.fill_alpha or 0.88
        )
        love.graphics.rectangle("fill", stain_hint.x, stain_hint.y, stain_hint.w, stain_hint.h, stain_hint_corner, stain_hint_corner)
        love.graphics.setColor(
            stain_hint_line[1] or 0.88,
            stain_hint_line[2] or 0.42,
            stain_hint_line[3] or 0.30,
            stain_hint_layout.line_alpha or 0.78
        )
        love.graphics.rectangle("line", stain_hint.x, stain_hint.y, stain_hint.w, stain_hint.h, stain_hint_corner, stain_hint_corner)
        draw_text_center(
            tr(MODULE_UI.stain_pick_hint),
            stain_hint,
            get_font(stain_hint_layout.text_size or 12, false),
            stain_hint_layout.text_color or {0.98, 0.88, 0.82, 1}
        )
    end

    for row = 1, rows do
        local row_open = folio.isRowOpen and folio:isRowOpen(row) or true
        local is_guided = folio.isGuidedRow and folio:isGuidedRow(row) or false
        local row_y = gy + (row - 1) * (cell + gap)
        local stripe_x = gx - RuntimeUI.sized(row_stripe_layout.x_expand or 2)
        local stripe_y = row_y - RuntimeUI.sized(row_stripe_layout.y_expand or 1)
        local stripe_w = grid_w + RuntimeUI.sized(row_stripe_layout.w_expand or 4)
        local stripe_h = cell + RuntimeUI.sized(row_stripe_layout.h_expand or 2)
        local stripe_fill
        local stripe_line
        local pulse = 0
        if row_open and love.timer and love.timer.getTime then
            pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * (row_stripe_layout.pulse_speed or 2.2) + row)
        end
        if row_open then
            stripe_fill = rgba(row_stripe_layout.open_fill, {0.56, 0.42, 0.24, 0.64})
            stripe_line = rgba(row_stripe_layout.open_line, {1.00, 0.88, 0.64, 0.88})
        elseif is_guided then
            stripe_fill = rgba(row_stripe_layout.guided_fill, {0.20, 0.15, 0.10, 0.42})
            stripe_line = rgba(row_stripe_layout.guided_line, {0.78, 0.60, 0.40, 0.52})
        else
            stripe_fill = rgba(row_stripe_layout.closed_fill, {0.08, 0.07, 0.06, 0.62})
            stripe_line = rgba(row_stripe_layout.closed_line, {0.32, 0.25, 0.18, 0.22})
        end
        if stain_pick then
            local stain_pick_scale = row_stripe_layout.stain_pick_alpha_scale or 0.82
            stripe_fill[4] = stripe_fill[4] * stain_pick_scale
            stripe_line[4] = stripe_line[4] * stain_pick_scale
        end
        if row_open then
            local open_glow_color = row_stripe_layout.open_glow_color or {0.99, 0.92, 0.70}
            local open_glow_expand = row_stripe_layout.open_glow_expand or {}
            local glow_alpha = (row_stripe_layout.open_glow_alpha_base or 0.18)
                + (row_stripe_layout.open_glow_alpha_pulse or 0.12) * pulse
            love.graphics.setColor(
                open_glow_color[1] or 0.99,
                open_glow_color[2] or 0.92,
                open_glow_color[3] or 0.70,
                glow_alpha
            )
            love.graphics.rectangle(
                "fill",
                stripe_x - RuntimeUI.sized(open_glow_expand.x or 4),
                row_y - RuntimeUI.sized(open_glow_expand.y or 5),
                stripe_w + RuntimeUI.sized(open_glow_expand.w or 8),
                stripe_h + RuntimeUI.sized(open_glow_expand.h or 10),
                row_stripe_layout.open_glow_corner_radius or 6,
                row_stripe_layout.open_glow_corner_radius or 6
            )
        end
        love.graphics.setColor(stripe_fill[1], stripe_fill[2], stripe_fill[3], stripe_fill[4])
        love.graphics.rectangle("fill", stripe_x, stripe_y, stripe_w, stripe_h, row_stripe_layout.corner_radius or 4, row_stripe_layout.corner_radius or 4)
        love.graphics.setColor(stripe_line[1], stripe_line[2], stripe_line[3], stripe_line[4])
        love.graphics.rectangle("line", stripe_x, stripe_y, stripe_w, stripe_h, row_stripe_layout.corner_radius or 4, row_stripe_layout.corner_radius or 4)

        if row_open then
            local open_line_color = row_open_line_layout.color or {0.98, 0.92, 0.76}
            love.graphics.setColor(
                open_line_color[1] or 0.98,
                open_line_color[2] or 0.92,
                open_line_color[3] or 0.76,
                (row_open_line_layout.alpha_base or 0.40) + (row_open_line_layout.alpha_pulse or 0.10) * pulse
            )
            love.graphics.setLineWidth(row_open_line_layout.line_width or 2)
            local line_y = row_y + cell * 0.5
            local x_inset = RuntimeUI.sized(row_open_line_layout.x_inset or 2)
            love.graphics.line(gx + x_inset, line_y, gx + grid_w - x_inset, line_y)
            love.graphics.setLineWidth(1)
        end
        if row_open and self.row_ruling_animations and self.row_ruling_animations[row] and love.timer and love.timer.getTime then
            local t = love.timer.getTime() - (self.row_ruling_animations[row] or 0)
            local duration = row_ruling_layout.duration or 0.7
            if t > duration then
                self.row_ruling_animations[row] = nil
            else
                local p = math.max(0, math.min(1, t / duration))
                local line_y = row_y + cell * 0.5
                local x1 = gx + RuntimeUI.sized(row_ruling_layout.x_start_inset or 4)
                local x2 = x1 + (grid_w - RuntimeUI.sized(row_ruling_layout.x_end_inset or 8)) * p
                local ruling_color = row_ruling_layout.color or {0.98, 0.92, 0.70}
                love.graphics.setColor(
                    ruling_color[1] or 0.98,
                    ruling_color[2] or 0.92,
                    ruling_color[3] or 0.70,
                    row_ruling_layout.alpha or 0.68
                )
                love.graphics.setLineWidth(row_ruling_layout.line_width or 2)
                love.graphics.line(x1, line_y, x2, line_y)
                love.graphics.setLineWidth(1)
            end
        end
        if not row_open then
            local closed_overlay_color = row_closed_overlay_layout.color or {0.08, 0.07, 0.06}
            love.graphics.setColor(
                closed_overlay_color[1] or 0.08,
                closed_overlay_color[2] or 0.07,
                closed_overlay_color[3] or 0.06,
                row_closed_overlay_layout.alpha or 0.70
            )
            love.graphics.rectangle("fill", stripe_x, stripe_y, stripe_w, stripe_h, row_stripe_layout.corner_radius or 4, row_stripe_layout.corner_radius or 4)
            local hatch_color = row_hatch_layout.color or {0.22, 0.18, 0.14}
            love.graphics.setColor(
                hatch_color[1] or 0.22,
                hatch_color[2] or 0.18,
                hatch_color[3] or 0.14,
                row_hatch_layout.alpha or 0.26
            )
            local hatch_step = math.max(row_hatch_layout.step_min or 8, math.floor(cell * (row_hatch_layout.step_ratio or 0.45)))
            local hatch_inset = RuntimeUI.sized(row_hatch_layout.inset or 6)
            local hatch_bottom = RuntimeUI.sized(row_hatch_layout.bottom_inset or 2)
            for hx = stripe_x + hatch_inset, stripe_x + stripe_w - hatch_inset, hatch_step do
                love.graphics.line(hx, row_y, hx - hatch_inset, row_y + stripe_h - hatch_bottom)
            end
        end

        if is_guided then
            local hole_r = math.max(guided_holes_layout.radius_min or 3, math.floor(cell * (guided_holes_layout.radius_ratio or 0.12)))
            local hole_y = row_y + cell * 0.5
            local left_x = gx - RuntimeUI.sized(guided_holes_layout.side_offset or 10)
            local right_x = gx + grid_w + RuntimeUI.sized(guided_holes_layout.side_offset or 10)
            local hole_fill = guided_holes_layout.fill_color or {0.08, 0.06, 0.05}
            local hole_line = guided_holes_layout.line_color or {1.00, 0.88, 0.62}
            local stitch_color = guided_holes_layout.stitch_color or {0.22, 0.15, 0.10}
            love.graphics.setColor(
                hole_fill[1] or 0.08,
                hole_fill[2] or 0.06,
                hole_fill[3] or 0.05,
                guided_holes_layout.fill_alpha or 0.96
            )
            love.graphics.circle("fill", left_x, hole_y, hole_r)
            love.graphics.circle("fill", right_x, hole_y, hole_r)
            love.graphics.setColor(
                hole_line[1] or 1.00,
                hole_line[2] or 0.88,
                hole_line[3] or 0.62,
                guided_holes_layout.line_alpha or 0.96
            )
            love.graphics.circle("line", left_x, hole_y, hole_r)
            love.graphics.circle("line", right_x, hole_y, hole_r)
            love.graphics.setColor(
                stitch_color[1] or 0.22,
                stitch_color[2] or 0.15,
                stitch_color[3] or 0.10,
                guided_holes_layout.stitch_alpha or 0.78
            )
            love.graphics.setLineWidth(1)
            love.graphics.line(
                left_x + hole_r + (guided_holes_layout.stitch_inner or 2),
                hole_y - (guided_holes_layout.stitch_y_top or 3),
                left_x + hole_r + RuntimeUI.sized(guided_holes_layout.stitch_outer or 10),
                hole_y - (guided_holes_layout.stitch_y_bottom or 1)
            )
            love.graphics.line(
                right_x - hole_r - (guided_holes_layout.stitch_inner or 2),
                hole_y - (guided_holes_layout.stitch_y_top or 3),
                right_x - hole_r - RuntimeUI.sized(guided_holes_layout.stitch_outer or 10),
                hole_y - (guided_holes_layout.stitch_y_bottom or 1)
            )
            love.graphics.setLineWidth(1)
        end

        local row_rules = folio.getRowRules and folio:getRowRules(row) or nil
        if row_rules and #row_rules > 0 then
            local labels = {}
            for _, rule in ipairs(row_rules) do
                local tag = rule and get_row_rule_label(rule.type) or nil
                if not tag and rule and rule.type then
                    tag = tostring(rule.type)
                end
                if tag then
                    labels[#labels + 1] = tag
                end
            end
            if #labels > 0 then
                local separator = tr(MODULE_UI.row_rules_separator)
                if separator == "" then
                    separator = " • "
                end
                local text = table.concat(labels, separator)
                local font = get_font(row_rules_badge_layout.font_size or 10, false)
                local text_w = font:getWidth(text)
                local badge_h = math.max(
                    RuntimeUI.sized(row_rules_badge_layout.height_min or 14),
                    math.floor(cell * (row_rules_badge_layout.height_ratio or 0.28))
                )
                local badge_w = text_w + RuntimeUI.sized(row_rules_badge_layout.width_padding or 12)
                local left_x = gx - RuntimeUI.sized(row_rules_badge_layout.hole_side_offset or 10)
                local badge_x = left_x - badge_w - RuntimeUI.sized(row_rules_badge_layout.x_gap or 8)
                local min_x = rect.x + RuntimeUI.sized(row_rules_badge_layout.min_x_padding or 6)
                if badge_x < min_x then
                    badge_x = min_x
                end
                local badge_y = row_y + math.floor((cell - badge_h) * 0.5)
                local badge_fill = row_rules_badge_layout.fill_color or {0.22, 0.16, 0.11}
                local badge_line = row_rules_badge_layout.line_color or {0.78, 0.60, 0.38}
                local badge_corner = row_rules_badge_layout.corner_radius or 4
                love.graphics.setColor(
                    badge_fill[1] or 0.22,
                    badge_fill[2] or 0.16,
                    badge_fill[3] or 0.11,
                    row_rules_badge_layout.fill_alpha or 0.86
                )
                love.graphics.rectangle("fill", badge_x, badge_y, badge_w, badge_h, badge_corner, badge_corner)
                love.graphics.setColor(
                    badge_line[1] or 0.78,
                    badge_line[2] or 0.60,
                    badge_line[3] or 0.38,
                    row_rules_badge_layout.line_alpha or 0.70
                )
                love.graphics.rectangle("line", badge_x, badge_y, badge_w, badge_h, badge_corner, badge_corner)
                love.graphics.setFont(font)
                local badge_text = row_rules_badge_layout.text_color or {0.96, 0.90, 0.80}
                love.graphics.setColor(
                    badge_text[1] or 0.96,
                    badge_text[2] or 0.90,
                    badge_text[3] or 0.80,
                    row_rules_badge_layout.text_alpha or 0.95
                )
                love.graphics.printf(text, badge_x, badge_y + math.floor((badge_h - font:getHeight()) * 0.5), badge_w, "center")
            end
        end

        for col = 1, cols do
            local index = (row - 1) * cols + col
            local cx = gx + (col - 1) * (cell + gap)
            local cy = row_y
            local constraint = elem.pattern.grid[index]
            local tile_key = elem.pattern.tile_keys and elem.pattern.tile_keys[index] or get_tile_key_for_constraint(constraint)
            local marker = elem.pattern.tile_markers and elem.pattern.tile_markers[index] or nil
            local placed = (elem.wet and elem.wet[index]) or elem.placed[index]
            local stained = elem.stained and elem.stained[index] or false
            local cell_rect = {x = cx, y = cy, w = cell, h = cell}
            if (not placed) and type(constraint) == "string" and point_in_rect(self.mouse_x, self.mouse_y, cell_rect) then
                self.hover_constraint_color = constraint
            end
            local key = tostring(row) .. ":" .. tostring(col)
            local preview = zone_focus and zone_focus.by_key and zone_focus.by_key[key] or nil
            local visual = nil
            local stain_choice = stain_choice_map[key]
            if stain_pick then
                if stain_choice and not placed then
                    visual = {stain_choice = true}
                    self.ui_hit.stain_choice_cells[#self.ui_hit.stain_choice_cells + 1] = {
                        element = zone.element,
                        row = row,
                        col = col,
                        index = stain_choice.index,
                        rect = cell_rect,
                    }
                else
                    visual = {dim = true}
                end
            else
                if spotlight then
                    if preview and elem.unlocked and (not elem.completed) then
                        visual = {highlight = true, preview = preview}
                        if selected_die and (not selected_die.used) then
                            local options = {}
                            if preview and preview.palette_colors then
                                for _, color in ipairs(preview.palette_colors) do
                                    options[#options + 1] = color
                                end
                            end
                            if point_in_rect(self.mouse_x, self.mouse_y, cell_rect) then
                                visual.hover_preview = true
                            end
                            self.ui_hit.placement_cells[#self.ui_hit.placement_cells + 1] = {
                                element = zone.element,
                                row = row,
                                col = col,
                                rect = cell_rect,
                                palette_options = options,
                            }
                        end
                    else
                        visual = {dim = true}
                    end
                end
                if not row_open and not placed then
                    visual = visual or {}
                    visual.closed_row = true
                end
            end
            if stained and not placed then
                visual = visual or {}
                visual.stained = true
            end
            self:drawTileCell(cx, cy, cell, constraint, marker, placed, tile_key, high_contrast, visual)

            if (not placed) and row_open and spotlight and (not preview) then
                local blocked = focus and focus.blocked_by_element and focus.blocked_by_element[zone.element] or nil
                local reason = blocked and blocked[key] or nil
                if reason then
                    local icon = reason == "value" and "≠"
                        or (reason == "color" and "●" or (reason == "ink" and "◉" or "↔"))
                    local font_size = math.max(
                        blocked_icon_layout.font_min or 9,
                        math.floor(cell * (blocked_icon_layout.font_ratio or 0.22))
                    )
                    local blocked_color = blocked_icon_layout.color or {0.88, 0.62, 0.42}
                    love.graphics.setFont(get_font(font_size, true))
                    love.graphics.setColor(
                        blocked_color[1] or 0.88,
                        blocked_color[2] or 0.62,
                        blocked_color[3] or 0.42,
                        blocked_icon_layout.alpha or 0.90
                    )
                    love.graphics.print(
                        icon,
                        cx + RuntimeUI.sized(blocked_icon_layout.x_offset or 3),
                        cy + RuntimeUI.sized(blocked_icon_layout.y_offset or 2)
                    )
                end
            end
        end
    end

    if not elem.unlocked then
        love.graphics.setColor(0.08, 0.08, 0.08, locked_zone_layout.alpha or 0.20)
        love.graphics.rectangle(
            "fill",
            rect.x,
            rect.y,
            rect.w,
            rect.h,
            locked_zone_layout.corner_radius or 6,
            locked_zone_layout.corner_radius or 6
        )
        local badge_size = RuntimeUI.sized(locked_zone_layout.badge_size or LOCK_BADGE_LAYOUT.size or 20)
        local bx = rect.x + rect.w - badge_size - RuntimeUI.sized(locked_zone_layout.badge_x_offset or 6)
        local by = rect.y + RuntimeUI.sized(locked_zone_layout.badge_y_offset or 6)
        local badge_fill = LOCK_BADGE_LAYOUT.fill_color or {0.28, 0.20, 0.12}
        local badge_line = LOCK_BADGE_LAYOUT.line_color or {0.75, 0.58, 0.36}
        local badge_icon = LOCK_BADGE_LAYOUT.icon_color or {0.93, 0.88, 0.76}
        love.graphics.setColor(
            badge_fill[1] or 0.28,
            badge_fill[2] or 0.20,
            badge_fill[3] or 0.12,
            LOCK_BADGE_LAYOUT.fill_alpha or 0.94
        )
        love.graphics.rectangle(
            "fill",
            bx,
            by,
            badge_size,
            badge_size,
            LOCK_BADGE_LAYOUT.corner_radius or 4,
            LOCK_BADGE_LAYOUT.corner_radius or 4
        )
        love.graphics.setColor(
            badge_line[1] or 0.75,
            badge_line[2] or 0.58,
            badge_line[3] or 0.36,
            LOCK_BADGE_LAYOUT.line_alpha or 0.86
        )
        love.graphics.rectangle(
            "line",
            bx,
            by,
            badge_size,
            badge_size,
            LOCK_BADGE_LAYOUT.corner_radius or 4,
            LOCK_BADGE_LAYOUT.corner_radius or 4
        )
        local cx = bx + badge_size * 0.5
        local cy = by + badge_size * 0.5
        local r = badge_size * (LOCK_BADGE_LAYOUT.icon_radius_ratio or 0.24)
        love.graphics.setColor(
            badge_icon[1] or 0.93,
            badge_icon[2] or 0.88,
            badge_icon[3] or 0.76,
            LOCK_BADGE_LAYOUT.icon_alpha or 0.95
        )
        love.graphics.setLineWidth(LOCK_BADGE_LAYOUT.icon_line_width or 2)
        love.graphics.arc(
            "line",
            "open",
            cx,
            cy - RuntimeUI.sized(LOCK_BADGE_LAYOUT.icon_arc_y_offset or 2),
            r,
            math.pi,
            math.pi * 2
        )
        love.graphics.rectangle(
            "line",
            cx - r,
            cy - RuntimeUI.sized(LOCK_BADGE_LAYOUT.icon_body_y_offset or 1),
            r * 2,
            r * (LOCK_BADGE_LAYOUT.icon_body_height_ratio or 1.25),
            LOCK_BADGE_LAYOUT.icon_corner_radius or 2,
            LOCK_BADGE_LAYOUT.icon_corner_radius or 2
        )
        love.graphics.setLineWidth(1)
        self.lock_badges[#self.lock_badges + 1] = {
            rect = {x = bx, y = by, w = badge_size, h = badge_size},
            text = get_unlock_tooltip(folio, zone.element),
        }
    end
end

function Scriptorium:drawUnifiedFolioOverview(page, high_contrast)
    if not self.run or not self.run.current_folio then
        return
    end
    local folio = self.run.current_folio
    local panel_layout = UNIFIED_OVERVIEW_LAYOUT.panel or {}
    local focus_overlay_layout = UNIFIED_OVERVIEW_LAYOUT.focus_overlay or {}
    local wet_overlay_layout = UNIFIED_OVERVIEW_LAYOUT.wet_overlay or {}
    local stain_overlay_layout = UNIFIED_OVERVIEW_LAYOUT.stain_overlay or {}
    local zones = self:getUnifiedZones(page)
    local zone = (zones and zones.main) or (zones and zones.ordered and zones.ordered[1]) or nil
    if not zone then
        return
    end

    local panel_fill = panel_layout.fill_color or {0.88, 0.80, 0.66}
    local panel_line = panel_layout.line_color or {0.62, 0.45, 0.28}
    local panel_fill_alpha = high_contrast and (panel_layout.fill_alpha_high_contrast or 0.66) or (panel_layout.fill_alpha_normal or 0.54)
    local panel_corner = panel_layout.corner_radius or 10
    love.graphics.setColor(panel_fill[1] or 0.88, panel_fill[2] or 0.80, panel_fill[3] or 0.66, panel_fill_alpha)
    love.graphics.rectangle("fill", page.x, page.y, page.w, page.h, panel_corner, panel_corner)
    love.graphics.setColor(panel_line[1] or 0.62, panel_line[2] or 0.45, panel_line[3] or 0.28, panel_layout.line_alpha or 0.58)
    love.graphics.rectangle("line", page.x, page.y, page.w, page.h, panel_corner, panel_corner)

    local focus = self.current_focus
    if focus and focus.active then
        local focus_color = focus_overlay_layout.color or {0.10, 0.08, 0.06}
        love.graphics.setColor(focus_color[1] or 0.10, focus_color[2] or 0.08, focus_color[3] or 0.06, focus_overlay_layout.alpha or 0.18)
        love.graphics.rectangle("fill", page.x, page.y, page.w, page.h, panel_corner, panel_corner)
    end

    self:drawZoneGrid(nil, zone, high_contrast)

    local wet_count = folio.getWetCount and folio:getWetCount() or 0
    local wet_max = math.max(1, math.floor(tonumber(folio.wet_buffer_max) or (wet_overlay_layout.wet_buffer_max_fallback or 3)))
    local wet_full = wet_count >= wet_max
    if wet_full then
        local pulse_speed = wet_overlay_layout.pulse_speed or 3.5
        local pulse = (love.timer and love.timer.getTime and (0.5 + 0.5 * math.sin(love.timer.getTime() * pulse_speed))) or 0.5
        local wet_color = wet_overlay_layout.color or {0.08, 0.06, 0.04}
        local wet_alpha = (wet_overlay_layout.base_alpha or 0.10) + pulse * (wet_overlay_layout.pulse_alpha or 0.08)
        love.graphics.setColor(wet_color[1] or 0.08, wet_color[2] or 0.06, wet_color[3] or 0.04, wet_alpha)
        love.graphics.rectangle("fill", page.x, page.y, page.w, page.h, panel_corner, panel_corner)
    end
    local stains = tonumber(folio.stain_count) or 0
    if stains > 0 then
        local stain_color = stain_overlay_layout.color or {0.35, 0.14, 0.10}
        local alpha = math.min(stain_overlay_layout.alpha_max or 0.22, stains * (stain_overlay_layout.alpha_per_stain or 0.04))
        love.graphics.setColor(stain_color[1] or 0.35, stain_color[2] or 0.14, stain_color[3] or 0.10, alpha)
        love.graphics.rectangle("fill", page.x, page.y, page.w, page.h, panel_corner, panel_corner)
    end
end

function Scriptorium:drawGridPanel(bg, def, high_contrast)
    if not self.run or not self.run.current_folio then
        return
    end

    local folio = self.run.current_folio
    local elem = folio.elements[def.element]
    if not elem then
        return
    end
    local panel_layout = GRID_PANEL_LAYOUT.panel or {}
    local title_tab_layout = GRID_PANEL_LAYOUT.title_tab or {}
    local grid_layout = GRID_PANEL_LAYOUT.grid or {}
    local completed_layout = GRID_PANEL_LAYOUT.completed or {}
    local locked_overlay_layout = GRID_PANEL_LAYOUT.locked_overlay or {}
    local badge_layout = LOCK_BADGE_LAYOUT or {}

    local panel = resolve_panel_rect(bg, def)
    local panel_line_color = panel_layout.line_color or {0.74, 0.55, 0.35}
    local panel_line_alpha = high_contrast
        and (panel_layout.line_alpha_high_contrast or 0.46)
        or (panel_layout.line_alpha_normal or 0.30)
    local panel_corner = panel_layout.corner_radius or 4
    love.graphics.setColor(
        panel_line_color[1] or 0.74,
        panel_line_color[2] or 0.55,
        panel_line_color[3] or 0.35,
        panel_line_alpha
    )
    love.graphics.setLineWidth(panel_layout.line_width or 1)
    love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, panel_corner, panel_corner)

    local title_font = get_font(title_tab_layout.text_size or 13, false)
    local tab_w = clamp(
        title_font:getWidth(def.title) + RuntimeUI.sized(title_tab_layout.width_padding or 22),
        RuntimeUI.sized(title_tab_layout.width_min or 110),
        panel.w * (title_tab_layout.width_max_ratio or 0.56)
    )
    local tab_h = RuntimeUI.sized(title_tab_layout.height or 24)
    local tab_fill = title_tab_layout.fill_color or {0.38, 0.27, 0.17}
    love.graphics.setColor(
        tab_fill[1] or 0.38,
        tab_fill[2] or 0.27,
        tab_fill[3] or 0.17,
        title_tab_layout.fill_alpha or 0.95
    )
    love.graphics.rectangle(
        "fill",
        panel.x + RuntimeUI.sized(title_tab_layout.x_offset or 6),
        panel.y + RuntimeUI.sized(title_tab_layout.y_offset or -10),
        tab_w,
        tab_h,
        title_tab_layout.corner_radius or 4,
        title_tab_layout.corner_radius or 4
    )
    draw_text_center(def.title, {
        x = panel.x + RuntimeUI.sized(title_tab_layout.x_offset or 6),
        y = panel.y + RuntimeUI.sized(title_tab_layout.text_y_offset or -8),
        w = tab_w,
        h = tab_h,
    }, title_font, title_tab_layout.text_color or {0.95, 0.86, 0.68, 1})

    local rows = elem.pattern.rows or 4
    local cols = elem.pattern.cols or 5
    local gap = math.max(grid_layout.gap_min or 4, math.floor(panel.w * (grid_layout.gap_ratio or 0.010)))
    local side_pad = math.floor(panel.w * (grid_layout.side_padding_ratio or 0.030))
    local top_pad = math.floor(panel.h * (grid_layout.top_padding_ratio or 0.10))
    local bottom_pad = math.floor(panel.h * (grid_layout.bottom_padding_ratio or 0.05))
    local usable_w = panel.w - side_pad * 2
    local usable_h = panel.h - top_pad - bottom_pad
    local cell = math.floor(math.min((usable_w - gap * (cols - 1)) / cols, (usable_h - gap * (rows - 1)) / rows))
    if cell < (grid_layout.min_cell or 8) then
        cell = grid_layout.min_cell or 8
    end
    local grid_w = cell * cols + gap * (cols - 1)
    local grid_h = cell * rows + gap * (rows - 1)
    local gx = panel.x + (panel.w - grid_w) * 0.5
    local gy = panel.y + top_pad + (usable_h - grid_h) * 0.5

    for row = 1, rows do
        for col = 1, cols do
            local index = (row - 1) * cols + col
            local cx = gx + (col - 1) * (cell + gap)
            local cy = gy + (row - 1) * (cell + gap)
            local constraint = elem.pattern.grid[index]
            local tile_key = elem.pattern.tile_keys and elem.pattern.tile_keys[index] or get_tile_key_for_constraint(constraint)
            local marker = elem.pattern.tile_markers and elem.pattern.tile_markers[index] or nil
            local placed = (elem.wet and elem.wet[index]) or elem.placed[index]
            self:drawTileCell(cx, cy, cell, constraint, marker, placed, tile_key, high_contrast)
        end
    end

    if elem.completed then
        draw_text_center(tr(MODULE_UI.overview_completed), {
            x = panel.x,
            y = panel.y + panel.h - RuntimeUI.sized(completed_layout.y_offset or 26),
            w = panel.w,
            h = RuntimeUI.sized(completed_layout.height or 20),
        }, get_font(completed_layout.text_size or 12, false), completed_layout.text_color or {0.48, 0.92, 0.62, 1})
    elseif not elem.unlocked then
        love.graphics.setColor(
            0.08,
            0.08,
            0.08,
            PROTOTYPE_NO_BACKGROUND
                and (locked_overlay_layout.alpha_prototype or 0.14)
                or (locked_overlay_layout.alpha_default or 0.32)
        )
        if PROTOTYPE_NO_BACKGROUND then
            love.graphics.rectangle(
                "fill",
                gx,
                gy,
                grid_w,
                grid_h,
                locked_overlay_layout.corner_radius or 3,
                locked_overlay_layout.corner_radius or 3
            )
        else
            love.graphics.rectangle(
                "fill",
                panel.x,
                panel.y,
                panel.w,
                panel.h,
                locked_overlay_layout.corner_radius or 3,
                locked_overlay_layout.corner_radius or 3
            )
        end

        local badge_size = RuntimeUI.sized(badge_layout.size or 22)
        local bx = gx + grid_w - badge_size - RuntimeUI.sized(locked_overlay_layout.badge_x_offset or 2)
        local by = gy + RuntimeUI.sized(locked_overlay_layout.badge_y_offset or 2)
        local badge_fill = badge_layout.fill_color or {0.28, 0.20, 0.12}
        local badge_line = badge_layout.line_color or {0.75, 0.58, 0.36}
        local badge_icon = badge_layout.icon_color or {0.93, 0.88, 0.76}
        love.graphics.setColor(
            badge_fill[1] or 0.28,
            badge_fill[2] or 0.20,
            badge_fill[3] or 0.12,
            badge_layout.fill_alpha or 0.94
        )
        love.graphics.rectangle(
            "fill",
            bx,
            by,
            badge_size,
            badge_size,
            badge_layout.corner_radius or 4,
            badge_layout.corner_radius or 4
        )
        love.graphics.setColor(
            badge_line[1] or 0.75,
            badge_line[2] or 0.58,
            badge_line[3] or 0.36,
            badge_layout.line_alpha or 0.86
        )
        love.graphics.rectangle(
            "line",
            bx,
            by,
            badge_size,
            badge_size,
            badge_layout.corner_radius or 4,
            badge_layout.corner_radius or 4
        )
        local cx = bx + badge_size * 0.5
        local cy = by + badge_size * 0.5
        local r = badge_size * (badge_layout.icon_radius_ratio or 0.24)
        love.graphics.setColor(
            badge_icon[1] or 0.93,
            badge_icon[2] or 0.88,
            badge_icon[3] or 0.76,
            badge_layout.icon_alpha or 0.95
        )
        love.graphics.setLineWidth(badge_layout.icon_line_width or 2)
        love.graphics.arc("line", "open", cx, cy - RuntimeUI.sized(badge_layout.icon_arc_y_offset or 2), r, math.pi, math.pi * 2)
        love.graphics.rectangle(
            "line",
            cx - r,
            cy - RuntimeUI.sized(badge_layout.icon_body_y_offset or 1),
            r * 2,
            r * (badge_layout.icon_body_height_ratio or 1.25),
            badge_layout.icon_corner_radius or 2,
            badge_layout.icon_corner_radius or 2
        )
        love.graphics.setLineWidth(1)

        self.lock_badges[#self.lock_badges + 1] = {
            rect = {x = bx, y = by, w = badge_size, h = badge_size},
            text = get_unlock_tooltip(folio, def.element),
        }
    end
end

function Scriptorium:drawOverviewCard(bg, def, high_contrast)
    if not self.run or not self.run.current_folio then
        return
    end

    local folio = self.run.current_folio
    local elem = folio.elements[def.element]
    if not elem then
        return
    end
    local panel_layout = OVERVIEW_CARD_LAYOUT.panel or {}
    local title_tab_layout = OVERVIEW_CARD_LAYOUT.title_tab or {}
    local grid_size_layout = OVERVIEW_CARD_LAYOUT.grid_size_label or {}
    local progress_bar_layout = OVERVIEW_CARD_LAYOUT.progress_bar or {}
    local progress_label_layout = OVERVIEW_CARD_LAYOUT.progress_label or {}
    local subtitle_layout = OVERVIEW_CARD_LAYOUT.subtitle or {}
    local locked_overlay_layout = OVERVIEW_CARD_LAYOUT.locked_overlay or {}
    local badge_layout = LOCK_BADGE_LAYOUT or {}

    local panel = resolve_panel_rect(bg, def)
    self.ui_hit.overview_cards[#self.ui_hit.overview_cards + 1] = {
        element = def.element,
        rect = panel,
    }

    local hover = point_in_rect(self.mouse_x, self.mouse_y, panel)
    local panel_fill = panel_layout.fill_color or {0.16, 0.11, 0.07}
    local panel_line = panel_layout.line_color or {0.74, 0.55, 0.35}
    local panel_fill_alpha = hover and (panel_layout.fill_alpha_hover or 0.34) or (panel_layout.fill_alpha_normal or 0.26)
    local panel_line_alpha = hover and (panel_layout.line_alpha_hover or 0.62) or (panel_layout.line_alpha_normal or 0.40)
    local panel_corner = panel_layout.corner_radius or 8
    love.graphics.setColor(panel_fill[1] or 0.16, panel_fill[2] or 0.11, panel_fill[3] or 0.07, panel_fill_alpha)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, panel_corner, panel_corner)
    love.graphics.setColor(panel_line[1] or 0.74, panel_line[2] or 0.55, panel_line[3] or 0.35, panel_line_alpha)
    love.graphics.setLineWidth(panel_layout.line_width or 1)
    love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, panel_corner, panel_corner)

    local title_font = get_font(title_tab_layout.text_size or 14, false)
    local tab_w = clamp(
        title_font:getWidth(def.title) + RuntimeUI.sized(title_tab_layout.width_padding or 24),
        RuntimeUI.sized(title_tab_layout.width_min or 120),
        panel.w * (title_tab_layout.width_max_ratio or 0.62)
    )
    local tab_h = RuntimeUI.sized(title_tab_layout.height or 26)
    local tab_fill = title_tab_layout.fill_color or {0.38, 0.27, 0.17}
    love.graphics.setColor(
        tab_fill[1] or 0.38,
        tab_fill[2] or 0.27,
        tab_fill[3] or 0.17,
        title_tab_layout.fill_alpha or 0.95
    )
    love.graphics.rectangle(
        "fill",
        panel.x + RuntimeUI.sized(title_tab_layout.x_offset or 8),
        panel.y + RuntimeUI.sized(title_tab_layout.y_offset or -12),
        tab_w,
        tab_h,
        title_tab_layout.corner_radius or 5,
        title_tab_layout.corner_radius or 5
    )
    draw_text_center(def.title, {
        x = panel.x + RuntimeUI.sized(title_tab_layout.x_offset or 8),
        y = panel.y + RuntimeUI.sized(title_tab_layout.text_y_offset or -10),
        w = tab_w,
        h = tab_h,
    }, title_font, title_tab_layout.text_color or {0.95, 0.86, 0.68, 1})

    local rows = elem.pattern.rows or 0
    local cols = elem.pattern.cols or 0
    draw_text_center(tr(MODULE_UI.overview_grid_size, {
        rows = rows,
        cols = cols,
    }), {
        x = panel.x,
        y = panel.y + RuntimeUI.sized(grid_size_layout.y_offset or 52),
        w = panel.w,
        h = RuntimeUI.sized(grid_size_layout.height or 22),
    }, get_font(grid_size_layout.text_size or 16, false), grid_size_layout.text_color or {0.93, 0.88, 0.78, 1})

    local filled, total = get_section_progress(elem)
    local ratio = total > 0 and (filled / total) or 0
    local bar_x = panel.x + RuntimeUI.sized(progress_bar_layout.x_padding or 22)
    local bar_w = panel.w - RuntimeUI.sized(progress_bar_layout.width_padding or 44)
    local bar_h = RuntimeUI.sized(progress_bar_layout.height or 14)
    local bar_y = panel.y + panel.h - RuntimeUI.sized(progress_bar_layout.y_offset or 52)
    local bar_corner = progress_bar_layout.corner_radius or 5
    local bar_bg = progress_bar_layout.bg_color or {0.19, 0.14, 0.10}
    local bar_fill = progress_bar_layout.fill_color or {0.68, 0.52, 0.33}
    local bar_line = progress_bar_layout.line_color or {0.82, 0.66, 0.46}
    love.graphics.setColor(bar_bg[1] or 0.19, bar_bg[2] or 0.14, bar_bg[3] or 0.10, progress_bar_layout.bg_alpha or 0.84)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_w, bar_h, bar_corner, bar_corner)
    love.graphics.setColor(bar_fill[1] or 0.68, bar_fill[2] or 0.52, bar_fill[3] or 0.33, progress_bar_layout.fill_alpha or 0.92)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_w * ratio, bar_h, bar_corner, bar_corner)
    love.graphics.setColor(bar_line[1] or 0.82, bar_line[2] or 0.66, bar_line[3] or 0.46, progress_bar_layout.line_alpha or 0.52)
    love.graphics.rectangle("line", bar_x, bar_y, bar_w, bar_h, bar_corner, bar_corner)
    draw_text_center(tr(MODULE_UI.overview_progress_ratio, {
        filled = filled,
        total = total,
    }), {
        x = panel.x,
        y = bar_y - RuntimeUI.sized(progress_label_layout.y_offset or 20),
        w = panel.w,
        h = RuntimeUI.sized(progress_label_layout.height or 16),
    }, get_font(progress_label_layout.text_size or 14, false), progress_label_layout.text_color or {0.96, 0.90, 0.80, 1})

    local subtitle = elem.completed and tr(MODULE_UI.overview_completed) or tr(MODULE_UI.overview_click_to_zoom)
    local subtitle_color = elem.completed
        and (subtitle_layout.completed_color or {0.48, 0.92, 0.62, 1})
        or (subtitle_layout.default_color or {0.94, 0.84, 0.62, 1})
    draw_text_center(subtitle, {
        x = panel.x,
        y = panel.y + panel.h - RuntimeUI.sized(subtitle_layout.y_offset or 30),
        w = panel.w,
        h = RuntimeUI.sized(subtitle_layout.height or 18),
    }, get_font(subtitle_layout.text_size or 12, false), subtitle_color)

    if not elem.unlocked then
        love.graphics.setColor(0.08, 0.08, 0.08, locked_overlay_layout.alpha or 0.28)
        love.graphics.rectangle(
            "fill",
            panel.x,
            panel.y,
            panel.w,
            panel.h,
            locked_overlay_layout.corner_radius or 8,
            locked_overlay_layout.corner_radius or 8
        )

        local badge_size = RuntimeUI.sized(badge_layout.size or 22)
        local bx = panel.x + panel.w - badge_size - RuntimeUI.sized(locked_overlay_layout.badge_x_offset or 8)
        local by = panel.y + RuntimeUI.sized(locked_overlay_layout.badge_y_offset or 8)
        local badge_fill = badge_layout.fill_color or {0.28, 0.20, 0.12}
        local badge_line = badge_layout.line_color or {0.75, 0.58, 0.36}
        local badge_icon = badge_layout.icon_color or {0.93, 0.88, 0.76}
        love.graphics.setColor(
            badge_fill[1] or 0.28,
            badge_fill[2] or 0.20,
            badge_fill[3] or 0.12,
            badge_layout.fill_alpha or 0.94
        )
        love.graphics.rectangle(
            "fill",
            bx,
            by,
            badge_size,
            badge_size,
            badge_layout.corner_radius or 4,
            badge_layout.corner_radius or 4
        )
        love.graphics.setColor(
            badge_line[1] or 0.75,
            badge_line[2] or 0.58,
            badge_line[3] or 0.36,
            badge_layout.line_alpha or 0.86
        )
        love.graphics.rectangle(
            "line",
            bx,
            by,
            badge_size,
            badge_size,
            badge_layout.corner_radius or 4,
            badge_layout.corner_radius or 4
        )
        local cx = bx + badge_size * 0.5
        local cy = by + badge_size * 0.5
        local r = badge_size * (badge_layout.icon_radius_ratio or 0.24)
        love.graphics.setColor(
            badge_icon[1] or 0.93,
            badge_icon[2] or 0.88,
            badge_icon[3] or 0.76,
            badge_layout.icon_alpha or 0.95
        )
        love.graphics.setLineWidth(badge_layout.icon_line_width or 2)
        love.graphics.arc("line", "open", cx, cy - RuntimeUI.sized(badge_layout.icon_arc_y_offset or 2), r, math.pi, math.pi * 2)
        love.graphics.rectangle(
            "line",
            cx - r,
            cy - RuntimeUI.sized(badge_layout.icon_body_y_offset or 1),
            r * 2,
            r * (badge_layout.icon_body_height_ratio or 1.25),
            badge_layout.icon_corner_radius or 2,
            badge_layout.icon_corner_radius or 2
        )
        love.graphics.setLineWidth(1)

        self.lock_badges[#self.lock_badges + 1] = {
            rect = {x = bx, y = by, w = badge_size, h = badge_size},
            text = get_unlock_tooltip(folio, def.element),
        }
    end
end

function Scriptorium:drawZoomHeader(zoom_panel, high_contrast)
    local back_layout = ZOOM_HEADER_LAYOUT.back or {}
    local info_layout = ZOOM_HEADER_LAYOUT.info or {}
    local back_width = RuntimeUI.sized(back_layout.width or 220)
    local back_height = RuntimeUI.sized(back_layout.height or 30)
    local back_corner = back_layout.corner_radius or 5
    local back_rect = {
        x = zoom_panel.x,
        y = zoom_panel.y - RuntimeUI.sized(back_layout.y_offset or 44),
        w = back_width,
        h = back_height,
    }
    self.ui_hit.zoom_back = back_rect
    local hover_back = point_in_rect(self.mouse_x, self.mouse_y, back_rect)
    local back_fill = back_layout.fill_color or {0.30, 0.21, 0.13}
    local back_line = back_layout.line_color or {0.72, 0.55, 0.35}
    local back_fill_alpha = hover_back and (back_layout.fill_alpha_hover or 0.94) or (back_layout.fill_alpha_normal or 0.84)
    love.graphics.setColor(back_fill[1] or 0.30, back_fill[2] or 0.21, back_fill[3] or 0.13, back_fill_alpha)
    love.graphics.rectangle("fill", back_rect.x, back_rect.y, back_rect.w, back_rect.h, back_corner, back_corner)
    love.graphics.setColor(back_line[1] or 0.72, back_line[2] or 0.55, back_line[3] or 0.35, back_layout.line_alpha or 0.66)
    love.graphics.rectangle("line", back_rect.x, back_rect.y, back_rect.w, back_rect.h, back_corner, back_corner)
    draw_text_center(
        tr(MODULE_UI.zoom_back_to_overview),
        back_rect,
        get_font(back_layout.text_size or 14, false),
        back_layout.text_color or {0.96, 0.90, 0.80, 1}
    )

    local folio = self.run and self.run.current_folio
    local elem = folio and folio.elements[zoom_panel.element] or nil
    if elem then
        local filled, total = get_section_progress(elem)
        local info_w = RuntimeUI.sized(info_layout.width or 240)
        local info_corner = info_layout.corner_radius or 5
        local info_rect = {
            x = zoom_panel.x + zoom_panel.w - info_w,
            y = back_rect.y,
            w = info_w,
            h = back_rect.h,
        }
        local info_fill = info_layout.fill_color or {0.30, 0.21, 0.13}
        local info_line = info_layout.line_color or {0.72, 0.55, 0.35}
        local info_fill_alpha = high_contrast
            and (info_layout.fill_alpha_high_contrast or 0.92)
            or (info_layout.fill_alpha_normal or 0.82)
        love.graphics.setColor(info_fill[1] or 0.30, info_fill[2] or 0.21, info_fill[3] or 0.13, info_fill_alpha)
        love.graphics.rectangle("fill", info_rect.x, info_rect.y, info_rect.w, info_rect.h, info_corner, info_corner)
        love.graphics.setColor(info_line[1] or 0.72, info_line[2] or 0.55, info_line[3] or 0.35, info_layout.line_alpha or 0.58)
        love.graphics.rectangle("line", info_rect.x, info_rect.y, info_rect.w, info_rect.h, info_corner, info_corner)
        draw_text_center(
            tr(MODULE_UI.zoom_progress, {
                filled = filled,
                total = total,
            }),
            info_rect,
            get_font(info_layout.text_size or 13, false),
            info_layout.text_color or {0.95, 0.86, 0.70, 1}
        )
    end
end

function Scriptorium:draw()
    local w, h = ui_dimensions()
    local high_contrast = RuntimeUI.high_contrast()
    ensure_bg()
    self.ui_hit = {}
    self.ui_hit.placement_cells = {}
    self.ui_hit.stain_choice_cells = {}
    self.ui_hit.setup_guided_rows = nil
    self.ui_hit.setup_initial_rows = nil
    self.ui_hit.inkwell_buttons = nil
    self.lock_badges = {}
    local mouse_sx, mouse_sy = love.mouse.getPosition()
    self.mouse_x, self.mouse_y = ResolutionManager.to_virtual(mouse_sx, mouse_sy)
    self.hovered_lock = nil
    self.hover_constraint_color = nil
    self.current_focus = self:buildPlacementFocus()

    local bg = get_bg_rect(w, h)
    local unified_page = self:getUnifiedPagePanel(w, h)
    local draw_panels = {
        {x = unified_page.x, y = unified_page.y, w = unified_page.w, h = unified_page.h, screen_space = true}
    }
    self.page_rect = unified_page

    ResolutionManager.begin_ui()
    self:drawBackground(bg, high_contrast)
    self:drawDiegeticWorkspace(draw_panels, high_contrast)
    self:drawStatusBar(bg, high_contrast, unified_page)
    self:drawUnifiedFolioOverview(unified_page, high_contrast)

    for _, badge in ipairs(self.lock_badges) do
        if point_in_rect(self.mouse_x, self.mouse_y, badge.rect) then
            self.hovered_lock = badge
            break
        end
    end

    self:drawStopPushControls(high_contrast)

    local instruction = self:getInstructions()
    if instruction and instruction ~= "" then
        local hint_color = HINT_BAR_LAYOUT.text_color_default or {0.96, 0.92, 0.86, 1}
        if self.state == "stain_pick" then
            hint_color = HINT_BAR_LAYOUT.text_color_stain_pick or {0.98, 0.82, 0.76, 1}
        elseif self.state == "placing" then
            hint_color = HINT_BAR_LAYOUT.text_color_placing or {0.96, 0.90, 0.80, 1}
        end
        local hint_rect = {
            x = 0,
            y = h - RuntimeUI.sized(HINT_BAR_LAYOUT.y_offset or 46),
            w = w,
            h = RuntimeUI.sized(HINT_BAR_LAYOUT.height or 36),
        }
        local hint_fill = HINT_BAR_LAYOUT.fill_color or {0.08, 0.06, 0.04}
        local hint_line = HINT_BAR_LAYOUT.line_color or {0.62, 0.48, 0.30}
        love.graphics.setColor(
            hint_fill[1] or 0.08,
            hint_fill[2] or 0.06,
            hint_fill[3] or 0.04,
            HINT_BAR_LAYOUT.fill_alpha or 0.82
        )
        love.graphics.rectangle("fill", hint_rect.x, hint_rect.y, hint_rect.w, hint_rect.h)
        love.graphics.setColor(
            hint_line[1] or 0.62,
            hint_line[2] or 0.48,
            hint_line[3] or 0.30,
            HINT_BAR_LAYOUT.line_alpha or 0.46
        )
        love.graphics.rectangle("line", hint_rect.x, hint_rect.y, hint_rect.w, hint_rect.h)
        draw_text_center(instruction, {
            x = hint_rect.x,
            y = hint_rect.y + RuntimeUI.sized(HINT_BAR_LAYOUT.text_y_offset or 8),
            w = hint_rect.w,
            h = RuntimeUI.sized(HINT_BAR_LAYOUT.text_height or 22),
        }, get_font(HINT_BAR_LAYOUT.text_size or 16, false), hint_color)
    end

    self:drawHoveredLockTooltip()
    self:drawMessageOverlay()
    self:drawRunSetupOverlay()
    self:drawRulingOverlay()
    self:drawFolioResultOverlay()
    ResolutionManager.end_ui()
end

Scriptorium.getControlsDockHeight = layout_methods.getControlsDockHeight
Scriptorium._getTrayRect = layout_methods._getTrayRect
Scriptorium.getUnifiedPagePanel = layout_methods.getUnifiedPagePanel
Scriptorium.getUnifiedZones = layout_methods.getUnifiedZones
Scriptorium.getZoomPanelLayout = layout_methods.getZoomPanelLayout

Scriptorium.drawStatusBar = hud_methods.drawStatusBar
Scriptorium.drawStopPushControls = hud_methods.drawStopPushControls

Scriptorium.drawMessageOverlay = overlay_methods.drawMessageOverlay
Scriptorium.drawRunSetupOverlay = overlay_methods.drawRunSetupOverlay
Scriptorium.drawRulingOverlay = overlay_methods.drawRulingOverlay
Scriptorium.drawFolioResultOverlay = overlay_methods.drawFolioResultOverlay
Scriptorium.drawHoveredLockTooltip = overlay_methods.drawHoveredLockTooltip

Scriptorium.requestRoll = ScriptoriumActions.requestRoll
Scriptorium.performPushAll = ScriptoriumActions.performPushAll
Scriptorium.performPushOne = ScriptoriumActions.performPushOne
Scriptorium.performStop = ScriptoriumActions.performStop
Scriptorium.performRestart = ScriptoriumActions.performRestart
Scriptorium.clearTurnPalette = ScriptoriumActions.clearTurnPalette
Scriptorium.getTurnPalette = ScriptoriumActions.getTurnPalette
Scriptorium.ensureTurnPalette = ScriptoriumActions.ensureTurnPalette
Scriptorium.getLegalPaletteColorsForPlacement = ScriptoriumActions.getLegalPaletteColorsForPlacement
Scriptorium.getRerollIndices = ScriptoriumActions.getRerollIndices
Scriptorium.getSelectedDie = ScriptoriumActions.getSelectedDie
Scriptorium.setSelectedDie = ScriptoriumActions.setSelectedDie
Scriptorium.setSelectedDieByRollIndex = ScriptoriumActions.setSelectedDieByRollIndex
Scriptorium.refreshDiceLegality = ScriptoriumActions.refreshDiceLegality
Scriptorium.autoSelectPlayableDie = ScriptoriumActions.autoSelectPlayableDie
Scriptorium._consumeUnusableDie = ScriptoriumActions.consumeUnusableDie
Scriptorium.performPreparation = ScriptoriumActions.performPreparation
Scriptorium.performSealReroll = ScriptoriumActions.performSealReroll
Scriptorium.performSealAdjust = ScriptoriumActions.performSealAdjust
Scriptorium.placeSelectedDieAt = ScriptoriumActions.placeSelectedDieAt
Scriptorium.autoPlaceDie = ScriptoriumActions.autoPlaceDie
Scriptorium.undoWetPlacement = ScriptoriumActions.undoWetPlacement
Scriptorium.toggleSetupGuidedRow = ScriptoriumActions.toggleSetupGuidedRow
Scriptorium.setSetupInitialRow = ScriptoriumActions.setSetupInitialRow
Scriptorium.applyParchmentSetup = ScriptoriumActions.applyParchmentSetup
Scriptorium.pickBustStainCell = ScriptoriumActions.pickBustStainCell
Scriptorium.pickInkRecoveryColor = ScriptoriumActions.pickInkRecoveryColor
Scriptorium.toggleRowState = ScriptoriumActions.toggleRowState
Scriptorium.onDiceSettled = ScriptoriumActions.onDiceSettled
Scriptorium.showMessage = ScriptoriumActions.showMessage
Scriptorium.getInstructions = ScriptoriumActions.getInstructions
Scriptorium.keypressed = ScriptoriumActions.keypressed
Scriptorium.mousepressed = ScriptoriumActions.mousepressed
Scriptorium.mousemoved = ScriptoriumActions.mousemoved
Scriptorium.wheelmoved = ScriptoriumActions.wheelmoved

return Scriptorium
