
local SettingsState = require('src.core.runtime_state').settings

local AudioManager = {}

local ImpactGate = {}
ImpactGate.__index = ImpactGate

local impact_min_speed = {floor = 1.3, rim = 1.5, pair = 1.1}
local impact_min_interval = {floor = 0.085, rim = 0.095, pair = 0.07}

function ImpactGate.new()
    return setmetatable({last = {}}, ImpactGate)
end

function ImpactGate:accept(kind, index, other, speed, time)
    local threshold = impact_min_speed[kind]
    if not threshold or type(index) ~= "number" or
        type(speed) ~= "number" or speed ~= speed or
        type(time) ~= "number" or time ~= time or
        speed < threshold then
        return nil
    end
    local key
    if kind == "pair" then
        if type(other) ~= "number" or other == index then return nil end
        local lo, hi = math.min(index, other), math.max(index, other)
        key = "pair:" .. lo .. ":" .. hi
    else
        key = kind .. ":" .. index
    end
    local last = self.last[key]
    if last and time - last < impact_min_interval[kind] then return nil end
    self.last[key] = time
    return math.min(1, math.max(0.15, (speed - threshold) / 7))
end

function AudioManager.new_impact_gate()
    return ImpactGate.new()
end

local sources = {}
local music_sources = {}
local runtime_audio_override = nil
local sources_ready = false

local ui_sample_paths={
    click='resources/sounds/ButtonClick.wav',
    hover='resources/sounds/ButtonHover.wav',
    menu_open='resources/sounds/Menu ScrollMenuOpen .wav',
    menu_close='resources/sounds/Menu ScrollMenuClose .wav',
}

local function clamp(v, min_v, max_v)
    if v < min_v then return min_v end
    if v > max_v then return max_v end
    return v
end

local function get_persisted_audio_settings()
    local state = SettingsState.get()
    return state and state.audio or nil
end

local function get_audio_settings()
    if type(runtime_audio_override) == "table" then
        return runtime_audio_override
    end
    return get_persisted_audio_settings()
end

local function get_sfx_gain()
    local audio = get_audio_settings()
    if not audio then return 1 end
    if audio.mute_sfx then return 0 end
    return clamp(tonumber(audio.sfx_volume) or 1, 0, 1)
end

local function get_master_gain(audio)
    if type(audio) ~= "table" then
        return 1
    end
    return clamp(tonumber(audio.master_volume) or 1, 0, 1)
end

local function get_music_gain(audio)
    if type(audio) ~= "table" then
        return 0.6
    end
    if audio.mute_music then
        return 0
    end
    return clamp(tonumber(audio.music_volume) or 0.6, 0, 1)
end

local function is_valid_source(src)
    return src and type(src.setVolume) == "function"
end

local function make_tone(freq, duration, amp)
    if not (love and love.sound and love.sound.newSoundData and love.audio and love.audio.newSource) then
        return nil
    end

    local sample_rate = 44100
    local samples = math.max(1, math.floor(sample_rate * duration))
    local data = love.sound.newSoundData(samples, sample_rate, 16, 1)
    local two_pi = math.pi * 2
    amp = amp or 0.3

    for i = 0, samples - 1 do
        local t = i / sample_rate
        local envelope = 1 - (i / samples)
        local sample = math.sin(two_pi * freq * t) * amp * envelope
        data:setSample(i, sample)
    end

    return love.audio.newSource(data, "static")
end

local function load_static(path)
    if not (love and love.audio and love.audio.newSource) then return nil end
    local ok, source = pcall(love.audio.newSource, path, "static")
    return ok and source or nil
end

local function ensure_sources()
    if sources_ready then return end
    if not (love and love.audio and love.audio.newSource) then return end
    sources_ready = true
    sources.ui_move = make_tone(760, 0.03, 0.20)
    local click = load_static(ui_sample_paths.click)
    sources.ui_hover = load_static(ui_sample_paths.hover) or make_tone(920, 0.02, 0.14)
    sources.ui_toggle = click or make_tone(640, 0.04, 0.22)
    sources.ui_confirm = click or make_tone(1180, 0.05, 0.26)
    sources.ui_back = click or make_tone(520, 0.05, 0.24)
    sources.ui_menu_open = load_static(ui_sample_paths.menu_open)
    sources.ui_menu_close = load_static(ui_sample_paths.menu_close)
end

function AudioManager.play(name, opts)
    ensure_sources()
    local base = sources[name]
    if not base then return false end

    local gain = get_sfx_gain()
    if gain <= 0 then return false end

    local src = base:clone()
    local volume_mul = opts and opts.volume_mul or 1
    local pitch = opts and opts.pitch or 1
    src:setVolume(clamp(gain * volume_mul, 0, 1))
    src:setPitch(pitch)
    src:play()
    return true
end

function AudioManager.play_ui(event_name)
    if event_name == "move" then
        return AudioManager.play("ui_move", {volume_mul = 0.85})
    elseif event_name == "hover" then
        return AudioManager.play("ui_hover", {volume_mul = 0.65})
    elseif event_name == "toggle" then
        return AudioManager.play("ui_toggle", {volume_mul = 0.80, pitch = 0.96})
    elseif event_name == "confirm" then
        return AudioManager.play("ui_confirm", {volume_mul = 0.9})
    elseif event_name == "back" then
        return AudioManager.play("ui_back", {volume_mul = 0.78, pitch = 0.92})
    elseif event_name == "menu_open" then
        return AudioManager.play("ui_menu_open", {volume_mul = 0.68})
    elseif event_name == "menu_close" then
        return AudioManager.play("ui_menu_close", {volume_mul = 0.62})
    end
    return false
end

-- Original damped resonances: dry wood and a restrained metal overtone.
-- Deterministic synthesis never consumes either gameplay random generator.
local cue_specs={take={190,.13,.20},bank={360,.24,.19},loss={120,.18,.16},hot={480,.27,.19},medal={640,.20,.14}}
local function make_material_cue(spec)
    if not (love and love.sound and love.sound.newSoundData and love.audio and love.audio.newSource) then return nil end
    local rate=44100;local n=math.floor(rate*spec[2])
    local data=love.sound.newSoundData(n,rate,16,1)
    for i=0,n-1 do
        local t=i/rate;local attack=math.min(1,t/.003)
        local envelope=attack*math.exp(-t*28)*(1-i/n)
        local f=spec[1]*math.pi*2
        local sample=(math.sin(f*t)+.35*math.sin(f*2.71*t)+.13*math.sin(f*5.13*t))*spec[3]*envelope
        data:setSample(i,sample)
    end
    return love.audio.newSource(data,'static')
end
function AudioManager.play_farkle(event)
    local spec=cue_specs[event];if not spec then return false end
    local key='farkle_'..event
    if not sources[key] then sources[key]=make_material_cue(spec) end
    return AudioManager.play(key)
end


-- Physical dice recordings shipped with Project Folio. These are ordinary
-- SFX and obey the same persisted master/SFX volume and mute settings.
-- The round-robin variant cursor deliberately never consumes gameplay RNG.
local dice_sample_paths = {
    grab = {
        "resources/sounds/dice-grab-1.ogg",
        "resources/sounds/dice-grab-2.ogg",
    },
    shake = {
        "resources/sounds/dice-shake-1.ogg",
        "resources/sounds/dice-shake-2.ogg",
        "resources/sounds/dice-shake-3.ogg",
    },
    throw_group = {
        "resources/sounds/dice-throw-1.ogg",
        "resources/sounds/dice-throw-2.ogg",
        "resources/sounds/dice-throw-3.ogg",
    },
    throw_single = {
        "resources/sounds/die-throw-1.ogg",
        "resources/sounds/die-throw-2.ogg",
        "resources/sounds/die-throw-3.ogg",
        "resources/sounds/die-throw-4.ogg",
    },
}
local dice_variant_cursor = {}
-- Each entry owns a real LÖVE Source; impact clips are intentionally short
-- transients because the shipped 'throw' OGGs contain their own roll tails.
local dice_active_voices = {}
local DICE_MAX_VOICES = 16

local function stop_voice(entry)
    if entry.voice and type(entry.voice.stop) == "function" then
        entry.voice:stop()
    end
end

local function prune_dice_voices()
    for i = #dice_active_voices, 1, -1 do
        local entry = dice_active_voices[i]
        if type(entry.voice.isPlaying) == "function" and
            not entry.voice:isPlaying() then
            table.remove(dice_active_voices, i)
        end
    end
end

-- Game-loop time, never wall-clock time: this also permits deterministic
-- headless checks and avoids keeping a looping or overlapping shake alive.
function AudioManager.update_dice(dt)
    if type(dt) ~= "number" or dt ~= dt or dt <= 0 then return end
    prune_dice_voices()
    for i = #dice_active_voices, 1, -1 do
        local entry = dice_active_voices[i]
        entry.age = entry.age + dt
        if entry.max_age and entry.age >= entry.max_age and
            not entry.fade_duration then
            entry.fade_duration = 0.035
            entry.fade_elapsed = 0
        end
        if entry.fade_duration then
            entry.fade_elapsed = entry.fade_elapsed + dt
            if entry.fade_elapsed >= entry.fade_duration then
                stop_voice(entry)
                table.remove(dice_active_voices, i)
            elseif type(entry.voice.setVolume) == "function" then
                entry.voice:setVolume(entry.volume *
                    (1 - entry.fade_elapsed / entry.fade_duration))
            end
        end
    end
end

function AudioManager.stop_dice(event, fade)
    local duration = tonumber(fade) or 0
    for i = #dice_active_voices, 1, -1 do
        local entry = dice_active_voices[i]
        if entry.event == event then
            if duration <= 0 then
                stop_voice(entry)
                table.remove(dice_active_voices, i)
            elseif not entry.fade_duration then
                entry.fade_duration = duration
                entry.fade_elapsed = 0
            end
        end
    end
end

function AudioManager.play_dice(event, opts)
    local count = tonumber(opts and opts.count) or 1
    local category = (event == "impact") and "throw_single" or
        (event == "throw" and
            (count > 1 and "throw_group" or "throw_single") or event)
    local paths = dice_sample_paths[category]
    if not paths or not (love and love.audio and love.audio.newSource) then
        return false
    end
    local gain = get_sfx_gain()
    if gain <= 0 then return false end

    local strength = clamp(tonumber(opts and opts.strength) or 0.7, 0, 1)
    local loudness = category == "shake" and
        0.58 * (0.65 + 0.35 * strength) or
        category == "grab" and 0.72 or 0.85
    if event == "impact" then
        -- The leading transient is aligned to an actual solver contact;
        -- no complete pre-recorded throw is triggered at mouse release.
        loudness = (opts and opts.kind == "pair" and 0.23 or 0.30)
            + 0.37 * strength
    end
    local volume = clamp(gain * loudness, 0, 1)
    prune_dice_voices()

    if event == "shake" then
        for _, entry in ipairs(dice_active_voices) do
            if entry.event == "shake" and not entry.fade_duration then
                -- Repeated reversals sustain one voice instead of layering
                -- several complete shake recordings over each other.
                entry.volume = volume
                entry.voice:setVolume(volume)
                return true
            end
        end
    end

    local index = (dice_variant_cursor[category] or 0) % #paths + 1
    local path = paths[index]
    local base = sources[path]
    if not base then
        local ok, loaded = pcall(love.audio.newSource, path, "static")
        if not ok or not loaded then return false end
        sources[path] = loaded
        base = loaded
    end
    local ok, voice = pcall(function() return base:clone() end)
    if not ok or not voice then return false end

    voice:setVolume(volume)
    if event == "impact" and type(voice.setPitch) == "function" then
        voice:setPitch(0.93 + 0.13 * strength)
    end
    local played = pcall(function() voice:play() end)
    if not played then return false end

    if #dice_active_voices >= DICE_MAX_VOICES then
        stop_voice(table.remove(dice_active_voices, 1))
    end
    dice_active_voices[#dice_active_voices + 1] = {
        voice = voice, event = event, category = category,
        volume = volume, age = 0,
        max_age = event == "impact" and 0.115 or nil,
    }
    dice_variant_cursor[category] = index
    return true
end

function AudioManager.register_music_source(id, source, opts)
    if not source then return nil end
    local key = id or tostring(source)
    music_sources[key] = {
        source = source,
        volume_mul = clamp(tonumber(opts and opts.volume_mul) or 1, 0, 2),
    }
    AudioManager.apply_audio_settings()
    return key
end

function AudioManager.unregister_music_source(id)
    if id == nil then return end
    music_sources[id] = nil
end

function AudioManager.apply_audio_settings(audio_override)
    if type(audio_override) == "table" then
        runtime_audio_override = audio_override
    else
        runtime_audio_override = nil
    end
    local audio = get_audio_settings()

    local master = get_master_gain(audio)
    local music = get_music_gain(audio)

    if love and love.audio and love.audio.setVolume then
        pcall(function()
            love.audio.setVolume(master)
        end)
    end

    for key, entry in pairs(music_sources) do
        local src = entry and entry.source or nil
        if is_valid_source(src) then
            local mul = clamp(tonumber(entry.volume_mul) or 1, 0, 2)
            pcall(function()
                src:setVolume(clamp(music * mul, 0, 1))
            end)
        else
            music_sources[key] = nil
        end
    end

end

function AudioManager.refresh_music(audio_override)
    AudioManager.apply_audio_settings(audio_override)
end

return AudioManager
