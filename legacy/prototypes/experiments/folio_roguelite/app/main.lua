-- Isolated entry point: the shared engine is packaged unchanged.
local R=require('experiments.folio_roguelite.rules')
local U=require('experiments.folio_roguelite.ui')
package.loaded['src.features.scriptorium.module']=U
require('src.data.dice_roll_schema').pool={{kind='d6',count=4,sides=6}}
assert(love.filesystem.load('engine_main.lua'))()
local engine_load,engine_update=love.load,love.update
local box=require('src.engine3d.physics').box
function love.load()
 engine_load()
 for _,d in ipairs(dice) do
  d.die.image=function() end
  for face,value in ipairs(d.die.faceValueMap) do
   local c=R.colors[value]; d.die.faceColors[face]={c[1]*255,c[2]*255,c[3]*255,255}
  end
 end
 require('src.core.navigation').go('scriptorium')
 love.window.setMode(1920,1080,{resizable=true,vsync=1}); love.resize(1920,1080)
end
function love.update(dt)
 -- Same adapter used by the existing experiment: consumed dice stay visible,
 -- but are excluded from active bodies without changing the physics solver.
 for i=#box,1,-1 do box[i]=nil end
 for _,d in ipairs(dice) do if not d.kept then box[#box+1]=d.body end end
 engine_update(dt)
 for i=#box,1,-1 do box[i]=nil end
 for i,d in ipairs(dice) do box[i]=d.body end
end
if os.getenv('SCRIPTORIUM_FOLIO_SMOKE')=='1' then require('experiments.folio_roguelite.smoke').install(U) end
