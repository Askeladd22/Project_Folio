-- Low-poly geometry derived from the uploaded Wooden Table (game ready asset).
-- Original by Pixel Life, CC BY 4.0; see resources/models/WOODEN_TABLE_CREDITS.md.
-- Non-canonical visual-only fallback for the full model. Physics is untouched.
local M={}
M.vertex_count=243
M.face_count=497
M.bbox_min={-123.8540895,0.1132178,-63.0080835}
M.bbox_max={123.8363987,88.3412928,63.0277228}
local compressed=[=[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]=]

local function u16(raw,i)
 local a,b=raw:byte(i,i+1)
 return a+256*b
end
function M.mesh()
 assert(love and love.data,'LÖVE data decompression is required for the visual mesh')
 local raw=love.data.decompress('string','zlib',
  love.data.decode('string','base64',compressed))
 assert(#raw==M.vertex_count*6+M.face_count*6,
  'embedded wooden table silhouette corrupted')
 local points={}
 for i=0,M.vertex_count-1 do
  local j=i*6+1
  local function axis(k)
   return M.bbox_min[k]+u16(raw,j+(k-1)*2)/65535*
    (M.bbox_max[k]-M.bbox_min[k])
  end
  local x,y,z=axis(1),axis(2),axis(3)
  points[i+1]={x,-z,y}
 end
 local verts={}
 local base=M.vertex_count*6
 for i=0,M.face_count-1 do
  local j=base+i*6+1
  local a,b,c=points[u16(raw,j)+1],points[u16(raw,j+2)+1],points[u16(raw,j+4)+1]
  local ab={b[1]-a[1],b[2]-a[2],b[3]-a[3]}
  local ac={c[1]-a[1],c[2]-a[2],c[3]-a[3]}
  local nx=ab[2]*ac[3]-ab[3]*ac[2]
  local ny=ab[3]*ac[1]-ab[1]*ac[3]
  local nz=ab[1]*ac[2]-ab[2]*ac[1]
  local len=math.sqrt(nx*nx+ny*ny+nz*nz)
  if len>0.0001 then
   nx,ny,nz=nx/len,ny/len,nz/len
   for _,p in ipairs({a,b,c}) do
    local u=(p[1]-M.bbox_min[1])/(M.bbox_max[1]-M.bbox_min[1])
    local v=math.abs(nz)>.55 and
      (p[2]+M.bbox_max[3])/(M.bbox_max[3]-M.bbox_min[3]) or
      (p[3]-M.bbox_min[2])/(M.bbox_max[2]-M.bbox_min[2])
    verts[#verts+1]={p[1],p[2],p[3],u,v,nx,ny,nz,1,1,1,1}
   end
  end
 end
 return {verts=verts,min={M.bbox_min[1],-M.bbox_max[3],M.bbox_min[2]},
  max={M.bbox_max[1],-M.bbox_min[3],M.bbox_max[2]},unlit=false}
end
return M
