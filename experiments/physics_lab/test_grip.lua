local N=require('experiments.physics_lab.fps')
local M=require('experiments.physics_lab.metrics')
local rows={
 {position={-2.3,0,3.2},velocity={0,0,0},angular={0,0,0}},
 {position={2.3,0,3.2},velocity={0,0,0},angular={0,0,0}},
}
local world,count=N.new(rows)
assert(count==2)
local before=N.snapshot(world,count)
local original={}
for i=1,count do original[i]={before[i].position[1],before[i].position[2],before[i].position[3]} end
for step=1,200 do
 N.grip_step(world,{0,0,3.2},.005,23,8,
  (step%30<15) and 3 or -3,true)
end
local after=N.snapshot(world,count)
for i,b in ipairs(after) do
 assert(math.abs(b.position[1])<math.abs(original[i][1]),
  'FPS spring should pull each genuine body toward one hand point')
 assert(M.floor_height(b)>-20,
  'held-body experiment should not produce runaway geometry')
end
assert(not pcall(N.grip_step,world,{0/0,0,3},.005,23,8,0,true),
 'non-finite target must be rejected before FFI')
assert(not pcall(N.grip_step,world,{0,0,3},-.005,23,8,0,true),
 'invalid dt must be rejected by native guard')
assert(not package.loaded['src.features.farkle.controller'],
 'FPS test should never import production gameplay')
print('PASS FPS Lab 4: native hand spring / held spin, FFI validation, isolated from Farkle')
