-- Project Folio 0.1.35: facsimile Aldine Roman and per-glyph Cardo support.
local T=require('src.core.presentation').typography
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
local frontend=require('src.data.frontend_schema')
local settings=require('src.data.frontend_schema').settings
local schemas={
 {name='menu',assets=frontend.menu.assets,primary='font_text',support='font_fallback'},
 {name='settings',assets=settings.assets,primary='font_text',support='font_fallback'},
 {name='campaign',assets=frontend.campaign.assets,primary='font_text',support='font_fallback'},
 {name='splash',assets=frontend.splash.assets,primary='title_font_primary',support='title_font_fallback'},
}
for _,schema in ipairs(schemas) do
 assert(schema.assets[schema.primary]==primary and schema.assets[schema.support]==support,
  'primary and fallback fonts must be explicitly configured: '..schema.name)
end
for _,path in ipairs{'src/data/frontend_schema.lua','src/data/frontend_schema.lua'} do
 local code=read(path)
 assert(not code:find('ManuskriptGothisch',1,true),
  'no gothic font in a production schema: '..path)
end
local modules={'src/screens/frontend.lua',
 'src/screens/frontend.lua','src/screens/frontend.lua',
 'src/screens/startup_splash.lua',
 'src/farkle/ui.lua','src/farkle/ui.lua',
 'src/farkle/presentation.lua',
 'src/farkle/presentation.lua'}
for _,path in ipairs(modules) do
 local code=read(path)
 assert(code:find('src.core.presentation',1,true) and
  code:find('Typography.load(',1,true),
  'module must use the shared glyph-aware loader: '..path)
 assert(not code:find('GoudyBookletter1911.ttf',1,true),
  'old primary font must not remain in a production view: '..path)
end
local hud=read('src/farkle/ui.lua')
local register=assert(hud:match('%-%- Accepted dice register(.-)%-%- Table HUD'))
local table_hud=assert(hud:match('%-%- Table HUD(.*)'))
for name,section in pairs{register=register,hud=table_hud} do
 assert(section:find('src.core.presentation',1,true) and section:find('Typography.load(',1,true),
  'HUD section must use the shared glyph-aware loader: '..name)
end
local menu=read('src/screens/frontend.lua')
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
