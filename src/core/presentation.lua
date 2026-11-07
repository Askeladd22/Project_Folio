local Bundle = {}
Bundle.i18n = (function()
local SettingsState = require('src.core.runtime_state').settings

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
        return require("src.data.locale_" .. bundle_id)
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
end)()
Bundle.typography = (function()
-- Project Folio typography: facsimile Aldine Aetna + readable Roman fallback.
-- Load both as TTF fonts: LÖVE's setFallbacks substitutes individual glyphs,
-- rather than replacing a whole label when one character is missing.
local M={}
M.primary='resources/font/AldineAetna-Regular.ttf'
M.support='resources/font/Cardo-Regular.ttf'
local linked=setmetatable({},{__mode='k'})

function M.load(path,size)
 assert(type(path)=='string' and path~='','font path required')
 assert(type(size)=='number' and size>0,'positive font size required')
 local font=love.graphics.newFont(path,size)
 if path==M.primary then
  local secondary=love.graphics.newFont(M.support,size)
  -- Test graphics stubs may not implement this native LÖVE method.
  -- The production Font always does (LÖVE >= 0.10).
  if font.setFallbacks then font:setFallbacks(secondary) end
  linked[font]=secondary
 end
 return font
end
return M
end)()
Bundle.version = (function()
-- Single canonical Project Folio version from the repository's version.txt.
-- This is a pure module; normal LÖVE uses the mounted game filesystem.
local M={}
local current
function M.parse(value)
 if type(value)~='string' then return nil end
 local candidate=value:match('^%s*(.-)%s*$')
 local major,minor,patch,rest=candidate:match('^(%d+)%.(%d+)%.(%d+)(.*)$')
 if not major then return nil end
 if rest~='' and not rest:match('^%-[%w%.%-]+$') then return nil end
 if major:match('^0%d') or minor:match('^0%d') or patch:match('^0%d') then return nil end
 return candidate
end
function M.current()
 if current then return current end
 local content
 if love and love.filesystem and love.filesystem.read then
  content=love.filesystem.read('version.txt')
 else
  local file=assert(io.open('version.txt','rb'),'Missing Project Folio version.txt')
  content=file:read('*a')
  file:close()
 end
 current=assert(M.parse(content),'Invalid/missing Project Folio version.txt')
 return current
end
return M
end)()
Bundle.menu_visuals = (function()
-- Shared frontend backgrounds and ambient effects.
-- Rendering helpers only; no text, input or layout changes.
-- A missing/corrupt optional PNG can never make a menu fail to start.
local M = {}
local Art = require('src.data.frontend_schema').palette
local CORE = Art.rgb("paper")
local HALO = Art.rgb("paper_mid")
function M.load(preferred, fallback, legacy)
    if not love or not love.filesystem or not love.graphics then
        return nil, nil
    end
    local getInfo = love.filesystem.getInfo
    local newImage = love.graphics.newImage
    if type(getInfo) ~= 'function' or type(newImage) ~= 'function' then
        return nil, nil
    end
    local seen = {}
    for _,path in ipairs({preferred, fallback, legacy}) do
        if type(path) == 'string' and path ~= '' and not seen[path] then
            seen[path] = true
            local exists, info = pcall(getInfo, path)
            if exists and info then
                local ok, image = pcall(newImage, path)
                if ok and image then return image, path end
            end
        end
    end
    return nil, nil
end
-- Keep the authored illustration's blank left margin visible when
-- covering non-widescreen windows. Legacy backgrounds stay centered.
function M.cover_rect(image,w,h,keep_left)
    if not image or w<=0 or h<=0 then return nil end
    local bw,bh=image:getWidth(),image:getHeight()
    if bw<=0 or bh<=0 then return nil end
    local scale=math.max(w/bw,h/bh)
    local dw,dh=bw*scale,bh*scale
    local x=(w-dw)*.5
    if keep_left and dw>w then x=0 end
    return x,(h-dh)*.5,scale
end

-- Reserve the leftmost ~32.5% of the illustrated print shop as quiet
-- space for the parchment navigation. Keep press, workers and typecases
-- visible without disturbing the layout or mouse hitboxes.
function M.left_panel_limit(image,w,h,left)
    if not image then return nil end
    local x,_,scale=M.cover_rect(image,w,h,true)
    if not x then return nil end
    local safe_right=x+image:getWidth()*.325*scale
    local gap=math.max(10,h*.016)
    return math.max(0,math.floor(safe_right-left-gap))
end

function M.create_default(count)
    local total = math.max(1, tonumber(count) or 34)
    local particles = {}
    for i = 1, total do
        particles[i] = {
            x = 0.02 + 0.96 * (((i * 37) % 100) / 100),
            y = 0.02 + 0.96 * (((i * 53 + 17) % 100) / 100),
            drift = 0.0018 + ((i - 1) % 6) * 0.00045,
            sway = 0.0012 + ((i - 1) % 5) * 0.00045,
            phase = (i - 1) * 0.73,
            speed = 0.16 + ((i - 1) % 7) * 0.035,
            size = 0.52 + ((i - 1) % 4) * 0.20,
            depth = 0.70 + ((i - 1) % 5) * 0.09,
        }
    end
    return particles
end

function M.update(particles, dt, reduced_animations)
    if reduced_animations then
        return
    end
    for _, particle in ipairs(particles or {}) do
        particle.phase = particle.phase + dt * particle.speed
        particle.y = particle.y - dt * particle.drift * particle.depth
        if particle.y < -0.03 then
            particle.y = 1.02
        end
    end
end

function M.draw(particles, width, height, ui_scale, high_contrast, alpha_mul)
    local scale = tonumber(ui_scale) or 1
    local alpha_scale = tonumber(alpha_mul) or 1
    for _, particle in ipairs(particles or {}) do
        local px = (particle.x + math.sin(particle.phase * (0.8 + particle.depth * 0.2)) * particle.sway) * width
        local py = (particle.y + math.cos(particle.phase * 0.55) * particle.sway * 0.8) * height
        local twinkle = 0.5 + 0.5 * math.sin(particle.phase * 1.6 + particle.depth)
        local alpha = (0.10 + 0.12 * twinkle) * (high_contrast and 1.15 or 1.0) * alpha_scale
        local core_radius = math.max(0.45, particle.size * scale * 0.90)
        local halo_radius = core_radius * 2.3

        love.graphics.setColor(CORE[1], CORE[2], CORE[3], alpha)
        love.graphics.circle("fill", px, py, core_radius)
        love.graphics.setColor(HALO[1], HALO[2], HALO[3], alpha * 0.42)
        love.graphics.circle("fill", px, py, halo_radius)
    end
end

return M
end)()
return Bundle
