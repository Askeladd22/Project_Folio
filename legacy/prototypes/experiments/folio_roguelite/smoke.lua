local M={}
function M.install(U)
 local R=require('experiments.folio_roguelite.rules')
 local Res=require('src.core.resolution_manager')
 local Bridge=require('src.core.engine_bridge')
 local root=assert(os.getenv('SCRIPTORIUM_FOLIO_ROOT'))..'/experiments/folio_roguelite/'
 local log=assert(io.open(root..'smoke.log','w'))
 local function record(s) log:write(s..'\n'); log:flush(); print(s) end
 function love.errorhandler(e)
  record('FAIL '..tostring(e)..'\n'..debug.traceback()); log:close(); return function() return 1 end
 end
 local load,update,draw=love.load,love.update,love.draw
 local stage,frames,elapsed=0,0,0; local held,vertices
 local function click(id)
  U:draw(); local b=assert(U.buttons[id],id); assert(b.enabled,'disabled '..id)
  local x,y=Res.to_screen(b.x+b.w/2,b.y+b.h/2); U:mousepressed(x,y,1)
 end
 local function feed(values)
  assert(R.start(U.game)); U.state='rolling'
  local v={}; for i,c in pairs(values) do v[#v+1]={index=i,value=c} end
  U:onDiceSettled(v)
 end
 local function apply(d,slot) click('die'..d); click('slot'..slot) end
 local function screenshot(name)
  love.graphics.captureScreenshot(function(data)
   local f=assert(io.open(root..name,'wb')); f:write(data:encode('png'):getString()); f:close(); record('SCREENSHOT '..name)
  end)
 end
 function love.load()
  load(); assert(love.filesystem.getIdentity()=='scriptorium-folio-roguelite'); assert(#dice==4)
  for _,d in ipairs(dice) do for face,value in ipairs(d.die.faceValueMap) do
   assert(math.abs(d.die.faceColors[face][1]-R.colors[value][1]*255)<.001)
  end end
  record('PASS isolated identity and original four-die color mapping')
 end
 function love.update(dt)
  elapsed=elapsed+dt; assert(elapsed<150,'smoke timeout at '..stage); update(math.min(dt,.05))
 end
 function love.draw()
  draw(); frames=frames+1; if frames%12~=0 then return end
  local s=U.game
  if stage==0 then click('roll'); U:keypressed('r'); assert(U.game==s); stage=1
  elseif stage==1 and s.phase=='ready' then screenshot('preview-physical.png'); stage=11
  elseif stage==11 then
   for _,hit in ipairs(U.hits) do assert(Bridge.pickTrayDie(hit.x,hit.y)==hit.index) end
   local slot
   for i=1,4 do for j,c in ipairs(R.recipes[1]) do if s.hand[i]==c then held=i;slot=j;break end end; if held then break end end
   if not held then click('roll'); stage=10; return end
   apply(held,slot); vertices={}
   for i,v in ipairs(dice[held].body) do vertices[i]={v[1],v[2],v[3]} end
   click('roll'); stage=2
  elseif stage==10 and s.phase~='rolling' then
   U:reset(); stage=0
  elseif stage==2 and s.phase~='rolling' then
   for i,v in ipairs(dice[held].body) do for k=1,3 do assert(math.abs(v[k]-vertices[i][k])<1e-8,'consumed die moved') end end
   record('PASS actual physical roll/reroll, picking, consumed die pose, input lock')
   U:reset(); feed({1,3,3,4}); for i=1,4 do apply(i,i) end
   assert(s~=U.game); assert(U.game.phase=='ready'); click('bank'); click('next')
   feed({2,6,5,5}); apply(1,5); apply(2,6); click('bank'); assert(U.game.phase=='choice'); stage=3
  elseif stage==3 then screenshot('preview-choice.png'); stage=31
  elseif stage==31 then click('fixative'); feed({1,2,5,5}); apply(1,1); apply(2,2)
   click('technique'); click('slot2'); assert(U.game.protected==2)
   feed({[3]=6,[4]=6}); assert(U.game.slots[2]=='fixed' and not U.game.slots[1]); stage=4
  elseif stage==4 then
   record('PASS controlled UI: partial bank, next session, first folio, choice, protected failure')
   click('next'); feed({1,2,3,5}); apply(1,1); apply(2,3); stage=5
  elseif stage==5 then screenshot('preview-1080.png'); stage=51
  elseif stage==51 then love.window.setMode(1280,720,{resizable=true}); love.resize(1280,720); stage=6
  elseif stage==6 then screenshot('preview-720.png'); stage=61
  elseif stage==61 then click('bank'); assert(U.game.slots[1]=='fixed')
   U:reset(); U.game.phase='choice'; click('model'); feed({2,4,1,5}); apply(1,2)
   click('technique'); click('slot2'); click('slot3'); assert(U.game.slots[3]=='wet' and U.game.model_used)
   assert(U.game.used[1]); click('bank'); click('next'); assert(U.game.slots[3]=='fixed' and U.game.model_used)
   record('PASS resized input, transfer status, consumed die, once-per-folio persistence')
   feed({1,2,3,5}); apply(1,1); apply(2,2); apply(3,5); apply(4,6); click('bank'); click('next')
   feed({4,1,1,1}); apply(1,4); click('bank'); assert(U.game.phase=='won'); stage=7
  elseif stage==7 then
   U:update(); record('PASS complete two-folio run and telemetry; no mass simulation'); log:close(); love.event.quit(0)
  end
 end
end
return M
