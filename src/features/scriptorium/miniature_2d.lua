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
