-- The menu theme should sit well behind Farkle/physical dice effects.
-- Test against the AudioManager itself without requiring a real audio device.
local previous_love=love
local saved_settings=package.loaded["src.core.runtime_state"]
local saved_audio=package.loaded["src.core.audio_manager"]
package.loaded["src.core.runtime_state"]={settings={
    get=function() return {audio={
        master_volume=.8,music_volume=.6,sfx_volume=.7,
        mute_music=false,mute_sfx=false,
    }} end,
}}
package.loaded["src.core.audio_manager"]=nil
local master_calls={}
love={audio={setVolume=function(value) master_calls[#master_calls+1]=value end}}
local A=require("src.core.audio_manager")
local schema=require('src.data.frontend_schema').menu
local mul=schema.flow.main_theme_mix_gain
assert(mul>0 and mul<=.3, "Menu theme must have a quieter per-track mix level")
assert(schema.assets.music_path=="resources/sounds/maintitle.ogg")
local source={volume=-1}
function source:setVolume(v) self.volume=v end
A.apply_audio_settings({
    master_volume=.8,music_volume=.6,sfx_volume=.7,
    mute_music=false,mute_sfx=false,
})
A.register_music_source(schema.flow.music_track_id,source,{volume_mul=mul})
local function near(a,b) return math.abs(a-b)<1e-9 end
assert(near(source.volume,.6*mul), "Music source must use Music slider x menu mix trim")
assert(near(master_calls[#master_calls],.8), "Master volume is not changed by theme trim")
A.apply_audio_settings({
    master_volume=.8,music_volume=.1,sfx_volume=.7,
    mute_music=false,mute_sfx=false,
})
assert(near(source.volume,.1*mul), "Music slider must continue controlling theme")
A.apply_audio_settings({
    master_volume=.8,music_volume=.6,sfx_volume=.7,
    mute_music=true,mute_sfx=false,
})
assert(source.volume==0,"Music mute must silence main theme")
A.unregister_music_source(schema.flow.music_track_id)
A.apply_audio_settings({
    master_volume=.8,music_volume=.6,sfx_volume=.7,
    mute_music=false,mute_sfx=false,
})
assert(source.volume==0,"Unregistered menu theme must remain untouched")
local file=assert(io.open("src/screens/frontend.lua","rb"))
local menu_source=file:read("*a");file:close()
assert(menu_source:find("volume_mul = MAIN_THEME_MIX_GAIN",1,true),
    "Menu must register per-track mix attenuation")
assert(menu_source:find("music:pause()",1,true) and
       menu_source:find("unregister_music_source(MUSIC_TRACK_ID)",1,true),
    "Theme must be paused and unregistered when leaving the menu")
assert(not menu_source:find("music:setVolume(get_menu_music_volume())",1,true),
    "Menu must not start playback at untrimmed Music slider volume")
love=previous_love
package.loaded["src.core.runtime_state"]=saved_settings
package.loaded["src.core.audio_manager"]=saved_audio
print("PASS maintitle.ogg attenuation, Music/Master controls, mute and menu exit policy")
