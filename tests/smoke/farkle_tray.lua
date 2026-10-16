-- Targeted real-engine check; never installed in ordinary play.
local M={}
function M.install(U)
 local root=assert(os.getenv('MANUSCRIPT_AUDIT_OUT'))..'/'
 local log=assert(io.open(root..'tray-smoke.log','w'))
 local function record(s) log:write(s..'\n');log:flush() end
 function love.errorhandler(e) record('FAIL '..tostring(e)..'\n'..debug.traceback());log:close();return function() return 1 end end
 local load,update,draw=love.load,love.update,love.draw
 local elapsed,stage=0,0
 local checks={};local regions=require('src.data.dice_scene_schema').regions
 local crossing=0;local crossingStart=0
 local originalBox=require('src.data.dice_scene_schema').box
 local function split(y)
  local r=regions.unified;local t=(y-r.y_back)/(r.y_front-r.y_back)
  local half=r.half_back+(r.half_front-r.half_back)*t
  return (r.x_center or 0)-half+2*half*regions.d6_ratio
 end
 local function next_crossing()
  crossing=crossing+1;crossingStart=elapsed
  if crossing>12 then record('PASS all six dice physically cross old divider in both directions');log:close();love.event.quit(0);stage=6;return end
  for _,d in ipairs(dice) do d.kept=true end
  local d=dice[math.floor((crossing-1)/2)+1];local direction=crossing%2==1 and 1 or -1
  d.kept=false;local b=d.body;b.asleep=false;b.sleep_timer=0
  b.position[1]=split(0)-direction*.8;b.position[2]=0;b.position[3]=.9
  b.velocity[1]=direction*8;b.velocity[2]=0;b.velocity[3]=0
 end
 function love.load()
  load();assert(#dice==6 and U.tray_divided==false)
    assert(originalBox.half_x==9.2 and originalBox.half_y==3.8 and originalBox.border_height==.74)
    assert(regions.unified.half_back==6.3 and regions.unified.half_front==8.4)
    assert(U:request());record('START physical throw of all six D6; expanded tray dimensions')
 end
 function love.update(dt)
  elapsed=elapsed+dt;assert(elapsed<90,'tray verification timeout')
  update(dt)
  if stage==0 and U.game.phase~='rolling' then
   for i,d in ipairs(dice) do
    local best,z=1,-math.huge
    for f,face in ipairs(d.die.faces) do local h=0;for _,v in ipairs(face) do h=h+d.body[v][3] end;h=h/#face;if h>z then best=f;z=h end end
    assert(U.game.hand[i]==d.die.faceValueMap[best])
   end
   record('PASS six physical results match their visible upper faces');stage=1
  elseif stage==2 then
   -- Held bodies bypass integration but still pass through the real region constraint.
   -- Sweeping all six through the old split detects any remaining invisible clamp.
   for i,d in ipairs(dice) do assert(math.abs(d.body.position[1]-checks[i])<1e-8,'invisible partition clamps die '..i) end
   record('PASS all six centers beyond old divider remain unclamped across its full length')
   stage=3
  elseif stage==4 then
   for i,d in ipairs(dice) do assert(math.abs(d.body.position[1]-checks[i])<1e-8,'left-side position changed '..i) end
   record('PASS all six centers on opposite side remain unclamped; external constraints retained')
   stage=5;next_crossing()
  elseif stage==5 then
   assert(elapsed-crossingStart<3,'physical crossing blocked: '..crossing)
   local d=dice[math.floor((crossing-1)/2)+1];local direction=crossing%2==1 and 1 or -1
   if direction*(d.body.position[1]-split(d.body.position[2]))>.5 then next_crossing() end
  end
 end
 function love.draw()
  draw()
  if stage==1 then
   love.graphics.captureScreenshot(function(data)
    local f=assert(io.open(root..'preview-open-tray.png','wb'));f:write(data:encode('png'):getString());f:close()
   end)
   for i,d in ipairs(dice) do
    local y=-2+(i-1)*.8;checks[i]=split(y)+.65
    d.kept=true;d.body.position[1]=checks[i];d.body.position[2]=y
   end
   stage=2
  elseif stage==3 then
   for i,d in ipairs(dice) do checks[i]=split(d.body.position[2])-.65;d.body.position[1]=checks[i] end
   stage=4
  end
 end
end
return M
