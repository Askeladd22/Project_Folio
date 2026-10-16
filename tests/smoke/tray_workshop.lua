-- Explicit workshop diagnostic only. Fixtures never run in ordinary play.
local M={}
function M.install(U)
 local root=assert(os.getenv('MANUSCRIPT_WORKSHOP_OUT'))..'/'
 local log=assert(io.open(root..'checks.log','w'))
 local function record(s) log:write(s..'\n');log:flush() end
 function love.errorhandler(e) record('FAIL '..tostring(e)..'\n'..debug.traceback());log:close();return function() return 1 end end
 local load,update,draw=love.load,love.update,love.draw
 local R=require('src.gameplay.farkle.rules')
 local Res=require('src.core.resolution_manager')
 local Bridge=require('src.core.engine_bridge')
 local function signature(v,seen)
  if type(v)~='table' then return tostring(v) end
  seen=seen or {};if seen[v] then return '@' end;seen[v]=true
  local keys={};for k,w in pairs(v) do if type(w)~='function' then keys[#keys+1]=k end end
  table.sort(keys,function(a,b)return tostring(a)<tostring(b) end)
  local out={};for _,k in ipairs(keys) do out[#out+1]=tostring(k)..'='..signature(v[k],seen) end
  return '{'..table.concat(out,',')..'}'
 end
 local function invariant()
  local bodies={};for i,d in ipairs(dice) do bodies[i]={body=d.body,kept=d.kept} end
  return signature({game=U.game,bodies=bodies,config=require('src.data.dice_scene_schema'),
   rng=love.math.getRandomState(),view=require('src.engine3d.view'),hits=U.hits})
 end
 local function click(id)
  U:draw();local b=assert(U.buttons[id],id);assert(b.enabled,'disabled '..id)
  local x,y=Res.to_screen(b.x+b.w/2,b.y+b.h/2);U:mousepressed(x,y,1)
 end
 local function fixture(hand)
  U:reset('control');assert(R.start(U.game));U.state='rolling';U.pending={};U.observed={}
  local values={}
  for i,value in ipairs(hand) do
   local d=dice[i];local b=d.body;local n={0,0,0}
   for f,face in ipairs(d.die.faces) do if d.die.faceValueMap[f]==value then
    for _,id in ipairs(face) do for k=1,3 do n[k]=n[k]+b[id][k]/#face end end;break
   end end
   local len=math.sqrt(n[1]^2+n[2]^2+n[3]^2);for k=1,3 do n[k]=n[k]/len end
   local c=math.max(-1,math.min(1,n[3]));local s=math.sqrt(math.max(0,1-c*c))
   local ax,ay=0,1;if s>1e-8 then ax,ay=n[2]/s,-n[1]/s end
   local minz=math.huge
   for _,v in ipairs(b) do
    local x,y,z=v[1],v[2],v[3];local dot=ax*x+ay*y
    v[1]=x*c+ay*z*s+ax*dot*(1-c)
    v[2]=y*c-ax*z*s+ay*dot*(1-c)
    v[3]=z*c+(ax*y-ay*x)*s;minz=math.min(minz,v[3])
   end
   b.position[1]=-4.5+(i-1)*1.8;b.position[2]=(i%2==0) and .7 or -.7;b.position[3]=-minz+.005
   for k=1,3 do b.velocity[k]=0 end
   b.asleep=true
   values[#values+1]={index=i,value=value}
  end
  U:onDiceSettled(values)
 end
 local elapsed=0;local co,pending,canvas,W
 local function frame() coroutine.yield({frame=true}) end
 local function shots(name) coroutine.yield({shots=name}) end
 local function wait_roll() coroutine.yield({wait=true}) end
 local function scenario(w,h)
  love.window.setMode(w,h,{resizable=true});love.resize(w,h)
  local prefix=w..'-'
  W.current='current';U:reset('control')
  local before=invariant()
  for _,id in ipairs({'A','B','C','current'}) do U:keypressed('f8');assert(W.current==id);assert(invariant()==before,'F8 mutated state') end
  assert(U:request());frame();shots(prefix..'six-moving');wait_roll()
  fixture({1,1,1,2,3,4});frame();shots(prefix..'available')
  for _,variant in ipairs({'A','B','C'}) do
   U:keypressed('f8');assert(W.current==variant)
   local hit=assert(U.hits[1]);local id=assert(Bridge.pickTrayDie(hit.x,hit.y));assert(id==hit.index)
   U:mousepressed(hit.x,hit.y,1);assert(U.game.selected[id]);U:mousepressed(hit.x,hit.y,1);assert(not U.game.selected[id])
  end
  U:keypressed('f8');assert(W.current=='current')
  for i=1,3 do U:toggle(i) end;shots(prefix..'selected');U:toggle(3);assert(not U.game.selected[3]);U:toggle(3)
  click('take');U:keypressed('tab');assert(U.game.used[1] and U.game.used[2] and U.game.used[3]);frame();shots(prefix..'three-held')
  local held={};for i=1,3 do held[i]=signature(dice[i].body) end
  assert(U:request());assert(#U.game.active==3);frame();shots(prefix..'partial-moving');wait_roll()
  for i=1,3 do assert(held[i]==signature(dice[i].body),'held body moved during partial roll') end
  record('PASS '..w..' real six-die roll, mouse picking, select/deselect, 3 held + 3 available, real partial roll')
  fixture({1,2,3,4,5,6});for i=1,6 do U:toggle(i) end;click('take');U:keypressed('tab')
  assert(U.game.hot);frame();shots(prefix..'hot-dice');assert(U:request());assert(#U.game.active==6)
  frame();shots(prefix..'hot-moving');wait_roll()
  record('PASS '..w..' hot dice clears collection and physically relaunches six dice')
 end
 function love.load()
  load();W=require('src.features.farkle.tray_workshop')
  co=coroutine.create(function()
   scenario(1920,1080);scenario(1280,720)
   record('PASS all workshop scenarios; rendering and F8 preserve gameplay, bodies, RNG, camera, configuration and picking')
   log:close();love.event.quit(0)
  end)
 end
 function love.update(dt) elapsed=elapsed+dt;assert(elapsed<180,'workshop timeout');update(dt) end
 local function capture(name)
  local w,h=love.graphics.getDimensions()
  if canvas then canvas:release() end;canvas=love.graphics.newCanvas(w,h)
  local old=W.current;local before=invariant();local projection=signature(U.trayProjection)
  for _,id in ipairs({'current','A','B','C'}) do
   -- Each canvas is rendered in this single simulation frame: no update, RNG or pose changes.
   while W.current~=id do U:keypressed('f8') end
   assert(invariant()==before,'F8 mutated simulation during '..name)
   love.graphics.push('all')
   local setCanvas=love.graphics.setCanvas
   -- The real overlay explicitly resets its render target. Redirect that reset
   -- only during this diagnostic draw so the complete frame reaches the canvas.
   love.graphics.setCanvas=function(target,...) return setCanvas(target or canvas,...) end
   setCanvas(canvas);love.graphics.clear();draw();love.graphics.setCanvas=setCanvas;setCanvas();love.graphics.pop()
   assert(invariant()==before,'render mutated authoritative state or picking: '..id)
   assert(signature(U.trayProjection)==projection,'projection changed: '..id)
   for _,hit in ipairs(U.hits or {}) do
    if U.game.phase=='ready' then assert(Bridge.pickTrayDie(hit.x,hit.y)==hit.index,'picking changed: '..id) end
   end
   local data=canvas:newImageData();local bytes=data:encode('png');local f=assert(io.open(root..name..'-'..id..'.png','wb'));f:write(bytes:getString());f:close();data:release();bytes:release()
  end
  W.current=old;record('PASS comparable '..name..' current/A/B/C with identical simulation state')
 end
 function love.draw()
  draw()
  if pending then
   if pending.wait and U.game.phase=='rolling' then return end
   if pending.shots then capture(pending.shots) end
   pending=nil
  end
  if coroutine.status(co)~='dead' then local ok,value=coroutine.resume(co);assert(ok,value);pending=value end
 end
end
return M
