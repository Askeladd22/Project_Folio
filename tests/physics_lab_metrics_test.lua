local F=require('experiments.physics_lab.fixtures')
local M=require('experiments.physics_lab.metrics')
local a=F.generate(1337)
local b=F.generate(1337)
local c=F.generate(1338)
assert(#a==6 and #b==6)
for i=1,6 do
 for _,p in ipairs{'position','velocity','angular'} do
  for k=1,3 do
   assert(a[i][p][k]==b[i][p][k],'identical seed must produce identical inputs')
   assert(a[i][p][k]==a[i][p][k],'input values must be finite')
  end
 end
end
assert(a[1].velocity[1]~=c[1].velocity[1],'different seeds should vary inputs')
local corners={{1,1,1},{1,-1,1},{-1,-1,1},{-1,1,1},
               {1,1,-1},{1,-1,-1},{-1,-1,-1},{-1,1,-1}}
local function cube(x,y,z)
 local verts={}
 for i,v in ipairs(corners) do verts[i]={v[1]+x,v[2]+y,v[3]+z} end
 return {position={x,y,z},vertices=verts,asleep=false}
end
local boxA,boxB=cube(0,0,1),cube(1.6,0,1)
assert(math.abs(M.overlap(boxA,boxB)-.4)<1e-7,'SAT must report cube penetration depth')
assert(M.overlap(boxA,cube(2.1,0,1))==0,'SAT must reject separate cubes')
assert(M.overlap(boxA,cube(0,2.1,1))==0)
assert(M.overlap(boxA,cube(0,0,3.1))==0)
assert(math.abs(M.floor_height(boxA))<1e-9)
local v,up,gap=M.top_value(boxA)
assert(v==1 and up>.999 and gap>.8,'upright D6 should show face 1')
local st=M.new()
M.observe(st,{boxA,boxB},.1,9.2,3.8)
assert(st.overlap_events==1 and st.max_overlap>.39)
assert(st.settle_s==nil)
boxA.asleep=true;boxB.asleep=true
M.observe(st,{boxA,boxB},.2,9.2,3.8)
assert(st.settle_s==.2)
M.finish(st,{boxA,boxB})
assert(st.faces[1]==2 and st.invalid_faces==0)
local flying=cube(0,0,5);flying.asleep=true
M.observe(st,{flying},.3,9.2,3.8)
assert(st.airborne_sleep_events==1,'airborne sleep metric must detect bad solver state')
print('PASS Physics Lab 1: seeded fixtures, independent SAT, face-up and airborne-sleep diagnostics')
