-- Pure Lua 5.4 and LuaJIT bridge test, no FPS/native library needed.
local O=require('experiments.physics_lab.old')
local H=require('experiments.physics_lab.handoff')
local Metric=require('experiments.physics_lab.metrics')
local rows={
 {position={-2,0,3},velocity={.7,-.3,-1},angular={.4,.5,-.2}},
 {position={2,.6,3.4},velocity={-.2,.6,-.4},angular={-.4,.1,.8}}
}
local src=O.new(rows)
-- Move actual ORIGINAL physical cube orientations, not just cosmetic mesh.
for _,b in ipairs(src) do
 local vel={b.velocity[1],b.velocity[2],b.velocity[3]}
 b.velocity=vector{0,0,0}
 b:update(.17)
 b.velocity=vector(vel)
end
local state=O.snapshot(src)
for i,b in ipairs(src) do
 state[i].velocity={b.velocity[1],b.velocity[2],b.velocity[3]}
 state[i].angular={b.angular[1],b.angular[2],b.angular[3]}
 local ok,why=H.check(state[i]);assert(ok,why)
end
local new=H.handoff(state)
local delta=H.error(state,new)
for k,v in pairs(delta) do assert(v<1e-9,k..' altered at transfer') end
for i,s in ipairs(state) do
 local expected=Metric.top_value(s)
 local actual=Metric.top_value(O.snapshot(new)[i])
 assert(expected==actual,'handoff must preserve physical pip face ordering')
 assert(new[i].asleep==false and new[i]._manual_pending==false)
end
-- Reject corruption before touching the existing world, not silently
-- normalizing/scrambling authoritative Farkle result geometry.
local bad={}
for i,s in ipairs(state) do bad[i]=s end
local malformed={}
for k,v in pairs(state[1]) do malformed[k]=v end
malformed.vertices={}
for j,p in ipairs(state[1].vertices) do
 malformed.vertices[j]={p[1],p[2],p[3]}
end
malformed.vertices[1][1]=malformed.vertices[1][1]+.15
bad[1]=malformed
local ok,reason=H.check(bad[1])
assert(not ok and reason,'distorted FPS die must be rejected')
assert(not pcall(H.handoff,bad),'partial corrupt group must never transfer')
local nan={}
for k,v in pairs(state[1]) do nan[k]=v end
nan.velocity={0/0,0,0}
assert(not H.check(nan),'non-finite release velocity must be rejected')
local flipped={}
for k,v in pairs(state[1]) do flipped[k]=v end
flipped.vertices={}
for j,p in ipairs(state[1].vertices) do flipped.vertices[j]={p[1],p[2],-p[3]} end
assert(not H.check(flipped),'mirrored physical cube must not flip dice pips')
print('PASS Lab 5 bridge: lossless world/local pose, linear+angular velocity, face numbering, invalid-state rejection')
