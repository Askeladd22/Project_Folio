-- FPS-like single-attractor group-grip regression with mocked genuine
-- body vertices; no renderer and no native physics_lab dependency.
local G=require('src.features.farkle.group_throw')
local view={yaw=0,pitch=.48,focus=5,distance=14.1}
local bounds={half_x=9.2,half_y=3.8,height=10}
local function build(n,coincident)
 local dice,ids={},{}
 for i=1,n do
  local x=coincident and 0 or (i-(n+1)*.5)*1.3
  local y=coincident and 0 or ((i%2==0) and .85 or -.85)
  local b={position={x,y,1.1},velocity={0,0,0},
   angular={0,0,0},radius=.52,asleep=true,sleep_timer=0,
   _manual_pending=true,{1,1,1},{-1,-1,-1}}
  function b:update(dt)
   for _,v in ipairs(self) do v[1]=v[1]+self.angular[2]*dt end
  end
  dice[i]={body=b,kept=false}
  ids[i]=i
 end
 return dice,ids
end
local function positions(g)
 local out={}
 for i,member in ipairs(g.held) do
  local p=member.body.position
  out[i]={x=p[1],y=p[2],z=p[3]}
 end
 return out
end
for n=2,6 do
 local dice,indices=build(n,false)
 local orig={}
 for i=1,n do local p=dice[i].body.position
  orig[i]={p[1],p[2],p[3]} end
 local g=assert(G.begin(indices,dice,100,200,1,view,25,bounds,1,100,200))
 assert(g.group and #g.held==n and g.hand and #g.hold_velocity==n)
 local first=0
 for _,member in ipairs(g.held) do
  local p=member.body.position
  first=first+math.sqrt((p[1]-g.hand.x)^2+(p[2]-g.hand.y)^2)
 end
 for step=1,110 do assert(G.tick(g,.02)) end
 local last=0
 for _,member in ipairs(g.held) do
  local p=member.body.position
  last=last+math.sqrt((p[1]-g.hand.x)^2+(p[2]-g.hand.y)^2)
  assert(p[1]>-9.2 and p[1]<9.2 and
   p[2]>-3.8 and p[2]<3.8 and p[3]>1.9,
   'held body must remain within physical bounds')
 end
 assert(last<n*3.2 and last<first+2,
  'FPS-like spring must gather dice around the hand')
 assert(G.clearance(positions(g))>.4,
  'held-stage contacts must separate bodies in actual coordinates')

 -- The hand can move without teleporting bodies into a hardcoded pattern.
 local prior=positions(g)
 assert(G.move(g,135,215,3.3,view,25,bounds))
 for k=1,12 do assert(G.tick(g,.02)) end
 local moved=positions(g)
 assert(moved[1].x~=prior[1].x,
  'held bodies must follow the moving attractor')
 local beforeRelease=positions(g)
 local releases=assert(G.release(g,135,215,3.8,view,25,bounds))
 assert(#releases==n and G.clearance(positions(g))>.4)
 for i,member in ipairs(g.held) do
  local b=member.body
  assert(not b._manual_pending and not b._grabbed and not b.asleep,
   'release must restore the original production physics flags')
  assert(math.abs(b.position[1]-beforeRelease[i].x)<1e-8 and
   math.abs(b.position[2]-beforeRelease[i].y)<1e-8 and
   math.abs(b.position[3]-beforeRelease[i].z)<1e-8,
   'FPS-like release must use each actual body pose, not snap to a grid')
 end

 local another,ids=build(n,false)
 local c=assert(G.begin(ids,another,100,200,1,view,25,bounds,1,100,200))
 for k=1,15 do G.tick(c,.02) end
 G.cancel(c)
 for i=1,n do
  local p=another[i].body.position
  assert(p[1]==orig[i][1] and p[2]==orig[i][2] and p[3]==orig[i][3],
   'cancel must restore the original unthrown six physical dice')
  assert(another[i].body._manual_pending and not another[i].body._grabbed)
 end
end

-- Identical starting positions used to expose a divide-by-zero and locked
-- bodies in a common hand point. The contact normal must be deterministic.
local dice,indices=build(6,true)
local g=assert(G.begin(indices,dice,0,0,1,view,25,bounds,1,0,0))
for k=1,90 do G.tick(g,.02) end
assert(G.clearance(positions(g))>.3,
 'even coincident die centers must separate before the next physical release')
print('PASS FPS-like group grip: shared spring attractor, real held contacts, boundary and exact-pose release, cancellation, coincident centers')
