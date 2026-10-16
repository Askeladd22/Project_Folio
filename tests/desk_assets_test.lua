local Config = require("src.data.scriptorium_module_config")
local View = require("src.features.scriptorium.desk_view")
local loads,draws,fallbacks = 0,0,0
-- Only the LOVE image boundary is substituted; exercise the real layer loader.
love = {
    filesystem = {getInfo=function(path) return path~="missing.png" and {type="file"} or nil end},
    graphics = {
        newImage=function(path)
            loads=loads+1
            if path=="broken.png" then error("invalid PNG") end
            return {getWidth=function() return 200 end,getHeight=function() return 100 end,
                setFilter=function(a,min,mag) assert(min=="linear" and mag=="linear") end}
        end,
        push=function(mode) assert(mode=="all") end,
        pop=function() end,
        setBlendMode=function(mode,alpha) assert(mode=="alpha" and alpha=="alphamultiply") end,
        setColor=function() end,
        draw=function(_,x,y,rotation,sx,sy)
            assert(x==10 and y==20 and rotation==0 and sx==2 and sy==3,"layer target scaling changed")
            draws=draws+1
        end,
    },
}
Config.desk_assets={background="valid.png",desk="missing.png",lectern="broken.png",parchment="valid.png"}
local function fallback() fallbacks=fallbacks+1 end
local r={x=10,y=20,w=400,h=300}
assert(View.draw_layer("background",r,fallback))
assert(not View.draw_layer("desk",r,fallback))
assert(not View.draw_layer("lectern",r,fallback))
assert(View.draw_layer("parchment",r,fallback),"one missing layer disabled other PNGs")
assert(loads==2 and draws==2 and fallbacks==2,"independent fallback failed")
assert(not View.draw_layer("lectern",r,fallback))
assert(loads==2,"broken asset is retried every frame")
View.reload_assets()
assert(View.draw_layer("background",r,fallback) and loads==3,"asset reload failed")
print("ok - independent PNG loading, target scaling, caching and missing/corrupt fallback")
