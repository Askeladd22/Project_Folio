-- Thin, lazy LÖVE-only adapter to SYSL-Text for manuscript narration.
-- This never runs in headless Farkle simulations or during module require.
local M={}
local Ink={}
Ink.__index=Ink

function M.new(message,options)
 options=options or {}
 return setmetatable({
  message=assert(message,'ink text required'),
  font=options.font,wrap=options.wrap or 480,
  speed=options.speed or .045,ink=options.color or {.19,.12,.07,1},
  box=nil,visible=false
 },Ink)
end

function Ink:ensure()
 if self.box then return end
 local Text=require('lib.sysl_text')
 self.box=Text.new('left',{
  font=self.font or love.graphics.getFont(),
  color=self.ink,print_speed=self.speed,character_sound=false,
 })
 self.box:send(self.message,self.wrap,self.visible)
end

function Ink:show_all()
 self.visible=true
 if self.box then self.box:send(self.message,self.wrap,true) end
end

function Ink:update(dt,reduced)
 if reduced then self:show_all() end
 self:ensure()
 if not reduced then self.box:update(math.max(0,dt or 0)) end
end

function Ink:draw(x,y)
 self:ensure()
 love.graphics.push('all')
 self.box:draw(x,y)
 love.graphics.pop()
end

return M
