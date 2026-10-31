-- Adapted from audits/source-launch/integration.lua: restored frontend is permitted.
-- External diagnostic: executes current source callbacks, never assigns physical results.
local U=require('src.features.farkle.controller')
local R=require('src.gameplay.farkle.rules')
local D=require('src.features.farkle.dice')
local F=require('src.engine3d.face_state')
local P=require('src.engine3d.physics')
local out=assert(os.getenv('MANUSCRIPT_AUDIT_OUT'))
local load0,update0=love.load,love.update
local images,shaders={},{}
local image0,shader0=love.graphics.newImage,love.graphics.newShader
love.graphics.newImage=function(path,...)
 local result=image0(path,...);if type(path)=='string' then images[path]=true end;return result
end
love.graphics.newShader=function(code,...) local result=shader0(code,...);shaders[#shaders+1]=true;return result end
function love.run()
 local log=assert(io.open(out..'/integration.txt','w'))
 local function say(x) log:write(x..'\n');log:flush() end
 local ok,err=xpcall(function()
  load0()
  assert(love.filesystem.getIdentity()=='manuscript-farkle-roguelite')
  assert(love.filesystem.getSaveDirectory():find('/appdata/',1,true),love.filesystem.getSaveDirectory())
  for _,name in ipairs{'src.features.scriptorium.module','src.features.run.module','src.features.reward.module','src.core.save_state','src.gameplay.run','src.gameplay.folio'} do
   assert(not package.loaded[name],'legacy dependency loaded: '..name)
  end
  local modules={};for n in pairs(package.loaded) do assert(not n:find('^experiments%.'),'experimental runtime module: '..n);if n:find('^src%.') or n:find('^experiments%.') then modules[#modules+1]=n end end;table.sort(modules)
  local inventory=assert(io.open(out..'/loaded-modules.txt','w'));inventory:write(table.concat(modules,'\n'));inventory:close()
  say('PASS source bootstrap, Farkle identity, isolated saves, no legacy gameplay loaded')
  local proposed,rejected=0,0
  local oldlog=U.log
  U.log=function(self,event,detail)
   if event=='weighted_proposal' then proposed=proposed+1;if detail:find('retry') then rejected=rejected+1 end end
   return oldlog(self,event,detail)
  end
  local function top(d)
   local best,z=1,-math.huge
   for f,face in ipairs(d.die.faces) do local h=0;for _,i in ipairs(face) do h=h+d.body[i][3] end;h=h/#face;if h>z then best,z=f,h end end
   return d.die.faceValueMap[best]
  end
  local function settle()
   local steps=0
   while U.game.phase=='rolling' and U.state~='physics_error' and steps<12000 do update0(1/60);steps=steps+1 end
   assert(U.state~='physics_error' and U.game.phase~='rolling','physical throw failed')
   for _,i in ipairs(U.game.active) do assert(U.game.hand[i]==top(dice[i]),'visible face/value mismatch') end
   return steps
  end
  for _,build in ipairs{'normal','engraved','weighted'} do
   for _,seed in ipairs{54083,87001} do
    U:reset('build');U.game.build=build;D.install(build);P.box.timeleft=0
    love.math.setRandomSeed(seed);math.randomseed(seed)
    assert(U:request());local n=settle()
    say('PASS physical '..build..' seed='..seed..' steps='..n..' faces='..table.concat(U.game.hand,'/'))
   end
  end
  for seed=91001,91006 do
   if rejected>0 then break end
   U:reset('build');U.game.build='weighted';D.install('weighted');P.box.timeleft=0
   love.math.setRandomSeed(seed);math.randomseed(seed);assert(U:request());settle()
   say('PASS additional weighted retry coverage seed='..seed)
  end
  say('Weighted proposals='..proposed..' rejected='..rejected..' (physical retries, not a distribution study)')
  assert(rejected>0,'weighted retry not exercised')
  for _,build in ipairs{'normal','engraved','weighted'} do
   U:reset('build');U.game.build=build;D.install(build);assert(R.equip_reference(U.game,'reroll_gold'))
   P.box.timeleft=0;love.math.setRandomSeed(54083);math.randomseed(54083)
   assert(U:request());settle();say('Reference opening '..build..' phase='..U.game.phase..' faces='..table.concat(U.game.hand,'/'))
   while U.game.phase=='ended' do assert(R.next_turn(U.game));U:sync();assert(U:request());settle() end
   assert(U.game.phase=='ready','no valid throw within commission for medal integration')
   local positions,faces={},{unpack(U.game.hand)}
   for i,d in ipairs(dice) do positions[i]={unpack(d.body.position)} end
   assert(U:activate_reference({1,3}));assert(#U.game.active==2);settle()
   for _,i in ipairs{2,4,5,6} do
    assert(U.game.hand[i]==faces[i],'medal changed retained result')
    for k=1,3 do assert(dice[i].body.position[k]==positions[i][k],'medal moved excluded die') end
   end
   assert(require('src.gameplay.farkle.medals').remaining(U.game)==0)
   say('PASS reference medal real selective reroll '..build..': retained faces/positions, visible result, single charge')
  end
  -- Controlled rule fixtures lead into genuine physical hot-dice and medal rolls.
  U:reset('build');local s=U.game;assert(R.start(s));assert(R.settle(s,{1,2,3,4,5,6}));U:sync()
  for i=1,6 do assert(R.toggle(s,i)) end;assert(R.take(s));U:sync();assert(s.hot)
  assert(U:request());assert(#s.active==6);settle();say('PASS hot dice relaunches all six physical bodies')
  U:reset('build');s=U.game;s.medal='retry'
  assert(R.start(s));assert(R.settle(s,{2,2,3,3,4,6}));U:sync();assert(s.phase=='rescue')
  assert(U:request(true));assert(s.medalUsed);settle();say('PASS medal initiates real physical rescue')
  D.install('engraved')
  for i,d in ipairs(dice) do for f=1,6 do
   local path='resources/dice/'..D.values('engraved',i)[f]..'.png'
   assert(love.filesystem.getInfo(path,'file'));d.die.image(f,0,0,1,0,1,1,0,1)
   assert(images[path],'texture not loaded '..path)
  end end
  U:draw()
  -- The old chromatic desk image-loader is retired; normal Farkle never
  -- loads its config, palette or obsolete PNG layers.
  assert(not package.loaded['src.features.scriptorium.desk_view'],
    'retired chromatic desk imported into the active Farkle session')
  assert(not package.loaded['src.data.scriptorium_module_config'],
    'obsolete desk configuration imported')
  for path in pairs(images) do
    assert(not path:find('resources/ui/desk/',1,true),
      'retired desk layer loaded: '..path)
  end
  assert(#shaders>0,'glow shader not loaded')
  say('PASS 36 face texture calls, shared background/desk/parchment, fonts and glow shader')
  assert(not love.filesystem.getInfo('scriptorium_save.lua'))
  say('PASS no legacy save created; settings remain in Farkle identity')
 end,debug.traceback)
 if not ok then say('FAIL '..err) end;log:close()
 return function() return ok and 0 or 1 end
end
