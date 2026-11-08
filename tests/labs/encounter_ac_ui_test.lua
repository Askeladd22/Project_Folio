-- Graphics-stub regression: UI opens in both modes without physical GPU.
local shown={}
local function capture(v) shown[#shown+1]=tostring(v) end
local font={getHeight=function() return 20 end}
local g={}
for _,name in ipairs({'setColor','rectangle','circle','line','setLineWidth',
 'clear','push','pop','translate','scale','setFont','draw'}) do
 g[name]=function() end
end
g.newFont=function() return font end
g.getDimensions=function() return 1280,720 end
g.print=capture;g.printf=capture
love={graphics=g,
 filesystem={getSource=function() return 'experiments/encounter_ac_lab' end,
  newFileData=function() return nil end},
 event={quit=function() end}}
dofile('experiments/encounter_ac_lab/main.lua')
assert(love.load and love.draw and love.keypressed and love.mousepressed)
love.load({'--mode','A','--seed','101'})
love.draw()
local function saw(part)
 for _,str in ipairs(shown) do
  if str:find(part,1,true) then return true end
 end
 return false
end
assert(saw('OFFERTE E CONTROMOSSE') and saw('IL TUO FARKLE'))
assert(saw('Capilettera') and saw('Miniatura') and saw('Marca tipografica'))
shown={}
love.keypressed('m');love.draw()
assert(saw('PROVE CONTESE'))
shown={}
love.keypressed('m');love.keypressed('space');love.draw()
assert(saw('PROVVISORIO'))
love.keypressed('r')
shown={};love.draw()
assert(saw('OFFERTE E CONTROMOSSE'))
print('PASS Encounter A/C UI opens both modes and handles basic input')
