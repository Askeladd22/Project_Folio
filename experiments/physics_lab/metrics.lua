-- Read-only SAT metric independent of both physics solvers.
-- Inputs are {position={x,y,z}, vertices={{x,y,z}, ...}, asleep=boolean}.
local M={}
local faces={{1,2,3,4},{5,6,7,8},{1,2,6,5},{2,3,7,6},{3,4,8,7},{4,1,5,8}}
local values={1,6,3,5,4,2}
local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
local function sub(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
local function cross(a,b)
 return {a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]}
end
local function mag(a) return math.sqrt(dot(a,a)) end
local function axis(a,b) local d=sub(a,b);local m=mag(d);return m>1e-9 and {d[1]/m,d[2]/m,d[3]/m} or nil end
local function cube_axes(v)
 return {axis(v[2],v[1]),axis(v[4],v[1]),axis(v[5],v[1])}
end
function M.overlap(a,b)
 local aa,bb=cube_axes(a.vertices),cube_axes(b.vertices)
 local axes={}
 for i=1,3 do axes[#axes+1]=aa[i];axes[#axes+1]=bb[i] end
 for i=1,3 do for j=1,3 do
  local p=cross(aa[i],bb[j]);local length=mag(p)
  if length>1e-7 then axes[#axes+1]={p[1]/length,p[2]/length,p[3]/length} end
 end end
 local smallest=math.huge
 for _,n in ipairs(axes) do
  local loA,hiA,loB,hiB=math.huge,-math.huge,math.huge,-math.huge
  for _,v in ipairs(a.vertices) do
   local p=dot(v,n);loA=math.min(loA,p);hiA=math.max(hiA,p)
  end
  for _,v in ipairs(b.vertices) do
   local p=dot(v,n);loB=math.min(loB,p);hiB=math.max(hiB,p)
  end
  local overlap=math.min(hiA,hiB)-math.max(loA,loB)
  if overlap<=0 then return 0 end
  smallest=math.min(smallest,overlap)
 end
 return smallest
end
function M.floor_height(a)
 local z=math.huge
 for _,v in ipairs(a.vertices) do z=math.min(z,v[3]) end
 return z
end
function M.top_value(a)
 local top,second=-math.huge,-math.huge
 local best=0
 for i,face in ipairs(faces) do
  local z=0
  local sx,sy=0,0
  for _,idx in ipairs(face) do
   local v=a.vertices[idx]
   z=z+v[3]/4;sx=sx+v[1]/4;sy=sy+v[2]/4
  end
  if z>top then second=top;top=z;best=i
  elseif z>second then second=z end
 end
 local top_v=a.vertices[faces[best][1]]
 local center={0,0,0}
 for _,v in ipairs(a.vertices) do
  for k=1,3 do center[k]=center[k]+v[k]/8 end
 end
 local face_center={0,0,0}
 for _,idx in ipairs(faces[best]) do
  local v=a.vertices[idx]
  for k=1,3 do face_center[k]=face_center[k]+v[k]/4 end
 end
 local radial=sub(face_center,center)
 local cosine=radial[3]/math.max(mag(radial),1e-9)
 local gap=(top-second)/math.max(mag(radial),1e-9)
 return values[best],cosine,gap
end
function M.new()
 return {samples=0,overlap_events=0,max_overlap=0,
         airborne_sleep_events=0,floor_penetration_events=0,
         max_floor_penetration=0,unsettled=0,invalid_faces=0,
         faces={0,0,0,0,0,0},settle_s=nil}
end
function M.observe(result,bodies,time,half_x,half_y)
 result.samples=result.samples+1
 local all_sleep=true
 for i,a in ipairs(bodies) do
  local floor=M.floor_height(a)
  if floor<-.002 then
   result.floor_penetration_events=result.floor_penetration_events+1
   result.max_floor_penetration=math.max(result.max_floor_penetration,-floor)
  end
  if a.asleep and floor>.08 then result.airborne_sleep_events=result.airborne_sleep_events+1 end
  if not a.asleep then all_sleep=false end
  for j=i+1,#bodies do
   local depth=M.overlap(a,bodies[j])
   if depth>1e-4 then
    result.overlap_events=result.overlap_events+1
    result.max_overlap=math.max(result.max_overlap,depth)
   end
  end
 end
 if all_sleep and not result.settle_s then result.settle_s=time end
end
function M.finish(result,bodies)
 for _,b in ipairs(bodies) do
  if not b.asleep then result.unsettled=result.unsettled+1 end
  local v,cos,gap=M.top_value(b)
  if b.asleep and cos>=math.cos(math.rad(5)) and gap>=.8 and
     M.floor_height(b)>=-.002 then
    result.faces[v]=result.faces[v]+1
  else
    result.invalid_faces=result.invalid_faces+1
  end
 end
 return result
end
return M
