-- Headless geometry and visual-contract tests for the ONE parchment frontend.
-- Screenshot-level Windows QA is still needed. No real graphics or font files.
local Surface=require('src.screens.folio_surface').menu_surface
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
local Main=require('src.screens.frontend').main_menu
local build_main=get_upvalue(Main.draw,'compute_layout')
local mainSchema=require('src.data.frontend_schema').menu
local expected=#mainSchema.menu_items
assert(expected>=2)
local function inside(outer,inner)
 return Surface.contains(outer,inner.x,inner.y) and
  Surface.contains(outer,inner.x+inner.w,inner.y+inner.h)
end
for _,size in ipairs{{1920,1080},{1280,720},{2560,1440}} do
 resolution=size
 local w,h=size[1],size[2]
 local m=build_main(w,h)
 assert(Surface.within(m.frame,w,h),'menu page outside viewport')
 assert(#m.item_rects==expected,'schema and visible actions differ')
 assert(inside(m.frame,m.mute_rect),'mute outside paper page')
 for i,item in ipairs(m.item_rects) do
  assert(Surface.within(item,w,h) and inside(m.frame,item))
  if i>1 then assert(item.y>=m.item_rects[i-1].y+m.item_rects[i-1].h,
    'menu actions overlap') end
 end
 assert(m.footer_y>m.item_rects[#m.item_rects].y+
  m.item_rects[#m.item_rects].h-1)
 Surface.backdrop(w,h,false,1)
 Surface.panel(m.frame,{high_contrast=false,style="editorial"})
 local prior=drawings.diamond
 Surface.rule(m.menu_x,m.divider_y,m.menu_w,1,{quiet=true})
 assert(drawings.diamond==prior,'main menu must not add gold ornament')
 Surface.item(m.item_rects[2],{active=true,primary=true,style="editorial"})
 Surface.item(m.item_rects[1],{disabled=true,style="editorial"})
end
assert(drawings.push==drawings.pop,'menu surface leaks graphics state')
assert(drawings.fill>10 and drawings.line>=3 and drawings.diamond==0)
local function read(path)
 local file=assert(io.open(path,'rb'))
 local source=file:read('*a');file:close();return source
end
for _,path in ipairs{'src/screens/frontend.lua','src/farkle/ui.lua'} do
 local source=read(path)
 assert(source:find('src.screens.folio_surface',1,true),
  'not using manuscript surfaces: '..path)
 assert(not source:find('MANUSCRIPT_UI_V2_EXPERIMENT',1,true))
 assert(not source:find('hud_minimal',1,true))
end
local frontend=read('src/screens/frontend.lua')
local a=assert(frontend:match('Bundle%.main_menu = %(function%(%)(.-)Bundle%.settings ='))
assert(a:find('style="editorial"',1,true))
assert(a:find('title_x = cached_layout.menu_x',1,true))
assert(a:find("MainMenu:activate",1,true))
assert(not frontend:find('Bundle.campaign_select',1,true))
local wishlist
for _,item in ipairs(mainSchema.menu_items) do
 if item.id=='wishlist' then wishlist=item.label.default end
end
assert(wishlist=='Wishlist')
for _,obsolete in ipairs{'w * 0.52','w * 0.24','h * 0.16','h * 0.84'} do
 assert(not a:find(obsolete,1,true),'legacy letterbox returned: '..obsolete)
end
love=oldLove
print('PASS single-entry parchment menu geometry and actions at 720p/1080p/1440p')
