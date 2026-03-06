local I18n = require("src.core.i18n")
local Schema = require("src.core.schema")
local Colors = require("src.data.colors")
local ScriptoriumUISchema = require("src.data.scriptorium_ui_schema")

local Hud = {}

local function tr(entry, params)
    if type(entry) ~= "table" then
        return ""
    end
    return I18n.t(entry.key, entry.default, params)
end

local expect_table = Schema.expect_table
local expect_non_empty_list = Schema.expect_non_empty_list
local expect_number = Schema.expect_number
local expect_color3 = Schema.expect_color3
local expect_color4 = Schema.expect_color4

function Hud.new(deps)
    local RuntimeUI = deps.RuntimeUI
    local PROTOTYPE_NO_BACKGROUND = deps.PROTOTYPE_NO_BACKGROUND
    local HUD_LAYOUT = expect_table(deps.HUD_LAYOUT, "deps.HUD_LAYOUT")
    local project_rect = deps.project_rect
    local clamp = deps.clamp
    local point_in_rect = deps.point_in_rect
    local draw_text_center = deps.draw_text_center
    local get_font = deps.get_font
    local ui_dimensions = deps.ui_dimensions

    local DIE_COLOR_SWATCH = Colors.swatch
    local schema_colors = expect_table(ScriptoriumUISchema.colors, "ScriptoriumUISchema.colors")
    local COLOR_LABELS = expect_table(schema_colors.labels, "ScriptoriumUISchema.colors.labels")
    local INKWELL_ORDER = expect_non_empty_list(schema_colors.inkwell_order, "ScriptoriumUISchema.colors.inkwell_order")
    local COLOR_SHORT = expect_table(schema_colors.short, "ScriptoriumUISchema.colors.short")
    local STATUS_BAR_LAYOUT = expect_table(HUD_LAYOUT.status_bar, "deps.HUD_LAYOUT.status_bar")
    local MARGIN_NOTES_LAYOUT = expect_table(HUD_LAYOUT.margin_notes, "deps.HUD_LAYOUT.margin_notes")
    local CONTROLS_LAYOUT = expect_table(HUD_LAYOUT.controls, "deps.HUD_LAYOUT.controls")

    local function color_label(color_key)
        local entry = COLOR_LABELS[color_key]
        if entry then
            return tr(entry)
        end
        return tostring(color_key or "")
    end

    local function drops_to_dots(current, cap)
        local c = math.max(0, math.floor(tonumber(current) or 0))
        local m = math.max(c, math.floor(tonumber(cap) or 0))
        local list_empty = tr(ScriptoriumUISchema.hud.list_empty)
        if list_empty == "" then
            list_empty = "-"
        end
        if m <= 0 then
            return list_empty
        end
        local out = {}
        for i = 1, m do
            out[#out + 1] = (i <= c) and "●" or "○"
        end
        return table.concat(out, "")
    end

    local methods = {}

    function methods.drawStatusBar(self, bg, high_contrast, anchor_page)
        if not self.run or not self.run.current_folio then
            return
        end

        local stack_layout = expect_table(STATUS_BAR_LAYOUT.stack, "deps.HUD_LAYOUT.status_bar.stack")
        local stack_prototype_layout = expect_table(stack_layout.prototype, "deps.HUD_LAYOUT.status_bar.stack.prototype")
        local stack_default_rect_layout = expect_table(stack_layout.default_rect, "deps.HUD_LAYOUT.status_bar.stack.default_rect")
        local stats_panel_layout = expect_table(STATUS_BAR_LAYOUT.stats_panel, "deps.HUD_LAYOUT.status_bar.stats_panel")
        local header_layout = expect_table(STATUS_BAR_LAYOUT.header, "deps.HUD_LAYOUT.status_bar.header")
        local objective_badge_layout = expect_table(STATUS_BAR_LAYOUT.objective_badge, "deps.HUD_LAYOUT.status_bar.objective_badge")
        local inkwell_panel_layout = expect_table(STATUS_BAR_LAYOUT.inkwell_panel, "deps.HUD_LAYOUT.status_bar.inkwell_panel")
        local inkwell_title_layout = expect_table(STATUS_BAR_LAYOUT.inkwell_title, "deps.HUD_LAYOUT.status_bar.inkwell_title")
        local recovery_layout = expect_table(STATUS_BAR_LAYOUT.recovery, "deps.HUD_LAYOUT.status_bar.recovery")
        local inkwell_items_layout = expect_table(STATUS_BAR_LAYOUT.inkwell_items, "deps.HUD_LAYOUT.status_bar.inkwell_items")

        local top_margin = RuntimeUI.sized(expect_number(stack_layout.top_margin, "deps.HUD_LAYOUT.status_bar.stack.top_margin"))
        local stack_gap = RuntimeUI.sized(expect_number(stack_layout.gap, "deps.HUD_LAYOUT.status_bar.stack.gap"))
        local stats_h = RuntimeUI.sized(expect_number(stack_layout.stats_height, "deps.HUD_LAYOUT.status_bar.stack.stats_height"))
        local badge_h = RuntimeUI.sized(expect_number(stack_layout.badge_height, "deps.HUD_LAYOUT.status_bar.stack.badge_height"))
        local inkwell_h = RuntimeUI.sized(expect_number(stack_layout.inkwell_height, "deps.HUD_LAYOUT.status_bar.stack.inkwell_height"))
        local screen_w, screen_h = ui_dimensions()

        local stats_rect
        local badge_y
        local inkwell_y
        if PROTOTYPE_NO_BACKGROUND then
            local base_w = anchor_page
                and anchor_page.w
                or (screen_w * expect_number(stack_prototype_layout.base_width_ratio, "deps.HUD_LAYOUT.status_bar.stack.prototype.base_width_ratio"))
            local stats_w = clamp(
                math.floor(base_w * expect_number(stack_prototype_layout.stats_width_ratio, "deps.HUD_LAYOUT.status_bar.stack.prototype.stats_width_ratio")),
                RuntimeUI.sized(expect_number(stack_prototype_layout.min_width, "deps.HUD_LAYOUT.status_bar.stack.prototype.min_width")),
                RuntimeUI.sized(expect_number(stack_prototype_layout.max_width, "deps.HUD_LAYOUT.status_bar.stack.prototype.max_width"))
            )
            local x
            local stack_h = stats_h + badge_h + inkwell_h + stack_gap * 2
            local stack_top = top_margin
            if anchor_page then
                x = math.floor(anchor_page.x + (anchor_page.w - stats_w) * 0.5)
                local desired_bottom = math.floor(anchor_page.y - RuntimeUI.sized(expect_number(stack_prototype_layout.anchor_gap, "deps.HUD_LAYOUT.status_bar.stack.prototype.anchor_gap")))
                stack_top = desired_bottom - stack_h
            else
                x = math.floor((screen_w - stats_w) * 0.5)
            end
            local max_stack_top = screen_h - stack_h - RuntimeUI.sized(expect_number(stack_prototype_layout.screen_bottom_margin, "deps.HUD_LAYOUT.status_bar.stack.prototype.screen_bottom_margin"))
            if max_stack_top < top_margin then
                max_stack_top = top_margin
            end
            stack_top = clamp(math.floor(stack_top), top_margin, max_stack_top)
            stats_rect = {
                x = x,
                y = stack_top,
                w = stats_w,
                h = stats_h,
            }
            badge_y = stats_rect.y + stats_h + stack_gap
            inkwell_y = badge_y + badge_h + stack_gap
        else
            stats_rect = project_rect(
                bg,
                expect_number(stack_default_rect_layout.x, "deps.HUD_LAYOUT.status_bar.stack.default_rect.x"),
                expect_number(stack_default_rect_layout.y, "deps.HUD_LAYOUT.status_bar.stack.default_rect.y"),
                expect_number(stack_default_rect_layout.w, "deps.HUD_LAYOUT.status_bar.stack.default_rect.w"),
                expect_number(stack_default_rect_layout.h, "deps.HUD_LAYOUT.status_bar.stack.default_rect.h")
            )
            badge_y = stats_rect.y + stats_rect.h + stack_gap
            inkwell_y = badge_y + badge_h + stack_gap
        end
        local stats_fill = expect_color3(stats_panel_layout.fill_color, "deps.HUD_LAYOUT.status_bar.stats_panel.fill_color")
        local stats_line = expect_color3(stats_panel_layout.line_color, "deps.HUD_LAYOUT.status_bar.stats_panel.line_color")
        local stats_fill_alpha = high_contrast
            and expect_number(stats_panel_layout.fill_alpha_high_contrast, "deps.HUD_LAYOUT.status_bar.stats_panel.fill_alpha_high_contrast")
            or expect_number(stats_panel_layout.fill_alpha_normal, "deps.HUD_LAYOUT.status_bar.stats_panel.fill_alpha_normal")
        love.graphics.setColor(
            stats_fill[1],
            stats_fill[2],
            stats_fill[3],
            stats_fill_alpha
        )
        local stats_corner = expect_number(stats_panel_layout.corner_radius, "deps.HUD_LAYOUT.status_bar.stats_panel.corner_radius")
        love.graphics.rectangle(
            "fill",
            stats_rect.x,
            stats_rect.y,
            stats_rect.w,
            stats_rect.h,
            stats_corner,
            stats_corner
        )
        love.graphics.setColor(
            stats_line[1],
            stats_line[2],
            stats_line[3],
            expect_number(stats_panel_layout.line_alpha, "deps.HUD_LAYOUT.status_bar.stats_panel.line_alpha")
        )
        love.graphics.setLineWidth(expect_number(stats_panel_layout.line_width, "deps.HUD_LAYOUT.status_bar.stats_panel.line_width"))
        love.graphics.rectangle(
            "line",
            stats_rect.x,
            stats_rect.y,
            stats_rect.w,
            stats_rect.h,
            stats_corner,
            stats_corner
        )
        love.graphics.setLineWidth(1)

        local folio = self.run.current_folio
        local folio_label = string.format(
            "%d/%d",
            tonumber(self.run.current_folio_index) or 1,
            tonumber(self.run.total_folios) or 1
        )
        local quality_value = folio.quality
        if folio.getQualityTier then
            quality_value = folio:getQualityTier()
        elseif folio.quality_tier then
            quality_value = folio.quality_tier
        end
        quality_value = tostring(quality_value or 0)

        local header = tr(ScriptoriumUISchema.hud.status_header, {
            folio = folio_label,
            stains = tostring(folio.stain_count),
            quality = quality_value,
        })
        local header_font = get_font(expect_number(header_layout.text_size, "deps.HUD_LAYOUT.status_bar.header.text_size"), true)
        draw_text_center(header, stats_rect, header_font, expect_color4(header_layout.text_color, "deps.HUD_LAYOUT.status_bar.header.text_color"))

        local obj_done, obj_target = 0, 2
        local objective_label = tr(ScriptoriumUISchema.hud.objective_complete_rows)
        if folio.getObjectiveProgress then
            local f, t, label = folio:getObjectiveProgress()
            obj_done = tonumber(f) or 0
            obj_target = tonumber(t) or 2
            if label and label ~= "" then
                objective_label = label
            end
        end
        local badge_w = math.min(
            stats_rect.w * expect_number(objective_badge_layout.width_ratio, "deps.HUD_LAYOUT.status_bar.objective_badge.width_ratio"),
            RuntimeUI.sized(expect_number(objective_badge_layout.width_max, "deps.HUD_LAYOUT.status_bar.objective_badge.width_max"))
        )
        local badge_x = stats_rect.x + (stats_rect.w - badge_w) * 0.5
        local badge_fill = expect_color3(objective_badge_layout.fill_color, "deps.HUD_LAYOUT.status_bar.objective_badge.fill_color")
        local badge_line = expect_color3(objective_badge_layout.line_color, "deps.HUD_LAYOUT.status_bar.objective_badge.line_color")
        local badge_corner = expect_number(objective_badge_layout.corner_radius, "deps.HUD_LAYOUT.status_bar.objective_badge.corner_radius")
        love.graphics.setColor(
            badge_fill[1],
            badge_fill[2],
            badge_fill[3],
            expect_number(objective_badge_layout.fill_alpha, "deps.HUD_LAYOUT.status_bar.objective_badge.fill_alpha")
        )
        love.graphics.rectangle("fill", badge_x, badge_y, badge_w, badge_h, badge_corner, badge_corner)
        love.graphics.setColor(
            badge_line[1],
            badge_line[2],
            badge_line[3],
            expect_number(objective_badge_layout.line_alpha, "deps.HUD_LAYOUT.status_bar.objective_badge.line_alpha")
        )
        love.graphics.rectangle("line", badge_x, badge_y, badge_w, badge_h, badge_corner, badge_corner)
        local open_rows = folio.getOpenRows and folio:getOpenRows() or {}
        local open_text = tr(ScriptoriumUISchema.hud.open_rows_compact, {
            open = #open_rows,
            max = tonumber(folio.max_open_rows) or 2,
        })
        local badge_text = tr(ScriptoriumUISchema.hud.status_badge, {
            objective = objective_label,
            done = tonumber(obj_done) or 0,
            target = tonumber(obj_target) or 2,
            open_rows = open_text,
        })
        draw_text_center(
            badge_text,
            {x = badge_x, y = badge_y, w = badge_w, h = badge_h},
            get_font(expect_number(objective_badge_layout.text_size, "deps.HUD_LAYOUT.status_bar.objective_badge.text_size"), false),
            expect_color4(objective_badge_layout.text_color, "deps.HUD_LAYOUT.status_bar.objective_badge.text_color")
        )

        local inkwell_w = anchor_page
            and (anchor_page.w * expect_number(inkwell_panel_layout.width_ratio_anchor, "deps.HUD_LAYOUT.status_bar.inkwell_panel.width_ratio_anchor"))
            or math.max(stats_rect.w, RuntimeUI.sized(expect_number(inkwell_panel_layout.width_min_no_anchor, "deps.HUD_LAYOUT.status_bar.inkwell_panel.width_min_no_anchor")))
        inkwell_w = clamp(
            inkwell_w,
            RuntimeUI.sized(expect_number(inkwell_panel_layout.min_width, "deps.HUD_LAYOUT.status_bar.inkwell_panel.min_width")),
            RuntimeUI.sized(expect_number(inkwell_panel_layout.max_width, "deps.HUD_LAYOUT.status_bar.inkwell_panel.max_width"))
        )
        local inkwell_x
        if anchor_page then
            inkwell_x = math.floor(anchor_page.x + (anchor_page.w - inkwell_w) * 0.5)
        else
            inkwell_x = math.floor((screen_w - inkwell_w) * 0.5)
        end
        local inkwell_screen_margin = RuntimeUI.sized(expect_number(inkwell_panel_layout.screen_margin, "deps.HUD_LAYOUT.status_bar.inkwell_panel.screen_margin"))
        local max_inkwell_y = screen_h - inkwell_h - inkwell_screen_margin
        if inkwell_y > max_inkwell_y then
            inkwell_y = max_inkwell_y
        end
        if inkwell_y < inkwell_screen_margin then
            inkwell_y = inkwell_screen_margin
        end

        local inkwell_fill = expect_color3(inkwell_panel_layout.fill_color, "deps.HUD_LAYOUT.status_bar.inkwell_panel.fill_color")
        local inkwell_line = expect_color3(inkwell_panel_layout.line_color, "deps.HUD_LAYOUT.status_bar.inkwell_panel.line_color")
        local inkwell_fill_alpha = high_contrast
            and expect_number(inkwell_panel_layout.fill_alpha_high_contrast, "deps.HUD_LAYOUT.status_bar.inkwell_panel.fill_alpha_high_contrast")
            or expect_number(inkwell_panel_layout.fill_alpha_normal, "deps.HUD_LAYOUT.status_bar.inkwell_panel.fill_alpha_normal")
        local inkwell_corner = expect_number(inkwell_panel_layout.corner_radius, "deps.HUD_LAYOUT.status_bar.inkwell_panel.corner_radius")
        love.graphics.setColor(
            inkwell_fill[1],
            inkwell_fill[2],
            inkwell_fill[3],
            inkwell_fill_alpha
        )
        love.graphics.rectangle("fill", inkwell_x, inkwell_y, inkwell_w, inkwell_h, inkwell_corner, inkwell_corner)
        love.graphics.setColor(
            inkwell_line[1],
            inkwell_line[2],
            inkwell_line[3],
            expect_number(inkwell_panel_layout.line_alpha, "deps.HUD_LAYOUT.status_bar.inkwell_panel.line_alpha")
        )
        love.graphics.rectangle("line", inkwell_x, inkwell_y, inkwell_w, inkwell_h, inkwell_corner, inkwell_corner)

        local title_font = get_font(expect_number(inkwell_title_layout.text_size, "deps.HUD_LAYOUT.status_bar.inkwell_title.text_size"), false)
        draw_text_center(tr(ScriptoriumUISchema.hud.inkwell_title), {
            x = inkwell_x,
            y = inkwell_y + RuntimeUI.sized(expect_number(inkwell_title_layout.y_offset, "deps.HUD_LAYOUT.status_bar.inkwell_title.y_offset")),
            w = RuntimeUI.sized(expect_number(inkwell_title_layout.width, "deps.HUD_LAYOUT.status_bar.inkwell_title.width")),
            h = title_font:getHeight(),
        }, title_font, expect_color4(inkwell_title_layout.text_color, "deps.HUD_LAYOUT.status_bar.inkwell_title.text_color"))

        local pending_recovery = math.max(0, math.floor(tonumber(self.pending_ink_recovery) or 0))
        if pending_recovery > 0 then
            local recovery_font = get_font(expect_number(recovery_layout.text_size, "deps.HUD_LAYOUT.status_bar.recovery.text_size"), false)
            draw_text_center(
                tr(ScriptoriumUISchema.hud.inkwell_recovery, {
                    count = pending_recovery,
                }),
                {
                    x = inkwell_x + inkwell_w - RuntimeUI.sized(expect_number(recovery_layout.right_offset, "deps.HUD_LAYOUT.status_bar.recovery.right_offset")),
                    y = inkwell_y + RuntimeUI.sized(expect_number(recovery_layout.y_offset, "deps.HUD_LAYOUT.status_bar.recovery.y_offset")),
                    w = RuntimeUI.sized(expect_number(recovery_layout.width, "deps.HUD_LAYOUT.status_bar.recovery.width")),
                    h = recovery_font:getHeight(),
                },
                recovery_font,
                expect_color4(recovery_layout.text_color, "deps.HUD_LAYOUT.status_bar.recovery.text_color")
            )
        end

        self.ui_hit.inkwell_buttons = {}
        local pad = RuntimeUI.sized(expect_number(inkwell_items_layout.pad, "deps.HUD_LAYOUT.status_bar.inkwell_items.pad"))
        local item_gap = RuntimeUI.sized(expect_number(inkwell_items_layout.gap, "deps.HUD_LAYOUT.status_bar.inkwell_items.gap"))
        local item_y = inkwell_y + RuntimeUI.sized(expect_number(inkwell_items_layout.y_offset, "deps.HUD_LAYOUT.status_bar.inkwell_items.y_offset"))
        local item_h = inkwell_h - RuntimeUI.sized(expect_number(inkwell_items_layout.height_padding, "deps.HUD_LAYOUT.status_bar.inkwell_items.height_padding"))
        local item_w = math.floor((inkwell_w - pad * 2 - item_gap * (#INKWELL_ORDER - 1)) / #INKWELL_ORDER)
        local default_swatch = expect_color3(inkwell_items_layout.default_swatch, "deps.HUD_LAYOUT.status_bar.inkwell_items.default_swatch")
        local line_color_white = expect_color4(inkwell_items_layout.line_color_white, "deps.HUD_LAYOUT.status_bar.inkwell_items.line_color_white")
        local line_color_default = expect_color4(inkwell_items_layout.line_color_default, "deps.HUD_LAYOUT.status_bar.inkwell_items.line_color_default")
        local line_color_empty = expect_color4(inkwell_items_layout.line_color_empty, "deps.HUD_LAYOUT.status_bar.inkwell_items.line_color_empty")
        local hover_outline_color = expect_color4(inkwell_items_layout.hover_outline_color, "deps.HUD_LAYOUT.status_bar.inkwell_items.hover_outline_color")
        local recovery_outline_color = expect_color4(inkwell_items_layout.recovery_outline_color, "deps.HUD_LAYOUT.status_bar.inkwell_items.recovery_outline_color")
        local text_color = expect_color3(inkwell_items_layout.text_color, "deps.HUD_LAYOUT.status_bar.inkwell_items.text_color")
        local item_corner = expect_number(inkwell_items_layout.corner_radius, "deps.HUD_LAYOUT.status_bar.inkwell_items.corner_radius")
        local outline_expand = expect_number(inkwell_items_layout.outline_expand, "deps.HUD_LAYOUT.status_bar.inkwell_items.outline_expand")
        local outline_line_width = expect_number(inkwell_items_layout.outline_line_width, "deps.HUD_LAYOUT.status_bar.inkwell_items.outline_line_width")
        local hovered_constraint = self.hover_constraint_color
        for i, color_key in ipairs(INKWELL_ORDER) do
            local drops = folio.getInkDrops and folio:getInkDrops(color_key) or 0
            local cap = folio.getInkCap and folio:getInkCap(color_key) or drops
            local depleted = drops <= 0
            local recoverable = drops < cap
            local rect = {
                x = inkwell_x + pad + (i - 1) * (item_w + item_gap),
                y = item_y,
                w = item_w,
                h = item_h,
            }
            self.ui_hit.inkwell_buttons[#self.ui_hit.inkwell_buttons + 1] = {color = color_key, rect = rect}

            local swatch = DIE_COLOR_SWATCH[color_key] or default_swatch
            local hover = point_in_rect(self.mouse_x, self.mouse_y, rect)
            local fill_alpha = depleted
                and expect_number(inkwell_items_layout.fill_alpha_empty, "deps.HUD_LAYOUT.status_bar.inkwell_items.fill_alpha_empty")
                or (hover
                    and expect_number(inkwell_items_layout.fill_alpha_hover, "deps.HUD_LAYOUT.status_bar.inkwell_items.fill_alpha_hover")
                    or expect_number(inkwell_items_layout.fill_alpha_normal, "deps.HUD_LAYOUT.status_bar.inkwell_items.fill_alpha_normal"))
            love.graphics.setColor(swatch[1], swatch[2], swatch[3], fill_alpha)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, item_corner, item_corner)

            local line = (color_key == "BIANCO") and line_color_white or line_color_default
            if depleted then
                line = line_color_empty
            end
            love.graphics.setColor(line[1], line[2], line[3], line[4])
            love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, item_corner, item_corner)

            if hovered_constraint and hovered_constraint == color_key then
                love.graphics.setColor(hover_outline_color[1], hover_outline_color[2], hover_outline_color[3], hover_outline_color[4])
                love.graphics.setLineWidth(outline_line_width)
                love.graphics.rectangle("line", rect.x - outline_expand, rect.y - outline_expand, rect.w + outline_expand * 2, rect.h + outline_expand * 2, item_corner + 1, item_corner + 1)
                love.graphics.setLineWidth(1)
            elseif pending_recovery > 0 and recoverable then
                love.graphics.setColor(recovery_outline_color[1], recovery_outline_color[2], recovery_outline_color[3], recovery_outline_color[4])
                love.graphics.setLineWidth(outline_line_width)
                love.graphics.rectangle("line", rect.x - outline_expand, rect.y - outline_expand, rect.w + outline_expand * 2, rect.h + outline_expand * 2, item_corner + 1, item_corner + 1)
                love.graphics.setLineWidth(1)
            end

            local short = COLOR_SHORT[color_key] or tostring(color_key):sub(1, 1)
            love.graphics.setFont(get_font(expect_number(inkwell_items_layout.short_text_size, "deps.HUD_LAYOUT.status_bar.inkwell_items.short_text_size"), true))
            love.graphics.setColor(
                text_color[1],
                text_color[2],
                text_color[3],
                depleted
                    and expect_number(inkwell_items_layout.short_text_alpha_empty, "deps.HUD_LAYOUT.status_bar.inkwell_items.short_text_alpha_empty")
                    or expect_number(inkwell_items_layout.short_text_alpha_normal, "deps.HUD_LAYOUT.status_bar.inkwell_items.short_text_alpha_normal")
            )
            love.graphics.printf(short, rect.x, rect.y + RuntimeUI.sized(expect_number(inkwell_items_layout.short_text_y_offset, "deps.HUD_LAYOUT.status_bar.inkwell_items.short_text_y_offset")), rect.w, "center")
            love.graphics.setFont(get_font(expect_number(inkwell_items_layout.dots_text_size, "deps.HUD_LAYOUT.status_bar.inkwell_items.dots_text_size"), false))
            love.graphics.setColor(
                text_color[1],
                text_color[2],
                text_color[3],
                depleted
                    and expect_number(inkwell_items_layout.dots_text_alpha_empty, "deps.HUD_LAYOUT.status_bar.inkwell_items.dots_text_alpha_empty")
                    or expect_number(inkwell_items_layout.dots_text_alpha_normal, "deps.HUD_LAYOUT.status_bar.inkwell_items.dots_text_alpha_normal")
            )
            love.graphics.printf(drops_to_dots(drops, cap), rect.x, rect.y + RuntimeUI.sized(expect_number(inkwell_items_layout.dots_text_y_offset, "deps.HUD_LAYOUT.status_bar.inkwell_items.dots_text_y_offset")), rect.w, "center")
        end

    end

    function methods.drawMarginNotes(self, page, high_contrast)
        if not self.run or not self.run.current_folio or not page then
            return
        end
        local note_layout = expect_table(MARGIN_NOTES_LAYOUT.note, "deps.HUD_LAYOUT.margin_notes.note")
        local title_layout = expect_table(MARGIN_NOTES_LAYOUT.title, "deps.HUD_LAYOUT.margin_notes.title")
        local body_layout = expect_table(MARGIN_NOTES_LAYOUT.body, "deps.HUD_LAYOUT.margin_notes.body")
        local divider_layout = expect_table(MARGIN_NOTES_LAYOUT.divider, "deps.HUD_LAYOUT.margin_notes.divider")
        local icons_layout = expect_table(MARGIN_NOTES_LAYOUT.icons, "deps.HUD_LAYOUT.margin_notes.icons")
        local folio = self.run.current_folio
        local objective_filled, objective_target = 0, 2
        local objective_label = tr(ScriptoriumUISchema.hud.objective_complete_rows)
        if folio.getObjectiveProgress then
            local f, t, label = folio:getObjectiveProgress()
            objective_filled = tonumber(f) or 0
            objective_target = tonumber(t) or 2
            if label and label ~= "" then
                objective_label = label
            end
        end
        local open_rows = folio.getOpenRows and folio:getOpenRows() or {}
        local list_separator = tr(ScriptoriumUISchema.hud.list_separator)
        if list_separator == "" then
            list_separator = ", "
        end
        local list_empty = tr(ScriptoriumUISchema.hud.list_empty)
        if list_empty == "" then
            list_empty = "-"
        end
        local open_rows_text = (#open_rows > 0) and table.concat(open_rows, list_separator) or list_empty
        local guided_rows = folio.getGuidedRows and folio:getGuidedRows() or {}
        local guided_rows_text = (#guided_rows > 0) and table.concat(guided_rows, list_separator) or list_empty
        local max_open_rows = folio.max_open_rows or 2
        local bust_choice_count = math.max(1, math.floor(tonumber(folio.bust_choice_count) or 2))
        local bust_open_rows_only = folio.bust_open_rows_only and true or false

        local note = {
            x = page.x + page.w * (note_layout.x_ratio or 0.74),
            y = page.y + page.h * (note_layout.y_ratio or 0.54),
            w = page.w * (note_layout.width_ratio or 0.21),
            h = page.h * (note_layout.height_ratio or 0.40),
        }
        local note_fill = note_layout.fill_color or {0.92, 0.85, 0.72}
        local note_line = note_layout.line_color or {0.66, 0.49, 0.31}
        local note_corner = note_layout.corner_radius or 7
        local note_fill_alpha = high_contrast
            and (note_layout.fill_alpha_high_contrast or 0.88)
            or (note_layout.fill_alpha_normal or 0.74)
        love.graphics.setColor(
            note_fill[1] or 0.92,
            note_fill[2] or 0.85,
            note_fill[3] or 0.72,
            note_fill_alpha
        )
        love.graphics.rectangle("fill", note.x, note.y, note.w, note.h, note_corner, note_corner)
        love.graphics.setColor(
            note_line[1] or 0.66,
            note_line[2] or 0.49,
            note_line[3] or 0.31,
            note_layout.line_alpha or 0.62
        )
        love.graphics.rectangle("line", note.x, note.y, note.w, note.h, note_corner, note_corner)

        local y = note.y + RuntimeUI.sized(title_layout.y_offset or 8)
        draw_text_center(tr(ScriptoriumUISchema.hud.brief_title), {
            x = note.x,
            y = y,
            w = note.w,
            h = RuntimeUI.sized(title_layout.height or 20),
        }, get_font(title_layout.text_size or 16, false), title_layout.text_color or {0.95, 0.86, 0.68, 1})

        local body_top = y + RuntimeUI.sized(title_layout.top_gap or 24)
        local bust_line = bust_open_rows_only
            and tr(ScriptoriumUISchema.hud.brief_bust_open_rows, {choices = bust_choice_count})
            or tr(ScriptoriumUISchema.hud.brief_bust_any_rows, {choices = bust_choice_count})
        local wet_max = math.max(1, math.floor(tonumber(folio.wet_buffer_max) or 3))
        local lines = {
            tr(ScriptoriumUISchema.hud.brief_objective, {
                objective = objective_label,
                done = objective_filled,
                target = objective_target,
            }),
            tr(ScriptoriumUISchema.hud.brief_open_rows, {
                rows = open_rows_text,
                max = max_open_rows,
            }),
            tr(ScriptoriumUISchema.hud.brief_guided_rows, {
                rows = guided_rows_text,
            }),
            tr(ScriptoriumUISchema.hud.brief_wet_buffer, {
                current = folio.getWetCount and folio:getWetCount() or 0,
                max = wet_max,
            }),
            bust_line,
        }
        local reroll_max = tonumber(folio.reroll_max)
        if reroll_max ~= nil then
            reroll_max = math.max(0, math.floor(reroll_max))
            lines[#lines + 1] = tr(ScriptoriumUISchema.hud.brief_reroll_cap, {
                max = reroll_max,
                used = math.max(0, math.floor(tonumber(folio.turn_pushes) or 0)),
            })
        end
        if self.state == "stain_pick" then
            lines[#lines + 1] = tr(ScriptoriumUISchema.hud.brief_bust_active)
        end
        local footer_h = RuntimeUI.sized(body_layout.footer_height or 36)
        local divider_y = note.y + note.h - footer_h - RuntimeUI.sized(body_layout.divider_bottom_offset or 14)
        local available_h = math.max(
            RuntimeUI.sized(body_layout.available_min or 84),
            divider_y - body_top - RuntimeUI.sized(body_layout.available_padding or 4)
        )
        local target_px = clamp(
            math.floor(available_h / #lines) - RuntimeUI.sized(body_layout.font_target_spacing or 4),
            body_layout.font_min or 10,
            body_layout.font_max or 13
        )
        local body_font = get_font(target_px, false)
        local line_h = math.max(
            body_font:getHeight() + RuntimeUI.sized(body_layout.font_target_spacing or 4),
            clamp(
                math.floor(available_h / #lines),
                RuntimeUI.sized(body_layout.line_min or 16),
                RuntimeUI.sized(body_layout.line_max or 30)
            )
        )
        love.graphics.setFont(body_font)
        y = body_top
        for i, line in ipairs(lines) do
            if y + line_h > divider_y then
                break
            end
            if i == #lines then
                local text_last = body_layout.text_color_last or {0.68, 0.26, 0.18, 1}
                love.graphics.setColor(text_last[1] or 0.68, text_last[2] or 0.26, text_last[3] or 0.18, text_last[4] or 1)
            else
                local text_normal = body_layout.text_color or {0.34, 0.25, 0.17, 1}
                love.graphics.setColor(text_normal[1] or 0.34, text_normal[2] or 0.25, text_normal[3] or 0.17, text_normal[4] or 1)
            end
            love.graphics.print(line, note.x + RuntimeUI.sized(body_layout.text_x_padding or 10), y)
            y = y + line_h
        end

        local divider_color = divider_layout.color or {0.64, 0.47, 0.30}
        love.graphics.setColor(
            divider_color[1] or 0.64,
            divider_color[2] or 0.47,
            divider_color[3] or 0.30,
            divider_layout.alpha or 0.36
        )
        love.graphics.line(
            note.x + RuntimeUI.sized(divider_layout.x_padding or 10),
            divider_y,
            note.x + note.w - RuntimeUI.sized(divider_layout.x_padding or 10),
            divider_y
        )
        y = divider_y + RuntimeUI.sized(divider_layout.y_offset or 8)

        local icons = {
            {
                short = icons_layout.shield_short or "S",
                value = tostring(folio.shield or 0),
                color = icons_layout.shield_color or {0.82, 0.68, 0.40, 1},
            },
            {
                short = icons_layout.wet_short or "W",
                value = tostring(folio.getWetCount and folio:getWetCount() or 0),
                color = icons_layout.wet_color or {0.85, 0.36, 0.32, 1},
            },
            {
                short = icons_layout.turn_short or "T",
                value = tostring(folio.turn_count or 0),
                color = icons_layout.turn_color or {0.74, 0.62, 0.28, 1},
            },
            {
                short = icons_layout.bust_short or "B",
                value = tostring(folio.bust_count or 0),
                color = icons_layout.bust_color or {0.50, 0.74, 0.88, 1},
            },
            {
                short = icons_layout.pattern_short or "K",
                value = tostring(folio.getPatternToken and folio:getPatternToken() or 0),
                color = icons_layout.pattern_color or {0.64, 0.88, 0.62, 1},
            },
        }
        local icon_r = RuntimeUI.sized(icons_layout.radius or 8)
        local slot_w = (note.w - RuntimeUI.sized(icons_layout.slot_padding or 24)) / #icons
        local start_x = note.x + RuntimeUI.sized(icons_layout.x_padding or 10)
        local icon_font = get_font(icons_layout.text_size or 9, false)
        love.graphics.setFont(icon_font)
        local icon_text_h = icon_font:getHeight()
        local icon_text_color = icons_layout.text_color or {0.34, 0.25, 0.17, 1}
        local icon_ring_color = icons_layout.ring_color or {0.23, 0.16, 0.10, 1}
        for i, icon in ipairs(icons) do
            local ix = start_x + (i - 1) * slot_w
            love.graphics.setColor(icon.color[1], icon.color[2], icon.color[3], 0.95)
            love.graphics.circle("fill", ix, y + icon_r, icon_r)
            love.graphics.setColor(
                icon_ring_color[1] or 0.23,
                icon_ring_color[2] or 0.16,
                icon_ring_color[3] or 0.10,
                icon_ring_color[4] or 1
            )
            love.graphics.circle("line", ix, y + icon_r, icon_r)
            love.graphics.setColor(
                icon_text_color[1] or 0.34,
                icon_text_color[2] or 0.25,
                icon_text_color[3] or 0.17,
                icon_text_color[4] or 1
            )
            local text_y = y + math.floor((icon_r * 2 - icon_text_h) * 0.5)
            love.graphics.print(icon.short .. ":" .. icon.value, ix + RuntimeUI.sized(icons_layout.label_x_offset or 11), text_y)
        end
    end

    function methods.drawStopPushControls(self, high_contrast)
        local folio = self.run and self.run.current_folio
        if not folio then
            return
        end

        local dock_layout = expect_table(CONTROLS_LAYOUT.dock, "deps.HUD_LAYOUT.controls.dock")
        local segments_layout = expect_table(CONTROLS_LAYOUT.segments, "deps.HUD_LAYOUT.controls.segments")
        local section_panel_layout = expect_table(CONTROLS_LAYOUT.section_panel, "deps.HUD_LAYOUT.controls.section_panel")
        local controls_label_layout = expect_table(CONTROLS_LAYOUT.labels, "deps.HUD_LAYOUT.controls.labels")
        local action_layout = expect_table(CONTROLS_LAYOUT.action, "deps.HUD_LAYOUT.controls.action")
        local action_button_layout = expect_table(action_layout.button, "deps.HUD_LAYOUT.controls.action.button")
        local action_text_layout = expect_table(action_layout.text, "deps.HUD_LAYOUT.controls.action.text")
        local placing_action_layout = expect_table(action_layout.placing, "deps.HUD_LAYOUT.controls.action.placing")
        local reroll_button_layout = expect_table(action_layout.reroll_button, "deps.HUD_LAYOUT.controls.action.reroll_button")
        local commit_button_layout = expect_table(action_layout.commit_button, "deps.HUD_LAYOUT.controls.action.commit_button")
        local roll_button_layout = expect_table(action_layout.roll_button, "deps.HUD_LAYOUT.controls.action.roll_button")
        local system_menu_layout = expect_table(CONTROLS_LAYOUT.system_menu, "deps.HUD_LAYOUT.controls.system_menu")
        local system_button_layout = expect_table(system_menu_layout.button, "deps.HUD_LAYOUT.controls.system_menu.button")
        local system_icon_layout = expect_table(system_menu_layout.icon, "deps.HUD_LAYOUT.controls.system_menu.icon")
        local system_panel_layout = expect_table(system_menu_layout.panel, "deps.HUD_LAYOUT.controls.system_menu.panel")
        local system_item_layout = expect_table(system_menu_layout.item, "deps.HUD_LAYOUT.controls.system_menu.item")
        local wet_buffer_layout = expect_table(CONTROLS_LAYOUT.wet_buffer, "deps.HUD_LAYOUT.controls.wet_buffer")
        local wet_buffer_title_layout = expect_table(wet_buffer_layout.title, "deps.HUD_LAYOUT.controls.wet_buffer.title")
        local wet_buffer_meter_layout = expect_table(wet_buffer_layout.meter, "deps.HUD_LAYOUT.controls.wet_buffer.meter")
        local wet_buffer_slots_layout = expect_table(wet_buffer_layout.slots, "deps.HUD_LAYOUT.controls.wet_buffer.slots")
        local wet_buffer_entry_layout = expect_table(wet_buffer_layout.entry, "deps.HUD_LAYOUT.controls.wet_buffer.entry")
        local wet_buffer_undo_layout = expect_table(wet_buffer_layout.undo, "deps.HUD_LAYOUT.controls.wet_buffer.undo")
        local palette_picker_layout = expect_table(CONTROLS_LAYOUT.palette_picker, "deps.HUD_LAYOUT.controls.palette_picker")
        local dice_controls_layout = expect_table(CONTROLS_LAYOUT.dice, "deps.HUD_LAYOUT.controls.dice")
        local dice_area_layout = expect_table(dice_controls_layout.area, "deps.HUD_LAYOUT.controls.dice.area")
        local dice_empty_layout = expect_table(dice_controls_layout.empty_state, "deps.HUD_LAYOUT.controls.dice.empty_state")
        local dice_chip_layout = expect_table(dice_controls_layout.chip, "deps.HUD_LAYOUT.controls.dice.chip")
        local dice_moves_layout = expect_table(dice_controls_layout.moves_hint, "deps.HUD_LAYOUT.controls.dice.moves_hint")
        local dice_moves_dot_layout = expect_table(dice_moves_layout.dot, "deps.HUD_LAYOUT.controls.dice.moves_hint.dot")
        local dice_moves_text_layout = expect_table(dice_moves_layout.text, "deps.HUD_LAYOUT.controls.dice.moves_hint.text")
        local palette_controls_layout = expect_table(CONTROLS_LAYOUT.palette, "deps.HUD_LAYOUT.controls.palette")
        local palette_pills_layout = expect_table(palette_controls_layout.pills, "deps.HUD_LAYOUT.controls.palette.pills")
        local palette_fixed_label_layout = expect_table(palette_controls_layout.fixed_label, "deps.HUD_LAYOUT.controls.palette.fixed_label")

        local page = self.page_rect
        local tray = self:_getTrayRect()

        local dock_h = self:getControlsDockHeight()
        local dock_x
        local dock_w
        local dock_y
        if page then
            dock_x = page.x
            dock_w = page.w
            dock_y = page.y + page.h + RuntimeUI.sized(dock_layout.page_y_offset or 12)
        else
            dock_w = math.min(tray.w, RuntimeUI.sized(dock_layout.tray_width_max or 980))
            dock_x = tray.x + (tray.w - dock_w) * 0.5
            dock_y = tray.y - dock_h - RuntimeUI.sized(dock_layout.tray_y_offset or 12)
        end
        local max_y = tray.y - dock_h - RuntimeUI.sized(dock_layout.tray_max_gap or 10)
        if dock_y > max_y then
            dock_y = max_y
        end

        local dock_fill = dock_layout.fill_color or {0.24, 0.16, 0.10}
        local dock_line = dock_layout.line_color or {0.70, 0.52, 0.33}
        local dock_corner = dock_layout.corner_radius or 8
        love.graphics.setColor(
            dock_fill[1] or 0.24,
            dock_fill[2] or 0.16,
            dock_fill[3] or 0.10,
            high_contrast and (dock_layout.fill_alpha_high_contrast or 0.96) or (dock_layout.fill_alpha_normal or 0.90)
        )
        love.graphics.rectangle("fill", dock_x, dock_y, dock_w, dock_h, dock_corner, dock_corner)
        love.graphics.setColor(
            dock_line[1] or 0.70,
            dock_line[2] or 0.52,
            dock_line[3] or 0.33,
            dock_layout.line_alpha or 0.56
        )
        love.graphics.rectangle("line", dock_x, dock_y, dock_w, dock_h, dock_corner, dock_corner)

        local pad = RuntimeUI.sized(segments_layout.pad or 12)
        local gap = RuntimeUI.sized(segments_layout.gap or 10)
        local inner_w = dock_w - pad * 2 - gap * 4
        if inner_w < 0 then
            inner_w = dock_w - pad * 2
        end
        local dice_w = math.floor(inner_w * (segments_layout.dice_width_ratio or 0.40))
        local palette_w = math.floor(inner_w * (segments_layout.palette_width_ratio or 0.18))
        local buffer_w = math.floor(inner_w * (segments_layout.buffer_width_ratio or 0.16))
        local reroll_w = math.floor(inner_w * (segments_layout.reroll_width_ratio or 0.07))
        local commit_w = inner_w - dice_w - palette_w - buffer_w - reroll_w

        local seg_y = dock_y + pad
        local seg_h = dock_h - pad * 2
        local x = dock_x + pad
        local dice_rect = {x = x, y = seg_y, w = dice_w, h = seg_h}
        x = x + dice_w + gap
        local palette_rect = {x = x, y = seg_y, w = palette_w, h = seg_h}
        x = x + palette_w + gap
        local buffer_rect = {x = x, y = seg_y, w = buffer_w, h = seg_h}
        x = x + buffer_w + gap
        local reroll_rect = {x = x, y = seg_y, w = reroll_w, h = seg_h}
        x = x + reroll_w + gap
        local commit_rect = {x = x, y = seg_y, w = commit_w, h = seg_h}

        local function draw_panel(rect)
            local panel_fill = section_panel_layout.fill_color or {0.31, 0.22, 0.14}
            local panel_line = section_panel_layout.line_color or {0.70, 0.52, 0.33}
            local panel_corner = section_panel_layout.corner_radius or 6
            love.graphics.setColor(
                panel_fill[1] or 0.31,
                panel_fill[2] or 0.22,
                panel_fill[3] or 0.14,
                section_panel_layout.fill_alpha or 0.88
            )
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, panel_corner, panel_corner)
            love.graphics.setColor(
                panel_line[1] or 0.70,
                panel_line[2] or 0.52,
                panel_line[3] or 0.33,
                section_panel_layout.line_alpha or 0.42
            )
            love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, panel_corner, panel_corner)
        end

        draw_panel(dice_rect)
        draw_panel(palette_rect)
        draw_panel(buffer_rect)

        local placing_mode = (self.state == "placing")
        local interaction_locked = (self.state == "stain_pick")

        self.ui_hit.dice_chips = {}
        self.ui_hit.wet_buffer_undo_buttons = {}
        self.ui_hit.palette_color_buttons = nil
        self.ui_hit.stop_button = nil
        self.ui_hit.push_all_button = nil
        self.ui_hit.push_one_button = nil
        self.ui_hit.prepare_risk_button = nil
        self.ui_hit.prepare_guard_button = nil
        self.ui_hit.restart_button = nil
        self.ui_hit.roll_button = nil
        self.ui_hit.seal_reroll_button = nil
        self.ui_hit.seal_plus_button = nil
        self.ui_hit.seal_minus_button = nil

        local section_label_color = controls_label_layout.section_title_color or {0.95, 0.90, 0.82, 1}
        local section_label_size = controls_label_layout.section_title_size or 12
        local section_label_y_offset = controls_label_layout.section_title_y_offset or 2
        local dice_label_font = get_font(section_label_size, false)
        local dice_label_h = dice_label_font:getHeight()
        draw_text_center(tr(ScriptoriumUISchema.hud.dice_in_hand), {
            x = dice_rect.x,
            y = dice_rect.y + RuntimeUI.sized(section_label_y_offset),
            w = dice_rect.w,
            h = dice_label_h,
        }, dice_label_font, section_label_color)

        local dice = self.dice_results or {}
        local die_count = #dice
        local moves_label_h = RuntimeUI.sized(dice_area_layout.moves_label_height or 16)
        local reserve_moves = placing_mode and moves_label_h or 0
        local dice_area_y = dice_rect.y + dice_label_h + RuntimeUI.sized(dice_area_layout.top_gap or 6)
        local dice_area_h = dice_rect.h - dice_label_h - RuntimeUI.sized(dice_area_layout.bottom_padding or 12) - reserve_moves
        if die_count <= 0 then
            draw_text_center(tr(ScriptoriumUISchema.hud.roll_to_draw), {
                x = dice_rect.x,
                y = dice_area_y,
                w = dice_rect.w,
                h = dice_area_h,
            }, get_font(dice_empty_layout.text_size or 11, false), dice_empty_layout.text_color or {0.88, 0.78, 0.64, 0.9})
        else
            local die_gap = RuntimeUI.sized(dice_area_layout.die_gap or 6)
            local max_by_w = (dice_rect.w - die_gap * math.max(0, die_count - 1)) / math.max(1, die_count)
            local die_size = math.floor(math.min(dice_area_h, max_by_w))
            die_size = math.max(RuntimeUI.sized(dice_area_layout.die_size_min or 30), die_size)
            local boosted = math.floor(die_size * (dice_area_layout.die_size_boost_ratio or 1.22))
            local max_size = math.floor(math.min(dice_area_h, max_by_w))
            die_size = math.min(boosted, max_size)
            local total_w = die_count * die_size + die_gap * math.max(0, die_count - 1)
            local start_x = dice_rect.x + math.floor((dice_rect.w - total_w) * 0.5)
            local die_y = dice_area_y + math.floor((dice_area_h - die_size) * 0.5)
            local chip_corner = dice_chip_layout.corner_radius or 6
            local chip_used_fill = dice_chip_layout.used_fill_color or {0.28, 0.22, 0.18}
            local chip_idle_fill = dice_chip_layout.idle_fill_color or {0.86, 0.80, 0.70}
            local chip_unusable_fill = dice_chip_layout.unusable_fill_color or {0.50, 0.50, 0.50}
            local chip_selected_outer = dice_chip_layout.selected_outer or {}
            local chip_shadow = dice_chip_layout.shadow or {}
            local chip_selected_inner = dice_chip_layout.selected_inner or {}
            local chip_sheen = dice_chip_layout.sheen or {}
            local chip_edge = dice_chip_layout.edge or {}
            local chip_border = dice_chip_layout.border or {}
            local chip_value = dice_chip_layout.value or {}
            local chip_hover_badge = dice_chip_layout.hover_badge or {}
            local chip_unusable_cross = dice_chip_layout.unusable_cross or {}
            for i, die in ipairs(dice) do
                local rect = {
                    x = start_x + (i - 1) * (die_size + die_gap),
                    y = die_y,
                    w = die_size,
                    h = die_size,
                }
                local selected = (self.selected_die == i)
                local hover = point_in_rect(self.mouse_x, self.mouse_y, rect)
                local unusable = die.unusable and (not die.used)
                local fill = die.used and chip_used_fill or chip_idle_fill
                if unusable then
                    fill = chip_unusable_fill
                end
                local alpha = die.used and (dice_chip_layout.used_alpha or 0.38) or (dice_chip_layout.idle_alpha or 0.98)
                if selected then
                    local outer_color = chip_selected_outer.color or {0.96, 0.88, 0.70}
                    local outer_expand = chip_selected_outer.expand or 3
                    love.graphics.setColor(
                        outer_color[1] or 0.96,
                        outer_color[2] or 0.88,
                        outer_color[3] or 0.70,
                        chip_selected_outer.alpha or 0.22
                    )
                    love.graphics.rectangle(
                        "fill",
                        rect.x - outer_expand,
                        rect.y - outer_expand,
                        rect.w + outer_expand * 2,
                        rect.h + outer_expand * 2,
                        chip_selected_outer.corner_radius or 7,
                        chip_selected_outer.corner_radius or 7
                    )
                end
                local shadow_color = chip_shadow.color or {0.08, 0.06, 0.05}
                local shadow_x = chip_shadow.x_offset or 2
                local shadow_y = chip_shadow.y_offset or 3
                love.graphics.setColor(
                    shadow_color[1] or 0.08,
                    shadow_color[2] or 0.06,
                    shadow_color[3] or 0.05,
                    chip_shadow.alpha or 0.30
                )
                love.graphics.rectangle(
                    "fill",
                    rect.x + shadow_x,
                    rect.y + shadow_y,
                    rect.w,
                    rect.h,
                    chip_shadow.corner_radius or chip_corner,
                    chip_shadow.corner_radius or chip_corner
                )
                if selected then
                    local inner_color = chip_selected_inner.color or {0.98, 0.88, 0.62}
                    local inner_expand = chip_selected_inner.expand or 2
                    love.graphics.setColor(
                        inner_color[1] or 0.98,
                        inner_color[2] or 0.88,
                        inner_color[3] or 0.62,
                        chip_selected_inner.alpha or 0.30
                    )
                    love.graphics.rectangle(
                        "fill",
                        rect.x - inner_expand,
                        rect.y - inner_expand,
                        rect.w + inner_expand * 2,
                        rect.h + inner_expand * 2,
                        chip_selected_inner.corner_radius or 7,
                        chip_selected_inner.corner_radius or 7
                    )
                end
                love.graphics.setColor(fill[1], fill[2], fill[3], alpha)
                love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, chip_corner, chip_corner)
                local sheen_color = chip_sheen.color or {0.98, 0.94, 0.86}
                local sheen_inset = chip_sheen.inset or 2
                love.graphics.setColor(
                    sheen_color[1] or 0.98,
                    sheen_color[2] or 0.94,
                    sheen_color[3] or 0.86,
                    chip_sheen.alpha or 0.18
                )
                love.graphics.setLineWidth(1)
                love.graphics.line(rect.x + sheen_inset, rect.y + sheen_inset, rect.x + rect.w - sheen_inset, rect.y + sheen_inset)
                love.graphics.line(rect.x + sheen_inset, rect.y + sheen_inset, rect.x + sheen_inset, rect.y + rect.h - sheen_inset)
                local edge_color = chip_edge.color or {0.20, 0.16, 0.12}
                local edge_inset = chip_edge.inset or 2
                love.graphics.setColor(
                    edge_color[1] or 0.20,
                    edge_color[2] or 0.16,
                    edge_color[3] or 0.12,
                    chip_edge.alpha or 0.40
                )
                love.graphics.line(rect.x + edge_inset, rect.y + rect.h - edge_inset, rect.x + rect.w - edge_inset, rect.y + rect.h - edge_inset)
                love.graphics.line(rect.x + rect.w - edge_inset, rect.y + edge_inset, rect.x + rect.w - edge_inset, rect.y + rect.h - edge_inset)
                local line = selected
                    and (chip_border.selected_color or {0.98, 0.90, 0.70, 1})
                    or (chip_border.normal_color or {0.60, 0.50, 0.40, 0.72})
                if hover and (not selected) then
                    line = chip_border.hover_color or {0.94, 0.82, 0.62, 0.95}
                end
                if unusable then
                    line = chip_border.unusable_color or {0.85, 0.36, 0.32, 0.95}
                end
                love.graphics.setColor(line[1], line[2], line[3], line[4])
                love.graphics.setLineWidth(selected and (chip_border.line_width_selected or 3) or (chip_border.line_width_normal or 1))
                love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, chip_corner, chip_corner)
                love.graphics.setLineWidth(1)
                local value_used = chip_value.used_color or {0.70, 0.64, 0.54, 0.70}
                local value_idle = chip_value.idle_color or {0.20, 0.15, 0.10, 0.95}
                draw_text_center(
                    tostring(die.value or "?"),
                    rect,
                    get_font(chip_value.text_size or 20, true),
                    die.used and value_used or value_idle
                )
                if selected and self.palette_picker and self.palette_picker.hover_color then
                    local badge_color = self.palette_picker.hover_color
                    local swatch = DIE_COLOR_SWATCH[badge_color] or {0.65, 0.45, 0.25}
                    local badge_w = math.max(
                        RuntimeUI.sized(chip_hover_badge.width_min or 34),
                        math.floor(rect.w * (chip_hover_badge.width_ratio or 0.55))
                    )
                    local badge_h = RuntimeUI.sized(chip_hover_badge.height or 14)
                    local badge_x = rect.x + (rect.w - badge_w) * 0.5
                    local badge_y = rect.y - badge_h - RuntimeUI.sized(chip_hover_badge.y_offset or 4)
                    if badge_y < dice_rect.y + RuntimeUI.sized(chip_hover_badge.y_min or 2) then
                        badge_y = rect.y + RuntimeUI.sized(chip_hover_badge.y_min or 2)
                    end
                    love.graphics.setColor(swatch[1], swatch[2], swatch[3], chip_hover_badge.fill_alpha or 0.96)
                    love.graphics.rectangle(
                        "fill",
                        badge_x,
                        badge_y,
                        badge_w,
                        badge_h,
                        chip_hover_badge.corner_radius or 4,
                        chip_hover_badge.corner_radius or 4
                    )
                    local badge_line = (badge_color == "BIANCO")
                        and (chip_hover_badge.line_white or {0.14, 0.14, 0.14, 0.8})
                        or (chip_hover_badge.line_default or {0.98, 0.92, 0.80, 0.9})
                    love.graphics.setColor(badge_line[1], badge_line[2], badge_line[3], badge_line[4])
                    love.graphics.rectangle(
                        "line",
                        badge_x,
                        badge_y,
                        badge_w,
                        badge_h,
                        chip_hover_badge.corner_radius or 4,
                        chip_hover_badge.corner_radius or 4
                    )
                    local label = color_label(badge_color)
                    local badge_text = chip_hover_badge.text_color or {0.12, 0.10, 0.08, 0.95}
                    love.graphics.setFont(get_font(chip_hover_badge.text_size or 9, true))
                    love.graphics.setColor(
                        badge_text[1] or 0.12,
                        badge_text[2] or 0.10,
                        badge_text[3] or 0.08,
                        badge_text[4] or 0.95
                    )
                    love.graphics.printf(
                        label,
                        badge_x,
                        badge_y + RuntimeUI.sized(chip_hover_badge.text_y_offset or 1),
                        badge_w,
                        "center"
                    )
                end
                if unusable then
                    local cross_color = chip_unusable_cross.color or {0.85, 0.34, 0.30}
                    local cross_inset = RuntimeUI.sized(chip_unusable_cross.inset or 4)
                    love.graphics.setColor(
                        cross_color[1] or 0.85,
                        cross_color[2] or 0.34,
                        cross_color[3] or 0.30,
                        chip_unusable_cross.alpha or 0.86
                    )
                    love.graphics.setLineWidth(chip_unusable_cross.line_width or 2)
                    love.graphics.line(
                        rect.x + cross_inset,
                        rect.y + cross_inset,
                        rect.x + rect.w - cross_inset,
                        rect.y + rect.h - cross_inset
                    )
                    love.graphics.line(
                        rect.x + rect.w - cross_inset,
                        rect.y + cross_inset,
                        rect.x + cross_inset,
                        rect.y + rect.h - cross_inset
                    )
                    love.graphics.setLineWidth(1)
                end
                if placing_mode and (not interaction_locked) and (not die.used) then
                    self.ui_hit.dice_chips[#self.ui_hit.dice_chips + 1] = {index = i, rect = rect}
                end
            end
        end

        local palette_label_font = get_font(section_label_size, false)
        local palette_label_h = palette_label_font:getHeight()
        draw_text_center(tr(ScriptoriumUISchema.hud.turn_palette), {
            x = palette_rect.x,
            y = palette_rect.y + RuntimeUI.sized(section_label_y_offset),
            w = palette_rect.w,
            h = palette_label_h,
        }, palette_label_font, section_label_color)
        local function boost_color(c, boost)
            local b = boost or 0.12
            return {
                math.min(1, c[1] + b),
                math.min(1, c[2] + b),
                math.min(1, c[3] + b),
            }
        end
        local palette = {}
        if placing_mode and self.getTurnPalette then
            palette = self:getTurnPalette() or {}
        elseif type(self.turn_palette) == "table" then
            palette = self.turn_palette
        end
        local palette_slots = palette_controls_layout.slots or 3
        local pill_gap = RuntimeUI.sized(palette_pills_layout.gap or 10)
        local pill_area_y = palette_rect.y + palette_label_h + RuntimeUI.sized(palette_pills_layout.top_gap or 6)
        local pill_area_h = palette_rect.h - palette_label_h - RuntimeUI.sized(palette_pills_layout.bottom_padding or 28)
        local pill_h = math.min(RuntimeUI.sized(palette_pills_layout.height_max or 26), pill_area_h)
        local pill_w = math.floor(
            (palette_rect.w - RuntimeUI.sized(palette_pills_layout.width_side_padding or 12) - pill_gap * (palette_slots - 1))
                / palette_slots
        )
        if pill_w < RuntimeUI.sized(palette_pills_layout.width_min or 22) then
            pill_w = RuntimeUI.sized(palette_pills_layout.width_min or 22)
        end
        local pills_total_w = pill_w * palette_slots + pill_gap * (palette_slots - 1)
        local pills_x = palette_rect.x + math.floor((palette_rect.w - pills_total_w) * 0.5)
        local pills_y = pill_area_y + math.floor((pill_area_h - pill_h) * 0.5)
        for i = 1, palette_slots do
            local color_key = palette[i]
            local rect = {
                x = pills_x + (i - 1) * (pill_w + pill_gap),
                y = pills_y,
                w = pill_w,
                h = pill_h,
            }
            if color_key then
                local base = DIE_COLOR_SWATCH[color_key] or {0.60, 0.50, 0.36}
                local c = boost_color(base, palette_pills_layout.boost or 0.14)
                local drops = folio and folio.getInkDrops and folio:getInkDrops(color_key) or 0
                local cap = folio and folio.getInkCap and folio:getInkCap(color_key) or drops
                local hover = point_in_rect(self.mouse_x, self.mouse_y, rect)
                local alpha = hover and (palette_pills_layout.alpha_hover or 1) or (palette_pills_layout.alpha_normal or 0.92)
                if drops <= 0 then
                    alpha = palette_pills_layout.alpha_empty or 0.36
                end
                love.graphics.setColor(c[1], c[2], c[3], alpha)
                love.graphics.rectangle(
                    "fill",
                    rect.x,
                    rect.y,
                    rect.w,
                    rect.h,
                    palette_pills_layout.corner_radius or 5,
                    palette_pills_layout.corner_radius or 5
                )
                local line = (color_key == "BIANCO")
                    and (palette_pills_layout.line_white or {0.12, 0.12, 0.12, 0.9})
                    or (palette_pills_layout.line_default or {0.96, 0.90, 0.82, 0.9})
                love.graphics.setColor(line[1], line[2], line[3], line[4])
                love.graphics.rectangle(
                    "line",
                    rect.x,
                    rect.y,
                    rect.w,
                    rect.h,
                    palette_pills_layout.corner_radius or 5,
                    palette_pills_layout.corner_radius or 5
                )
                if hover then
                    local hover_outline = palette_pills_layout.hover_outline or {}
                    local pulse = (love.timer and love.timer.getTime and (0.6 + 0.4 * math.sin(love.timer.getTime() * (hover_outline.pulse_speed or 4.0)))) or 0.6
                    local hover_color = hover_outline.color or {0.98, 0.92, 0.78}
                    local hover_expand = hover_outline.expand or 2
                    love.graphics.setColor(
                        hover_color[1] or 0.98,
                        hover_color[2] or 0.92,
                        hover_color[3] or 0.78,
                        (hover_outline.alpha_base or 0.35) + pulse * (hover_outline.alpha_pulse or 0.35)
                    )
                    love.graphics.setLineWidth(hover_outline.line_width or 2)
                    love.graphics.rectangle(
                        "line",
                        rect.x - hover_expand,
                        rect.y - hover_expand,
                        rect.w + hover_expand * 2,
                        rect.h + hover_expand * 2,
                        hover_outline.corner_radius or 6,
                        hover_outline.corner_radius or 6
                    )
                    love.graphics.setLineWidth(1)
                end
                local pill_icon = palette_pills_layout.icon or {}
                local icon_r = math.max(
                    pill_icon.radius_min or 2,
                    math.floor(rect.h * (pill_icon.radius_ratio or 0.18))
                )
                local icon_color = pill_icon.color or {0.16, 0.12, 0.08}
                love.graphics.setColor(
                    icon_color[1] or 0.16,
                    icon_color[2] or 0.12,
                    icon_color[3] or 0.08,
                    pill_icon.alpha or 0.85
                )
                love.graphics.circle(
                    "fill",
                    rect.x + icon_r + RuntimeUI.sized(pill_icon.x_offset or 2),
                    rect.y + rect.h * 0.5,
                    icon_r
                )
                local label = color_label(color_key)
                local pill_label = palette_pills_layout.label or {}
                local pill_dots = palette_pills_layout.dots or {}
                draw_text_center(label, {
                    x = rect.x,
                    y = rect.y - RuntimeUI.sized(pill_label.y_offset or 1),
                    w = rect.w,
                    h = math.floor(rect.h * (pill_label.height_ratio or 0.55)),
                }, get_font(pill_label.text_size or 8, true), drops <= 0
                        and (pill_label.text_color_empty or {0.18, 0.12, 0.08, 0.52})
                        or (pill_label.text_color or {0.18, 0.12, 0.08, 0.95}))
                draw_text_center(drops_to_dots(drops, cap), {
                    x = rect.x,
                    y = rect.y + math.floor(rect.h * (pill_dots.y_ratio or 0.48)),
                    w = rect.w,
                    h = math.floor(rect.h * (pill_dots.height_ratio or 0.42)),
                }, get_font(pill_dots.text_size or 8, false), drops <= 0
                        and (pill_dots.text_color_empty or {0.12, 0.08, 0.06, 0.48})
                        or (pill_dots.text_color or {0.12, 0.08, 0.06, 0.9}))
            else
                local empty_fill = palette_pills_layout.empty_fill_color or {0.18, 0.12, 0.08}
                local empty_line = palette_pills_layout.empty_line_color or {0.58, 0.44, 0.30}
                love.graphics.setColor(
                    empty_fill[1] or 0.18,
                    empty_fill[2] or 0.12,
                    empty_fill[3] or 0.08,
                    palette_pills_layout.empty_fill_alpha or 0.80
                )
                love.graphics.rectangle(
                    "fill",
                    rect.x,
                    rect.y,
                    rect.w,
                    rect.h,
                    palette_pills_layout.corner_radius or 5,
                    palette_pills_layout.corner_radius or 5
                )
                love.graphics.setColor(
                    empty_line[1] or 0.58,
                    empty_line[2] or 0.44,
                    empty_line[3] or 0.30,
                    palette_pills_layout.empty_line_alpha or 0.50
                )
                love.graphics.rectangle(
                    "line",
                    rect.x,
                    rect.y,
                    rect.w,
                    rect.h,
                    palette_pills_layout.corner_radius or 5,
                    palette_pills_layout.corner_radius or 5
                )
            end
        end

        do
            local fixed_text = tr(ScriptoriumUISchema.hud.turn_palette_fixed)
            local fixed_font = get_font(palette_fixed_label_layout.text_size or 10, false)
            local fixed_h = fixed_font:getHeight()
            local fixed_y = palette_rect.y + palette_rect.h - fixed_h - RuntimeUI.sized(palette_fixed_label_layout.y_offset or 5)
            local min_fixed_y = pills_y + pill_h + RuntimeUI.sized(palette_fixed_label_layout.y_min or 2)
            if fixed_y < min_fixed_y then
                fixed_y = min_fixed_y
            end
            draw_text_center(fixed_text, {
                x = palette_rect.x,
                y = fixed_y,
                w = palette_rect.w,
                h = fixed_h,
            }, fixed_font, palette_fixed_label_layout.text_color or {0.90, 0.82, 0.68, 0.85})
        end

        local moves_count = 0
        if placing_mode and folio and self.dice_results and #self.dice_results > 0 and #palette > 0 then
            for _, die in ipairs(self.dice_results) do
                if die and not die.used then
                    for _, color_key in ipairs(palette) do
                        for _, element in ipairs(folio.ELEMENTS or {}) do
                            local elem = folio.elements and folio.elements[element]
                            if elem and elem.unlocked and elem.pattern then
                                for row = 1, elem.pattern.rows do
                                    for col = 1, elem.pattern.cols do
                                        if folio:canPlaceDie(element, row, col, die.value, color_key) then
                                            moves_count = moves_count + 1
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        local moves_label = placing_mode and tr(ScriptoriumUISchema.hud.moves_label, {
            count = tostring(moves_count),
        }) or ""
        if moves_label ~= "" then
            local dot_x = dice_rect.x + RuntimeUI.sized(dice_moves_dot_layout.x or 10)
            local dot_y = dice_rect.y + dice_rect.h - RuntimeUI.sized(dice_moves_dot_layout.y or 12)
            local dot_r = RuntimeUI.sized(dice_moves_dot_layout.radius or 3)
            local dot_color = dice_moves_dot_layout.color or {0.92, 0.82, 0.62, 0.9}
            love.graphics.setColor(dot_color[1] or 0.92, dot_color[2] or 0.82, dot_color[3] or 0.62, dot_color[4] or 0.9)
            love.graphics.circle("fill", dot_x, dot_y, dot_r)
            draw_text_center(moves_label, {
                x = dice_rect.x,
                y = dice_rect.y + dice_rect.h - RuntimeUI.sized(dice_moves_text_layout.y or 18),
                w = dice_rect.w,
                h = RuntimeUI.sized(dice_moves_text_layout.height or 16),
            }, get_font(dice_moves_text_layout.size or 11, false), dice_moves_text_layout.color or {0.92, 0.84, 0.70, 1})
        end

        local wet_max = math.max(1, math.floor(tonumber(folio.wet_buffer_max) or 3))
        local wet_count = folio.getWetCount and folio:getWetCount() or 0
        local buffer_label_font = get_font(wet_buffer_title_layout.text_size or 11, false)
        local buffer_label_h = buffer_label_font:getHeight()
        draw_text_center(
            tr(ScriptoriumUISchema.hud.wet_buffer_title),
            {
                x = buffer_rect.x,
                y = buffer_rect.y + RuntimeUI.sized(wet_buffer_title_layout.y_offset or 2),
                w = buffer_rect.w,
                h = buffer_label_h,
            },
            buffer_label_font,
            wet_buffer_title_layout.text_color or {0.92, 0.84, 0.70, 1}
        )
        local bar_w = math.min(
            buffer_rect.w * (wet_buffer_meter_layout.width_ratio or 0.72),
            RuntimeUI.sized(wet_buffer_meter_layout.width_max or 140)
        )
        local bar_h = RuntimeUI.sized(wet_buffer_meter_layout.height or 8)
        local bar_x = buffer_rect.x + (buffer_rect.w - bar_w) * 0.5
        local bar_y = buffer_rect.y + buffer_label_h + RuntimeUI.sized(wet_buffer_meter_layout.y_gap or 4)
        local seg_gap = RuntimeUI.sized(wet_buffer_meter_layout.segment_gap or 4)
        local seg_w = math.max(
            RuntimeUI.sized(wet_buffer_meter_layout.segment_min or 10),
            math.floor((bar_w - seg_gap * (wet_max - 1)) / wet_max)
        )
        local bar_total = seg_w * wet_max + seg_gap * (wet_max - 1)
        local bar_start = bar_x + (bar_w - bar_total) * 0.5
        local meter_bg = wet_buffer_meter_layout.background_color or {0.20, 0.14, 0.09}
        local meter_fill = wet_buffer_meter_layout.fill_color or {0.92, 0.74, 0.44}
        local meter_line = wet_buffer_meter_layout.line_color or {0.55, 0.40, 0.26}
        for i = 1, wet_max do
            local filled = i <= wet_count
            local pulse = 0
            if wet_count >= wet_max and love.timer and love.timer.getTime then
                pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * (wet_buffer_meter_layout.fill_pulse_speed or 5.0) + i)
            end
            local seg_x = bar_start + (i - 1) * (seg_w + seg_gap)
            love.graphics.setColor(
                meter_bg[1] or 0.20,
                meter_bg[2] or 0.14,
                meter_bg[3] or 0.09,
                wet_buffer_meter_layout.background_alpha or 0.85
            )
            love.graphics.rectangle(
                "fill",
                seg_x,
                bar_y,
                seg_w,
                bar_h,
                wet_buffer_meter_layout.segment_corner or 3,
                wet_buffer_meter_layout.segment_corner or 3
            )
            if filled then
                love.graphics.setColor(
                    meter_fill[1] or 0.92,
                    (meter_fill[2] or 0.74) + pulse * (wet_buffer_meter_layout.fill_pulse_g or 0.06),
                    meter_fill[3] or 0.44,
                    wet_buffer_meter_layout.fill_alpha or 0.95
                )
                love.graphics.rectangle(
                    "fill",
                    seg_x,
                    bar_y,
                    seg_w,
                    bar_h,
                    wet_buffer_meter_layout.segment_corner or 3,
                    wet_buffer_meter_layout.segment_corner or 3
                )
            else
                love.graphics.setColor(
                    meter_line[1] or 0.55,
                    meter_line[2] or 0.40,
                    meter_line[3] or 0.26,
                    wet_buffer_meter_layout.line_alpha or 0.55
                )
                love.graphics.rectangle(
                    "line",
                    seg_x,
                    bar_y,
                    seg_w,
                    bar_h,
                    wet_buffer_meter_layout.segment_corner or 3,
                    wet_buffer_meter_layout.segment_corner or 3
                )
            end
        end
        local wet_ratio_text = tr(ScriptoriumUISchema.hud.counter_ratio, {
            current = wet_count,
            max = wet_max,
        })
        if wet_ratio_text == "" then
            wet_ratio_text = string.format("%d/%d", wet_count, wet_max)
        end
        draw_text_center(
            wet_ratio_text,
            {
                x = buffer_rect.x,
                y = bar_y + bar_h + RuntimeUI.sized(wet_buffer_meter_layout.count_y_gap or 2),
                w = buffer_rect.w,
                h = RuntimeUI.sized(wet_buffer_meter_layout.count_height or 12),
            },
            get_font(wet_buffer_meter_layout.count_text_size or 10, false),
            wet_buffer_meter_layout.count_text_color or {0.86, 0.78, 0.66, 0.9}
        )
        local slot_gap = RuntimeUI.sized(wet_buffer_slots_layout.gap or 6)
        local slot_area_y = bar_y + bar_h + RuntimeUI.sized(wet_buffer_slots_layout.top_offset or 14)
        local slot_area_h = buffer_rect.h - (slot_area_y - buffer_rect.y) - RuntimeUI.sized(wet_buffer_slots_layout.bottom_padding or 8)
        local slot_w = math.floor((buffer_rect.w - RuntimeUI.sized(12) - slot_gap * (wet_max - 1)) / wet_max)
        slot_w = math.max(RuntimeUI.sized(wet_buffer_slots_layout.min_size or 22), math.min(slot_area_h, slot_w))
        local slots_total_w = slot_w * wet_max + slot_gap * (wet_max - 1)
        local slots_x = buffer_rect.x + math.floor((buffer_rect.w - slots_total_w) * 0.5)
        local slots_y = slot_area_y + math.floor((slot_area_h - slot_w) * 0.5)
        local wet_entries = folio.wet_buffer or {}
        local can_undo = placing_mode and (math.max(0, math.floor(tonumber(folio.turn_pushes) or 0)) == 0)
        local slot_fill = wet_buffer_slots_layout.fill_color or {0.20, 0.14, 0.09}
        local slot_line = wet_buffer_slots_layout.line_color or {0.70, 0.52, 0.33}
        for i = 1, wet_max do
            local rect = {
                x = slots_x + (i - 1) * (slot_w + slot_gap),
                y = slots_y,
                w = slot_w,
                h = slot_w,
            }
            love.graphics.setColor(
                slot_fill[1] or 0.20,
                slot_fill[2] or 0.14,
                slot_fill[3] or 0.09,
                wet_buffer_slots_layout.fill_alpha or 0.86
            )
            love.graphics.rectangle(
                "fill",
                rect.x,
                rect.y,
                rect.w,
                rect.h,
                wet_buffer_slots_layout.corner or 4,
                wet_buffer_slots_layout.corner or 4
            )
            love.graphics.setColor(
                slot_line[1] or 0.70,
                slot_line[2] or 0.52,
                slot_line[3] or 0.33,
                wet_buffer_slots_layout.line_alpha or 0.48
            )
            love.graphics.rectangle(
                "line",
                rect.x,
                rect.y,
                rect.w,
                rect.h,
                wet_buffer_slots_layout.corner or 4,
                wet_buffer_slots_layout.corner or 4
            )
            local entry = wet_entries[i]
            if entry then
                local c = DIE_COLOR_SWATCH[entry.color] or {0.70, 0.52, 0.33}
                local outer_expand = wet_buffer_entry_layout.outer_expand or 2
                local inner_inset = wet_buffer_entry_layout.inner_inset or 2
                love.graphics.setColor(c[1], c[2], c[3], wet_buffer_entry_layout.outer_alpha or 0.35)
                love.graphics.rectangle(
                    "fill",
                    rect.x - outer_expand,
                    rect.y - outer_expand,
                    rect.w + outer_expand * 2,
                    rect.h + outer_expand * 2,
                    wet_buffer_entry_layout.outer_corner or 4,
                    wet_buffer_entry_layout.outer_corner or 4
                )
                love.graphics.setColor(c[1], c[2], c[3], wet_buffer_entry_layout.inner_alpha or 0.92)
                love.graphics.rectangle(
                    "fill",
                    rect.x + inner_inset,
                    rect.y + inner_inset,
                    rect.w - inner_inset * 2,
                    rect.h - inner_inset * 2,
                    wet_buffer_entry_layout.inner_corner or 3,
                    wet_buffer_entry_layout.inner_corner or 3
                )
                local value_color = wet_buffer_entry_layout.value_color or {0.15, 0.10, 0.08, 0.9}
                love.graphics.setColor(value_color[1] or 0.15, value_color[2] or 0.10, value_color[3] or 0.08, value_color[4] or 0.9)
                love.graphics.setFont(get_font(wet_buffer_entry_layout.value_text_size or 12, true))
                love.graphics.printf(
                    tostring(entry.value or "?"),
                    rect.x,
                    rect.y + rect.h * (wet_buffer_entry_layout.value_y_ratio or 0.22),
                    rect.w,
                    "center"
                )
                local drop_r = math.max(
                    wet_buffer_entry_layout.drop_radius_min or 3,
                    math.floor(rect.w * (wet_buffer_entry_layout.drop_radius_ratio or 0.12))
                )
                local drop_inset = wet_buffer_entry_layout.drop_inset or 3
                local drop_fill = wet_buffer_entry_layout.drop_fill_color or {0.95, 0.90, 0.70}
                local drop_line = wet_buffer_entry_layout.drop_line_color or {0.32, 0.22, 0.12}
                love.graphics.setColor(drop_fill[1] or 0.95, drop_fill[2] or 0.90, drop_fill[3] or 0.70, wet_buffer_entry_layout.drop_fill_alpha or 0.95)
                love.graphics.circle("fill", rect.x + rect.w - drop_r - drop_inset, rect.y + rect.h - drop_r - drop_inset, drop_r)
                love.graphics.setColor(drop_line[1] or 0.32, drop_line[2] or 0.22, drop_line[3] or 0.12, wet_buffer_entry_layout.drop_line_alpha or 0.82)
                love.graphics.circle("line", rect.x + rect.w - drop_r - drop_inset, rect.y + rect.h - drop_r - drop_inset, drop_r)
                if can_undo and (not interaction_locked) then
                    local undo_w = math.max(
                        wet_buffer_undo_layout.width_min or 10,
                        math.floor(rect.w * (wet_buffer_undo_layout.width_ratio or 0.36))
                    )
                    local undo_inset = wet_buffer_undo_layout.inset or 2
                    local undo_rect = {
                        x = rect.x + rect.w - undo_w - undo_inset,
                        y = rect.y + undo_inset,
                        w = undo_w,
                        h = undo_w,
                    }
                    local undo_fill = wet_buffer_undo_layout.fill_color or {0.18, 0.12, 0.08}
                    local undo_line = wet_buffer_undo_layout.line_color or {0.86, 0.70, 0.46}
                    local undo_text = wet_buffer_undo_layout.text_color or {0.98, 0.94, 0.86, 1}
                    local undo_corner = wet_buffer_undo_layout.corner or 3
                    love.graphics.setColor(
                        undo_fill[1] or 0.18,
                        undo_fill[2] or 0.12,
                        undo_fill[3] or 0.08,
                        wet_buffer_undo_layout.fill_alpha or 0.90
                    )
                    love.graphics.rectangle("fill", undo_rect.x, undo_rect.y, undo_rect.w, undo_rect.h, undo_corner, undo_corner)
                    love.graphics.setColor(
                        undo_line[1] or 0.86,
                        undo_line[2] or 0.70,
                        undo_line[3] or 0.46,
                        wet_buffer_undo_layout.line_alpha or 0.88
                    )
                    love.graphics.rectangle("line", undo_rect.x, undo_rect.y, undo_rect.w, undo_rect.h, undo_corner, undo_corner)
                    love.graphics.setFont(get_font(wet_buffer_undo_layout.text_size or 9, true))
                    love.graphics.setColor(undo_text[1] or 0.98, undo_text[2] or 0.94, undo_text[3] or 0.86, undo_text[4] or 1)
                    love.graphics.printf(
                        tr(ScriptoriumUISchema.hud.wet_buffer_undo_short),
                        undo_rect.x,
                        undo_rect.y + RuntimeUI.sized(wet_buffer_undo_layout.text_y_offset or 1),
                        undo_rect.w,
                        "center"
                    )
                    self.ui_hit.wet_buffer_undo_buttons[#self.ui_hit.wet_buffer_undo_buttons + 1] = {
                        index = i,
                        rect = undo_rect,
                    }
                end
            end
        end

        if self.palette_picker and self.palette_picker.options and #self.palette_picker.options > 0 then
            local picker = self.palette_picker
            local options = picker.options
            picker.hover_color = nil
            local btn_size = RuntimeUI.sized(palette_picker_layout.button_size or 20)
            local btn_gap = RuntimeUI.sized(palette_picker_layout.button_gap or 8)
            local picker_w = (#options * btn_size)
                + (math.max(0, #options - 1) * btn_gap)
                + RuntimeUI.sized(palette_picker_layout.width_padding or 14)
            local picker_h = btn_size + RuntimeUI.sized(palette_picker_layout.height_padding or 10)
            local px = (picker.anchor_x or (palette_rect.x + palette_rect.w * 0.5)) - picker_w * 0.5
            local py = (picker.anchor_y or (dock_y - RuntimeUI.sized(palette_picker_layout.anchor_y_offset or 8)))
                - picker_h
                - RuntimeUI.sized(palette_picker_layout.panel_gap or 6)
            local min_x = dock_x + RuntimeUI.sized(palette_picker_layout.min_margin or 6)
            local max_x = dock_x + dock_w - RuntimeUI.sized(palette_picker_layout.min_margin or 6) - picker_w
            if px < min_x then
                px = min_x
            end
            if px > max_x then
                px = max_x
            end
            local min_y = RuntimeUI.sized(palette_picker_layout.min_margin or 6)
            local picker_max_y = dock_y - picker_h - RuntimeUI.sized(palette_picker_layout.panel_gap or 6)
            if picker_max_y < min_y then
                picker_max_y = min_y
            end
            if py < min_y then
                py = min_y
            end
            if py > picker_max_y then
                py = picker_max_y
            end

            local picker_fill = palette_picker_layout.panel_fill_color or {0.15, 0.11, 0.07}
            local picker_line = palette_picker_layout.panel_line_color or {0.82, 0.65, 0.42}
            local picker_corner = palette_picker_layout.corner_radius or 6
            love.graphics.setColor(
                picker_fill[1] or 0.15,
                picker_fill[2] or 0.11,
                picker_fill[3] or 0.07,
                palette_picker_layout.panel_fill_alpha or 0.96
            )
            love.graphics.rectangle("fill", px, py, picker_w, picker_h, picker_corner, picker_corner)
            love.graphics.setColor(
                picker_line[1] or 0.82,
                picker_line[2] or 0.65,
                picker_line[3] or 0.42,
                palette_picker_layout.panel_line_alpha or 0.72
            )
            love.graphics.rectangle("line", px, py, picker_w, picker_h, picker_corner, picker_corner)

            self.ui_hit.palette_color_buttons = {}
            local bx = px + RuntimeUI.sized(palette_picker_layout.x_padding or 7)
            local by = py + RuntimeUI.sized(palette_picker_layout.y_padding or 5)
            for i, color_key in ipairs(options) do
                local rect = {x = bx + (i - 1) * (btn_size + btn_gap), y = by, w = btn_size, h = btn_size}
                local c = DIE_COLOR_SWATCH[color_key] or {0.55, 0.35, 0.20}
                local hover = point_in_rect(self.mouse_x, self.mouse_y, rect)
                love.graphics.setColor(
                    c[1],
                    c[2],
                    c[3],
                    hover and (palette_picker_layout.item_alpha_hover or 1) or (palette_picker_layout.item_alpha or 0.95)
                )
                love.graphics.rectangle(
                    "fill",
                    rect.x,
                    rect.y,
                    rect.w,
                    rect.h,
                    palette_picker_layout.item_corner or 4,
                    palette_picker_layout.item_corner or 4
                )
                local line = (color_key == "BIANCO") and {0.12, 0.12, 0.12, 0.9} or {0.96, 0.90, 0.82, 0.9}
                love.graphics.setColor(line[1], line[2], line[3], line[4])
                love.graphics.rectangle(
                    "line",
                    rect.x,
                    rect.y,
                    rect.w,
                    rect.h,
                    palette_picker_layout.item_corner or 4,
                    palette_picker_layout.item_corner or 4
                )
                if hover then
                    picker.hover_color = color_key
                end
                self.ui_hit.palette_color_buttons[#self.ui_hit.palette_color_buttons + 1] = {
                    color = color_key,
                    rect = rect,
                }
            end
        end

        local function fit_font(target_px, decorative, max_h)
            local px = target_px
            local f = get_font(px, decorative)
            while px > 8 and f:getHeight() > max_h do
                px = px - 1
                f = get_font(px, decorative)
            end
            return f
        end

        local function draw_action(rect, title, subtitle, base_color, line_color, enabled, title_px, subtitle_px)
            local hover = enabled and point_in_rect(self.mouse_x, self.mouse_y, rect)
            local alpha = enabled
                and (hover and (action_button_layout.alpha_hover or 0.96) or (action_button_layout.alpha_normal or 0.88))
                or (action_button_layout.alpha_disabled or 0.40)
            love.graphics.setColor(base_color[1], base_color[2], base_color[3], alpha)
            local action_corner = action_button_layout.corner_radius or 6
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, action_corner, action_corner)
            love.graphics.setColor(line_color[1], line_color[2], line_color[3], alpha)
            love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, action_corner, action_corner)
            local max_title_h = math.max(
                RuntimeUI.sized(action_text_layout.title_min_height or 12),
                math.floor(rect.h * (action_text_layout.title_ratio or 0.50))
            )
            local max_subtitle_h = math.max(
                RuntimeUI.sized(action_text_layout.subtitle_min_height or 10),
                math.floor(rect.h * (action_text_layout.subtitle_ratio or 0.32))
            )
            local title_font = fit_font(title_px or 16, true, max_title_h)
            local subtitle_font = fit_font(subtitle_px or 10, false, max_subtitle_h)
            local title_h = title_font:getHeight()
            local subtitle_h = subtitle_font:getHeight()
            local spacing = RuntimeUI.sized(action_text_layout.spacing or 2)
            local content_h = title_h + subtitle_h + spacing
            local text_top = rect.y + math.max(
                RuntimeUI.sized(action_text_layout.top_padding or 4),
                math.floor((rect.h - content_h) * 0.5)
            )
            local title_color = action_text_layout.title_color or {0.98, 0.93, 0.84, 1}
            local subtitle_color = action_text_layout.subtitle_color or {0.98, 0.93, 0.84, 1}
            draw_text_center(title, {
                x = rect.x,
                y = text_top,
                w = rect.w,
                h = title_h,
            }, title_font, {
                title_color[1] or 0.98,
                title_color[2] or 0.93,
                title_color[3] or 0.84,
                enabled and 1 or (action_text_layout.title_alpha_disabled or 0.55),
            })
            if subtitle and subtitle ~= "" then
                draw_text_center(subtitle, {
                    x = rect.x,
                    y = text_top + title_h + spacing,
                    w = rect.w,
                    h = subtitle_h,
                }, subtitle_font, {
                    subtitle_color[1] or 0.98,
                    subtitle_color[2] or 0.93,
                    subtitle_color[3] or 0.84,
                    enabled and (action_text_layout.subtitle_alpha_enabled or 0.95) or (action_text_layout.subtitle_alpha_disabled or 0.45),
                })
            end
        end

        if placing_mode then
            local wet_full = wet_count >= wet_max
            local reroll_max = tonumber(folio.reroll_max)
            if reroll_max ~= nil then
                reroll_max = math.max(0, math.floor(reroll_max))
            end
            local reroll_used = math.max(0, math.floor(tonumber(folio.turn_pushes) or 0))
            local reroll_left = reroll_max and math.max(0, reroll_max - reroll_used) or nil
            local has_placed = false
            for _, die in ipairs(self.dice_results or {}) do
                if die and die.used then
                    has_placed = true
                    break
                end
            end
            local can_reroll = (not interaction_locked) and has_placed and (not wet_full) and ((reroll_left == nil) or (reroll_left > 0))
            local can_commit = (not interaction_locked) and (wet_count > 0)

            local action_text_h = RuntimeUI.sized(placing_action_layout.text_height or 16)
            local action_btn_h = seg_h - action_text_h - RuntimeUI.sized(placing_action_layout.text_gap or 4)
            if action_btn_h < RuntimeUI.sized(placing_action_layout.min_button_height or 44) then
                action_btn_h = seg_h
                action_text_h = 0
            end
            local action_btn_y = seg_y
            local action_text_y = seg_y + action_btn_h + RuntimeUI.sized(placing_action_layout.text_gap or 4)

            local reroll_btn = {x = reroll_rect.x, y = action_btn_y, w = reroll_rect.w, h = action_btn_h}
            local commit_btn = {x = commit_rect.x, y = action_btn_y, w = commit_rect.w, h = action_btn_h}

            local reroll_sub = tr(ScriptoriumUISchema.hud.action_reroll_sub_available)
            if reroll_max then
                reroll_sub = tr(ScriptoriumUISchema.hud.counter_ratio, {
                    current = reroll_left or 0,
                    max = reroll_max,
                })
                if reroll_sub == "" then
                    reroll_sub = string.format("%d/%d", reroll_left or 0, reroll_max)
                end
            end
            draw_action(
                reroll_btn,
                tr(ScriptoriumUISchema.hud.action_reroll_title),
                reroll_sub,
                reroll_button_layout.fill_color or {0.24, 0.22, 0.18},
                reroll_button_layout.line_color or {0.60, 0.54, 0.46},
                can_reroll,
                reroll_button_layout.title_size or 15,
                reroll_button_layout.subtitle_size or 10
            )

            local commit_fill = commit_button_layout.fill_color or {0.78, 0.62, 0.36}
            local commit_line = commit_button_layout.line_color or {0.98, 0.88, 0.66}
            local commit_sub = ""
            if wet_count <= 0 then
                commit_fill = commit_button_layout.fill_color_empty or {0.30, 0.24, 0.20}
                commit_line = commit_button_layout.line_color_empty or {0.60, 0.50, 0.40}
                commit_sub = ""
            elseif wet_full then
                local pulse_speed = commit_button_layout.pulse_speed or 4.0
                local pulse = (love.timer and love.timer.getTime and (0.6 + 0.4 * math.sin(love.timer.getTime() * pulse_speed))) or 0.6
                local commit_fill_saturated = commit_button_layout.fill_color_saturated or {0.86, 0.66, 0.34}
                commit_fill = {
                    commit_fill_saturated[1] or 0.86,
                    (commit_fill_saturated[2] or 0.66) + pulse * (commit_button_layout.fill_pulse_gain or 0.05),
                    commit_fill_saturated[3] or 0.34,
                }
                commit_line = commit_button_layout.line_color_saturated or {1.00, 0.90, 0.66}
                commit_sub = tr(ScriptoriumUISchema.hud.action_commit_sub_saturated)
            end
            draw_action(
                commit_btn,
                tr(ScriptoriumUISchema.hud.action_commit_title),
                commit_sub,
                commit_fill,
                commit_line,
                can_commit,
                commit_button_layout.title_size or 16,
                commit_button_layout.subtitle_size or 10
            )

            self.ui_hit.push_all_button = can_reroll and reroll_btn or nil
            self.ui_hit.stop_button = can_commit and commit_btn or nil

            if action_text_h > 0 then
                local bust_wet_count = folio.getWetCount and folio:getWetCount() or 0
                local penalty = math.max(1, bust_wet_count)
                local penalty_text = tr(ScriptoriumUISchema.hud.bust_penalty, {
                    count = penalty,
                    suffix = penalty == 1 and "" or tr(ScriptoriumUISchema.hud.bust_penalty_suffix_plural),
                })
                draw_text_center(penalty_text, {
                    x = reroll_rect.x,
                    y = action_text_y,
                    w = reroll_rect.w + gap + commit_rect.w,
                    h = action_text_h,
                }, get_font(placing_action_layout.penalty_text_size or 11, false), placing_action_layout.penalty_text_color or {0.92, 0.60, 0.56, 0.95})
            end
        else
            local roll_w = reroll_rect.w + gap + commit_rect.w
            local roll_rect = {x = reroll_rect.x, y = reroll_rect.y, w = roll_w, h = reroll_rect.h}
            local can_roll = (self.state == "waiting") and (not interaction_locked)
            local title = can_roll
                and tr(ScriptoriumUISchema.hud.action_roll_title_ready)
                or tr(ScriptoriumUISchema.hud.action_roll_title_wait)
            local subtitle = can_roll
                and tr(ScriptoriumUISchema.hud.action_roll_sub_ready)
                or tr(ScriptoriumUISchema.hud.action_roll_sub_wait)
            draw_action(
                roll_rect,
                title,
                subtitle,
                roll_button_layout.fill_color or {0.22, 0.45, 0.24},
                roll_button_layout.line_color or {0.70, 0.88, 0.64},
                can_roll,
                roll_button_layout.title_size or 18,
                roll_button_layout.subtitle_size or 11
            )
            self.ui_hit.roll_button = can_roll and roll_rect or nil
        end

        local function draw_system_menu_controls()
            self.ui_hit.system_button = nil
            self.ui_hit.system_settings_button = nil
            self.ui_hit.system_main_menu_button = nil
            self.ui_hit.system_restart_button = nil

            local system_button_size = RuntimeUI.sized(system_button_layout.size or 28)
            local system_rect = {
                x = dock_x + dock_w - RuntimeUI.sized(system_button_layout.x_offset or 36),
                y = dock_y + RuntimeUI.sized(system_button_layout.y_offset or 6),
                w = system_button_size,
                h = system_button_size,
            }
            self.ui_hit.system_button = system_rect
            local menu_open = self.show_system_menu and true or false
            local system_hover = point_in_rect(self.mouse_x, self.mouse_y, system_rect)
            local system_alpha = (system_hover or menu_open)
                and (system_button_layout.alpha_active or 0.96)
                or (system_button_layout.alpha_normal or 0.84)
            local system_button_fill = system_button_layout.fill_color or {0.28, 0.19, 0.12}
            local system_button_line = system_button_layout.line_color or {0.78, 0.60, 0.38}
            local system_button_corner = system_button_layout.corner_radius or 6
            love.graphics.setColor(
                system_button_fill[1] or 0.28,
                system_button_fill[2] or 0.19,
                system_button_fill[3] or 0.12,
                system_alpha
            )
            love.graphics.rectangle("fill", system_rect.x, system_rect.y, system_rect.w, system_rect.h, system_button_corner, system_button_corner)
            love.graphics.setColor(
                system_button_line[1] or 0.78,
                system_button_line[2] or 0.60,
                system_button_line[3] or 0.38,
                system_alpha
            )
            love.graphics.rectangle("line", system_rect.x, system_rect.y, system_rect.w, system_rect.h, system_button_corner, system_button_corner)

            local cx = system_rect.x + system_rect.w * 0.5
            local cy = system_rect.y + system_rect.h * 0.5
            local outer_r = RuntimeUI.sized(system_icon_layout.outer_radius or 6)
            local inner_r = RuntimeUI.sized(system_icon_layout.inner_radius or 2)
            local system_icon_color = system_icon_layout.color or {0.97, 0.92, 0.84}
            local spoke_count = system_icon_layout.spoke_count or 8
            love.graphics.setColor(
                system_icon_color[1] or 0.97,
                system_icon_color[2] or 0.92,
                system_icon_color[3] or 0.84,
                system_icon_layout.alpha or 0.94
            )
            love.graphics.setLineWidth(system_icon_layout.line_width or 2)
            for i = 0, spoke_count - 1 do
                local a = (i / spoke_count) * math.pi * 2
                local sx = cx + math.cos(a) * RuntimeUI.sized(system_icon_layout.spoke_inner or 4)
                local sy = cy + math.sin(a) * RuntimeUI.sized(system_icon_layout.spoke_inner or 4)
                local ex = cx + math.cos(a) * RuntimeUI.sized(system_icon_layout.spoke_outer or 7)
                local ey = cy + math.sin(a) * RuntimeUI.sized(system_icon_layout.spoke_outer or 7)
                love.graphics.line(sx, sy, ex, ey)
            end
            love.graphics.circle("line", cx, cy, outer_r)
            love.graphics.circle("fill", cx, cy, inner_r)
            love.graphics.setLineWidth(1)

            if menu_open then
                local item_h = RuntimeUI.sized(system_panel_layout.item_height or 28)
                local panel_w = RuntimeUI.sized(system_panel_layout.width or 170)
                local panel_h = item_h * 3 + RuntimeUI.sized(system_panel_layout.vertical_padding or 10)
                local panel_x = system_rect.x + system_rect.w - panel_w
                local panel_y = system_rect.y - panel_h - RuntimeUI.sized(system_panel_layout.y_offset or 6)
                if panel_y < RuntimeUI.sized(system_panel_layout.top_min or 4) then
                    panel_y = system_rect.y + system_rect.h + RuntimeUI.sized(system_panel_layout.y_offset or 6)
                end
                local panel = {x = panel_x, y = panel_y, w = panel_w, h = panel_h}
                local panel_edge_padding = RuntimeUI.sized(system_panel_layout.edge_padding or 4)
                local restart_rect = {
                    x = panel_x + panel_edge_padding,
                    y = panel_y + panel_edge_padding,
                    w = panel_w - panel_edge_padding * 2,
                    h = item_h,
                }
                local settings_rect = {
                    x = panel_x + panel_edge_padding,
                    y = panel_y + panel_edge_padding + item_h,
                    w = panel_w - panel_edge_padding * 2,
                    h = item_h,
                }
                local main_menu_rect = {
                    x = panel_x + panel_edge_padding,
                    y = settings_rect.y + item_h,
                    w = panel_w - panel_edge_padding * 2,
                    h = item_h,
                }
                self.ui_hit.system_restart_button = restart_rect
                self.ui_hit.system_settings_button = settings_rect
                self.ui_hit.system_main_menu_button = main_menu_rect

                local restart_hover = point_in_rect(self.mouse_x, self.mouse_y, restart_rect)
                local settings_hover = point_in_rect(self.mouse_x, self.mouse_y, settings_rect)
                local main_hover = point_in_rect(self.mouse_x, self.mouse_y, main_menu_rect)
                local panel_fill = system_panel_layout.fill_color or {0.14, 0.10, 0.07}
                local panel_line = system_panel_layout.line_color or {0.80, 0.62, 0.40}
                local panel_corner = system_panel_layout.corner_radius or 6
                love.graphics.setColor(
                    panel_fill[1] or 0.14,
                    panel_fill[2] or 0.10,
                    panel_fill[3] or 0.07,
                    system_panel_layout.fill_alpha or 0.96
                )
                love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, panel_corner, panel_corner)
                love.graphics.setColor(
                    panel_line[1] or 0.80,
                    panel_line[2] or 0.62,
                    panel_line[3] or 0.40,
                    system_panel_layout.line_alpha or 0.82
                )
                love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, panel_corner, panel_corner)

                local item_fill = system_item_layout.fill_color or {0.26, 0.18, 0.11}
                local item_line = system_item_layout.line_color or {0.74, 0.58, 0.36}
                local item_text_color = system_item_layout.text_color or {0.97, 0.92, 0.84, 1}
                local item_corner = system_item_layout.corner_radius or 4
                local function draw_menu_item(rect, hovered, label, text_size)
                    love.graphics.setColor(
                        item_fill[1] or 0.26,
                        item_fill[2] or 0.18,
                        item_fill[3] or 0.11,
                        hovered and (system_item_layout.fill_alpha_hover or 0.96) or (system_item_layout.fill_alpha_normal or 0.86)
                    )
                    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, item_corner, item_corner)
                    love.graphics.setColor(
                        item_line[1] or 0.74,
                        item_line[2] or 0.58,
                        item_line[3] or 0.36,
                        hovered and (system_item_layout.line_alpha_hover or 0.94) or (system_item_layout.line_alpha_normal or 0.68)
                    )
                    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, item_corner, item_corner)
                    draw_text_center(label, rect, get_font(text_size, true), item_text_color)
                end

                draw_menu_item(
                    restart_rect,
                    restart_hover,
                    tr(ScriptoriumUISchema.hud.system_restart_folio),
                    system_item_layout.restart_text_size or 10
                )
                draw_menu_item(
                    settings_rect,
                    settings_hover,
                    tr(ScriptoriumUISchema.hud.system_settings),
                    system_item_layout.text_size or 11
                )
                draw_menu_item(
                    main_menu_rect,
                    main_hover,
                    tr(ScriptoriumUISchema.hud.system_main_menu),
                    system_item_layout.text_size or 11
                )
            end
        end

        draw_system_menu_controls()
    end
    return methods
end

return Hud


