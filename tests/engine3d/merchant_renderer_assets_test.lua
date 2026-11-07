-- Prevent deleted Merchant-era files from crashing the production g3d renderer.
local function read(path)
 local file=assert(io.open(path,'rb'),'missing production asset: '..path)
 local bytes=file:read('*a');file:close();return bytes
end
local renderer=read('src/engine3d/g3d/live.lua')
local scenery=assert(read('src/engine3d/g3d/scene.lua')
 :match('%-%- Table scenery(.-)%-%- Camera and projection'))
local opponent=read('src/farkle/ui.lua')
local hud=read('src/farkle/ui.lua')
local table_shader=read('resources/shaders/dream_table.glsl')
local atmosphere=read('resources/shaders/dream_atmosphere.glsl')
local portrait_shader=read('resources/shaders/woodcut_portrait.glsl')
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
assert(renderer:find('self.table_prop.shader=self.table_shader',1,true) and
 scenery:find("shader='resources/shaders/dream_table.glsl'",1,true) and
 table_shader:find('warmStone',1,true) and
 table_shader:find('printPalette',1,true) and
 table_shader:find('(softened - vec3(0.5)) * 0.94',1,true),
 'the marble prop needs its soft, warm playable center')
assert(not hud:find('dream_night',1,true) and not hud:find('soften_room',1,true),
 'the new night artwork must not be re-tinted or blurred')
assert(atmosphere:find('abs(uv.x - 0.5)',1,true) and
 atmosphere:find('* symmetry *',1,true),
 'background waviness must be symmetric around the scene center')
assert(opponent:find("S.room_path='resources/scenes/printshop-room.png'",1,true),
 'the independent printshop room must remain in production')
assert(opponent:find("g.newShader('resources/shaders/woodcut_portrait.glsl')",1,true) and
 portrait_shader:find('smoothstep(0.12, 0.88, luminance)',1,true),
 'portrait should render as a warm, replaceable woodcut rather than a pasted monochrome cutout')
print('PASS Merchant g3d uses tracked wood and independent character, no retired JPG assets')
