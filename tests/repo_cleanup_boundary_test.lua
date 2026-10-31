-- The active Farkle edition must never revive retired chromatic-game assets.
-- The old desk loader, palette, optional PNG art pack, and obsolete
-- presentation_view had no production callers at the 2026-10-31 audit.
local removed={
 'src/features/scriptorium/desk_view.lua',
 'src/data/scriptorium_module_config.lua',
 'src/data/colors.lua',
 'src/features/farkle/presentation_view.lua',
 'resources/ui/game.png',
 'resources/ui/splash.png',
 'resources/textures/marble.png',
 'resources/textures/marble2.png',
 'resources/font/UnifrakturMaguntia-Regular.ttf',
 'third_party/OFL_UnifrakturMaguntia.txt',
 'tests/desk_assets_test.lua',
 'tests/retired_desk_assets_test.lua',
 'src/engine3d/render.lua',
 'src/features/farkle/hud_minimal.lua',
 'src/features/farkle/hud.lua',
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
 'src/app/dice_runtime.lua',
 'src/features/farkle/controller.lua',
 'src/features/farkle/ui_v2/hud.lua',
 'src/features/farkle/ui_v2/dialogs.lua',
 'src/features/farkle/ui_v2/accepted_dice.lua',
 'src/features/campaign_select/module.lua',
 'src/features/main_menu/module.lua',
 'src/features/farkle/tray_workshop.lua',
} do
 local s=read(path)
 for _,module in ipairs{
  'src.features.scriptorium.desk_view',
  'src.data.scriptorium_module_config',
  'src.data.colors',
  'src.features.farkle.presentation_view',
 } do
  assert(not s:find(module,1,true),'retired module referenced: '..path)
 end
end
for i=1,5 do
 for _,resolution in ipairs{'1280x720','1920x1080'} do
  for _,state in ipairs{'animated','disabled'} do
   local path=('experiments/fx_lab/audit/effect-%d-%s-%s.png')
       :format(i,resolution,state)
   assert(io.open(path,'rb')==nil,'generated FX snapshot checked in: '..path)
  end
 end
end
local ignore=read('.gitignore')
assert(ignore:find('/experiments/fx_lab/audit/*.png',1,true),
 'reproducible FX screenshots must be ignored')
-- Keep the current physics and authentic D6 textures, not the old painter.
for _,path in ipairs{
 'src/engine3d/physics.lua',
 'src/engine3d/g3d_live.lua',
 'resources/textures/tray/walnut.png',
 'resources/textures/felt.png',
 'resources/dice/1.png',
 'experiments/physics_lab/fpslab.c',
} do
 local f=assert(io.open(path,'rb'),'active engine asset deleted: '..path)
 f:close()
end
print('PASS retired chromatic desk/painter code and generated FX PNGs absent; active Farkle, g3d and physics preserved')
