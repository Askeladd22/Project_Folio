-- 0.1.0-dev.9: only Project Folio SETTINGS adopt the parchment style.
-- LOVE's pink/blue heart engine splash is deliberately preserved.
-- Headless geometry and drawing-contract test for 720p/1080p/1440p.
local Surface=require('src.features.ui_v2.menu_surface')
local Schema=require('src.data.settings_schema')
local Theme=require('src.data.settings_ui_schema')
local SplashSpec=require('src.data.startup_splash_schema')
local oldLove=love
local width,height=1920,1080
local calls={push=0,pop=0,rect=0}
local function fake_font(size)
 size=type(size)=='number' and size or 22
 return {
  getHeight=function()return math.floor(size*1.12)end,
  getWidth=function(_,s)return #tostring(s)*size*.56 end,
  getWrap=function(_,s)return #tostring(s)*size*.56,{s}end,
 }
end
love={
 graphics=setmetatable({
  getWidth=function()return width end,
  getHeight=function()return height end,
  getDimensions=function()return width,height end,
  getFont=function()return fake_font(20)end,
  newFont=function(a,b)return fake_font(b or a)end,
  push=function()calls.push=calls.push+1 end,
  pop=function()calls.pop=calls.pop+1 end,
  rectangle=function()calls.rect=calls.rect+1 end,
 },{__index=function()return function()end end}),
 filesystem={getInfo=function()return nil end}
}
local Settings=require('src.features.settings.module')
local function up(f,name)
 for i=1,120 do
  local n,v=debug.getupvalue(f,i)
  if n==name then return v,i end
  if n==nil then break end
 end
 error('missing upvalue '..name)
end
local build=up(Settings.draw,'build_layout')
local ensure=up(Settings.draw,'ensure_assets')
local get_tab=up(build,'get_active_tab')
local function set(f,name,value)
 local _,index=up(f,name)
 assert(debug.setupvalue(f,index,value)==name)
end
local function inside(outer,rect)
 return Surface.contains(outer,rect.x,rect.y) and
  Surface.contains(outer,rect.x+rect.w,rect.y+rect.h)
end
assert(#Schema.tabs==5 and #Schema.actions==3)
assert(Theme.text.branding_title.default=='Project Folio')
for _,size in ipairs{{1280,720},{1920,1080},{2560,1440}} do
 width,height=size[1],size[2]
 ensure()
 set(build,'view_mode','sections')
 local page=build()
 assert(Surface.within(page.frame,width,height))
 assert(#page.section_items==#Schema.tabs+1)
 assert(inside(page.frame,page.section_items[1]))
 for i,rect in ipairs(page.section_items) do
  assert(Surface.within(rect,width,height))
  assert(inside(page.frame,rect),'section outside manuscript page')
  if i>1 then
   local last=page.section_items[i-1]
   assert(rect.y>=last.y+last.h,'sections overlap')
  end
 end
 Settings:draw()
 for tab_index,tab in ipairs(Schema.tabs) do
  set(build,'view_mode','content')
  set(get_tab,'selected_tab',tab_index)
  local current=build()
  assert(Surface.within(current.frame,width,height))
  assert(#current.controls==#tab.controls)
  assert(#current.actions==#Schema.actions)
  local previous=nil
  for _,rect in ipairs(current.controls) do
   assert(inside(current.frame,rect),'setting outside page')
   if previous then assert(rect.y>=previous.y+previous.h,'controls overlap') end
   previous=rect
   if rect.slider_rect then
    assert(inside(rect,rect.slider_rect),'slider outside control hitbox')
   end
  end
  for _,rect in ipairs(current.actions) do
   assert(inside(current.frame,rect),'button outside manuscript')
   if previous then assert(rect.y>=previous.y+previous.h,'action overlaps setting') end
   previous=rect
  end
  Settings:draw()
 end
end
assert(calls.push==calls.pop,'parchment graphics stack leaked')
assert(calls.rect>40,'settings folio not drawn')
local function source(path)
 local f=assert(io.open(path,'rb'))
 local s=f:read('*a');f:close();return s
end
local settings=source('src/features/settings/module.lua')
assert(settings:find('src.features.ui_v2.menu_surface',1,true))
assert(not settings:find('w * 0.52',1,true))
assert(not settings:find('h * 0.84',1,true))
assert(settings:find('SettingsState.save()',1,true))
assert(settings:find('apply_live_audio_preview()',1,true))
-- LOVE is a separate engine intro, not an obsolete branding to delete.
local splash=source('src/features/startup_splash/module.lua')
assert(splash:find('drawSplitBackground()',1,true))
assert(splash:find('drawHeartFallback(',1,true))
assert(splash:find('heartImage',1,true))
assert(splash:find('function Splash:keypressed(',1,true))
assert(splash:find('function Splash:mousepressed(',1,true))
assert(SplashSpec.colors.pink and SplashSpec.colors.blue)
assert(SplashSpec.assets.image_heart_path)
assert(SplashSpec.assets.shader_fill_path)
love=oldLove
print('PASS Settings parchment layout at 720p/1080p/1440p; original LOVE engine heart splash preserved')
