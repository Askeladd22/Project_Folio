-- Flat miniature presentation libraries: headless contracts for both Lua 5.4 / LuaJIT.
-- Genuine upstream Flux and anim8 are exercised without a GPU.
local graphicsCalls={draw=0,quads=0}
local oldLove=love
love={graphics={
 newQuad=function(x,y,w,h,iw,ih)
  graphicsCalls.quads=graphicsCalls.quads+1
  return {getViewport=function() return x,y,w,h end}
 end,
 draw=function(image,quad,...)
  assert(image and quad and type(quad.getViewport)=='function')
  graphicsCalls.draw=graphicsCalls.draw+1
 end,
 push=function(mode) assert(mode=='all') end,
 pop=function() end,
 setColor=function() end,
}}
local Flux=require('lib.flux')
local Anim8=require('lib.anim8')
assert(Flux._version=='0.1.5')
assert(Anim8._VERSION=='anim8 v2.3.1')

-- Separate groups prevent transition timing from leaking into gameplay.
local easing=Flux.group()
local p={x=0,y=0,scale=1}
easing:to(p,1,{x=100,y=40,scale=2}):ease('linear')
easing:update(.5)
assert(math.abs(p.x-50)<.00001 and math.abs(p.y-20)<.00001)
easing:update(.5)
assert(p.x==100 and p.y==40 and p.scale==2 and #easing==0)

local Mini=require('src.features.scriptorium.miniature_2d')
local img={getWidth=function() return 384 end,
           getHeight=function() return 144 end}
local knight=Mini.new(img,{x=140,y=220,scale=1,
  frames=4,frameWidth=96,frameHeight=144,frameTime=.1})
assert(graphicsCalls.quads==4)
knight:move_to(240,160,1.5,1,false)
knight:update(.5,false)
assert(knight.pose.x>140 and knight.pose.x<240,
 'transformation should interpolate without touching Farkle state')
knight.animation:gotoFrame(2)
knight:draw()
assert(graphicsCalls.draw==1)
knight:return_to_page(0,true)
assert(knight.pose.x==140 and knight.pose.y==220 and
  knight.pose.scale==1,'reduced motion should snap back to page')
knight:update(.05,true)
assert(knight.animation.position==1,
 'reduced motion must suppress decorative sprite animation')

local Ink=require('src.features.scriptorium.folio_ink_text')
local text=Ink.new('Folio',{wrap=120, speed=.05})
assert(text.box==nil and text.visible==false,
 'SYSL-Text should remain unloaded until graphical usage')
local realText=package.loaded['lib.sysl_text']
local sent,updates,draws=0,0,0
package.loaded['lib.sysl_text']={new=function(align,settings)
 assert(align=='left' and type(settings)=='table'
  and settings.character_sound==false)
 return {send=function(_,value,wrap,full)
   assert(value=='Folio' and wrap==120 and type(full)=='boolean')
   sent=sent+1
  end,update=function(_,dt) updates=updates+1 end,
  draw=function(_,x,y) assert(x==4 and y==5);draws=draws+1 end}
 end}
love.graphics.getFont=function() return {} end
text:update(.1,false)
assert(sent==1 and updates==1)
text:draw(4,5)
assert(draws==1)
text:update(.1,true)
text:update(.1,true)
assert(sent==2 and updates==1,
 'reduced motion should reveal the final text exactly once')
package.loaded['lib.sysl_text']=realText

-- Moonshine is intentionally opt-in, and its Canvas is never wrapped around
-- the 3D tray during normal play.
-- LuaJIT's standalone runner omits ?/init.lua from package.path, unlike
-- LÖVE and Lua 5.4; resolve the same vendored folder module in both tests.
local oldPackagePath=package.path
package.path='./?/init.lua;'..package.path
local realMoonshine=package.loaded['lib.moonshine']
local originalRequire=require('lib.moonshine')
assert(originalRequire.effects~=nil)
local drawn=0
package.loaded['lib.moonshine']=setmetatable({
 effects={vignette=function() end},
},{__call=function(_,effect)
 return setmetatable({vignette={},resize=function(_,w,h) end},{
  __call=function(_,drawfn) drawn=drawn+1;return drawfn() end
 })
end})
local PostFX=require('src.features.scriptorium.dream_postfx_2d')
local fx=PostFX.new()
assert(fx.enabled==false)
local value=0
fx:draw(function() value=value+1 end)
assert(value==1 and drawn==0)
fx.enabled=true
fx:draw(function() value=value+1 end)
assert(value==2 and drawn==1)
package.loaded['lib.moonshine']=realMoonshine or originalRequire
love=oldLove
package.path=oldPackagePath
print('PASS Project Folio 2D libraries: Flux tweens, anim8 sprite frames, reduced motion, lazy SYSL ink, optional Moonshine; no 3D or physics dependencies')
