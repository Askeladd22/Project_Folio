-- EX-FPS-FIX: deterministic acceptance tests for real production D6 bodies.
-- No native FPS claim. OBB SAT, CCD and angular contact-point response.
require('lib.core')
love={graphics={newImage=function()end}}
local Physics=require('src.engine3d.physics')
local Geometry=require('src.engine3d.geometry')
local Collision=require('src.engine3d.die_collision')
local count=0
local function check(name,fn)
 fn();count=count+1
 print('PASS D6 collision '..name)
end
local function world()
 local w=clone(Physics.box,{timeleft=0,log_buffer={},simulated_time=0}):
   set(100,100,100,0,.3,.6,.01)
 w.linear_damping=0
 w.angular_damping=0
 w.sleep_linear=0
 w.sleep_angular=0
 w.sleep_time=1e5
 return w
end
local function die(x,y,z,vx,vy,vz,ax,ay,az)
 return Geometry.newD6Body(.8):set({x,y,z},
   {vx or 0,vy or 0,vz or 0},{ax or 0,ay or 0,az or 0})
end
local function mag(v) return math.sqrt(v[1]^2+v[2]^2+v[3]^2) end

check('no false sphere contact for visibly separated aligned cubes',function()
 local w=world()
 local a,b=die(0,0,3),die(1.2,0,3)
 assert(a.radius+b.radius>1.2,'historical sphere false-positive is absent')
 w[1],w[2]=a,b
 assert(Collision.overlap(a,b)==nil)
 local p1,p2=a.position[1],b.position[1]
 w:update(.01)
 assert(math.abs(a.position[1]-p1)<1e-9 and
   math.abs(b.position[1]-p2)<1e-9,
   'SAT must not displace separate cubes')
end)

check('actual overlapping cubes separate without phantom pair sounds',function()
 local w=world()
 local a,b=die(0,0,3),die(.83,0,3)
 w[1],w[2]=a,b
 assert(Collision.overlap(a,b))
 local before=b.position[1]-a.position[1]
 w:update(.01)
 assert(b.position[1]-a.position[1]>before+.01,
   'real overlap must be resolved using cube face separation')
end)

check('continuous collision catches swapped-endpoint fast crossing',function()
 local w=world()
 local a,b=die(-1.5,0,3,250,0,0),die(1.5,0,3,-250,0,0)
 w[1],w[2]=a,b
 local events=0
 w.on_contact=function(_,kind,aa,bb,speed)
  assert(kind=='pair' and aa==1 and bb==2 and speed>0)
  events=events+1
 end
 w:update(.01)
 assert(events>=1,'missing swept contact with no final overlap')
 assert(a.position[1]<b.position[1],
   'bodies must not swap positions by tunnelling')
 assert(b.velocity[1]-a.velocity[1]>=-1e-8,
   'CCD safety must remove residual closing center velocity')
 assert(w.ccd_safety_stops and w.ccd_safety_stops>=1,
   'high-speed cap fallback must be exercised and observable')
end)

check('off-centre face collision imparts angular velocity',function()
 local w=world()
 local a,b=die(0,0,3,5,0,0),die(.85,.25,3,0,0,0)
 w[1],w[2]=a,b
 local events=0
 w.on_contact=function(_,kind)if kind=='pair' then events=events+1 end end
 w:update(.01)
 assert(events>0,'no physical pair impact')
 assert(mag(a.angular)+mag(b.angular)>1e-5,
   'contact point offsets must create torque on both D6')
end)

check('staged/held dice stay kinematic and non-impulsive',function()
 local w=world()
 local a,b=die(0,0,3,0,0,0),die(.83,0,3,3,0,0)
 a._manual_pending=true
 a.asleep=true
 w[1],w[2]=a,b
 local x=a.position[1]
 for i=1,5 do w:update(.01) end
 assert(math.abs(a.position[1]-x)<1e-9,
   'pending physical cube must not be displaced')
end)

check('same initial state, same deterministic trajectory',function()
 local function simulate()
  local w=world()
  w[1]=die(-.7,0,3,5,.1,0,0,1,.5)
  w[2]=die(.7,.2,3,-5,0,0,.2,0,1)
  for step=1,40 do w:update(.01) end
  return w
 end
 local a,b=simulate(),simulate()
 for i=1,2 do
  for k=1,3 do
   assert(math.abs(a[i].position[k]-b[i].position[k])<1e-9)
   assert(math.abs(a[i].velocity[k]-b[i].velocity[k])<1e-9)
   assert(math.abs(a[i].angular[k]-b[i].angular[k])<1e-9)
  end
 end
end)
print('PASS D6 collision acceptance '..count..'/6')
