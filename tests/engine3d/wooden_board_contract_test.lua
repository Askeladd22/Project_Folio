-- Source-derived walnut table must remain a visual alternative, not a collider.
local Workshop=require('src.farkle.tabletop').tray_workshop
local Scenery=require('src.engine3d.g3d.scene').scenery
local Scheme=require('src.data.dice_schema').scene
local model=require('resources.models.wooden_table_mesh')
local saved=Workshop.current
assert(saved=='wooden','new game must open with the wooden game-ready variant')
assert(model.vertex_count==243 and model.face_count==497,
 'the source-derived low-poly geometry metadata must remain stable')
assert(Scheme.box.border_height==.74 and
 Scheme.regions.unified.y_back==-6.05 and Scheme.regions.unified.y_front==6.05,
 'changing the decorative table must not change the physical boundaries')
local box={verts={
 {-1,-1,0,0,0,0,0,1,1,1,1,1},
 { 1, 1,1,0,0,0,0,1,1,1,1,1}},
 min={-1,-1,0},max={1,1,1}}
Scenery.place_table(box,{-14,14,-6.05,6.05},.28,-.018)
assert(math.abs(box.max[3]+.018)<1e-9 and
 math.abs(box.verts[2][3]+.018)<1e-9,
 'fallback tabletop must remain below the physical contact plane')
local geo=require('src.engine3d.g3d.scene').mesh
local floor=Scenery.floor_vertices(geo,{-14,14,-6.05,6.05},'wooden')
assert(#floor==6+8*6 and floor[1][3]==0,
 'bundled walnut surface needs plank shading over its physical receiver')
for i=7,#floor do
 assert(math.abs(floor[i][3]-.006)<1e-9,
  'decorative planks must remain almost flush with the collision plane')
end
local full=Scenery.floor_vertices(geo,{-14,14,-6.05,6.05},'wooden_full')
assert(#full==6 and full[1][3]==-.018,
 'full GLB should retain its own texture over a recessed shadow receiver')
Workshop.current='book'
assert(Workshop.cycle()=='current','legacy table must stay selectable through F8')
Workshop.current=saved
print('PASS wooden table visual contract: reversible, raised rim, unchanged D6 bounds')
