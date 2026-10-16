require('core');love={graphics={newImage=function()end}}
local P=require('src.engine3d.physics');local G=require('src.engine3d.geometry')
local C=require('src.engine3d.containment')
local function b() local s=G.newD6Body(.92):set({0,0,.575},{0,0,0},{0,0,0});s.asleep=true;s.sleep_timer=.24;return s end
local s=b();C.apply(s,1.23e-8,0,0,0,true)
assert(s.position[1]==1.23e-8,'correction must still be applied')
assert(s.asleep and s.sleep_timer==.24,'numerical correction must preserve mechanical rest')
s=b();C.apply(s,.001,0,0,0,true);assert(not s.asleep and s.sleep_timer==0,'meaningful displacement wakes')
s=b();s.velocity=vector{1,0,0};C.apply(s,1e-8,0,1,0,true);assert(not s.asleep,'moving body wakes')
s=b();C.apply(s,1e-8,0,0,0,false);assert(not s.asleep,'loss of support wakes')
s=b();s.asleep=false;C.apply(s,1e-8,0,0,0,true);assert(not s.asleep and s.sleep_timer==.24,'do not force sleep')
print('PASS numerical containment, displacement, velocity, support and no forced sleep')
