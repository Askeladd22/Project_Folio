-- Pure geometry adapter for the renderer A/B experiment.
-- Reuses the exact six physical vertices/faces already used by Manuscript.
-- Does not integrate physics or assign a gameplay die value.
local M={}
local UV={{0,0},{1,0},{1,1},{0,1}}
local TRIANGLES={1,2,3,1,3,4}
local LIGHT={0.25,-0.4,0.88}

function M.face_vertices(body,face)
 assert(type(body)=='table' and type(body.position)=='table' and
        type(face)=='table' and #face==4,'four physical vertex indices required')
 local points={}
 for i=1,4 do
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
  for j=1,3 do center[j]=center[j]+v[j]/4 end
 end
 local outward=nx*(center[1]-body.position[1])+
               ny*(center[2]-body.position[2])+
               nz*(center[3]-body.position[3])
 if outward<0 then nx,ny,nz=-nx,-ny,-nz end
 local dot=math.max(0,nx*LIGHT[1]+ny*LIGHT[2]+nz*LIGHT[3])
 local shade=0.57+0.43*dot
 local vertices={}
 for i,k in ipairs(TRIANGLES) do
  local v,uv=points[k],UV[k]
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
return M
