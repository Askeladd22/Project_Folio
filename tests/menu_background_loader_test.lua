local Background=require('src.core.menu_background')
local Main=require('src.data.main_menu_schema')
local Campaign=require('src.data.campaign_select_schema')
local Settings=require('src.data.settings_ui_schema')
local manuzio="resources/ui/menu_manuzio.png"
local expect="resources/ui/menu_illustrated.png"
local old="resources/ui/menu.png"
for _,schema in ipairs({Main,Campaign,Settings}) do
 assert(schema.assets.manuzio_background_path==manuzio)
 assert(schema.assets.illustrated_background_path==expect)
 assert(schema.assets.background_path==old)
end
local previousLove=love
local attempted={}
local present={[manuzio]=true,[expect]=true,[old]=true}
love={
 filesystem={getInfo=function(path) return present[path] and {type="file"} or nil end},
 graphics={newImage=function(path)
  attempted[#attempted+1]=path
  return {path=path,getWidth=function()return 1920 end,
      getHeight=function()return 1080 end}
 end},
}
local img,path=Background.load(manuzio,expect,old)
assert(path==manuzio and img.path==manuzio,
 'Venetian printing workshop must take priority')
assert(#attempted==1,'fallback was loaded unnecessarily')
present[manuzio]=false
attempted={}
img,path=Background.load(manuzio,expect,old)
assert(path==expect and img.path==expect and #attempted==1,
 'preexisting authored asset must remain a fallback')
present[expect]=false
attempted={}
img,path=Background.load(manuzio,expect,old)
assert(path==old and img.path==old and #attempted==1,
 'legacy photo remains the last fallback')
present[manuzio]=true
present[expect]=true
love.graphics.newImage=function(path)
 attempted[#attempted+1]=path
 if path==manuzio then error('damaged new image') end
 return {path=path}
end
attempted={}
img,path=Background.load(manuzio,expect,old)
assert(path==expect and #attempted==2,
 'corrupt Manuzio PNG must fall back to older image')
present[expect]=false
present[old]=false
attempted={}
img,path=Background.load(manuzio,expect,old)
assert(img==nil and path==nil,'missing all candidates should be safe')
love={}
assert(Background.load(manuzio,expect,old)==nil,'no LÖVE API must be safe')
-- Validate exact responsive cover framing without a GPU dependency.
local image={getWidth=function()return 1920 end,
             getHeight=function()return 1080 end}
for _,size in ipairs{{1280,720},{1920,1080},{2560,1440},{3440,1440}} do
 local w,h=size[1],size[2]
 local x,y,scale=Background.cover_rect(image,w,h,true)
 assert(x==0,'16:9 and ultrawide preserve left blank area')
 assert(scale*1920>=w and scale*1080>=h)
 local left=math.max(math.max(12,math.floor(h*.038)),math.floor(w*.045))
 local width=Background.left_panel_limit(image,w,h,left)
 assert(width>275,'illustration leaves insufficient UI width')
 assert(left+width < image:getWidth()*.325*scale,
  'interactive page intrudes on workshop focal point')
end
local centered=Background.cover_rect(image,1024,768,false)
local anchored=Background.cover_rect(image,1024,768,true)
assert(centered < -100 and anchored==0,
 '4:3 crop must preserve the illustrated UI zone')
assert(Background.left_panel_limit(image,1024,768,46)>275)
assert(Background.cover_rect(nil,1920,1080,true)==nil)
love=previousLove
for _,p in ipairs({
 'src/features/main_menu/module.lua',
 'src/features/campaign_select/module.lua',
 'src/features/settings/module.lua',
}) do
 local f=assert(io.open(p,'rb'));local source=f:read('*a');f:close()
 assert(source:find('src.core.menu_background',1,true),
  'frontend omitted shared illustration loader: '..p)
 assert(source:find('MenuBackground.load(MANUZIO_BG_PATH, ILLUSTRATED_BG_PATH, MENU_BG_PATH)',1,true),
  'frontend must retain fallback: '..p)
end
print('PASS optional illustrated menu background, fallback and frontend continuity')
