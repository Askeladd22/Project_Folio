-- Protect the removal of the obsolete 8-layer desk art pack.
local cfg=require('src.data.scriptorium_module_config')
assert(type(cfg.desk_assets)=='table' and next(cfg.desk_assets)==nil,
 'runtime must not reference obsolete desk PNGs')
local function read(path)
 local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s
end
local view=read('src/features/scriptorium/desk_view.lua')
assert(view:find('fallback()',1,true),
 'procedural Scriptorium background/panels must remain available')
local f=io.open('resources/ui/desk/background.png','rb')
assert(not f,'removed desk art unexpectedly reintroduced')
print('PASS desk prototype art retired; procedural fallback available')
