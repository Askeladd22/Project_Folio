local entry=assert(io.open('main.lua'));local source=entry:read('*a');entry:close()
local chunk,syntax_error=loadfile('main.lua')
assert(chunk,'production entry must compile: '..tostring(syntax_error))
assert(not source:find('experiments',1,true),'production entry uses experimental paths')
assert(source:find('src.farkle.controller',1,true))
for mod in source:gmatch("require%s*%(['\"]([^'\"]+)['\"]%)") do
 local f=assert(io.open(mod:gsub('%.','/')..'.lua'),'missing entry dependency '..mod);f:close()
end
for _,path in ipairs{'src/farkle/rules.lua','src/farkle/controller.lua','src/farkle/interaction.lua','src/farkle/dice.lua','src/farkle/ui.lua','src/farkle/ui.lua','src/farkle/presentation.lua','src/farkle/tabletop.lua','src/engine3d/g3d/scene.lua'} do
 local f=assert(io.open(path));local s=f:read('*a');f:close()
 local compiled,err=loadfile(path)
 assert(compiled,'production module must compile: '..path..': '..tostring(err))
 assert(not s:find('experiments',1,true),path)
end
print('PASS canonical production imports, no experimental aliases')
