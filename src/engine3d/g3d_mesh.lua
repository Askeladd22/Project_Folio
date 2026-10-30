-- Pure geometry adapter for the renderer A/B experiment.
-- Reuses the exact six physical vertices/faces already used by Manuscript.
-- Does not integrate physics or assign a gameplay die value.
local M={}
local UV={{0,0},{1,0},{1,1},{0,1}}
local UV3={{0,0},{1,0},{.5,1}}
local TRIANGLES={1,2,3,1,3,4}
local LIGHT={0.25,-0.4,0.88}

function M.face_vertices(body,face,raw_lighting)
 assert(type(body)=='table' and type(body.position)=='table' and
        type(face)=='table' and (#face==4 or #face==3),'three or four physical vertex indices required')
 local points={}
 for i=1,#face do
  local vertex=assert(body[face[i]],'missing physical vertex')
  points[i]={vertex[1]+body.position[1],
             vertex[2]+body.position[2],
             vertex[3]+body.position[3]}
 end
 local p,q,r=points[1],points[2],points[3]
 local ax,ay,az=q[1]-p[1],q[2]-p[2],q[3]-p[3]
 local bx,by,bz=r[1]-p[1],r[2]-p[2],r[3]-p[3]
 local nx,ny,nz=ay*bz-az*by,az*bx-ax*bz,ax*by-ay*bx
 local length=math.sqrt(nx*nx+ny*ny+nz*nz)
 assert(length>1e-8,'degenerate physical face')
 nx,ny,nz=nx/length,ny/length,nz/length
 local center={0,0,0}
 for _,v in ipairs(points) do
  for j=1,3 do center[j]=center[j]+v[j]/#face end
 end
 local outward=nx*(center[1]-body.position[1])+
               ny*(center[2]-body.position[2])+
               nz*(center[3]-body.position[3])
 if outward<0 then nx,ny,nz=-nx,-ny,-nz end
 local dot=math.max(0,nx*LIGHT[1]+ny*LIGHT[2]+nz*LIGHT[3])
 -- Only the historical g3d preset uses baked vertex illumination.
 -- Custom shaders light the same outward physical face normals per pixel.
 local shade=raw_lighting and 1 or (0.57+0.43*dot)
 local vertices={}
 local triangulation=#face==3 and {1,2,3} or TRIANGLES
 for i,k in ipairs(triangulation) do
  local v,uv=points[k],#face==3 and UV3[k] or UV[k]
  vertices[i]={v[1],v[2],v[3],uv[1],uv[2],
               nx,ny,nz,shade,shade,shade,1}
 end
 return vertices
end

function M.pip(face_index,d6)
 return assert(d6.faceValueMap[face_index],'unknown D6 face')
end

function M.floor_vertices(x1,x2,y1,y2)
 local points={{x1,y1,0},{x2,y1,0},{x2,y2,0},{x1,y2,0}}
 local result={}
 for i,k in ipairs(TRIANGLES) do
  local v,uv=points[k],UV[k]
  result[i]={v[1],v[2],v[3],uv[1],uv[2],0,0,1,.8,.8,.8,1}
 end
 return result
end
-- Same 8-segment outer/inner/rim quads as render.tray_border.
-- Geometry is static: build the GPU mesh once, not on every frame.
function M.tray_border_vertices(x1,x2,y1,y2,width,height,segments)
 assert(x1<x2 and y1<y2 and width>0 and height>0,'valid tray dimensions')
 segments=segments or 8
 assert(segments>=1 and segments==math.floor(segments),'valid segments')
 local outer={
  {x1-width,y1-width},{x2+width,y1-width},
  {x2+width,y2+width},{x1-width,y2+width}
 }
 local inner={{x1,y1},{x2,y1},{x2,y2},{x1,y2}}
 local shades={
  outer={180,220,255,190},inner={130,140,150,130},
  rim={230,240,255,225}
 }
 local vertices={}
 local function mix(a,b,t) return a+(b-a)*t end
 local function interpolate(a,b,t,z)
  return {mix(a[1],b[1],t),mix(a[2],b[2],t),z}
 end
 local function quad(points,uv,shade)
  local a,b,c=points[1],points[2],points[3]
  local dx,dy,dz=b[1]-a[1],b[2]-a[2],b[3]-a[3]
  local ex,ey,ez=c[1]-a[1],c[2]-a[2],c[3]-a[3]
  local nx,ny,nz=dy*ez-dz*ey,dz*ex-dx*ez,dx*ey-dy*ex
  local len=math.sqrt(nx*nx+ny*ny+nz*nz)
  if len<1e-9 then error('degenerate tray quad') end
  nx,ny,nz=nx/len,ny/len,nz/len
  for _,k in ipairs(TRIANGLES) do
   local p,u=points[k],uv[k]
   vertices[#vertices+1]={p[1],p[2],p[3],u[1],u[2],
    nx,ny,nz,shade,shade*.94,shade*.86,1}
  end
 end
 for side=1,4 do
  local nextside=side%4+1
  local ia,ib=inner[side],inner[nextside]
  local oa,ob=outer[side],outer[nextside]
  local len=math.sqrt((ib[1]-ia[1])^2+(ib[2]-ia[2])^2)
  local rim_width=math.sqrt((oa[1]-ia[1])^2+(oa[2]-ia[2])^2)
  local outershade=shades.outer[side]/255
  local innershade=shades.inner[side]/255
  local rimshade=shades.rim[side]/255
  for k=0,segments-1 do
   local t1,t2=k/segments,(k+1)/segments
   local p1,p2=interpolate(oa,ob,t1,0),interpolate(oa,ob,t2,0)
   local p3,p4=interpolate(oa,ob,t2,height),interpolate(oa,ob,t1,height)
   local u1,u2=t1*len/24,t2*len/24
   local uv_outer={{u1,height/24},{u2,height/24},{u2,0},{u1,0}}
   quad({p1,p2,p3,p4},uv_outer,outershade)
   local i1,i2=interpolate(ia,ib,t1,0),interpolate(ia,ib,t2,0)
   local i3,i4=interpolate(ia,ib,t2,height),interpolate(ia,ib,t1,height)
   quad({i2,i1,i4,i3},{{u2,height/24},{u1,height/24},{u1,0},{u2,0}},innershade)
   quad({p4,p3,i3,i4},
    {{u1,.31},{u2,.31},{u2,.31+rim_width/24},{u1,.31+rim_width/24}},
    rimshade)
  end
 end
 return vertices
end
return M
