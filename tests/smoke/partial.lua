-- Canonical entry is already loaded by main.lua.
local U=require('src.features.farkle.controller')
local S=require('src.engine3d.spawn_clearance')
local P=require('src.engine3d.physics')
local load0,update0=love.load,love.update
local function copy(t) if type(t)~='table' then return t end;local r={};for k,v in pairs(t) do r[k]=copy(v) end;return setmetatable(r,getmetatable(t)) end
local function same(a,b) if type(a)~='table' then return a==b end;for k,v in pairs(a) do if not same(v,b[k]) then return false end end;for k in pairs(b) do if a[k]==nil then return false end end;return true end
function love.run()
 local f=assert(io.open(os.getenv('MANUSCRIPT_AUDIT_OUT')..'/partial.txt','w'))
 local function say(s) f:write(s..'\n');f:flush() end
 local ok,err=xpcall(function()
  load0();local snapshots={};for i,d in ipairs(dice) do snapshots[i]=copy(d.body) end
  local result
  U.onDiceSettled=function(self,values)result=values;self.state='waiting' end
  local function prepare(indices,variant)
   U.state='waiting';U:reset('control');P.box.timeleft=0;result=nil
   local active={};for _,i in ipairs(indices) do active[i]=true end
   for i,d in ipairs(dice) do d.body=copy(snapshots[i]);if not active[i] then d.body.position=vector{variant*2,variant,6};d.body.asleep=true;d.body.velocity=vector{0,0,0};d.body.angular=vector{0,0,0} end end
   love.math.setRandomSeed(87001);math.randomseed(87001)
   return active
  end
  for _,indices in ipairs{{1},{2,4,6},{1,2,3,4,5},{1,2,3,4,5,6}} do
   local ref,ref_rng
   for variant=0,1 do
    local active=prepare(indices,variant);local before={};for i,d in ipairs(dice) do before[i]=copy(d.body) end
    U:begin_physical(indices)
    local current={};for _,i in ipairs(indices) do current[i]=copy(dice[i].body) end
    if ref then assert(same(current,ref),'kept dice influenced spawn');assert(love.math.getRandomState()==ref_rng) else ref=current;ref_rng=love.math.getRandomState() end
    for a,i in ipairs(indices) do for b=a+1,#indices do local j=indices[b];assert(not S.intersects(dice[i].body,dice[i].body.position,dice[j].body,dice[j].body.position,S.margin)) end end
    local frames=0;while not result and frames<3900 do update0(1/60);frames=frames+1 end
    assert(result and #result==#indices,'subset did not settle')
    for i,d in ipairs(dice) do if not active[i] then assert(same(d.body,before[i]),'kept body changed') end end
   end
   say('PASS subset '..table.concat(indices,',')..': kept bodies excluded, unchanged through settlement, margin respected')
  end
  prepare({1},0);U.game.build='weighted';require('src.features.farkle.dice').install('weighted')
  U:begin_physical({1});local frames=0;while not result and frames<3900 do update0(1/60);frames=frames+1 end
  assert(result and #result==1 and result[1].index==1);say('PASS weighted die single-body physical reroll (acceptance rule tested separately)')
  prepare({1,3},0);local before={};for i,d in ipairs(dice) do before[i]=copy(d.body) end
  local original=S.place;S.place=function()return nil,{failed=true}end
  local bank,pot,turn=U.game.bank,U.game.pot,U.game.turn
  U:begin_physical({1,3});S.place=original
  assert(U.state=='physics_error' and not result)
  for i,d in ipairs(dice) do assert(same(d.body,before[i]),'failed plan modified body') end
  assert(U.game.bank==bank and U.game.pot==pot and U.game.turn==turn)
  U:retry_physical();frames=0;while not result and frames<3900 do update0(1/60);frames=frames+1 end
  assert(result and #result==2);say('PASS exhausted plan atomic rollback, no score change, explicit physical retry succeeds')
 end,debug.traceback)
 if not ok then say('FAIL '..err) end;f:close();return function()return ok and 0 or 1 end
end
