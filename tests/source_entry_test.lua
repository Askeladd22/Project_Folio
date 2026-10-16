-- Canonical entry restores the frontend, without bootstrapping chromatic gameplay.
love={}
assert(loadfile('conf.lua'))()
local config={window={}}
love.conf(config)
assert(config.identity=='manuscript-farkle-roguelite','root conf still uses the legacy save identity')
local file=assert(io.open('main.lua','r'));local entry=file:read('*a');file:close()
assert(not entry:find('engine_main.lua',1,true),'entry requires an assembled file')
assert(not entry:find('package.loaded',1,true),'entry masks the legacy module')
local engine=assert(io.open('src/app/dice_runtime.lua','r'))
local source=engine:read('*a');engine:close()
for _,name in ipairs{'run','reward'} do
 assert(not source:find('require("src.features.'..name..'.module")',1,true),'loads legacy feature '..name)
end
assert(entry:find("go('startup_splash')",1,true),'missing normal splash entry')
print('PASS canonical Farkle identity, source-only entry, restored frontend')
