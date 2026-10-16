local Overlays = {}
local EngineBridge = require("src.core.engine_bridge")
local I18n = require("src.core.i18n")
local Schema = require("src.core.schema")
local ScriptoriumUISchema = require("src.data.scriptorium_ui_schema")

local function tr(entry, params)
    if type(entry) ~= "table" then
        return ""
    end
    return I18n.t(entry.key, entry.default, params)
end

local expect_table = Schema.expect_table
local expect_number = Schema.expect_number
local expect_color3 = Schema.expect_color3
local expect_color4 = Schema.expect_color4

function Overlays.new(deps)
    local RuntimeUI = deps.RuntimeUI
    local ResolutionManager = deps.ResolutionManager
    local OVERLAY_LAYOUT = expect_table(deps.OVERLAY_LAYOUT, "deps.OVERLAY_LAYOUT")
    local ui_dimensions = deps.ui_dimensions
    local get_font = deps.get_font
    local draw_text_center = deps.draw_text_center
    local point_in_rect = deps.point_in_rect
    local clamp = deps.clamp
    local COLOR_SWATCH = expect_table(deps.color_swatch, "deps.color_swatch")
    local MESSAGE_LAYOUT = expect_table(OVERLAY_LAYOUT.message, "deps.OVERLAY_LAYOUT.message")
    local SETUP_LAYOUT = expect_table(OVERLAY_LAYOUT.setup, "deps.OVERLAY_LAYOUT.setup")
    local RULING_LAYOUT = expect_table(OVERLAY_LAYOUT.ruling, "deps.OVERLAY_LAYOUT.ruling")
    local RESULT_LAYOUT = expect_table(OVERLAY_LAYOUT.result, "deps.OVERLAY_LAYOUT.result")
    local LOCK_TOOLTIP_LAYOUT = expect_table(OVERLAY_LAYOUT.lock_tooltip, "deps.OVERLAY_LAYOUT.lock_tooltip")

    local methods = {}

    function methods.drawMessageOverlay(self)
        if not self.message then
            return
        end

        local message_layout = MESSAGE_LAYOUT
        local message_box_layout = expect_table(message_layout.box, "deps.OVERLAY_LAYOUT.message.box")
        local message_title_layout = expect_table(message_layout.title, "deps.OVERLAY_LAYOUT.message.title")
        local message_subtext_layout = expect_table(message_layout.subtext, "deps.OVERLAY_LAYOUT.message.subtext")
        local message_box_fill = expect_color3(message_box_layout.fill_color, "deps.OVERLAY_LAYOUT.message.box.fill_color")
        local message_box_line = expect_color3(message_box_layout.line_color, "deps.OVERLAY_LAYOUT.message.box.line_color")
        local message_title_color = expect_color4(message_title_layout.text_color, "deps.OVERLAY_LAYOUT.message.title.text_color")
        local message_subtext_color = expect_color4(message_subtext_layout.text_color, "deps.OVERLAY_LAYOUT.message.subtext.text_color")
        local w, h = ui_dimensions()
        love.graphics.setColor(0, 0, 0, expect_number(message_layout.backdrop_alpha, "deps.OVERLAY_LAYOUT.message.backdrop_alpha"))
        love.graphics.rectangle("fill", 0, 0, w, h)

        local box_w = math.min(
            RuntimeUI.sized(expect_number(message_box_layout.width_max, "deps.OVERLAY_LAYOUT.message.box.width_max")),
            w * expect_number(message_box_layout.width_ratio, "deps.OVERLAY_LAYOUT.message.box.width_ratio")
        )
        local box_h = RuntimeUI.sized(expect_number(message_box_layout.height, "deps.OVERLAY_LAYOUT.message.box.height"))
        local box_x = (w - box_w) * 0.5
        local box_y = (h - box_h) * 0.5

        love.graphics.setColor(
            message_box_fill[1],
            message_box_fill[2],
            message_box_fill[3],
            expect_number(message_box_layout.fill_alpha, "deps.OVERLAY_LAYOUT.message.box.fill_alpha")
        )
        local box_corner = expect_number(message_box_layout.corner_radius, "deps.OVERLAY_LAYOUT.message.box.corner_radius")
        love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, box_corner, box_corner)
        love.graphics.setColor(
            message_box_line[1],
            message_box_line[2],
            message_box_line[3],
            expect_number(message_box_layout.line_alpha, "deps.OVERLAY_LAYOUT.message.box.line_alpha")
        )
        love.graphics.setLineWidth(expect_number(message_box_layout.line_width, "deps.OVERLAY_LAYOUT.message.box.line_width"))
        love.graphics.rectangle("line", box_x, box_y, box_w, box_h, box_corner, box_corner)
        love.graphics.setLineWidth(1)

        draw_text_center(
            self.message.text or "",
            {
                x = box_x,
                y = box_y + RuntimeUI.sized(expect_number(message_title_layout.y_offset, "deps.OVERLAY_LAYOUT.message.title.y_offset")),
                w = box_w,
                h = RuntimeUI.sized(expect_number(message_title_layout.height, "deps.OVERLAY_LAYOUT.message.title.height")),
            },
            get_font(expect_number(message_title_layout.text_size, "deps.OVERLAY_LAYOUT.message.title.text_size"), true),
            message_title_color
        )

        if self.message.subtext then
            local subtext_pad = RuntimeUI.sized(expect_number(message_subtext_layout.x_padding, "deps.OVERLAY_LAYOUT.message.subtext.x_padding"))
            draw_text_center(
                self.message.subtext,
                {
                    x = box_x + subtext_pad,
                    y = box_y + RuntimeUI.sized(expect_number(message_subtext_layout.y_offset, "deps.OVERLAY_LAYOUT.message.subtext.y_offset")),
                    w = box_w - subtext_pad * 2,
                    h = RuntimeUI.sized(expect_number(message_subtext_layout.height, "deps.OVERLAY_LAYOUT.message.subtext.height")),
                },
                get_font(expect_number(message_subtext_layout.text_size, "deps.OVERLAY_LAYOUT.message.subtext.text_size"), false),
                message_subtext_color
            )
        end
    end

    function methods.drawRunSetupOverlay(self)
        if not self.show_run_setup then
            self.ui_hit.setup_start_button = nil
            self.ui_hit.setup_guided_rows = nil
            self.ui_hit.setup_initial_rows = nil
            return
        end

        local w, h = ui_dimensions()
        local folio = self.run and self.run.current_folio or nil
        local pattern_name = folio and folio.getPatternName and folio:getPatternName()
            or tr(ScriptoriumUISchema.overlays.pattern_fallback_name)
        local row_count = folio and folio.getRowCount and folio:getRowCount("TEXT") or 4
        local required_guided = math.max(1, math.min(row_count, math.floor(tonumber(folio and folio.required_guided_rows) or 2)))
        local max_open_rows = math.max(1, math.floor(tonumber(folio and folio.max_open_rows) or 2))
        local bust_choices = math.max(1, math.floor(tonumber(folio and folio.bust_choice_count) or 2))
        local bust_open_rows_only = folio and folio.bust_open_rows_only and true or false
        local reroll_max = tonumber(folio and folio.reroll_max)
        if reroll_max ~= nil then
            reroll_max = math.max(0, math.floor(reroll_max))
        end
        local objective_rows = math.max(1, math.floor(tonumber(folio and folio.objective and folio.objective.target) or 2))
        local objective_label = tr(ScriptoriumUISchema.overlays.objective_complete_rows)
        if folio and folio.getObjectiveProgress then
            local _, _, label = folio:getObjectiveProgress()
            if label and label ~= "" then
                objective_label = label
            end
        end
        local function has_row(rows, row)
            for _, r in ipairs(rows or {}) do
                if r == row then
                    return true
                end
            end
            return false
        end
        local function build_default_guided_rows()
            local defaults = {}
            for row = 1, row_count do
                defaults[#defaults + 1] = row
                if #defaults >= required_guided then
                    break
                end
            end
            return defaults
        end

        if type(self.setup_guided_rows) ~= "table" then
            self.setup_guided_rows = build_default_guided_rows()
        end
        if #self.setup_guided_rows > required_guided then
            while #self.setup_guided_rows > required_guided do
                table.remove(self.setup_guided_rows)
            end
        end
        if #self.setup_guided_rows <= 0 then
            self.setup_guided_rows = build_default_guided_rows()
        end
        if type(self.setup_initial_row) ~= "number" or (not has_row(self.setup_guided_rows, self.setup_initial_row)) then
            self.setup_initial_row = self.setup_guided_rows[1]
        end

        local selected_count = #self.setup_guided_rows
        local setup_ready = (selected_count == required_guided)
        local setup_layout = SETUP_LAYOUT
        local setup_container_layout = expect_table(setup_layout.container, "deps.OVERLAY_LAYOUT.setup.container")
        local setup_header_layout = expect_table(setup_layout.header, "deps.OVERLAY_LAYOUT.setup.header")
        local setup_header_title_layout = expect_table(setup_header_layout.title, "deps.OVERLAY_LAYOUT.setup.header.title")
        local setup_header_subtitle_layout = expect_table(setup_header_layout.subtitle, "deps.OVERLAY_LAYOUT.setup.header.subtitle")
        local setup_steps_layout = expect_table(setup_layout.steps, "deps.OVERLAY_LAYOUT.setup.steps")
        local setup_progress_layout = expect_table(setup_layout.progress, "deps.OVERLAY_LAYOUT.setup.progress")
        local setup_preview_layout = expect_table(setup_layout.preview, "deps.OVERLAY_LAYOUT.setup.preview")
        local setup_preview_title_layout = expect_table(setup_preview_layout.title, "deps.OVERLAY_LAYOUT.setup.preview.title")
        local setup_preview_grid_layout = expect_table(setup_preview_layout.grid, "deps.OVERLAY_LAYOUT.setup.preview.grid")
        local setup_preview_grid_rows_layout = expect_table(setup_preview_grid_layout.rows, "deps.OVERLAY_LAYOUT.setup.preview.grid.rows")
        local setup_preview_grid_holes_layout = expect_table(setup_preview_grid_layout.holes, "deps.OVERLAY_LAYOUT.setup.preview.grid.holes")
        local setup_preview_grid_cells_layout = expect_table(setup_preview_grid_layout.cells, "deps.OVERLAY_LAYOUT.setup.preview.grid.cells")
        local setup_preview_constraint_number_layout = expect_table(setup_preview_grid_layout.constraint_number, "deps.OVERLAY_LAYOUT.setup.preview.grid.constraint_number")
        local setup_preview_constraint_color_layout = expect_table(setup_preview_grid_layout.constraint_color, "deps.OVERLAY_LAYOUT.setup.preview.grid.constraint_color")
        local setup_rules_panel_layout = expect_table(setup_layout.rules_panel, "deps.OVERLAY_LAYOUT.setup.rules_panel")
        local setup_rules_panel_title_layout = expect_table(setup_rules_panel_layout.title, "deps.OVERLAY_LAYOUT.setup.rules_panel.title")
        local setup_rules_panel_text_layout = expect_table(setup_rules_panel_layout.text, "deps.OVERLAY_LAYOUT.setup.rules_panel.text")
        local setup_cards_layout = expect_table(setup_layout.cards, "deps.OVERLAY_LAYOUT.setup.cards")
        local setup_cards_shell_layout = expect_table(setup_cards_layout.shell, "deps.OVERLAY_LAYOUT.setup.cards.shell")
        local setup_cards_title_layout = expect_table(setup_cards_layout.title, "deps.OVERLAY_LAYOUT.setup.cards.title")
        local setup_cards_subtitle_layout = expect_table(setup_cards_layout.subtitle, "deps.OVERLAY_LAYOUT.setup.cards.subtitle")
        local setup_cards_accents_layout = expect_table(setup_cards_layout.accents, "deps.OVERLAY_LAYOUT.setup.cards.accents")
        local setup_spacing_layout = expect_table(setup_layout.spacing, "deps.OVERLAY_LAYOUT.setup.spacing")
        local setup_row_buttons_layout = expect_table(setup_layout.row_buttons, "deps.OVERLAY_LAYOUT.setup.row_buttons")
        local setup_row_buttons_guided_layout = expect_table(setup_row_buttons_layout.guided, "deps.OVERLAY_LAYOUT.setup.row_buttons.guided")
        local setup_row_buttons_initial_layout = expect_table(setup_row_buttons_layout.initial, "deps.OVERLAY_LAYOUT.setup.row_buttons.initial")
        local setup_helper_layout = expect_table(setup_layout.helper, "deps.OVERLAY_LAYOUT.setup.helper")
        local setup_start_button_layout = expect_table(setup_layout.start_button, "deps.OVERLAY_LAYOUT.setup.start_button")
        local setup_start_button_gloss_layout = expect_table(setup_start_button_layout.gloss, "deps.OVERLAY_LAYOUT.setup.start_button.gloss")
        local setup_start_button_text_layout = expect_table(setup_start_button_layout.text, "deps.OVERLAY_LAYOUT.setup.start_button.text")
        local setup_header_gloss_layout = expect_table(setup_container_layout.header_gloss, "deps.OVERLAY_LAYOUT.setup.container.header_gloss")
        local setup_outline_layout = expect_table(setup_container_layout.outline, "deps.OVERLAY_LAYOUT.setup.container.outline")
        local setup_inner_outline_layout = expect_table(setup_container_layout.inner_outline, "deps.OVERLAY_LAYOUT.setup.container.inner_outline")

        love.graphics.setColor(0, 0, 0, setup_layout.backdrop_alpha or 0.82)
        love.graphics.rectangle("fill", 0, 0, w, h)

        local tray_top = nil
        local tray = EngineBridge.getDiceTrayRect()
        if tray and tray.y then
            local tray_y = tray.y
            if ResolutionManager and ResolutionManager.to_virtual then
                local _, virtual_y = ResolutionManager.to_virtual(0, tray.y)
                tray_y = virtual_y
            elseif love and love.graphics and love.graphics.getDimensions then
                local _, real_h = love.graphics.getDimensions()
                if real_h and real_h > 0 then
                    tray_y = tray.y * (h / real_h)
                end
            end
            tray_top = tray_y
        end

        local top_margin = RuntimeUI.sized(setup_container_layout.top_margin or 48)
        local bottom_margin = RuntimeUI.sized(setup_container_layout.bottom_margin or 176)
        if tray_top then
            bottom_margin = math.max(bottom_margin, h - tray_top + RuntimeUI.sized(setup_container_layout.tray_bottom_margin or 16))
        end
        local max_box_h = math.max(
            RuntimeUI.sized(setup_container_layout.max_height_min or 520),
            h - top_margin - bottom_margin
        )
        local box_w = math.min(
            RuntimeUI.sized(setup_container_layout.width_max or 1020),
            w * (setup_container_layout.width_ratio or 0.92)
        )
        local box_h = math.min(
            math.min(
                RuntimeUI.sized(setup_container_layout.height_max or 610),
                h * (setup_container_layout.height_ratio or 0.84)
            ),
            max_box_h
        )
        local box_x = (w - box_w) * 0.5
        local box_y = clamp(
            (h - box_h) * 0.5,
            top_margin,
            h - box_h - RuntimeUI.sized(setup_container_layout.y_bottom_margin or 16)
        )
        if tray_top then
            local max_bottom = tray_top - RuntimeUI.sized(setup_container_layout.tray_overlap_gap or 14)
            if box_y + box_h > max_bottom then
                box_y = math.max(RuntimeUI.sized(setup_container_layout.y_min or 18), max_bottom - box_h)
            end
        end
        local pad = RuntimeUI.sized(setup_container_layout.pad or 20)
        local corner = RuntimeUI.sized(setup_container_layout.corner_radius or 10)
        local container_fill = setup_container_layout.fill_color or {0.18, 0.12, 0.08}
        local header_gloss_color = setup_header_gloss_layout.color or {0.12, 0.08, 0.06}
        local outline_color = setup_outline_layout.line_color or {0.88, 0.70, 0.46}
        local inner_outline_color = setup_inner_outline_layout.line_color or {0.66, 0.52, 0.34}

        love.graphics.setColor(
            container_fill[1] or 0.18,
            container_fill[2] or 0.12,
            container_fill[3] or 0.08,
            setup_container_layout.fill_alpha or 0.97
        )
        love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, corner, corner)
        love.graphics.setColor(
            header_gloss_color[1] or 0.12,
            header_gloss_color[2] or 0.08,
            header_gloss_color[3] or 0.06,
            setup_header_gloss_layout.alpha or 0.40
        )
        local gloss_inset = RuntimeUI.sized(setup_header_gloss_layout.inset or 2)
        love.graphics.rectangle(
            "fill",
            box_x + gloss_inset,
            box_y + gloss_inset,
            box_w - gloss_inset * 2,
            RuntimeUI.sized(setup_header_gloss_layout.height or 74),
            corner,
            corner
        )
        love.graphics.setColor(
            outline_color[1] or 0.88,
            outline_color[2] or 0.70,
            outline_color[3] or 0.46,
            setup_outline_layout.line_alpha or 0.90
        )
        love.graphics.setLineWidth(setup_outline_layout.line_width or 2)
        love.graphics.rectangle("line", box_x, box_y, box_w, box_h, corner, corner)
        love.graphics.setColor(
            inner_outline_color[1] or 0.66,
            inner_outline_color[2] or 0.52,
            inner_outline_color[3] or 0.34,
            setup_inner_outline_layout.line_alpha or 0.55
        )
        local inner_inset = RuntimeUI.sized(setup_inner_outline_layout.inset or 3)
        local corner_inset = RuntimeUI.sized(setup_inner_outline_layout.corner_inset or 2)
        love.graphics.rectangle(
            "line",
            box_x + inner_inset,
            box_y + inner_inset,
            box_w - inner_inset * 2,
            box_h - inner_inset * 2,
            corner - corner_inset,
            corner - corner_inset
        )
        love.graphics.setLineWidth(1)

        draw_text_center(tr(ScriptoriumUISchema.overlays.setup_title), {
            x = box_x,
            y = box_y + RuntimeUI.sized(setup_header_title_layout.y_offset or 10),
            w = box_w,
            h = RuntimeUI.sized(setup_header_title_layout.height or 40),
        }, get_font(setup_header_title_layout.text_size or 40, true), setup_header_title_layout.text_color or {0.98, 0.90, 0.66, 1})
        draw_text_center(tr(ScriptoriumUISchema.overlays.setup_subtitle, {
            pattern = tostring(pattern_name),
        }), {
            x = box_x + pad,
            y = box_y + RuntimeUI.sized(setup_header_subtitle_layout.y_offset or 42),
            w = box_w - pad * 2,
            h = RuntimeUI.sized(setup_header_subtitle_layout.height or 20),
        }, get_font(setup_header_subtitle_layout.text_size or 13, false), setup_header_subtitle_layout.text_color or {0.90, 0.84, 0.74, 1})

        local chip_y = box_y + RuntimeUI.sized(setup_steps_layout.y_offset or 64)
        local chip_gap = RuntimeUI.sized(setup_steps_layout.gap or 10)
        local step_count = setup_steps_layout.count or 3
        local chip_w = math.floor((box_w - pad * 2 - chip_gap * math.max(0, step_count - 1)) / step_count)
        local chip_h = RuntimeUI.sized(setup_steps_layout.height or 28)
        local steps = {
            {label = tr(ScriptoriumUISchema.overlays.setup_step_1), done = selected_count == required_guided},
            {label = tr(ScriptoriumUISchema.overlays.setup_step_2), done = true},
            {label = tr(ScriptoriumUISchema.overlays.setup_step_3), done = setup_ready},
        }
        for i, step in ipairs(steps) do
            local rect = {
                x = box_x + pad + (i - 1) * (chip_w + chip_gap),
                y = chip_y,
                w = chip_w,
                h = chip_h,
            }
            local fill = step.done
                and (setup_steps_layout.fill_done or {0.18, 0.32, 0.20, 0.90})
                or (setup_steps_layout.fill_default or {0.24, 0.17, 0.11, 0.86})
            local line = step.done
                and (setup_steps_layout.line_done or {0.62, 0.88, 0.66, 0.82})
                or (setup_steps_layout.line_default or {0.74, 0.58, 0.38, 0.72})
            local text = step.done
                and (setup_steps_layout.text_done or {0.86, 0.98, 0.86, 1})
                or (setup_steps_layout.text_default or {0.95, 0.90, 0.82, 1})
            love.graphics.setColor(fill[1], fill[2], fill[3], fill[4])
            love.graphics.rectangle(
                "fill",
                rect.x,
                rect.y,
                rect.w,
                rect.h,
                setup_steps_layout.corner_radius or 6,
                setup_steps_layout.corner_radius or 6
            )
            love.graphics.setColor(line[1], line[2], line[3], line[4])
            love.graphics.rectangle(
                "line",
                rect.x,
                rect.y,
                rect.w,
                rect.h,
                setup_steps_layout.corner_radius or 6,
                setup_steps_layout.corner_radius or 6
            )
            draw_text_center(step.label, rect, get_font(setup_steps_layout.text_size or 13, false), text)
        end
        local steps_total = setup_progress_layout.steps_total or 3
        local progress = setup_ready and steps_total or ((selected_count == required_guided) and math.max(1, steps_total - 1) or 1)
        local track_h = RuntimeUI.sized(setup_progress_layout.height or 6)
        local track_y = chip_y + chip_h + RuntimeUI.sized(setup_progress_layout.y_gap or 8)
        local track_w = box_w - pad * 2
        local fill_w = track_w * (progress / steps_total)
        local progress_bg = setup_progress_layout.bg_color or {0.22, 0.16, 0.10}
        local progress_fill = setup_progress_layout.fill_color or {0.62, 0.88, 0.66}
        local progress_line = setup_progress_layout.line_color or {0.78, 0.62, 0.42}
        local progress_corner = setup_progress_layout.corner_radius or 4
        love.graphics.setColor(
            progress_bg[1] or 0.22,
            progress_bg[2] or 0.16,
            progress_bg[3] or 0.10,
            setup_progress_layout.bg_alpha or 0.84
        )
        love.graphics.rectangle("fill", box_x + pad, track_y, track_w, track_h, progress_corner, progress_corner)
        love.graphics.setColor(
            progress_fill[1] or 0.62,
            progress_fill[2] or 0.88,
            progress_fill[3] or 0.66,
            setup_progress_layout.fill_alpha or 0.88
        )
        love.graphics.rectangle("fill", box_x + pad, track_y, fill_w, track_h, progress_corner, progress_corner)
        love.graphics.setColor(
            progress_line[1] or 0.78,
            progress_line[2] or 0.62,
            progress_line[3] or 0.42,
            setup_progress_layout.line_alpha or 0.62
        )
        love.graphics.rectangle("line", box_x + pad, track_y, track_w, track_h, progress_corner, progress_corner)

        local wet_buffer_max = math.max(1, math.floor(tonumber(folio and folio.wet_buffer_max) or 3))
        local notes = {
            tr(ScriptoriumUISchema.overlays.setup_note_select_guided, {count = required_guided}),
            tr(ScriptoriumUISchema.overlays.setup_note_max_open, {count = max_open_rows}),
            tr(ScriptoriumUISchema.overlays.setup_note_guided_open),
            tr(ScriptoriumUISchema.overlays.setup_note_turn_flow),
            reroll_max and tr(ScriptoriumUISchema.overlays.setup_note_reroll_cap, {count = reroll_max})
                or tr(ScriptoriumUISchema.overlays.setup_note_reroll_default),
            tr(ScriptoriumUISchema.overlays.setup_note_wet_buffer, {count = wet_buffer_max}),
            bust_open_rows_only
                and tr(ScriptoriumUISchema.overlays.setup_note_bust_open_rows, {choices = bust_choices})
                or tr(ScriptoriumUISchema.overlays.setup_note_bust_any_rows, {choices = bust_choices}),
            tr(ScriptoriumUISchema.overlays.setup_note_goal, {
                objective = objective_label,
                target = objective_rows,
            }),
        }
        local panel_x = box_x + pad
        local preview_h = RuntimeUI.sized(setup_preview_layout.height or 140)
        local preview_y = track_y + track_h + RuntimeUI.sized(setup_spacing_layout.preview_gap_from_progress or 8)
        local panel_y = preview_y + preview_h + RuntimeUI.sized(setup_spacing_layout.panel_gap_from_preview or 10)
        local panel_w = box_w - pad * 2

        local button_w = math.min(
            RuntimeUI.sized(setup_start_button_layout.width_max or 380),
            box_w - RuntimeUI.sized(setup_start_button_layout.width_margin or 120)
        )
        local button_h = RuntimeUI.sized(setup_start_button_layout.height or 52)
        local button_bottom_margin = RuntimeUI.sized(setup_start_button_layout.bottom_margin or 16)
        local button_rect = {
            x = box_x + (box_w - button_w) * 0.5,
            y = box_y + box_h - button_h - button_bottom_margin,
            w = button_w,
            h = button_h,
        }

        local card_gap_y = RuntimeUI.sized(setup_spacing_layout.cards_gap_y or 14)
        local card_h = RuntimeUI.sized(setup_spacing_layout.cards_height or 132)
        local helper_gap_from_cards = RuntimeUI.sized(setup_spacing_layout.helper_gap_from_cards or 12)
        local helper_h = RuntimeUI.sized(setup_spacing_layout.helper_height or 24)
        local helper_gap_to_button = RuntimeUI.sized(setup_spacing_layout.helper_gap_to_button or 10)

        local rules_font = get_font(setup_rules_panel_text_layout.font_size or 15, false)
        love.graphics.setFont(rules_font)
        local line_h = math.max(
            RuntimeUI.sized(setup_rules_panel_text_layout.line_height_min or 22),
            rules_font:getHeight() + RuntimeUI.sized(setup_rules_panel_text_layout.line_height_padding or 2)
        )
        local rules_title_h = RuntimeUI.sized(setup_rules_panel_title_layout.height or 30)
        local rules_top_pad = RuntimeUI.sized(setup_rules_panel_title_layout.top_padding or 6)
        local rules_bottom_pad = RuntimeUI.sized(setup_rules_panel_title_layout.bottom_padding or 10)
        local panel_needed_h = rules_title_h + rules_top_pad + (#notes * line_h) + rules_bottom_pad
        local panel_min_h = RuntimeUI.sized(setup_rules_panel_layout.min_height or 126)
        local panel_max_h = button_rect.y - helper_gap_to_button - helper_h - helper_gap_from_cards - card_h - card_gap_y - panel_y
        panel_max_h = math.max(panel_min_h, panel_max_h)
        local panel_h = clamp(panel_needed_h, panel_min_h, panel_max_h)

        local preview_rect = {
            x = panel_x,
            y = preview_y,
            w = panel_w,
            h = preview_h,
        }
        local preview_corner = setup_preview_layout.corner_radius or 8
        local preview_fill = setup_preview_layout.fill_color or {0.86, 0.80, 0.68}
        local preview_line = setup_preview_layout.line_color or {0.62, 0.45, 0.28}
        love.graphics.setColor(
            preview_fill[1] or 0.86,
            preview_fill[2] or 0.80,
            preview_fill[3] or 0.68,
            setup_preview_layout.fill_alpha or 0.78
        )
        love.graphics.rectangle("fill", preview_rect.x, preview_rect.y, preview_rect.w, preview_rect.h, preview_corner, preview_corner)
        love.graphics.setColor(
            preview_line[1] or 0.62,
            preview_line[2] or 0.45,
            preview_line[3] or 0.28,
            setup_preview_layout.line_alpha or 0.58
        )
        love.graphics.rectangle("line", preview_rect.x, preview_rect.y, preview_rect.w, preview_rect.h, preview_corner, preview_corner)
        draw_text_center(tr(ScriptoriumUISchema.overlays.setup_preview_title), {
            x = preview_rect.x,
            y = preview_rect.y + RuntimeUI.sized(setup_preview_title_layout.y_offset or 6),
            w = preview_rect.w,
            h = RuntimeUI.sized(setup_preview_title_layout.height or 18),
        }, get_font(setup_preview_title_layout.text_size or 12, true), setup_preview_title_layout.text_color or {0.60, 0.46, 0.30, 1})

        do
            local rows = row_count
            local cols = setup_preview_grid_layout.cols or 5
            local inner_pad = RuntimeUI.sized(setup_preview_grid_layout.inner_pad or 16)
            local usable_w = preview_rect.w - inner_pad * 2
            local usable_h = preview_rect.h - RuntimeUI.sized(setup_preview_grid_layout.bottom_reserved or 34)
            local gap = math.max(
                setup_preview_grid_layout.gap_min or 2,
                math.floor(usable_w * (setup_preview_grid_layout.gap_ratio or 0.02))
            )
            local cell = math.floor(math.min((usable_w - gap * (cols - 1)) / cols, (usable_h - gap * (rows - 1)) / rows))
            local grid_w = cell * cols + gap * (cols - 1)
            local grid_h = cell * rows + gap * (rows - 1)
            local gx = preview_rect.x + (preview_rect.w - grid_w) * 0.5
            local gy = preview_rect.y + RuntimeUI.sized(setup_preview_grid_layout.top_offset or 26) + math.max(0, (usable_h - grid_h) * 0.5)

            for row = 1, rows do
                local row_y = gy + (row - 1) * (cell + gap)
                local guided = has_row(self.setup_guided_rows, row)
                local opened = guided
                local fill = opened
                    and (setup_preview_grid_rows_layout.open_fill or {0.30, 0.38, 0.26, 0.55})
                    or (guided
                        and (setup_preview_grid_rows_layout.guided_fill or {0.26, 0.20, 0.14, 0.45})
                        or (setup_preview_grid_rows_layout.closed_fill or {0.22, 0.18, 0.12, 0.34}))
                love.graphics.setColor(fill[1], fill[2], fill[3], fill[4])
                love.graphics.rectangle(
                    "fill",
                    gx - RuntimeUI.sized(setup_preview_grid_rows_layout.x_expand or 4),
                    row_y - RuntimeUI.sized(setup_preview_grid_rows_layout.y_expand or 2),
                    grid_w + RuntimeUI.sized(setup_preview_grid_rows_layout.w_expand or 8),
                    cell + RuntimeUI.sized(setup_preview_grid_rows_layout.h_expand or 4),
                    setup_preview_grid_rows_layout.corner_radius or 4,
                    setup_preview_grid_rows_layout.corner_radius or 4
                )
                if guided then
                    local hole_r = math.max(
                        setup_preview_grid_holes_layout.radius_min or 2,
                        math.floor(cell * (setup_preview_grid_holes_layout.radius_ratio or 0.12))
                    )
                    local hole_y = row_y + cell * 0.5
                    local hole_color = setup_preview_grid_holes_layout.fill_color or {0.20, 0.14, 0.09}
                    love.graphics.setColor(
                        hole_color[1] or 0.20,
                        hole_color[2] or 0.14,
                        hole_color[3] or 0.09,
                        setup_preview_grid_holes_layout.fill_alpha or 0.92
                    )
                    local hole_side = RuntimeUI.sized(setup_preview_grid_holes_layout.side_offset or 10)
                    love.graphics.circle("fill", gx - hole_side, hole_y, hole_r)
                    love.graphics.circle("fill", gx + grid_w + hole_side, hole_y, hole_r)
                end
                for col = 1, cols do
                    local cx = gx + (col - 1) * (cell + gap)
                    local cy = row_y
                    local cell_fill = setup_preview_grid_cells_layout.fill_color or {0.34, 0.26, 0.18}
                    local cell_line = setup_preview_grid_cells_layout.line_color or {0.62, 0.45, 0.28}
                    local cell_corner = setup_preview_grid_cells_layout.corner_radius or 2
                    love.graphics.setColor(
                        cell_fill[1] or 0.34,
                        cell_fill[2] or 0.26,
                        cell_fill[3] or 0.18,
                        setup_preview_grid_cells_layout.fill_alpha or 0.78
                    )
                    love.graphics.rectangle("fill", cx, cy, cell, cell, cell_corner, cell_corner)
                    love.graphics.setColor(
                        cell_line[1] or 0.62,
                        cell_line[2] or 0.45,
                        cell_line[3] or 0.28,
                        setup_preview_grid_cells_layout.line_alpha or 0.26
                    )
                    love.graphics.rectangle("line", cx, cy, cell, cell, cell_corner, cell_corner)
                    local index = (row - 1) * cols + col
                    local constraint = folio and folio.elements and folio.elements.TEXT and folio.elements.TEXT.pattern.grid[index] or nil
                    if type(constraint) == "number" then
                        love.graphics.setFont(
                            get_font(
                                math.max(
                                    setup_preview_constraint_number_layout.font_min or 9,
                                    math.floor(cell * (setup_preview_constraint_number_layout.font_ratio or 0.38))
                                ),
                                true
                            )
                        )
                        local number_color = setup_preview_constraint_number_layout.color or {0.20, 0.14, 0.09}
                        love.graphics.setColor(
                            number_color[1] or 0.20,
                            number_color[2] or 0.14,
                            number_color[3] or 0.09,
                            setup_preview_constraint_number_layout.alpha or 0.40
                        )
                        love.graphics.printf(
                            tostring(constraint),
                            cx,
                            cy + cell * (setup_preview_constraint_number_layout.y_ratio or 0.18),
                            cell,
                            "center"
                        )
                    elseif type(constraint) == "string" then
                        local fallback_color = setup_preview_constraint_color_layout.fallback_color or {0.75, 0.75, 0.75}
                        local c = COLOR_SWATCH[constraint] or fallback_color
                        local dot = math.max(
                            setup_preview_constraint_color_layout.radius_min or 3,
                            math.floor(cell * (setup_preview_constraint_color_layout.radius_ratio or 0.16))
                        )
                        love.graphics.setColor(c[1], c[2], c[3], setup_preview_constraint_color_layout.alpha or 0.90)
                        love.graphics.circle(
                            "fill",
                            cx + cell - dot - (setup_preview_constraint_color_layout.x_inset or 2),
                            cy + dot + (setup_preview_constraint_color_layout.y_inset or 2),
                            dot
                        )
                    end
                end
            end
        end

        local rules_panel_corner = setup_rules_panel_layout.corner_radius or 8
        local rules_panel_fill = setup_rules_panel_layout.fill_color or {0.28, 0.19, 0.11}
        local rules_panel_line = setup_rules_panel_layout.line_color or {0.80, 0.62, 0.40}
        love.graphics.setColor(
            rules_panel_fill[1] or 0.28,
            rules_panel_fill[2] or 0.19,
            rules_panel_fill[3] or 0.11,
            setup_rules_panel_layout.fill_alpha or 0.92
        )
        love.graphics.rectangle("fill", panel_x, panel_y, panel_w, panel_h, rules_panel_corner, rules_panel_corner)
        love.graphics.setColor(
            rules_panel_line[1] or 0.80,
            rules_panel_line[2] or 0.62,
            rules_panel_line[3] or 0.40,
            setup_rules_panel_layout.line_alpha or 0.78
        )
        love.graphics.rectangle("line", panel_x, panel_y, panel_w, panel_h, rules_panel_corner, rules_panel_corner)
        draw_text_center(tr(ScriptoriumUISchema.overlays.setup_rules_title), {
            x = panel_x,
            y = panel_y + RuntimeUI.sized(setup_rules_panel_title_layout.y_offset or 5),
            w = panel_w,
            h = rules_title_h,
        }, get_font(setup_rules_panel_title_layout.text_size or 20, true), setup_rules_panel_title_layout.text_color or {0.98, 0.90, 0.70, 1})
        local rules_available_h = panel_h - (rules_title_h + rules_top_pad + rules_bottom_pad)
        local wrap_w = panel_w - RuntimeUI.sized(setup_rules_panel_text_layout.wrap_padding or 32)
        local bullet_prefix = setup_rules_panel_text_layout.bullet_prefix or "- "
        local wrapped = {}
        for _, text in ipairs(notes) do
            local bullet = string.format("%s%s", bullet_prefix, text)
            local _, lines = rules_font:getWrap(bullet, wrap_w)
            if type(lines) == "table" and #lines > 0 then
                for _, line in ipairs(lines) do
                    wrapped[#wrapped + 1] = line
                end
            else
                wrapped[#wrapped + 1] = bullet
            end
        end
        local max_lines = math.max(1, math.floor(rules_available_h / line_h))
        local shown_lines = math.min(#wrapped, max_lines)
        if shown_lines < #wrapped and shown_lines > 0 then
            local tail = wrapped[shown_lines]
            local ellipsis = setup_rules_panel_text_layout.ellipsis or "..."
            if type(tail) == "string" and #tail > 3 then
                wrapped[shown_lines] = tail:sub(1, #tail - 3) .. ellipsis
            else
                wrapped[shown_lines] = tostring(tail or "") .. ellipsis
            end
        end
        local line_y = panel_y + rules_title_h + rules_top_pad
        for i = 1, shown_lines do
            local rules_text_color = setup_rules_panel_text_layout.text_color or {0.97, 0.92, 0.84, 1}
            love.graphics.setColor(rules_text_color[1], rules_text_color[2], rules_text_color[3], rules_text_color[4] or 1)
            love.graphics.print(wrapped[i], panel_x + RuntimeUI.sized(setup_rules_panel_text_layout.x_offset or 16), line_y + (i - 1) * line_h)
        end

        self.ui_hit.setup_guided_rows = {}
        self.ui_hit.setup_initial_rows = nil

        local card_y = panel_y + panel_h + card_gap_y
        local card_gap_x = RuntimeUI.sized(setup_cards_layout.gap_x or 14)
        local card_w = math.floor((box_w - pad * 2 - card_gap_x) * 0.5)
        local guided_card = {
            x = box_x + pad,
            y = card_y,
            w = card_w,
            h = card_h,
        }
        local open_card = {
            x = guided_card.x + card_w + card_gap_x,
            y = card_y,
            w = card_w,
            h = card_h,
        }
        local function draw_card_shell(rect, title, subtitle, accent)
            local shell_fill = setup_cards_shell_layout.fill_color or {0.24, 0.17, 0.11}
            local shell_corner = setup_cards_shell_layout.corner_radius or 8
            love.graphics.setColor(
                shell_fill[1] or 0.24,
                shell_fill[2] or 0.17,
                shell_fill[3] or 0.11,
                setup_cards_shell_layout.fill_alpha or 0.90
            )
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, shell_corner, shell_corner)
            love.graphics.setColor(accent[1], accent[2], accent[3], setup_cards_shell_layout.line_alpha or 0.72)
            love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, shell_corner, shell_corner)
            draw_text_center(title, {
                x = rect.x,
                y = rect.y + RuntimeUI.sized(setup_cards_title_layout.y_offset or 6),
                w = rect.w,
                h = RuntimeUI.sized(setup_cards_title_layout.height or 20),
            }, get_font(setup_cards_title_layout.text_size or 15, true), setup_cards_title_layout.text_color or {0.98, 0.90, 0.74, 1})
            draw_text_center(subtitle, {
                x = rect.x + RuntimeUI.sized(setup_cards_subtitle_layout.x_padding or 8),
                y = rect.y + RuntimeUI.sized(setup_cards_subtitle_layout.y_offset or 26),
                w = rect.w - RuntimeUI.sized((setup_cards_subtitle_layout.x_padding or 8) * 2),
                h = RuntimeUI.sized(setup_cards_subtitle_layout.height or 16),
            }, get_font(setup_cards_subtitle_layout.text_size or 12, false), setup_cards_subtitle_layout.text_color or {0.95, 0.90, 0.82, 1})
        end

        draw_card_shell(
            guided_card,
            tr(ScriptoriumUISchema.overlays.setup_card_pricking_title),
            tr(ScriptoriumUISchema.overlays.setup_card_pricking_subtitle, {count = required_guided}),
            (selected_count == required_guided)
                and (setup_cards_accents_layout.guided_ready or {0.62, 0.84, 0.60})
                or (setup_cards_accents_layout.guided_pending or {0.82, 0.66, 0.46})
        )
        draw_card_shell(
            open_card,
            tr(ScriptoriumUISchema.overlays.setup_card_start_title),
            tr(ScriptoriumUISchema.overlays.setup_card_start_subtitle),
            setup_ready
                and (setup_cards_accents_layout.start_ready or {0.62, 0.84, 0.60})
                or (setup_cards_accents_layout.start_pending or {0.76, 0.60, 0.40})
        )

        local btn_h = RuntimeUI.sized(setup_row_buttons_layout.height or 38)
        local btn_gap = RuntimeUI.sized(setup_row_buttons_layout.gap or 8)
        local btn_margin = RuntimeUI.sized(setup_row_buttons_layout.horizontal_margin or 12)
        local btn_w = clamp(
            math.floor((guided_card.w - btn_margin * 2 - (row_count - 1) * btn_gap) / row_count),
            RuntimeUI.sized(setup_row_buttons_layout.width_min or 72),
            RuntimeUI.sized(setup_row_buttons_layout.width_max or 102)
        )
        local row_group_w = row_count * btn_w + (row_count - 1) * btn_gap
        local guided_row_start_x = guided_card.x + (guided_card.w - row_group_w) * 0.5
        local row_bottom_offset = RuntimeUI.sized(setup_row_buttons_layout.y_bottom_offset or 12)
        local guided_y = guided_card.y + guided_card.h - btn_h - row_bottom_offset
        local initial_row_start_x = open_card.x + (open_card.w - row_group_w) * 0.5
        local initial_y = open_card.y + open_card.h - btn_h - row_bottom_offset
        local row_button_corner = setup_row_buttons_layout.corner_radius or 5
        local row_button_text_size = setup_row_buttons_layout.text_size or 13

        for row = 1, row_count do
            local rect = {
                x = guided_row_start_x + (row - 1) * (btn_w + btn_gap),
                y = guided_y,
                w = btn_w,
                h = btn_h,
            }
            self.ui_hit.setup_guided_rows[#self.ui_hit.setup_guided_rows + 1] = {row = row, rect = rect}
            local selected = has_row(self.setup_guided_rows, row)
            local hover = point_in_rect(self.mouse_x, self.mouse_y, rect)
            local guided_fill_selected = setup_row_buttons_guided_layout.fill_selected or {0.20, 0.31, 0.20, 0.96}
            local guided_fill_unselected = setup_row_buttons_guided_layout.fill_unselected or {0.26, 0.18, 0.11}
            local guided_line_selected = setup_row_buttons_guided_layout.line_selected or {0.62, 0.88, 0.66, 0.94}
            local guided_line_unselected = setup_row_buttons_guided_layout.line_unselected or {0.84, 0.66, 0.42, 0.66}
            local text_color = selected
                and (setup_row_buttons_guided_layout.text_selected or {0.95, 0.99, 0.92, 1})
                or (setup_row_buttons_guided_layout.text_unselected or {0.92, 0.84, 0.74, 1})
            local fill = selected
                and guided_fill_selected
                or {
                    guided_fill_unselected[1] or 0.26,
                    guided_fill_unselected[2] or 0.18,
                    guided_fill_unselected[3] or 0.11,
                    hover
                        and (setup_row_buttons_guided_layout.fill_unselected_alpha_hover or 0.90)
                        or (setup_row_buttons_guided_layout.fill_unselected_alpha_normal or 0.80),
                }
            local line = selected and guided_line_selected or guided_line_unselected
            love.graphics.setColor(fill[1], fill[2], fill[3], fill[4])
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, row_button_corner, row_button_corner)
            love.graphics.setColor(line[1], line[2], line[3], line[4])
            love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, row_button_corner, row_button_corner)
            local row_text = selected
                and tr(ScriptoriumUISchema.overlays.setup_guided_row_selected, {row = tostring(row)})
                or tr(ScriptoriumUISchema.overlays.setup_guided_row_unselected, {row = tostring(row)})
            draw_text_center(
                row_text,
                rect,
                get_font(row_button_text_size, false),
                text_color
            )
        end

        for row = 1, row_count do
            local rect = {
                x = initial_row_start_x + (row - 1) * (btn_w + btn_gap),
                y = initial_y,
                w = btn_w,
                h = btn_h,
            }
            local enabled = has_row(self.setup_guided_rows, row)
            local selected = enabled and (self.setup_initial_row == row)
            local hover = point_in_rect(self.mouse_x, self.mouse_y, rect)
            local initial_fill_selected = setup_row_buttons_initial_layout.fill_selected or {0.20, 0.35, 0.22, 0.96}
            local initial_fill_enabled = setup_row_buttons_initial_layout.fill_enabled or {0.22, 0.16, 0.10}
            local initial_fill_disabled = setup_row_buttons_initial_layout.fill_disabled or {0.22, 0.16, 0.10, 0.46}
            local initial_line_selected = setup_row_buttons_initial_layout.line_selected or {0.68, 0.90, 0.68, 0.98}
            local initial_line_enabled = setup_row_buttons_initial_layout.line_enabled or {0.80, 0.62, 0.40, 0.66}
            local initial_line_disabled = setup_row_buttons_initial_layout.line_disabled or {0.80, 0.62, 0.40, 0.34}
            local fill = enabled
                and (
                    selected and initial_fill_selected
                    or {
                        initial_fill_enabled[1] or 0.22,
                        initial_fill_enabled[2] or 0.16,
                        initial_fill_enabled[3] or 0.10,
                        hover
                            and (setup_row_buttons_initial_layout.fill_enabled_alpha_hover or 0.90)
                            or (setup_row_buttons_initial_layout.fill_enabled_alpha_normal or 0.84),
                    }
                )
                or initial_fill_disabled
            local line = enabled and (selected and initial_line_selected or initial_line_enabled) or initial_line_disabled
            love.graphics.setColor(fill[1], fill[2], fill[3], fill[4])
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, row_button_corner, row_button_corner)
            love.graphics.setColor(line[1], line[2], line[3], line[4])
            love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, row_button_corner, row_button_corner)
            local label = enabled
                and tr(ScriptoriumUISchema.overlays.setup_auto_row_enabled, {row = tostring(row)})
                or tr(ScriptoriumUISchema.overlays.setup_auto_row_locked)
            local enabled_text = setup_row_buttons_initial_layout.text_enabled or {0.98, 0.92, 0.84, 1}
            local disabled_text = setup_row_buttons_initial_layout.text_disabled or {0.64, 0.56, 0.46, 1}
            draw_text_center(label, rect, get_font(row_button_text_size, false), enabled and enabled_text or disabled_text)
        end

        local helper_text = setup_ready
            and tr(ScriptoriumUISchema.overlays.setup_helper_ready)
            or tr(ScriptoriumUISchema.overlays.setup_helper_select, {count = required_guided})
        local helper_min_y = card_y + card_h + helper_gap_from_cards
        local helper_max_y = button_rect.y - helper_gap_to_button - helper_h
        local helper_y = helper_min_y
        if helper_max_y > helper_min_y then
            helper_y = clamp(math.floor((helper_min_y + helper_max_y) * 0.5), helper_min_y, helper_max_y)
        end
        draw_text_center(helper_text, {
            x = box_x + pad,
            y = helper_y,
            w = box_w - pad * 2,
            h = helper_h,
        }, get_font(setup_helper_layout.text_size or 16, false), setup_ready
                and (setup_helper_layout.ready_color or {0.78, 0.96, 0.72, 1})
                or (setup_helper_layout.pending_color or {0.95, 0.86, 0.70, 1}))

        self.ui_hit.setup_start_button = setup_ready and button_rect or nil
        local hover = point_in_rect(self.mouse_x, self.mouse_y, button_rect)
        local alpha = setup_ready
            and (hover and (setup_start_button_layout.alpha_hover or 0.96) or (setup_start_button_layout.alpha_normal or 0.88))
            or (setup_start_button_layout.alpha_disabled or 0.42)

        local start_fill = setup_start_button_layout.fill_color or {0.22, 0.45, 0.24}
        local start_line = setup_start_button_layout.line_color or {0.70, 0.88, 0.64}
        local start_corner = setup_start_button_layout.corner_radius or 6
        love.graphics.setColor(
            start_fill[1] or 0.22,
            start_fill[2] or 0.45,
            start_fill[3] or 0.24,
            setup_ready and alpha or (setup_start_button_layout.fill_alpha_disabled or 0.30)
        )
        love.graphics.rectangle("fill", button_rect.x, button_rect.y, button_rect.w, button_rect.h, start_corner, start_corner)
        local gloss_color = setup_start_button_gloss_layout.color or {0.96, 0.98, 0.88}
        local start_gloss_inset = RuntimeUI.sized(setup_start_button_gloss_layout.inset or 2)
        love.graphics.setColor(
            gloss_color[1] or 0.96,
            gloss_color[2] or 0.98,
            gloss_color[3] or 0.88,
            setup_ready
                and (setup_start_button_gloss_layout.alpha_enabled or 0.12)
                or (setup_start_button_gloss_layout.alpha_disabled or 0.04)
        )
        love.graphics.rectangle(
            "fill",
            button_rect.x + start_gloss_inset,
            button_rect.y + start_gloss_inset,
            button_rect.w - start_gloss_inset * 2,
            RuntimeUI.sized(setup_start_button_gloss_layout.height or 16),
            setup_start_button_gloss_layout.corner_radius or 5,
            setup_start_button_gloss_layout.corner_radius or 5
        )
        love.graphics.setColor(
            start_line[1] or 0.70,
            start_line[2] or 0.88,
            start_line[3] or 0.64,
            setup_ready and alpha or (setup_start_button_layout.line_alpha_disabled or 0.40)
        )
        love.graphics.rectangle("line", button_rect.x, button_rect.y, button_rect.w, button_rect.h, start_corner, start_corner)
        local start_text_enabled = setup_start_button_text_layout.color_enabled or {0.98, 0.94, 0.86, 1}
        local start_text_disabled = setup_start_button_text_layout.color_disabled or {0.66, 0.64, 0.58, 1}
        draw_text_center(setup_ready
                and tr(ScriptoriumUISchema.overlays.setup_start_cta)
                or tr(ScriptoriumUISchema.overlays.setup_start_cta_locked), {
            x = button_rect.x,
            y = button_rect.y + RuntimeUI.sized(setup_start_button_text_layout.y_offset or 10),
            w = button_rect.w,
            h = RuntimeUI.sized(setup_start_button_text_layout.height or 28),
        }, get_font(setup_start_button_text_layout.size or 21, true), setup_ready and start_text_enabled or start_text_disabled)
    end

    function methods.drawRulingOverlay(self)
        if not self.show_ruling_overlay then
            self.ui_hit.ruling_row_buttons = nil
            self.ui_hit.ruling_done_button = nil
            self.ui_hit.ruling_done_enabled = nil
            return
        end
        local folio = self.run and self.run.current_folio or nil
        if not folio then
            return
        end

        local w, h = ui_dimensions()
        local ruling_layout = RULING_LAYOUT
        local ruling_box_layout = expect_table(ruling_layout.box, "deps.OVERLAY_LAYOUT.ruling.box")
        local ruling_title_layout = expect_table(ruling_layout.title, "deps.OVERLAY_LAYOUT.ruling.title")
        local ruling_subtitle_layout = expect_table(ruling_layout.subtitle, "deps.OVERLAY_LAYOUT.ruling.subtitle")
        local ruling_status_layout = expect_table(ruling_layout.status, "deps.OVERLAY_LAYOUT.ruling.status")
        local ruling_rows_layout = expect_table(ruling_layout.rows, "deps.OVERLAY_LAYOUT.ruling.rows")
        local ruling_done_button_layout = expect_table(ruling_layout.done_button, "deps.OVERLAY_LAYOUT.ruling.done_button")
        local ruling_warning_layout = expect_table(ruling_layout.warning, "deps.OVERLAY_LAYOUT.ruling.warning")

        love.graphics.setColor(0, 0, 0, ruling_layout.backdrop_alpha or 0.65)
        love.graphics.rectangle("fill", 0, 0, w, h)

        local box_w = math.min(
            RuntimeUI.sized(ruling_box_layout.width_max or 740),
            w * (ruling_box_layout.width_ratio or 0.72)
        )
        local box_h = math.min(
            RuntimeUI.sized(ruling_box_layout.height_max or 420),
            h * (ruling_box_layout.height_ratio or 0.68)
        )
        local box_x = (w - box_w) * 0.5
        local box_y = (h - box_h) * 0.5
        local box_corner = ruling_box_layout.corner_radius or 10
        local box_fill = ruling_box_layout.fill_color or {0.18, 0.12, 0.08}
        local box_line = ruling_box_layout.line_color or {0.86, 0.68, 0.44}
        love.graphics.setColor(
            box_fill[1] or 0.18,
            box_fill[2] or 0.12,
            box_fill[3] or 0.08,
            ruling_box_layout.fill_alpha or 0.96
        )
        love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, box_corner, box_corner)
        love.graphics.setColor(
            box_line[1] or 0.86,
            box_line[2] or 0.68,
            box_line[3] or 0.44,
            ruling_box_layout.line_alpha or 0.92
        )
        love.graphics.rectangle("line", box_x, box_y, box_w, box_h, box_corner, box_corner)

        draw_text_center(tr(ScriptoriumUISchema.overlays.ruling_title), {
            x = box_x,
            y = box_y + RuntimeUI.sized(ruling_title_layout.y_offset or 10),
            w = box_w,
            h = RuntimeUI.sized(ruling_title_layout.height or 28),
        }, get_font(ruling_title_layout.text_size or 28, true), ruling_title_layout.text_color or {0.98, 0.90, 0.66, 1})
        draw_text_center(tr(ScriptoriumUISchema.overlays.ruling_subtitle), {
            x = box_x,
            y = box_y + RuntimeUI.sized(ruling_subtitle_layout.y_offset or 38),
            w = box_w,
            h = RuntimeUI.sized(ruling_subtitle_layout.height or 18),
        }, get_font(ruling_subtitle_layout.text_size or 13, false), ruling_subtitle_layout.text_color or {0.92, 0.86, 0.74, 1})

        local row_count = folio.getRowCount and folio:getRowCount("TEXT") or 4
        local open_rows = folio.getOpenRows and folio:getOpenRows() or {}
        local max_open = tonumber(folio.max_open_rows) or 2
        local actions_left = math.max(0, math.floor(tonumber(self.ruling_actions_left) or 0))
        local ruling_list_separator = tr(ScriptoriumUISchema.overlays.ruling_list_separator)
        if ruling_list_separator == "" then
            ruling_list_separator = ", "
        end
        local ruling_list_empty = tr(ScriptoriumUISchema.overlays.ruling_list_empty)
        if ruling_list_empty == "" then
            ruling_list_empty = "-"
        end
        local open_text = (#open_rows > 0) and table.concat(open_rows, ruling_list_separator) or ruling_list_empty
        draw_text_center(tr(ScriptoriumUISchema.overlays.ruling_status, {
            rows = open_text,
            max = max_open,
            actions = actions_left,
        }), {
            x = box_x,
            y = box_y + RuntimeUI.sized(ruling_status_layout.y_offset or 58),
            w = box_w,
            h = RuntimeUI.sized(ruling_status_layout.height or 18),
        }, get_font(ruling_status_layout.text_size or 12, false), ruling_status_layout.text_color or {0.90, 0.84, 0.72, 1})

        self.ui_hit.ruling_row_buttons = {}
        local list_y = box_y + RuntimeUI.sized(ruling_rows_layout.list_y_offset or 88)
        local btn_h = RuntimeUI.sized(ruling_rows_layout.button_height or 38)
        local btn_gap = RuntimeUI.sized(ruling_rows_layout.button_gap or 10)
        local btn_w = math.min(
            RuntimeUI.sized(ruling_rows_layout.button_width_max or 420),
            box_w - RuntimeUI.sized(ruling_rows_layout.button_width_margin or 80)
        )
        local start_x = box_x + (box_w - btn_w) * 0.5
        local row_button_corner = ruling_rows_layout.button_corner_radius or 6
        local row_fill_open = ruling_rows_layout.fill_open or {0.26, 0.38, 0.24, 0.92}
        local row_fill_closed = ruling_rows_layout.fill_closed or {0.22, 0.16, 0.10, 0.86}
        local row_line_open = ruling_rows_layout.line_open or {0.70, 0.92, 0.64, 0.92}
        local row_line_closed = ruling_rows_layout.line_closed or {0.78, 0.62, 0.40, 0.74}
        local row_text_enabled = ruling_rows_layout.text_color_enabled or {0.98, 0.94, 0.86, 1}
        local row_text_disabled = ruling_rows_layout.text_color_disabled or {0.62, 0.58, 0.52, 1}
        for row = 1, row_count do
            local rect = {
                x = start_x,
                y = list_y + (row - 1) * (btn_h + btn_gap),
                w = btn_w,
                h = btn_h,
            }
            local row_open = folio.isRowOpen and folio:isRowOpen(row) or false
            local is_guided = folio.isGuidedRow and folio:isGuidedRow(row) or false
            local can_open = true
            if (not row_open) and folio.canRowBeOpened then
                can_open = folio:canRowBeOpened(row)
            end
            local enabled = (actions_left > 0) and (row_open or can_open)
            local fill = row_open and row_fill_open or row_fill_closed
            local line = row_open and row_line_open or row_line_closed
            if not enabled then
                fill = {fill[1], fill[2], fill[3], ruling_rows_layout.disabled_alpha or 0.46}
                line = {line[1], line[2], line[3], ruling_rows_layout.disabled_alpha or 0.46}
            end
            love.graphics.setColor(fill[1], fill[2], fill[3], fill[4])
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, row_button_corner, row_button_corner)
            love.graphics.setColor(line[1], line[2], line[3], line[4])
            love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, row_button_corner, row_button_corner)
            local label = row_open
                and tr(ScriptoriumUISchema.overlays.ruling_close_row, {row = tostring(row)})
                or tr(ScriptoriumUISchema.overlays.ruling_open_row, {row = tostring(row)})
            if (not row_open) and is_guided then
                label = tr(ScriptoriumUISchema.overlays.ruling_open_guided_row, {row = tostring(row)})
            end
            draw_text_center(
                label,
                rect,
                get_font(ruling_rows_layout.text_size or 13, true),
                enabled and row_text_enabled or row_text_disabled
            )
            if enabled then
                self.ui_hit.ruling_row_buttons[#self.ui_hit.ruling_row_buttons + 1] = {row = row, rect = rect}
            end
        end

        local function has_open_space()
            local elem = folio.elements and (folio.elements[folio.active_element or "TEXT"] or folio.elements.TEXT) or nil
            if not elem or not elem.pattern then
                return true
            end
            local cols = elem.pattern.cols or 5
            for _, row in ipairs(open_rows) do
                for col = 1, cols do
                    local state = folio.getCellState and folio:getCellState(folio.active_element or "TEXT", row, col) or nil
                    if state and (not state.placed) and (not state.wet) and (not state.stained) then
                        return true
                    end
                end
            end
            return false
        end

        local done_enabled = (actions_left <= 0) or has_open_space()
        self.ui_hit.ruling_done_enabled = done_enabled
        local done_btn_w = math.min(
            RuntimeUI.sized(ruling_done_button_layout.width_max or 300),
            box_w - RuntimeUI.sized(ruling_done_button_layout.width_margin or 120)
        )
        local done_btn_h = RuntimeUI.sized(ruling_done_button_layout.height or 44)
        local done_btn_x = box_x + (box_w - done_btn_w) * 0.5
        local done_btn_y = box_y + box_h - done_btn_h - RuntimeUI.sized(ruling_done_button_layout.bottom_margin or 18)
        local btn_rect = {x = done_btn_x, y = done_btn_y, w = done_btn_w, h = done_btn_h}
        self.ui_hit.ruling_done_button = btn_rect
        local hover = point_in_rect(self.mouse_x, self.mouse_y, btn_rect)
        local alpha = done_enabled
            and (hover and (ruling_done_button_layout.alpha_hover or 0.96) or (ruling_done_button_layout.alpha_normal or 0.88))
            or (ruling_done_button_layout.alpha_disabled or 0.42)
        local done_fill = ruling_done_button_layout.fill_color or {0.26, 0.45, 0.24}
        local done_line = ruling_done_button_layout.line_color or {0.70, 0.90, 0.64}
        local done_corner = ruling_done_button_layout.corner_radius or 6
        love.graphics.setColor(done_fill[1], done_fill[2], done_fill[3], alpha)
        love.graphics.rectangle("fill", btn_rect.x, btn_rect.y, btn_rect.w, btn_rect.h, done_corner, done_corner)
        love.graphics.setColor(done_line[1], done_line[2], done_line[3], alpha)
        love.graphics.rectangle("line", btn_rect.x, btn_rect.y, btn_rect.w, btn_rect.h, done_corner, done_corner)
        draw_text_center(
            tr(ScriptoriumUISchema.overlays.ruling_done),
            btn_rect,
            get_font(ruling_done_button_layout.text_size or 18, true),
            done_enabled
                and (ruling_done_button_layout.text_color_enabled or {0.98, 0.94, 0.86, 1})
                or (ruling_done_button_layout.text_color_disabled or {0.62, 0.58, 0.52, 1})
        )
        if not done_enabled then
            draw_text_center(tr(ScriptoriumUISchema.overlays.ruling_done_warning), {
                x = box_x,
                y = btn_rect.y - RuntimeUI.sized(ruling_warning_layout.y_offset or 22),
                w = box_w,
                h = RuntimeUI.sized(ruling_warning_layout.height or 18),
            }, get_font(ruling_warning_layout.text_size or 12, false), ruling_warning_layout.text_color or {0.96, 0.84, 0.62, 1})
        end
    end

    function methods.drawFolioResultOverlay(self)
        if not self.show_folio_result then
            self.ui_hit.folio_result_continue = nil
            return
        end
        local folio = self.run and self.run.current_folio or nil
        local w, h = ui_dimensions()
        local result_layout = RESULT_LAYOUT
        local result_box_layout = expect_table(result_layout.box, "deps.OVERLAY_LAYOUT.result.box")
        local result_title_layout = expect_table(result_layout.title, "deps.OVERLAY_LAYOUT.result.title")
        local result_subtitle_layout = expect_table(result_layout.subtitle, "deps.OVERLAY_LAYOUT.result.subtitle")
        local result_preview_layout = expect_table(result_layout.preview, "deps.OVERLAY_LAYOUT.result.preview")
        local result_preview_grid_layout = expect_table(result_preview_layout.grid, "deps.OVERLAY_LAYOUT.result.preview.grid")
        local result_preview_cell_layout = expect_table(result_preview_grid_layout.cell, "deps.OVERLAY_LAYOUT.result.preview.grid.cell")
        local result_preview_placed_layout = expect_table(result_preview_grid_layout.placed, "deps.OVERLAY_LAYOUT.result.preview.grid.placed")
        local result_preview_stain_layout = expect_table(result_preview_grid_layout.stain, "deps.OVERLAY_LAYOUT.result.preview.grid.stain")
        local result_preview_completed_row_layout = expect_table(result_preview_grid_layout.completed_row, "deps.OVERLAY_LAYOUT.result.preview.grid.completed_row")
        local result_right_panel_layout = expect_table(result_layout.right_panel, "deps.OVERLAY_LAYOUT.result.right_panel")
        local result_right_stats_layout = expect_table(result_right_panel_layout.stats, "deps.OVERLAY_LAYOUT.result.right_panel.stats")
        local result_right_badge_layout = expect_table(result_right_panel_layout.badge, "deps.OVERLAY_LAYOUT.result.right_panel.badge")
        local result_right_badge_text_layout = expect_table(result_right_badge_layout.text, "deps.OVERLAY_LAYOUT.result.right_panel.badge.text")
        local result_right_badge_success_layout = expect_table(result_right_badge_layout.success, "deps.OVERLAY_LAYOUT.result.right_panel.badge.success")
        local result_right_badge_failed_layout = expect_table(result_right_badge_layout.failed, "deps.OVERLAY_LAYOUT.result.right_panel.badge.failed")
        local result_continue_button_layout = expect_table(result_layout.continue_button, "deps.OVERLAY_LAYOUT.result.continue_button")

        love.graphics.setColor(0, 0, 0, result_layout.backdrop_alpha or 0.70)
        love.graphics.rectangle("fill", 0, 0, w, h)

        local box_w = math.min(
            RuntimeUI.sized(result_box_layout.width_max or 980),
            w * (result_box_layout.width_ratio or 0.88)
        )
        local box_h = math.min(
            RuntimeUI.sized(result_box_layout.height_max or 520),
            h * (result_box_layout.height_ratio or 0.80)
        )
        local box_x = (w - box_w) * 0.5
        local box_y = (h - box_h) * 0.5
        local box_corner = result_box_layout.corner_radius or 10
        local box_fill = result_box_layout.fill_color or {0.18, 0.12, 0.08}
        local box_line = result_box_layout.line_color or {0.86, 0.68, 0.44}
        love.graphics.setColor(
            box_fill[1] or 0.18,
            box_fill[2] or 0.12,
            box_fill[3] or 0.08,
            result_box_layout.fill_alpha or 0.96
        )
        love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, box_corner, box_corner)
        love.graphics.setColor(
            box_line[1] or 0.86,
            box_line[2] or 0.68,
            box_line[3] or 0.44,
            result_box_layout.line_alpha or 0.92
        )
        love.graphics.rectangle("line", box_x, box_y, box_w, box_h, box_corner, box_corner)

        local failed = self.folio_result and self.folio_result.failed
        local title = failed
            and tr(ScriptoriumUISchema.overlays.result_title_failed)
            or tr(ScriptoriumUISchema.overlays.result_title_completed)
        local subtitle = failed
            and tr(ScriptoriumUISchema.overlays.result_subtitle_failed)
            or tr(ScriptoriumUISchema.overlays.result_subtitle_completed)
        draw_text_center(title, {
            x = box_x,
            y = box_y + RuntimeUI.sized(result_title_layout.y_offset or 12),
            w = box_w,
            h = RuntimeUI.sized(result_title_layout.height or 32),
        }, get_font(result_title_layout.text_size or 32, true), result_title_layout.text_color or {0.98, 0.90, 0.66, 1})
        draw_text_center(subtitle, {
            x = box_x,
            y = box_y + RuntimeUI.sized(result_subtitle_layout.y_offset or 44),
            w = box_w,
            h = RuntimeUI.sized(result_subtitle_layout.height or 22),
        }, get_font(result_subtitle_layout.text_size or 14, false), result_subtitle_layout.text_color or {0.92, 0.86, 0.74, 1})

        local preview = {
            x = box_x + RuntimeUI.sized(result_preview_layout.x_offset or 26),
            y = box_y + RuntimeUI.sized(result_preview_layout.y_offset or 86),
            w = math.floor(box_w * (result_preview_layout.width_ratio or 0.48)),
            h = math.floor(box_h * (result_preview_layout.height_ratio or 0.62)),
        }
        local preview_corner = result_preview_layout.corner_radius or 8
        local preview_fill = result_preview_layout.fill_color or {0.88, 0.80, 0.66}
        local preview_line = result_preview_layout.line_color or {0.62, 0.45, 0.28}
        love.graphics.setColor(
            preview_fill[1] or 0.88,
            preview_fill[2] or 0.80,
            preview_fill[3] or 0.66,
            result_preview_layout.fill_alpha or 0.75
        )
        love.graphics.rectangle("fill", preview.x, preview.y, preview.w, preview.h, preview_corner, preview_corner)
        love.graphics.setColor(
            preview_line[1] or 0.62,
            preview_line[2] or 0.45,
            preview_line[3] or 0.28,
            result_preview_layout.line_alpha or 0.58
        )
        love.graphics.rectangle("line", preview.x, preview.y, preview.w, preview.h, preview_corner, preview_corner)

        if folio and folio.elements then
            local elem = folio.elements[folio.active_element or "TEXT"] or folio.elements.TEXT
            local rows = (elem and elem.pattern and elem.pattern.rows) or 4
            local cols = (elem and elem.pattern and elem.pattern.cols) or 5
            local gap = math.max(
                result_preview_grid_layout.gap_min or 2,
                math.floor(preview.w * (result_preview_grid_layout.gap_ratio or 0.01))
            )
            local cell = math.floor(math.min((preview.w - gap * (cols - 1)) / cols, (preview.h - gap * (rows - 1)) / rows))
            local grid_w = cell * cols + gap * (cols - 1)
            local grid_h = cell * rows + gap * (rows - 1)
            local gx = preview.x + (preview.w - grid_w) * 0.5
            local gy = preview.y + (preview.h - grid_h) * 0.5

            for row = 1, rows do
                local row_complete = true
                for col = 1, cols do
                    local state = folio.getCellState and folio:getCellState("TEXT", row, col) or nil
                    local placed = state and state.placed or nil
                    local stained = state and state.stained or false
                    local cx = gx + (col - 1) * (cell + gap)
                    local cy = gy + (row - 1) * (cell + gap)
                    local preview_cell_corner = result_preview_cell_layout.corner_radius or 2
                    local preview_cell_fill = result_preview_cell_layout.fill_color or {0.32, 0.24, 0.16}
                    local preview_cell_line = result_preview_cell_layout.line_color or {0.58, 0.44, 0.30}
                    love.graphics.setColor(
                        preview_cell_fill[1] or 0.32,
                        preview_cell_fill[2] or 0.24,
                        preview_cell_fill[3] or 0.16,
                        result_preview_cell_layout.fill_alpha or 0.76
                    )
                    love.graphics.rectangle("fill", cx, cy, cell, cell, preview_cell_corner, preview_cell_corner)
                    love.graphics.setColor(
                        preview_cell_line[1] or 0.58,
                        preview_cell_line[2] or 0.44,
                        preview_cell_line[3] or 0.30,
                        result_preview_cell_layout.line_alpha or 0.30
                    )
                    love.graphics.rectangle("line", cx, cy, cell, cell, preview_cell_corner, preview_cell_corner)
                    if placed then
                        local placed_fallback = result_preview_placed_layout.fallback_color or {0.70, 0.56, 0.40}
                        local c = COLOR_SWATCH[placed.color] or placed_fallback
                        local placed_inset = result_preview_placed_layout.inset or 1
                        local placed_corner = result_preview_placed_layout.corner_radius or 2
                        love.graphics.setColor(c[1], c[2], c[3], result_preview_placed_layout.alpha or 0.86)
                        love.graphics.rectangle(
                            "fill",
                            cx + placed_inset,
                            cy + placed_inset,
                            cell - placed_inset * 2,
                            cell - placed_inset * 2,
                            placed_corner,
                            placed_corner
                        )
                    elseif stained then
                        local stain_color = result_preview_stain_layout.color or {0.54, 0.18, 0.14}
                        love.graphics.setColor(
                            stain_color[1] or 0.54,
                            stain_color[2] or 0.18,
                            stain_color[3] or 0.14,
                            result_preview_stain_layout.alpha or 0.86
                        )
                        love.graphics.circle(
                            "fill",
                            cx + cell * 0.5,
                            cy + cell * 0.5,
                            math.max(
                                result_preview_stain_layout.radius_min or 3,
                                math.floor(cell * (result_preview_stain_layout.radius_ratio or 0.22))
                            )
                        )
                        row_complete = false
                    else
                        row_complete = false
                    end
                end
                if row_complete then
                    local completed_line = result_preview_completed_row_layout.line_color or {0.96, 0.84, 0.54}
                    local completed_line_width = result_preview_completed_row_layout.line_width or 2
                    local ry = gy + (row - 1) * (cell + gap)
                    love.graphics.setColor(
                        completed_line[1] or 0.96,
                        completed_line[2] or 0.84,
                        completed_line[3] or 0.54,
                        result_preview_completed_row_layout.line_alpha or 0.85
                    )
                    love.graphics.setLineWidth(completed_line_width)
                    love.graphics.rectangle(
                        "line",
                        gx - RuntimeUI.sized(result_preview_completed_row_layout.x_expand or 2),
                        ry - RuntimeUI.sized(result_preview_completed_row_layout.y_expand or 2),
                        grid_w + RuntimeUI.sized(result_preview_completed_row_layout.w_expand or 4),
                        cell + RuntimeUI.sized(result_preview_completed_row_layout.h_expand or 4),
                        result_preview_completed_row_layout.corner_radius or 4,
                        result_preview_completed_row_layout.corner_radius or 4
                    )
                    love.graphics.setLineWidth(1)
                end
            end
        end

        local right = {
            x = preview.x + preview.w + RuntimeUI.sized(result_right_panel_layout.gap_from_preview or 22),
            y = preview.y,
            w = box_x + box_w - (preview.x + preview.w + RuntimeUI.sized(result_right_panel_layout.right_margin or 44)),
            h = preview.h,
        }
        local right_panel_corner = result_right_panel_layout.corner_radius or 8
        local right_panel_fill = result_right_panel_layout.fill_color or {0.22, 0.16, 0.11}
        local right_panel_line = result_right_panel_layout.line_color or {0.70, 0.52, 0.33}
        love.graphics.setColor(
            right_panel_fill[1] or 0.22,
            right_panel_fill[2] or 0.16,
            right_panel_fill[3] or 0.11,
            result_right_panel_layout.fill_alpha or 0.88
        )
        love.graphics.rectangle("fill", right.x, right.y, right.w, right.h, right_panel_corner, right_panel_corner)
        love.graphics.setColor(
            right_panel_line[1] or 0.70,
            right_panel_line[2] or 0.52,
            right_panel_line[3] or 0.33,
            result_right_panel_layout.line_alpha or 0.52
        )
        love.graphics.rectangle("line", right.x, right.y, right.w, right.h, right_panel_corner, right_panel_corner)

        local completed_rows = folio and folio.getCompletedRowsCount and folio:getCompletedRowsCount("TEXT") or 0
        local turns = folio and (folio.turn_count or 0) or 0
        local stains = folio and (folio.stain_count or 0) or 0
        local badge = (self.folio_result and self.folio_result.quality)
            or (folio and folio.getQualityTier and folio:getQualityTier() or tr(ScriptoriumUISchema.overlays.result_quality_working))

        local stat_y = right.y + RuntimeUI.sized(result_right_stats_layout.y_offset or 18)
        local stat_gap = RuntimeUI.sized(result_right_stats_layout.gap or 26)
        local stat_font = get_font(result_right_stats_layout.text_size or 14, false)
        local stat_x = right.x + RuntimeUI.sized(result_right_stats_layout.x_offset or 16)
        love.graphics.setFont(stat_font)
        local stat_color = result_right_stats_layout.text_color or {0.96, 0.90, 0.82, 1}
        love.graphics.setColor(stat_color[1], stat_color[2], stat_color[3], stat_color[4] or 1)
        love.graphics.print(tr(ScriptoriumUISchema.overlays.result_rows_completed, {
            count = completed_rows,
        }), stat_x, stat_y)
        love.graphics.print(tr(ScriptoriumUISchema.overlays.result_stains, {
            count = stains,
        }), stat_x, stat_y + stat_gap)
        love.graphics.print(tr(ScriptoriumUISchema.overlays.result_turns, {
            count = turns,
        }), stat_x, stat_y + stat_gap * 2)

        local badge_y = right.y + right.h - RuntimeUI.sized(result_right_badge_layout.y_bottom_offset or 120)
        local badge_w = right.w - RuntimeUI.sized(result_right_badge_layout.width_padding or 32)
        local badge_x = right.x + RuntimeUI.sized(result_right_badge_layout.x_offset or 16)
        local badge_h = RuntimeUI.sized(result_right_badge_layout.height or 64)
        local badge_corner = result_right_badge_layout.corner_radius or 6
        local badge_style = failed and result_right_badge_failed_layout or result_right_badge_success_layout
        local badge_fill = badge_style.fill_color or (failed and {0.34, 0.18, 0.14} or {0.30, 0.22, 0.14})
        local badge_line = badge_style.line_color or (failed and {0.82, 0.46, 0.38} or {0.86, 0.68, 0.44})
        love.graphics.setColor(
            badge_fill[1] or 0.30,
            badge_fill[2] or 0.22,
            badge_fill[3] or 0.14,
            badge_style.fill_alpha or 0.94
        )
        love.graphics.rectangle("fill", badge_x, badge_y, badge_w, badge_h, badge_corner, badge_corner)
        love.graphics.setColor(
            badge_line[1] or 0.86,
            badge_line[2] or 0.68,
            badge_line[3] or 0.44,
            badge_style.line_alpha or 0.82
        )
        love.graphics.rectangle("line", badge_x, badge_y, badge_w, badge_h, badge_corner, badge_corner)
        draw_text_center(badge, {
            x = badge_x,
            y = badge_y + RuntimeUI.sized(result_right_badge_text_layout.y_offset or 10),
            w = badge_w,
            h = RuntimeUI.sized(result_right_badge_text_layout.height or 40),
        }, get_font(result_right_badge_text_layout.text_size or 20, true), result_right_badge_text_layout.text_color or {0.98, 0.90, 0.66, 1})

        local btn_w = math.min(
            RuntimeUI.sized(result_continue_button_layout.width_max or 340),
            box_w - RuntimeUI.sized(result_continue_button_layout.width_margin or 120)
        )
        local btn_h = RuntimeUI.sized(result_continue_button_layout.height or 48)
        local btn_x = box_x + (box_w - btn_w) * 0.5
        local btn_y = box_y + box_h - btn_h - RuntimeUI.sized(result_continue_button_layout.bottom_margin or 18)
        local btn_rect = {x = btn_x, y = btn_y, w = btn_w, h = btn_h}
        self.ui_hit.folio_result_continue = btn_rect

        local hover = point_in_rect(self.mouse_x, self.mouse_y, btn_rect)
        local btn_corner = result_continue_button_layout.corner_radius or 6
        local btn_fill = failed
            and (result_continue_button_layout.failed_fill_color or {0.40, 0.26, 0.22})
            or (result_continue_button_layout.success_fill_color or {0.26, 0.50, 0.30})
        local btn_line = failed
            and (result_continue_button_layout.failed_line_color or {0.86, 0.66, 0.56})
            or (result_continue_button_layout.success_line_color or {0.70, 0.90, 0.64})
        love.graphics.setColor(
            btn_fill[1],
            btn_fill[2],
            btn_fill[3],
            hover and (result_continue_button_layout.fill_alpha_hover or 0.96) or (result_continue_button_layout.fill_alpha_normal or 0.88)
        )
        love.graphics.rectangle("fill", btn_rect.x, btn_rect.y, btn_rect.w, btn_rect.h, btn_corner, btn_corner)
        love.graphics.setColor(
            btn_line[1],
            btn_line[2],
            btn_line[3],
            hover and (result_continue_button_layout.line_alpha_hover or 0.98) or (result_continue_button_layout.line_alpha_normal or 0.86)
        )
        love.graphics.rectangle("line", btn_rect.x, btn_rect.y, btn_rect.w, btn_rect.h, btn_corner, btn_corner)
        local cta = ((self.run and (self.run.current_folio_index or 1) >= (self.run.total_folios or 1))
            and tr(ScriptoriumUISchema.overlays.result_cta_deliver))
            or tr(ScriptoriumUISchema.overlays.result_cta_next)
        draw_text_center(
            cta,
            btn_rect,
            get_font(result_continue_button_layout.text_size or 18, true),
            result_continue_button_layout.text_color or {0.98, 0.94, 0.86, 1}
        )
    end

    function methods.drawHoveredLockTooltip(self)
        ---@type {text:string}|nil
        local hovered = self.hovered_lock
        if not hovered then
            return
        end
        local text = hovered.text
        if text == "" then
            return
        end

        local lock_tooltip_layout = LOCK_TOOLTIP_LAYOUT
        local tooltip_fill = expect_color3(lock_tooltip_layout.fill_color, "deps.OVERLAY_LAYOUT.lock_tooltip.fill_color")
        local tooltip_line = expect_color3(lock_tooltip_layout.line_color, "deps.OVERLAY_LAYOUT.lock_tooltip.line_color")
        local tooltip_text_color = expect_color4(lock_tooltip_layout.text_color, "deps.OVERLAY_LAYOUT.lock_tooltip.text_color")
        local font = get_font(expect_number(lock_tooltip_layout.text_size, "deps.OVERLAY_LAYOUT.lock_tooltip.text_size"), false)
        love.graphics.setFont(font)
        local padding = RuntimeUI.sized(expect_number(lock_tooltip_layout.padding, "deps.OVERLAY_LAYOUT.lock_tooltip.padding"))
        local tw = font:getWidth(text)
        local th = font:getHeight()
        local w, h = ui_dimensions()
        local tooltip_margin = RuntimeUI.sized(expect_number(lock_tooltip_layout.screen_margin, "deps.OVERLAY_LAYOUT.lock_tooltip.screen_margin"))
        local x = clamp(
            self.mouse_x + RuntimeUI.sized(expect_number(lock_tooltip_layout.offset_x, "deps.OVERLAY_LAYOUT.lock_tooltip.offset_x")),
            tooltip_margin,
            w - tw - padding * 2 - tooltip_margin
        )
        local y = clamp(
            self.mouse_y + RuntimeUI.sized(expect_number(lock_tooltip_layout.offset_y, "deps.OVERLAY_LAYOUT.lock_tooltip.offset_y")),
            tooltip_margin,
            h - th - padding * 2 - tooltip_margin
        )

        local tooltip_corner = expect_number(lock_tooltip_layout.box_corner_radius, "deps.OVERLAY_LAYOUT.lock_tooltip.box_corner_radius")
        love.graphics.setColor(
            tooltip_fill[1],
            tooltip_fill[2],
            tooltip_fill[3],
            expect_number(lock_tooltip_layout.fill_alpha, "deps.OVERLAY_LAYOUT.lock_tooltip.fill_alpha")
        )
        love.graphics.rectangle("fill", x, y, tw + padding * 2, th + padding * 2, tooltip_corner, tooltip_corner)
        love.graphics.setColor(
            tooltip_line[1],
            tooltip_line[2],
            tooltip_line[3],
            expect_number(lock_tooltip_layout.line_alpha, "deps.OVERLAY_LAYOUT.lock_tooltip.line_alpha")
        )
        love.graphics.rectangle("line", x, y, tw + padding * 2, th + padding * 2, tooltip_corner, tooltip_corner)
        love.graphics.setColor(tooltip_text_color[1], tooltip_text_color[2], tooltip_text_color[3], tooltip_text_color[4])
        love.graphics.print(text, x + padding, y + padding)
    end

    return methods
end

return Overlays
