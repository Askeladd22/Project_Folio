local Typography=require('src.core.typography')
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
local OpponentScene=require('src.features.farkle.ui_v2.opponent_scene')
local LabelFit=require('src.features.farkle.ui_v2.label_fit')
local Art=require('src.data.art_palette')
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
