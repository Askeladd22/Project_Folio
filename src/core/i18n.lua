local SettingsState = require("src.core.settings_state")

local I18n = {}

local loaded_bundles = {}
local active_language = nil
local active_bundle = nil

local LANGUAGE_TO_BUNDLE = {
    English = "en",
}

local function resolve_language()
    local state = SettingsState.get()
    local lang = state and state.game and state.game.language or "English"
    if type(lang) ~= "string" or lang == "" then
        return "English"
    end
    if LANGUAGE_TO_BUNDLE[lang] then
        return lang
    end
    return "English"
end

local function load_bundle(language)
    local bundle_id = LANGUAGE_TO_BUNDLE[language] or "en"
    if loaded_bundles[bundle_id] then
        return loaded_bundles[bundle_id]
    end
    local ok, bundle = pcall(function()
        return require("src.data.localization." .. bundle_id)
    end)
    if not ok or type(bundle) ~= "table" then
        bundle = {}
    end
    loaded_bundles[bundle_id] = bundle
    return bundle
end

function I18n.get_language()
    return resolve_language()
end

function I18n.t(key, fallback, params)
    local language = resolve_language()
    if active_language ~= language then
        active_language = language
        active_bundle = load_bundle(language)
    elseif not active_bundle then
        active_bundle = load_bundle(language)
    end

    local value = nil
    if type(active_bundle) == "table" then
        value = active_bundle[key]
    end
    if type(value) ~= "string" then
        value = fallback or key
    end

    if type(params) == "table" then
        for token, replacement in pairs(params) do
            value = value:gsub("{" .. tostring(token) .. "}", tostring(replacement))
        end
    end
    return value
end

return I18n
