local out=assert(os.getenv('MANUSCRIPT_AUDIT_OUT'))
local baseline=os.getenv('MANUSCRIPT_FRONTEND_SMOKE')=='baseline'
local log=assert(io.open(out..'/frontend.log','w'))
local function say(s) log:write(s..'\n');log:flush() end
function love.errorhandler(e) say('FAIL '..tostring(e)..'\n'..debug.traceback());return function() return 1 end end
local GM=require('src.core.game_manager');local new=GM.new;local manager
GM.new=function(...) manager=new(...);return manager end
local N=require('src.core.navigation')
local Menu=require('src.features.main_menu.module')
local Settings=require('src.features.settings.module')
local Choose=require('src.features.campaign_select.module')
local U=require('src.features.farkle.controller')
local State=require('src.core.settings_state')
local assets={}
for _,entry in ipairs{{love.graphics,'newImage'},{love.graphics,'newFont'},{love.graphics,'newShader'},{love.audio,'newSource'}} do
 local api,key=entry[1],entry[2];local original=api[key]
 api[key]=function(path,...)
  if type(path)=='string' and not path:find('\n',1,true) then assets[path]=key end
  return original(path,...)
 end
end
local function up(fn,name)
 for i=1,100 do local n,v=debug.getupvalue(fn,i);if not n then break end;if n==name then return v end end
 error('upvalue missing '..name)
end
local function click(r)
 assert(r and r.x>=0 and r.y>=0 and r.x+r.w<=love.graphics.getWidth()+1 and r.y+r.h<=love.graphics.getHeight()+1,'control outside window')
 love.mousepressed(r.x+r.w/2,r.y+r.h/2,1)
end
local function menu(id)
 Menu:draw();local layout=up(Menu.draw,'cached_layout');local items=up(Menu.activate,'menu_items')
 for i,v in ipairs(items) do if v.id==id then click(layout.item_rects[i]);return end end
 error(id)
end
local function wait(t) coroutine.yield({seconds=t or 1.2}) end
local function shot(name) coroutine.yield({shot=name}) end
local function scenario(w,h)
 local settings=State.get();settings.video.window_mode='Windowed';State.set(settings)
 love.window.setMode(w,h,{resizable=true,vsync=1,fullscreen=false,borderless=false});love.resize(w,h)
 N.go('startup_splash');wait(2);shot(w..'-splash')
 if not baseline and w==1920 then
  wait(6);shot(w..'-splash-title');wait(5)
  assert(manager.current_name=='main_menu','automatic splash completion failed')
  say('PASS complete splash animation and automatic menu transition')
 end
 say('Before splash skip: '..tostring(manager.current_name))
 -- Observe the route before injecting input: the timed splash can finish naturally.
 if manager.current_name=='startup_splash' then love.keypressed('space') end
 assert(manager.current_name=='main_menu','splash destination: '..tostring(manager.current_name));wait()
 assert(manager.current_name=='main_menu','route changed while waiting: '..tostring(manager.current_name));shot(w..'-menu')
 if not baseline then local before=manager.current;menu('continue');assert(manager.current==before);say('PASS Continue disabled') end
 menu('settings');wait();assert(manager.current_name=='settings');shot(w..'-settings')
 Settings:draw();click(up(Settings.draw,'layout_cache').section_items[1]);wait();shot(w..'-settings-game')
 if not baseline then
  Settings:draw();local l=up(Settings.draw,'layout_cache');local old=State.get().game.verbose_logs
  click(l.controls[2]);click(l.actions[2]);assert(State.get().game.verbose_logs~=old)
  assert(State.load().game.verbose_logs~=old);say('PASS settings changed and reloaded from isolated disk')
  assert(love.graphics.getWidth()==w and love.graphics.getHeight()==h,'settings unexpectedly resized window')
 end
 N.go('settings');Settings:draw();local items=up(Settings.draw,'layout_cache').section_items;click(items[#items]);wait()
 assert(manager.current_name=='main_menu');menu('new-game');wait();assert(manager.current_name=='campaign_select');shot(w..'-commissions')
 Choose:draw();local layout=up(Choose.draw,'layout_cache')
 if not baseline then
  assert(#layout.items==2 and layout.items[1].label=='Farkle Roguelite' and layout.items[2].kind=='back')
  say('PASS only Farkle and Back are present')
 end
 click(layout.items[#layout.items]);wait();assert(manager.current_name=='main_menu')
 if not baseline then
  menu('new-game');wait();Choose:draw();click(up(Choose.draw,'layout_cache').items[1]);assert(manager.current_name=='scriptorium' and U.game)
  wait(.3);shot(w..'-farkle')
  assert(not package.loaded['src.features.scriptorium.module'] and not package.loaded['src.content.commissions'] and not package.loaded['src.core.save_state'])
  say('PASS '..w..' navigation, Farkle start and chromatic isolation')
 end
end
local load0,update0,draw0=love.load,love.update,love.draw
local co,pending,elapsed,frames
function love.load()
 load0()
 if baseline then
  for _,name in ipairs{'startup_splash','main_menu','settings','campaign_select'} do manager:register(name,require('src.features.'..name..'.module')) end
  N.go('startup_splash')
 else assert(manager.current_name=='startup_splash','normal boot must start at splash') end
 if not baseline then
  local _,_,flags=love.window.getMode();local v=State.get().video
  assert(v.fps_limit~=0 or flags.vsync==0,'startup overrides Unlimited/VSync preference')
  assert(v.window_mode~='Borderless' or flags.borderless,'startup overrides Borderless preference')
  assert(v.window_mode~='Fullscreen' or flags.fullscreen,'startup overrides Fullscreen preference')
  say('PASS startup respects persisted video settings')
 end
 elapsed=0;frames=0
 co=coroutine.create(function()
  scenario(1920,1080);scenario(1280,720)
  if not baseline then
   local settings=State.get();settings.accessibility.big_text=true;State.set(settings);State.apply()
   N.go('campaign_select');wait();Choose:draw();local l=up(Choose.draw,'layout_cache')
   shot('1280-commissions-big-text');click(l.items[#l.items]);assert(manager.current_name=='main_menu')
   say('PASS 720p Big Text keeps Back accessible')
   settings.accessibility.big_text=false;State.set(settings);State.apply()
  end
  if not baseline then
   N.go('main_menu');Menu:draw();local quit=love.event.quit;local called=false;love.event.quit=function()called=true end;menu('quit');love.event.quit=quit;assert(called);say('PASS Quit invokes application exit')
  end
  local f=assert(io.open(out..'/loaded-modules.txt','w'));local names={};for n in pairs(package.loaded) do assert(not n:find('^experiments%.'),'experimental runtime module: '..n);if n:find('^src%.') or n:find('^experiments%.') then names[#names+1]=n end end;table.sort(names);f:write(table.concat(names,'\n'));f:close()
  f=assert(io.open(out..'/loaded-assets.txt','w'));names={};for path,loader in pairs(assets) do names[#names+1]=loader..' '..path end;table.sort(names);f:write(table.concat(names,'\n'));f:close()
  say('PASS frontend complete');log:close();love.event.quit(0)
 end)
end
function love.update(dt)
 elapsed=elapsed+dt;assert(elapsed<100,'frontend timeout');update0(dt)
 if pending and pending.seconds then pending.seconds=pending.seconds-dt end
end
function love.draw()
 draw0();frames=frames+1
 if frames%4~=0 then return end
 if pending then
  if pending.seconds and pending.seconds>0 then return end
  if pending.shot then local name=pending.shot;love.graphics.captureScreenshot(function(data)local f=assert(io.open(out..'/'..name..'.png','wb'));f:write(data:encode('png'):getString());f:close()end);pending=nil;return end
 end
 if coroutine.status(co)~='dead' then local ok,p=coroutine.resume(co);assert(ok,p);pending=p end
end
