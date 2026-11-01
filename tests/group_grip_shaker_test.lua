-- Shaking a held group should feel like dice rattling in a cup, driven
-- by real mouse reversals; Farkle RNG, die count and scoring stay untouched.
-- No LÖVE graphics, native FPS library or game rules are imported here.
local G=require('src.features.farkle.group_throw')
local view={yaw=0,pitch=.48,focus=5,distance=14.1}
local bounds={half_x=9.2,half_y=3.8,height=10}
local function build()
 local dice,indices={},{}
 for i=1,6 do
  local b={position={(i-3.5)*1.05,(i%2==0) and .8 or -.8,1},
    velocity={0,0,0},angular={0,0,0},radius=.52,
    asleep=true,sleep_timer=0,_manual_pending=true,
    {1,1,1},{-1,-1,-1}}
  function b:update(dt)
   for _,v in ipairs(self) do v[1]=v[1]+self.angular[2]*dt end
  end
  dice[i]={body=b,kept=false}
  indices[i]=i
 end
 return dice,indices
end
local function start()
 local dice,indices=build()
 local grip=assert(G.begin(indices,dice,200,200,0,view,25,bounds,3,200,200))
 return dice,grip
end
local function measure(g)
 local min=math.huge
 local spread,zrange=0,0
 local minz,maxz=math.huge,-math.huge
 local momentum=0
 for i,a in ipairs(g.held) do
  local p=a.body.position
  assert(p[1]==p[1] and p[2]==p[2] and p[3]==p[3])
  assert(p[1]>=-bounds.half_x and p[1]<=bounds.half_x and
   p[2]>=-bounds.half_y and p[2]<=bounds.half_y and
   p[3]>=1.9 and p[3]<=bounds.height,
   'shaker must keep real rigid bodies in a bounded tray')
  minz,maxz=math.min(minz,p[3]),math.max(maxz,p[3])
  for j=i+1,#g.held do
   local b=g.held[j].body.position
   local d=math.sqrt((p[1]-b[1])^2+(p[2]-b[2])^2+(p[3]-b[3])^2)
   min=math.min(min,d)
  end
  local v=g.hold_velocity[i]
  momentum=momentum+math.abs(v[1])+math.abs(v[2])+math.abs(v[3])
  spread=spread+math.sqrt((p[1]-g.hand.x)^2+(p[2]-g.hand.y)^2)
 end
 return min,momentum,minz,maxz,spread
end

local _,quiet=start()
G.move(quiet,260,200,.1,view,25,bounds)
for _=1,24 do G.tick(quiet,.02) end
assert(quiet.shaker.events==0 and quiet.shaker.energy==0,
 'a one-direction flick must not activate cup physics')
local _,jitter=start()
for i=1,16 do
 G.move(jitter,200+(i%2==0 and 3 or -3),200,i*.04,view,25,bounds)
 G.tick(jitter,.02)
end
assert(jitter.shaker.events==0 and jitter.shaker.energy==0,
 'tiny mouse jitter must never start the shaking cup')
local _,slow=start()
G.move(slow,255,200,.4,view,25,bounds)
G.move(slow,200,200,.8,view,25,bounds)
G.move(slow,255,200,1.2,view,25,bounds)
assert(slow.shaker.events==0,'slow changes of hand direction must not shake')

local dice,g=start()
for i,x in ipairs{260,200,260,200,260,200,260} do
 G.move(g,x,200,i*.095,view,25,bounds)
 G.tick(g,.018)
end
assert(g.shaker.events>=2 and g.shaker.energy>.2,
 'fast alternating hand motions must activate and sustain the cup')
local first=g.shaker.events
local active=g.shaker.energy
local firstMin,firstMomentum,minz,maxz=measure(g)
assert(firstMomentum>2,'the cup must inject real per-die velocity, not only a screen effect')
assert(maxz-minz>.03,'shaking should create visible vertical clatter')
assert(firstMin>.12,'dice cannot all collapse into the same contact center')
local angles={}
for i,member in ipairs(g.held) do
 local a=member.angular
 angles[i]=a[1]+a[2]+a[3]
end
assert(angles[1]~=angles[2],
 'dice need different real angular impulses, not one fake shared spin')
for step=1,75 do
 G.tick(g,.02)
 local mind=measure(g)
 assert(mind>.10,'contact solver must remain stable during rattling')
end
assert(g.shaker.energy<active*.05 and g.shaker.events==first,
 'the rattling must fade when mouse movement stops')
local before={}
for i,member in ipairs(g.held) do
 local p=member.body.position
 before[i]={p[1],p[2],p[3]}
end
local released=assert(G.release(g,260,200,2.1,view,25,bounds))
assert(#released==6)
for i,member in ipairs(g.held) do
 local b=member.body
 assert(not b._manual_pending and not b._grabbed and not b.asleep)
 for axis=1,3 do
  assert(math.abs(b.position[axis]-before[i][axis])<1e-8,
   'the physical release must not teleport any shaken die')
 end
 assert(released[i].index==i and released[i].velocity[3]<0)
end

-- Fresh shake, immediate physical release: relative hand momentum must be
-- represented in the returned solver velocities, without a synthetic roll.
local _,hot=start()
for i,x in ipairs{260,200,260} do
 G.move(hot,x,220,i*.09,view,25,bounds)
 G.tick(hot,.02)
end
assert(hot.shaker.events==1)
local raw={}
for i,m in ipairs(hot.held) do
 raw[i]={m.body.position[1],m.body.position[2],m.body.position[3]}
end
local impulses=assert(G.release(hot,260,220,.32,view,25,bounds))
assert(#impulses==6)
for i,m in ipairs(hot.held) do
 for axis=1,3 do
  assert(math.abs(m.body.position[axis]-raw[i][axis])<1e-8)
 end
 assert(m.body.velocity[3]<0)
end
local unique=false
for i=2,6 do
 if math.abs(impulses[i].velocity[1]-impulses[1].velocity[1])>.01 or
    math.abs(impulses[i].velocity[2]-impulses[1].velocity[2])>.01 then
  unique=true
 end
end
assert(unique,'shaken dice should not all inherit one identical fling velocity')
print('PASS shaker cup: real mouse reversals, per-body tumble, bounded contacts, energy fade and exact-pose release')
