-- UI 2.0 P1 PROVISIONAL layout candidates. No renderer/input changes.
local L=require('src.features.farkle.ui_v2.layout_candidates')
local Res=require('src.core.resolution_manager')
local oldTray={x=40,y=60,w=1460,h=808}
local candidates={'single_folio','open_codex'}
local rectKeys={'header','book','page_main','shelf','tray','folio',
                'context','message','primary','secondary'}
local function inside(a,b)
 return L.contains(a,b)
end
for _,name in ipairs(candidates) do
 local layout=L.build(name)
 local valid,reason=L.validate(layout)
 assert(valid,name..' invalid: '..tostring(reason))
 assert(layout.name==name)
 assert(L.overlap(layout.tray,layout.folio)==0)
 assert(L.overlap(layout.tray,layout.shelf)==0)
 assert(L.overlap(layout.tray,layout.primary)==0)
 assert(L.overlap(layout.tray,layout.secondary)==0)
 assert(layout.tray.w>=1100 and layout.tray.h>=570)
 assert(layout.primary.w>=400 and layout.primary.h>=72)
 -- Confirm region constraints survive virtual-to-screen transformation
 -- for both window targets and letterboxed ultrawide, without a new
 -- competing pointer coordinate transformation.
 Res.init(1920,1080)
 for _,size in ipairs({{1920,1080},{1280,720},{2560,1080},
                        {3440,1440},{1024,768}}) do
  Res.refresh(size[1],size[2])
  local viewport=Res.get_viewport()
  local mapped={}
  for _,key in ipairs(rectKeys) do
   mapped[key]=L.screen_rect(layout[key],{
    x=viewport.x,y=viewport.y,scale=Res.get_scale()})
   local r=layout[key]
   for _,corner in ipairs({{r.x,r.y},{r.x+r.w,r.y+r.h}}) do
    local x,y=Res.to_screen(corner[1],corner[2])
    local sx,sy=L.screen_rect(layout[key],{
     x=viewport.x,y=viewport.y,scale=Res.get_scale()}).x,
     L.screen_rect(layout[key],{
     x=viewport.x,y=viewport.y,scale=Res.get_scale()}).y
    if corner[1]~=r.x then sx=sx+mapped[key].w end
    if corner[2]~=r.y then sy=sy+mapped[key].h end
    assert(math.abs(x-sx)<1e-6 and math.abs(y-sy)<1e-6,
     name..' coordinate mismatch for '..key)
    local vx,vy=Res.to_virtual(x,y)
    assert(math.abs(vx-corner[1])<1e-6 and
           math.abs(vy-corner[2])<1e-6,
     name..' pointer hitbox mismatch for '..key)
   end
  end
  assert(not L.overlap(mapped.tray,mapped.folio) or
         L.overlap(mapped.tray,mapped.folio)==0)
  assert(L.overlap(mapped.tray,mapped.primary)==0)
  assert(L.overlap(mapped.tray,mapped.secondary)==0)
  assert(inside(L.screen_rect({x=0,y=0,w=1920,h=1080},{
    x=viewport.x,y=viewport.y,scale=Res.get_scale()}),mapped.tray))
 end
end
local c=L.comparison()
assert(c.single_tray_area==1402*666)
assert(c.open_tray_area==1136*598)
assert(c.single_tray_area/oldTray.w/oldTray.h>.79,
 'single-folio prototype sacrifices too much of existing full-size dice area')
assert(c.open_vs_single_tray_fraction>.70 and
       c.open_vs_single_tray_fraction<.80,
 'two-page book has a material space cost that P1 must consider')
assert(c.open_folio_area>c.single_folio_area,
 'second page should benefit manuscript content, not just decorations')
-- Inject bad regions: must fail rather than silently clipping touch
-- targets beneath dice or outside the 1920x1080 virtual window.
local invalid=L.build('single_folio')
invalid.primary={x=invalid.tray.x,y=invalid.tray.y,w=300,h=76}
assert(not L.validate(invalid),'buttons cannot steal a part of the D6 board')
local outside=L.build('open_codex')
outside.folio={x=1840,y=200,w=250,h=480}
assert(not L.validate(outside),'folio cannot extend beyond viewport')
local tiny=L.build('open_codex')
tiny.tray={x=88,y=262,w=800,h=400}
assert(not L.validate(tiny),'physical throw area must remain large')
assert(not pcall(L.build,'unknown'),'layout ID must be explicit')
Res.refresh(1920,1080)
print(string.format(
 'PASS UI v2 P1 candidates: single tray %dpx2 (%.1f%% legacy), open tray %dpx2 (%.1f%% single); untouched production HUD',
 c.single_tray_area,100*c.single_tray_area/(oldTray.w*oldTray.h),
 c.open_tray_area,100*c.open_vs_single_tray_fraction))
