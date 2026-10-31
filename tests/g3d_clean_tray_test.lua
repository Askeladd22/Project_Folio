-- Clean g3d presentation regression: geometry and render order.
-- No graphics context; only pure geometry and static execution path checks.
local Scene=require('src.engine3d.g3d_scenery')
local Mesh=require('src.engine3d.g3d_mesh')
local Live=require('src.engine3d.g3d_live')
local schema=require('src.data.dice_scene_schema')
local extents={-9.2,9.2,-3.8,3.8}
local book=Scene.floor_vertices(Mesh,extents,'book')
assert(#book==6,'one simple two-triangle floor')
for _,v in ipairs(book) do
 assert(v[3]==0 and v[8]==1,'the GPU floor must lie at physical z=0')
 assert(v[9]>.8 and v[10]>.7 and v[11]>.5,
  'the book floor must be plain warm parchment')
 assert(v[12]==1,'GPU floor must be opaque to write valid depth')
end
local skins=Scene.style_vertices(Mesh,extents,.74,'book')
assert(#skins==4*3*8*6,'plain book rim must retain existing face topology')
local minx,maxx=math.huge,-math.huge
for _,v in ipairs(skins) do minx=math.min(minx,v[1]);maxx=math.max(maxx,v[1]) end
assert(math.abs(minx-(extents[1]-.32))<1e-8 and
 math.abs(maxx-(extents[2]+.32))<1e-8,'book frame is thinner without physical geometry change')
for _,style in ipairs({'current','A','B','C'}) do
 assert(#Scene.floor_vertices(Mesh,extents,style)==6,'missing simple GPU floor for '..style)
end
assert(schema.tray_camera.yaw==0,
 'preserve the established tray camera and fixed dice scale/picking parity')
local function read(path)
 local f=assert(io.open(path,'rb'),'missing '..path)
 local s=f:read('*a');f:close();return s
end
local runtime=read('src/app/dice_runtime.lua')
local renderer=read('src/engine3d/g3d_live.lua')
assert(runtime:find('live_g3d:draw({',1,true),
 'production tray must always draw through g3d')
assert(not runtime:find('render.paint()',1,true),
 'CPU fallback painter must not be called')
assert(not runtime:find('draw_legacy_floor',1,true),
 'legacy floor must not remain')
assert(not runtime:find("key=='f9'",1,true),'F9 fallback must be removed')
local floorPos=assert(renderer:find('self.floor_model:draw()',1,true))
local shadowPos=assert(renderer:find('self.models[item.index].shadow:draw()',1,true))
local wallPos=assert(renderer:find('self.walls:draw()',1,true))
assert(floorPos<shadowPos and shadowPos<wallPos,
 'depth-accurate floor, shadow and wall GPU draw order must be preserved')
assert(not renderer:find('self.lines:draw()',1,true),'minimal mode must not paint ornamental page bars')
assert(not renderer:find('love.graphics.origin()',1,true),'GPU error handling must preserve painter transform')
assert(Live.supported({{die={faces={{1,2,3},{1,2,3},{1,2,3},{1,2,3},
 {1,2,3},{1,2,3},{1,2,3},{1,2,3}},faceValueMap={1,2,3,4,5,6,7,8}}}}),
 'D8 support must survive the visual cleanup')
assert(not package.loaded['lib.g3d'],'headless checks must not load GPU')
print('PASS g3d clean presentation: plain floor, thin frame, rendering isolation without legacy painter fallback')
