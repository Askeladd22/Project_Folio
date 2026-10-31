-- Purely flat, original painted placeholder for the Farkle opponent.
-- Uses the already approved 2D animation stack. No meshes, g3d characters
-- or input over the physical D6 area.
local Miniature=require('src.features.scriptorium.miniature_2d')
local Res=require('src.core.resolution_manager')
local RuntimeUI=require('src.core.runtime_ui')
local M={}
local monk=nil
local titleFont=nil
local bodyFont=nil

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
 return Miniature.new(sheet,{
  x=1780,y=330,scale=.86,frameWidth=72,frameHeight=120,
  frames=4,frameTime=.3,
 })
end

function M.update(dt)
 if monk then monk:update(dt,RuntimeUI.reduced_animations()) end
end

local function message(g,x,y,w,h,title,text)
 g.setColor(.12,.095,.065,.94)
 g.rectangle('fill',x,y,w,h,8)
 g.setColor(.7,.51,.29,1)
 g.setLineWidth(1.7)
 g.rectangle('line',x+1,y+1,w-2,h-2,8)
 g.setFont(titleFont)
 g.setColor(.94,.78,.43,1)
 g.print(title,x+16,y+10)
 g.setFont(bodyFont)
 g.setColor(.96,.91,.79,1)
 g.print(text,x+16,y+44)
end

function M.draw(duel)
 if not duel then return end
 local g=love.graphics
 g.push('all')
 Res.begin_ui()
 if not monk then monk=build_monk() end
 if not titleFont then titleFont=g.newFont('resources/font/IMFeENsc28P.ttf',22) end
 if not bodyFont then bodyFont=g.newFont('resources/font/IMFeENsc28P.ttf',18) end
 -- Entire scoreboard is outside the playable 3D tray in both HUD layouts.
 message(g,1510,122,350,96,'SFIDA AL MONACO',
  'TU: '..(duel.last and duel.last.player or 0)..
  '    MONACO: '..duel.bot.game.bank..' pt')
 -- Flat 2D foe on the narrow folio region, never over physical D6.
 monk:draw()
 if duel.finished then
  local verdict=duel.winner=='player' and 'HAI VINTO!' or
    duel.winner=='bot' and 'IL MONACO HA VINTO' or 'PARITA'
  message(g,600,440,720,152,verdict,
    'R: nuova sfida   |   ESC: menu principale')
  g.setColor(.8,.67,.45,1)
  g.rectangle('line',780,540,350,45,6)
  g.setFont(bodyFont)
  g.print('RIPROVA   /   CLICCA QUI',812,553)
 end
 Res.end_ui()
 g.pop()
end
return M
