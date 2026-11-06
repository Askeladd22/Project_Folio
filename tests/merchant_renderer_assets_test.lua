-- Prevent deleted Merchant-era files from crashing the production g3d renderer.
local function read(path)
 local file=assert(io.open(path,'rb'),'missing production asset: '..path)
 local bytes=file:read('*a');file:close();return bytes
end
local renderer=read('src/engine3d/g3d_live.lua')
local scenery=read('src/engine3d/g3d_scenery.lua')
local opponent=read('src/features/farkle/ui_v2/opponent_scene.lua')
for _,path in ipairs({
 'resources/textures/wood.png',
 'resources/scenes/printshop-room.png',
 'resources/opponents/merchant.png',
}) do
 assert(#read(path)>16,'production image unexpectedly small: '..path)
end
assert(renderer:find("g.newImage('resources/textures/wood.png'",1,true),
 'the real g3d tabletop must load a tracked and existing wood texture')
assert(renderer:find('floor_texture=self.merchantWood',1,true),
 'the Merchant floor still needs the wood texture binding')
for _,old in ipairs({
 'resources/merchant/wood-floor.jpg',
 'resources/merchant/carving.jpg',
}) do
 assert(not renderer:find(old,1,true),
  'renderer still loads removed file '..old)
end
assert(not renderer:find('self.carving',1,true) and
 not scenery:find('merchant_carving',1,true),
 'removed carved plank must not create a missing-asset model')
assert(renderer:find('self.floor_model:draw()',1,true),
 'the physical floor still needs to be rendered in the 3D depth pass')
assert(opponent:find("S.room_path='resources/scenes/printshop-room.png'",1,true),
 'the independent printshop room must remain in production')
print('PASS Merchant g3d uses tracked wood and independent character, no retired JPG assets')
