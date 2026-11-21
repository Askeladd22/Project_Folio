-- Pressure test: six real physical D6, no mocked contacts/poses.
-- Protect the kept-row geometry and prevent decorative "teleports"
-- when a later Farkle take updates the entire scored mask.
require('lib.core')
love={graphics={newImage=function() end}}
local Physics=require('src.engine3d.physics')
local Geometry=require('src.engine3d.geometry')
local Collision=require('src.engine3d.die_collision')
local D=require('src.farkle.dice')
local function die(x,y,z,vx,vy)
 return Geometry.newD6Body(.8):set({x,y,z},{vx or 0,vy or 0,0},{0,0,0})
end
local function world()
 local w=clone(Physics.box,{timeleft=0,simulated_time=0,log_buffer={}}):
   set(100,100,100,0,.3,.6,.01)
 w.linear_damping=0;w.angular_damping=0;w.sleep_time=1e6
 return w
end
local function max_penetration(bodies)
 local depth=0
 for i=1,#bodies-1 do for j=i+1,#bodies do
  local hit=Collision.overlap(bodies[i],bodies[j])
  if hit then depth=math.max(depth,hit.depth) end
 end end
 return depth
end
local function close(a,b,tol) return math.abs(a-b)<(tol or 1e-8) end

-- Six nearly superimposed, resting dice must converge without a
-- phantom activation or endless movement as fixed ticks progress.
local function pile()
 local w=world()
 for i=1,6 do
  local col=(i-1)%3
  local row=math.floor((i-1)/3)
  local b=die((col-1)*.66,(row-.5)*.66,.5)
  b.asleep=true
  w[i]=b
 end
 assert(max_penetration(w)>.1,'fixture must contain a real six-cube pile')
 for step=1,80 do w:update(.01) end
 assert(max_penetration(w)<.02,
  ('six resting D6 remain deeply penetrated: %.5f'):format(max_penetration(w)))
 for i=1,6 do
  assert(w[i].asleep and close(w[i].velocity:abs(),0),
   'resting pile correction must not keep D6 awake')
 end
 return w
end
local first,second=pile(),pile()
for i=1,6 do for axis=1,3 do
 assert(close(first[i].position[axis],second[i].position[axis]),
  'physical pile corrections must be deterministic')
end end

-- Occupied target -> fallback; a later scoring action frees that target.
-- The first die must not teleport again just because its old slot is free.
do
 local entries={}
 for i=1,6 do entries[i]={body=die((i-3.5)*1.3,2,.5)} end
 local target=(1-3.5)*2
 entries[6].body.position[1]=target
 entries[6].body.position[2]=-4.45
 D.stage_kept(entries,{[1]=true})
 local b=entries[1].body
 local parked={b.position[1],b.position[2],b.position[3]}
 assert(parked[1]~=target and b._kept_solid,
  'first scored cube should use a vacant fallback slot')
 -- Clear the preferred slot without touching the already scored cube.
 entries[6].body.position[1]=8
 entries[6].body.position[2]=2
 D.stage_kept(entries,{[1]=true,[2]=true,[3]=true,[4]=true,[5]=true})
 for axis=1,3 do
  assert(close(b.position[axis],parked[axis]),
   'scoring another die moved a previously parked physical D6')
 end
 local bodies={}
 for i=1,6 do bodies[i]=entries[i].body end
 assert(max_penetration(bodies)<1e-6,
  'multiple kept dice intersect after serial scoring')
 local poses={}
 for i=1,6 do poses[i]={bodies[i].position[1],bodies[i].position[2]} end
 D.stage_kept(entries,{[1]=true,[2]=true,[3]=true,[4]=true,[5]=true})
 for i=1,6 do
  assert(close(bodies[i].position[1],poses[i][1])
    and close(bodies[i].position[2],poses[i][2]),
    'restaging an identical scored mask must be idempotent')
 end
end

-- Three parked obstacles versus three physical throws toward the rear.
-- Parked dice must neither drift nor generate a stuck pair.
do
 local entries={}
 for i=1,6 do
  entries[i]={body=die((i-2)*2.0,-1.8,.5)}
 end
 D.stage_kept(entries,{[1]=true,[2]=true,[3]=true})
 local w=world()
 local parked={}
 for i=1,6 do
  w[i]=entries[i].body
  if i<=3 then parked[i]={w[i].position[1],w[i].position[2],w[i].position[3]}
  else
   w[i].position[1]=w[i-3].position[1]
   w[i].position[2]=-2.7
   w[i].velocity[2]=-25
  end
 end
 local pair_contacts=0
 w.on_contact=function(_,kind)if kind=='pair' then pair_contacts=pair_contacts+1 end end
 for step=1,50 do w:update(.01) end
 assert(pair_contacts>0,'active D6 did not collide with any scored solid')
 for i=1,3 do
  for axis=1,3 do
   assert(close(w[i].position[axis],parked[i][axis]),
    'impact moved a scored D6')
  end
  assert(w[i]._kept_solid and w[i]._manual_pending,
   'scored D6 re-entered the rolling hand')
 end
 assert(max_penetration(w)<.025,
  ('parked/moving D6 collision left overlap %.5f'):format(max_penetration(w)))
end
print('PASS six-D6 resting pressure, stable serial keeps and physical impacts')
