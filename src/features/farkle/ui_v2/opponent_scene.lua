-- Data-driven visual layer only; never mutates Farkle or g3d geometry.
-- The shipping composite JPEG already contains the Merchant. Other
-- opponents REQUIRE a clean room, so two figures can never overlap.
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
 local scale=math.min(540/w,300/h)
 local outW,outH=w*scale,h*scale
 local x=layout.tray.x+layout.tray.w*.5-outW*.5
 local bottom=layout.tray.y-5
 return {x=x,y=bottom-outH,w=outW,h=outH}
end
local image_cache={}
function S.draw_portrait(selection,layout,g)
 if not selection.portrait then return end
 local path=selection.portrait
 local sprite=image_cache[path]
 if not sprite then
  sprite=g.newImage(path)
  sprite:setFilter('linear','linear')
  image_cache[path]=sprite
 end
 local bounds=S.portrait_bounds(sprite:getWidth(),sprite:getHeight(),layout)
 g.setColor(1,1,1,1)
 g.draw(sprite,bounds.x,bounds.y,0,
  bounds.w/sprite:getWidth(),bounds.h/sprite:getHeight())
end
return S
