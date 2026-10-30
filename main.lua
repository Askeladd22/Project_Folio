-- Opt-in renderer diagnostic only; normal startup does not load lab code.
if require('src.core.renderer_lab_boot').start() then return end
-- Canonical source entry: run LOVE from this repository directory.
local U=require('src.features.farkle.controller')
local D=require('src.features.farkle.dice')
-- The six D6 share the entire existing tray, without the legacy D6/D8 partition.
U.tray_divided=false
require('src.data.dice_roll_schema').pool={{kind='d6',count=6,sides=6}}
assert(love.filesystem.load('src/app/dice_runtime.lua'))(U)
local engine_load,engine_update=love.load,love.update
local box=require('src.engine3d.physics').box
function love.load()
 engine_load();D.install('normal');require('src.core.navigation').go('startup_splash')
 -- Historical game-only diagnostics explicitly bypass the restored frontend.
 if os.getenv('MANUSCRIPT_FARKLE_TRAY_SMOKE')=='1' or os.getenv('MANUSCRIPT_TRAY_WORKSHOP_SMOKE')=='1'
 or os.getenv('MANUSCRIPT_FARKLE_HUD_SMOKE')=='1' or os.getenv('MANUSCRIPT_HUD_COMPARISON')=='1' or os.getenv('MANUSCRIPT_SOURCE_CASE') then
  require('src.core.navigation').go('scriptorium')
 end
 -- initialize_runtime already applies the user's persisted video settings.
 love.resize(love.graphics.getDimensions())
end
function love.update(dt)
 for i=#box,1,-1 do box[i]=nil end
 for _,d in ipairs(dice) do if not d.kept then box[#box+1]=d.body end end
 engine_update(dt)
 for i=#box,1,-1 do box[i]=nil end
 for i,d in ipairs(dice) do box[i]=d.body end
end
if os.getenv('MANUSCRIPT_FARKLE_TRAY_SMOKE')=='1' then require('tests.smoke.farkle_tray').install(U) end
if os.getenv('MANUSCRIPT_FARKLE_HUD_SMOKE')=='1' then require('tests.smoke.farkle_hud').install(U) end
if os.getenv('MANUSCRIPT_TRAY_WORKSHOP_SMOKE')=='1' then require('tests.smoke.tray_workshop').install(U) end
if os.getenv('MANUSCRIPT_HUD_COMPARISON')=='1' then require('tests.smoke.compare_huds').install(U) end
-- Explicit diagnostics only; ordinary play never loads audit modules.
if os.getenv('MANUSCRIPT_SOURCE_CASE') then require('tests.smoke.driver') end
if os.getenv('MANUSCRIPT_FRONTEND_SMOKE') then require('tests.smoke.frontend') end
