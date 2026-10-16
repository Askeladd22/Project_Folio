-- Real-time presentation capture. Never assigns physical outcomes.
local U=require('src.features.farkle.controller')
local R=require('src.gameplay.farkle.rules')
local out=assert(os.getenv('MANUSCRIPT_AUDIT_OUT'))
local load0,update0,draw0=love.load,love.update,love.draw
local elapsed,lastCapture,frame=0,-1,0
local phase='opening';local deadline=1;local samples={};local done=false
local log=assert(io.open(out..'/turn-feel.log','w'))
local timings={update={},draw={}}
local function timed(name,fn,...)
 local t=love.timer.getTime();fn(...);local a=timings[name];a[#a+1]=(love.timer.getTime()-t)*1000
end
local function say(s) log:write(s..'\n');log:flush() end
local function shot(name)
 love.graphics.captureScreenshot(function(data)
  local f=assert(io.open(out..'/'..name..'.png','wb'));f:write(data:encode('png'):getString());f:close()
 end)
end
function love.load()
 load0();love.window.setMode(1280,720,{resizable=true,vsync=1});love.resize(1280,720)
 U:reset('build');love.math.setRandomSeed(54083);math.randomseed(54083)
end
function love.update(dt)
 timed('update',update0,dt);elapsed=elapsed+dt
 if phase=='opening' and elapsed>=deadline then assert(U:request());phase='first'
 elseif phase=='first' and U.game.phase~='rolling' then
  assert(U.state~='physics_error');say('First physical result '..table.concat(U.game.hand,'/'));shot('result')
  if U.game.phase=='ready' then phase='select';deadline=elapsed+.7 else phase='ended';deadline=elapsed+.7 end
 elseif phase=='select' and elapsed>=deadline then
  local choices=R.options(U.game);local o=assert(choices[1]);U:select_option(o.mask)
  phase='take';deadline=elapsed+.6;shot('selected')
 elseif phase=='take' and elapsed>=deadline then
  U:act('take',function() return R.take(U.game) end);phase='hold';deadline=elapsed+.8
 elseif phase=='hold' and elapsed>=deadline then shot('held');phase='reroll';deadline=elapsed+.2
 elseif phase=='reroll' and elapsed>=deadline then assert(U:request());phase='second'
 elseif phase=='second' and U.game.phase~='rolling' then
  assert(U.state~='physics_error');shot('reroll-result');phase='bank';deadline=elapsed+.6
 elseif phase=='bank' and elapsed>=deadline then
  if U.game.phase=='ready' then local o=R.options(U.game)[1];if o then U:select_option(o.mask);U:act('bank',function() return R.bank_turn(U.game) end) end end
  shot('conclusion');phase='ended';deadline=elapsed+1.1
 elseif phase=='ended' and elapsed>=deadline then
  if U.game.phase=='ended' then U:act('next',function() return R.next_turn(U.game) end) end
  phase='done';deadline=elapsed+.8
 end
 if elapsed>60 or phase=='done' and elapsed>=deadline then done=true end
end
function love.draw()
 timed('draw',draw0)
 if elapsed-lastCapture>=1/15 then
  lastCapture=elapsed;frame=frame+1;local name=string.format('frame-%05d',frame);shot(name)
  local p=U.trayProjection;samples[#samples+1]=string.format('%.6f,%s,%.6f,%.6f,%.6f',elapsed,name,p and p.cx or 0,p and p.cy or 0,p and p.scale or 0)
 end
 if done then
  local f=assert(io.open(out..'/frames.csv','w'));f:write('time,file,cx,cy,scale\n'..table.concat(samples,'\n'));f:close()
  for name,a in pairs(timings) do
   table.sort(a);local sum=0;for _,v in ipairs(a) do sum=sum+v end
   say(string.format('CPU %s n=%d mean=%.3fms p95=%.3fms max=%.3fms (capture excluded; GPU not measured)',name,#a,sum/#a,a[math.ceil(#a*.95)],a[#a]))
  end
  say((phase=='done' and 'PASS' or 'INCOMPLETE')..' real-time presentation capture '..frame..' frames '..elapsed..' seconds; final capture phase='..phase);log:close();love.event.quit(phase=='done' and 0 or 1)
 end
end
