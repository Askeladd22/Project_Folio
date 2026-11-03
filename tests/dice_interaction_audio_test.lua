-- Dice interaction samples are tested without an actual audio device.
-- LoveAudio is stubbed; gameplay RNG must never be used to pick a variant.
local old_love=love
local previous_settings=package.loaded["src.core.settings_state"]
local previous_audio=package.loaded["src.core.audio_manager"]
package.loaded["src.core.settings_state"]={
    get=function() return {audio={sfx_volume=1,master_volume=1,mute_sfx=false}} end
}
package.loaded["src.core.audio_manager"]=nil
local loaded,played,stopped,volumes={},{},0,{}
local function voice(path)
    return {
        setVolume=function(self,v) self.volume=v;volumes[#volumes+1]=v end,
        play=function(self) played[#played+1]=path end,
        isPlaying=function() return true end,
        stop=function() stopped=stopped+1 end,
    }
end
love={
    audio={
        newSource=function(path,kind)
            assert(kind=="static" and path:match("^resources/sounds/"))
            loaded[#loaded+1]=path
            return {clone=function() return voice(path) end}
        end,
        setVolume=function() end
    }
}
local A=require("src.core.audio_manager")
A.apply_audio_settings({master_volume=.8,sfx_volume=.5,mute_sfx=false})
local random=math.random
math.random=function() error("Dice sound variation consumed gameplay RNG") end
assert(A.play_dice("grab",{count=6}))
assert(A.play_dice("grab",{count=1}))
assert(played[1]:match("dice%-grab%-1%.ogg$"))
assert(played[2]:match("dice%-grab%-2%.ogg$"))
assert(A.play_dice("shake",{count=6,strength=1}))
assert(A.play_dice("shake",{count=6,strength=.4}))
assert(A.play_dice("shake",{count=1,strength=.9}))
assert(played[3]:match("dice%-shake%-1%.ogg$") and
       played[4]:match("dice%-shake%-2%.ogg$") and
       played[5]:match("dice%-shake%-3%.ogg$"))
assert(volumes[3]>volumes[4],"Harder shake should be louder")
assert(A.play_dice("throw",{count=1}))
assert(A.play_dice("throw",{count=1}))
assert(A.play_dice("throw",{count=1}))
assert(A.play_dice("throw",{count=1}))
assert(played[6]:match("die%-throw%-1%.ogg$") and
       played[9]:match("die%-throw%-4%.ogg$"))
assert(A.play_dice("throw",{count=6}))
assert(A.play_dice("throw",{count=3}))
assert(A.play_dice("throw",{count=2}))
assert(played[10]:match("dice%-throw%-1%.ogg$") and
       played[12]:match("dice%-throw%-3%.ogg$"))
assert(#loaded==12,"Exactly twelve unique OGG prototypes should be cached")
for i=1,25 do assert(A.play_dice("grab",{count=6})) end
assert(stopped>0,"Dice SFX voices must be capped at 16")
local prior=#played
A.apply_audio_settings({master_volume=.8,sfx_volume=.5,mute_sfx=true})
assert(not A.play_dice("shake",{strength=1}))
assert(#played==prior,"SFX mute must block sound playback")
assert(not A.play_dice("unknown"))
math.random=random
love=old_love
package.loaded["src.core.settings_state"]=previous_settings
package.loaded["src.core.audio_manager"]=previous_audio
print("PASS real dice OGG paths, variant rotation, mute/volume, bounded voices and RNG isolation")
