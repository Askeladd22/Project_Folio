-- The active Farkle edition must never revive retired chromatic-game assets.
-- The old desk loader, palette, optional PNG art pack, and obsolete
-- presentation_view had no production callers at the 2026-10-31 audit.
local removed={
 'src/engine3d/light.lua',
 'resources/textures/felt.png',
 'resources/textures/tray/walnut.png',
 'resources/textures/tray/SOURCE.txt',
 'src/features/scriptorium/desk_view.lua',
 'src/data/scriptorium_module_config.lua',
 'src/data/colors.lua',
 'src/farkle/presentation_view.lua',
 'resources/ui/game.png',
 'resources/ui/splash.png',
 'resources/textures/marble.png',
 'resources/textures/marble2.png',
 'resources/font/UnifrakturMaguntia-Regular.ttf',
 'lib/licenses/OFL_UnifrakturMaguntia.txt',
 'tests/desk_assets_test.lua',
 'tests/retired_desk_assets_test.lua',
 'src/engine3d/render.lua',
 'src/farkle/hud_minimal.lua',
 'src/farkle/hud.lua',
 'tests/smoke/compare_huds.lua',
 'resources/ui/bulb.png',
}
local function read(path)
 local f=assert(io.open(path,'rb'),'missing production file: '..path)
 local s=f:read('*a');f:close();return s
end
for _,path in ipairs(removed) do
 local f=io.open(path,'rb')
 assert(not f,'dead dependency was restored without design approval: '..path)
 if f then f:close() end
end
for _,path in ipairs{
 'main.lua',
 'src/core/dice_runtime.lua',
 'src/farkle/controller.lua',
 'src/farkle/ui.lua',
 'src/farkle/ui.lua',
 'src/screens/frontend.lua',
 'src/screens/frontend.lua',
 'src/farkle/tabletop.lua',
} do
 local s=read(path)
 for _,module in ipairs{
  'src.features.scriptorium.desk_view',
  'src.data.scriptorium_module_config',
  'src.data.colors',
  'src.farkle.presentation_view',
 } do
  assert(not s:find(module,1,true),'retired module referenced: '..path)
 end
end
-- Keep the current physics and authentic D6 textures, not the old painter.
for _,path in ipairs{
 'src/engine3d/physics.lua',
 'src/engine3d/g3d/live.lua',
 'resources/textures/wood.png',
 'resources/scenes/printshop-room.png',
 'resources/opponents/merchant.png',
 'resources/dice/1.png',
} do
 local f=assert(io.open(path,'rb'),'active engine asset deleted: '..path)
 f:close()
end
print('PASS retired desk/painter absent; production Farkle, g3d and physics assets preserved')
