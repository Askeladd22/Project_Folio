-- Adapted the provisional test to the shipped object-based model API.
local M=dofile('experiments/fx_lab/model.lua')
for _,hz in ipairs({20,30,60,144}) do
 local s=M.new(); s:set_duration(2); s:play()
 for i=1,hz do s:update(1/hz) end
 assert(math.abs(s:progress()-.5)<1e-9)
 s:update(10); assert(s:progress()==1 and s.completions==1)
 s:play(); assert(s:progress()==0)
 s:pause(); s:update(1); assert(s:progress()==0)
 s:set_reduced(true); assert(s:progress()==1)
 s:set_reduced(false); s:set_disabled(true); assert(s:progress()==1)
end
for _,name in ipairs({'main','visuals','shaders','conf','model'}) do
 assert(loadfile('experiments/fx_lab/'..name..'.lua'))
end
print('PASS 20/30/60/144 Hz, pause, replay, reduced/disabled, LuaJIT source syntax')
