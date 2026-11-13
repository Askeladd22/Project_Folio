-- Contract of the shipping Merchant table; retired P1 layouts are not selectable.
local Layout=require('src.farkle.ui').layout
local Res=require('src.core.navigation').resolution

local layout=Layout.build()
assert(Layout.validate(layout),'shipping Merchant table layout is invalid')
assert(layout.tray.x==60 and layout.tray.y==538
 and layout.tray.w==1800 and layout.tray.h==426,
 'physical six-D6 play area changed')
assert(layout.folio==nil and layout.context==nil,
 'retired sidebar geometry must not return to the shipping table')
assert(Layout.overlap(layout.tray,layout.score_panel)==0)
assert(Layout.overlap(layout.tray,layout.footer)==0)
assert(Layout.overlap(layout.tray,layout.primary)==0)
assert(Layout.overlap(layout.tray,layout.secondary)==0)

-- Screen mapping is independent from the removed P1 visual comparison.
local keys={'tray','score_panel','footer','shelf','primary','secondary','help','runmenu'}
for _,size in ipairs{{1920,1080},{1280,720},{2560,1080},
                     {3440,1440},{1024,768}} do
 Res.init(1920,1080)
 Res.refresh(size[1],size[2])
 local vp=Res.get_viewport()
 local frame={x=vp.x,y=vp.y,scale=Res.get_scale()}
 local bounds=Layout.screen_rect({x=0,y=0,w=1920,h=1080},frame)
 for _,key in ipairs(keys) do
  local source=layout[key]
  local drawn=Layout.screen_rect(source,frame)
  assert(Layout.contains(bounds,drawn),'off-screen '..key)
  for _,corner in ipairs{{source.x,source.y},
                          {source.x+source.w,source.y+source.h}} do
   local x,y=Res.to_screen(corner[1],corner[2])
   local expectedX=drawn.x+(corner[1]==source.x and 0 or drawn.w)
   local expectedY=drawn.y+(corner[2]==source.y and 0 or drawn.h)
   assert(math.abs(x-expectedX)<1e-6 and math.abs(y-expectedY)<1e-6,
    'layout-to-screen mismatch: '..key)
   local vx,vy=Res.to_virtual(x,y)
   assert(math.abs(vx-corner[1])<1e-6 and
          math.abs(vy-corner[2])<1e-6,
    'screen-to-layout mismatch: '..key)
  end
 end
end
local invalid=Layout.build()
invalid.primary={x=invalid.tray.x,y=invalid.tray.y,w=300,h=76}
assert(not Layout.validate(invalid),'button overlapping D6 must be rejected')
local outside=Layout.build()
outside.tray={x=-1,y=538,w=1800,h=426}
assert(not Layout.validate(outside),'off-screen 3D tray must be rejected')
assert(not pcall(Layout.build,'single_folio'),
 'retired sidebar layout must not be selectable')
assert(not pcall(Layout.build,'unknown'),'invalid layout names must fail')
Res.refresh(1920,1080)
print('PASS active Merchant table geometry and viewport mapping without P1 A/B layout')
