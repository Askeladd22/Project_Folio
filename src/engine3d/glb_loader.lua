-- Static glTF 2.0 binary (.glb) loader for decorative g3d props.
-- Supports one or more triangle meshes, node transforms and the base colour
-- texture. Animation, skins, morph targets and PBR maps are ignored.
local ffi=require('ffi')
local M={}

local function decode_json(s)
 local i=1
 local function ws() i=s:find('[^ \t\r\n]',i) or #s+1 end
 local value
 local function str()
  local out={}
  i=i+1
  while true do
   local c=s:sub(i,i)
   if c=='"' then i=i+1;return table.concat(out) end
   if c=='' then error('unterminated JSON string') end
   if c=='\\' then
    local e=s:sub(i+1,i+1)
    if e=='u' then
     local code=tonumber(s:sub(i+2,i+5),16)
     out[#out+1]=code<128 and string.char(code) or '?'
     i=i+6
    else
     out[#out+1]=({b='\b',f='\f',n='\n',r='\r',t='\t'})[e] or e
     i=i+2
    end
   else
    local j=s:find('["\\]',i) or #s+1
    out[#out+1]=s:sub(i,j-1);i=j
   end
  end
 end
 function value()
  ws()
  local c=s:sub(i,i)
  if c=='{' then
   local t={};i=i+1;ws()
   if s:sub(i,i)=='}' then i=i+1;return t end
   while true do
    ws();local k=str();ws()
    assert(s:sub(i,i)==':','JSON object expects ":"');i=i+1
    t[k]=value();ws()
    local d=s:sub(i,i);i=i+1
    if d=='}' then return t end
    assert(d==',','JSON object expects ","')
   end
  elseif c=='[' then
   local t={};i=i+1;ws()
   if s:sub(i,i)==']' then i=i+1;return t end
   while true do
    t[#t+1]=value();ws()
    local d=s:sub(i,i);i=i+1
    if d==']' then return t end
    assert(d==',','JSON array expects ","')
   end
  elseif c=='"' then return str()
  elseif s:sub(i,i+3)=='true' then i=i+4;return true
  elseif s:sub(i,i+4)=='false' then i=i+5;return false
  elseif s:sub(i,i+3)=='null' then i=i+4;return nil
  end
  local num=s:match('^-?%d+%.?%d*[eE]?[-+]?%d*',i)
  assert(num and #num>0,'invalid JSON at byte '..i)
  i=i+#num
  return tonumber(num)
 end
 return value()
end
M.decode_json=decode_json

local function u32(bytes,offset)
 local a,b,c,d=bytes:byte(offset+1,offset+4)
 return a+b*256+c*65536+d*16777216
end

local CTYPES={[5126]={'float',4},[5125]={'uint32_t',4},[5123]={'uint16_t',2},[5121]={'uint8_t',1}}
local WIDTH={SCALAR=1,VEC2=2,VEC3=3,VEC4=4}

local function mat_mul(a,b)
 local r={}
 for c=0,3 do for row=0,3 do
  local sum=0
  for k=0,3 do sum=sum+a[k*4+row+1]*b[c*4+k+1] end
  r[c*4+row+1]=sum
 end end
 return r
end
local IDENTITY={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
local function node_matrix(n)
 if n.matrix then return n.matrix end
 local t=n.translation or {0,0,0}
 local q=n.rotation or {0,0,0,1}
 local s=n.scale or {1,1,1}
 local x,y,z,w=q[1],q[2],q[3],q[4]
 return {
  (1-2*(y*y+z*z))*s[1],(2*(x*y+z*w))*s[1],(2*(x*z-y*w))*s[1],0,
  (2*(x*y-z*w))*s[2],(1-2*(x*x+z*z))*s[2],(2*(y*z+x*w))*s[2],0,
  (2*(x*z+y*w))*s[3],(2*(y*z-x*w))*s[3],(1-2*(x*x+y*y))*s[3],0,
  t[1],t[2],t[3],1,
 }
end

-- Returns {verts=g3d vertex list, image=bytes|nil, mime=string|nil,
-- min={x,y,z}, max={x,y,z}, unlit=bool} in glTF space (Y up by convention).
-- opts.largest_only drops proxy/LOD primitives bundled with scanned props.
function M.parse(bytes,opts)
 opts=opts or {}
 assert(type(bytes)=='string' and #bytes>=20,'GLB data required')
 assert(bytes:sub(1,4)=='glTF','not a GLB file')
 assert(u32(bytes,4)==2,'only glTF 2.0 GLB is supported')
 local json,bin
 local offset=12
 while offset+8<=#bytes do
  local len,kind=u32(bytes,offset),bytes:sub(offset+5,offset+8)
  local chunk=bytes:sub(offset+9,offset+8+len)
  if kind=='JSON' then json=chunk elseif kind=='BIN\0' then bin=chunk end
  offset=offset+8+len
 end
 local doc=decode_json(assert(json,'GLB without JSON chunk'))
 assert(bin,'GLB without binary chunk')
 local base=ffi.cast('const uint8_t*',bin)

 local function accessor(index)
  local a=doc.accessors[index+1]
  local view=doc.bufferViews[a.bufferView+1]
  local ct=assert(CTYPES[a.componentType],'unsupported component type')
  local width=WIDTH[a.type]
  local stride=view.byteStride or ct[2]*width
  local start=(view.byteOffset or 0)+(a.byteOffset or 0)
  assert(start+stride*(a.count-1)+ct[2]*width<=#bin,'accessor exceeds buffer')
  local ptype=ffi.typeof(ct[1]..'*')
  return function(i,c)
   return ffi.cast(ptype,base+start+i*stride+c*ct[2])[0]
  end,a.count
 end

 local verts={}
 local mn={math.huge,math.huge,math.huge}
 local mx={-math.huge,-math.huge,-math.huge}
 local material
 local function emit(prim,m)
  do
   assert((prim.mode or 4)==4,'only triangle lists are supported')
   material=material or prim.material
   local pos=accessor(prim.attributes.POSITION)
   local nor=prim.attributes.NORMAL and accessor(prim.attributes.NORMAL)
   local uv=prim.attributes.TEXCOORD_0 and accessor(prim.attributes.TEXCOORD_0)
   local idx,count
   if prim.indices then idx,count=accessor(prim.indices)
   else count=doc.accessors[prim.attributes.POSITION+1].count end
   for k=0,count-1 do
    local i=idx and tonumber(idx(k,0)) or k
    local x,y,z=pos(i,0),pos(i,1),pos(i,2)
    local wx=m[1]*x+m[5]*y+m[9]*z+m[13]
    local wy=m[2]*x+m[6]*y+m[10]*z+m[14]
    local wz=m[3]*x+m[7]*y+m[11]*z+m[15]
    local nx,ny,nz=0,0,1
    if nor then
     local a,b,c=nor(i,0),nor(i,1),nor(i,2)
     nx=m[1]*a+m[5]*b+m[9]*c
     ny=m[2]*a+m[6]*b+m[10]*c
     nz=m[3]*a+m[7]*b+m[11]*c
     local l=math.sqrt(nx*nx+ny*ny+nz*nz)
     if l>0 then nx,ny,nz=nx/l,ny/l,nz/l end
    end
    verts[#verts+1]={wx,wy,wz,uv and uv(i,0) or 0,uv and uv(i,1) or 0,nx,ny,nz,1,1,1,1}
    mn[1],mn[2],mn[3]=math.min(mn[1],wx),math.min(mn[2],wy),math.min(mn[3],wz)
    mx[1],mx[2],mx[3]=math.max(mx[1],wx),math.max(mx[2],wy),math.max(mx[3],wz)
   end
  end
 end
 local found={}
 local function walk(index,parent)
  local n=doc.nodes[index+1]
  local m=mat_mul(parent,node_matrix(n))
  if n.mesh then
   for _,prim in ipairs(doc.meshes[n.mesh+1].primitives) do
    local a=doc.accessors[(prim.indices or prim.attributes.POSITION)+1]
    found[#found+1]={prim=prim,m=m,count=a.count}
   end
  end
  for _,child in ipairs(n.children or {}) do walk(child,m) end
 end
 local scene=doc.scenes and doc.scenes[(doc.scene or 0)+1]
 for _,root in ipairs(scene and scene.nodes or {0}) do walk(root,IDENTITY) end
 if opts.largest_only then
  table.sort(found,function(a,b) return a.count>b.count end)
  found={found[1]}
 end
 for _,item in ipairs(found) do emit(item.prim,item.m) end
 assert(#verts>0,'GLB contains no triangles')

 local image,mime
 local mat=material and doc.materials and doc.materials[material+1]
 local pbr=mat and mat.pbrMetallicRoughness
 local texture=pbr and pbr.baseColorTexture and doc.textures[pbr.baseColorTexture.index+1]
 if texture and texture.source then
  local img=doc.images[texture.source+1]
  if img.bufferView then
   local view=doc.bufferViews[img.bufferView+1]
   local start=view.byteOffset or 0
   image=bin:sub(start+1,start+view.byteLength)
   mime=img.mimeType
  end
 end
 return {verts=verts,image=image,mime=mime,min=mn,max=mx,
  unlit=mat and mat.extensions and mat.extensions.KHR_materials_unlit~=nil or false}
end

-- Converts glTF Y-up to the tray's Z-up world in place: (x,y,z)->(x,-z,y).
function M.to_z_up(model)
 for _,v in ipairs(model.verts) do
  v[2],v[3]=-v[3],v[2]
  v[7],v[8]=-v[8],v[7]
 end
 model.min,model.max={model.min[1],-model.max[3],model.min[2]},{model.max[1],-model.min[3],model.max[2]}
 return model
end

-- Loads a .glb through love.filesystem into a g3d model (base colour only).
-- prepare(model) may transform model.verts in place before upload.
-- opts.max_texture downsizes huge scan textures to bound GPU memory.
function M.load(g3d,path,prepare,opts)
 opts=opts or {}
 local bytes=assert(love.filesystem.read(path),'cannot read '..path)
 local model=M.to_z_up(M.parse(bytes,opts))
 if prepare then prepare(model) end
 local texture
 if model.image then
  local g=love.graphics
  local ext=model.mime=='image/jpeg' and '.jpg' or '.png'
  local source=g.newImage(love.filesystem.newFileData(model.image,path..ext))
  local limit=opts.max_texture or 4096
  local w,h=source:getDimensions()
  local k=math.min(1,limit/math.max(w,h))
  local canvas=g.newCanvas(math.floor(w*k),math.floor(h*k))
  g.push('all')
  g.setCanvas(canvas)
  g.origin()
  g.setScissor()
  g.setStencilTest()
  g.setShader()
  g.clear(0,0,0,0)
  g.setBlendMode('replace')
  g.setColor(1,1,1,1)
  source:setFilter('linear','linear')
  g.draw(source,0,0,0,k,k)
  g.pop()
  source:release()
  texture=g.newImage(canvas:newImageData(),{mipmaps=true})
  canvas:release()
  texture:setFilter('linear','linear')
  texture:setMipmapFilter('linear')
  texture:setWrap('repeat','repeat')
 end
 return g3d.newModel(model.verts,texture),model
end
return M
