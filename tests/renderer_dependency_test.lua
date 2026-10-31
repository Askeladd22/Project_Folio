-- Regression gate: g3d is the only renderer of the physical tray.
local function read(path)
 local f=assert(io.open(path,'rb'),'missing '..path)
 local s=f:read('*a');f:close();return s
end
assert(io.open('src/engine3d/render.lua','rb')==nil,
 'CPU painter source must not be kept as fallback')
for _,path in ipairs{
 'src/app/dice_runtime.lua',
 'src/features/farkle/ui_v2/hud.lua',
 'src/features/farkle/tray_workshop.lua',
 'src/features/farkle/tray_view.lua',
 'experiments/g3d_lab/main.lua',
} do
 local s=read(path)
 assert(not s:find('src.engine3d.render',1,true),path..' imports retired painter')
 assert(not s:find('render.paint()',1,true),path..' draws with retired painter')
end
local runtime=read('src/app/dice_runtime.lua')
assert(not runtime:find('light.plastic',1,true),
 'deleted CPU painter light must not be used during real g3d startup')
assert(not runtime:find('material = die_material',1,true),
 'deleted painter-only material field must not return to g3d spawn')
assert(runtime:find('live_g3d:draw({',1,true))
assert(not runtime:find("key=='f9'",1,true))
assert(not runtime:find('draw_legacy_floor',1,true))
assert(not runtime:find("MANUSCRIPT_RENDERER",1,true))
assert(not runtime:find("MANUSCRIPT_G3D_INGAME",1,true))
assert(not runtime:find('experiments.physics_lab.fps',1,true))
local live=read('src/engine3d/g3d_live.lua')
assert(live:find('self:_draw_scene(args)',1,true))
assert(not live:find('reverting to legacy',1,true))
assert(not live:find('function M:toggle()',1,true))
local workshop=read('src/features/farkle/tray_workshop.lua')
assert(workshop:find('function W.cycle()',1,true))
assert(not workshop:find('function W.floor(',1,true))
assert(not workshop:find('function W.border(',1,true))
local hud=read('src/features/farkle/ui_v2/hud.lua')
local shelf=read('src/features/farkle/ui_v2/accepted_dice.lua')
assert(not hud:find('hud_minimal',1,true))
assert(shelf:find('src.engine3d.g3d_portrait',1,true))
assert(not shelf:find('local function snapshot(',1,true))
print('PASS g3d sole renderer: no F9, CPU painter, legacy HUD fallback, or FPS production')
