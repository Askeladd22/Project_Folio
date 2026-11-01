-- FPS-inspired physical group grip: six REAL rigid bodies follow a shared
-- hand attractor. While held (_manual_pending), the ordinary solver skips
-- these bodies, so we apply bounded spring dynamics and soft pair contacts
-- in the holding stage. No fixed two-level heap or rigid 3x2 hand formation.
-- On release all bodies re-enter the existing production physics solver.
local Single=require('src.features.farkle.mouse_throw')
local Shaker=require('src.features.farkle.group_shaker')
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
  local wx,wy=Single.world_motion(x-hit_x,y-hit_y,camera(view),scale)
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
 local dx,dy=Single.world_motion(x-g.x0,y-g.y0,camera(view),scale)
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
