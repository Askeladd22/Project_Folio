-- This entry point exists only in the experimental .love archive.
-- All overrides below are process-local. No original module is edited.
local R=require('experiments.arte_del_rischio.rules')
local U=require('experiments.arte_del_rischio.ui')
package.loaded['src.features.scriptorium.module']=U
local schema=require('src.data.dice_roll_schema')
schema.pool={{kind='d6',count=4,sides=6}}
local load_engine=assert(love.filesystem.load('engine_main.lua')); load_engine()
local engine_load,engine_update=love.load,love.update
local box=require('src.engine3d.physics').box
function love.load()
 engine_load()
 for _,d in ipairs(dice) do
  d.die.image=function() end -- no numerical pips in this experimental session
  for face,value in ipairs(d.die.faceValueMap) do
   local c=R.colors[value]; d.die.faceColors[face]={c[1]*255,c[2]*255,c[3]*255,255}
  end
 end
 require('src.core.navigation').go('scriptorium')
 love.window.setMode(1920,1080,{resizable=true,vsync=1})
 love.resize(1920,1080)
end
function love.update(dt)
 -- Held dice are outside the active throw, as if set aside by the player.
 -- Keep their visible bodies in dice[], but exclude them from box's active list.
 -- This uses the existing physics unchanged and prevents collisions rotating a hold.
 for i=#box,1,-1 do box[i]=nil end
 for _,d in ipairs(dice) do
  if not d.kept then box[#box+1]=d.body end
 end
 engine_update(dt)
 for i=#box,1,-1 do box[i]=nil end
 for i,d in ipairs(dice) do box[i]=d.body end
end
if os.getenv('SCRIPTORIUM_RISK_SMOKE')=='1' then require('experiments.arte_del_rischio.smoke').install(U) end
