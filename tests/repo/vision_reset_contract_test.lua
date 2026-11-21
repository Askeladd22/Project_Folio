-- Assert the user's 21-Nov reset without erasing the playable Farkle baseline.
local function read(path)
 local f=assert(io.open(path,'rb'),path)
 local source=f:read('*a');f:close()
 return source
end
local vision=read('docs/project_vision.md')
assert(vision:find('D-005',1,true),'vision reset must cite its decision')
assert(vision:find('incisore nella Venezia rinascimentale',1,true),
 'the sole creative invariant must be documented explicitly')
assert(vision:find('Farkle',1,true) and
 vision:find('baseline',1,true),'prototype is still a measurable baseline')
local previous=read('docs/player_fantasy.md')
assert(previous:find('ipotesi in revisione',1,true),
 'the old dice fantasy must not pose as a mandatory final premise')
local doc=read('docs/technical.md')
assert(doc:find('src/engine3d/die_collision.lua',1,true)
 and doc:find('helpTab1',1,true),
 'operational physics and controls must survive the historical trim')
local readme=read('README.md')
assert(readme:find('30 Lua source files',1,true))
local f=io.open('scripts/run_hud_comparison.py','rb')
assert(f==nil,'retired dual-HUD runner reappeared')
if f then f:close() end
f=io.open('resources/models/old_wooden_table.glb','rb')
assert(f==nil,'historical test-only 9 MiB GLB reappeared')
if f then f:close() end
assert(read('version.txt'):match('^0%.1%.104%s*$'))
print('PASS v0.1.104 creative reset, retained runtime contracts and retired artifacts')
