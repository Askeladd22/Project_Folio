-- Headless geometry and visual-contract tests for the ONE parchment frontend.
-- Screenshot-level Windows QA is still needed. No real graphics or font files.
local Surface=require('src.features.ui_v2.menu_surface')
local oldLove=love
local resolution={1920,1080}
local drawings={push=0,pop=0,fill=0,line=0,diamond=0}
local function font(size)
 size=type(size)=='number' and size or 20
 return {getHeight=function()return math.floor(size*1.12)end,
   getWidth=function(_,s)return #tostring(s)*size*.57 end,
   getWrap=function(_,s) return #tostring(s)*size*.57,{s} end}
end
local g={
 getWidth=function()return resolution[1] end,
 getHeight=function()return resolution[2] end,
 getDimensions=function()return resolution[1],resolution[2] end,
 getFont=function()return font(20)end,
 newFont=function(a,b)return font(b or a)end,
 push=function()drawings.push=drawings.push+1 end,
 pop=function()drawings.pop=drawings.pop+1 end,
 setColor=function()end,
 rectangle=function(mode)drawings[mode]=drawings[mode]+1 end,
 line=function()end,setLineWidth=function()end,
 polygon=function()drawings.diamond=drawings.diamond+1 end,
}
love={graphics=g,filesystem={getInfo=function()return false end}}
local function get_upvalue(f,name)
 for i=1,100 do
  local n,v=debug.getupvalue(f,i)
  if not n then break end
  if n==name then return v end
 end
 error('missing '..name)
end
local Main=require('src.features.main_menu.module')
local Campaign=require('src.features.campaign_select.module')
local build_main=get_upvalue(Main.draw,'compute_layout')
local build_campaign=get_upvalue(Campaign.draw,'build_layout')
local campaigns=require('src.data.commission_menu')
for i=1,70 do
 local name=debug.getupvalue(build_campaign,i)
 if name=='campaigns' then debug.setupvalue(build_campaign,i,campaigns);break end
end
local function inside(outer,inner)
 return Surface.contains(outer,inner.x,inner.y) and
   Surface.contains(outer,inner.x+inner.w,inner.y+inner.h)
end
for _,size in ipairs{{1920,1080},{1280,720},{2560,1440}} do
 resolution=size
 local w,h=size[1],size[2]
 local m=build_main(w,h)
 assert(Surface.within(m.frame,w,h),'menu page outside viewport')
 assert(#m.item_rects==6,'must not discard any menu item')
 assert(inside(m.frame,m.mute_rect),'music mute outside folio page')
 for i,item in ipairs(m.item_rects) do
  assert(Surface.within(item,w,h),'menu action outside viewport')
  assert(inside(m.frame,item),'menu action outside parchment')
  if i>1 then
   assert(item.y>=m.item_rects[i-1].y+m.item_rects[i-1].h,
    'main actions overlap')
  end
 end
 assert(m.footer_y>m.item_rects[6].y+m.item_rects[6].h-1)
 local c=build_campaign()
 assert(Surface.within(c.frame,w,h),'commission page outside viewport')
 assert(#c.items==#campaigns+1,'only valid campaigns and Back')
 for i,item in ipairs(c.items) do
  assert(inside(c.frame,item),'campaign action outside page')
  assert(Surface.within(item,w,h))
  if i>1 then
   assert(item.y>=c.items[i-1].y+c.items[i-1].h,
    'commission rows overlap')
  end
 end
 Surface.backdrop(w,h,false,1)
 Surface.panel(m.frame,{high_contrast=false})
 Surface.panel(c.frame,{high_contrast=true})
 Surface.rule(m.menu_x,m.divider_y,m.menu_w,1)
 Surface.item(m.item_rects[1],{active=true,primary=true})
 Surface.item(c.items[1],{disabled=true})
end
assert(drawings.push==drawings.pop,'shared menu surfaces leaked graphics state')
assert(drawings.fill>20 and drawings.line>15 and drawings.diamond>0)
local module_paths={
 'src/features/main_menu/module.lua',
 'src/features/campaign_select/module.lua',
 'src/features/farkle/ui_v2/dialogs.lua'
}
for _,path in ipairs(module_paths) do
 local f=assert(io.open(path,'rb'));local source=f:read('*a');f:close()
 assert(source:find('src.features.ui_v2.menu_surface',1,true),
  'front-facing page is not on the shared manuscript theme: '..path)
 assert(not source:find("MANUSCRIPT_UI_V2_EXPERIMENT",1,true))
 assert(not source:find("hud_minimal",1,true))
end
local function read(path)
 local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s
end
local a=read('src/features/main_menu/module.lua')
local c=read('src/features/campaign_select/module.lua')
for _,obsolete in ipairs{"w * 0.52","w * 0.24","h * 0.16","h * 0.84"} do
 assert(not a:find(obsolete,1,true) and not c:find(obsolete,1,true),
  'legacy black letterbox overlay returned: '..obsolete)
end
assert(a:find("MainMenu:activate",1,true))
assert(c:find("start_campaign(campaign.id)",1,true))
love=oldLove
print('PASS unified parchment frontend: all six menu actions, Back, mute and card bounds at 720p/1080p/1440p')
