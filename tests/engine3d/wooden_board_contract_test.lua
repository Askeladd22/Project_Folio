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
Scenery.place_table(box,{-14,14,-6.05,6.05},.28,.24)
assert(math.abs(box.max[3]-.24)<1e-9 and
 math.abs(box.verts[2][3]-.24)<1e-9,
 'ornamental rim must be raised without lifting the physical collision plane')
local floor=Scenery.floor_vertices(require('src.engine3d.g3d.scene').mesh,
 {-14,14,-6.05,6.05},'wooden')
assert(#floor==6 and floor[1][9]>0,'the physical floor must stay renderable')
Workshop.current='book'
assert(Workshop.cycle()=='current','legacy table must stay selectable through F8')
Workshop.current=saved
print('PASS wooden table visual contract: reversible, raised rim, unchanged D6 bounds')
