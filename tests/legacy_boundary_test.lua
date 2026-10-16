-- Shared drawing modules are allowed; archived operational gameplay is not.
local forbidden={'src.gameplay.run','src.gameplay.folio','src.content','src.core.save_state','src.features.scriptorium.module','src.features.reward','src.features.run','legacy/','legacy.'}
local files={'main.lua','src/app/dice_runtime.lua','src/features/farkle/controller.lua','src/features/main_menu/module.lua','src/features/campaign_select/module.lua','src/features/scriptorium/desk_view.lua','src/features/scriptorium/page_layout.lua'}
for _,path in ipairs(files) do
 local f=assert(io.open(path));local s=f:read('*a');f:close()
 for mod in s:gmatch('require%s*%(?["\']([^"\']+)') do
  for _,prefix in ipairs(forbidden) do assert(mod:sub(1,#prefix)~=prefix,path..' loads '..mod) end
 end
end
print('PASS active/legacy dependency boundary')
