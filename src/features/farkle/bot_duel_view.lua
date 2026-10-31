-- Optional Farkle encounter with a FLAT illuminated-manuscript figure.
-- g3d remains the sole renderer for the physical six D6 and book tray.
-- The figure's return-to-folio motion is decorative, never a game rule.
local Miniature=require('src.features.scriptorium.miniature_2d')
local Model=require('src.features.farkle.bot_duel_presentation')
local Res=require('src.core.resolution_manager')
local RuntimeUI=require('src.core.runtime_ui')
local M={}
local monk=nil
local status=Model.new()
local titleFont=nil
local bodyFont=nil

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

local function panel(g)
 g.setColor(.12,.095,.065,.94)
 g.rectangle('fill',1510,122,350,177,8)
 g.setColor(.7,.51,.29,1)
 g.setLineWidth(1.7)
 g.rectangle('line',1511,123,348,175,8)
 g.setFont(titleFont)
 g.setColor(.94,.78,.43,1)
 g.print('SFIDA AL MONACO',1525,132)
 g.setFont(bodyFont)
 g.setColor(.96,.91,.79,1)
 g.print('TU: '..status.player..'    MONACO: '..status.bot,1525,172)
 g.print('MANO '..status.round..'/'..status.limit..
  '  |  META '..status.target,1525,201)
 g.setColor(.86,.72,.48,1)
 g.print('Ultimo tiro: '..status.last_roll,1525,231)
 g.setColor(.95,.89,.76,1)
 g.printf(status.status,1525,261,316,'left')
end

local function final_panel(g)
 local verdict=status.winner=='player' and 'HAI VINTO!' or
   status.winner=='bot' and 'IL MONACO HA VINTO' or 'PARITA'
 g.setColor(.12,.095,.065,.97)
 g.rectangle('fill',600,440,720,152,8)
 g.setColor(.7,.51,.29,1)
 g.setLineWidth(1.7)
 g.rectangle('line',601,441,718,150,8)
 g.setFont(titleFont)
 g.setColor(.94,.78,.43,1)
 g.print(verdict,618,450)
 g.setFont(bodyFont)
 g.setColor(.96,.91,.79,1)
 g.print('R: nuova sfida   |   ESC: menu principale',618,487)
 g.setColor(.8,.67,.45,1)
 g.rectangle('line',780,540,350,45,6)
 g.setFont(bodyFont)
 g.print('RIPROVA   /   CLICCA QUI',812,553)
end

function M.draw(duel)
 if not duel then return end
 local g=love.graphics
 g.push('all')
 Res.begin_ui()
 if not monk then monk=build_monk() end
 if not titleFont then titleFont=g.newFont('resources/font/IMFeENsc28P.ttf',22) end
 if not bodyFont then bodyFont=g.newFont('resources/font/IMFeENsc28P.ttf',18) end
 panel(g)
 monk:draw()
 if status.finished then final_panel(g) end
 Res.end_ui()
 g.pop()
end

return M
