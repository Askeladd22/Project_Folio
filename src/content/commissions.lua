local I18n = require("src.core.i18n")
local CommissionData = require("src.data.commissions")

local Commissions = {}

local function tr(key, fallback, params)
    return I18n.t(key, fallback, params)
end

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

local function localize_folio(folio)
    local out = deep_copy(folio or {})
    if type(out.pattern_name_key) == "string" then
        out.pattern_name = tr(out.pattern_name_key, out.pattern_name_default or out.pattern_name)
    end
    out.pattern_name_key = nil
    out.pattern_name_default = nil
    return out
end

local function localize_commission(commission)
    local out = deep_copy(commission or {})
    out.title = tr(out.title_key, out.title_default or out.title or out.id)
    out.subtitle = tr(out.subtitle_key, out.subtitle_default or out.subtitle or "")

    local localized_folios = {}
    for i, folio in ipairs(out.folios or {}) do
        localized_folios[i] = localize_folio(folio)
    end
    out.folios = localized_folios

    out.title_key = nil
    out.title_default = nil
    out.subtitle_key = nil
    out.subtitle_default = nil

    return out
end

local function get_commission_list()
    if type(CommissionData) ~= "table" or type(CommissionData.list) ~= "table" then
        return {}
    end
    return CommissionData.list
end

function Commissions.getAll()
    local source = get_commission_list()
    local out = {}
    for i, commission in ipairs(source) do
        out[i] = localize_commission(commission)
    end
    return out
end

function Commissions.getById(id)
    local target = tostring(id or "")
    for _, commission in ipairs(get_commission_list()) do
        if commission.id == target then
            return localize_commission(commission)
        end
    end
    return nil
end

function Commissions.getDefaultId()
    local source = get_commission_list()
    local preferred = type(CommissionData) == "table" and CommissionData.default_id or nil

    if type(preferred) == "string" and preferred ~= "" then
        for _, commission in ipairs(source) do
            if commission.id == preferred then
                return preferred
            end
        end
    end

    return source[1] and source[1].id or "commission_mvp"
end

return Commissions
