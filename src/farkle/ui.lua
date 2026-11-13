local Bundle = {}
Bundle.layout = (function()
local Parts = {}

-- Dialog geometry
Parts.modal = (function()
-- Presentation geometry only for canonical Farkle UI V2 dialogs.
-- Modal overlays intentionally cover the 3D board; controller hitboxes
-- and command IDs are still authoritative in ui_v2/dialogs.lua.
local M={}
local function rect(x,y,w,h) return {x=x,y=y,w=w,h=h} end
local function contains(a,b)
 return b.x>=a.x and b.y>=a.y and
  b.x+b.w<=a.x+a.w and b.y+b.h<=a.y+a.h
end
local function overlap(a,b)
 return a.x<b.x+b.w and b.x<a.x+a.w and
  a.y<b.y+b.h and b.y<a.y+a.h
end
M.frame=rect(390,145,1140,800)
M.close=rect(1295,175,205,56)
M.header_rule={x=425,y=240,w=1070}
M.reward_frame=rect(390,210,1140,650)
M.reward_rule={x=440,y=418,w=1040}
M.reward_cards={
 rect(430,438,510,218),
 rect(980,438,510,218),
}
M.reward_buttons={
 rect(440,685,490,85),
 rect(990,685,490,85),
}

-- Compact in-game pause/navigation leaf; unrelated dialog geometry is unchanged.
M.pause_frame=rect(615,226,690,620)
M.pause_close=rect(1165,252,100,44)
M.pause_title=rect(670,277,440,48)
M.pause_intro=rect(670,326,490,34)
M.pause_items={
 rect(674,378,572,62),rect(674,450,572,62),
 rect(674,522,572,62),rect(674,594,572,62),
}
M.pause_confirm_frame=rect(635,292,650,440)
M.pause_confirm_close=rect(1137,316,107,44)
M.pause_confirm_title=rect(688,370,425,50)
M.pause_confirm_actions={
 rect(690,568,540,62),rect(690,644,540,62),
}
function M.validate()
 local bounds=rect(0,0,1920,1080)
 for _,r in ipairs({M.frame,M.reward_frame,M.close,
   M.reward_cards[1],M.reward_cards[2],
   M.reward_buttons[1],M.reward_buttons[2]}) do
  if not contains(bounds,r) then return false,'dialog outside viewport' end
 end
 for _,pair in ipairs({
  {M.pause_frame,M.pause_close},
  {M.pause_frame,M.pause_title},
  {M.pause_frame,M.pause_intro},
  {M.pause_confirm_frame,M.pause_confirm_close},
  {M.pause_confirm_frame,M.pause_confirm_title},
 }) do
  if not contains(pair[1],pair[2]) then return false,'pause item outside frame' end
 end
 for _,r in ipairs(M.pause_items) do
  if not contains(M.pause_frame,r) then return false,'pause action outside frame' end
 end
 for _,r in ipairs(M.pause_confirm_actions) do
  if not contains(M.pause_confirm_frame,r) then return false,'confirm action outside frame' end
 end
 for i=2,#M.pause_items do
  if overlap(M.pause_items[i-1],M.pause_items[i]) then
   return false,'pause actions overlap'
  end
 end
 if overlap(M.pause_confirm_actions[1],M.pause_confirm_actions[2]) then
  return false,'confirm actions overlap'
 end
 if not contains(M.frame,M.close) then
  return false,'close outside standard dialog'
 end
 for i=1,2 do
  if not contains(M.reward_frame,M.reward_cards[i]) or
    not contains(M.reward_frame,M.reward_buttons[i]) then
   return false,'reward element outside folio'
  end
  if overlap(M.reward_cards[i],M.reward_buttons[i]) then
   return false,'reward action obscured by its description'
  end
 end
 if overlap(M.reward_cards[1],M.reward_cards[2]) or
  overlap(M.reward_buttons[1],M.reward_buttons[2]) then
  return false,'reward columns overlap'
 end
 for _,rule in ipairs({{M.frame,M.header_rule},
                       {M.reward_frame,M.reward_rule}}) do
  local frame,r=rule[1],rule[2]
  if r.x<frame.x or r.x+r.w>frame.x+frame.w or
    r.y<frame.y or r.y>frame.y+frame.h then
   return false,'rule outside dialog'
  end
 end
 return true
end
return M
end)()

-- Table and HUD geometry
Parts.layout = (function()
-- Merchant-table geometry and the retained single-folio HUD contract.
-- Layout is presentation-only: g3d, rules and input stay authoritative.
local M={virtual_w=1920,virtual_h=1080}

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
 assert(which=='single_folio' or which=='table_minimal',
        'unknown HUD layout')
 if which=='table_minimal' then
  -- Production Farkle table: preserve a large 3D viewport, without the
  -- legacy commission/folio/tools sidebar.
  return {
   name=which,
   header=rect(44,20,1832,72),
   -- The rear seam leaves room for a larger illustrated opponent.
    host=rect(0,0,1920,614),
    portrait_lift=48,
   rear_span=1280,
   -- One unified scorecard: the risk total is not stranded below the table.
   score_panel=rect(44,20,414,116),
   -- Align the one-button state to the same axis as the real tray.
  single_action=rect(763,976,394,68),
   secured_caption=rect(63,25,173,18),
   secured_value=rect(63,43,173,30),
   risk_caption=rect(258,25,178,18),
   risk_value=rect(258,43,178,30),
   objective_caption=rect(63,82,173,18),
   objective_value=rect(63,100,173,30),
   turns_caption=rect(258,82,178,18),
   turns_value=rect(258,100,178,30),
   help=rect(1510,32,145,46),
   runmenu=rect(1682,32,158,46),
   book=rect(44,107,1832,944),
   page_main=rect(56,119,1808,921),
   -- A small command plaque, shown ONLY when controls are present.
   -- Sit immediately below the front apron. All UI and pick targets
   -- share the same virtual coordinates as the painted room.
  footer=rect(445,970,1030,78),
  footer_trim=rect(458,975,1004,2),
   -- The accepted-dice register is just to the LEFT of the plaque.
  shelf=rect(56,965,384,51),
   shelf_label=rect(58,935,382,25),
   -- Starts above the rear seam (host bottom) so the tops of dice
   -- resting against the back rail stay inside the pick rectangle.
  tray=rect(60,538,1800,426),
  message=rect(650,1050,620,27),
  idle_message=rect(650,972,620,36),
  context_actions={rect(459,976,186,67),rect(459,1042,186,32)},
  primary=rect(665,976,392,68),
  secondary=rect(1076,976,383,68),
  }
 end
 local a=common()
 -- Retained single-folio geometry for compatibility coverage.
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
 a.name=which
 return a
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

-- Geometry probe for viewport and hitbox regression tests; production uses
-- ResolutionManager for the actual pointer mapping.
function M.screen_rect(r,viewport)
 assert(viewport and viewport.scale and viewport.scale>0)
 return rect(viewport.x+r.x*viewport.scale,
             viewport.y+r.y*viewport.scale,
             r.w*viewport.scale,r.h*viewport.scale)
end

function M.validate(layout)
 local bounds=rect(0,0,M.virtual_w,M.virtual_h)
 if layout.name=='table_minimal' then
  local required={'header','book','page_main','shelf','tray','message',
   'primary','secondary','help','runmenu','secured_caption','secured_value',
   'risk_caption','risk_value','objective_caption','objective_value',
   'turns_caption','turns_value','shelf_label','score_panel',
   'footer','footer_trim','single_action','idle_message'}
  for _,name in ipairs(required) do
   local r=layout[name]
   if not r or r.w<=0 or r.h<=0 or not M.contains(bounds,r) then
    return false,'off-screen minimal table element '..name
   end
  end
  if not M.contains(layout.book,layout.page_main) or
     not M.contains(layout.page_main,layout.tray) or
     not M.contains(layout.page_main,layout.shelf) or
     not M.contains(layout.header,layout.help) or
     not M.contains(layout.header,layout.runmenu) then
   return false,'invalid table containment'
  end
  for _,metric in ipairs({
   {layout.secured_caption,layout.secured_value},
   {layout.risk_caption,layout.risk_value},
   {layout.objective_caption,layout.objective_value},
   {layout.turns_caption,layout.turns_value},
  }) do
   if not M.contains(layout.score_panel,metric[1]) or
      not M.contains(layout.score_panel,metric[2]) or
      M.overlap(metric[1],metric[2])>0 then
    return false,'score metric outside or overlapping its scorecard'
   end
  end
  if M.overlap(layout.secured_caption,layout.risk_caption)>0 or
     M.overlap(layout.secured_value,layout.risk_value)>0 or
     M.overlap(layout.objective_caption,layout.turns_caption)>0 or
     M.overlap(layout.objective_value,layout.turns_value)>0 or
     M.overlap(layout.score_panel,layout.help)>0 or
     not M.contains(layout.footer,layout.footer_trim) or
     layout.footer.h>110 or layout.footer.w>1160 or
     layout.footer.y<layout.tray.y+layout.tray.h or
     not M.contains(layout.footer,layout.primary) or
     not M.contains(layout.footer,layout.secondary) or
     not M.contains(layout.footer,layout.single_action) then
   return false,'invalid unified scorecard or compact command rail'
  end
  for _,r in ipairs{layout.shelf,layout.header,layout.message,
    layout.primary,layout.secondary,layout.single_action,
    layout.idle_message,layout.help,layout.runmenu} do
   if M.overlap(r,layout.tray)>0 then
    return false,'minimal controls overlap the physical D6 field'
   end
  end
  local center=layout.tray.x+layout.tray.w*.5
  local function aligned(r) return math.abs(r.x+r.w*.5-center)<=3 end
  local actions_left=layout.context_actions[1].x
  local actions_right=layout.secondary.x+layout.secondary.w
  if not aligned(layout.footer) or not aligned(layout.footer_trim) or
     not aligned(layout.single_action) or not aligned(layout.idle_message) or
     not aligned(layout.message) or
     math.abs((actions_left+actions_right)*.5-center)>3 then
   return false,'merchant controls are not centered on physical table'
  end
  if M.overlap(layout.primary,layout.secondary)>0 or
     M.overlap(layout.help,layout.runmenu)>0 or
     M.overlap(layout.message,layout.primary)>0 or
     M.overlap(layout.message,layout.secondary)>0 or
     M.overlap(layout.shelf,layout.footer)>0 or
     M.overlap(layout.idle_message,layout.tray)>0 then
   return false,'overlapping minimal table actions'
  end
  for _,r in ipairs(layout.context_actions) do
   if not M.contains(bounds,r) or M.overlap(r,layout.tray)>0 or
     M.overlap(r,layout.primary)>0 or M.overlap(r,layout.secondary)>0 or
     M.overlap(r,layout.message)>0 then
    return false,'invalid minimal contextual action'
   end
  end
  if layout.tray.w<1500 or layout.tray.h<420 then
   return false,'physical table viewport too small'
  end
  if layout.primary.h<66 or layout.secondary.h<66 then
   return false,'main table actions too short'
  end
  return true
 end
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
end)()

Parts.layout.modal = Parts.modal
return Parts.layout
end)()
Bundle.text_fit = (function()
local Parts = {}

-- Single-line fitting
Parts.label = (function()
-- Pure one-line typography helper for the illuminated Farkle UI.
-- Uses the actual font metrics supplied by the caller; no LÖVE dependency.
-- Never slices a UTF-8 glyph halfway through when shortening a long label.
local M={}

local function characters(text)
 local result={}
 local i=1
 while i<=#text do
  local b=text:byte(i)
  local n=(b and b>=240 and 4)
     or (b and b>=224 and 3)
     or (b and b>=194 and 2) or 1
  result[#result+1]=text:sub(i,i+n-1)
  i=i+n
 end
 return result
end

function M.fit(value,measure,preferred,minimum,max_width,max_height)
 assert(type(measure)=='function','font measure callback required')
 local text=tostring(value or '')
 local high=math.max(8,math.floor(preferred or 18))
 local low=math.max(8,math.min(high,math.floor(minimum or 12)))
 local w=math.max(0,max_width or 0)
 local h=math.max(0,max_height or 0)
 for px=high,low,-1 do
  local tw,th=measure(text,px)
  if tw<=w and th<=h then return text,px,false end
 end
 -- In tight layouts, height remains a hard boundary even if text is long.
 local px=low
 while px>8 do
  local _,th=measure('Hg',px)
  if th<=h then break end
  px=px-1
 end
 local _,height=measure('Hg',px)
 if height>h then return '',px,true end
 if measure(text,px)<=w then return text,px,false end
 local dots='...'
 if measure(dots,px)>w then return '',px,true end
 local glyphs=characters(text)
 local lo,hi=0,#glyphs
 while lo<hi do
  local mid=math.floor((lo+hi+1)*.5)
  local trial=table.concat(glyphs,'',1,mid)..dots
  if measure(trial,px)<=w then lo=mid
  else hi=mid-1 end
 end
 return table.concat(glyphs,'',1,lo)..dots,px,true
end

return M
end)()

-- Paragraph fitting
Parts.paragraph = (function()
-- Pure bounded paragraph typography for the shipping Folio modal UI.
-- Never changes game state, buttons or the real LÖVE font metrics.
local M={}

local function glyphs(text)
 local result={}
 local i=1
 while i<=#text do
  local byte=text:byte(i)
  local count=(byte>=240 and 4) or (byte>=224 and 3)
    or (byte>=194 and 2) or 1
  result[#result+1]=text:sub(i,i+count-1)
  i=i+count
 end
 return result
end

local function fits(value,measure,px,width,height)
 local count,lineHeight,longest=measure(value,px,width)
 count=math.max(1,count or 1)
 lineHeight=math.max(0,lineHeight or 0)
 return count*lineHeight<=height and (longest or 0)<=width,
  count
end

-- measure(text,px,width) returns line count, line step and widest line;
-- callers use actual Font:getWrap / getHeight / getLineHeight.
-- Returns printable text, font pixels, line count and a clipped flag.
function M.fit(value,measure,preferred,minimum,width,height)
 assert(type(measure)=='function','paragraph measure callback required')
 local text=tostring(value or '')
 local w=math.max(0,width or 0)
 local h=math.max(0,height or 0)
 local hi=math.max(8,math.floor(preferred or 22))
 local low=math.max(8,math.min(hi,math.floor(minimum or 12)))
 if text=='' or w<=0 or h<=0 then return '',low,0,text~='' end
 for px=hi,low,-1 do
  local ok,count=fits(text,measure,px,w,h)
  if ok then return text,px,count,false end
 end
 -- Very small viewports or unusually verbose experimental descriptions:
 -- trim by whole UTF-8 glyph, never leak words into the next UI control.
 local px=low
 while px>8 do
  local _,step=measure('Hg',px,w)
  if step and step<=h then break end
  px=px-1
 end
 local dots='...'
 local ok,lines=fits(dots,measure,px,w,h)
 if not ok then return '',px,0,true end
 local chars=glyphs(text)
 local left,right=0,#chars
 while left<right do
  local mid=math.floor((left+right+1)/2)
  local candidate=table.concat(chars,'',1,mid)..dots
  if fits(candidate,measure,px,w,h) then left=mid
  else right=mid-1 end
 end
 local result=table.concat(chars,'',1,left)..dots
 local _,count=fits(result,measure,px,w,h)
 return result,px,count,true
end

return M
end)()

return Parts
end)()
Bundle.opponent_scene = (function()
-- Data-driven visual layer only; never mutates Farkle or g3d geometry.
-- The shipping composite JPEG already contains the Merchant. Other
-- opponents REQUIRE a clean room, so two figures can never overlap.
local Art=require('src.data.frontend_schema').palette
local S={}
S.default_id='merchant'
S.room_path='resources/scenes/printshop-room.png'
S.legacy_room='resources/merchant/table-host.jpg'
function S.validate_id(id)
 if id==nil then return S.default_id end
 assert(type(id)=='string' and id:match('^[a-z][a-z0-9_]*$'),
  'opponent ID must contain only lowercase letters, digits and underscores')
 return id
end
function S.portrait_path(id)
 return 'resources/opponents/'..S.validate_id(id)..'.png'
end
function S.available(path)
 return love and love.filesystem and love.filesystem.getInfo
  and love.filesystem.getInfo(path,'file')~=nil or false
end
function S.resolve(id,exists)
 id=S.validate_id(id)
 assert(type(exists)=='function','file-existence function required')
 local png=S.portrait_path(id)
 if exists(S.room_path) and exists(png) then
  return {id=id,room=S.room_path,portrait=png,legacy=false}
 end
 if id==S.default_id then
  return {id=id,room=S.legacy_room,portrait=nil,legacy=true}
 end
 if not exists(S.room_path) then
  error('Missing clean background '..S.room_path..
   '; current JPEG contains the Merchant and cannot host '..id,2)
 end
 error('Missing transparent portrait '..png,2)
end
function S.portrait_bounds(w,h,layout)
 assert(w>0 and h>0 and layout and layout.tray,'invalid portrait/layout')
 -- All PNG opponents use one proportional envelope. The lower edge
 -- slips behind the g3d table top, avoiding floating or pasted-on figures.
 local bottom=(layout.host and layout.host.y+layout.host.h or layout.tray.y)+35
  -(layout.portrait_lift or 0)
 local maxHeight=math.max(1,math.min(580,bottom-12))
 local scale=math.min(800/w,maxHeight/h)
 local outW,outH=w*scale,h*scale
 local x=layout.tray.x+layout.tray.w*.5-outW*.5
 return {x=x,y=bottom-outH,w=outW,h=outH}
end
-- 2.5D staging: the g3d table is the fixed pivot, farther planes drift
-- more. Pixel values are in the 1920x1080 virtual UI space.
S.depth={room=22,room_y=9,portrait=8,portrait_y=3,overscan=1.035,breath=.005}
local view={x=0,y=0}
function S.parallax(dt,nx,ny,t,reduced)
 if reduced then
  view.x,view.y=0,0
 else
  local tx=math.max(-1,math.min(1,nx))*.85+math.sin(t*.21)*.15
  local ty=math.max(-1,math.min(1,ny))*.5+math.sin(t*.17+1.3)*.12
  local k=1-math.exp(-math.max(0,math.min(dt,.1))*2.4)
  view.x=view.x+(tx-view.x)*k
  view.y=view.y+(ty-view.y)*k
 end
 return {x=view.x,y=view.y}
end
local portrait_shader
local function get_portrait_shader(g)
 if not portrait_shader then
  portrait_shader=assert(g.newShader('resources/shaders/woodcut_portrait.glsl'),
   'Failed to create woodcut portrait shader')
 end
 return portrait_shader
end
local image_cache={}
function S.draw_portrait(selection,layout,g,depth)
 if not selection.portrait then return end
 local path=selection.portrait
 local sprite=image_cache[path]
 if not sprite then
  sprite=g.newImage(path)
  sprite:setFilter('linear','linear')
  image_cache[path]=sprite
 end
 local iw,ih=sprite:getWidth(),sprite:getHeight()
 local bounds=S.portrait_bounds(iw,ih,layout)
 local sx,sy=bounds.w/iw,bounds.h/ih
 local x,y,lift=bounds.x,bounds.y,1
 if depth then
  x=x-depth.x*S.depth.portrait
  y=y-depth.y*S.depth.portrait_y
  lift=1+S.depth.breath*(depth.breath or 0)
 end
 -- Breathing grows upward from the hidden waist, never off the table.
 local oy=ih
 local shader=depth and get_portrait_shader(g)
 if shader then
  -- Cast shadow on the back wall separates the figure from the room.
  local shade=Art.rgb('earth_dark')
  shader:send('shadowTexel',{1/iw,1/ih})
  shader:send('shadowPass',1)
  g.setShader(shader)
  g.setColor(shade[1],shade[2],shade[3],.24)
  g.draw(sprite,x+bounds.w*.5+16-depth.x*(S.depth.room-S.depth.portrait),y+bounds.h+4,0,
   sx*1.02,sy*1.015*lift,iw*.5,oy)
  shader:send('shadowPass',0)
  shader:send('inkTone',Art.rgb('ink'))
  shader:send('paperTone',Art.rgb('paper'))
 end
 g.setColor(1,1,1,1)
 g.draw(sprite,x+bounds.w*.5,y+bounds.h,0,sx,sy*lift,iw*.5,oy)
 if shader then g.setShader() end
 g.setColor(1,1,1,1)
end
return S
end)()
Bundle.overlay = (function()
local Parts = {}

-- Indicator state
Parts.model = (function()
-- UI v2 P3: pure, read-only projection of physical and scoring feedback.
-- Coordinates of dice hits and marquee remain REAL SCREEN pixels from the
-- existing g3d/engine bridge. No physics, camera, roll or input mutations.
local H=require('src.farkle.presentation').hud_model
local R=require('src.farkle.rules')
local Marquee=require('src.farkle.interaction').selection
local M={}

local function finite(n)
 return type(n)=='number' and n==n and n~=math.huge and n~=-math.huge
end

function M.build(u,hits,hoveredId)
 local result={markers={},marquee=nil,hand=nil,physicalCount=0}
 local s=u and u.game
 if not s or u.modal or H.reward_active(s) then return result end

 if u.marquee and Marquee.dragged(u.marquee) then
  result.marquee=Marquee.rectangle(u.marquee)
 end

 result.physicalCount=Marquee.count(u.dragSelected)
 if u.mouseThrow then
  local gesture=u.mouseThrow
  local count=gesture.group and type(gesture.held)=='table'
    and #gesture.held or 1
  if finite(gesture.x) and finite(gesture.y) then
   result.hand={x=gesture.x,y=gesture.y,count=math.max(1,count)}
  end
  -- Never paint six per-die selections on top of a gathered physical group.
  -- Also suppress scoring highlights while a throw is physically in hand.
  return result
 end

 local eligible=s.phase=='ready' and H.eligible(s) or {}
 local hasScoreSelection=s.phase=='ready' and s.selected
    and next(s.selected)~=nil
 local scoreKind=hasScoreSelection and (R.selection(s) and 'score'
     or H.can_complete(s) and 'partial' or 'invalid')
 for _,hit in ipairs(hits or {}) do
  local id=hit.index or hit.roll_index
  if type(id)=='number' and id%1==0 and id>=1 and id<=6
      and finite(hit.x) and finite(hit.y) then
   local kind
   if u.dragSelected and u.dragSelected[id] then
    kind='physical'
   elseif s.phase=='ready' and s.selected and s.selected[id] then
    kind=scoreKind
   elseif eligible[id] then
    kind='eligible'
   end
   local hovered=s.phase=='ready' and not s.used[id] and s.hand[id] and id==hoveredId
   if not kind and hovered then kind='neutral' end
   if kind then
    result.markers[#result.markers+1]={
     id=id,x=hit.x,y=hit.y,r=finite(hit.r) and
       math.max(11,math.min(30,hit.r*.70)) or 22,kind=kind,outline=hit.outline,hovered=not not hovered
    }
   end
  end
 end
 return result
end

return M
end)()

-- Indicator drawing
Parts.overlay = (function()
-- Legible marks beside the pips, with silhouettes taken from the same
-- projected physical dice the pointer picks.
local Model=Parts.model
local UI=require('src.core.runtime_state').ui
local Bridge=require('src.core.engine_bridge')
local Res=require('src.core.navigation').resolution
local M={}
local fonts={}
local function palette()
 if UI.high_contrast() then
  return {physical={.30,1,1,1},score={1,.86,.20,1},
    partial={1,.86,.20,1},invalid={1,.52,.46,1},eligible={1,.96,.64,1},
    neutral={1,1,1,.85},hover={1,1,.94,1}}
 end
 return {physical={.40,.83,.91,.96},score={1,.80,.30,.98},
   partial={.96,.78,.41,1},invalid={1,.54,.46,1},eligible={.96,.82,.52,.95},
   neutral={.88,.84,.76,.52},hover={1,.95,.77,.94}}
end
local function colour(c)
 love.graphics.setColor(c[1],c[2],c[3],c[4])
end
local function corner_marks(x,y,r,extended)
 local g=love.graphics
 local reach=extended and 15 or 11
 local d=r+7
 -- Corner strokes stay outside the die's pips, unlike full-size circles.
 g.line(x-d,y-d+reach,x-d,y-d,x-d+reach,y-d)
 g.line(x+d-reach,y-d,x+d,y-d,x+d,y-d+reach)
 g.line(x-d,y+d-reach,x-d,y+d,x-d+reach,y+d)
 g.line(x+d-reach,y+d,x+d,y+d,x+d,y+d-reach)
end
local edgeInk={.18,.12,.065,.82}
-- Passive eligibility is already a subtle tint on the g3d die faces.
-- Score feedback draws only on the projected physical silhouette: there
-- must be no dashes, ticks or glyphs detached below the dice.
local function score_mark(m,colors,scale)
 if not m.outline then return end
 local chosen=m.kind=='score' or m.kind=='partial' or m.kind=='invalid'
 if not chosen and not m.hovered then return end
 local g=love.graphics
 local width=(chosen and 2.25 or 1.35)*scale
 g.setLineWidth(width+1.5*scale);colour(edgeInk)
 g.polygon('line',m.outline)
 g.setLineWidth(width)
 colour(chosen and colors[m.kind] or colors.hover)
 g.polygon('line',m.outline)
end
function M.draw(u,hits)
 local hover
 if u.game and u.game.phase=='ready' and not u.modal and not u.mouseThrow and
    not u.marquee and love.mouse and love.mouse.getPosition then
  hover=Bridge.pickTrayDie(love.mouse.getPosition())
 end
 local model=Model.build(u,hits,hover)
 local g=love.graphics
 g.push('all')
 local colors=palette()
 local viewportScale=math.max(.8,math.min(2,Res.get_scale()*UI.scale()))
 if model.marquee then
  local r=model.marquee
  colour(colors.physical)
  g.setLineWidth(1.8)
  g.rectangle('line',r.x,r.y,r.w,r.h)
  g.setColor(colors.physical[1],colors.physical[2],
    colors.physical[3],.08)
  g.rectangle('fill',r.x,r.y,r.w,r.h)
 end
 for _,m in ipairs(model.markers) do
  colour(colors[m.kind])
  if m.kind=='physical' then
   -- Drag-grab remains cyan but stays close to the projected die.
   g.setLineWidth(2.1*viewportScale)
   corner_marks(m.x,m.y,math.min(24,m.r),false)
  else
   score_mark(m,colors,viewportScale)
  end
 end
 if model.hand then
  local hand=model.hand
  -- One pointer badge, not a ring for every die in the held constellation.
  colour(colors.physical)
  g.setLineWidth(2.3*viewportScale)
  g.line(hand.x-18,hand.y,hand.x-7,hand.y)
  g.line(hand.x+7,hand.y,hand.x+18,hand.y)
  g.line(hand.x,hand.y-18,hand.x,hand.y-7)
  g.line(hand.x,hand.y+7,hand.x,hand.y+18)
  local pts=math.max(14,math.min(27,math.floor(16*UI.scale()*
       (UI.big_text() and 1.2 or 1)+.5)))
  if not fonts[pts] then fonts[pts]=g.newFont(pts) end
  local title=hand.count>1 and (hand.count..' DADI IN MANO')
      or 'DADO IN MANO'
  local width=fonts[pts]:getWidth(title)+20
  local height=pts+16
  local x=hand.x+22
  local y=hand.y-height-15
  g.setColor(.08,.10,.11,.92)
  g.rectangle('fill',x,y,width,height,5)
  colour(colors.physical)
  g.setLineWidth(1.3)
  g.rectangle('line',x,y,width,height,5)
  g.setFont(fonts[pts])
  g.print(title,x+10,y+7)
 end
 g.pop()
 return model
end
return M
end)()

Parts.overlay.model = Parts.model
return Parts.overlay
end)()
Bundle.dialogs = (function()
local Typography=require('src.core.presentation').typography
local R=require('src.farkle.rules')
local Medals=R.medals
local MedalPanel=require('src.farkle.presentation').medal_panel
local D=require('src.farkle.dice')
local H=require('src.farkle.presentation').hud_model
local Res=require('src.core.navigation').resolution
local Presentation=require('src.farkle.presentation')
local FolioView=require('src.farkle.presentation').folio_view
local MenuSurface=require('src.screens.folio_surface').menu_surface
local RuntimeUI=require('src.core.runtime_state').ui
local ModalLayout=Bundle.layout.modal
local TextFit=Bundle.text_fit
local LabelFit=TextFit.label
local ParagraphFit=TextFit.paragraph
local Art=require('src.data.frontend_schema').palette
local Navigation=require('src.core.navigation')
-- Dialog/reward presenter for the canonical UI v2. This module owns modal hitboxes
-- but never draws the old work surface or implements a fallback HUD.
local V={};local fonts={}
local ink=Art.rgba('text')
local muted=Art.rgba('text_muted')
local gold=Art.rgba('reward')
local green=Art.rgba('forest')
local function sized(n)
 return math.max(8,math.floor(n*math.min(1.35,RuntimeUI.scale())*
  (RuntimeUI.big_text() and 1.16 or 1)+.5))
end
local function face(px)
 fonts[px]=fonts[px] or
  Typography.load(Typography.primary,px)
 return fonts[px]
end
-- Body paragraphs must preserve their existing wraps and deliberate line
-- breaks. Action labels instead use the measured single-line fitter below.
local function txt(s,x,y,w,size,c,align)
 local g=love.graphics
 g.setFont(face(size))
 g.setColor(unpack(c or ink))
 g.printf(tostring(s),x,y,w,align or 'left')
end
local function fitted(s,r,preferred,minimum,color,align)
 local g=love.graphics
 local label,px=LabelFit.fit(s,function(text,n)
  local f=face(n)
  return f:getWidth(text),f:getHeight()
 end,sized(preferred),sized(minimum),r.w,r.h)
 if label=='' then return end
 local f=face(px)
 g.setFont(f)
 g.setColor(unpack(color or ink))
 g.printf(label,r.x,r.y+math.max(0,(r.h-f:getHeight())*.5),
  r.w,align or 'center')
end
-- Multi-line paragraphs use actual wrap metrics and a bounded cell.
-- Unlike txt (also used by FolioView), the whole paragraph must fit
-- vertically before drawing, even when big text is enabled.
local function paragraph(value,x,y,w,h,preferred,minimum,color,align)
 local g=love.graphics
 local content,px=ParagraphFit.fit(value,function(text,n,width)
  local f=face(n)
  local widest,lines=f:getWrap(text,width)
  local spacing=f.getLineHeight and f:getLineHeight() or 1
  return #lines,f:getHeight()*spacing,widest
 end,sized(preferred),sized(minimum),w,h)
 if content=='' then return end
 g.setFont(face(px))
 g.setColor(unpack(color or ink))
 g.printf(content,x,y,w,align or 'left')
end
local function panel(x,y,w,h)
 MenuSurface.panel({x=x,y=y,w=w,h=h},
  {high_contrast=RuntimeUI.high_contrast()})
end
local function pointer_over(rect)
 if not love.mouse or not love.mouse.getPosition then return false end
 local mx,my=love.mouse.getPosition()
 if type(mx)~='number' or type(my)~='number' then return false end
 local vx,vy=Res.to_virtual(mx,my)
 return MenuSurface.contains(rect,vx,vy)
end
local function button(u,id,label,x,y,w,h,on,fn,primary)
 local rect={x=x,y=y,w=w,h=h}
 -- Same authoritative hitboxes/callbacks as the previous UI V2.
 -- Hover can never activate a disabled option.
 MenuSurface.item(rect,{active=on and (primary or pointer_over(rect)),
  primary=primary,disabled=not on})
 fitted(label,{x=x+14,y=y+6,w=w-28,h=h-12},
  w<215 and 22 or 24,13,on and ink or muted,'center')
 u.buttons[id]={x=x,y=y,w=w,h=h,enabled=on,fn=fn,label=label}
end

-- The normal pause menu never exposes balancing/comparison developer tools.
local function pause_button(u,id,label,r,fn,primary)
  local g=love.graphics
  if primary then
    g.setColor(unpack(Art.rgba('surface_alt',.92)))
    g.rectangle('fill',r.x,r.y,r.w,r.h)
  end
  MenuSurface.item(r,{style='editorial',active=pointer_over(r)})
  fitted(label,{x=r.x+14,y=r.y+6,w=r.w-28,h=r.h-12},
    id=='close' and 17 or 25,14,ink,'center')
  u.buttons[id]={x=r.x,y=r.y,w=r.w,h=r.h,enabled=true,fn=fn,label=label}
end
local function draw_pause(u)
  local g=love.graphics
  local saved=u.buttons
  u.modalButtons={}
  u.buttons=u.modalButtons
  g.push('all')
  Res.begin_ui()
  g.setColor(unpack(Art.rgba('ink',.68)))
  g.rectangle('fill',0,0,1920,1080)
  local confirming=u.modal=='run_restart_confirm' or u.modal=='run_exit_confirm'
  local frame=confirming and ModalLayout.pause_confirm_frame
    or ModalLayout.pause_frame
  MenuSurface.panel(frame,{style='editorial',
    high_contrast=RuntimeUI.high_contrast()})
  local closeRect=confirming and ModalLayout.pause_confirm_close
    or ModalLayout.pause_close
  pause_button(u,'close','Chiudi [Esc]',closeRect,
    function() u.modal=confirming and 'run' or nil end)
  if not confirming then
    fitted('PARTITA IN PAUSA',ModalLayout.pause_title,33,22,ink,'left')
    fitted('Scegli come proseguire.',ModalLayout.pause_intro,
      21,15,muted,'left')
    local items=ModalLayout.pause_items
    pause_button(u,'resume','Riprendi la partita',items[1],
      function() u.modal=nil end,true)
    pause_button(u,'settings','Impostazioni',items[2],
      function()
        u.modal=nil
        Navigation.go('settings',{return_to='scriptorium'})
      end)
    pause_button(u,'restart','Ricomincia la partita',items[3],
      function() u.modal='run_restart_confirm' end)
    pause_button(u,'mainmenu','Torna al menu principale',items[4],
      function() u.modal='run_exit_confirm' end)
    paragraph('La partita non dispone ancora di un salvataggio automatico.',
      frame.x+54,frame.y+508,frame.w-108,64,19,14,muted,'center')
  else
    local restarting=u.modal=='run_restart_confirm'
    fitted(restarting and 'RICOMINCIARE?' or 'TORNARE AL MENU?',
      ModalLayout.pause_confirm_title,31,19,ink,'left')
    paragraph(restarting
      and 'I progressi della partita corrente andranno perduti. La modalità di gioco resterà invariata.'
      or 'I progressi non salvati andranno perduti. Potrai iniziare una nuova partita dal menu principale.',
      frame.x+55,frame.y+132,frame.w-110,126,24,16,muted,'left')
    pause_button(u,'cancel','Annulla',ModalLayout.pause_confirm_actions[1],
      function() u.modal='run' end,true)
    if restarting then
      pause_button(u,'confirmrestart','Conferma riavvio',
        ModalLayout.pause_confirm_actions[2],function()
          local mode=(u.game and u.game.mode) or 'build'
          u:reset(mode)
        end)
    else
      pause_button(u,'confirmexit','Conferma uscita',
        ModalLayout.pause_confirm_actions[2],function()
          u.modal=nil
          Navigation.go('main_menu')
        end)
    end
  end
  Res.end_ui()
  g.pop()
  u.buttons=saved
end

local function reward(u)
 local s=u.game;local g=love.graphics
 Res.begin_ui();g.setColor(unpack(Art.rgba('ink',.78)));g.rectangle('fill',0,0,1920,1080)
 u.buttons={};u.modalButtons={}
 local area=ModalLayout.reward_frame
 panel(area.x,area.y,area.w,area.h)
 txt('COMMISSION DELIVERED',440,245,1040,26,green)
 txt(s.phase=='upgrade' and 'Choose your die' or 'Choose your medal',440,295,1040,43)
 paragraph('Your choice carries into the next commission.',440,359,1040,50,25,17)
 MenuSurface.rule(ModalLayout.reward_rule.x,ModalLayout.reward_rule.y,
  ModalLayout.reward_rule.w,RuntimeUI.high_contrast() and 1 or .85)
 for _,card in ipairs(ModalLayout.reward_cards) do
  MenuSurface.panel(card,{high_contrast=RuntimeUI.high_contrast()})
 end
 if s.phase=='upgrade' then
  fitted('WEIGHTED DIE',{x=450,y=458,w=470,h=38},29,18,ink,'left')
  paragraph('Die 1 favours rolling a 1.\nIts numbered faces stay unchanged.',450,516,470,126,26,17)
  fitted('ENGRAVED DIE',{x=1010,y=458,w=470,h=38},29,18,ink,'left')
  paragraph('Replace the 2 on die 1 with a 1.\nThe new face counts in combinations.',1010,516,470,126,26,17)
  button(u,'weighted','Choose weighted die',440,685,490,85,true,function() R.choose_build(s,'weighted');D.install(s.build);u:sync();u:log('upgrade') end,true)
  button(u,'engraved','Choose engraved die',990,685,490,85,true,function() R.choose_build(s,'engraved');D.install(s.build);u:sync();u:log('upgrade') end,true)
 else
  fitted('CORRECTOR',{x=450,y=458,w=470,h=38},29,18,ink,'left')
  paragraph('One second chance after a Farkle.\nReroll the same dice once per commission.',450,516,470,126,26,17)
  fitted('NO MEDAL',{x=1010,y=458,w=470,h=38},29,18,ink,'left')
  paragraph('Continue with your current dice\nand no additional effect.',1010,516,470,126,26,17)
  button(u,'medal','Equip the Corrector',440,685,490,85,true,function() R.choose_medal(s,'retry');u:sync();u:log('medal') end,true)
  button(u,'none','Continue without a medal',990,685,490,85,true,function() R.choose_medal(s,'none');u:sync();u:log('no_medal') end)
 end
 Res.end_ui()
end
function V.overlay(u,hits)
 u.hits=hits
 local g=love.graphics;local s=u.game
 local eligible=H.eligible(s)
 -- Only unobtrusive outlines on the 3D dice; all text stays outside the tray.
 for _,h in ipairs(hits or {}) do local i=h.index or h.roll_index
  if i and (s.selected[i] or s.used[i] or eligible[i]) then
   g.setColor(unpack(s.selected[i] and Art.rgba('ochre_light',1)
     or s.used[i] and Art.rgba('sage_light',.85)
     or Art.rgba('ochre_light',.55)))
   g.setLineWidth(s.selected[i] and 3 or 1)
   g.circle('line',h.x,h.y,(h.r or 25)+4)
  end
 end
 g.setLineWidth(1)
if H.reward_active(s) then reward(u);return end
 if not u.modal then return end
 if u.modal=='run' or u.modal=='run_restart_confirm'
  or u.modal=='run_exit_confirm' then
  draw_pause(u)
  return
 end
 Res.begin_ui();g.setColor(unpack(Art.rgba('ink',.82)));g.rectangle('fill',0,0,1920,1080)
 local area=ModalLayout.frame
 panel(area.x,area.y,area.w,area.h);u.modalButtons={}
 local saved=u.buttons;u.buttons=u.modalButtons
 local close=ModalLayout.close
 button(u,'close','Close [Esc]',close.x,close.y,close.w,close.h,
  true,function() u.modal=nil end)
 MenuSurface.rule(ModalLayout.header_rule.x,ModalLayout.header_rule.y,
  ModalLayout.header_rule.w,RuntimeUI.high_contrast() and 1 or .8)
 if u.modal=='medals' or u.modal=='medaluse' then
  MedalPanel.draw(u,txt,button,paragraph)
 elseif u.modal=='folio' then
    txt('THE MANUSCRIPT',425,180,750,30)
    -- Same folio renderer used by the in-game side panel; the previous
    -- unbound manuscript(...) call crashed every time this modal opened.
    FolioView.draw(s,u.presentation,665,245,510,625,txt,R.contracts[s.stage].target)
    paragraph(R.contracts[s.stage].condition,435,882,1050,49,24,15)
 else
  txt('FARKLE RULES',425,180,800,30)
  local sections=H.help_sections(s);u.helpTab=math.max(1,math.min(3,u.helpTab or 1))
  for i,section in ipairs(sections) do
   button(u,'helpTab'..i,section.title,425+(i-1)*360,250,350,60,true,function() u.helpTab=i end,u.helpTab==i)
  end
  local section=sections[u.helpTab]
  if section.rows then
   paragraph(section.lines[1],445,329,1030,56,27,17)
   local headers={'Face','Three of a kind','Four of a kind','Five of a kind','Six of a kind'}
   for j,label in ipairs(headers) do
    fitted(label,{x=445+(j-1)*210,y=388,w=200,h=39},
     25,13,gold,'left')
   end
   for i,row in ipairs(section.rows) do
    g.setColor(unpack(Art.rgba(i%2==0 and 'surface_alt' or 'surface')))
    g.rectangle('fill',435,432+(i-1)*47,1060,47)
    for j,value in ipairs(row) do
     fitted(value,{x=445+(j-1)*210,y=436+(i-1)*47,w=200,h=39},
      26,14,ink,'left')
    end
   end
   paragraph(section.lines[2],445,735,1030,55,26,16)
   paragraph(section.lines[3],445,794,1030,55,26,16)
  else
   for i,line in ipairs(section.lines) do
    paragraph(line,445,333+(i-1)*76,1030,66,26,17)
   end
  end
  paragraph('Left/right arrows: change tab · Esc: close',445,887,1030,45,22,14,muted)

 end
 u.buttons=saved;Res.end_ui()
end
return V
end)()
Bundle.hud_module = (function()
local Parts = {}

-- HUD actions
Parts.actions = (function()
-- UI 2.0 experimental command model. Pure LÖVE-free action registration.
-- Authoritative scoring and side effects stay in R / controller.  This
-- action model is separate from geometry, painting and mouse picking.
local R=require('src.farkle.rules')
local H=require('src.farkle.presentation').hud_model
local Medals=R.medals
local M={}

local function entry(id,label,enabled,fn,slot,detail)
 return {id=id,label=label,enabled=not not enabled,fn=fn,slot=slot,detail=detail}
end

function M.build(u)
 local s=assert(u.game,'UI 2.0 actions require authoritative Farkle game')
 local a={}
 local function add(id,label,enabled,fn,slot,detail)
  a[#a+1]=entry(id,label,enabled,fn,slot,detail)
 end
 local block=s.phase=='rolling'
 if H.reward_active(s) then return a end
 add('help','Regole [?]',not block,function() u.modal='help' end,'header')
 add('runmenu','Pausa [Esc]',not block,function() u.modal='run' end,'header')
 -- The page remains accessible via F; the large always-clickable folio
 -- card is not part of the normal table. The comparison layout still exposes this action.
 if not u.minimalHud then
  add('folio','Apri folio [F]',not block,function() u.modal='folio' end,'folio')
 end
 if s.medal~='none' then
  local d=Medals.get(s.medal)
  local uses=Medals.remaining(s)
  add('medaluse',(d and d.label or 'Correttore')..' · '..uses..' usi',
    d~=nil and not block and not H.commission_closed(s),
    function() u.medalDice={};u.modal='medaluse' end,'context')
 end

 if u.physicalFailure then
  add('retryphysical','Riprova tiro fisico',true,
   function() u:retry_physical() end,'primary','Recupero tecnico, non Farkle')
 elseif s.phase=='rescue' then
  add('rescue','Usa Correttore [M]',true,
   function() u:request(true) end,'primary','Salva il turno')
  add('fail','Accetta Farkle',true,
   function() u:act('accept_bust',function() return R.fail(s) end) end,
   'secondary','Perdi i punti a rischio')
 elseif H.commission_closed(s) then
  if s.phase=='advance' then
   add('next','Prossima commissione [N]',true,
     function() u:act('next',function() return R.advance(s) end) end,'primary')
  end
 elseif s.phase=='ended' then
  add('next','Prossimo turno [N]',true,
   function() u:act('next',function() return R.next_turn(s) end) end,'primary')
 else
  local pts=R.selection(s)
  local has_selection=next(s.selected)~=nil
  if has_selection then
   local label=pts and ('Accantona · '..pts..' pt')
     or (H.can_complete(s) and 'Completa la combinazione' or 'Selezione non valida')
   add('take',label,
     pts~=nil,function() u:act('take',function() return R.take(s) end) end,
     'primary',u.minimalHud and '[A] · Aggiungi ai punti a rischio'
       or '[A] · Convalida la combinazione')
  else
   local can=R.can_roll(s) and u.manualRoll==nil
   local label=s.hot and 'Rilancia sei dadi' or
     (s.phase=='fresh' and 'Lancia i sei dadi' or
       'Rilancia '..R.count_free(s)..' dadi')
   if not u.minimalHud or can then
    add('roll',label,can,function() u:request() end,
     'primary','[Spazio] · Destro: presa fisica')
   end
  end
  local ok,total,min=R.bank_status(s)
  -- Existing Farkle rules permit banking a VALID selected combination
  -- directly, without forcing a separate Set aside action first.
  add('bank','Incassa '..total..' pt',ok,
   function() u:act('bank',function() return R.bank_turn(s) end) end,
   'secondary',u.minimalHud and
      (min>0 and ('[Invio] · Soglia '..min..' pt') or '[Invio] · Metti al sicuro')
      or ('[Invio] · minimo '..min..' pt'))
 end
 return a
end

function M.state(u)
 if u.mouseThrow then
  local count=u.mouseThrow.held and #u.mouseThrow.held or 1
  return count>1 and ('GRUPPO DI '..count..' DADI IN MANO · Esc annulla') or
    'DADO IN MANO · Muovi, rilascia; Esc annulla'
 end
 if u.manualRoll then
  return 'LANCIO MANUALE · '..u.manualRoll.count..' dadi ancora da lanciare'
 end
 return H.state_text(u)
end

return M
end)()

-- Accepted dice register
Parts.accepted = (function()
local Typography=require('src.core.presentation').typography
-- UI 2.0: accepted-dice manuscript register. No old walnut canalina.
-- Drawn AFTER g3d so accepted dice never occupy the 3D rolling surface.
-- Captures use only g3d; no CPU painter, legacy HUD or gameplay mutation.
local Layout=Bundle.layout
local Presentation=require('src.farkle.presentation')
local Res=require('src.core.navigation').resolution
local UI=require('src.core.runtime_state').ui
local M={}
local fonts={}
local function font(n)
 local px=math.floor(n*(UI.big_text() and 1.15 or 1)+.5)
 if not fonts[px] then
  fonts[px]=Typography.load(Typography.primary,px)
 end
 return fonts[px]
end
function M.slots(layout)
 local area=(layout or Layout.build('single_folio')).shelf
 local result={}
 local gutter=12
 local step=(area.w-gutter*2)/6
 for i=1,6 do
  result[i]={x=area.x+gutter+(i-1)*step,y=area.y+4,
   w=step-4,h=area.h-8}
 end
 return result
end

function M.draw(u)
 local s=u and u.game
 if not s or not s.used then return end
 local g=love.graphics
 local minimal=u.minimalHud==true
 local slots=M.slots(Layout.build(minimal and 'table_minimal' or 'single_folio'))
 local p=u.presentation
 local contributors=p and Presentation.contributing_dice(p) or {}
 g.push('all')
 Res.begin_ui()
 for i,rect in ipairs(slots) do
  local used=s.used[i] and true or false
  -- No permanent row of six blank boxes on the minimal player table.
  if not minimal or used then
  local active=contributors[i] and true or false
  local high=UI.high_contrast()
  -- The register should read as six inset parchment tokens rather than
  -- detached dark boxes; no geometry or 3D portrait logic changes.
  if active then g.setColor(.99,.88,.59,.98)
  elseif used then g.setColor(.93,.85,.71,.98)
  else g.setColor(.78,.70,.55,high and .87 or .72) end
  g.rectangle('fill',rect.x,rect.y,rect.w,rect.h,5)
  if active then g.setColor(.64,.38,.11,1)
  else g.setColor(high and .20 or .45,.33,.20,.88) end
  g.setLineWidth(active and 2.4 or 1)
  g.rectangle('line',rect.x+.5,rect.y+.5,rect.w-1,rect.h-1,5)
  local entry=p and p.shelf and p.shelf[i]
  if used and entry and dice and dice[i] and u.trayProjection then
   if not entry.g3dPortrait then
    entry.g3dPortrait=require('src.engine3d.g3d.live').portrait
     .capture(dice[i],u.trayProjection,i)
   end
   if entry.g3dPortrait then
    g.push('all')
    g.setBlendMode('alpha','premultiplied')
    g.setColor(1,1,1,1)
    local scale=.37
    g.draw(entry.g3dPortrait,rect.x+9,rect.y+1,0,scale,scale)
    g.pop()
   end
  end
  g.setFont(font(17))
  g.setColor(used and .23 or .38,used and .16 or .30,
   used and .10 or .22,1)
  local label=used and tostring(s.hand and s.hand[i] or i) or tostring(i)
  g.printf(label,rect.x+rect.w-45,rect.y+15,36,'center')
  end
 end
 Res.end_ui()
 g.pop()
end
return M
end)()

-- Table HUD
Parts.hud = (function()
local Typography=require('src.core.presentation').typography
-- Shipping folio HUD: one presentation path, one authoritative hitbox table.
-- g3d owns physical dice and tray. Non-modal HUD no longer imports old HUD.
-- Gameplay rules and six physical D6 are owned elsewhere; this module paints only the HUD.
local Actions=Parts.actions
local Layout=Bundle.layout
local R=require('src.farkle.rules')
local H=require('src.farkle.presentation').hud_model
local Res=require('src.core.navigation').resolution
local UI=require('src.core.runtime_state').ui
local Folio=require('src.farkle.presentation').folio_view
local Accepted=Parts.accepted
local Dialogs=Bundle.dialogs
local Indicators=Bundle.overlay
local MenuSurface=require('src.screens.folio_surface').menu_surface
local OpponentScene=Bundle.opponent_scene
local LabelFit=Bundle.text_fit.label
local Art=require('src.data.frontend_schema').palette
local AudioManager=require('src.core.audio_manager')
local V={}
local fonts={}
local modal_states=setmetatable({},{__mode='k'})
local unpack=table.unpack or unpack
local function rgba(r,g,b,a) return {r,g,b,a or 1} end
local ink=Art.rgba('text')
local pale=Art.rgba('surface')
local muted=Art.rgba('quiet')
local highlight=Art.rgba('ochre_light')
-- UI surfaces use the same palette as the menu; the physical 3D dice
-- and their underlying renderer/materials remain untouched.
local parchment=Art.rgba('surface',.98)
local border_ink=Art.rgba('border',.92)
local paper_ink=Art.rgba('text')
local paper_muted=Art.rgba('text_muted')
local paper_gold=Art.rgba('reward')
local paper_warning=Art.rgba('risk')
local function size(n)
 return math.floor(n*math.min(1.35,UI.scale())*
     (UI.big_text() and 1.16 or 1)+.5)
end
local function font_px(px)
 if not fonts[px] then
  fonts[px]=Typography.load(Typography.primary,px)
 end
 return fonts[px]
end
local function font(n)
 return font_px(size(n))
end
local function write(label,x,y,w,pt,color,align)
 local g=love.graphics
 g.setFont(font(pt))
 g.setColor(unpack(color or pale))
 g.printf(tostring(label),x,y,w,align or 'left')
end
-- One measured line per visual cell: no wraps behind other controls.
-- Use font metrics (not string length), with UTF-8-safe abbreviation only
-- when a readable minimum size still cannot fit the available rectangle.
local function write_fitted(value,rect,pt,min_pt,color,align)
 local g=love.graphics
 local text,px=LabelFit.fit(value,function(s,n)
  local f=font_px(n)
  return f:getWidth(s),f:getHeight()
 end,size(pt),size(min_pt or math.max(10,pt*.7)),rect.w,rect.h)
 if text=='' then return end
 local face=font_px(px)
 g.setFont(face)
 g.setColor(unpack(color or paper_ink))
 g.printf(text,rect.x,rect.y+math.max(0,(rect.h-face:getHeight())*.5),
  rect.w,align or 'left')
end
local function panel(r,fill,stroke,radius)
 local g=love.graphics
 g.setColor(unpack(fill));g.rectangle('fill',r.x,r.y,r.w,r.h,radius or 5)
 if stroke then
  g.setColor(unpack(stroke));g.setLineWidth(1.4)
  g.rectangle('line',r.x+.8,r.y+.8,r.w-1.6,r.h-1.6,radius or 5)
 end
end
local function pointer_over(rect)
 if not (love.mouse and love.mouse.getPosition) then return false end
 local mx,my=love.mouse.getPosition()
 if type(mx)~='number' or type(my)~='number' then return false end
 local vx,vy=Res.to_virtual(mx,my)
 return MenuSurface.contains(rect,vx,vy)
end
local function action_button(u,a,rect)
 local isPrimary=a.slot=='primary'
 -- Every visible control uses the same rectangular hitbox as the
 -- authoritative controller action table; no decorative overlay eats input.
 -- Give even disabled actions a light leaf underneath: their semi-transparent
 -- shared widget fill would otherwise sit directly on the dark desk.
 panel(rect,parchment,nil,5)
 MenuSurface.item(rect,{primary=isPrimary,disabled=not a.enabled,
   active=a.enabled and pointer_over(rect)})
 local caption={x=rect.x+12,y=rect.y+8,w=rect.w-24,
   h=a.detail and rect.h>=66 and 32 or rect.h-16}
 write_fitted(a.label,caption,a.slot=='context' and 17 or 24,14,
   a.enabled and paper_ink or paper_muted,'center')
 if a.detail and rect.h>=66 then
  local detail={x=rect.x+8,y=rect.y+44,w=rect.w-16,h=rect.h-50}
  write_fitted(a.detail,detail,15,11,paper_muted,'center')
 end
 u.buttons[a.id]={x=rect.x,y=rect.y,w=rect.w,h=rect.h,
    enabled=a.enabled,fn=a.fn,label=a.label}
end
local function turns_remaining(s,c)
 return math.max(0,c.limit-s.turn+
   ((s.phase=='ended' or H.commission_closed(s)) and 0 or 1))
end
local function header(u,s,layout,actions)
 local g=love.graphics
 local c=R.contracts[s.stage]
 local readout=layout.header_readout
 panel(layout.header,parchment,border_ink,7)
 -- The commission name and the four numbers occupy measured cells:
 -- long campaign titles and large-text settings cannot wrap into stats.
 write_fitted('COMMISSIONE '..s.stage..'/3',
   readout.commission_tag,18,12,paper_gold)
 write_fitted(c.name,readout.commission_name,18,12,paper_ink)
 local remaining=turns_remaining(s,c)
 local values={
  {'OBIETTIVO',c.target..' pt'},
  {'ASSICURATI',s.bank..' pt'},
  {'A RISCHIO',s.pot..' pt'},
  {'TURNI',tostring(remaining)}
 }
 g.setLineWidth(1)
 g.setColor(border_ink[1],border_ink[2],border_ink[3],
   UI.high_contrast() and .70 or .34)
 for _,x in ipairs(readout.dividers) do
  g.line(x,30,x,82)
 end
 for i,v in ipairs(values) do
  local cell=readout.metrics[i]
  write_fitted(v[1],cell.caption,13,10,paper_muted)
  write_fitted(v[2],cell.value,24,15,
   i==3 and paper_warning or paper_ink)
 end
 for _,a in ipairs(actions) do
  if a.slot=='header' then
   action_button(u,a,a.id=='help' and readout.help or readout.runmenu)
  end
 end
end
local function work_surface(layout)
 local g=love.graphics
 g.setColor(.077,.060,.047,1)
 g.rectangle('fill',0,0,1920,1080)
 -- A broad opened working leaf; the actual 3D tray floor and dice are
 -- rendered over this by the unchanged engine with the same projection.
 panel(layout.book,Art.rgba('earth'),Art.rgba('ink'),10)
 panel(layout.page_main,Art.rgba('surface_alt',.88),Art.rgba('border',.70),5)
 g.setColor(unpack(Art.rgba('border',.42)))
 g.setLineWidth(2)
 g.line(layout.page_main.x+15,layout.page_main.y+15,
        layout.page_main.x+15,layout.page_main.y+layout.page_main.h-15)
 -- Never draw over the 3D throw rectangle. Ornamentation lives
 -- only in the book margins between the six accepted slots and tray.
 if layout.shelf_caption then
  -- A narrow illuminated rubric stays legible across the leather/paper
  -- seam at the top of the leaf, above every accepted-die rectangle.
  panel(layout.shelf_caption,Art.rgba('surface',.98),nil,4)
  write_fitted('REGISTRO DEI DADI ACCANTONATI',layout.shelf_caption,
   14,11,paper_ink,'center')
  g.setColor(unpack(Art.rgba('border',UI.high_contrast() and .90 or .52)))
  g.setLineWidth(1)
  g.line(layout.shelf_divider.x,layout.shelf_divider.y,
   layout.shelf_divider.x+layout.shelf_divider.w,
   layout.shelf_divider.y)
 end
 -- A restrained bookbinding frame joins the working leaf and notes
 -- without changing the folio's actual geometry or interaction.
 if layout.sidebar_frame then
  local side=layout.sidebar_frame
  panel(side,Art.rgba('earth_dark'),Art.rgba('timber',.97),9)
  g.setColor(unpack(Art.rgba('ochre_light',UI.high_contrast() and .86 or .40)))
  g.setLineWidth(1)
  g.rectangle('line',side.x+7,side.y+7,side.w-14,side.h-14,6)
  for _,y in ipairs({side.y+22,side.y+side.h-22}) do
   g.line(side.x+9,y,side.x+17,y)
   g.line(side.x+side.w-17,y,side.x+side.w-9,y)
  end
 end
end
local function compact_status(u)
 local s=u.game
 if u.mouseThrow or u.manualRoll then return Actions.state(u) end
 if u.physicalFailure then return 'Tiro non valido: usa Riprova tiro fisico.' end
 if s.phase=='rolling' then return 'I dadi stanno rotolando…' end
 if s.phase=='fresh' then return '' end
 if s.phase=='rescue' then return 'FARKLE · Usa il Correttore o accetta la perdita.' end
 if s.phase=='ended' then return 'Turno concluso · Continua con [N].' end
 if s.phase=='lost' then return 'Partita terminata · Nessun turno rimasto.' end
 if s.phase=='won' then return 'Partita completata.' end
 if s.phase=='advance' then return 'Obiettivo raggiunto · Prosegui con [N].' end
 if s.phase=='upgrade' or s.phase=='medal' then
  return 'Obiettivo raggiunto · Scegli una ricompensa.'
 end
 if s.hot then return 'Dadi caldi · Rilancia tutti e sei oppure incassa.' end
 if next(s.selected) then
  if R.selection(s) then return '' end
  if H.can_complete(s) then return 'Aggiungi i dadi che completano la combinazione.' end
  return 'Deseleziona i dadi che non fanno parte di una combinazione.'
 end
 if s.scored then return '' end
 local eligible=H.eligible(s)
 local keys={}
 for i=1,6 do if eligible[i] then keys[#keys+1]='['..i..']' end end
 if #keys==0 then return '' end
 return 'Scegli i dadi segnati · clic o tasti '..table.concat(keys,' ')
end
local merchant_room,room_edges,active_room_path
local atmosphere_shader
local function draw_room(path,depth)
 local g=love.graphics
 local w,h=Layout.virtual_w,Layout.virtual_h
 if active_room_path~=path then
  merchant_room=g.newImage(path)
  active_room_path=path
  local iw,ih=merchant_room:getWidth(),merchant_room:getHeight()
  -- Mirror only a strip of the empty room past the composition on
  -- non-16:9 windows. Never duplicate the host or rescale the seam.
  local side,top,base=math.max(1,math.floor(iw*.09)),
   math.max(1,math.floor(ih*.012)),math.max(1,math.floor(ih*.07))
  room_edges={left=g.newQuad(0,0,side,ih,iw,ih),right=g.newQuad(iw-side,0,side,ih,iw,ih),
   top=g.newQuad(0,0,iw,top,iw,ih),base=g.newQuad(0,ih-base,iw,base,iw,ih),
   side=side,top_h=top,base_h=base}
 end
 local iw,ih=merchant_room:getWidth(),merchant_room:getHeight()
 local x,y=Res.to_virtual(0,0)
 g.push()
 if depth then
  local o=OpponentScene.depth
  g.translate(w*.5-depth.x*o.room,h*.5-depth.y*o.room_y)
  g.scale(o.overscan,o.overscan)
  g.translate(-w*.5,-h*.5)
 end
 g.setColor(1,1,1,1)
 if not atmosphere_shader and g.newShader then
  local ok,shader=pcall(g.newShader,'resources/shaders/dream_atmosphere.glsl')
  if ok then atmosphere_shader=shader end
 end
 if atmosphere_shader then
  local time=0
  if not UI.reduced_animations() and love.timer and love.timer.getTime then
   time=love.timer.getTime()
  end
  atmosphere_shader:send('dreamTime',time)
  g.setShader(atmosphere_shader)
 end
 g.draw(merchant_room,0,0,0,w/iw,h/ih)
 if x<-.001 then
  g.draw(merchant_room,room_edges.left,0,0,0,x/room_edges.side,h/ih)
  g.draw(merchant_room,room_edges.right,w-x,0,0,x/room_edges.side,h/ih)
 elseif y<-.001 then
  g.draw(merchant_room,room_edges.top,0,0,0,w/iw,y/room_edges.top_h)
  g.draw(merchant_room,room_edges.base,0,h-y,0,w/iw,y/room_edges.base_h)
 end
 if atmosphere_shader then g.setShader() end
 g.pop()
 g.setColor(1,1,1,1)
end
-- Soft contact shadow grounds the g3d table on the printshop floor.
local table_shadow
local function draw_table_shadow(g)
 if not table_shadow and g.newMesh then
  local c=Art.rgb('earth_dark')
  local function v(x,y,a) return {x,y,0,0,c[1],c[2],c[3],a} end
  local top={v(170,976,0),v(260,976,.62),v(1660,976,.62),v(1750,976,0)}
  local low={v(130,1060,0),v(260,1060,0),v(1660,1060,0),v(1790,1060,0)}
  local tris={}
  for i=1,3 do
   for _,p in ipairs({top[i],top[i+1],low[i+1],top[i],low[i+1],low[i]}) do
    tris[#tris+1]=p
   end
  end
  table_shadow=g.newMesh(tris,'triangles','static')
 end
 if table_shadow then
  g.setColor(1,1,1,1)
  g.draw(table_shadow)
 end
end
local function scene_depth(u,g)
 local reduced=UI.reduced_animations()
 local t=love.timer and love.timer.getTime and love.timer.getTime() or 0
 local dt=love.timer and love.timer.getDelta and love.timer.getDelta() or 0
 local nx,ny=0,0
 if love.mouse and love.mouse.getPosition then
  local px,py=love.mouse.getPosition()
  local ww,wh=g.getDimensions()
  -- Dampen drift while aiming a throw so the room never fights the hand.
  local gain=u.mouseThrow and .25 or 1
  nx,ny=(px/ww*2-1)*gain,(py/wh*2-1)*gain
 end
 local depth=OpponentScene.parallax(dt,nx,ny,t,reduced)
 depth.breath=reduced and 0 or math.sin(t*1.3)
 return depth
end
local function draw_minimal_footer(u,layout,actions)
 local s=u.game
 local g=love.graphics
 -- Keep the timber plaque small and never show an empty panel while
 -- the dice are rolling. Controls are actual actions, not placeholders.
 local visible_controls,has_context=0,false
 for _,a in ipairs(actions) do
  if a.slot=='context' then
   has_context=true
   visible_controls=visible_controls+1
  elseif a.slot=='primary' or a.slot=='secondary' and (a.id~='bank' or a.enabled) then
   visible_controls=visible_controls+1
  end
 end
 if visible_controls>0 then
  -- Walnut plaque hung from the table's front edge on two brass brackets.
  local f=layout.footer
  local brass=Art.rgba('ochre',.95)
  g.setColor(unpack(Art.rgba('ink',.55)))
  g.rectangle('fill',f.x+6,f.y+6,f.w,f.h,4)
  for _,bx in ipairs({f.x+f.w*.12,f.x+f.w*.88}) do
   g.setColor(unpack(Art.rgba('ochre_dark',.95)))
   g.rectangle('fill',bx-9,f.y-10,18,16,2)
  end
  panel(f,Art.rgba('earth_dark',.98),Art.rgba('ink',.9),4)
  g.setColor(unpack(Art.rgba('earth',.55)))
  g.rectangle('fill',f.x+3,f.y+3,f.w-6,f.h*.35,3)
  local trim=layout.footer_trim
  g.setColor(unpack(Art.rgba('ochre_light',.45)))
  g.rectangle('fill',trim.x,trim.y,trim.w,trim.h)
  g.setColor(unpack(brass))
  g.setLineWidth(1.5)
  g.rectangle('line',f.x+6,f.y+6,f.w-12,f.h-12,3)
  for _,p in ipairs({{f.x+13,f.y+13},{f.x+f.w-13,f.y+13},{f.x+13,f.y+f.h-13},{f.x+f.w-13,f.y+f.h-13}}) do
   g.setColor(unpack(Art.rgba('ochre_light',.95)))
   g.circle('fill',p[1],p[2],3.2)
   g.setColor(unpack(Art.rgba('ink',.6)))
   g.circle('line',p[1],p[2],3.2)
  end
 end
 -- Only real accepted dice are painted on this unobtrusive register.
 if next(s.used) then
  write_fitted('DADI ACCANTONATI',layout.shelf_label,16,12,Art.rgba('ochre_light'))
 end
 local choosing=s.phase=='ready' and not s.scored and not next(s.selected) and not u.physicalFailure
 local notice_rect=(visible_controls==0 or choosing)
   and layout.idle_message or layout.message
 write_fitted(compact_status(u),notice_rect,choosing and 20 or 18,12,
   (s.phase=='rescue' or s.phase=='lost') and Art.rgba('clay') or pale,
   'center')
 local primary,secondary=layout.primary,layout.secondary
 if not has_context then
  if visible_controls==1 then
   primary,secondary=layout.single_action,layout.single_action
  elseif visible_controls==2 then
   -- This frame owns its layout. Slide the pair together so the gap
   -- stays the same and the two outer edges balance on the tray axis.
   local axis=layout.tray.x+layout.tray.w/2
   local shift=axis-(primary.x+secondary.x+secondary.w)/2
   primary.x,secondary.x=primary.x+shift,secondary.x+shift
  end
 end
 local context=0
 for _,a in ipairs(actions) do
  if a.slot=='context' then
   context=context+1
   local rect=assert(layout.context_actions[context],
    'missing minimal table context slot')
   action_button(u,a,rect)
  elseif a.slot=='primary' then
   action_button(u,a,primary)
  elseif a.slot=='secondary' and (a.id~='bank' or a.enabled) then
   action_button(u,a,secondary)
  end
 end
end
local function draw_minimal(u)
 local s=u.game
 local layout=Layout.build('table_minimal')
 local actions=Actions.build(u)
 local g=love.graphics
 u.buttons={}
 g.push('all')
 Res.begin_ui()
 g.setColor(.077,.060,.047,1)
 g.rectangle('fill',0,0,1920,1080)
 local visual=OpponentScene.resolve(u.opponentId,OpponentScene.available)
 local depth=scene_depth(u,g)
 draw_room(visual.room,depth)
 OpponentScene.draw_portrait(visual,layout,g,depth)
 draw_table_shadow(g)
 -- Keep both sides of the wager in one legible scorecard.
 panel(layout.score_panel,Art.rgba('surface',.93),border_ink,7)
 g.setColor(unpack(Art.rgba('border',.48)))
 g.setLineWidth(1)
 g.line(246,27,246,129)
 g.line(61,77,441,77)
 panel({x=1494,y=20,w=382,h=72},Art.rgba('surface',.93),border_ink,7)
 write_fitted('ASSICURATI',layout.secured_caption,17,12,paper_muted)
 write_fitted(s.bank..' pt',layout.secured_value,29,18,paper_ink)
 write_fitted('A RISCHIO',layout.risk_caption,17,12,paper_muted)
 write_fitted(s.pot..' pt',layout.risk_value,29,18,paper_warning)
 local c=R.contracts[s.stage]
 write_fitted('OBIETTIVO',layout.objective_caption,15,11,paper_muted)
 write_fitted(c.target..' pt',layout.objective_value,25,16,paper_gold)
 write_fitted('TURNI RIMASTI',layout.turns_caption,15,11,paper_muted)
 write_fitted(turns_remaining(s,c),layout.turns_value,25,16,paper_ink)
 for _,a in ipairs(actions) do
  if a.slot=='header' then
   action_button(u,a,a.id=='help' and layout.help or layout.runmenu)
  end
 end
 -- Register footer hitboxes now; V.overlay paints them above the 3D table.
 g.setColorMask(false,false,false,false)
 draw_minimal_footer(u,layout,actions)
 g.setColorMask(true,true,true,true)
 Res.end_ui()
 g.pop()
end

function V.draw(u)
 if u.minimalHud then return draw_minimal(u) end
 local s=u.game
 if not s then return end
 local layout=Layout.build('single_folio')
 local actions=Actions.build(u)
 u.buttons={} -- a single authoritative hitbox table for controller.lua
 local g=love.graphics
 g.push('all')
 Res.begin_ui()
 work_surface(layout)
 header(u,s,layout,actions)
 if layout.sidebar_caption then
  write_fitted('MANOSCRITTO',layout.sidebar_caption,17,13,
   Art.rgba('ochre_light'), 'center')
 end
 Folio.draw(s,u.presentation,layout.folio.x,layout.folio.y,
            layout.folio.w,layout.folio.h,write,R.contracts[s.stage].target)
 for _,a in ipairs(actions) do
  if a.slot=='folio' then
   local r=layout.folio
   -- The folio itself is the clickable action, not an overlay button.
   u.buttons[a.id]={x=r.x,y=r.y,w=r.w,h=r.h,
                     enabled=a.enabled,fn=a.fn,label=a.label}
  end
 end
 if layout.sidebar_divider then
  MenuSurface.rule(layout.sidebar_divider.x,layout.sidebar_divider.y,
   layout.sidebar_divider.w,UI.high_contrast() and 1 or .82)
 end
 panel(layout.context,parchment,border_ink,5)
 write_fitted('STRUMENTI',layout.context_caption,14,11,paper_gold,'center')
 local c=0
 for _,a in ipairs(actions) do
  if a.slot=='context' then
   c=c+1
   -- Exactly the same input geometry as before; it is now named and
   -- validated alongside the decorative folio/sidebar proportions.
   local rect=assert(layout.context_actions[c],
    'missing visual-only contextual button slot')
   action_button(u,a,rect)
  end
 end
 if c==0 then
  write_fitted('Consulta la pagina [F]',
    {x=layout.context.x+12,y=layout.context.y+53,
     w=layout.context.w-24,h=38},17,12,paper_muted,'center')
 end
 -- Treat the actual state message as a manuscript status strip,
 -- not free-floating small text on the dark desk.
 panel(layout.message,Art.rgba('surface',.98),border_ink,5)
 write_fitted(Actions.state(u),
   {x=layout.message.x+12,y=layout.message.y+2,
    w=layout.message.w-24,h=layout.message.h-4},18,12,
   (s.phase=='rescue' or s.phase=='lost') and paper_warning or paper_ink,
   'center')
 for _,a in ipairs(actions) do
  if a.slot=='primary' then action_button(u,a,layout.primary)
  elseif a.slot=='secondary' then action_button(u,a,layout.secondary) end
 end

 Res.end_ui()
 g.pop()
end

-- Physical and scoring indicators are non-mutating screen-space strokes.
-- Accepted dice belong to the V2 register; only dialog/reward content
-- stays in the shared modal presenter until a separate P4 redesign.
function V.overlay(u,hits)
 u.hits=hits
 if u.minimalHud then
  local previous=modal_states[u]
  if previous~=u.modal then
   if u.modal then AudioManager.play_ui('menu_open')
   elseif previous then AudioManager.play_ui('menu_close') end
   modal_states[u]=u.modal
  end
 end
 if u.minimalHud and u.game then
  local g=love.graphics
  g.push('all')
  Res.begin_ui()
  draw_minimal_footer(u,Layout.build('table_minimal'),Actions.build(u))
  Res.end_ui()
  g.pop()
 end
 Indicators.draw(u,hits)
 Accepted.draw(u)
 if H.reward_active(u.game) or u.modal then
  Dialogs.overlay(u,hits)
 end
end
return V
end)()

Parts.hud.actions = Parts.actions
Parts.hud.accepted = Parts.accepted
return Parts.hud
end)()
Bundle.hud = Bundle.hud_module
return Bundle
