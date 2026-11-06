-- The shipped typeface is Roman Antiqua, shared by all user-facing menus.
local font='resources/font/GoudyBookletter1911.ttf'
local file=assert(io.open(font,'rb'),'Antiqua font missing')
local magic=file:read(4);file:close()
assert(magic==string.char(0,1,0,0) or magic=='OTTO','invalid TTF/OTF signature')
local schemas={'src/data/main_menu_schema.lua','src/data/settings_ui_schema.lua',
 'src/data/campaign_select_schema.lua','src/data/startup_splash_schema.lua'}
local gameplay={'src/features/farkle/ui_v2/hud.lua','src/features/farkle/ui_v2/dialogs.lua',
 'src/features/farkle/ui_v2/accepted_dice.lua','src/features/farkle/folio_view.lua',
 'src/features/farkle/toast_messages.lua'}
for _,path in ipairs(schemas) do
 local f=assert(io.open(path,'rb'));local code=f:read('*a');f:close()
 assert(code:find(font,1,true),path..' not using Antiqua')
 assert(not code:find('ManuskriptGothisch',1,true),path..' still uses blackletter')
end
for _,path in ipairs(gameplay) do
 local f=assert(io.open(path,'rb'));local code=f:read('*a');f:close()
 assert(code:find(font,1,true),path..' not using Antiqua')
end
local f=assert(io.open('src/features/main_menu/module.lua','rb'))
local menu=f:read('*a');f:close()
assert(menu:find('fonts.subtitle = load_font({FONT_TEXT, FONT_FALLBACK}',1,true))
assert(menu:find('fonts.footer = load_font({FONT_TEXT, FONT_FALLBACK}',1,true))
print('PASS Roman Antiqua across menus, gameplay HUD and actual font file')
