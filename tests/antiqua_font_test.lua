-- Project Folio 0.1.35: facsimile Aldine Roman and per-glyph Cardo support.
local T=require('src.core.typography')
local primary='resources/font/AldineAetna-Regular.ttf'
local support='resources/font/Cardo-Regular.ttf'
assert(T.primary==primary and T.support==support)
local function read(path)
 local f=assert(io.open(path,'rb'),'missing '..path)
 local data=f:read('*a');f:close()
 return data
end
for _,path in ipairs({primary,support}) do
 local data=read(path)
 assert(#data>20000,'font binary unexpectedly small: '..path)
 assert(data:sub(1,4)==string.char(0,1,0,0) or data:sub(1,4)=='OTTO',
  'font must be a valid TrueType/OpenType file: '..path)
end
assert(read('resources/font/LICENSE-AldineAetna.txt'):find('CC0',1,true))
assert(read('resources/font/OFL-Cardo.txt'):find('SIL OPEN FONT LICENSE',1,true))
local schemas={'src/data/main_menu_schema.lua','src/data/settings_ui_schema.lua',
 'src/data/campaign_select_schema.lua','src/data/startup_splash_schema.lua'}
for _,path in ipairs(schemas) do
 local code=read(path)
 assert(code:find(primary,1,true) and code:find(support,1,true),
  'primary and fallback fonts must be explicitly configured: '..path)
 assert(not code:find('ManuskriptGothisch',1,true),
  'no gothic font in a production schema: '..path)
end
local modules={'src/features/main_menu/module.lua',
 'src/features/campaign_select/module.lua','src/features/settings/module.lua',
 'src/features/startup_splash/module.lua',
 'src/features/farkle/ui_v2/hud.lua','src/features/farkle/ui_v2/dialogs.lua',
 'src/features/farkle/ui_v2/accepted_dice.lua','src/features/farkle/folio_view.lua',
 'src/features/farkle/toast_messages.lua'}
for _,path in ipairs(modules) do
 local code=read(path)
 assert(code:find('src.core.typography',1,true) and
  code:find('Typography.load(',1,true),
  'module must use the shared glyph-aware loader: '..path)
 assert(not code:find('GoudyBookletter1911.ttf',1,true),
  'old primary font must not remain in a production view: '..path)
end
local menu=read('src/features/main_menu/module.lua')
assert(menu:find('fonts.subtitle = load_font({FONT_TEXT, FONT_FALLBACK}',1,true))
assert(menu:find('fonts.footer = load_font({FONT_TEXT, FONT_FALLBACK}',1,true))

-- Test actual loader sequencing without the graphical LÖVE runtime.
local oldLove=love
local calls={}
love={graphics={newFont=function(path,size)
 calls[#calls+1]={path=path,size=size}
 return {path=path,size=size,
   setFallbacks=function(self,other)
    self.fallback=other
   end}
end}}
local title=T.load(primary,26)
assert(#calls==2 and calls[1].path==primary and calls[2].path==support and
 calls[1].size==26 and calls[2].size==26 and title.fallback and
 title.fallback.path==support,
 'Aldine must attach Cardo with Font:setFallbacks at the SAME font size')
local alternate=T.load(support,15)
assert(#calls==3 and alternate.path==support and not alternate.fallback,
 'Cardo may load directly when the primary font itself is unavailable')
love=oldLove
print('PASS Aldine Aetna primary, Cardo Roman per-glyph fallback, fonts, licences and UI coverage')
