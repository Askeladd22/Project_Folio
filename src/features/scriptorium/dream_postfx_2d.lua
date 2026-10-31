-- Opt-in vignette restricted to 2D drawing passes.
-- Do not wrap g3d dice or the playable tray: Moonshine changes the Canvas.
local M={}
local FX={}
FX.__index=FX

function M.new()
 local Moonshine=require('lib.moonshine')
 local effect=Moonshine(Moonshine.effects.vignette)
 effect.vignette.opacity=.16
 effect.vignette.radius=.9
 effect.vignette.softness=.42
 return setmetatable({effect=effect,enabled=false},FX)
end

function FX:resize(width,height)
 if self.effect then self.effect.resize(width,height) end
end

function FX:draw(draw2d)
 assert(type(draw2d)=='function','2D draw callback required')
 if self.enabled then return self.effect(draw2d) end
 return draw2d()
end

return M
