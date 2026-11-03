local Background=require('src.core.menu_background')
local Main=require('src.data.main_menu_schema')
local Campaign=require('src.data.campaign_select_schema')
local Settings=require('src.data.settings_ui_schema')
local expect="resources/ui/menu_illustrated.png"
local old="resources/ui/menu.png"
for _,schema in ipairs({Main,Campaign,Settings}) do
 assert(schema.assets.illustrated_background_path==expect)
 assert(schema.assets.background_path==old)
end
local previousLove=love
local attempted={}
local present={[expect]=true,[old]=true}
love={
 filesystem={getInfo=function(path) return present[path] and {type="file"} or nil end},
 graphics={newImage=function(path)
  attempted[#attempted+1]=path
  return {path=path,getWidth=function()return 1920 end,
      getHeight=function()return 1080 end}
 end},
}
local img,path=Background.load(expect,old)
assert(path==expect and img.path==expect,'illustrated image must take priority')
assert(#attempted==1,'fallback was loaded unnecessarily')
present[expect]=false
attempted={}
img,path=Background.load(expect,old)
assert(path==old and img.path==old and #attempted==1)
present[expect]=true
love.graphics.newImage=function(path)
 attempted[#attempted+1]=path
 if path==expect then error('corrupt optional image') end
 return {path=path}
end
attempted={}
img,path=Background.load(expect,old)
assert(path==old and #attempted==2,'corrupt image must fall back')
present[old]=false
img,path=Background.load(expect,old)
assert(img==nil and path==nil,'no assets should return nil')
love={}
assert(Background.load(expect,old)==nil,'no LÖVE API must be safe')
love=previousLove
for _,p in ipairs({
 'src/features/main_menu/module.lua',
 'src/features/campaign_select/module.lua',
 'src/features/settings/module.lua',
}) do
 local f=assert(io.open(p,'rb'));local source=f:read('*a');f:close()
 assert(source:find('src.core.menu_background',1,true),
  'frontend omitted shared illustration loader: '..p)
 assert(source:find('MenuBackground.load(ILLUSTRATED_BG_PATH, MENU_BG_PATH)',1,true),
  'frontend must retain fallback: '..p)
end
print('PASS optional illustrated menu background, fallback and frontend continuity')
