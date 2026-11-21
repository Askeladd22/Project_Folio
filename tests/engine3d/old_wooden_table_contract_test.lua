-- A new furniture model must not redefine the physical six-D6 game.
local W=require('src.farkle.tabletop').tray_workshop
local Scheme=require('src.data.dice_schema').scene
local Scenery=require('src.engine3d.g3d.scene').scenery
local model=require('resources.models.old_wooden_table_fallback')
local extents={-14,14,-6.05,6.05}
local old=W.current
assert(old=='old_wooden','Old Wooden Table must be the reversible default')
local m=model.mesh(extents)
assert(#m.verts>180 and #m.verts%3==0,'fallback must be a triangle mesh')
assert(math.abs(m.min[1]+14)<1e-9 and math.abs(m.max[1]-14)<1e-9
 and math.abs(m.min[2]+6.05)<1e-9 and math.abs(m.max[2]-6.05)<1e-9,
 'visible playing surface must cover all six D6 physics bounds')
assert(m.min[3]<-1.5 and m.max[3]<.01 and m.max[3]>0,
 'furniture must stay below the resting die contact plane')
for _,v in ipairs(m.verts) do
 assert(#v==12 and v[1]>=-14-1e-6 and v[1]<=14+1e-6
  and v[2]>=-6.05-1e-6 and v[2]<=6.05+1e-6,
  'fallback geometry must fit the physical tabletop')
 assert(v[3]>=m.min[3]-1e-6 and v[3]<=m.max[3]+1e-6,
  'furniture geometry must not float above a resting die')
 local len=math.sqrt(v[6]^2+v[7]^2+v[8]^2)
 assert(math.abs(len-1)<1e-5,'triangle normals must stay unit length')
end
-- The imported GLB's supports must not inherit the excessive X stretch
-- required to adapt its original 1.6:1 top to the physics 2.31:1 plane.
local transformed={min={-14,-6.05,-2},max={14,6.05,0},
 verts={{12,0,0,0,0,1,0,0,1,1,1,1},
        {12,0,-2,0,0,1,0,0,1,1,1,1}}}
Scenery.keep_old_support_proportions(transformed,.70)
assert(math.abs(transformed.verts[1][1]-12)<1e-8 and
 math.abs(transformed.verts[2][1]-8.4)<1e-8,
 'top remains wide while independent lower supports are narrower')
assert(math.abs(Scheme.box.border_height-.74)<1e-9 and
 Scheme.regions.unified.half_back==14 and
 Scheme.regions.unified.y_back==-6.05,
 'physical walls and dice field remain unchanged')
W.current='old_wooden'
assert(W.cycle()=='wooden_compact','F8 must restore the previous model')
W.current=old
print('PASS Old Wooden Table: source fallback, support proportions and reversible F8')
