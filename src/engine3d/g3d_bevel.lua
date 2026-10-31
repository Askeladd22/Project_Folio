-- Visual-only clipped/chamfered D6 derived from the current physical
-- vertices. No extra physical vertices, no collider or face-value changes.
-- Faces retain their original pip UV orientation; chamfers use plain white.
local B={}
-- Subtle edge rounding: a broad 11% chamfer read as an extra square
-- laid on top of the cube in 2026-10-31 screenshots.
B.default_fraction=.055
B.max_fraction=.20
local TRIANGLES={1,2,3,1,3,4}
local function lerp(a,b,t) return a+(b-a)*t end
local function point(body,index)
 local p=assert(body[index],'missing physical cube corner')
 return {p[1]+body.position[1],p[2]+body.position[2],p[3]+body.position[3]}
end
local function trimmed(body,face,fraction)
 assert(#face==4,'chamfer only supports D6 quads')
 assert(type(fraction)=='number' and fraction>0 and fraction<=B.max_fraction,
  'invalid visual bevel fraction')
 local center={0,0,0}
 for _,index in ipairs(face) do
  local v=point(body,index)
  for axis=1,3 do center[axis]=center[axis]+v[axis]/4 end
 end
 local result={}
 for i,index in ipairs(face) do
  local p=point(body,index)
  result[i]={lerp(p[1],center[1],fraction),
   lerp(p[2],center[2],fraction),lerp(p[3],center[3],fraction)}
 end
 return result
end

function B.face_vertices(mesh,body,face,raw_lighting,fraction)
 local vertices=mesh.face_vertices(body,face,raw_lighting)
 if not fraction or fraction<=0 then return vertices end
 local inset=trimmed(body,face,fraction)
 for i,k in ipairs(TRIANGLES) do
  local v=vertices[i]
  local p=inset[k]
  v[1],v[2],v[3]=p[1],p[2],p[3]
  -- Preserve pip alignment and size: crop the border of the original
  -- texture instead of stretching its entire image across the small face.
  v[4]=.5+(v[4]-.5)*(1-fraction)
  v[5]=.5+(v[5]-.5)*(1-fraction)
 end
 return vertices
end

local function add_triangle(result,a,b,c,body)
 local cx,cy,cz=body.position[1],body.position[2],body.position[3]
 local ux,uy,uz=b[1]-a[1],b[2]-a[2],b[3]-a[3]
 local vx,vy,vz=c[1]-a[1],c[2]-a[2],c[3]-a[3]
 local nx,ny,nz=uy*vz-uz*vy,uz*vx-ux*vz,ux*vy-uy*vx
 local len=math.sqrt(nx*nx+ny*ny+nz*nz)
 assert(len>1e-9,'degenerate visual chamfer')
 nx,ny,nz=nx/len,ny/len,nz/len
 local mx,my,mz=(a[1]+b[1]+c[1])/3,(a[2]+b[2]+c[2])/3,
  (a[3]+b[3]+c[3])/3
 if nx*(mx-cx)+ny*(my-cy)+nz*(mz-cz)<0 then
  b,c=c,b
  nx,ny,nz=-nx,-ny,-nz
 end
 for _,p in ipairs({a,b,c}) do
  result[#result+1]={p[1],p[2],p[3],0,0,nx,ny,nz,1,1,1,1}
 end
end

function B.rim_vertices(body,faces,fraction)
 assert(type(body)=='table' and body.position,'physical die required')
 assert(type(faces)=='table' and #faces==6,'six D6 faces required')
 local edges,corners={},{}
 for _,face in ipairs(faces) do
  local cut=trimmed(body,face,fraction)
  for k,original_index in ipairs(face) do
   corners[original_index]=corners[original_index] or {}
   corners[original_index][#corners[original_index]+1]=cut[k]
  end
  for k=1,4 do
   local next_k=k%4+1
   local i,j=face[k],face[next_k]
   local min,max=math.min(i,j),math.max(i,j)
   local key=min..':'..max
   local edge=edges[key] or {a=min,b=max,sides={}}
   edge.sides[#edge.sides+1]={
    [i]=cut[k],[j]=cut[next_k]
   }
   edges[key]=edge
  end
 end
 local result={}
 local edge_count,corner_count=0,0
 for _,edge in pairs(edges) do
  assert(#edge.sides==2,'D6 edge must join exactly two physical faces')
  local a,b=edge.sides[1],edge.sides[2]
  local a1,a2,b1,b2=a[edge.a],a[edge.b],b[edge.a],b[edge.b]
  add_triangle(result,a1,a2,b2,body)
  add_triangle(result,a1,b2,b1,body)
  edge_count=edge_count+1
 end
 for _,points in pairs(corners) do
  assert(#points==3,'D6 corner must join exactly three physical faces')
  add_triangle(result,points[1],points[2],points[3],body)
  corner_count=corner_count+1
 end
 assert(edge_count==12 and corner_count==8,'incomplete D6 visual chamfer')
 return result
end
return B
