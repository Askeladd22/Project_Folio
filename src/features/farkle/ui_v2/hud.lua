-- Shipping folio HUD: one presentation path, one authoritative hitbox table.
-- g3d owns physical dice and tray. Non-modal HUD no longer imports old HUD.
-- Gameplay rules and six physical D6 are owned elsewhere; this module paints only the HUD.
local Actions=require('src.features.farkle.ui_v2.actions')
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local R=require('src.gameplay.farkle.rules')
local H=require('src.features.farkle.hud_model')
local Res=require('src.core.resolution_manager')
local UI=require('src.core.runtime_ui')
local Folio=require('src.features.farkle.folio_view')
local Accepted=require('src.features.farkle.ui_v2.accepted_dice')
local Dialogs=require('src.features.farkle.ui_v2.dialogs')
local Indicators=require('src.features.farkle.ui_v2.overlay')
local MenuSurface=require('src.features.ui_v2.menu_surface')
local LabelFit=require('src.features.farkle.ui_v2.label_fit')
local V={}
local fonts={}
local unpack=table.unpack or unpack
local function rgba(r,g,b,a) return {r,g,b,a or 1} end
local ink=rgba(.16,.13,.10)
local pale=rgba(.94,.89,.78)
local muted=rgba(.70,.65,.53)
local highlight=rgba(.95,.77,.36)
-- Match the frontend's illuminated folio, without covering the 3D dice field.
local parchment=rgba(.89,.81,.65,.98)
local border_ink=rgba(.48,.32,.16,.92)
local paper_ink=rgba(.24,.15,.09)
local paper_muted=rgba(.43,.32,.22)
local paper_gold=rgba(.53,.34,.12)
local paper_warning=rgba(.52,.20,.15)
local function size(n)
 return math.floor(n*math.min(1.35,UI.scale())*
     (UI.big_text() and 1.16 or 1)+.5)
end
local function font_px(px)
 if not fonts[px] then
  fonts[px]=love.graphics.newFont('resources/font/IMFeENsc28P.ttf',px)
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
 local remaining=math.max(0,c.limit-s.turn+
     ((s.phase=='ended' or H.commission_closed(s)) and 0 or 1))
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
 panel(layout.book,rgba(.64,.55,.40,1),rgba(.20,.13,.09,1),10)
 panel(layout.page_main,rgba(.87,.79,.63,.88),rgba(.48,.32,.19,.7),5)
 g.setColor(.41,.29,.18,.42)
 g.setLineWidth(2)
 g.line(layout.page_main.x+15,layout.page_main.y+15,
        layout.page_main.x+15,layout.page_main.y+layout.page_main.h-15)
 -- Never draw over the 3D throw rectangle. Ornamentation lives
 -- only in the book margins between the six accepted slots and tray.
 if layout.shelf_caption then
  write_fitted('REGISTRO DEI DADI ACCANTONATI',layout.shelf_caption,
   14,11,paper_ink,'center')
  g.setColor(.39,.27,.16,UI.high_contrast() and .90 or .52)
  g.setLineWidth(1)
  g.line(layout.shelf_divider.x,layout.shelf_divider.y,
   layout.shelf_divider.x+layout.shelf_divider.w,
   layout.shelf_divider.y)
 end
 -- A restrained bookbinding frame joins the working leaf and notes
 -- without changing the folio's actual geometry or interaction.
 if layout.sidebar_frame then
  local side=layout.sidebar_frame
  panel(side,rgba(.25,.18,.12,1),rgba(.68,.49,.26,.97),9)
  g.setColor(.86,.68,.39,UI.high_contrast() and .86 or .40)
  g.setLineWidth(1)
  g.rectangle('line',side.x+7,side.y+7,side.w-14,side.h-14,6)
  for _,y in ipairs({side.y+22,side.y+side.h-22}) do
   g.line(side.x+9,y,side.x+17,y)
   g.line(side.x+side.w-17,y,side.x+side.w-9,y)
  end
 end
end
function V.draw(u)
 local s=u.game
 if not s then return end
 local layout=Layout.build('single_folio')
 -- The Monk's status occupies the top of this sidebar: keep the
 -- manuscript folio BELOW it, never behind an opaque overlay.
 if u.botDuel then
  layout.folio={x=layout.folio.x,y=320,w=layout.folio.w,h=370}
 end
 local actions=Actions.build(u)
 u.buttons={} -- a single authoritative hitbox table for controller.lua
 local g=love.graphics
 g.push('all')
 Res.begin_ui()
 work_surface(layout)
 header(u,s,layout,actions)
 if not u.botDuel and layout.sidebar_caption then
  write_fitted('MANOSCRITTO',layout.sidebar_caption,17,13,
   rgba(.97,.85,.61), 'center')
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
 panel(layout.message,rgba(.89,.81,.65,.98),border_ink,5)
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
 Indicators.draw(u,hits)
 Accepted.draw(u)
 if H.reward_active(u.game) or u.modal then
  Dialogs.overlay(u,hits)
 end
end
return V
