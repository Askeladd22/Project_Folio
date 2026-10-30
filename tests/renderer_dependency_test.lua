-- Prevent accidental deletion of an active renderer before parity is proven.
local function read(path)
 local f=assert(io.open(path,'rb'),'missing '..path)
 local s=f:read('*a');f:close();return s
end
local r=read('src/engine3d/render.lua')
local runtime=read('src/app/dice_runtime.lua')
local workshop=read('src/features/farkle/tray_workshop.lua')
local hud=read('src/features/farkle/hud_minimal.lua')
local lab=read('experiments/g3d_lab/main.lua')
assert(r:find('function render.die',1,true) and r:find('function render.tray_border',1,true))
assert(runtime:find('require("src.engine3d.render")',1,true),'runtime still has painter dependencies')
assert(runtime:find('render.paint()',1,true),'runtime must keep visible fallback while g3d is partial')
assert(workshop:find('render.tray_border',1,true),'F8 layouts still use legacy borders')
assert(hud:find('render.die',1,true),'HUD-related legacy rendering is still active')
assert(lab:find("require('src.engine3d.render')",1,true),'historical A/B reference still needed')
assert(not runtime:find("experiments.physics_lab.fps",1,true),'native FPS must not be loaded by game')
print('PASS renderer retirement audit: legacy is still referenced, FPS isolated')
