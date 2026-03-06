local AudioManager = require("src.core.audio_manager")
local Navigation = require("src.core.navigation")
local EngineBridge = require("src.core.engine_bridge")
local Logger = require("src.core.logger")
local ResolutionManager = require("src.core.resolution_manager")
local I18n = require("src.core.i18n")
local DiceFaces = require("src.core.dice_faces")
local Colors = require("src.data.colors")
local ScriptoriumUISchema = require("src.data.scriptorium_ui_schema")
local FolioTurnReasons = require("src.data.folio_turn_reasons")

local Helpers = require("src.features.scriptorium.helpers")
local point_in_rect = Helpers.point_in_rect

local Actions = {}

local ACTIONS_UI = ScriptoriumUISchema.actions or {}
local ACTIONS_FLOW = ACTIONS_UI.flow or {}
local DEFAULT_PIGMENT = Colors.default_pigment or "OCRA_GIALLA"
local SFX_TOGGLE = ACTIONS_FLOW.audio_toggle or "toggle"
local SFX_CONFIRM = ACTIONS_FLOW.audio_confirm or "confirm"
local SFX_BACK = ACTIONS_FLOW.audio_back or "back"
local SFX_MOVE = ACTIONS_FLOW.audio_move or "move"
local TURN_D8_COLOR_TABLE = Colors.turn_d8_order
local CONFIRM_MOUSE_BUTTON = tonumber(ACTIONS_FLOW.confirm_mouse_button) or 1
local SYSTEM_SETTINGS_MODULE = ACTIONS_FLOW.system_settings_module or "settings"
local SYSTEM_MAIN_MENU_MODULE = ACTIONS_FLOW.system_main_menu_module or "main_menu"

local function tr(entry, params)
    if type(entry) ~= "table" then
        return ""
    end
    return I18n.t(entry.key, entry.default, params)
end

local function show_message(self, title_entry, subtitle_entry, duration, title_params, subtitle_params)
    local title = tr(title_entry, title_params)
    local subtitle = subtitle_entry and tr(subtitle_entry, subtitle_params) or nil
    self:showMessage(title, subtitle, duration)
end

local function random_int(min_v, max_v)
    local rnd = (love and love.math and love.math.random) or math.random
    return rnd(min_v, max_v)
end

local function normalize_face_for_pigment(value)
    local numeric = tonumber(value) or 1
    numeric = math.floor(numeric)
    if numeric < 1 then
        numeric = 1
    end
    return ((numeric - 1) % 6) + 1
end

local function list_contains(list, value)
    if not list then
        return false
    end
    for _, item in ipairs(list) do
        if item == value then
            return true
        end
    end
    return false
end

local function clamp_int(v, min_v, max_v)
    local n = tonumber(v) or min_v
    n = math.floor(n)
    if n < min_v then
        return min_v
    end
    if n > max_v then
        return max_v
    end
    return n
end

local function remove_value(list, value)
    if not list then
        return
    end
    for i = #list, 1, -1 do
        if list[i] == value then
            table.remove(list, i)
        end
    end
end

local function get_required_guided_rows(folio)
    local required = tonumber(folio and folio.required_guided_rows) or 2
    required = math.max(1, math.floor(required))
    return required
end

local function get_bust_stain_amount(folio)
    local pushes = math.max(0, math.floor(tonumber(folio and folio.turn_pushes) or 0))
    if pushes >= 2 then
        return 2
    end
    return 1
end

local function get_wet_buffer_max(folio)
    local max = tonumber(folio and folio.wet_buffer_max)
    if not max then
        return 3
    end
    return math.max(1, math.floor(max))
end

local function get_open_rows_count(folio)
    local rows = folio and folio.getOpenRows and folio:getOpenRows() or {}
    return #rows
end

local function open_rows_have_space(folio)
    if not folio or not folio.elements then
        return false
    end
    local element = folio.active_element or "TEXT"
    local elem = folio.elements[element]
    if not elem or not elem.pattern then
        return false
    end
    local cols = elem.pattern.cols or 5
    local open_rows = folio.getOpenRows and folio:getOpenRows() or {}
    for _, row in ipairs(open_rows) do
        for col = 1, cols do
            local state = folio.getCellState and folio:getCellState(element, row, col) or nil
            if state and (not state.placed) and (not state.wet) and (not state.stained) then
                return true
            end
        end
    end
    return false
end

local function can_open_any_row(folio)
    if not folio then
        return false
    end
    if folio.canOpenAnyRowWithSpace then
        return folio:canOpenAnyRowWithSpace()
    end
    return true
end

local function get_pending_ink_recovery(self)
    return math.max(0, math.floor(tonumber(self and self.pending_ink_recovery) or 0))
end

local function clear_pending_ink_recovery(self)
    self.pending_ink_recovery = nil
    self.pending_ink_recovery_rows = nil
end

local function set_pending_ink_recovery(self, count, rows)
    local pending = math.max(0, math.floor(tonumber(count) or 0))
    if pending <= 0 then
        clear_pending_ink_recovery(self)
        return 0
    end
    self.pending_ink_recovery = pending
    self.pending_ink_recovery_rows = rows
    return pending
end

local function set_ruling_overlay_state(self, actions_left)
    local actions = math.max(0, math.floor(tonumber(actions_left) or 0))
    self.ruling_actions_left = actions
    self.show_ruling_overlay = actions > 0
    if actions <= 0 then
        self.pending_row_swap = nil
    end
end

local function clear_ruling_overlay_state(self)
    set_ruling_overlay_state(self, 0)
end

local function pick_turn_palette_colors(folio, count)
    local target = clamp_int(count or 3, 1, #TURN_D8_COLOR_TABLE)
    if folio and folio.drawTurnPalette then
        local drawn = folio:drawTurnPalette(target)
        if type(drawn) == "table" then
            return drawn
        end
        return {}
    end

    local selected = {}
    while #selected < target do
        local face = random_int(1, #TURN_D8_COLOR_TABLE)
        local color = TURN_D8_COLOR_TABLE[face]
        if color and (not list_contains(selected, color)) then
            selected[#selected + 1] = color
        end
        if #selected >= #TURN_D8_COLOR_TABLE then
            break
        end
    end
    return selected
end

local function pick_turn_palette_from_d8_roll(values, count)
    local target = clamp_int(count or 3, 1, #TURN_D8_COLOR_TABLE)
    local selected = {}
    for _, item in ipairs(values or {}) do
        if type(item) == "table" then
            local sides = math.max(2, math.floor(tonumber(item.sides) or 6))
            local kind = item.kind or "d6"
            if kind == "d8" or sides == 8 then
                local face = clamp_int(item.value, 1, #TURN_D8_COLOR_TABLE)
                local color = TURN_D8_COLOR_TABLE[face]
                if color then
                    selected[#selected + 1] = color
                end
                if #selected >= target then
                    break
                end
            end
        end
    end
    return selected
end
local function count_any_legal_placements(folio, value, palette)
    local total = 0
    for _, color in ipairs(palette) do
        local all_valid = folio:getAllValidPlacements(value, color)
        for _, placements in pairs(all_valid) do
            total = total + #placements
            if total > 0 then
                return total
            end
        end
    end
    return total
end


function Actions.requestRoll(self, max_dice)
    if self.state == "rolling" then
        return
    end
    local folio = self.run and self.run.current_folio or nil
    local pending_recovery = get_pending_ink_recovery(self)
    if pending_recovery > 0 then
        show_message(
            self,
            ACTIONS_UI.message_row_reward_pending_title,
            ACTIONS_UI.message_row_reward_pending_subtext,
            1.6
        )
        AudioManager.play_ui(SFX_BACK)
        return
    end
    if self.show_ruling_overlay then
        show_message(
            self,
            ACTIONS_UI.message_ruling_pending_title,
            ACTIONS_UI.message_ruling_pending_subtext,
            1.4
        )
        AudioManager.play_ui(SFX_BACK)
        return
    end
    if folio and folio.isParchmentConfigured and (not folio:isParchmentConfigured()) then
        show_message(
            self,
            ACTIONS_UI.message_prepare_parchment_title,
            ACTIONS_UI.message_prepare_parchment_subtext,
            1.6
        )
        AudioManager.play_ui(SFX_BACK)
        return
    end
    if folio and (not open_rows_have_space(folio)) then
        if not can_open_any_row(folio) then
            folio.busted = true
            clear_ruling_overlay_state(self)
            if self.openFolioResult then
                self:openFolioResult()
            else
                show_message(
                    self,
                    ACTIONS_UI.message_folio_failed_title,
                    ACTIONS_UI.message_folio_failed_no_rows_subtext,
                    2.0
                )
            end
            return
        end
        show_message(
            self,
            ACTIONS_UI.message_no_open_cells_title,
            ACTIONS_UI.message_no_open_cells_before_roll_subtext,
            1.6
        )
        AudioManager.play_ui(SFX_BACK)
        set_ruling_overlay_state(self, math.max(1, math.floor(tonumber(self.ruling_actions_left) or 0)))
        return
    end

    self.palette_picker = nil
    if self.state == "placing" and (type(self.turn_palette) ~= "table" or #self.turn_palette <= 0) then
        self:ensureTurnPalette()
    end

    local roll_indices = nil
    if self.state == "placing" and self.dice_results and #self.dice_results > 0 then
        roll_indices = self:getRerollIndices()
        if #roll_indices <= 0 then
            show_message(
                self,
                ACTIONS_UI.message_no_dice_left_title,
                ACTIONS_UI.message_no_dice_left_subtext,
                1.4
            )
            self.state = "placing"
            return
        end
    end

    clear_ruling_overlay_state(self)

    -- Keep this state until the physics callback settles dice to avoid double-roll races.
    self.state = "rolling"

    if self.onRollRequest then
        self.onRollRequest(max_dice, roll_indices)
    else
        self.state = "waiting"
    end
end

function Actions.onDiceSettled(self, values)
    if not self.run or not values or #values == 0 then
        self.state = "waiting"
        return
    end

    local folio = self.run.current_folio
    if not folio then
        self.state = "waiting"
        return
    end
    self.pending_stain_choices = nil
    self.pending_stain_total = nil
    self.pending_stain_remaining = nil
    clear_pending_ink_recovery(self)
    clear_ruling_overlay_state(self)

    local normalized_roll = {}
    local placement_roll = {}
    for _, item in ipairs(values) do
        local value = item
        local sides = 6
        local kind = "d6"
        local index = nil
        if type(item) == "table" then
            value = item.value
            sides = item.sides or sides
            kind = item.kind or kind
            index = item.index
        end
        value = tonumber(value) or 1
        value = math.max(1, math.floor(value))
        sides = math.max(2, math.floor(tonumber(sides) or 6))
        local normalized_item = {
            value = value,
            sides = sides,
            kind = kind,
            index = tonumber(index) and math.floor(tonumber(index)) or nil,
        }
        normalized_roll[#normalized_roll + 1] = normalized_item
        if kind == "d6" or sides == 6 then
            placement_roll[#placement_roll + 1] = normalized_item
        end
    end

    if #placement_roll == 0 then
        placement_roll = normalized_roll
    end

    local d8_palette = pick_turn_palette_from_d8_roll(normalized_roll, 3)
    if #d8_palette > 0 then
        self.turn_palette = d8_palette
        if folio.markTurnStarted then
            folio:markTurnStarted(self.turn_palette)
        end
    end

    local palette = self:getTurnPalette()
    if #palette <= 0 then
        palette = self:ensureTurnPalette()
    end

    local has_any_legal = false
    if folio.hasAnyMove then
        has_any_legal = folio:hasAnyMove(placement_roll, palette)
    else
        for _, item in ipairs(placement_roll) do
            if count_any_legal_placements(folio, item.value, palette) > 0 then
                has_any_legal = true
                break
            end
        end
    end

    if not has_any_legal then
        local lost_wet = folio.discardWetBuffer and folio:discardWetBuffer() or 0
        folio.bust_count = (folio.bust_count or 0) + 1
        if self.run then
            self.run.reputation = math.max(0, (self.run.reputation or 0) - 1)
        end

        local stains_to_add = get_bust_stain_amount(folio)
        local candidates = folio.getBustStainCandidates and folio:getBustStainCandidates() or {}
        self.dice_results = {}
        self.selected_die = nil
        self.palette_picker = nil
        self.turn_palette = nil
        clear_ruling_overlay_state(self)

        if #candidates > 1 then
            self.message = nil
            self.message_timer = 0
            self.pending_stain_total = stains_to_add
            self.pending_stain_remaining = stains_to_add
            self.pending_stain_choices = candidates
            self.state = "stain_pick"
            AudioManager.play_ui(SFX_BACK)
            return
        end

        if #candidates == 1 then
            self.pending_stain_total = stains_to_add
            self.pending_stain_remaining = stains_to_add
            self.pending_stain_choices = candidates
            self:pickBustStainCell(candidates[1])
            return
        end

        local bust_reached = folio.addStain and folio:addStain(stains_to_add) or false
        local bust_text = bust_reached and tr(ACTIONS_UI.message_bust_result_ruined_title)
            or tr(ACTIONS_UI.message_bust_result_title)
        self:showMessage(
            bust_text,
            tr(ACTIONS_UI.message_bust_result_wet_lost_subtext, {
                lost = lost_wet,
                stains = stains_to_add,
            }),
            2.2
        )
        self.state = "waiting"
        return
    end

    self.dice_results = {}
    for _, item in ipairs(placement_roll) do
        self.dice_results[#self.dice_results + 1] = {
            value = item.value,
            sides = item.sides,
            kind = item.kind,
            index = item.index,
            color_key = nil,
            used = false,
            unusable = false,
            burned = false,
            legal_count = 0,
        }
    end

    self.selected_cell = nil
    self.palette_picker = nil
    self:refreshDiceLegality()
    self.selected_die = nil
    clear_ruling_overlay_state(self)

    if folio.busted then
        self:showMessage(
            tr(ACTIONS_UI.message_bust_title),
            tr(ACTIONS_UI.message_bust_subtext)
        )
        self.state = "waiting"
    elseif folio.completed then
        self:showMessage(
            tr(ACTIONS_UI.message_completed_title),
            tr(ACTIONS_UI.message_completed_subtext)
        )
        self.state = "waiting"
    else
        self.state = "placing"
    end
end

function Actions.performSealReroll(self)
    local folio = self.run and self.run.current_folio
    if self.state ~= "placing" or not folio or not (folio.canSpendSeal and folio:canSpendSeal()) then
        return
    end
    local die = self:getSelectedDie()
    if not die or die.used then
        show_message(
            self,
            ACTIONS_UI.message_select_die_title,
            ACTIONS_UI.message_select_die_subtext_before_seal,
            1.3
        )
        AudioManager.play_ui(SFX_BACK)
        return
    end
    if not folio:spendSeal() then
        return
    end

    local sides = math.max(2, math.floor((die and die.sides) or 6))
    die.value = random_int(1, sides)
    die.color_key = nil
    die.unusable = false
    die.burned = false
    AudioManager.play_ui(SFX_CONFIRM)
    self:refreshDiceLegality()
    show_message(
        self,
        ACTIONS_UI.message_seal_title,
        ACTIONS_UI.message_seal_subtext_reroll_one_die,
        1.2
    )
end

function Actions.performSealAdjust(self, delta)
    local folio = self.run and self.run.current_folio
    if self.state ~= "placing" or not folio or not (folio.canSpendSeal and folio:canSpendSeal()) then
        return
    end
    local die = self:getSelectedDie()
    if not die or die.used then
        show_message(
            self,
            ACTIONS_UI.message_select_die_title,
            ACTIONS_UI.message_select_die_subtext_before_seal,
            1.3
        )
        AudioManager.play_ui(SFX_BACK)
        return
    end
    local sides = math.max(2, math.floor((die and die.sides) or 6))
    local next_value = (die.value or 1) + (delta or 0)
    if next_value < 1 or next_value > sides then
        return
    end
    if not folio:spendSeal() then
        return
    end

    die.value = next_value
    die.color_key = nil
    die.unusable = false
    die.burned = false
    AudioManager.play_ui(SFX_CONFIRM)
    self:refreshDiceLegality()
    show_message(
        self,
        ACTIONS_UI.message_seal_title,
        ACTIONS_UI.message_seal_subtext_adjusted_die_to,
        1.2,
        nil,
        {value = tostring(die.value)}
    )
end

function Actions.placeSelectedDieAt(self, element, row, col, chosen_color)
    if self.state ~= "placing" or not self.run or not self.run.current_folio then
        return false
    end
    local die = self:getSelectedDie()
    if not die or die.used then
        return false
    end

    local folio = self.run.current_folio
    local wet_max = get_wet_buffer_max(folio)
    local wet_count = folio.getWetCount and folio:getWetCount() or 0
    if wet_count >= wet_max then
        show_message(
            self,
            ACTIONS_UI.message_wet_buffer_full_title,
            ACTIONS_UI.message_wet_buffer_full_subtext_press_commit,
            1.6
        )
        AudioManager.play_ui(SFX_BACK)
        return false
    end
    local legal_colors = self:getLegalPaletteColorsForPlacement(element, row, col, die.value)
    if #legal_colors <= 0 then
        show_message(
            self,
            ACTIONS_UI.message_placement_blocked_title,
            ACTIONS_UI.message_placement_blocked_subtext_no_palette_fit,
            1.4
        )
        AudioManager.play_ui(SFX_BACK)
        self:refreshDiceLegality()
        return false
    end

    local color_key = chosen_color
    if not color_key or not list_contains(legal_colors, color_key) then
        color_key = legal_colors[1]
    end

    local pigment_face = normalize_face_for_pigment(die.value)
    local fallback_pigment = (DiceFaces.DiceFaces[pigment_face] and DiceFaces.DiceFaces[pigment_face].fallback)
        or DEFAULT_PIGMENT
    local ok, reason, placement, events = folio:addWetDie(element, row, col, die.value, color_key, fallback_pigment)
    if not ok then
        self:showMessage(
            tr(ACTIONS_UI.message_placement_blocked_title),
            reason or tr(ACTIONS_UI.message_placement_blocked_subtext_cannot_place_die),
            1.6
        )
        AudioManager.play_ui(SFX_BACK)
        self:refreshDiceLegality()
        return false
    end
    if placement then
        placement.source_roll_index = die.index
    end

    die.used = true
    die.color_key = color_key
    die.unusable = false
    die.legal_count = 0
    die.burned = false
    self.selected_cell = {element = element, row = row, col = col}
    AudioManager.play_ui(SFX_MOVE)

    if events and events.double_awarded then
        show_message(
            self,
            ACTIONS_UI.message_double_award_title,
            ACTIONS_UI.message_double_award_subtext,
            1.8
        )
    end

    self:refreshDiceLegality()
    self.selected_die = nil

    wet_count = folio.getWetCount and folio:getWetCount() or 0
    wet_max = get_wet_buffer_max(folio)
    if wet_count >= wet_max then
        self:performStop({auto = true})
        return true
    end

    if folio.completed then
        show_message(
            self,
            ACTIONS_UI.message_completed_title,
            ACTIONS_UI.message_completed_subtext
        )
    end

    return true
end

function Actions.undoWetPlacement(self, index)
    if self.state ~= "placing" or not self.run or not self.run.current_folio then
        return false
    end
    local folio = self.run.current_folio
    local rerolls_used = math.max(0, math.floor(tonumber(folio.turn_pushes) or 0))
    if rerolls_used > 0 then
        show_message(
            self,
            ACTIONS_UI.message_undo_locked_title,
            ACTIONS_UI.message_undo_locked_subtext_after_reroll,
            1.4
        )
        AudioManager.play_ui(SFX_BACK)
        return false
    end
    if not folio.removeWetPlacementAt then
        return false
    end
    local entry = folio:removeWetPlacementAt(index)
    if not entry then
        AudioManager.play_ui(SFX_BACK)
        return false
    end

    local restored = false
    local source_idx = tonumber(entry.source_roll_index)
    if source_idx and self.dice_results then
        source_idx = math.floor(source_idx)
        for _, die in ipairs(self.dice_results) do
            local die_idx = tonumber(die and die.index)
            if die_idx and math.floor(die_idx) == source_idx and die.used then
                die.used = false
                die.color_key = nil
                die.unusable = false
                die.legal_count = 0
                restored = true
                break
            end
        end
    end
    if (not restored) and self.dice_results then
        for _, die in ipairs(self.dice_results) do
            if die and die.used and (tonumber(die.value) == tonumber(entry.value)) then
                die.used = false
                die.color_key = nil
                die.unusable = false
                die.legal_count = 0
                break
            end
        end
    end

    self.selected_die = nil
    self.palette_picker = nil
    self:refreshDiceLegality()
    AudioManager.play_ui(SFX_TOGGLE)
    return true
end

function Actions.autoPlaceDie(self, value)
    if not self.run or not self.run.current_folio then
        return false
    end

    local folio = self.run.current_folio
    local palette = self:getTurnPalette()
    local function try_place_value(candidate_value)
        for _, color_key in ipairs(palette) do
            for _, element in ipairs(folio.ELEMENTS) do
                local valid_cells = folio:getValidPlacements(element, candidate_value, color_key)
                if #valid_cells > 0 then
                    local target_cell = valid_cells[1]
                    local normalized_candidate = normalize_face_for_pigment(candidate_value)
                    local fallback_pigment = (DiceFaces.DiceFaces[candidate_value] and DiceFaces.DiceFaces[candidate_value].fallback)
                        or (DiceFaces.DiceFaces[normalized_candidate] and DiceFaces.DiceFaces[normalized_candidate].fallback)
                        or DEFAULT_PIGMENT
                    local placed_successfully =
                        folio:addWetDie(element, target_cell.row, target_cell.col, candidate_value, color_key, fallback_pigment)
                    if placed_successfully then
                        return true
                    end
                end
            end
        end
        return false
    end

    if try_place_value(value) then
        return true
    end

    if value > 1 and folio.canUseTool and folio:canUseTool("knife") then
        local corrected_value = value - 1
        if try_place_value(corrected_value) then
            folio:consumeToolUse("knife")
            return true
        end
    end

    return false
end


function Actions.keypressed(self, _key)
end

function Actions.mousepressed(self, x, y, button)
    if button ~= CONFIRM_MOUSE_BUTTON then
        return
    end

    local ui_x, ui_y = ResolutionManager.to_virtual(x, y)

    if self.message then
        self.message = nil
        self.message_timer = 0
        if self.advanceRunIfResolved then
            self:advanceRunIfResolved()
        end
        return
    end

    if self.show_folio_result then
        if self.ui_hit.folio_result_continue and point_in_rect(ui_x, ui_y, self.ui_hit.folio_result_continue) then
            self.show_folio_result = false
            self.folio_result = nil
            if self.advanceRunIfResolved then
                self:advanceRunIfResolved()
            end
        end
        return
    end

    if self.show_run_setup then
        -- Setup overlay has priority: clicks here must not trigger gameplay controls below.
        if self.ui_hit.setup_guided_rows then
            for _, hit in ipairs(self.ui_hit.setup_guided_rows) do
                if point_in_rect(ui_x, ui_y, hit.rect) then
                    if self:toggleSetupGuidedRow(hit.row) then
                        AudioManager.play_ui(SFX_TOGGLE)
                    end
                    return
                end
            end
        end
        if self.ui_hit.setup_initial_rows then
            for _, hit in ipairs(self.ui_hit.setup_initial_rows) do
                if point_in_rect(ui_x, ui_y, hit.rect) then
                    if self:setSetupInitialRow(hit.row) then
                        AudioManager.play_ui(SFX_TOGGLE)
                    else
                        AudioManager.play_ui(SFX_BACK)
                    end
                    return
                end
            end
        end
        if point_in_rect(ui_x, ui_y, self.ui_hit.setup_start_button) then
            if self:applyParchmentSetup() then
                self.show_run_setup = false
                AudioManager.play_ui(SFX_CONFIRM)
            end
        end
        return
    end

    local pending_recovery = get_pending_ink_recovery(self)
    if pending_recovery > 0 then
        if self.ui_hit.inkwell_buttons then
            for _, hit in ipairs(self.ui_hit.inkwell_buttons) do
                if point_in_rect(ui_x, ui_y, hit.rect) then
                    self:pickInkRecoveryColor(hit.color)
                    return
                end
            end
        end
        AudioManager.play_ui(SFX_BACK)
        return
    end

    if self.show_ruling_overlay then
        if self.ui_hit.ruling_row_buttons then
            for _, hit in ipairs(self.ui_hit.ruling_row_buttons) do
                if point_in_rect(ui_x, ui_y, hit.rect) then
                    if self:toggleRowState(hit.row) then
                        if self.ruling_actions_left and self.ruling_actions_left <= 0 then
                            clear_ruling_overlay_state(self)
                        end
                    end
                    return
                end
            end
        end
        if self.ui_hit.ruling_done_button and point_in_rect(ui_x, ui_y, self.ui_hit.ruling_done_button) then
            if self.ui_hit.ruling_done_enabled then
                clear_ruling_overlay_state(self)
                AudioManager.play_ui(SFX_CONFIRM)
            else
                AudioManager.play_ui(SFX_BACK)
            end
            return
        end
        return
    end

    local menu_open = self.show_system_menu and true or false
    local clicked_system = point_in_rect(ui_x, ui_y, self.ui_hit.system_button)
    local clicked_settings = point_in_rect(ui_x, ui_y, self.ui_hit.system_settings_button)
    local clicked_main_menu = point_in_rect(ui_x, ui_y, self.ui_hit.system_main_menu_button)
    local clicked_restart = point_in_rect(ui_x, ui_y, self.ui_hit.system_restart_button)
    if clicked_system then
        self.show_system_menu = not menu_open
        AudioManager.play_ui(SFX_TOGGLE)
        return
    end
    if menu_open and clicked_settings then
        self.show_system_menu = false
        AudioManager.play_ui(SFX_CONFIRM)
        Navigation.go(SYSTEM_SETTINGS_MODULE)
        return
    end
    if menu_open and clicked_restart then
        self.show_system_menu = false
        AudioManager.play_ui(SFX_CONFIRM)
        if self.clearPersistedRun then
            self:clearPersistedRun("restart")
        end
        self:performRestart()
        return
    end
    if menu_open and clicked_main_menu then
        self.show_system_menu = false
        AudioManager.play_ui(SFX_BACK)
        if self.persistRunSnapshot then
            self:persistRunSnapshot("return_to_menu")
        end
        Navigation.go(SYSTEM_MAIN_MENU_MODULE)
        return
    end
    if menu_open then
        self.show_system_menu = false
        return
    end

    if self.state == "stain_pick" then
        if self.ui_hit.stain_choice_cells then
            for _, hit in ipairs(self.ui_hit.stain_choice_cells) do
                if point_in_rect(ui_x, ui_y, hit.rect) then
                    self:pickBustStainCell(hit)
                    return
                end
            end
        end
        return
    end

    if self.state == "placing" then
        if self.ui_hit.wet_buffer_undo_buttons then
            for _, hit in ipairs(self.ui_hit.wet_buffer_undo_buttons) do
                if point_in_rect(ui_x, ui_y, hit.rect) then
                    if self.undoWetPlacement then
                        self:undoWetPlacement(hit.index)
                    end
                    return
                end
            end
        end

        local roll_index = EngineBridge.pickTrayDie(x, y)
        if roll_index then
            if self:setSelectedDieByRollIndex(roll_index) then
                self.palette_picker = nil
                AudioManager.play_ui(SFX_TOGGLE)
                return
            end
        end

        if self.palette_picker and self.ui_hit.palette_color_buttons then
            for _, pick in ipairs(self.ui_hit.palette_color_buttons) do
                if point_in_rect(ui_x, ui_y, pick.rect) then
                    local picker = self.palette_picker
                    if picker and self:placeSelectedDieAt(picker.element, picker.row, picker.col, pick.color) then
                        self.palette_picker = nil
                        return
                    end
                end
            end
            -- Click outside color picker closes it.
            self.palette_picker = nil
        end

        if self.ui_hit.dice_chips then
            for _, chip in ipairs(self.ui_hit.dice_chips) do
                if point_in_rect(ui_x, ui_y, chip.rect) then
                    if self:setSelectedDie(chip.index) then
                        AudioManager.play_ui(SFX_TOGGLE)
                    end
                    return
                end
            end
        end

        if point_in_rect(ui_x, ui_y, self.ui_hit.seal_reroll_button) then
            self:performSealReroll()
            return
        end
        if point_in_rect(ui_x, ui_y, self.ui_hit.seal_plus_button) then
            self:performSealAdjust(1)
            return
        end
        if point_in_rect(ui_x, ui_y, self.ui_hit.seal_minus_button) then
            self:performSealAdjust(-1)
            return
        end

        if self.ui_hit.placement_cells then
            for _, hit in ipairs(self.ui_hit.placement_cells) do
                if point_in_rect(ui_x, ui_y, hit.rect) then
                    local die = self:getSelectedDie()
                    if not die or die.used then
                        show_message(
                            self,
                            ACTIONS_UI.message_select_die_title,
                            ACTIONS_UI.message_select_die_subtext_click_tray_first,
                            1.3
                        )
                        AudioManager.play_ui(SFX_BACK)
                        return
                    end

                    local options = hit.palette_options
                    if type(options) ~= "table" or #options == 0 then
                        options = self:getLegalPaletteColorsForPlacement(hit.element, hit.row, hit.col, die.value)
                    end
                    if #options == 1 then
                        if self:placeSelectedDieAt(hit.element, hit.row, hit.col, options[1]) then
                            return
                        end
                    elseif #options > 1 then
                        self.palette_picker = {
                            die_index = self.selected_die,
                            element = hit.element,
                            row = hit.row,
                            col = hit.col,
                            options = options,
                            anchor_x = hit.rect.x + hit.rect.w * 0.5,
                            anchor_y = hit.rect.y - 2,
                        }
                        AudioManager.play_ui(SFX_TOGGLE)
                        return
                    end
                end
            end
        end

        if point_in_rect(ui_x, ui_y, self.ui_hit.stop_button) then
            self:performStop()
            return
        end
        if point_in_rect(ui_x, ui_y, self.ui_hit.push_all_button) then
            self:performPushAll()
            return
        end
        if point_in_rect(ui_x, ui_y, self.ui_hit.push_one_button) then
            self:performPushOne()
            return
        end
        if point_in_rect(ui_x, ui_y, self.ui_hit.prepare_risk_button) then
            self:performPreparation("risk")
            return
        end
        if point_in_rect(ui_x, ui_y, self.ui_hit.prepare_guard_button) then
            self:performPreparation("guard")
            return
        end
        return
    end

    if point_in_rect(ui_x, ui_y, self.ui_hit.restart_button) then
        self:performRestart()
        return
    end
    if point_in_rect(ui_x, ui_y, self.ui_hit.roll_button) then
        AudioManager.play_ui(SFX_CONFIRM)
        self:requestRoll()
        return
    end
end

function Actions.mousemoved(self, x, y, dx, dy)
    local ui_x, ui_y = ResolutionManager.to_virtual(x, y)
    self.mouse_x = ui_x
    self.mouse_y = ui_y
    self.hovered_lock = nil
    if self.lock_badges then
        for _, badge in ipairs(self.lock_badges) do
            if point_in_rect(ui_x, ui_y, badge.rect) then
                self.hovered_lock = badge
                break
            end
        end
    end
end

function Actions.wheelmoved(self, x, y)
end

function Actions.clearTurnPalette(self)
    self.turn_palette = nil
    self.palette_picker = nil
end

function Actions.getTurnPalette(self)
    if type(self.turn_palette) ~= "table" then
        return {}
    end
    return self.turn_palette
end

function Actions.ensureTurnPalette(self)
    if type(self.turn_palette) == "table" and #self.turn_palette > 0 then
        return self.turn_palette
    end
    local folio = self.run and self.run.current_folio or nil
    self.turn_palette = pick_turn_palette_colors(folio, 3)
    if folio and folio.markTurnStarted then
        folio:markTurnStarted(self.turn_palette)
    end
    return self.turn_palette
end

function Actions.toggleSetupGuidedRow(self, row)
    local folio = self.run and self.run.current_folio or nil
    if not folio then
        return false
    end
    local row_count = folio.getRowCount and folio:getRowCount("TEXT") or 4
    local normalized = clamp_int(row, 1, row_count)
    self.setup_guided_rows = self.setup_guided_rows or {}
    self.setup_initial_row = tonumber(self.setup_initial_row) or nil

    if list_contains(self.setup_guided_rows, normalized) then
        if #self.setup_guided_rows <= 1 then
            return false
        end
        remove_value(self.setup_guided_rows, normalized)
        if self.setup_initial_row == normalized then
            self.setup_initial_row = self.setup_guided_rows[1]
        end
        return true
    end

    local required_guided = get_required_guided_rows(folio)
    if #self.setup_guided_rows >= required_guided then
        return false
    end
    self.setup_guided_rows[#self.setup_guided_rows + 1] = normalized
    table.sort(self.setup_guided_rows)
    if not self.setup_initial_row or (not list_contains(self.setup_guided_rows, self.setup_initial_row)) then
        self.setup_initial_row = normalized
    end
    return true
end

function Actions.setSetupInitialRow(self, row)
    local normalized = math.floor(tonumber(row) or -1)
    if normalized <= 0 then
        return false
    end
    if not list_contains(self.setup_guided_rows or {}, normalized) then
        return false
    end
    self.setup_initial_row = normalized
    return true
end

function Actions.applyParchmentSetup(self)
    local folio = self.run and self.run.current_folio or nil
    if not folio or not folio.configureParchment then
        return true
    end
    local guided = self.setup_guided_rows or {}
    local initial = nil
    local max_open_rows = tonumber(folio.max_open_rows) and math.floor(tonumber(folio.max_open_rows)) or 2
    local ok, reason = folio:configureParchment(guided, initial, max_open_rows)
    if not ok then
        if reason then
            Logger.debug("[Scriptorium] Setup rejected: " .. tostring(reason))
        end
        AudioManager.play_ui(SFX_BACK)
        return false
    end
    return true
end

function Actions.pickBustStainCell(self, choice)
    local folio = self.run and self.run.current_folio or nil
    if not folio or not (self.pending_stain_choices and #self.pending_stain_choices > 0) then
        return false
    end
    local ok, reason, result = folio:applyStainChoice(choice)
    if not ok then
        self:showMessage(
            tr(ACTIONS_UI.message_stain_blocked_title),
            reason or tr(ACTIONS_UI.message_stain_blocked_subtext),
            1.4
        )
        AudioManager.play_ui(SFX_BACK)
        return false
    end

    local remaining = math.max(0, (self.pending_stain_remaining or 1) - 1)
    self.pending_stain_remaining = remaining

    if remaining > 0 then
        local next_choices = folio.getBustStainCandidates and folio:getBustStainCandidates() or {}
        if #next_choices > 0 then
            self.pending_stain_choices = next_choices
            self.state = "stain_pick"
            AudioManager.play_ui(SFX_CONFIRM)
            show_message(
                self,
                ACTIONS_UI.message_bust_followup_title,
                ACTIONS_UI.message_bust_followup_subtext,
                1.4
            )
            return true
        end
        folio:addStain(remaining)
    end

    self.pending_stain_choices = nil
    self.pending_stain_remaining = nil
    local total = self.pending_stain_total or 1
    self.pending_stain_total = nil
    self.state = "waiting"
    AudioManager.play_ui(SFX_CONFIRM)

    local bust_text = (result and result.busted)
        and tr(ACTIONS_UI.message_bust_result_ruined_title)
        or tr(ACTIONS_UI.message_bust_result_title)
    local subtitle = tr(ACTIONS_UI.message_bust_result_subtext, {
        row = result and result.row or 0,
        col = result and result.col or 0,
        count = total,
    })
    self:showMessage(bust_text, subtitle, 1.9)
    return true
end

function Actions.pickInkRecoveryColor(self, color)
    local folio = self.run and self.run.current_folio or nil
    local pending = get_pending_ink_recovery(self)
    if not folio or pending <= 0 then
        return false
    end

    local recovered, reason = folio:recoverInk(color, 1)
    if recovered <= 0 then
        self:showMessage(
            tr(ACTIONS_UI.message_inkwell_full_title),
            reason or tr(ACTIONS_UI.message_inkwell_full_subtext_choose_missing),
            1.3
        )
        AudioManager.play_ui(SFX_BACK)
        return false
    end

    pending = pending - 1
    if pending <= 0 then
        clear_pending_ink_recovery(self)
        show_message(
            self,
            ACTIONS_UI.message_row_reward_title,
            ACTIONS_UI.message_row_reward_subtext,
            1.3,
            nil,
            {color = tostring(color)}
        )
    else
        self.pending_ink_recovery = pending
    end
    AudioManager.play_ui(SFX_CONFIRM)
    return true
end

function Actions.toggleRowState(self, row)
    local folio = self.run and self.run.current_folio or nil
    if not folio or not folio.isParchmentConfigured or not folio:isParchmentConfigured() then
        return false
    end
    if not self.ruling_actions_left or self.ruling_actions_left <= 0 then
        show_message(
            self,
            ACTIONS_UI.message_ruling_title,
            ACTIONS_UI.message_ruling_adjust_after_commit_subtext,
            1.5
        )
        AudioManager.play_ui(SFX_BACK)
        return false
    end
    local row_num = math.floor(tonumber(row) or -1)
    if row_num <= 0 then
        return false
    end
    local function mark_row_open(row_id)
        if not self.row_ruling_animations then
            return
        end
        local now = (love and love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()
        self.row_ruling_animations[row_id] = now
    end

    local ok, reason
    if self.pending_row_swap then
        local swap_target = self.pending_row_swap
        if self.pending_row_swap == row_num then
            self.pending_row_swap = nil
            show_message(
                self,
                ACTIONS_UI.message_ruling_title,
                ACTIONS_UI.message_ruling_swap_cancelled_subtext,
                1.2
            )
            AudioManager.play_ui(SFX_BACK)
            return false
        end
        if not folio:isRowOpen(row_num) then
            show_message(
                self,
                ACTIONS_UI.message_ruling_title,
                ACTIONS_UI.message_ruling_select_open_row_to_close_subtext,
                1.4
            )
            AudioManager.play_ui(SFX_BACK)
            return false
        end
        local closed, close_reason = folio:closeRow(row_num, true)
        if not closed then
            self:showMessage(
                tr(ACTIONS_UI.message_ruling_title),
                close_reason or tr(ACTIONS_UI.message_ruling_cannot_close_row_subtext),
                1.4
            )
            AudioManager.play_ui(SFX_BACK)
            return false
        end
        ok, reason = folio:openRow(self.pending_row_swap)
        if ok then
            self.pending_row_swap = nil
            self.ruling_actions_left = math.max(0, (self.ruling_actions_left or 1) - 1)
            mark_row_open(swap_target)
            AudioManager.play_ui(SFX_TOGGLE)
            return true
        end
        folio:openRow(row_num)
        self:showMessage(
            tr(ACTIONS_UI.message_ruling_title),
            reason or tr(ACTIONS_UI.message_ruling_cannot_open_row_subtext),
            1.5
        )
        AudioManager.play_ui(SFX_BACK)
        return false
    end

    if folio:isRowOpen(row_num) then
        ok, reason = folio:closeRow(row_num)
    else
        local max_open = tonumber(folio.max_open_rows) or 2
        if get_open_rows_count(folio) >= max_open then
            self.pending_row_swap = row_num
            show_message(
                self,
                ACTIONS_UI.message_ruling_title,
                ACTIONS_UI.message_ruling_choose_open_row_to_close_subtext,
                1.6
            )
            AudioManager.play_ui(SFX_TOGGLE)
            return true
        end
        ok, reason = folio:openRow(row_num)
    end

    if ok then
        self.ruling_actions_left = math.max(0, (self.ruling_actions_left or 1) - 1)
        if folio:isRowOpen(row_num) then
            mark_row_open(row_num)
        end
        AudioManager.play_ui(SFX_TOGGLE)
        return true
    end
    if reason and reason ~= "" then
        self:showMessage(tr(ACTIONS_UI.message_ruling_title), reason, 1.5)
    end
    AudioManager.play_ui(SFX_BACK)
    return false
end

function Actions.getLegalPaletteColorsForPlacement(self, element, row, col, die_value)
    local folio = self.run and self.run.current_folio
    if not folio then
        return {}
    end
    local value = clamp_int(die_value, 1, 6)
    local legal = {}
    local palette = self:getTurnPalette()
    for _, color in ipairs(palette) do
        local ok = folio:canPlaceDie(element, row, col, value, color)
        if ok then
            legal[#legal + 1] = color
        end
    end
    return legal
end

function Actions.getRerollIndices(self)
    local indices = {}
    if not self.dice_results then
        return indices
    end
    local seen = {}
    for i, die in ipairs(self.dice_results) do
        if die and not die.used then
            local idx = tonumber(die.index) or i
            idx = math.floor(idx)
            if idx > 0 and not seen[idx] then
                indices[#indices + 1] = idx
                seen[idx] = true
            end
        end
    end
    table.sort(indices)
    return indices
end

function Actions.getSelectedDie(self)
    if not self.dice_results then
        return nil, nil
    end
    if type(self.selected_die) ~= "number" then
        return nil, nil
    end
    local die = self.dice_results[self.selected_die]
    if not die then
        return nil, nil
    end
    return die, self.selected_die
end

function Actions.setSelectedDie(self, index)
    if type(index) ~= "number" or not self.dice_results then
        self.selected_die = nil
        return false
    end
    local die = self.dice_results[index]
    if not die or die.used then
        return false
    end
    self.selected_die = index
    return true
end

function Actions.setSelectedDieByRollIndex(self, roll_index)
    if not self.dice_results then
        self.selected_die = nil
        return false
    end

    local target = tonumber(roll_index)
    if not target then
        return false
    end
    target = math.floor(target)
    if target <= 0 then
        return false
    end

    for i, die in ipairs(self.dice_results) do
        local die_roll_index = tonumber(die and die.index)
        if die_roll_index and math.floor(die_roll_index) == target and (not die.used) then
            self.selected_die = i
            return true
        end
    end

    return false
end

function Actions.refreshDiceLegality(self)
    local folio = self.run and self.run.current_folio
    if not folio or not self.dice_results then
        return
    end

    local palette = self:getTurnPalette()
    for _, die in ipairs(self.dice_results) do
        if die and not die.used then
            local legal_count = 0
            local seen = {}
            for _, color in ipairs(palette) do
                local all_valid = folio:getAllValidPlacements(die.value, color)
                for element, placements in pairs(all_valid) do
                    for _, placement in ipairs(placements) do
                        local key = tostring(element) .. ":" .. tostring(placement.row) .. ":" .. tostring(placement.col)
                        if not seen[key] then
                            seen[key] = true
                            legal_count = legal_count + 1
                        end
                    end
                end
            end
            die.legal_count = legal_count
            die.unusable = legal_count <= 0
        elseif die then
            die.legal_count = 0
            die.unusable = false
        end
    end
end

function Actions.autoSelectPlayableDie(self)
    if not self.dice_results then
        self.selected_die = nil
        return nil
    end

    local current_die, current_index = self:getSelectedDie()
    if current_die and not current_die.used and not current_die.unusable then
        return current_index
    end

    for i, die in ipairs(self.dice_results) do
        if die and not die.used and not die.unusable then
            self.selected_die = i
            return i
        end
    end

    for i, die in ipairs(self.dice_results) do
        if die and not die.used then
            self.selected_die = i
            return i
        end
    end

    self.selected_die = nil
    return nil
end

local function perform_push(self, push_mode)
    if self.state ~= "placing" or not self.run or not self.run.current_folio then
        return
    end
    local folio = self.run.current_folio
    local wet_max = get_wet_buffer_max(folio)
    local wet_count = folio.getWetCount and folio:getWetCount() or 0
    if wet_count >= wet_max then
        show_message(
            self,
            ACTIONS_UI.message_wet_buffer_full_title,
            ACTIONS_UI.message_wet_buffer_full_subtext_press_commit,
            1.6
        )
        AudioManager.play_ui(SFX_BACK)
        return
    end
    local has_placed_in_current_roll = false
    for _, die in ipairs(self.dice_results or {}) do
        if die and die.used then
            has_placed_in_current_roll = true
            break
        end
    end
    if not has_placed_in_current_roll then
        show_message(
            self,
            ACTIONS_UI.message_place_first_title,
            ACTIONS_UI.message_place_first_subtext_before_reroll,
            1.6
        )
        AudioManager.play_ui(SFX_BACK)
        return
    end
    local pushed, push_reason = folio:registerPush(push_mode)
    if pushed == false then
        local reason_text = push_reason
        if push_reason == FolioTurnReasons.reroll_limit_reached then
            reason_text = tr(ACTIONS_UI.message_reroll_limit_subtext_commit_before_new_roll)
        elseif type(reason_text) ~= "string" or reason_text == "" then
            reason_text = tr(ACTIONS_UI.message_reroll_limit_subtext_commit_before_new_roll)
        end
        self:showMessage(
            tr(ACTIONS_UI.message_reroll_limit_title),
            reason_text,
            1.6
        )
        AudioManager.play_ui(SFX_BACK)
        return
    end
    self.selected_die = nil
    AudioManager.play_ui(SFX_CONFIRM)
    self:requestRoll(nil)
end

function Actions.performPushAll(self)
    perform_push(self, "all")
end

function Actions.performPushOne(self)
    perform_push(self, "one")
end

function Actions.performStop(self, opts)
    if self.state ~= "placing" or not self.run or not self.run.current_folio then
        return
    end
    AudioManager.play_ui(SFX_CONFIRM)
    local commit_result = self.run.current_folio:commitWetBuffer()
    if commit_result and commit_result.committed and commit_result.committed > 0 then
        AudioManager.play_ui(SFX_MOVE)
    end
    self.dice_results = {}
    self.selected_die = nil
    self.palette_picker = nil
    self.turn_palette = nil
    clear_pending_ink_recovery(self)

    local rows_completed = (commit_result and commit_result.rows_completed) or {}
    local recovery_count = math.max(0, math.floor(tonumber(commit_result and commit_result.ink_recovery_available) or #rows_completed))
    if recovery_count > 0 and (not self.run.current_folio.completed) then
        set_pending_ink_recovery(self, recovery_count, rows_completed)
    end

    local commit_actions_left = (commit_result and commit_result.committed and commit_result.committed > 0) and 1 or 0
    set_ruling_overlay_state(self, commit_actions_left)
    if (not self.run.current_folio.completed) and (not open_rows_have_space(self.run.current_folio)) then
        if not can_open_any_row(self.run.current_folio) then
            self.run.current_folio.busted = true
            clear_ruling_overlay_state(self)
            if self.openFolioResult then
                self:openFolioResult()
            else
                show_message(
                    self,
                    ACTIONS_UI.message_folio_failed_title,
                    ACTIONS_UI.message_folio_failed_no_rows_subtext,
                    2.0
                )
            end
        else
            set_ruling_overlay_state(self, math.max(1, self.ruling_actions_left or 0))
            show_message(
                self,
                ACTIONS_UI.message_no_open_cells_title,
                ACTIONS_UI.message_no_open_cells_subtext_open_row_to_continue,
                1.6
            )
        end
    end
    if self.run.current_folio.completed then
        if self.openFolioResult then
            self:openFolioResult()
        else
            show_message(
                self,
                ACTIONS_UI.message_completed_title,
                ACTIONS_UI.message_completed_subtext
            )
        end
    elseif get_pending_ink_recovery(self) > 0 then
        local count = get_pending_ink_recovery(self)
        show_message(
            self,
            ACTIONS_UI.message_row_completed_title,
            ACTIONS_UI.message_row_completed_subtext_choose_ink,
            1.8,
            nil,
            {count = count}
        )
    elseif opts and opts.auto then
        show_message(
            self,
            ACTIONS_UI.message_wet_buffer_full_title,
            ACTIONS_UI.message_wet_buffer_full_subtext_auto_commit,
            1.8
        )
    elseif commit_result and commit_result.still_wet and commit_result.still_wet > 0 then
        show_message(
            self,
            ACTIONS_UI.message_humid_parchment_title,
            ACTIONS_UI.message_humid_parchment_subtext_die_remains_wet,
            2.0,
            nil,
            {count = tostring(commit_result.still_wet)}
        )
    elseif commit_result and commit_result.stains_added and commit_result.stains_added > 0 then
        show_message(
            self,
            ACTIONS_UI.message_ink_still_wet_title,
            ACTIONS_UI.message_ink_still_wet_subtext_stains_from_risk,
            2.0,
            nil,
            {count = tostring(commit_result.stains_added)}
        )
    end
    if self.persistRunSnapshot then
        self:persistRunSnapshot("commit")
    end
    self.state = "waiting"
    return commit_result
end

function Actions.performRestart(self)
    AudioManager.play_ui(SFX_TOGGLE)
    local params = self.start_params or {}
    self:enter({
        folio_set = params.folio_set or (self.run and self.run.folio_set) or "BIFOLIO",
        campaign_id = params.campaign_id or (self.run and self.run.campaign_id),
        seed = os.time(),
    })
end

function Actions.consumeUnusableDie(self)
    if not self.dice_results then
        return nil
    end
    for _, die in ipairs(self.dice_results) do
        if die and die.unusable and not die.burned and not die.used then
            die.burned = true
            die.used = true
            return die
        end
    end
    return nil
end

function Actions.performPreparation(self, mode)
    if self.state ~= "placing" or not self.run or not self.run.current_folio then
        return
    end
    local folio = self.run.current_folio
    if not (folio.canUsePreparation and folio:canUsePreparation()) then
        return
    end
    if not self:_consumeUnusableDie() then
        return
    end
    local ok = folio:applyPreparation(mode)
    if ok then
        AudioManager.play_ui(SFX_MOVE)
    end
end

function Actions.showMessage(self, text, subtext, duration)
    self.message = {
        text = text,
        subtext = subtext,
    }
    self.message_timer = duration or 2.2
end

function Actions.getInstructions(self)
    if self.show_run_setup then
        local folio = self.run and self.run.current_folio or nil
        local required_guided = get_required_guided_rows(folio)
        return tr(ACTIONS_UI.instruction_setup_guided, {
            count = required_guided,
        })
    end
    if self.message then
        return tr(ACTIONS_UI.instruction_close_message)
    end
    if self.state == "stain_pick" then
        return tr(ACTIONS_UI.instruction_stain_pick)
    end
    local pending_recovery = get_pending_ink_recovery(self)
    if pending_recovery > 0 then
        return tr(ACTIONS_UI.instruction_ink_recovery, {
            count = pending_recovery,
        })
    end
    if self.state == "waiting" then
        if self.pending_row_swap then
            return tr(ACTIONS_UI.instruction_ruling_select_close)
        end
        if self.ruling_actions_left and self.ruling_actions_left > 0 then
            return tr(ACTIONS_UI.instruction_ruling_adjust)
        end
        if not self.dice_results or #self.dice_results == 0 then
            return tr(ACTIONS_UI.instruction_waiting_roll_start)
        end
        return tr(ACTIONS_UI.instruction_waiting_review)
    end
    if self.state == "rolling" then
        return tr(ACTIONS_UI.instruction_rolling)
    end
    if self.state == "placing" then
        local folio = self.run and self.run.current_folio
        if folio then
            local wet_count = folio.getWetCount and folio:getWetCount() or 0
            local wet_max = get_wet_buffer_max(folio)
            if wet_count >= wet_max then
                return tr(ACTIONS_UI.instruction_wet_buffer_full)
            end
        end
        local die = self:getSelectedDie()
        if folio and (not die) and self.dice_results and #self.dice_results > 0 then
            return tr(ACTIONS_UI.instruction_select_die)
        end
        return tr(ACTIONS_UI.instruction_place_reroll_commit)
    end
    return tr(ACTIONS_UI.instruction_mouse_only)
end

return Actions



