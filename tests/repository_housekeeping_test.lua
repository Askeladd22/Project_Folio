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
 'resources/textures/tray/walnut.png',
 'resources/ui/menu_manuzio.png',
 'resources/ui/menu.png',
 'resources/ui/startup_splash/love.png',
 'resources/dice/1.png',
 'src/engine3d/g3d_live.lua',
 'src/engine3d/physics.lua',
 'src/gameplay/farkle/rules.lua',
 'docs/PROJECT_VISION.md',
} do
 assert(exists(path),'protected production source/asset missing: '..path)
end
local f=assert(io.open('.gitignore','rb'))
local ignore=f:read('*a');f:close()
for _,pattern in ipairs{
 '/audits/ui-v2-review/',
 '/audits/windows-qa/',
 '/experiments/physics_lab/build/',
 '/experiments/g3d_lab/build/',
} do
 assert(ignore:find(pattern,1,true),'missing generated-output ignore: '..pattern)
end
print('PASS repository housekeeping guard (historical QA retired, production preserved)')
