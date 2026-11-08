-- Native V4 view regression with graphics stub, no dependency on production GPU.
local printed={}
local function draw_text(v)
 printed[#printed+1]=tostring(v)
end
local font={getHeight=function()return 20 end}
local graphics={}
for _,name in ipairs({'setColor','rectangle','circle','line','setLineWidth','clear',
 'push','pop','translate','scale','setScissor','draw','setFont'}) do
 graphics[name]=function() end
end
graphics.newFont=function() return font end
graphics.getDimensions=function() return 1280,720 end
graphics.print=draw_text
graphics.printf=draw_text
love={
 graphics=graphics,
 filesystem={
  getSource=function() return 'experiments/merchant_wager_lab' end,
  getInfo=function() return nil end,
  getSaveDirectory=function() return 'merchant-ui-regression' end,
  read=function() return '' end,
  write=function()return true end,
  append=function() return true end,
  -- No FileData in this stub: fallback deliberately tests asset-safe startup.
  newFileData=function()return nil end,
 },
 math={random=function() return 101 end},
 event={quit=function() end},
}
dofile('experiments/merchant_wager_lab/main.lua')
assert(love.load and love.draw and love.keypressed and love.mousepressed)
love.load({'--seed','101'})
love.draw()
local function saw(text)
 for _,s in ipairs(printed) do
  if s:find(text,1,true) then return true end
 end
 return false
end
assert(saw('Il Mercante e la posta'))
assert(saw('POSTA SUL TAVOLO'))
assert(saw('OFFERTA DEL MERCANTE'))
assert(saw('6 D6'))
assert(saw('IL TUO PATRIMONIO'))
assert(not saw('V2 —') and not saw('Il Correttore'),'removed prototypes must not be in the UI')
printed={}
love.keypressed('e');love.draw()
assert(saw('LIBRO MASTRO'))
assert(saw('Denari totali:'))
printed={}
love.keypressed('e');love.keypressed('b');love.draw()
assert(saw('CASSA TIPOGRAFICA'))
printed={}
love.keypressed('escape');love.keypressed('r');love.draw()
assert(saw('LA SFIDA'))
printed={}
love.keypressed('s');love.draw()
assert(saw('NUOVO INCONTRO') and saw('SEED DELLA PARTITA') and saw('RIALZI'))
-- Switching seed and wager policy is still available without restoring legacy modes.
love.mousepressed(500,329,1) -- seed 202
love.mousepressed(530,415,1) -- disable raises
printed={};love.draw()
assert(saw('DISATTIVATI'))
love.keypressed('return')
printed={};love.draw()
assert(saw('SEED 202') and saw('rialzi disattivati'))
print('PASS merchant Aldine scene: no legacy menu, wager prominence, book ledger, cassa overlay and replay')
