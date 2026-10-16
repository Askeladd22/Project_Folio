-- Observation harness only. All original source files are loaded unchanged.
-- Canonical entry is already loaded by main.lua.
local out=assert(os.getenv('MANUSCRIPT_AUDIT_OUT'))
local focused=os.getenv('MANUSCRIPT_AUDIT_FOCUSED')=='1'
local log=assert(io.open(out..(focused and '/focused.txt' or '/observations.txt'),'w'))
local function say(s) log:write(s..'\n');log:flush() end
local P=require('src.engine3d.physics')
local G=require('src.engine3d.geometry')
local U=require('src.features.farkle.controller')
local B=require('src.core.engine_bridge')
local box=P.box
local load0,update0,draw0=love.load,love.update,love.draw
local timings={};local oldbox=box.update
function box:update(dt)
 local t=love.timer.getTime();oldbox(self,dt);timings[#timings+1]=(love.timer.getTime()-t)*1000
end
local function copy(t)
 if type(t)~='table' then return t end
 local r={};for k,v in pairs(t) do r[k]=copy(v) end;return setmetatable(r,getmetatable(t))
end
local function summary(name,a)
 table.sort(a);local sum=0;for _,v in ipairs(a) do sum=sum+v end
 say(string.format('%s n=%d mean=%.6f p50=%.6f p95=%.6f max=%.6f ms',name,#a,sum/#a,a[math.ceil(#a*.5)],a[math.ceil(#a*.95)],a[#a]))
end
local function testbox(bodies)
 local b=clone(P.box,{timeleft=0,log_buffer={}}):set(100,100,100,0,0.25,0.75,.01)
 b.linear_damping=0;b.angular_damping=0
 for i,v in ipairs(bodies) do b[i]=v end;return b
end
local function body(x,y,z)
 local b=G.newD6Body(.92):set({x,y,z},{0,0,0},{0,0,0});P.materials.apply(b,P.materials.get('bone'));return b
end
local function isolated()
 local a,b=body(0,0,5),body(0,0,5);local w=testbox{a,b};w:update(.02)
 say('coincident_centers distance='..(b.position-a.position):abs())
 a,b=body(0,0,5),body(1,0,5);w=testbox{a,b};local before=(b.position-a.position):abs();w:update(0)
 say('update_zero overlap distance_before='..before..' after='..(b.position-a.position):abs())
 a,b=body(-2,0,5),body(2,0,5);a.velocity=vector{500,0,0};b.velocity=vector{-500,0,0};w=testbox{a,b};w:update(.010001)
 say('fast_crossing xA='..a.position[1]..' xB='..b.position[1]..' vxA='..a.velocity[1]..' vxB='..b.velocity[1])
 a=body(0,0,5);a.velocity=vector{0,0,1};a.restitution=.3;a.friction=0;a:wall(1,vector{0,0,1},.3,0)
 say('separating_wall velocity_z_after='..a.velocity[3])
 local function free(dt,n)
  local c=body(0,0,5);c.velocity=vector{1,0,0};c.linear_damping=0;c.angular_damping=0
  local q=testbox{c};for i=1,n do q:update(dt) end;return c.position[1],q.timeleft
 end
 for _,fps in ipairs{10,20,30,60,144} do local x,left=free(1/fps,fps);say('one_second_free fps='..fps..' x='..x..' remainder='..left) end
 a=body(0,0,0);local r=rotation():set(math.pi/4,vector{1,0,0});local minz=math.huge
 for i,v in ipairs(a) do a[i]=r(v);minz=math.min(minz,a[i][3]) end
 a.position[3]=-minz;w=testbox{a};w.gravity=25;for i=1,1200 do w:update(1/60) end
 local zs={};for _,f in ipairs(G.d6.faces) do local z=0;for _,i in ipairs(f) do z=z+a[i][3] end;zs[#zs+1]=z/#f end;table.sort(zs)
 say('edge_start after20s asleep='..tostring(a.asleep)..' top_gap='..(zs[6]-zs[5])..' z='..a.position[3])
 local c=body(0,0,5);local orig={};for i,v in ipairs(c) do orig[i]=v:abs() end;c.angular=vector{3,4,5}
 for i=1,100000 do c:update(.01) end
 local drift=0;for i,v in ipairs(c) do drift=math.max(drift,math.abs(v:abs()-orig[i])) end;say('rotation_100000_steps_max_radius_drift='..drift)
end
local result
local originalSettled=U.onDiceSettled
-- Observe only the physical callback; do not run commissions/rewards in statistical trials.
function U:onDiceSettled(values) result=copy(values);self.state='waiting' end
local snapshots
local function restore()
 for i,s in ipairs(snapshots) do dice[i].body=copy(s);dice[i].kept=false end
 box.timeleft=0;U.retry=nil;U.activePhysical=nil
end
local function runthrow(seed,dt,reset)
 if reset then restore() end
 if seed then love.math.setRandomSeed(seed);math.randomseed(seed) end
 for _,d in ipairs(dice) do d.kept=false end
 result=nil;U.onRollRequest();local frames=0;local t=love.timer.getTime()
 while not result and not U.physicalFailure and frames*dt<65 do update0(dt);frames=frames+1 end
 local ms=(love.timer.getTime()-t)*1000
 local vals={0,0,0,0,0,0};for i,v in ipairs(result or {}) do vals[i]=v.value end
 local minup=1;local mingap=math.huge;local floor=0
 for _,d in ipairs(dice) do
  local heights={};for _,f in ipairs(d.die.faces) do local z=0;for _,i in ipairs(f) do z=z+d.body[i][3] end;heights[#heights+1]=z/#f end
  table.sort(heights);minup=math.min(minup,heights[6]/(.92/1.6));mingap=math.min(mingap,heights[6]-heights[5])
  for _,v in ipairs(d.body) do floor=math.min(floor,v[3]+d.body.position[3]) end
 end
 local retries,ambiguous,timeouts=0,0,0
 local invalid,mismatch=0,0
 local F=require('src.engine3d.face_state')
 for _,v in ipairs(result or {}) do local e=dice[v.index];local q=F.inspect(e)
  if not q.valid then invalid=invalid+1 end
  if (e.die.faceValueMap or e.die.pipMap)[q.face]~=v.value then mismatch=mismatch+1 end
 end
 for _,e in ipairs(U.physicalResolution and U.physicalResolution.events or {}) do
  retries=retries+1
  if e.reason=='timeout' then timeouts=timeouts+1 else ambiguous=ambiguous+1 end
  say('RECOVERY seed='..tostring(seed)..' fps='..(1/dt)..' reason='..e.reason..' age='..e.age)
 end
 return vals,result~=nil,frames*dt,ms,minup,mingap,floor,retries,ambiguous,timeouts,U.physicalFailure and 1 or 0,invalid,mismatch
end
local function capture(name)
 love.graphics.captureScreenshot(function(data) local f=assert(io.open(out..'/'..name..'.png','wb'));f:write(data:encode('png'):getString());f:close() end)
 love.graphics.present()
end
local function graphics_tests()
 U.onDiceSettled=originalSettled;U.state='waiting';U:reset('control')
 require('src.core.runtime_state').apply_settings({video={fps_limit=0}})
 local originalOverlay=U.drawDeskOverlays;local hits
 function U:drawDeskOverlays(h) hits=h;return originalOverlay(self,h) end
 for _,wh in ipairs{{1280,720},{1920,1080}} do
  love.window.setMode(wh[1],wh[2],{vsync=0,resizable=true});love.resize(wh[1],wh[2])
  U.state='waiting';U:reset('control');restore();love.math.setRandomSeed(881);U:request();result=nil
  local draws,updates,presents={},{},{};local bounded=true;local startmem=collectgarbage('count')
  for frame=1,240 do
   local t=love.timer.getTime();update0(1/60);updates[#updates+1]=(love.timer.getTime()-t)*1000
   love.graphics.origin();love.graphics.clear();t=love.timer.getTime();draw0();love.graphics.flushBatch();draws[#draws+1]=(love.timer.getTime()-t)*1000
   local p=U.trayProjection
   for _,v in ipairs(p.points) do local x,y=p.cx+v[1]*p.scale,p.cy+v[2]*p.scale;local r=p.rect;if x<r.x or x>r.x+r.w or y<r.y or y>r.y+r.h then bounded=false end end
   if frame==15 then capture(wh[1]..'-rolling') else t=love.timer.getTime();love.graphics.present();presents[#presents+1]=(love.timer.getTime()-t)*1000 end
  end
  local wait=0;while U.game.phase=='rolling' and wait<1800 do update0(1/60);wait=wait+1 end
  love.graphics.origin();love.graphics.clear();draw0()
  local ok,total=0,0;for _,h in ipairs(hits or {}) do total=total+1;if B.pickTrayDie(h.x,h.y)==h.index then ok=ok+1 end end
  say('graphics '..wh[1]..' final_phase='..U.game.phase..' extra_wait_seconds='..wait/60)
  say('graphics '..wh[1]..' bounds='..tostring(bounded)..' center_picks='..ok..'/'..total..' raw_heap_delta_KB='..(collectgarbage('count')-startmem))
  summary('update_'..wh[1],updates);summary('draw_submit_'..wh[1],draws);summary('present_'..wh[1],presents)
  love.graphics.origin();love.graphics.clear();draw0();capture(wh[1]..'-settled')
  if U.game.phase=='ready' then
   local R=require('src.gameplay.farkle.rules')
   for mask=1,63 do local hand,ids={},{};for i=1,6 do if math.floor(mask/2^(i-1))%2==1 then hand[#hand+1]=U.game.hand[i];ids[#ids+1]=i end end
    if R.score(hand) then for _,i in ipairs(ids) do local h=hits[i];U:mousepressed(h.x,h.y,1) end;break end
   end
   love.graphics.origin();love.graphics.clear();draw0();capture(wh[1]..'-picked')
   say('mouse_selection '..wh[1]..' score='..tostring(R.selection(U.game)))
  end
 end
end
local function overlap(a,b)
 local axes={}
 local function basis(c) return {(c[2]-c[1]):norm(),(c[4]-c[1]):norm(),(c[5]-c[1]):norm()} end
 local aa,bb=basis(a),basis(b)
 for _,v in ipairs(aa) do axes[#axes+1]=v end;for _,v in ipairs(bb) do axes[#axes+1]=v end
 for _,x in ipairs(aa) do for _,y in ipairs(bb) do local v=x^y;if v:abs()>1e-8 then axes[#axes+1]=v:norm() end end end
 local pen=math.huge
 for _,n in ipairs(axes) do
  local lo,hi,lo2,hi2=math.huge,-math.huge,math.huge,-math.huge
  for _,v in ipairs(a) do local p=(v+a.position)..n;lo=math.min(lo,p);hi=math.max(hi,p) end
  for _,v in ipairs(b) do local p=(v+b.position)..n;lo2=math.min(lo2,p);hi2=math.max(hi2,p) end
  local d=math.min(hi,hi2)-math.max(lo,lo2);if d<=0 then return 0 end;pen=math.min(pen,d)
 end
 return pen
end
local function focused_tests()
 local rr1=runthrow(99117,1/60,true);local state={};for i,d in ipairs(dice) do state[i]=copy(d.body) end
 local rr2=runthrow(99117,1/60,true);local diff=0
 for i,d in ipairs(dice) do for k=1,8 do for j=1,3 do diff=math.max(diff,math.abs(d.body[k][j]-state[i][k][j])) end end;for j=1,3 do diff=math.max(diff,math.abs(d.body.position[j]-state[i].position[j])) end end
 say('replay_same_seed_max_pose_difference='..diff)
 local a,b=body(0,0,.575),body(1.55,0,.575);local rot=rotation():set(math.pi/4,vector{0,0,1})
 for i=1,8 do a[i]=rot(a[i]);b[i]=rot(b[i]) end
 a.asleep=true;b.asleep=true;local w=testbox{a,b};w:update(.02)
 say('cube_SAT_overlap_missed_by_spheres='..overlap(a,b)..' sphere_distance='..(b.position-a.position):abs()..' radius_sum='..(a.radius+b.radius))
 a,b=body(0,0,.575),body(0,0,.575+1.45);a.asleep=true;b.asleep=true;w=testbox{a,b};w:update(0)
 local zmin=math.huge;for _,v in ipairs(a) do zmin=math.min(zmin,v[3]+a.position[3]) end
 say('sleeping_stack_after_zero_update lower_floor='..zmin..' upper_z='..b.position[3]);w:update(.02)
 local z2=math.huge;for _,v in ipairs(a) do z2=math.min(z2,v[3]+a.position[3]) end;say('sleeping_stack_after_steps lower_floor='..z2..' lower_asleep='..tostring(a.asleep))
 -- Test pile at same center and modest separations using real integration, not forcing final poses.
 for _,gap in ipairs{0,.1,1.15} do
  local bodies={};for i=1,6 do bodies[i]=body(0,0,1+(i-1)*gap) end;w=testbox(bodies);w.gravity=25
  for frame=1,1200 do w:update(1/60) end
  local asleep,pairs=0,0;for i,c in ipairs(bodies) do if c.asleep then asleep=asleep+1 end;for j=i+1,6 do if overlap(c,bodies[j])>.001 then pairs=pairs+1 end end end
  say('pile_gap='..gap..' after20s asleep='..asleep..'/6 overlapping_cube_pairs='..pairs)
 end
 local overlaps,ground,most,maxrim=0,0,0,0
 for seed=50001,50040 do
  runthrow(seed,1/60,true);local hits=0
  for i,d in ipairs(dice) do
   for _,v in ipairs(d.body) do if v[3]+d.body.position[3]<-.001 then ground=ground+1;break end end
   for _,v in ipairs(d.body) do maxrim=math.max(maxrim,math.abs(v[2]+d.body.position[2])-3.05) end
   for j=i+1,6 do local p=overlap(d.body,dice[j].body);if p>.001 then hits=hits+1;most=math.max(most,p) end end
  end
  if hits>0 then overlaps=overlaps+1 end
 end
 say('ordinary40 settled_throws_with_cube_overlap='..overlaps..' max_SAT_depth='..most..' dice_below_floor_more_than_.001='..ground..' max_front_back_vertex_overrun='..maxrim)
 restore();for _,d in ipairs(dice) do d.kept=true end
 dice[1].body.position=vector{0,4,5};dice[1].body.velocity=vector{0,0,0};update0(0)
 say('airborne_region_clamp y_before=4 z=5 y_after='..dice[1].body.position[2])
 -- Affine face image transform: fourth corner is not used by the production transform.
 local view=require('src.engine3d.view');view.pitch=.4;view.cos_pitch=math.cos(.4);view.sin_pitch=math.sin(.4)
 local c=body(0,0,.9);rot=rotation():set(.5,vector{1,1,0});for i=1,8 do c[i]=rot(c[i]) end
 local points={};for _,i in ipairs(G.d6.faces[1]) do points[#points+1]={view.project(unpack(c[i]+c.position))} end
 love.graphics.origin();love.graphics.push();love.graphics.transform(points[1][1],points[1][2],points[2][1],points[2][2],points[4][1],points[4][2])
 local x,y=love.graphics.transformPoint(1,1);love.graphics.pop()
 say('affine_face_fourth_corner_projection_error='..math.sqrt((x-points[3][1])^2+(y-points[3][2])^2)..' projected_units')
 graphics_tests()
end
function love.run()
 local function audit()
  load0();say('LOVE '..love.getVersion()..' '..jit.version);say('renderer '..table.concat({love.graphics.getRendererInfo()},' | '))
  say(string.format('runtime box gravity=%g bounce=%g friction=%g dt=%g max_steps=%d',box.gravity,box.bounce,box.friction,box.dt,box.max_steps))
  say(string.format('body mass=%g theta=%g radius=%g restitution=%g friction=%g',dice[1].body.mass,dice[1].body.theta,dice[1].body.radius,dice[1].body.restitution,dice[1].body.friction))
  snapshots={};for i,d in ipairs(dice) do snapshots[i]=copy(d.body) end
  if os.getenv('MANUSCRIPT_LEGACY_GATE')=='1' then
   U.onPhysicalFailure=nil;U.onRollRequest()
   assert(not U.physicalResolution,'Recovery enabled for an adapter without technical-failure UI')
   say('PASS legacy adapter retains its existing settlement path');log:close();return
  end
  if os.getenv('MANUSCRIPT_FACE_GATE')=='1' then
   result=nil;U:reset('control');assert(U:request())
   for attempt=1,3 do
   for i,d in ipairs(dice) do
    local b=body(-4+i,0,2);b.asleep=true
    if i==1 then local r=rotation():set(math.pi/4,vector{1,0,0});for k,v in ipairs(b) do b[k]=r(v) end end
    local low=math.huge;for _,v in ipairs(b) do low=math.min(low,v[3]) end;b.position[3]=-low;d.body=b
   end
   for frame=1,30 do update0(1/60) end
   assert(not result,'Ambiguous edge result was accepted by the game adapter')
   assert(U.physicalResolution and U.physicalResolution.retries==math.min(attempt,2),'Missing bounded physical recovery')
   end
   assert(U.physicalFailure and U.state=='physics_error','No terminal technical failure')
   local s=U.game;local turn,pot,bank=s.turn,s.pot,s.bank
   for i=1,100 do update0(1/60) end
   assert(U.physicalResolution.retries==2 and not result,'Automatic retry loop after exhaustion')
   U:draw();assert(U.buttons.retryphysical.enabled and U.buttons.runmenu.enabled,'Technical failure has no usable actions')
   U.buttons.retryphysical.fn()
   assert(U.physicalResolution.retries==0 and not U.physicalFailure and U.state=='rolling')
   assert(s.turn==turn and s.pot==pot and s.bank==bank,'Technical recovery changed game rules')
   say('PASS ambiguous pose rejected, bounded recovery, manual retry and unchanged Farkle state');log:close();return
  end
  if os.getenv('MANUSCRIPT_CONTACT_DIAGNOSTIC')=='1' then
   local hook=box.after_step
   for _,mode in ipairs{'production','without_region_clamp'} do
    if mode=='without_region_clamp' then box.after_step=nil end
    for _,seed in ipairs{50088,50217,50001,50002} do
     local _,ok,seconds=runthrow(seed,1/60,true)
     say('diagnostic '..mode..' seed='..seed..' settled='..tostring(ok)..' seconds='..seconds)
     for i,d in ipairs(dice) do local b=d.body
      say(string.format('die%d pos=(%.4f,%.4f,%.4f) v=%.8f w=%.8f asleep=%s supported=%s',i,b.position[1],b.position[2],b.position[3],b.velocity:abs(),b.angular:abs(),tostring(b.asleep),tostring(b._supported)))
     end
    end
   end
   box.after_step=hook;say('COMPLETE diagnostic');log:close();return
  end
  if focused then focused_tests();say('COMPLETE focused');log:close();return end
  isolated();timings={}
  local csv=assert(io.open(out..'/throws.csv','w'));csv:write('trial,seed,fps,settled,seconds,cpu_ms,min_up,min_gap,min_floor,v1,v2,v3,v4,v5,v6,recovery_events,ambiguous_events,timeout_events,failed,invalid_accepted,value_mismatch\n')
  local function row(id,seed,fps,reset)
   local v,ok,secs,ms,up,gap,floor,retries,ambiguous,timeouts,failed,invalid,mismatch=runthrow(seed,1/fps,reset)
   local fields={id,seed or '',fps,tostring(ok),secs,ms,up,gap,floor};for _,n in ipairs(v) do fields[#fields+1]=n end;for _,n in ipairs{retries,ambiguous,timeouts,failed,invalid,mismatch} do fields[#fields+1]=n end;csv:write(table.concat(fields,',')..'\n');csv:flush();return table.concat(v,'/'),ok
  end
  -- 300 independent controlled starts; six interacting physical dice per start.
  for i=1,300 do row('distribution',50000+i,60,true);if i%25==0 then say('distribution '..i..'/300');love.event.pump() end end
  for i=1,12 do for _,fps in ipairs{20,30,60,144,10} do row('fps',70000+i,fps,true) end end
  local a=row('replayA',99117,60,true);local b=row('replayB',99117,60,true);say('same_seed_full_reset_equal='..tostring(a==b))
  -- Consecutive rolls preserve orientation as ordinary play does.
  restore();love.math.setRandomSeed(99001);math.randomseed(99001)
  for i=1,100 do row('sequence',nil,60,false) end
  csv:close();summary('physics_all_updates',timings)
  graphics_tests();say('COMPLETE');log:close()
 end
 local ok,err=xpcall(audit,debug.traceback)
 if not ok then say('ERROR '..tostring(err));log:close() end
 return function() return ok and 0 or 1 end
end
