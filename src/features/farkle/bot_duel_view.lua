-- Optional Farkle encounter with a FLAT illuminated-manuscript figure.
-- g3d remains the sole renderer for the physical six D6 and book tray.
-- The figure's return-to-folio motion is decorative, never a game rule.
local Miniature=require('src.features.scriptorium.miniature_2d')
local Model=require('src.features.farkle.bot_duel_presentation')
local Res=require('src.core.resolution_manager')
local RuntimeUI=require('src.core.runtime_ui')
local MenuSurface=require('src.features.ui_v2.menu_surface')
local LabelFit=require('src.features.farkle.ui_v2.label_fit')
local Geometry=require('src.features.farkle.ui_v2.monk_layout')
local M={}
local monk=nil
local status=Model.new()
local fonts={}
local function draw_fit(value,rect,pt,min_pt,color,align)
 local g=love.graphics
 local scale=math.min(1.35,RuntimeUI.scale())*
  (RuntimeUI.big_text() and 1.16 or 1)
 local hi=math.max(8,math.floor(pt*scale+.5))
 local lo=math.max(8,math.floor(min_pt*scale+.5))
 local str,px=LabelFit.fit(value,function(text,n)
  fonts[n]=fonts[n] or
   g.newFont('resources/font/IMFeENsc28P.ttf',n)
  return fonts[n]:getWidth(text),fonts[n]:getHeight()
 end,hi,lo,rect.w,rect.h)
 if str=='' then return end
 g.setFont(fonts[px])
 g.setColor(color[1],color[2],color[3],color[4] or 1)
 g.printf(str,rect.x,rect.y+math.max(0,
  (rect.h-fonts[px]:getHeight())*.5),rect.w,align or 'left')
end
local ink={.24,.15,.09,1}
local muted={.43,.32,.22,1}
local gold={.53,.34,.12,1}
local warning={.52,.20,.15,1}

-- Virtual 1920x1080 folio area: x=1512..1864, y=128..690.
-- The portrait stays well outside the physical 3D tray.
local PAGE_X,PAGE_Y,PAGE_SCALE=1740,621,.26
local STAGE_X,STAGE_Y,STAGE_SCALE=1735,543,.90

local function build_monk()
 local g=love.graphics
 local sheet=g.newCanvas(4*72,120)
 g.push('all')
 g.setCanvas(sheet)
 g.clear(0,0,0,0)
 for i=1,4 do
  local x=(i-1)*72
  local sway=math.sin((i-1)*math.pi/2)*3
  g.setColor(.34,.17,.13,1)
  g.polygon('fill',x+13,112,x+15,67,x+19,41,x+51,41,x+58,70,x+60,112)
  g.setColor(.54,.29,.18,1)
  g.polygon('fill',x+19,57,x+29,70,x+45,70,x+51,57,x+55,106,x+17,106)
  g.setColor(.79,.59,.36,1)
  g.rectangle('fill',x+22,77,28,3)
  g.setColor(.84,.70,.48,1)
  g.circle('fill',x+35+sway,36,17)
  g.setColor(.31,.19,.13,1)
  g.arc('fill','pie',x+35+sway,35,18,math.pi,math.pi*2)
  g.setColor(.27,.17,.12,1)
  g.rectangle('fill',x+29+sway,42,13,2)
  g.setColor(.78,.63,.41,1)
  g.setLineWidth(3)
  g.line(x+19,75,x+8,94)
  g.line(x+50,73,x+60,93+2*math.sin(i))
  g.setColor(.9,.79,.51,1)
  g.rectangle('fill',x+8,94,21,9)
  g.setColor(.43,.22,.11,1)
  g.line(x+8,96,x+29,96)
 end
 g.pop()
 local figure=Miniature.new(sheet,{
  x=PAGE_X,y=PAGE_Y,scale=PAGE_SCALE,
  frameWidth=72,frameHeight=120,frames=4,frameTime=.3,
 })
 if status.return_to_page then
  -- A completed duel can be presented before the first graphical frame.
  figure:return_to_page(0,true)
 else
  figure:move_to(STAGE_X,STAGE_Y,STAGE_SCALE,.75,
    RuntimeUI.reduced_animations())
 end
 return figure
end

function M.reset()
 -- Explicitly discard every previous result/transition on replay.
 -- The actor is recreated lazily during the next graphical frame.
 status=Model.new()
 monk=nil
end

function M.on_turn(event)
 if not Model.observe(status,event) then return false end
 if status.return_to_page and monk then
  monk:return_to_page(.85,RuntimeUI.reduced_animations())
 end
 return true
end

function M.update(dt)
 if monk then monk:update(dt,RuntimeUI.reduced_animations()) end
end

local function panel()
 local high=RuntimeUI.high_contrast()
 MenuSurface.panel(Geometry.status_panel,{high_contrast=high})
 draw_fit('SFIDA AL MONACO',Geometry.title,22,15,gold,'center')
 MenuSurface.rule(Geometry.status_rule.x,Geometry.status_rule.y,
  Geometry.status_rule.w,high and 1 or .8)
 draw_fit('TU: '..status.player..'     MONACO: '..status.bot,
  Geometry.score,19,12,ink,'center')
 draw_fit('MANO '..status.round..'/'..status.limit..
  '   |   META '..status.target,Geometry.round,17,11,muted,'center')
 draw_fit('Ultimo tiro: '..status.last_roll,
  Geometry.last_roll,17,10,muted,'center')
 MenuSurface.rule(Geometry.message_rule.x,Geometry.message_rule.y,
  Geometry.message_rule.w,high and 1 or .75)
 draw_fit(status.status,Geometry.status,16,10,
  status.status:find('FARKLE',1,true) and warning or ink,'center')
end

local function final_panel()
 local verdict=status.winner=='player' and 'HAI VINTO!' or
   status.winner=='bot' and 'IL MONACO HA VINTO' or 'PARITA'
 MenuSurface.panel(Geometry.result_panel,
  {high_contrast=RuntimeUI.high_contrast()})
 draw_fit(verdict,Geometry.result_title,32,18,gold,'center')
 draw_fit('R: nuova sfida   |   ESC: menu principale',
  Geometry.result_help,20,13,muted,'center')
 -- Draw ONLY the pre-existing mouse target, not a new action region.
 -- Controller.lua owns the restart logic and Escape handling.
 local hovered=false
 if love.mouse and love.mouse.getPosition then
  local mx,my=love.mouse.getPosition()
  if type(mx)=='number' and type(my)=='number' then
   local x,y=Res.to_virtual(mx,my)
   hovered=MenuSurface.contains(Geometry.retry,x,y)
  end
 end
 MenuSurface.item(Geometry.retry,{primary=true,active=hovered})
 draw_fit('RIPROVA   /   CLICCA QUI',
  Geometry.retry_label,21,13,ink,'center')
end

function M.draw(duel)
 if not duel then return end
 local g=love.graphics
 g.push('all')
 Res.begin_ui()
 if not monk then monk=build_monk() end
 panel()
 monk:draw()
 if status.finished then final_panel() end
 Res.end_ui()
 g.pop()
end

return M
