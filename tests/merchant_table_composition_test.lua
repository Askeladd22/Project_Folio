-- Headless structural QA for the table wager, footer and true D6 size.
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local L=Layout.build('table_minimal')
assert(Layout.validate(L))
for _,r in ipairs{L.secured_caption,L.secured_value,L.risk_caption,L.risk_value} do
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
assert(Layout.overlap(L.primary,L.secondary)==0)
local file=assert(io.open('src/app/dice_runtime.lua','rb'))
local code=file:read('*a');file:close()
local value=tonumber(assert(code:match('local TABLE_DIE_SCALE = ([%d%.]+)')))
assert(value>.85 and value<=1,'D6 enlargement must be modest and physical')
assert(code:find('body_factory(spawn_dice_size * TABLE_DIE_SCALE)',1,true),
 'renderer and collision geometry must derive from the same physical size')
local Res=require('src.core.resolution_manager')
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
print('PASS merchant table layout, unified scorecard, footer and physical D6 scale')
