local M={}
function M.install(U)
 local R=require('experiments.arte_del_rischio.rules')
 local Res=require('src.core.resolution_manager')
 local Bridge=require('src.core.engine_bridge')
 local root=assert(os.getenv('SCRIPTORIUM_RISK_ROOT'))..'/experiments/arte_del_rischio/'
 local quick=os.getenv('SCRIPTORIUM_RISK_QUICK')=='1'
 local log=assert(io.open(root..(quick and 'smoke-quick.log' or 'smoke.log'),'w'))
 local function record(s) log:write(s..'\n'); log:flush(); print(s) end
 function love.errorhandler(e)
  record('FAIL '..tostring(e)..'\n'..debug.traceback()); log:close()
  return function() return 1 end
 end
 local load,update,draw=love.load,love.update,love.draw
 local stage,variant,frames,elapsed=0,1,0,0
 local variants={'A','B','C'}; local held_face,held_vertices
 local samples=0; local frequencies={0,0,0,0,0,0}; local illustrated=false
 local function click(id)
  U:draw() -- refresh hitboxes after a previous action, as the next frame would
  local b=assert(U.buttons[id],id); assert(b.enabled,'disabled '..id)
  local x,y=Res.to_screen(b.x+b.w/2,b.y+b.h/2); U:mousepressed(x,y,1)
 end
 local function capture(name)
  love.graphics.captureScreenshot(function(data)
   local f=assert(io.open(root..name,'wb')); f:write(data:encode('png'):getString()); f:close()
   record('SCREENSHOT '..name)
  end)
 end
 function love.load()
  load(); math.randomseed(842); love.math.setRandomSeed(842)
  assert(love.filesystem.getIdentity()=='scriptorium-arte-del-rischio')
  assert(#dice==4)
  for _,d in ipairs(dice) do for face,value in ipairs(d.die.faceValueMap) do
   assert(math.abs(d.die.faceColors[face][1]-R.colors[value][1]*255)<.001)
  end end
  record('PASS isolated identity, four D6 and six face pigment mappings')
 end
 function love.update(dt)
  elapsed=elapsed+dt; assert(elapsed<500,'smoke timeout stage '..stage..' samples '..samples)
  update(math.min(dt,.05))
 end
 function love.draw()
  draw(); frames=frames+1; if frames%12~=0 then return end
  local s=U.game
  if stage==0 then
   U:reset(variants[variant]); stage=1
  elseif stage==1 then
   if s.variant~='B' then click('project1') end
   click('roll'); assert(s.phase=='rolling')
   U:keypressed('c'); assert(U.game==s,'variant changed during roll')
   stage=2
  elseif stage==2 and s.phase=='ready' then
   if s.variant=='B' then click('project1') end
   local hits=U.hits; assert(#hits==4,'four pick targets')
   for _,hit in ipairs(hits) do
    assert(Bridge.pickTrayDie(hit.x,hit.y)==hit.index,'picking projected center')
   end
   local h=hits[1]; U:mousepressed(h.x,h.y,1); assert(U.held[h.index])
   for i=1,4 do if not U.held[i] then U:toggle(i) end end
   U:draw(); assert(not U.buttons.roll.enabled,'all held must disable roll')
   for i=1,4 do if i~=h.index then U:toggle(i) end end
   held_face={index=h.index,value=s.hand[h.index]}; held_vertices={}
   for i,v in ipairs(dice[h.index].body) do held_vertices[i]={v[1],v[2],v[3]} end
   click('roll'); stage=3
  elseif stage==3 and s.phase~='rolling' then
   assert(s.hand[held_face.index]==held_face.value,'held pigment changed')
   for i,v in ipairs(dice[held_face.index].body) do
    for k=1,3 do assert(math.abs(v[k]-held_vertices[i][k])<1e-8,'held orientation changed') end
   end
   record('PASS '..variants[variant]..' physical roll, partial reroll, holds, picking, input lock')
   if variant==1 then love.window.setMode(1280,720,{resizable=true}); love.resize(1280,720) end
   stage=4
  elseif stage==4 then
   for _,hit in ipairs(U.hits) do assert(Bridge.pickTrayDie(hit.x,hit.y)==hit.index,'resize picking') end
   record('PASS '..variants[variant]..' resize picking')
   if variant==2 then capture('preview-720.png') end
   if variant<3 then variant=variant+1; stage=0
   else love.window.setMode(1920,1080,{resizable=true}); love.resize(1920,1080); stage=5 end
  elseif stage==5 then
   capture('preview-1080.png'); stage=6
  elseif stage==6 then
   -- Controlled callbacks for otherwise rare UI branches, separate from physical tests.
   U:reset('C'); R.select(U.game,3); R.start(U.game,15); U.state='rolling'
   U:onDiceSettled({{index=1,value=1},{index=2,value=1},{index=3,value=4},{index=4,value=4}})
   stage=7
  elseif stage==7 then click('project1'); assert(s.changed); click('bank'); assert(s.score==1 and #s.works==1); stage=8
  elseif stage==8 then
   click('pass'); assert(s.turn==2)
   R.select(s,3); R.start(s,15); U:onDiceSettled({{index=1,value=5},{index=2,value=5},{index=3,value=5},{index=4,value=5}})
   for j=1,2 do R.start(s,1); U:onDiceSettled({{index=1,value=5}}) end
   U.held={false,true,true,true}; stage=9
  elseif stage==9 then click('tempt'); assert(s.score==0 and s.temptations==1 and s.phase=='rolling'); stage=10
  elseif stage==10 and s.phase~='rolling' then
   record('PASS controlled C change, bank, next turn, paid physical Tentation')
   -- Exhaust turns using the actual end-turn action.
   R.abandon(s); while not s.finished do R.next_turn(s); R.abandon(s) end
   assert(s.turn==8 and not s.won)
   record('PASS eight-turn result; original save path never used')
   if quick then log:close(); love.event.quit(0); return end
   stage=11
  elseif stage==11 then
   U:reset('C'); R.select(U.game,1); U:request(false); stage=12
  elseif stage==12 and s.phase=='ready' then
   samples=samples+1
   if samples%8==0 then record('Physical samples: '..samples..'/64') end
   for _,v in ipairs(s.hand) do frequencies[v]=frequencies[v]+1 end
   if not illustrated then
    for p=1,3 do if R.score(p,s.hand)>0 then
     if p~=s.project then R.select(s,p) end
     R.bank(s); illustrated=true; stage=13; return
    end end
   end
   if samples>=64 then
    local f=assert(io.open(root..'physical-sample.csv','w'))
    f:write('pigment,count\n'); for p,n in ipairs(frequencies) do f:write(R.names[p]..','..n..'\n') end; f:close()
    record('PASS 64 physical initial rolls, 256 face observations: '..table.concat(frequencies,','))
    log:close(); love.event.quit(0)
   else stage=11 end
  elseif stage==13 then capture('preview-work-1080.png'); stage=11
  end
 end
end
return M
