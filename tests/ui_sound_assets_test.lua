-- Supplied UI WAVs route through SFX volume, cloning and mute.
local saved_love=love
local saved_settings=package.loaded['src.core.settings_state']
local saved_audio=package.loaded['src.core.audio_manager']
package.loaded['src.core.settings_state']={get=function()
 return {audio={master_volume=.8,sfx_volume=.5,mute_sfx=false}}
end}
package.loaded['src.core.audio_manager']=nil
local loaded,played={},{}
local function base(path)
 return {path=path,clone=function(self)
  local voice={path=self.path}
  function voice:setVolume(v) self.volume=v end
  function voice:setPitch(v) self.pitch=v end
  function voice:play() played[#played+1]=self end
  return voice
 end}
end
love={audio={newSource=function(path,kind)
 assert(kind=='static')
 loaded[#loaded+1]=path
 return base(path)
end}}
local A=require('src.core.audio_manager')
assert(A.play_ui('confirm'))
assert(A.play_ui('hover'))
assert(A.play_ui('menu_open'))
assert(A.play_ui('menu_close'))
assert(#loaded==4 and #played==4,'each UI WAV loads once and plays')
local paths={}
for _,path in ipairs(loaded) do paths[path]=true end
for _,path in ipairs({
 'resources/sounds/ButtonClick.wav',
 'resources/sounds/ButtonHover.wav',
 'resources/sounds/Menu ScrollMenuOpen .wav',
 'resources/sounds/Menu ScrollMenuClose .wav',
}) do assert(paths[path],'missing mapped UI sample '..path) end
local volumes={}
for _,voice in ipairs(played) do volumes[voice.path]=voice.volume end
assert(math.abs(volumes['resources/sounds/ButtonClick.wav']-.45)<1e-9)
assert(math.abs(volumes['resources/sounds/ButtonHover.wav']-.325)<1e-9)
assert(math.abs(volumes['resources/sounds/Menu ScrollMenuOpen .wav']-.34)<1e-9)
assert(math.abs(volumes['resources/sounds/Menu ScrollMenuClose .wav']-.31)<1e-9)
A.apply_audio_settings({master_volume=.8,sfx_volume=.5,mute_sfx=true})
assert(not A.play_ui('confirm') and #played==4,'SFX mute must silence UI samples')
love=saved_love
package.loaded['src.core.settings_state']=saved_settings
package.loaded['src.core.audio_manager']=saved_audio
print('PASS UI WAV mapping, relative mix, one-time loading and SFX mute')
