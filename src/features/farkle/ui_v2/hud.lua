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
local function size(n)
 return math.floor(n*math.min(1.35,UI.scale())*
     (UI.big_text() and 1.16 or 1)+.5)
end
local function font(n)
 n=size(n)
 if not fonts[n] then
  fonts[n]=love.graphics.newFont('resources/font/IMFeENsc28P.ttf',n)
 end
 return fonts[n]
end
local function write(label,x,y,w,pt,color,align)
 local g=love.graphics
 g.setFont(font(pt))
 g.setColor(unpack(color or pale))
 g.printf(tostring(label),x,y,w,align or 'left')
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
 write(a.label,rect.x+12,rect.y+(rect.h>=66 and 10 or 11),rect.w-24,
   a.slot=='context' and 17 or 24,
   a.enabled and paper_ink or paper_muted,'center')
 if a.detail and rect.h>=66 then
  write(a.detail,rect.x+8,rect.y+46,rect.w-16,15,
    paper_muted,'center')
 end
 u.buttons[a.id]={x=rect.x,y=rect.y,w=rect.w,h=rect.h,
    enabled=a.enabled,fn=a.fn,label=a.label}
end
local function header(u,s,layout,actions)
 local g=love.graphics
 local c=R.contracts[s.stage]
 panel(layout.header,parchment,border_ink,7)
 write('COMMISSIONE '..s.stage..'/3',70,26,300,18,paper_gold)
 write(c.name,70,53,402,16,paper_ink)
 local remaining=math.max(0,c.limit-s.turn+
     ((s.phase=='ended' or H.commission_closed(s)) and 0 or 1))
 local values={
  {'OBIETTIVO',c.target..' pt',520},
  {'ASSICURATI',s.bank..' pt',744},
  {'A RISCHIO',s.pot..' pt',970},
  {'TURNI',tostring(remaining),1190}
 }
 for _,v in ipairs(values) do
  write(v[1],v[3],28,195,13,paper_muted)
  write(v[2],v[3],50,195,24,v[1]=='A RISCHIO' and paper_gold or paper_ink)
 end
 for _,a in ipairs(actions) do
  if a.slot=='header' then
   local rect=a.id=='help' and
      {x=1510,y=33,w=155,h=49} or {x=1682,y=33,w=156,h=49}
   action_button(u,a,rect)
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
 -- Do not paint opaque graphics over the projected physical D6 plane.
 g.setColor(.22,.16,.09,.4)
 g.line(layout.tray.x,layout.tray.y,
        layout.tray.x+layout.tray.w,layout.tray.y)
 write('REGISTRO DEI DADI ACCANTONATI',
       layout.shelf.x+18,layout.shelf.y+6,layout.shelf.w-36,15,ink)
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
 if not u.botDuel then
  write('MANOSCRITTO',layout.folio.x+4,layout.folio.y-21,
        layout.folio.w-8,17,highlight,'center')
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
 panel(layout.context,parchment,border_ink,5)
 write('STRUMENTI',layout.context.x+13,layout.context.y+7,
       layout.context.w-24,14,paper_gold)
 local c=0
 for _,a in ipairs(actions) do
  if a.slot=='context' then
   c=c+1
   action_button(u,a,{x=layout.context.x+12,
      y=layout.context.y+31+(c-1)*59,w=layout.context.w-24,h=52})
  end
 end
 if c==0 then
  write('Consulta la pagina [F]',layout.context.x+12,
      layout.context.y+62,layout.context.w-24,17,paper_muted,'center')
 end
 write(Actions.state(u),layout.message.x,
       layout.message.y,layout.message.w,18,
       (s.phase=='rescue' or s.phase=='lost') and rgba(.92,.44,.36) or pale,
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
