package.path = 'experiments/fx_lab/?.lua;' .. package.path
local M = require('model')
local function near(a,b) assert(math.abs(a-b)<1e-8, tostring(a)..' ~= '..tostring(b)) end
local a,b=M.new(),M.new()
a:play(); b:play()
a:update(.73)
for i=1,73 do b:update(.01) end
near(a:progress(), b:progress())
a:set_duration(.8); a:play(); a:update(.8)
near(a:progress(),1); assert(a.completions==1 and not a.playing)
a:update(9); assert(a.completions==1)
a:play(); a:update(.2); a:pause(); local p=a:progress(); a:update(2); near(a:progress(),p)
a:set_reduced(true); near(a:progress(),1); assert(not a.playing)
a:play(); near(a:progress(),1); assert(not a.playing)
a:set_reduced(false); a:set_disabled(true); a:play(); near(a:progress(),1)
a:set_disabled(false); a.loop=true; a:play(); local n=a.completions
a:update(2.1); assert(a.completions==n+2); near(a:progress(),.625)
for _,f in pairs(M.ease) do near(f(0),0); near(f(1),1) end
local c,d=M.new(),M.new(); c.loop=true; d.loop=true; c:play(); d:play()
c:update(7.31); for i=1,731 do d:update(.01) end
near(c:progress(),d:progress()); assert(c.completions==d.completions)
print('timeline: partition, endpoint, pause, reduced, disabled, loops, easing OK')
