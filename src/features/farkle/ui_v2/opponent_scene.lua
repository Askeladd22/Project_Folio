-- Data-driven visual layer only; never mutates Farkle or g3d geometry.
-- The shipping composite JPEG already contains the Merchant. Other
-- opponents REQUIRE a clean room, so two figures can never overlap.
local Art=require('src.data.art_palette')
local S={}
S.default_id='merchant'
S.room_path='resources/scenes/printshop-room.png'
S.legacy_room='resources/merchant/table-host.jpg'
function S.validate_id(id)
 if id==nil then return S.default_id end
 assert(type(id)=='string' and id:match('^[a-z][a-z0-9_]*$'),
  'opponent ID must contain only lowercase letters, digits and underscores')
 return id
end
function S.portrait_path(id)
 return 'resources/opponents/'..S.validate_id(id)..'.png'
end
function S.available(path)
 return love and love.filesystem and love.filesystem.getInfo
  and love.filesystem.getInfo(path,'file')~=nil or false
end
function S.resolve(id,exists)
 id=S.validate_id(id)
 assert(type(exists)=='function','file-existence function required')
 local png=S.portrait_path(id)
 if exists(S.room_path) and exists(png) then
  return {id=id,room=S.room_path,portrait=png,legacy=false}
 end
 if id==S.default_id then
  return {id=id,room=S.legacy_room,portrait=nil,legacy=true}
 end
 if not exists(S.room_path) then
  error('Missing clean background '..S.room_path..
   '; current JPEG contains the Merchant and cannot host '..id,2)
 end
 error('Missing transparent portrait '..png,2)
end
function S.portrait_bounds(w,h,layout)
 assert(w>0 and h>0 and layout and layout.tray,'invalid portrait/layout')
 -- All PNG opponents use one proportional envelope. The lower edge
 -- slips behind the g3d table top, avoiding floating or pasted-on figures.
 local bottom=(layout.host and layout.host.y+layout.host.h or layout.tray.y)+35
  -(layout.portrait_lift or 0)
 local maxHeight=math.max(1,math.min(580,bottom-12))
 local scale=math.min(800/w,maxHeight/h)
 local outW,outH=w*scale,h*scale
 local x=layout.tray.x+layout.tray.w*.5-outW*.5
 return {x=x,y=bottom-outH,w=outW,h=outH}
end
-- 2.5D staging: the g3d table is the fixed pivot, farther planes drift
-- more. Pixel values are in the 1920x1080 virtual UI space.
S.depth={room=22,room_y=9,portrait=8,portrait_y=3,overscan=1.035,breath=.005}
local view={x=0,y=0}
function S.parallax(dt,nx,ny,t,reduced)
 if reduced then
  view.x,view.y=0,0
 else
  local tx=math.max(-1,math.min(1,nx))*.85+math.sin(t*.21)*.15
  local ty=math.max(-1,math.min(1,ny))*.5+math.sin(t*.17+1.3)*.12
  local k=1-math.exp(-math.max(0,math.min(dt,.1))*2.4)
  view.x=view.x+(tx-view.x)*k
  view.y=view.y+(ty-view.y)*k
 end
 return {x=view.x,y=view.y}
end
local portrait_shader
local function get_portrait_shader(g)
 if not portrait_shader then
  portrait_shader=assert(g.newShader('resources/shaders/woodcut_portrait.glsl'),
   'Failed to create woodcut portrait shader')
 end
 return portrait_shader
end
local image_cache={}
function S.draw_portrait(selection,layout,g,depth)
 if not selection.portrait then return end
 local path=selection.portrait
 local sprite=image_cache[path]
 if not sprite then
  sprite=g.newImage(path)
  sprite:setFilter('linear','linear')
  image_cache[path]=sprite
 end
 local iw,ih=sprite:getWidth(),sprite:getHeight()
 local bounds=S.portrait_bounds(iw,ih,layout)
 local sx,sy=bounds.w/iw,bounds.h/ih
 local x,y,lift=bounds.x,bounds.y,1
 if depth then
  x=x-depth.x*S.depth.portrait
  y=y-depth.y*S.depth.portrait_y
  lift=1+S.depth.breath*(depth.breath or 0)
 end
 -- Breathing grows upward from the hidden waist, never off the table.
 local oy=ih
 local shader=depth and get_portrait_shader(g)
 if shader then
  -- Cast shadow on the back wall separates the figure from the room.
  local shade=Art.rgb('earth_dark')
  shader:send('shadowTexel',{1/iw,1/ih})
  shader:send('shadowPass',1)
  g.setShader(shader)
  g.setColor(shade[1],shade[2],shade[3],.24)
  g.draw(sprite,x+bounds.w*.5+16-depth.x*(S.depth.room-S.depth.portrait),y+bounds.h+4,0,
   sx*1.02,sy*1.015*lift,iw*.5,oy)
  shader:send('shadowPass',0)
  shader:send('inkTone',Art.rgb('ink'))
  shader:send('paperTone',Art.rgb('paper'))
 end
 g.setColor(1,1,1,1)
 g.draw(sprite,x+bounds.w*.5,y+bounds.h,0,sx,sy*lift,iw*.5,oy)
 if shader then g.setShader() end
 g.setColor(1,1,1,1)
end
return S
