local entry=assert(io.open('main.lua'));local source=entry:read('*a');entry:close()
assert(not source:find('experiments',1,true),'production entry uses experimental paths')
assert(source:find('src.features.farkle.controller',1,true))
for mod in source:gmatch("require%s*%(['\"]([^'\"]+)['\"]%)") do
 local f=assert(io.open(mod:gsub('%.','/')..'.lua'),'missing entry dependency '..mod);f:close()
end
for _,path in ipairs{'src/gameplay/farkle/rules.lua','src/gameplay/farkle/scoring.lua','src/features/farkle/controller.lua','src/features/farkle/dice.lua','src/features/farkle/hud.lua','src/features/farkle/hud_model.lua','src/features/farkle/tray_view.lua'} do
 local f=assert(io.open(path));local s=f:read('*a');f:close()
 assert(not s:find('experiments',1,true),path)
end
print('PASS canonical production imports, no experimental aliases')
