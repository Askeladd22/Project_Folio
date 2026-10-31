local Portrait=require('src.engine3d.g3d_portrait')
local Bridge=require('src.core.engine_bridge')
local entry={body={{1,2,3},{-1,2,-3},{2,0,1},
 position={14,-5,2}}}
local out=Portrait.physical_pose(entry)
assert(#out==3 and out.position[1]==0 and out.position[2]==0 and out.position[3]==0)
assert(out[1][1]==1 and out[2][3]==-3,'portrait must retain physical rotations')
out[1][1]=10
assert(entry.body[1][1]==1,'GPU portrait must not mutate physical body')
assert(Bridge.get_renderer_mode==nil and Bridge.rendererMode==nil,
 'no legacy renderer mode should remain in the engine bridge')
assert(not package.loaded['lib.g3d'],'headless portrait import must not initialize GPU')
print('PASS HUD g3d portrait: immutable physical snapshot, g3d-only, lazy loading')
