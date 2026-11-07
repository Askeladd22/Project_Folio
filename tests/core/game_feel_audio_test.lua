local A=require('src.core.audio_manager')
assert(type(A.play_farkle)=='function','semantic Farkle audio missing')
local played,created=0,0
love={sound={newSoundData=function() return {setSample=function() end} end},audio={
 setVolume=function() end,newSource=function()
 created=created+1
 local s={setVolume=function() end,setPitch=function() end,play=function() played=played+1 end}
 s.clone=function() return s end;return s
end}}
A.apply_audio_settings({master_volume=1,sfx_volume=.5,mute_sfx=false})
for _,name in ipairs({'take','bank','loss','hot','medal'}) do assert(A.play_farkle(name)) end
assert(played==5);local n=created
assert(A.play_farkle('take'));assert(created==n,'no rebuilding sound on each event')
A.apply_audio_settings({mute_sfx=true});assert(not A.play_farkle('bank'));assert(played==6)
assert(not A.play_farkle('unknown'))
print('PASS semantic cues cached, one playback per event, mute and unknown event')
