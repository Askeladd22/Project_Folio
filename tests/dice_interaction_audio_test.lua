-- Headless LÖVE audio: playback is tied to physical contacts, not
-- simulated mouse releases. Neither variation nor fading uses gameplay RNG.
local old_love = love
local old_settings = package.loaded["src.core.settings_state"]
local old_audio = package.loaded["src.core.audio_manager"]
package.loaded["src.core.settings_state"] = {
    get = function()
        return {audio = {sfx_volume = 1, master_volume = 1, mute_sfx = false}}
    end
}
package.loaded["src.core.audio_manager"] = nil

local loaded, played, stopped, voices = {}, {}, 0, {}
local function new_voice(path)
    local v = {path = path, playing = false, volume = 0}
    function v:setVolume(value) self.volume = value end
    function v:setPitch(value) self.pitch = value end
    function v:play()
        self.playing = true
        played[#played + 1] = self.path
    end
    function v:isPlaying() return self.playing end
    function v:stop()
        self.playing = false
        stopped = stopped + 1
    end
    voices[#voices + 1] = v
    return v
end
love = {
    audio = {
        newSource = function(path, kind)
            assert(kind == "static" and path:match("^resources/sounds/"))
            loaded[#loaded + 1] = path
            return {clone = function() return new_voice(path) end}
        end,
        setVolume = function() end,
    },
}

local A = require("src.core.audio_manager")
A.apply_audio_settings({master_volume = 0.8, sfx_volume = 0.5, mute_sfx = false})
local old_random = math.random
math.random = function() error("Dice audio must not consume Farkle RNG") end

assert(A.play_dice("grab", {count = 6}))
assert(A.play_dice("grab", {count = 1}))
assert(played[1]:match("dice%-grab%-1%.ogg$"))
assert(played[2]:match("dice%-grab%-2%.ogg$"))

assert(A.play_dice("shake", {strength = 1}))
local first_shake = voices[#voices]
local first_volume = first_shake.volume
local before = #played
assert(A.play_dice("shake", {strength = 0.4}))
assert(#played == before, "Repeated shake must sustain one voice")
assert(first_shake.volume < first_volume, "Shake strength should change gain")
A.stop_dice("shake", 0.04)
A.update_dice(0.02)
assert(first_shake.volume < first_volume, "Shake fades before stopping")
A.update_dice(0.03)
assert(not first_shake:isPlaying() and stopped >= 1,
    "Idle or release must terminate the held shake")
assert(A.play_dice("shake", {strength = 0.9}))
assert(#played == before + 1, "New gesture may start a new shake sample")
A.stop_dice("shake", 0)

local count = #played
assert(A.play_dice("impact", {kind = "floor", strength = 1}))
local impact = voices[#voices]
assert(#played == count + 1 and played[#played]:match("die%-throw%-%d%.ogg$"))
assert(impact.pitch and impact.pitch > 1, "Impact intensity should affect pitch")
A.update_dice(0.12)
A.update_dice(0.04)
assert(not impact:isPlaying(), "Impact tail must be trimmed after contact")
assert(A.play_dice("impact", {kind = "pair", strength = 0.25}))
local pair = voices[#voices]
assert(pair.volume < impact.volume, "Small impacts must be quieter")
A.update_dice(0.2)
assert(not pair:isPlaying())

-- Keep diagnostic legacy samples loadable; production never plays a full
-- recorded throw on button press or mouse release.
for _ = 1, 4 do assert(A.play_dice("throw", {count = 1})) end
for _ = 1, 3 do assert(A.play_dice("throw", {count = 6})) end
assert(#loaded == 2 + 2 + 4 + 3,
    "Variant prototypes are loaded lazily and reused")

for _ = 1, 25 do assert(A.play_dice("grab", {count = 6})) end
assert(stopped > 2, "Dice SFX voice pool must stay bounded")
local before_mute = #played
A.apply_audio_settings({mute_sfx = true})
assert(not A.play_dice("shake", {strength = 1}))
assert(not A.play_dice("impact", {strength = 1}))
assert(#played == before_mute and not A.play_dice("unknown"))

math.random = old_random
love = old_love
package.loaded["src.core.settings_state"] = old_settings
package.loaded["src.core.audio_manager"] = old_audio
print("PASS dice audio: single held shake, idle fade, contact transients, mix, cap and RNG isolation")
