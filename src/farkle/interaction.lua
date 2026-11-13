local Parts = {}

-- Shake recognition
Parts.shake = (function()
-- Original LÖVE mouse-shake detector inspired by the mechanics observed
-- in Tabletop Simulator's .NET assembly. It does NOT contain TTS code.
-- A swift one-way throw is not a shake: require TWO strong reversals
-- inside a short window. All calculations use screen pixels and seconds.
local S={}
S.window=.85
S.min_distance=8
S.min_speed=230
S.reverse_dot=-.38
S.reversals_required=2
S.cooldown=.20
local function finite(v) return type(v)=='number' and v==v and math.abs(v)<math.huge end

local function next_unit(g)
 -- Private local PRNG: shaking a visual die never consumes Farkle RNG.
 g.seed=(g.seed*48271)%2147483647
 return (g.seed/2147483647)*2-1
end

function S.new(index,x,y,time)
 assert(finite(index) and finite(x) and finite(y) and finite(time))
 local seed=(math.floor(math.abs(x)*97)+math.floor(math.abs(y)*193)+
   math.floor(math.abs(time)*1000)*53+index*7919)%2147483646+1
 return {x=x,y=y,time=time,vx=0,vy=0,speed=0,first=0,
  reversals=0,events=0,last_event=-math.huge,strength=0,
  last_spin={0,0,0},seed=seed}
end

-- Returns a fresh rotation impulse only on a confirmed shake event.
function S.sample(g,x,y,time)
 if not g or not(finite(x) and finite(y) and finite(time)) or
    time<=g.time then return nil end
 local dt=time-g.time
 local dx,dy=x-g.x,y-g.y
 g.x,g.y,g.time=x,y,time
 if dt>.24 then
  g.reversals=0;g.vx,g.vy,g.speed=0,0,0
  return nil
 end
 local distance=math.sqrt(dx*dx+dy*dy)
 if distance<S.min_distance then return nil end
 local vx,vy=dx/dt,dy/dt
 local speed=distance/dt
 local previous=g.speed
 local a=previous>0 and
   (vx*g.vx+vy*g.vy)/(speed*previous) or 1
 if speed>=S.min_speed and previous>=S.min_speed and
    a<=S.reverse_dot then
  if g.reversals==0 or time-g.first>S.window then
   g.reversals=1;g.first=time
  else g.reversals=g.reversals+1 end
 elseif g.reversals>0 and time-g.first>S.window then
  g.reversals=0
 end
 g.vx,g.vy,g.speed=vx,vy,speed
 if g.reversals<S.reversals_required or time-g.last_event<S.cooldown then return nil end
 g.reversals=0
 g.last_event=time
 g.events=g.events+1
 g.strength=math.min(1.0,math.max(.4,(speed+previous)/1700))
 -- Independent rotational components; avoids a fixed face/spin outcome.
 local spin={
  next_unit(g)*7*g.strength,
  next_unit(g)*7*g.strength,
  next_unit(g)*5*g.strength
 }
 g.last_spin=spin
 return spin
end

function S.recent(g,time)
 return g and g.events>0 and finite(time) and time-g.last_event<=.70
end
return S
end)()

-- Single-die grip
Parts.single = (function()
-- Physical one-at-a-time mouse handling for Manuscript's existing solver.
-- The held body is real; its vertices rotate while _manual_pending freezes
-- ordinary gravity/collisions. Release restores dynamic physics immediately.
local Shake=Parts.shake
local T={}
local function clamp(x,lo,hi) return math.max(lo,math.min(hi,x)) end
local function finite(x) return type(x)=='number' and x==x and math.abs(x)<math.huge end
local function copy3(v) return {v[1],v[2],v[3]} end

function T.world_motion(dx,dy,view,scale,anchor)
 local zoom=(view.focus or 5)/(view.distance or 14.1)
 local k=math.max(.001,(scale or 1)*zoom)
 local yaw,pitch=view.yaw or 0,view.pitch or .48
 local sx=dx/k
 local sy=dy/(k*math.max(.15,math.cos(pitch)))
 local c,s=math.cos(yaw),math.sin(yaw)
 if view.projection=='perspective' and anchor then
  -- Unproject the displaced screen point onto the anchor's horizontal plane.
  local ax,ay,az=anchor[1],anchor[2],anchor[3]
  local rx,ry=c*ax-s*ay,s*ax+c*ay
  local cp,sp=math.cos(pitch),math.sin(pitch)
  local depth=view.distance-sp*ry-cp*az
  local focal=scale*view.focus
  local u=rx/depth+dx/focal
  local v=(cp*ry-sp*az)/depth+dy/focal
  local newY=(v*(view.distance-cp*az)+sp*az)/math.max(.05,cp+v*sp)
  sx=u*(view.distance-sp*newY-cp*az)-rx
  sy=newY-ry
 end
 return c*sx+s*sy,-s*sx+c*sy
end

function T.begin(index,body,x,y,time)
 if type(index)~='number' or index<1 or index%1~=0 or
    type(body)~='table' or not body.position or
    not (finite(x) and finite(y) and finite(time)) then return nil end
 local original={position=copy3(body.position),velocity=copy3(body.velocity),
  angular=copy3(body.angular),asleep=body.asleep,sleep_timer=body.sleep_timer,
  vertices={}}
 for i,v in ipairs(body) do original.vertices[i]=copy3(v) end
 body._manual_pending=true
 body._grabbed=true
 body.asleep=true
 body.sleep_timer=0
 body.velocity[1],body.velocity[2],body.velocity[3]=0,0,0
 local g={index=index,body=body,x0=x,y0=y,x=x,y=y,t0=time,t=time,
  original=original,samples={{x=x,y=y,t=time}},
  angular={2.0,1.4,.6},shake=Shake.new(index,x,y,time)}
 body.position[3]=math.max(body.position[3],2.1)
 return g
end

-- Update the gesture/swing without teleports. Group handling uses this
-- while guiding several ACTUAL rigid bodies to a compact formation.
function T.track(g,x,y,time)
 if not g or not(finite(x) and finite(y) and finite(time)) then return false end
 local elapsed=time-g.t
 local dx,dy=x-g.x,y-g.y
 g.x,g.y,g.t=x,y,math.max(g.t,time)
 -- A group release may request the SAME pointer sample twice in one frame.
 -- Preserve the last actual flick spin rather than resetting it to idle.
 -- Multi-die grab is driven by one elastic hand target. Ordinary
 -- mouse movement MUST NOT also impose a shared angular velocity on each
 -- die: that made all six visibly roll with the direction of the drag,
 -- drowning out the independent contact/shaker tumble. Single-die
 -- handling retains its existing gesture-driven rotation.
 if not g.group_hold and elapsed>.0001 and
    (math.abs(dx)+math.abs(dy))>.01 then
  local dt=math.max(.001,math.min(.05,elapsed))
  g.angular[1]=clamp(2.0+dy*.050/dt,-13,13)
  g.angular[2]=clamp(1.4+dx*.050/dt,-13,13)
  g.angular[3]=clamp(.6+(dx-dy)*.012/dt,-8,8)
 end
 -- Detect alternating back-and-forth hand motion, NOT one swift throw.
 -- Shake spin affects the REAL held body's next physical orientation.
 -- It is separate from the Farkle RNG and never sets a face value.
 local shake_spin=Shake.sample(g.shake,x,y,g.t)
 if shake_spin then
  for k=1,3 do
   g.angular[k]=clamp(g.angular[k]+shake_spin[k],
     k==3 and -10 or -14,k==3 and 10 or 14)
  end
 end
 local sample=g.samples
 if #sample==0 or g.t>sample[#sample].t+.0001 or
    math.abs(x-sample[#sample].x)+math.abs(y-sample[#sample].y)>.01 then
  sample[#sample+1]={x=x,y=y,t=g.t}
 end
 while #sample>2 and g.t-sample[1].t>.18 do table.remove(sample,1) end
 return true
end

function T.move(g,x,y,time,view,scale,bounds)
 if not T.track(g,x,y,time) then return false end
 local vx,vy=T.world_motion(x-g.x0,y-g.y0,view,scale,g.original.position)
 local b=g.body
 local pad=math.max(.4,(b.radius or .5)*.7)
 local hw=(bounds and bounds.half_x or 9.2)-pad
 local hh=(bounds and bounds.half_y or 3.8)-pad
 b.position[1]=clamp(g.original.position[1]+vx,-hw,hw)
 b.position[2]=clamp(g.original.position[2]+vy,-hh,hh)
 b.position[3]=math.max(2.1,math.min(4.2,g.original.position[3]+1.2))
 return true
end

function T.tick(g,dt)
 if not g or not dt or dt<=0 then return end
 local b=g.body
 if not b._grabbed then return end
 dt=math.min(.05,dt)
 b.velocity[1],b.velocity[2],b.velocity[3]=0,0,0
 b.angular[1],b.angular[2],b.angular[3]=g.angular[1],g.angular[2],g.angular[3]
 b:update(dt) -- physically rotate the true mesh vertices, no translation
 -- After an actual shake the held-group spin must settle promptly
 -- when the player stops. This changes only the group hold; the
 -- established single-die handling is intentionally unchanged.
 local decay=g.group_hold and .92 or .99
 g.angular[1]=g.angular[1]*(decay^ (dt*60))
 g.angular[2]=g.angular[2]*(decay^ (dt*60))
 g.angular[3]=g.angular[3]*(decay^ (dt*60))
end

function T.cancel(g)
 if not g then return end
 local b,old=g.body,g.original
 for j=1,3 do
  b.position[j]=old.position[j]
  b.velocity[j]=old.velocity[j]
  b.angular[j]=old.angular[j]
 end
 for i,v in ipairs(old.vertices) do for j=1,3 do b[i][j]=v[j] end end
 b._grabbed=false
 b._manual_pending=true -- still needs an official physical release
 b.asleep=true
 b.sleep_timer=0
end

function T.release(g,x,y,time,view,scale,bounds)
 if not g then return nil end
 T.move(g,x,y,time,view,scale,bounds)
 local sample=g.samples
 local recent=sample[1]
 for i=1,#sample do
  if g.t-sample[i].t<=.15 then recent=sample[i];break end
 end
 local dt=math.max(.025,g.t-recent.t)
 local dx,dy=T.world_motion(g.x-recent.x,g.y-recent.y,view,scale,g.body.position)
 local vx,vy=clamp(dx/dt,-18,18),clamp(dy/dt,-18,18)
 local b=g.body
 -- A simple release still drops the held die; vigorous swipes impart speed.
 b.velocity[1],b.velocity[2],b.velocity[3]=vx,vy,-3.5-math.min(7,math.sqrt(vx*vx+vy*vy)*.22)
 local recent_shake=Shake.recent(g.shake,g.t)
 local boost=recent_shake and .42 or 0
 b.angular[1]=clamp(g.angular[1]+g.shake.last_spin[1]*boost,-14,14)
 b.angular[2]=clamp(g.angular[2]+g.shake.last_spin[2]*boost,-14,14)
 b.angular[3]=clamp(g.angular[3]+g.shake.last_spin[3]*boost,-10,10)
 b.asleep=false
 b.sleep_timer=0
 b._grabbed=false
 b._manual_pending=false
 return {index=g.index,velocity=copy3(b.velocity),angular=copy3(b.angular),
  shake_events=g.shake.events}
end
return T
end)()

-- Group shaking
Parts.shaker = (function()
-- Held-stage virtual dice shaker, inspired by Tabletop Simulator's cup feel.
-- It is NOT a separate dice solver or a scripted result: confirmed mouse
-- reversals inject momentum into independent real D6 bodies, which rattle
-- against each other and a short-lived, invisible cup around the hand.
-- This module never imports gameplay RNG, creates dice or decides faces.
local Shake=Parts.shake
local Single=Parts.single
local M={}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function radius(member)
 return math.max(.32,member.body.radius or .52)
end

function M.new(x,y,time)
 return {detector=Shake.new(0,x,y,time),energy=0,events=0,
   pending=nil,phase=0}
end

-- Sampling lives in the mouse-event path, NOT love.update: a quick
-- unidirectional flick cannot start the shaker by itself.
function M.sample(s,x,y,time,view,scale)
 if not s then return false end
 local previous=s.detector
 local ox,oy=previous.x,previous.y
 local spin=Shake.sample(previous,x,y,time)
 if not spin then return false end
 local dx,dy=Single.world_motion(x-ox,y-oy,view,scale)
 local length=math.sqrt(dx*dx+dy*dy)
 local nx,ny=1,0
 if length>1e-6 then nx,ny=dx/length,dy/length end
 s.events=s.events+1
 local strength=previous.strength
 s.energy=clamp(math.max(s.energy,.45)+.48*strength,0,1.25)
 s.pending={x=nx,y=ny,strength=strength,number=s.events}
 return true
end

-- Only once per CONFIRMED reversing gesture, transfer hand acceleration
-- into the bodies: directional inertia, per-body swirl, vertical clatter,
-- and different real rotations. Fixed phase offsets just break symmetry.
function M.advance(g,dt)
 local s=g and g.shaker
 if not s then return 0 end
 dt=math.max(0,math.min(dt or 0,.04))
 s.phase=s.phase+dt*16
 s.energy=s.energy*math.exp(-dt*2.9)
 local pulse=s.pending
 local targetRadius=math.min(2.55,1.55+.17*#g.held)
 if pulse then
  -- Cup walls gradually close from the current scattered distribution;
  -- an instantaneous hard radius would teleport distant held bodies.
  local outer=targetRadius
  for _,member in ipairs(g.held) do
   local p=member.body.position
   local dx,dy=p[1]-g.hand.x,p[2]-g.hand.y
   outer=math.max(outer,math.sqrt(dx*dx+dy*dy)+radius(member)*.45+.10)
  end
  s.cup_radius=math.max(s.cup_radius or 0,outer)
  s.pending=nil
  for i,member in ipairs(g.held) do
   local vel=g.hold_velocity[i]
   local angle=i*2.3999632297+pulse.number*1.6180339887
   local weight=clamp(pulse.strength,.4,1)
   vel[1]=clamp(vel[1]-pulse.x*4.8*weight+
    math.cos(angle)*3.0*weight,-12,12)
   vel[2]=clamp(vel[2]-pulse.y*4.8*weight+
    math.sin(angle)*3.0*weight,-12,12)
   vel[3]=clamp(vel[3]+(2.7+1.7*(i%3)/2)*weight,-12,12)
   local rotation=member.angular
   rotation[1]=clamp(rotation[1]+math.sin(angle)*5*weight,-14,14)
   rotation[2]=clamp(rotation[2]+math.cos(angle)*5*weight,-14,14)
   rotation[3]=clamp(rotation[3]+(i%2==0 and 1 or -1)*3.2*weight,-10,10)
  end
 end
 -- Velocity turbulence is active only for the decaying post-shake window.
 -- The existing grip spring/contact solver remains responsible for motion
 -- and real collision separation; this is agitation, not a teleport.
 local energy=s.energy
 if s.cup_radius then
  s.cup_radius=math.max(targetRadius,s.cup_radius-4.6*dt)
 end
 if energy<.015 or dt<=0 then
  if energy<.015 then s.energy=0 end
  return s.energy
 end
 for i,member in ipairs(g.held) do
  local p=member.body.position
  local v=g.hold_velocity[i]
  local dx,dy=p[1]-g.hand.x,p[2]-g.hand.y
  local phase=s.phase+i*2.3999632297
  local swirl=energy*8*dt
  v[1]=clamp(v[1]+(-dy*.65+math.cos(phase))*swirl,-12,12)
  v[2]=clamp(v[2]+(dx*.65+math.sin(phase))*swirl,-12,12)
  v[3]=clamp(v[3]+math.sin(phase*1.25)*energy*13*dt,-12,12)
  -- Single.track updates the ordinary per-die spin at each mouse sample.
  -- Keep the cup's distinct tumble active throughout the energy window,
  -- not only at the instant of a reversing gesture.
  local a=member.angular
  a[1]=clamp(a[1]+math.sin(phase)*energy*32*dt,-14,14)
  a[2]=clamp(a[2]+math.cos(phase*.87)*energy*32*dt,-14,14)
  a[3]=clamp(a[3]+math.sin(phase*1.13)*energy*22*dt,-10,10)
 end
 return energy
end

-- A short-lived invisible cup stops active shaken dice flying away from
-- the hand; no visible mesh is necessary and the free throw has no cup.
-- Call after the ordinary held-stage pair contacts, so we never move
-- bodies that have been released to the real physics solver.
function M.contain(g)
 local s=g and g.shaker
 if not s or s.energy<.06 then return end
 local h=g.hand
 local count=#g.held
 local cupRadius=s.cup_radius or math.min(2.55,1.55+.17*count)
 for i,member in ipairs(g.held) do
  local p=member.body.position
  local v=g.hold_velocity[i]
  local dx,dy=p[1]-h.x,p[2]-h.y
  local d=math.sqrt(dx*dx+dy*dy)
  local limit=math.max(.8,cupRadius-radius(member)*.45)
  if d>limit and d>1e-7 then
   local nx,ny=dx/d,dy/d
   p[1]=h.x+nx*limit
   p[2]=h.y+ny*limit
   local outward=v[1]*nx+v[2]*ny
   if outward>0 then
    v[1]=v[1]-nx*outward*1.25
    v[2]=v[2]-ny*outward*1.25
   end
  end
  local floor=h.z-1.25
  local ceiling=h.z+1.28
  if p[3]<floor then
   p[3]=floor
   if v[3]<0 then v[3]=-v[3]*.35 end
  elseif p[3]>ceiling then
   p[3]=ceiling
   if v[3]>0 then v[3]=-v[3]*.35 end
  end
 end
end

return M
end)()

-- Group grip and release
Parts.group = (function()
-- FPS-inspired physical group grip: six REAL rigid bodies follow a shared
-- hand attractor. While held (_manual_pending), the ordinary solver skips
-- these bodies, so we apply bounded spring dynamics and soft pair contacts
-- in the holding stage. No fixed two-level heap or rigid 3x2 hand formation.
-- On release all bodies re-enter the existing production physics solver.
local Single=Parts.single
local Shaker=Parts.shaker
local G={}
local function clamp(x,a,b)
 if a>b then return (a+b)*.5 end
 return math.max(a,math.min(b,x))
end
local function camera(view)
 return view or {yaw=0,pitch=.48,focus=5,distance=14.1}
end
local function radius(member)
 return math.max(.32,member.body.radius or .52)
end
local function bounds_for(g)
 return g.bounds or {half_x=9.2,half_y=3.8,height=10}
end
local function clamp_body(g,member,p)
 local bounds=bounds_for(g)
 local pad=math.max(.42,radius(member)*.90)
 p[1]=clamp(p[1],-bounds.half_x+pad,bounds.half_x-pad)
 p[2]=clamp(p[2],-bounds.half_y+pad,bounds.half_y-pad)
 p[3]=clamp(p[3],math.max(1.9,radius(member)+.7),
  math.max(2.0,bounds.height-.85-radius(member)))
end

-- Deterministic contact normal when two initially stacked/identical dice
-- have coincident centers. The small skew is a symmetry breaker, NOT RNG.
local function normal(a,b,i,j)
 local dx,dy,dz=b[1]-a[1],b[2]-a[2],b[3]-a[3]
 local d=math.sqrt(dx*dx+dy*dy+dz*dz)
 if d<1e-8 then
  local theta=(i*2.3999632297+j*1.6180339887)
  return math.cos(theta),math.sin(theta),.18,0
 end
 return dx/d,dy/d,dz/d,d
end

-- A measured 3-D separation invariant for tests and diagnostics.
function G.clearance(poses)
 local minimum=math.huge
 for i=1,#poses do for j=i+1,#poses do
  local a,b=poses[i],poses[j]
  local ax,ay,az=a.x or a[1],a.y or a[2],a.z or a[3] or 0
  local bx,by,bz=b.x or b[1],b.y or b[2],b.z or b[3] or 0
  local dx,dy,dz=ax-bx,ay-by,az-bz
  minimum=math.min(minimum,math.sqrt(dx*dx+dy*dy+dz*dz))
 end end
 return minimum
end

-- Physical bodies follow one attractor with damped springs (similar to
-- FPS Lab 4) and receive pairwise contact impulses in the held phase
-- (compatible with the Lab 5 clearance experiment). The contacts below
-- are temporary and do NOT replace the production flight solver.
function G.step(g,dt)
 if not g or not g.group or not dt or dt<=0 then return false end
 dt=math.min(dt,.04)
 local hand=g.hand
 if not hand then return false end
 local n=#g.held
 local vel=g.hold_velocity
 -- A certified alternating mouse gesture supplies temporary inertia.
 -- A plain drag keeps the original quiet elastic-grip behavior.
 Shaker.advance(g,dt)
 local start={}
 for i,member in ipairs(g.held) do
  local p=member.body.position
  start[i]={p[1],p[2],p[3]}
  local v=vel[i]
  local natural=hand.z+(i%2==0 and .04 or -.04)
  local targets={hand.x,hand.y,natural}
  local k=38
  local damping=math.exp(-10*dt)
  for axis=1,3 do
   v[axis]=(v[axis]+(targets[axis]-p[axis])*k*dt)*damping
   v[axis]=clamp(v[axis],-12,12)
   p[axis]=p[axis]+v[axis]*dt
  end
  clamp_body(g,member,p)
 end
 -- During a held group the production box skips collision pairs. Solve
 -- contact depth in short bounded iterations so the spring cannot collapse
 -- six D6 into a single point (or force them apart at release).
 for iteration=1,5 do
  for i=1,n do for j=i+1,n do
   local a,b=g.held[i].body.position,g.held[j].body.position
   local nx,ny,nz,d=normal(a,b,i,j)
   local minDist=radius(g.held[i])+radius(g.held[j])+.08
   local depth=minDist-d
   if depth>0 then
    local correction=math.min(depth*.55,.34)
    a[1]=a[1]-nx*correction
    a[2]=a[2]-ny*correction
    a[3]=a[3]-nz*correction
    b[1]=b[1]+nx*correction
    b[2]=b[2]+ny*correction
    b[3]=b[3]+nz*correction
    clamp_body(g,g.held[i],a)
    clamp_body(g,g.held[j],b)
   end
  end end
 end
 -- The virtual cup only constrains the active shake phase; actual
 -- flight, regular group holding and all game rules remain unchanged.
 Shaker.contain(g)
 -- The virtual cup can approach the real tray walls. Apply the same
 -- physical bounds after confinement, without altering normal flight.
 for _,member in ipairs(g.held) do
  clamp_body(g,member,member.body.position)
 end
 -- Preserve soft contact response as part of the moving grip; without it
 -- velocities would keep pushing toward the overlapping hand center.
 for i,member in ipairs(g.held) do
  local p=member.body.position
  local v=vel[i]
  for axis=1,3 do
   local displacement=p[axis]-start[i][axis]
   v[axis]=clamp(.62*v[axis]+.38*displacement/dt,-12,12)
  end
  Single.tick(member,dt) -- rotate the actual die mesh in the hand
 end
 return true
end

-- Anchor comes from the picked die and the actual hit point; no random
-- starting formation and no instantaneous relocation of the six bodies.
function G.begin(indices,dice,x,y,time,view,scale,bounds,anchor_index,hit_x,hit_y)
 if type(indices)~='table' or #indices<2 or type(dice)~='table' then return nil end
 local held={}
 for _,index in ipairs(indices) do
  local entry=dice[index]
  if not entry or not entry.body or entry.kept or entry.body._grabbed or
     not entry.body._manual_pending then
   for _,member in ipairs(held) do Single.cancel(member) end
   return nil
  end
  local member=Single.begin(index,entry.body,x,y,time)
  if not member then
   for _,g in ipairs(held) do Single.cancel(g) end
   return nil
  end
  -- The same Single.track samples position and shake on each die,
  -- but group mouse dragging must not impose the single-die pointer-spin
  -- formula. Actual group rotation now comes only from shake impulses
  -- (or body contacts upon release). Begin the quiet hold without spin.
  member.group_hold=true
  member.angular={0,0,0}
  for axis=1,3 do member.body.angular[axis]=0 end
  held[#held+1]=member
 end
 local picked=dice[anchor_index or indices[1]] or dice[indices[1]]
 local ax,ay=picked.body.position[1],picked.body.position[2]
 if hit_x and hit_y then
  local wx,wy=Single.world_motion(x-hit_x,y-hit_y,camera(view),scale,picked.body.position)
  ax,ay=ax+wx,ay+wy
 end
 local hold_velocity={}
 for i=1,#held do hold_velocity[i]={0,0,0} end
 local g={group=true,index=indices[1],indices=indices,held=held,
  x0=x,y0=y,x=x,y=y,anchor_x=ax,anchor_y=ay,
  hold_velocity=hold_velocity,hand=nil,bounds=bounds,
  shaker=Shaker.new(x,y,time)}
 G.move(g,x,y,time,view,scale,bounds)
 return g
end

function G.move(g,x,y,time,view,scale,bounds)
 if not g or not g.group then return false end
 local dx,dy=Single.world_motion(x-g.x0,y-g.y0,camera(view),scale,{g.anchor_x,g.anchor_y,3.7})
 local cx,cy=g.anchor_x+dx,g.anchor_y+dy
 local limit=bounds or bounds_for(g)
 g.bounds=limit
 local maxR=.52
 for _,member in ipairs(g.held) do maxR=math.max(maxR,radius(member)) end
 -- Keep the hand itself within the physical board, and use per-body
 -- clamping/contact resolution rather than packing a hard formation.
 local inset=math.max(.8,maxR+1)
 cx=clamp(cx,-limit.half_x+inset,limit.half_x-inset)
 cy=clamp(cy,-limit.half_y+inset,limit.half_y-inset)
 local top=math.max(2.5,limit.height-.85-maxR)
 g.hand={x=cx,y=cy,z=math.min(top,3.7)}
 for _,member in ipairs(g.held) do
  if not Single.track(member,x,y,time) then return false end
 end
 Shaker.sample(g.shaker,x,y,time,camera(view),scale)
 g.x,g.y=x,y
 return true
end

function G.tick(g,dt)
 return G.step(g,dt)
end

function G.cancel(g)
 if not g or not g.group then return end
 for _,member in ipairs(g.held) do Single.cancel(member) end
end

function G.release(g,x,y,time,view,scale,bounds)
 if not g or not g.group then return nil end
 if not G.move(g,x,y,time,view,scale,bounds) then return nil end
 local results={}
 for i,member in ipairs(g.held) do
  local b=member.body
  -- The individual release helper updates momentum/spin and restores
  -- dynamic collision integration, but it also moves to the *single-die*
  -- pointer location. Restore the real spring/contact pose after calling.
  local original={b.position[1],b.position[2],b.position[3]}
  local result=Single.release(member,x,y,time,camera(view),scale,bounds)
  if not result then return nil end
  for axis=1,3 do b.position[axis]=original[axis] end
  -- Some of the cup's relative motion survives a release while the
  -- ordinary solver takes over. Preserve an explicit downward impulse.
  local energy=g.shaker and g.shaker.energy or 0
  if energy>.08 then
   for axis=1,2 do
    b.velocity[axis]=clamp(b.velocity[axis]+
      g.hold_velocity[i][axis]*energy*.28,-18,18)
   end
   b.velocity[3]=math.min(-1,
     b.velocity[3]+g.hold_velocity[i][3]*energy*.16)
   result.velocity={b.velocity[1],b.velocity[2],b.velocity[3]}
  end
  results[#results+1]=result
 end
 return results
end

return G
end)()

-- Physical selection
Parts.selection = (function()
-- Rectangle selection in screen coordinates. Separate from Farkle score selection.
-- Only hits whose centers lie inside the actual dragged rectangle are selected.
local M={}
local function finite(v)
 return type(v)=='number' and v==v and v~=math.huge and v~=-math.huge
end
local THRESHOLD=9
function M.begin(x,y)
 if not(finite(x) and finite(y)) then return nil end
 return {x0=x,y0=y,x=x,y=y}
end
function M.move(d,x,y)
 if not d or not(finite(x) and finite(y)) then return false end
 d.x,d.y=x,y
 return true
end
function M.rectangle(d)
 if not d then return nil end
 return {x=math.min(d.x0,d.x),y=math.min(d.y0,d.y),
   w=math.abs(d.x-d.x0),h=math.abs(d.y-d.y0)}
end
function M.dragged(d)
 local r=M.rectangle(d)
 return r and (r.w*r.w+r.h*r.h >= THRESHOLD*THRESHOLD) or false
end
function M.choose(d,hits,allowed)
 local r=M.rectangle(d)
 local selected={}
 if not r or not M.dragged(d) then return selected end
 for _,hit in ipairs(hits or {}) do
  local index=hit.index or hit.roll_index
  if type(index)=='number' and index%1==0 and index>=1 and
    finite(hit.x) and finite(hit.y) and
    hit.x>=r.x and hit.x<=r.x+r.w and
    hit.y>=r.y and hit.y<=r.y+r.h and
    (not allowed or allowed(index)) then
   selected[index]=true
  end
 end
 return selected
end
function M.count(indices)
 local n=0
 for _,value in pairs(indices or {}) do if value then n=n+1 end end
 return n
end
return M
end)()

return Parts
