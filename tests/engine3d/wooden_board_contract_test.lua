-- Source-derived walnut table must remain a visual alternative, not a collider.
local Workshop=require('src.farkle.tabletop').tray_workshop
local Scenery=require('src.engine3d.g3d.scene').scenery
local Scheme=require('src.data.dice_schema').scene
local model=require('resources.models.wooden_table_mesh')
local saved=Workshop.current
assert(saved=='old_wooden',
 'new game must start on the reversible old wooden table')
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
local top=box.max[3]
local originalDepth=top-box.min[3]
assert(Scenery.compact_table(box,.22)==box)
assert(math.abs(box.max[3]-top)<1e-9 and
 math.abs(top-box.min[3]-originalDepth*.22)<1e-9,
 'compact furniture must compress only its vertical decorative extent')
assert(math.abs(box.verts[2][3]-top)<1e-9,
 'six-D6 upper play plane must remain at the same visual height')
local ok=pcall(Scenery.compact_table,box,0)
assert(not ok,'decorative vertical compression must reject degenerate geometry')
local geo=require('src.engine3d.g3d.scene').mesh
local floor=Scenery.floor_vertices(geo,{-14,14,-6.05,6.05},'wooden')
assert(#floor==6+8*6 and floor[1][3]==0,
 'bundled walnut surface needs plank shading over its physical receiver')
for i=7,#floor do
 assert(math.abs(floor[i][3]-.006)<1e-9,
  'decorative planks must remain almost flush with the collision plane')
 assert(math.abs(floor[i][5]-(floor[i][2]+6.05)/12.10)<1e-9,
  'the walnut grain must not restart at every plank joint')
end
local compact=Scenery.floor_vertices(geo,{-14,14,-6.05,6.05},'wooden_compact')
assert(#compact==6+6*6,
 'compact style should show only six broad walnut planks')
for i=7,#compact do
 assert(math.abs(compact[i][3]-.006)<1e-9 and
  math.abs(compact[i][5]-(compact[i][2]+6.05)/12.10)<1e-9,
  'compact planks must remain flush and preserve continuous wood grain')
end
local wideRim=Scenery.style_vertices(geo,{-14,14,-6.05,6.05},.74,'wooden')
local smallRim=Scenery.style_vertices(geo,{-14,14,-6.05,6.05},.74,'wooden_compact')
local function xmin(v)
 local x=math.huge
 for _,p in ipairs(v) do x=math.min(x,p[1]) end
 return x
end
assert(xmin(smallRim)>xmin(wideRim)+.04 and
 #smallRim==#wideRim,
 'compact rim should be narrower without changing physical wall height')
local full=Scenery.floor_vertices(geo,{-14,14,-6.05,6.05},'wooden_full')
assert(#full==6 and full[1][3]==-.018,
 'full GLB should retain its own texture over a recessed shadow receiver')
Workshop.current='book'
assert(Workshop.cycle()=='current','legacy table must stay selectable through F8')
Workshop.current=saved
print('PASS compact table: shallow supports, thin rim, wide dice floor and F8 rollback')
