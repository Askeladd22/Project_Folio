local Bundle = {}
Bundle.menu_surface = (function()
-- Shared manuscript surfaces for Project Folio frontend and UI V2.
-- Lightweight LÖVE drawing primitives. No old HUD, CPU painter or fallback.
-- Pure geometry functions are usable in headless Lua tests.
local Art=require('src.data.frontend_schema').palette
local M={}
-- Retain the legacy public palette keys for callers. All colour sources
-- now resolve through one explicit, versioned art-direction vocabulary.
M.palette={
 ink=Art.rgb('text'),
 muted=Art.rgb('text_muted'),
 gold=Art.rgb('reward'),
 parchment=Art.rgb('surface'),
 border=Art.rgb('border'),
}
local function color(c,a)
 love.graphics.setColor(c[1],c[2],c[3],a or 1)
end
function M.within(rect,w,h)
 return type(rect)=='table' and rect.x>=0 and rect.y>=0
  and rect.w>0 and rect.h>0 and rect.x+rect.w<=w+1
  and rect.y+rect.h<=h+1
end
function M.contains(rect,x,y)
 return rect and x>=rect.x and y>=rect.y
  and x<=rect.x+rect.w and y<=rect.y+rect.h
end

-- No full-width legacy letterbox/header/footer strips: keep the original
-- illuminated workshop illustration visible beyond one bounded leaf.
function M.backdrop(w,h,high_contrast,opacity,opts)
 local g=love.graphics
 g.push('all')
 local quiet=opts and opts.quiet
 local darkness
 if quiet then
  darkness=high_contrast and .41 or
   (opts and opts.illustrated and .10 or .28)
 else
  darkness=high_contrast and .32 or .16
 end
 color(Art.rgb('ink'),darkness*(opacity or 1))
 g.rectangle('fill',0,0,w,h)
 g.pop()
end

-- Four thin rules and ink corner ornaments read as a folio, not a window.
function M.panel(r,opts)
 opts=opts or {}
 local alpha=opts.alpha or 1
 local high=opts.high_contrast
 local g=love.graphics
 if opts.style=="editorial" then
  g.push('all')
  -- A restrained paper leaf: straight edges, one hairline border and
  -- restrained paper warmth instead of faux embossed gold ornament.
  color(Art.rgb('ink'),.44*alpha)
  g.rectangle('fill',r.x+5,r.y+7,r.w,r.h)
  color(Art.rgb('surface'),(high and 1 or .98)*alpha)
  g.rectangle('fill',r.x,r.y,r.w,r.h)
  color(Art.rgb('border'),(high and .81 or .60)*alpha)
  g.setLineWidth(1)
  g.rectangle('line',r.x+.5,r.y+.5,r.w-1,r.h-1)
  g.pop()
  return
 end
 g.push('all')
 color(Art.rgb('ink'),.45*alpha)
 g.rectangle('fill',r.x+8,r.y+11,r.w,r.h,8,8)
 color(Art.rgb('surface'),(high and .98 or .94)*alpha)
 g.rectangle('fill',r.x,r.y,r.w,r.h,7,7)
 color(Art.rgb('plaster'),.49*alpha)
 g.rectangle('fill',r.x+8,r.y+8,r.w-16,r.h-16,3,3)
 color(M.palette.border,.82*alpha)
 g.setLineWidth(2)
 g.rectangle('line',r.x+1,r.y+1,r.w-2,r.h-2,7,7)
 color(Art.rgb('border'),.60*alpha)
 g.setLineWidth(1)
 g.rectangle('line',r.x+11,r.y+11,r.w-22,r.h-22,3,3)
 for _,dx in ipairs({1,-1}) do
  for _,dy in ipairs({1,-1}) do
   local x=dx==1 and r.x+20 or r.x+r.w-20
   local y=dy==1 and r.y+20 or r.y+r.h-20
   g.line(x,y+dy*13,x,y,x+dx*13,y)
  end
 end
 g.pop()
end

function M.rule(x,y,w,alpha,opts)
 local g=love.graphics
 if opts and opts.quiet then
  g.push('all')
  color(Art.rgb('border'),.34*(alpha or 1))
  g.setLineWidth(1)
  g.line(x,y,x+w,y)
  g.pop()
  return
 end
 g.push('all')
 color(M.palette.border,.50*(alpha or 1))
 g.setLineWidth(1)
 local center=x+w*.5
 g.line(x,y,center-12,y)
 g.line(center+12,y,x+w,y)
 color(M.palette.gold,.9*(alpha or 1))
 g.polygon('fill',center,y-5,center+5,y,center,y+5,center-5,y)
 g.pop()
end

function M.item(rect,opts)
 opts=opts or {}
 local g=love.graphics
 local alpha=opts.alpha or 1
 local active=opts.active and true or false
 local disabled=opts.disabled and true or false
 local primary=opts.primary and true or false
 if opts.style=="editorial" then
  g.push('all')
  -- Index-like navigation rather than six embossed parchment buttons.
  if active and not disabled then
   color(Art.rgb('selection'),.21*alpha)
   g.rectangle('fill',rect.x,rect.y,rect.w,rect.h)
   color(Art.rgb('focus'),.88*alpha)
   g.rectangle('fill',rect.x+1,rect.y+6,3,math.max(1,rect.h-12))
  end
  color(Art.rgb('border'),(disabled and .10 or .25)*alpha)
  g.setLineWidth(1)
  g.line(rect.x+1,rect.y+rect.h-.5,rect.x+rect.w-1,rect.y+rect.h-.5)
  g.pop()
  return
 end
 g.push('all')
 local fill=active and Art.rgb('sage_light')
  or primary and Art.rgb('surface_alt')
  or Art.rgb('surface')
 color(fill,(disabled and .38 or active and .95 or .68)*alpha)
 g.rectangle('fill',rect.x,rect.y,rect.w,rect.h,5,5)
 color(M.palette.border,(active and .93 or .36)*alpha)
 g.setLineWidth(active and 2 or 1)
 g.rectangle('line',rect.x+.5,rect.y+.5,rect.w-1,rect.h-1,5,5)
 if active then
  color(M.palette.gold,.95*alpha)
  g.rectangle('fill',rect.x+2,rect.y+7,3,rect.h-14)
  local x=rect.x+rect.w-23
  local cy=rect.y+rect.h/2
  g.polygon('fill',x,cy-5,x+5,cy,x,cy+5,x-5,cy)
 end
 g.pop()
end

return M
end)()
Bundle.page_layout = (function()
-- All desk geometry is in the existing 1920x1080 virtual coordinate space.
-- The lectern silhouette suggests inclination; the playable surface stays flat.
local Layout = {}
local page = {x = 610, y = 62, w = 700, h = 568}
local grid = {x = 76, y = 106, cell = 100, gap = 12, rows = 4, cols = 5}

function Layout.get()
    return {
        page = {x = page.x, y = page.y, w = page.w, h = page.h},
        commission = {x = 80, y = 116, w = 420, h = 510},
        glosses = {x = 1420, y = 116, w = 420, h = 510},
        dock = {x = 80, y = 682, w = 420, h = 236},
        actions = {x = 1420, y = 682, w = 420, h = 180},
        tray = {x = 530, y = 666, w = 860, h = 404},
        layers = {
            background = {x = 0, y = 0, w = 1920, h = 1080},
            desk = {x = 0, y = 650, w = 1920, h = 430},
            lectern = {x = 480, y = 48, w = 960, h = 612},
            parchment = {x = page.x, y = page.y, w = page.w, h = page.h},
        },
    }
end

function Layout.to_page(x, y)
    return x - page.x, y - page.y
end

function Layout.cell_rect(row, col)
    return {
        x = page.x + grid.x + (col - 1) * (grid.cell + grid.gap),
        y = page.y + grid.y + (row - 1) * (grid.cell + grid.gap),
        w = grid.cell, h = grid.cell,
    }
end

function Layout.hit_cell(x, y)
    local px, py = Layout.to_page(x, y)
    px, py = px - grid.x, py - grid.y
    if px < 0 or py < 0 then return nil end
    local step = grid.cell + grid.gap
    local col, row = math.floor(px / step) + 1, math.floor(py / step) + 1
    if row > grid.rows or col > grid.cols or px % step >= grid.cell or py % step >= grid.cell then
        return nil
    end
    return row, col
end

function Layout.screen_tray(resolution)
    local tray = Layout.get().tray
    local x, y = resolution.to_screen(tray.x, tray.y)
    local right, bottom = resolution.to_screen(tray.x + tray.w, tray.y + tray.h)
    return {x = x, y = y, w = right - x, h = bottom - y}
end

return Layout
end)()
Bundle.folio_ink_text = (function()
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
 if self.visible then return end
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
end)()
Bundle.miniature_2d = (function()
-- Flat illuminated-manuscript figures: ONLY a LÖVE SpriteSheet + transform.
-- Anim8 handles frames, Flux handles decorative motion; no 3D bodies and
-- absolutely no Farkle scoring/physics dependencies.
local Anim8=require('lib.anim8')
local Flux=require('lib.flux')
local M={}
local Figure={}
Figure.__index=Figure

function M.new(image,options)
 options=options or {}
 assert(image and image.getWidth and image.getHeight,
   'miniature needs a LÖVE Image or Canvas')
 local fw=assert(options.frameWidth,'frameWidth required')
 local fh=assert(options.frameHeight,'frameHeight required')
 local count=options.frames or math.floor(image:getWidth()/fw)
 assert(count>=1 and count*fw<=image:getWidth()
   and fh<=image:getHeight(),'spritesheet frames outside image')
 local grid=Anim8.newGrid(fw,fh,image:getWidth(),image:getHeight())
 local frames=grid('1-'..count,1)
 local x,y=options.x or 0,options.y or 0
 local scale=options.scale or 1
 return setmetatable({
   image=image,animation=Anim8.newAnimation(frames,options.frameTime or .16),
   origin={x=x,y=y,scale=scale},
   pose={x=x,y=y,scale=scale,opacity=1},
   target={x=x,y=y,scale=scale},
   group=Flux.group(),width=fw,height=fh,
 },Figure)
end

function Figure:move_to(x,y,scale,duration,reduced)
 assert(type(x)=='number' and type(y)=='number',
   'miniature position must be numeric')
 scale=scale or self.pose.scale
 self.target={x=x,y=y,scale=scale}
 self.group=Flux.group() -- replace previous ornamental motion cleanly
 if reduced or not duration or duration<=0 then
  self.pose.x,self.pose.y,self.pose.scale=x,y,scale
 else
  self.group:to(self.pose,duration,{x=x,y=y,scale=scale})
    :ease('cubicout')
 end
end

function Figure:return_to_page(duration,reduced)
 self:move_to(self.origin.x,self.origin.y,self.origin.scale,
  duration,reduced)
end

function Figure:update(dt,reduced)
 if reduced then
  -- When accessibility mode is enabled during an in-flight transition,
  -- snap to its intended destination rather than freezing halfway.
  self.group=Flux.group()
  if self.target then
   self.pose.x=self.target.x
   self.pose.y=self.target.y
   self.pose.scale=self.target.scale
  end
  self.animation:gotoFrame(1)
 else
  self.group:update(math.max(0,dt or 0))
  self.animation:update(math.max(0,dt or 0))
 end
end

function Figure:draw()
 local g=love.graphics
 g.push('all')
 g.setColor(1,1,1,self.pose.opacity)
 self.animation:draw(self.image,self.pose.x,self.pose.y,0,
   self.pose.scale,self.pose.scale,self.width/2,self.height)
 g.pop()
end

return M
end)()
Bundle.dream_postfx_2d = (function()
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
end)()
return Bundle
