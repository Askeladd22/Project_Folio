-- Guard against accidental return of one-off archived screenshots.
-- Keep current QA evidence and production assets until their own reviews.
local function exists(path)
 local file=io.open(path,'rb')
 if file then file:close();return true end
 return false
end
assert(not exists('audits/ui-v2-review/20261101-101134-b2e7f4cb/hud/hud-usability-1920-fresh.png'),
 'archived November 1 QA snapshot must not be reintroduced')
assert(not exists('audits/ui-v2-review/20261101-101134-b2e7f4cb/hud/hud-usability-1920-fresh.hitboxes.tsv'),
 'archived November 1 hitboxes must not be reintroduced')
for _,path in ipairs{
 'resources/textures/wood.png',
 'resources/scenes/printshop-room.png',
 'resources/opponents/merchant.png',
 'resources/ui/menu_manuzio.png',

 'resources/ui/startup_splash/love.png',
 'resources/dice/1.png',
 'resources/models/marble_topped_centre_table.glb',
 'resources/models/old_wooden_table.glb',
 'src/engine3d/g3d/live.lua',
 'src/engine3d/physics.lua',
 'src/farkle/rules.lua',
 'docs/project_vision.md',
} do
 assert(exists(path),'protected production source/asset missing: '..path)
end
-- Three inactive scans stay in Git history at commit 33f8afea35.
for _,path in ipairs{
 'resources/models/aged_alchemical_book_mid_poly.glb',
 'resources/models/de_humani_corporis_fabrica.glb',
 'resources/models/old_roman_coin_ueinbaiva_mid.glb',
} do
 assert(not exists(path),'retired GLB scan reintroduced: '..path)
end
-- Historical texture/prop samples are absent from the live asset map.
-- Source commits: d767b7c8 (wood_floor), 33f8afea (doubloon).
-- Keep the live wood.png and marble table GLB checked above.
for _,path in ipairs{
 'resources/textures/wood_floor.png',
 'resources/models/doubloon.glb',
} do
 assert(not exists(path),'retired unreferenced asset reintroduced: '..path)
end
local f=assert(io.open('.gitignore','rb'))
local ignore=f:read('*a');f:close()
for _,pattern in ipairs{
 '/audits/ui-v2-review/',
 '/audits/windows-qa/',
} do
 assert(ignore:find(pattern,1,true),'missing generated-output ignore: '..pattern)
end
-- The source manifest currently allows 30 modules. Documentation must
-- not lag behind physical-solver additions or claim an FPS native port.
local function read(path)
 local h=assert(io.open(path,'rb'));local s=h:read('*a');h:close()
 return s
end
assert(read('README.md'):find('30 file Lua',1,true),
 'README module count must match source_structure_test (30)')
assert(read('docs/technical.md'):find('src/engine3d/die_collision.lua',1,true),
 'technical map must include the production pair-contact solver')
assert(not ignore:find('\n/audits/\n',1,true),
 'do not hide all future audits: ignore only known generated QA folders')
print('PASS repository housekeeping guard (historical QA retired, production preserved)')
