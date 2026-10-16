local FolioTurn = {}
local FolioTurnReasons = require("src.data.folio_turn_reasons")

local function reset_turn_flags(self)
    self.turn_risk = 0
    self.turn_pushes = 0
    self.turn_flags = {}
    self.last_push_mode = nil
end

local function to_non_negative_int(value, fallback)
    local n = tonumber(value)
    if n == nil then
        n = fallback or 0
    end
    n = math.floor(n)
    if n < 0 then
        return 0
    end
    return n
end

local function normalize_tool_id(id)
    if type(id) ~= "string" then
        return nil
    end
    local key = id:lower()
    if key == "" then
        return nil
    end
    return key
end

function FolioTurn.registerPush(self, push_mode)
    local reroll_max = tonumber(self.reroll_max)
    if reroll_max ~= nil then
        reroll_max = math.max(0, math.floor(reroll_max))
        if (self.turn_pushes or 0) >= reroll_max then
            return false, FolioTurnReasons.reroll_limit_reached
        end
    end
    self.turn_pushes = (self.turn_pushes or 0) + 1
    self.last_push_mode = tostring(push_mode or "all")
    return true
end

function FolioTurn.getWetCount(self)
    return #(self.wet_buffer or {})
end

function FolioTurn.getTurnRisk(self)
    return self.turn_risk or 0
end

function FolioTurn.getPreparationGuard(self)
    return to_non_negative_int(self.preparation_guard, 0)
end

function FolioTurn.canUsePreparation(self)
    if not self.preparation_enabled then
        return false
    end
    self.turn_flags = self.turn_flags or {}
    return not self.turn_flags.preparation_used
end

function FolioTurn.applyPreparation(self, mode)
    if not self:canUsePreparation() then
        return false, FolioTurnReasons.preparation_disabled_in_mvp
    end
    local key = tostring(mode or "")
    if key == "guard" then
        self.preparation_guard = self:getPreparationGuard() + 1
    elseif key == "risk" then
        self.turn_risk = math.max(0, to_non_negative_int(self.turn_risk, 0) - 1)
    else
        return false, FolioTurnReasons.invalid_preparation_mode
    end
    self.turn_flags.preparation_used = true
    return true
end

function FolioTurn.getRuleCards(self)
    return self.rule_cards or {}
end

function FolioTurn.getRuleEffects(self)
    return self.rule_effects or {}
end

function FolioTurn.getToolUsesLeft(self)
    return to_non_negative_int(self.tool_uses_left, 0)
end

function FolioTurn.getSeals(self)
    return to_non_negative_int(self.seals, 0)
end

function FolioTurn.canSpendSeal(self)
    return self:getSeals() > 0
end

function FolioTurn.spendSeal(self)
    if not self:canSpendSeal() then
        return false
    end
    self.seals = self:getSeals() - 1
    return true
end

function FolioTurn.canUseTool(self, id)
    local tool_id = normalize_tool_id(id)
    if tool_id ~= "knife" then
        return false
    end
    return self:getToolUsesLeft() > 0
end

function FolioTurn.consumeToolUse(self, id)
    if not self:canUseTool(id) then
        return false
    end
    self.tool_uses_left = self:getToolUsesLeft() - 1
    return true
end

function FolioTurn.getWetSummary(self)
    local counts = {}
    for _, element in ipairs(self.ELEMENTS or {}) do
        counts[element] = 0
    end
    for _, entry in ipairs(self.wet_buffer or {}) do
        if entry and entry.element then
            counts[entry.element] = (counts[entry.element] or 0) + 1
        end
    end
    return {
        count = #(self.wet_buffer or {}),
        risk = self.turn_risk or 0,
        pushes = self.turn_pushes or 0,
        last_push_mode = self.last_push_mode,
        section_counts = counts,
    }
end

function FolioTurn.hasWetPair(self)
    local seen = {}
    for _, entry in ipairs(self.wet_buffer or {}) do
        local key = tostring(entry and entry.value) .. ":" .. tostring(entry and entry.color)
        if seen[key] then
            return true
        end
        seen[key] = true
    end
    return false
end

function FolioTurn.tryAwardDoubleSeal(self)
    self.turn_flags = self.turn_flags or {}
    if self.turn_flags.double_awarded then
        return false
    end
    if not self:hasWetPair() then
        return false
    end
    self.turn_flags.double_awarded = true
    self.seals = self:getSeals() + 1
    return true
end

function FolioTurn.discardWetBuffer(self)
    if not self.wet_buffer or #self.wet_buffer == 0 then
        reset_turn_flags(self)
        return 0
    end

    local discarded = 0
    for _, entry in ipairs(self.wet_buffer) do
        if entry and entry.element and entry.index then
            local elem = self.elements and self.elements[entry.element] or nil
            if elem and elem.wet and elem.wet[entry.index] then
                elem.wet[entry.index] = nil
                discarded = discarded + 1
            end
        end
    end

    self.wet_buffer = {}
    reset_turn_flags(self)
    return discarded
end

function FolioTurn.salvageWetBufferOnBust(self, _preferred_entry)
    local wet_count = self:getWetCount()
    local discarded = self:discardWetBuffer()
    local stains = math.max(1, wet_count)
    local busted = self:addStain(stains)
    self.bust_count = (self.bust_count or 0) + 1
    self.quality = self:calculateQuality()
    return {
        saved = nil,
        discarded = discarded,
        stains_added = stains,
        busted = busted,
    }
end

function FolioTurn.commitWetBuffer(self)
    if not self.wet_buffer or #self.wet_buffer == 0 then
        return {
            committed = 0,
            stains_added = 0,
            wettest_section = nil,
            still_wet = 0,
            rows_completed = {},
            ink_recovery_available = 0,
        }
    end

    local completed_before = self.getCompletedRowsMap and self:getCompletedRowsMap(self.active_element) or {}
    local now = (love and love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()
    local committed = 0
    for _, entry in ipairs(self.wet_buffer) do
        local elem = self.elements and self.elements[entry.element] or nil
        if elem and elem.wet and elem.wet[entry.index] then
            elem.wet[entry.index] = nil
            entry.wet = false
            if not elem.placed[entry.index] then
                elem.placed[entry.index] = {
                    element = entry.element,
                    row = entry.row,
                    col = entry.col,
                    index = entry.index,
                    value = entry.value,
                    color = entry.color,
                    pigment = entry.pigment,
                    wet = false,
                    committed_at = now,
                }
                elem.cells_filled = (elem.cells_filled or 0) + 1
                committed = committed + 1
            end
        end
    end

    self.wet_buffer = {}
    reset_turn_flags(self)
    if self._updateCompletionState then
        self:_updateCompletionState()
    else
        self.quality = self:calculateQuality()
    end

    local completed_after = self.getCompletedRowsMap and self:getCompletedRowsMap(self.active_element) or {}
    local rows_completed = {}
    for row, done in pairs(completed_after) do
        if done and not completed_before[row] then
            rows_completed[#rows_completed + 1] = row
        end
    end
    table.sort(rows_completed)

    return {
        committed = committed,
        stains_added = 0,
        wettest_section = self.active_element or "TEXT",
        still_wet = 0,
        rows_completed = rows_completed,
        ink_recovery_available = #rows_completed,
    }
end

function FolioTurn.removeWetPlacementAt(self, index)
    if not self.wet_buffer or #self.wet_buffer == 0 then
        return nil
    end
    local idx = math.floor(tonumber(index) or -1)
    if idx < 1 or idx > #self.wet_buffer then
        return nil
    end
    local entry = self.wet_buffer[idx]
    if not entry then
        return nil
    end
    local elem = self.elements and self.elements[entry.element] or nil
    if elem and elem.wet and entry.index then
        elem.wet[entry.index] = nil
    end
    local spent_ink = math.max(1, math.floor(tonumber(entry.ink_spent) or 1))
    if entry.color and self.recoverInk then
        self:recoverInk(entry.color, spent_ink)
    end
    table.remove(self.wet_buffer, idx)
    return entry
end

return FolioTurn
