-- UI 2.0 P1: pure geometry STUDY, no production HUD integration.
-- The two proposals share a 1920x1080 coordinate contract. The actual
-- selected layout is TBD until Windows g3d screenshots and P0 baseline QA.
-- This module contains neither LOVE drawing nor gameplay input/scoring.
local M={virtual_w=1920,virtual_h=1080}
M.variants={'single_folio','open_codex'}

local function rect(x,y,w,h)
 return {x=x,y=y,w=w,h=h}
end

local function common()
 return {
  header=rect(48,18,1824,76),
  -- Readout geometry is visual-only; it does not change any button
  -- positions or enlarge the physical tray's interaction footprint.
  header_readout={
   commission_tag=rect(70,26,408,22),
   commission_name=rect(70,51,408,31),
   metrics={
    {caption=rect(520,27,195,21),value=rect(520,50,195,36)},
    {caption=rect(744,27,195,21),value=rect(744,50,195,36)},
    {caption=rect(970,27,195,21),value=rect(970,50,195,36)},
    {caption=rect(1190,27,195,21),value=rect(1190,50,195,36)},
   },
   dividers={500,730,954,1177,1420},
   help=rect(1510,33,155,49),
   runmenu=rect(1682,33,156,49),
  },
  -- The status line and the two large contextual actions are outside
  -- the playable surface, so a six-die throw cannot hit the buttons.
  message=rect(100,910,1720,34),
  primary=rect(308,956,610,76),
  secondary=rect(1002,956,610,76),
 }
end

function M.build(which)
 assert(which=='single_folio' or which=='open_codex',
  'unknown UI 2.0 layout candidate')
 local a=common()
 if which=='single_folio' then
  -- A broad physical playing folio and a narrower on-desk work ledger.
  a.book=rect(48,108,1444,784)
  a.shelf=rect(140,136,1252,64)
  a.tray=rect(68,216,1402,666)
  a.folio=rect(1512,128,352,562)
  a.context=rect(1512,724,352,152)
  -- Decorative composition only: these rectangles do not alter the
  -- camera, the 3D tray, the existing folio click region or game buttons.
  a.sidebar_frame=rect(1498,104,380,788)
  a.sidebar_caption=rect(1526,105,324,20)
  a.sidebar_divider=rect(1518,707,340,1)
  a.context_caption=rect(1525,730,326,20)
  a.context_actions={
   rect(1524,755,328,52),
   rect(1524,814,328,52),
  }
  a.shelf_caption=rect(140,113,1252,20)
  a.shelf_divider=rect(140,208,1252,1)
  a.page_main=rect(60,120,1420,764)
  a.page_info=nil
 else
  -- Real two-facing-page silhouette: left playable, right for work.
  -- Deliberately smaller physical play surface, measurable in the study.
  a.book=rect(48,112,1824,780)
  a.page_main=rect(66,128,1182,744)
  a.page_info=rect(1250,128,604,744)
  a.shelf=rect(146,152,1030,80)
  a.tray=rect(88,262,1136,598)
  a.folio=rect(1286,164,530,520)
  a.context=rect(1286,714,530,146)
 end
 a.name=which
 return a
end

local function area(r) return r.w*r.h end
function M.comparison()
 local single=M.build('single_folio')
 local spread=M.build('open_codex')
 return {
  single_tray_area=area(single.tray),
  open_tray_area=area(spread.tray),
  open_vs_single_tray_fraction=area(spread.tray)/area(single.tray),
  single_folio_area=area(single.folio),
  open_folio_area=area(spread.folio),
  single_tray_ratio=single.tray.w/single.tray.h,
  open_tray_ratio=spread.tray.w/spread.tray.h,
 }
end

function M.contains(outer,inner)
 return inner.x>=outer.x and inner.y>=outer.y
  and inner.x+inner.w<=outer.x+outer.w
  and inner.y+inner.h<=outer.y+outer.h
end
function M.overlap(a,b)
 local w=math.min(a.x+a.w,b.x+b.w)-math.max(a.x,b.x)
 local h=math.min(a.y+a.h,b.y+b.h)-math.max(a.y,b.y)
 return math.max(0,w)*math.max(0,h)
end

-- Screen mapping is ONLY for experiments and hitbox QA; the production
-- resolution_manager remains the sole authority for input conversion.
function M.screen_rect(r,viewport)
 assert(viewport and viewport.scale and viewport.scale>0)
 return rect(viewport.x+r.x*viewport.scale,
             viewport.y+r.y*viewport.scale,
             r.w*viewport.scale,r.h*viewport.scale)
end

function M.validate(layout)
 local bounds=rect(0,0,M.virtual_w,M.virtual_h)
 local required={'header','book','page_main','tray','shelf','folio',
                 'context','message','primary','secondary'}
 for _,name in ipairs(required) do
  local r=layout[name]
  if not r or r.w<=0 or r.h<=0 or not M.contains(bounds,r) then
   return false,'invalid or off-screen '..name
  end
 end
 if layout.page_info and not M.contains(layout.book,layout.page_info) then
  return false,'second folio page outside book'
 end
 if not M.contains(layout.book,layout.page_main) then
  return false,'main folio page outside book'
 end
 if not M.contains(layout.book,layout.tray) then
  return false,'physical tray must be inside book'
 end
 if M.overlap(layout.tray,layout.folio)>0 then
  return false,'playable dice surface obscured by info folio'
 end
 if M.overlap(layout.tray,layout.shelf)>0 then
  return false,'scoring shelf obscures the dice throwing surface'
 end
 for _,id in ipairs({'header','message','primary','secondary','context'}) do
  if M.overlap(layout.tray,layout[id])>0 then
   return false,id..' obscures the 3D dice surface'
  end
 end
 if layout.sidebar_frame then
  for _,name in ipairs({'folio','context','sidebar_caption','sidebar_divider',
    'context_caption'}) do
   if not layout[name] or not M.contains(layout.sidebar_frame,layout[name]) then
    return false,'sidebar element outside the decorative frame: '..name
   end
  end
  if M.overlap(layout.sidebar_frame,layout.tray)>0 then
   return false,'decorative sidebar overlaps physical D6 tray'
  end
  if M.overlap(layout.sidebar_divider,layout.folio)>0
   or M.overlap(layout.sidebar_divider,layout.context)>0 then
   return false,'sidebar ornament overlaps interactive areas'
  end
  for _,r in ipairs(layout.context_actions or {}) do
   if not M.contains(layout.context,r) then
    return false,'context action outside manuscript tools panel'
   end
  end
  if not M.contains(layout.book,layout.shelf_caption)
   or not M.contains(layout.book,layout.shelf_divider)
   or M.overlap(layout.shelf_caption,layout.shelf)>0
   or M.overlap(layout.shelf_divider,layout.tray)>0 then
   return false,'shelf ornaments cover 3D dice or accepted slots'
  end
 end
 if M.overlap(layout.primary,layout.secondary)>0 then
  return false,'contextual actions overlap'
 end
 -- Minimum 3D footprint for six full-size D6 at 1920x1080.
 if layout.tray.w<1100 or layout.tray.h<570 then
  return false,'dice tray too small for the existing 3D presentation'
 end
 -- 76px action height is usable at the 1.18x big-text typography scale,
 -- while old click code may need further font fitting at implementation.
 if layout.primary.h<72 or layout.secondary.h<72 then
  return false,'contextual actions below target height'
 end
 return true
end
return M
