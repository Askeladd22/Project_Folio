local files={}
local font={getHeight=function() return 20 end}
local graphics={}
for _,name in ipairs({'clear','push','pop','translate','scale','setColor','setFont',
 'rectangle','circle','setLineWidth','print','printf'}) do
 graphics[name]=function() end
end
graphics.newFont=function() return font end
graphics.getDimensions=function() return 1280,720 end
love={
 graphics=graphics,
 math={setRandomSeed=function() end,random=function(min,max) return min or 1 end},
 event={quit=function() end},
 filesystem={
  getSource=function() return 'experiments/merchant_wager_lab' end,
  getSaveDirectory=function() return 'corrector-ui-test' end,
  getInfo=function(path) return files[path] and {} or nil end,
  read=function(path) return files[path] end,
  write=function(path,data) files[path]=data;return true end,
  append=function(path,data) files[path]=(files[path] or '')..data;return true end,
 },
}

dofile('experiments/merchant_wager_lab/main.lua')
love.load({})
love.draw()
love.keypressed('c')
love.draw()
local Match=require('experiments.merchant_wager_lab.match')
local test_seed=9001
Match.new_rng=function(seed)
 if seed==test_seed then
  local faces={2,3,4,6,2,4};local index=0
  return function()
   index=index+1
   return assert(faces[index],'unexpected extra player roll')
  end
 end
 return function(minimum) return minimum or 1 end
end
love.mousepressed(300,250,1)
for _=1,3 do love.keypressed('backspace') end
love.textinput(tostring(test_seed))
love.keypressed('return')
assert(love.draw and love.keypressed)
love.draw()
love.keypressed('space')
love.draw()
love.keypressed('escape')
assert(files['corrector_matches_v1.csv'],'closing the encounter must save a match row')
love.draw()
love.mousepressed(900,180,1)
love.textinput('0')
love.mousepressed(410,250,1)
love.draw()
love.mousepressed(940,520,1)
assert(files['corrector_feedback_v1.csv'],'feedback form must save through the UI')
assert(files['corrector_feedback_v1.csv']:find('0,yes',1,true))
love.draw()
print('Corrector UI flow passed.')
