local M={}
function M.install(U)
 local R=require('experiments.farkle_roguelite.rules');local D=require('experiments.farkle_roguelite.dice')
 local Res=require('src.core.resolution_manager');local Bridge=require('src.core.engine_bridge')
 local root=assert(os.getenv('MANUSCRIPT_FARKLE_ROOT'))..'/experiments/farkle_roguelite/'
 local log=assert(io.open(root..'smoke.log','w'));local observations=assert(io.open(root..'physical-sample.csv','w'))
 observations:write('build,sample,physical_face,accepted_value\n')
 local function record(x) log:write(x..'\n');log:flush();print(x) end
 function love.errorhandler(e) record('FAIL '..tostring(e)..'\n'..debug.traceback());log:close();observations:close();return function() return 1 end end
 local load,update,draw=love.load,love.update,love.draw
 local stage,frames,elapsed=0,0,0;local held,vertices;local sample=0;local family='normal'
 local function top(entry)
  local best,z=1,-math.huge
  for f,face in ipairs(entry.die.faces) do local v=0;for _,i in ipairs(face) do v=v+entry.body[i][3] end;v=v/#face;if v>z then z=v;best=f end end
  return best,entry.die.faceValueMap[best]
 end
 local function physical_check(s)
  for _,i in ipairs(s.active) do local _,v=top(dice[i]);assert(s.hand[i]==v,'physical face differs from recorded result') end
 end
 local function click(id)
  U:draw();local b=assert(U.buttons[id],id);assert(b.enabled,'disabled '..id)
  local x,y=Res.to_screen(b.x+b.w/2,b.y+b.h/2);U:mousepressed(x,y,1)
 end
 local function feed(values)
  assert(R.start(U.game));U.state='rolling';U.pending={};U.observed={}
  local v={};for i,n in pairs(values) do v[#v+1]={index=i,value=n} end;U:onDiceSettled(v)
 end
 local function select_all() for i=1,6 do click('die'..i) end end
 local function capture(name)
  love.graphics.captureScreenshot(function(data) local f=assert(io.open(root..name,'wb'));f:write(data:encode('png'):getString());f:close();record('SCREENSHOT '..name) end)
 end
 function love.load()
  load();love.math.setRandomSeed(1046);assert(#dice==6);assert(love.filesystem.getIdentity()=='manuscript-farkle-roguelite')
  record('PASS isolated six numbered D6, initial normal set')
  record('SAVE DIRECTORY '..love.filesystem.getSaveDirectory())
  assert(love.filesystem.getInfo('runs.csv'),'action log missing')
 end
 function love.update(dt) elapsed=elapsed+dt;assert(elapsed<390,'timeout stage '..stage);update(math.min(dt,.05)) end
 function love.draw()
  draw();frames=frames+1;if frames%12~=0 then return end
  local s=U.game
  if stage==0 then click('roll');U:keypressed('r');assert(U.game==s);stage=1
  elseif stage==1 and s.phase~='rolling' then
   physical_check(s)
   if s.phase~='ready' then U:reset('build');stage=0;return end
   capture('preview-physical.png');stage=2
  elseif stage==2 then
   for _,h in ipairs(U.hits) do assert(Bridge.pickTrayDie(h.x,h.y)==h.index) end
   local chosen
   for mask=1,63 do local h={};local ix={};for i=1,6 do if math.floor(mask/2^(i-1))%2==1 then h[#h+1]=s.hand[i];ix[#ix+1]=i end end
    if R.score(h) and #ix<6 then chosen=ix;break end
   end
   assert(chosen);for _,i in ipairs(chosen) do click('die'..i) end;click('take')
   held=chosen[1];vertices={};for i,v in ipairs(dice[held].body) do vertices[i]={v[1],v[2],v[3]} end
   click('roll');stage=3
  elseif stage==3 and s.phase~='rolling' then
   physical_check(s);for i,v in ipairs(dice[held].body) do for k=1,3 do assert(math.abs(v[k]-vertices[i][k])<1e-8) end end
   record('PASS actual selection, kept pose, physical reroll, geometric values and input lock')
   U:reset('build');feed({1,2,3,4,5,6});select_all();click('bank');assert(U.game.phase=='upgrade');stage=4
  elseif stage==4 then capture('preview-upgrade.png');stage=41
  elseif stage==41 then
   click('engraved');assert(U.game.build=='engraved' and U.game.stage==2)
   assert(dice[1].die~=dice[2].die and dice[1].die.faceValueMap[6]==1 and dice[2].die.faceValueMap[6]==2)
   local get=love.graphics.getImage;local requested
   love.graphics.getImage=function(path) requested=path;return get(path) end
   for i=1,6 do for f=1,6 do dice[i].die.image(f,0,0,1,0,1,1,0,1);assert(requested=='resources/dice/'..D.values('engraved',i)[f]..'.png') end end
   love.graphics.getImage=get;record('PASS 36 rendered face texture paths match independent per-die logical mappings')
   click('roll');stage=5
  elseif stage==5 and s.phase~='rolling' then
   physical_check(s);assert(s.hand[1]~=2);record('PASS actual engraved throw: visible top and scoring value agree')
   capture('preview-engraved.png');stage=51
  elseif stage==51 then
   s.phase='fresh';s.pot=0;s.used={};s.bank=0;s.turn=1;U:sync()
   feed({1,1,1,5,5,5});select_all();click('bank');assert(s.phase=='medal');click('medal')
   feed({2,2,3,3,4,6});assert(s.phase=='rescue');stage=6
  elseif stage==6 then capture('preview-medal.png');stage=61
  elseif stage==61 then click('rescue');assert(s.medalUsed);stage=7
  elseif stage==7 and s.phase~='rolling' then
   physical_check(s);record('PASS medal triggered from controlled Farkle then genuine physical rescue')
   s.phase='fresh';s.pot=0;s.used={};s.bank=0;s.turn=1;s.turnHot=false;s.turnGroup=false;U:sync()
   feed({1,2,3,4,5,6});select_all();click('take');assert(s.hot);feed({1,1,1,2,3,4})
   for i=1,3 do click('die'..i) end;click('bank');assert(s.phase=='won');record('PASS three commissions, banked group/hot conditions and persistent build')
   love.window.setMode(1280,720,{resizable=true});love.resize(1280,720);stage=8
  elseif stage==8 then capture('preview-720.png');stage=81
  elseif stage==81 then
   click('control');assert(U.game.mode=='control');record('PASS resized UI and base-game control mode');stage=9
  elseif stage==9 then
   U:reset('build');U.game.build=family;D.install(family);click('roll');stage=10
  elseif stage==10 and s.phase~='rolling' then
   physical_check(s);local face,value=top(dice[1]);sample=sample+1
   observations:write(family..','..sample..','..face..','..value..'\n');observations:flush()
   if sample%4==0 then record('Physical samples '..family..': '..sample..'/12') end
   if sample==12 then
    if family=='normal' then family='weighted';sample=0;stage=9
    else record('PASS 12 normal + 12 weighted accepted physical samples, every value verified against top face');observations:close();log:close();love.event.quit(0) end
   else stage=9 end
  end
 end
end
return M
