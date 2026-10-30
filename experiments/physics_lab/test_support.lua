local N=require('experiments.physics_lab.fps')
local M=require('experiments.physics_lab.metrics')
local row={position={0,0,3},velocity={0,0,0},angular={0,0,0}}
local fixed,c=N.new({row})
local wake,k=N.new({row})
assert(c==1 and k==1)
local before=N.probe(fixed)
assert(before.airborne==0 and before.penetrating==0 and before.min_height>2)
local total=0
for i=1,200 do
 N.step(fixed,.0025)
 total=total+N.support_step(wake,.0025)
 local p=N.probe(wake)
 assert(p.airborne>=0 and p.penetrating>=0 and p.max_depth>=0)
end
local vanilla=N.snapshot(fixed,1)[1]
local experimental=N.snapshot(wake,1)[1]
assert(total>0,'unsupported sleeping body must be woken by diagnostic')
assert(experimental.position[3]<vanilla.position[3],
 'waking an unsupported die must let it fall farther than baseline')
assert(M.floor_height(vanilla)>0 and M.floor_height(experimental)>0,
 'airborne test must not penetrate floor')
local resting,n=N.new({{position={0,0,1/1.6},velocity={0,0,0},angular={0,0,0}}})
local p=N.probe(resting)
assert(p.min_height>=-.001,'upright cube should initially touch floor')
assert(N.support_step(resting,.01)>=0)
print('PASS FPS Lab 3: probe read-only, unsupported sleep test and wake variant independent')
