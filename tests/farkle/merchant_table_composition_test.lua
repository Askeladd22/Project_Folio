-- Headless structural QA for the table wager, footer and true D6 size.
local Layout=require('src.farkle.ui').layout
local L=Layout.build()
assert(Layout.validate(L))
for _,r in ipairs{L.secured_caption,L.secured_value,L.risk_caption,L.risk_value,
                   L.objective_caption,L.objective_value,L.turns_caption,L.turns_value} do
 assert(Layout.contains(L.score_panel,r),'score metric detached from shared card')
 assert(Layout.overlap(L.tray,r)==0,'score metric obscures a real D6')
end
assert(L.risk_value.x>L.secured_value.x)
assert(L.footer.y>=L.tray.y+L.tray.h and
 L.footer.h<=110 and L.footer.w<=1160,
 'footer must be a compact plaque instead of a full-width slab')
-- Regression against the visible 0.1.27 offset: footer center was
-- x=1007 and primary launch button center x=1004 (vs tray x=960).
local axis=L.tray.x+L.tray.w/2
for _,r in ipairs{L.footer,L.footer_trim,L.single_action,L.idle_message,
                  L.message} do
 assert(math.abs(r.x+r.w/2-axis)<=3,
  'command row must be centered on the real 3D tray')
end
assert(math.abs((L.context_actions[1].x+L.secondary.x+L.secondary.w)/2-axis)<=3,
 'multi-button composition must be centered as a group')
assert(Layout.overlap(L.shelf,L.footer)==0,
 'accepted dice must not collide with shifted command plaque')
for _,r in ipairs{L.shelf,L.primary,L.secondary,L.single_action,L.message,L.idle_message} do
 assert(Layout.overlap(L.tray,r)==0,'action obstructs physical D6 viewport')
end
assert(Layout.overlap(L.context_actions[1],L.idle_message)==0,
 'the ready instruction must stay readable beside an equipped medal')
assert(Layout.overlap(L.primary,L.secondary)==0)
local file=assert(io.open('src/core/dice_runtime.lua','rb'))
local code=file:read('*a');file:close()
local value=tonumber(assert(code:match('local TABLE_DIE_SCALE = ([%d%.]+)')))
assert(value>.85 and value<=1,'D6 enlargement must be modest and physical')
assert(code:find('body_factory(spawn_dice_size * TABLE_DIE_SCALE)',1,true),
 'renderer and collision geometry must derive from the same physical size')
local Res=require('src.core.navigation').resolution
for _,wh in ipairs{{1920,1080},{1280,720},{2560,1440},{3440,1440}} do
 Res.init(1920,1080);Res.refresh(wh[1],wh[2])
 local vp=Res.get_viewport()
 for _,r in ipairs{L.score_panel,L.footer,L.footer_trim,
                         L.primary,L.single_action,L.secondary} do
  local q=Layout.screen_rect(r,{x=vp.x,y=vp.y,scale=Res.get_scale()})
  assert(q.x>=0 and q.y>=0 and q.x+q.w<=wh[1]+1 and q.y+q.h<=wh[2]+1)
  if r==L.footer or r==L.single_action then
   assert(math.abs(q.x+q.w*.5-(vp.x+axis*Res.get_scale()))<=3,
    'screen-space table controls must share center after viewport scaling')
  end
  local x,y=Res.to_screen(r.x+r.w/2,r.y+r.h/2)
  local vx,vy=Res.to_virtual(x,y)
  assert(math.abs(vx-(r.x+r.w/2))<1e-6 and math.abs(vy-(r.y+r.h/2))<1e-6)
 end
end
-- Even with letterbox or pillarbox space, the actual room art must reach
-- all four physical edges. The central illustration stays in proportion.
local images={}
local function image(w,h)
 return {getWidth=function() return w end,getHeight=function() return h end}
end
local font={getWidth=function(_,s) return #s*8 end,getHeight=function() return 16 end}
love={graphics=setmetatable({
 newImage=function() return image(1920,1080) end,newFont=function() return font end,
 newQuad=function(x,y,w,h) return {width=w,height=h} end,
 draw=function(im,q,x,y,angle,sx,sy)
  local w,h=im:getWidth(),im:getHeight()
  if type(q)=='number' then q,x,y,angle,sx,sy=nil,q,x,y,angle,sx end
  if q then w,h=q.width,q.height end
  local x2,y2=x+w*(sx or 1),y+h*(sy or 1)
  images[#images+1]={x=math.min(x,x2),y=math.min(y,y2),w=math.abs(x2-x),h=math.abs(y2-y),
   sx=math.abs(sx or 1),sy=math.abs(sy or 1)}
 end,
},{__index=function() return function() end end})}
local Hud=require('src.farkle.ui').hud
local game=require('src.farkle.rules').new()
for _,wh in ipairs{{1920,1080},{3440,1440},{1280,1024}} do
 Res.refresh(wh[1],wh[2]); images={}
 Hud.draw({game=game,minimalHud=true})
 local expected=0
 for _,r in ipairs(images) do
  expected=expected+r.w*r.h
  if r.w==1920 and r.h==1080 then
   assert(r.x==0 and r.y==0 and math.abs(r.sx-r.sy)<1e-7,'the room must keep its perspective')
  end
 end
 local vx,vy=Res.to_virtual(0,0)
 local xmax,ymax=Res.to_virtual(wh[1],wh[2])
 for _,p in ipairs{{vx,vy},{vx,ymax},{xmax,vy},{xmax,ymax},{960,540}} do
  local covered=false
  for _,r in ipairs(images) do
   if p[1]>=r.x-1e-6 and p[1]<=r.x+r.w+1e-6 and p[2]>=r.y-1e-6 and p[2]<=r.y+r.h+1e-6 then covered=true end
  end
  assert(covered,'unpainted room edge at '..wh[1]..'x'..wh[2])
 end
 assert(math.abs(expected-(xmax-vx)*(ymax-vy))<1,'room art leaves a band or duplicates the host')
end
print('PASS merchant table layout, unified scorecard, footer and physical D6 scale')
