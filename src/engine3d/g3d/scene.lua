local Parts = {}

-- Dice materials
Parts.materials = (function()
-- Dice-only material configuration; no physics, gameplay, or external g3d edits.
-- Cycle with F10 while g3d is active. Pure helpers remain headless-testable.
local M={}
M.modes={'original','unlit','normals','diffuse','ivory'}
M.default='ivory'
M.shader_path='resources/shaders/dice_lit.glsl'
M.vertex_path='lib/g3d/g3d.vert'
local indexes={original=1,unlit=2,normals=3,diffuse=4,ivory=5}
local shader_modes={unlit=1,normals=2,diffuse=3,ivory=4}
function M.valid(mode) return indexes[mode]~=nil end
function M.next(mode)
 return M.modes[(indexes[mode] or 1)%#M.modes+1]
end
function M.uses_shader(mode) return shader_modes[mode]~=nil end
function M.shader_mode(mode) return shader_modes[mode] end
local function normalized(x,y,z)
 local len=math.sqrt(x*x+y*y+z*z)
 return {x/len,y/len,z/len}
end
M.light=normalized(-.46,-.34,.82)
M.fill=normalized(.65,.25,.72)
function M.view_direction(view)
 local yaw,pitch=view.yaw,view.pitch
 return normalized(math.sin(yaw)*math.sin(pitch),
                   math.cos(yaw)*math.sin(pitch),math.cos(pitch))
end
function M.tint(d8,mode)
 if mode=='diffuse' then return {1,1,1} end
 -- D8 has independently colored faces: don't turn its color cycle ivory.
 if d8 then return {1,1,1} end
 return {.98,.95,.89}
end
function M.configure(shader,mode,view,is_d8,index)
 assert(M.uses_shader(mode),'unsupported dice material mode')
 shader:send('debugMode',M.shader_mode(mode))
 shader:send('lightDirection',M.light)
 shader:send('fillDirection',M.fill)
 shader:send('viewDirection',M.view_direction(view))
 shader:send('materialTint',M.tint(is_d8,mode))
 local bone=mode=='ivory' and not is_d8
 shader:send('boneSurface',bone and 1 or 0)
 shader:send('boneSeed',((index or 1)-1)%6)
 shader:send('pipValue',0)
 shader:send('ambientStrength',bone and .50 or .46)
 shader:send('keyStrength',bone and .40 or .46)
 shader:send('fillStrength',bone and .18 or .15)
 shader:send('specularStrength',bone and .025 or .075)
 shader:send('specularExponent',30)
 shader:send('pipTexel',{0,0})
 shader:send('pipReliefStrength',.045)
end

-- Ivory uses the physical face value for procedural ring-and-dot pips.
-- Diagnostic textures retain their texel offset. Clear the value on bevels.
function M.configure_pips(shader,mode,texture,value)
 local step={0,0}
 if mode=='ivory' and texture and type(texture.getDimensions)=='function' then
  local w,h=texture:getDimensions()
  if w and h and w>0 and h>0 then step={1/w,1/h} end
 end
 shader:send('pipTexel',step)
 local pip=mode=='ivory' and type(value)=='number' and value%1==0
  and value>=1 and value<=6 and value or 0
 shader:send('pipValue',pip)
end
return M
end)()

-- Dice bevel
Parts.bevel = (function()
-- Visual-only clipped/chamfered D6 derived from the current physical
-- vertices. No extra physical vertices, no collider or face-value changes.
-- Faces retain their original pip UV orientation; chamfers use plain white.
local B={}
-- Keep the worn edges visible without making the face read as a second panel.
B.default_fraction=.065
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
end)()

-- Physical geometry adapters
Parts.mesh = (function()
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
end)()

-- Table scenery
Parts.scenery = (function()
-- Pure geometry for F8 tray skins; never changes physical collision geometry.
-- GPU scene remains independent from Farkle rules, fixed stepping and picking.
local S={}
-- Merchant tints multiply wood.png: walnut gaming top, ink-blackened
-- press furniture around it (the dream merges table and press bed).
local PALETTE={
 merchant={.24,.22,.24},book={.76,.67,.51},current={.35,.215,.12},
 A={.31,.18,.095},B={.48,.33,.20},C={.52,.43,.255},
}
-- Plain, non-textured floors keep the physical dice visually prominent.
-- Unlike the old painter's manuscript rubrics these meshes share g3d depth.
local FLOORS={
 merchant={.70,.62,.60},book={.88,.79,.64},current={.36,.29,.22},
 A={.32,.23,.17},B={.29,.35,.31},C={.45,.39,.30},
}
function S.floor_vertices(mesh,extents,style)
 local color=FLOORS[style] or FLOORS.book
 local out=mesh.floor_vertices(extents[1],extents[2],extents[3],extents[4])
 for _,v in ipairs(out) do
  v[9],v[10],v[11],v[12]=color[1],color[2],color[3],1
 end
 return out
end
local function vertex(pos,color,alpha)
 return {pos[1],pos[2],pos[3],0,0,0,0,1,color[1],color[2],color[3],alpha or 1}
end
local function quad(out,a,b,c,d,color)
 for _,p in ipairs({a,b,c,a,c,d}) do out[#out+1]=vertex(p,color) end
end
function S.style_vertices(mesh,extents,height,style)
 style=PALETTE[style] and style or 'book'
 local x1,x2,y1,y2=unpack(extents)
 -- Thin decorative housing; the underlying collision walls do not change.
 local width=style=='book' and .32 or style=='current' and .28
  or style=='C' and .13 or style=='merchant' and .28 or .40
 local v=mesh.tray_border_vertices(x1,x2,y1,y2,width,height,8)
 local colors=PALETTE[style]
 -- All wall sections retain the same physical heights; only the skin changes.
 for side=1,4 do
  for part=1,3 do
   local shade=part==1 and .95 or part==2 and .67 or 1.08
   local c=colors
   if style=='book' then
    c=side==4 and ({[1]={.26,.12,.075},[2]={.37,.225,.14},[3]={.31,.17,.105}})[part]
      or ({[1]={.76,.67,.51},[2]={.60,.50,.355},[3]={.86,.775,.61}})[part]
    shade=1
   end
   for vertex_index=0,47 do
    -- Mesh order within each side: segment, then outer/inner/rim quad.
    local segment=math.floor(vertex_index/6)
    local i=((side-1)*8+segment)*18+(part-1)*6+vertex_index%6+1
    v[i][9]=math.min(1,c[1]*shade)
    v[i][10]=math.min(1,c[2]*shade)
    v[i][11]=math.min(1,c[3]*shade)
   end
  end
 end
 -- The illustration supplies the merchant's far end. Join its wood directly
 -- to the physical floor instead of laying a second crossbar across it.
 if style=='merchant' then
  local sides={}
  for i=8*3*6+1,#v do
   local point=v[i]
   -- A flush joint at the illustrated edge, rising to full rail height
   -- over the first segment. Keep both sides of each joint coincident.
   local rise=math.max(0,math.min(1,(point[2]-y1)/1.4))
   point[2]=math.max(y1,point[2])
   point[3]=point[3]*rise
   -- U follows each timber's length (front across X, side rails along Y).
   local front=i>2*8*18 and i<=3*8*18
   point[4]=front and (point[1]-x1+width)/(x2-x1+2*width)
    or (point[2]-y1)/(y2-y1+width)
   point[5]=.4+.20*(1-point[3]/height)
   if point[3]>height*.98 then
    for channel=9,11 do point[channel]=math.min(1,point[channel]+.09) end
   end
   -- Sink the near apron under the floor so it cannot mask a resting die.
   local drop=math.max(0,math.min(1,(point[2]-y2+1.4)/1.4))
   point[3]=point[3]-height*drop
   sides[#sides+1]=point
  end
  return sides
 end
 -- Variant B is a wide counter around an unchanged tray opening.
 if style=='B' then
  local inner={{x1,y1},{x2,y1},{x2,y2},{x1,y2}}
  local outer={{x1-4.5,y1-.85},{x2+4.5,y1-.85},
               {x2+4.5,y2+.85},{x1-4.5,y2+.85}}
  for i=1,4 do
   local j=i%4+1
   local a,b=inner[i],inner[j]
   local c,d=outer[i],outer[j]
   quad(v,{c[1],c[2],height},{d[1],d[2],height},
    {b[1],b[2],height},{a[1],a[2],height},{.48,.33,.20})
  end
 end
 return v
end
function S.divider_vertices(info)
 if not info then return nil end
 local x1,x2=assert(info.back_x),assert(info.front_x)
 local y1,y2=assert(info.back_y),assert(info.front_y)
 local w=assert(info.width)
 local z=assert(info.height)
 assert(y2>y1 and w>0 and z>0,'valid divider geometry')
 local p={}
 quad(p,{x1-w,y1,.01},{x2-w,y2,.01},{x2-w,y2,z},{x1-w,y1,z},{.24,.17,.11})
 quad(p,{x2+w,y2,.01},{x1+w,y1,.01},{x1+w,y1,z},{x2+w,y2,z},{.42,.30,.20})
 quad(p,{x1-w,y1,z},{x1+w,y1,z},{x2+w,y2,z},{x2-w,y2,z},{.56,.40,.28})
 quad(p,{x1-w,y1,.01},{x1-w,y1,z},{x1+w,y1,z},{x1+w,y1,.01},{.31,.22,.15})
 quad(p,{x2-w,y2,.01},{x2+w,y2,.01},{x2+w,y2,z},{x2-w,y2,z},{.31,.22,.15})
 return p
end
-- The scan is authored Z-up inside its glTF: remap {new x,y,z} = signed old
-- axes so the top faces +Z and the long side follows the tray width.
S.table_prop={
 path='resources/models/marble_topped_centre_table.glb',
 remap={3,-1,-2},largest_only=true,max_texture=4096,
 shader='resources/shaders/dream_table.glsl',
}
function S.remap_axes(model,remap)
 local function pick(a,b,c,k) local s=k<0 and -1 or 1;return s*({a,b,c})[math.abs(k)] end
 for _,v in ipairs(model.verts) do
  v[1],v[2],v[3]=pick(v[1],v[2],v[3],remap[1]),pick(v[1],v[2],v[3],remap[2]),pick(v[1],v[2],v[3],remap[3])
  v[6],v[7],v[8]=pick(v[6],v[7],v[8],remap[1]),pick(v[6],v[7],v[8],remap[2]),pick(v[6],v[7],v[8],remap[3])
 end
 local mn,mx={math.huge,math.huge,math.huge},{-math.huge,-math.huge,-math.huge}
 for _,v in ipairs(model.verts) do
  for k=1,3 do mn[k]=math.min(mn[k],v[k]);mx[k]=math.max(mx[k],v[k]) end
 end
 model.min,model.max=mn,mx
 return model
end
local TABLE_LIGHT={0.25,-0.4,0.88}
-- Scales a Z-up table so its top spans the tray and rim, flush at z=0 where
-- the flat floor used to be. Lit models get baked shading (g3d is unlit);
-- scans with baked light only receive the warm night tint.
function S.place_table(model,extents,rim)
 local x1,x2,y1,y2=extents[1],extents[2],extents[3],extents[4]
 local mn,mx=model.min,model.max
 local half=math.max(x2-x1,1)*.5+(rim or .28)+.4
 local scale=half/((mx[1]-mn[1])*.5)
 -- Depth may be shortened up to 30% so the top does not swallow the rival.
 local depth=math.max(scale*.7,((y2-y1)*.5+(rim or .28)+.8)/((mx[2]-mn[2])*.5))
 local ox,oy=(x1+x2)*.5-(mn[1]+mx[1])*.5*scale,(y1+y2)*.5-(mn[2]+mx[2])*.5*depth
 local oz=-mx[3]*scale
 local cx,cy=(x1+x2)*.5,(y1+y2)*.5
 local hx,hy=(x2-x1)*.5,(y2-y1)*.5
 for _,v in ipairs(model.verts) do
  v[1],v[2],v[3]=v[1]*scale+ox,v[2]*depth+oy,v[3]*scale+oz
  local dot=math.max(0,v[6]*TABLE_LIGHT[1]+v[7]*TABLE_LIGHT[2]+v[8]*TABLE_LIGHT[3])
  local shade=model.unlit and .80 or .30+.52*dot
  -- Candle pool: brightest where dice land, falling off to the rim and legs.
  local d=math.sqrt(((v[1]-cx)/hx)^2+((v[2]-cy)/hy)^2)
  local t=math.max(0,math.min(1,(d-.15)/1.05))
  local pool=1.15-.72*t*t*(3-2*t)
  local below=math.max(.95,1+v[3]/(hx*.5))
  shade=shade*pool*below
  v[9],v[10],v[11]=math.min(1,shade),math.min(1,shade*(model.unlit and .88 or .80)),
   math.min(1,shade*(model.unlit and .74 or .60))
 end
 model.min={mn[1]*scale+ox,mn[2]*depth+oy,mn[3]*scale+oz}
 model.max={mx[1]*scale+ox,mx[2]*depth+oy,0}
 return model
end
function S.face_color(die,i)
 local color=die.faceColors and die.faceColors[i] or die.color or {255,255,255,255}
 local n=math.max(color[1] or 255,color[2] or 255,color[3] or 255)
 local divisor=n>1 and 255 or 1
 return {math.max(0,math.min(1,(color[1] or 255)/divisor)),
         math.max(0,math.min(1,(color[2] or 255)/divisor)),
         math.max(0,math.min(1,(color[3] or 255)/divisor))}
end
return S
end)()

-- Camera and projection
Parts.camera = (function()
-- Camera parity adapter for g3d Lab 2. Pure functions except apply().
-- The historical painter projects screen X to the right but uses a
-- left-handed screen basis. Compose that basis in the 3D view matrix,
-- never by mirroring an already rendered Canvas.
local C={}
function C.matrix(view)
 local yaw,pitch,distance=view.yaw,view.pitch,view.distance
 local c,s=math.cos(yaw),math.sin(yaw)
 local cp,sp=math.cos(pitch),math.sin(pitch)
 -- Right, screen-up, and camera-back axes; screen-up = -legacy screen Y.
 return {
  c,-s,0,0,
  -s*cp,-c*cp,sp,0,
  s*sp,c*sp,cp,-distance,
  0,0,0,1,
 }
end
function C.screen(view,w,h,scale,x,y,z)
 local m=C.matrix(view)
 local sx=m[1]*x+m[2]*y+m[3]*z+m[4]
 local sy=m[5]*x+m[6]*y+m[7]*z+m[8]
 local sz=m[9]*x+m[10]*y+m[11]*z+m[12]
 local zoom=view.focus/(view.projection=='perspective' and -sz or view.distance)
 return w/2+sx*scale*zoom,h/2-sy*scale*zoom,sz
end
function C.apply(view,camera,w,h,scale,dx,dy)
 assert(w>0 and h>0 and scale>0,'valid viewport and zoom required')
 local m=C.matrix(view)
 for i=1,16 do camera.viewMatrix[i]=m[i] end
 camera.fov=math.pi/2
 camera.aspectRatio=w/h
 if view.projection=='perspective' then
  camera.fov=2*math.atan(h/(2*scale*view.focus))
  camera.updateProjectionMatrix()
  -- With clip.w = -eye.z the principal point shift belongs in column 3.
  camera.projectionMatrix[3]=-2*(dx or 0)/w
  camera.projectionMatrix[7]=2*(dy or 0)/h
 else
  camera.updateOrthographicMatrix(h/(2*scale*(view.focus/view.distance)))
  if dx then camera.projectionMatrix[4]=camera.projectionMatrix[4]+2*dx/w end
  if dy then camera.projectionMatrix[8]=camera.projectionMatrix[8]-2*dy/h end
 end
end
return C
end)()

-- Physical dice shadows
Parts.shadow = (function()
-- Project the physical corners onto the tabletop along the dice material's key light.
local light=Parts.materials.light
local cast_x,cast_y=-light[1]/light[3],-light[2]/light[3]

local function turn(a,b,c)
 return (b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])
end

local function convex_outline(points)
 table.sort(points,function(a,b)
  return a[1]<b[1] or (a[1]==b[1] and a[2]<b[2])
 end)
 local hull={}
 local function append(point,start)
  while #hull>start and turn(hull[#hull-1],hull[#hull],point)<=1e-9 do
   hull[#hull]=nil
  end
  hull[#hull+1]=point
 end
 for _,point in ipairs(points) do append(point,1) end
 local split=#hull
 for i=#points-1,1,-1 do append(points[i],split) end
 hull[#hull]=nil -- the first point closes both chains
 return hull
end

local function shadow_vertices(body,offset,preview)
 local position=body.position
 local x=position[1]-(offset or 0)+(preview and preview.x or 0)
 local y=position[2]+(preview and preview.y or 0)
 local z=position[3]+(preview and preview.z or 0)
 local radius=body.radius or .65
 local bottom=#body>0 and math.huge or -radius
 local projected={}
 for _,corner in ipairs(body) do
  bottom=math.min(bottom,corner[3])
  local height=z+corner[3]
  projected[#projected+1]={x+corner[1]+cast_x*height,y+corner[2]+cast_y*height}
 end
 -- Radius-only proxies have no physical silhouette to project.
 if #projected<3 then
  local cx,cy=x+cast_x*z,y+cast_y*z
  projected={{cx-radius,cy-radius},{cx+radius,cy-radius},
             {cx+radius,cy+radius},{cx-radius,cy+radius}}
 end
 local hull=convex_outline(projected)
 local cx,cy=x+cast_x*z,y+cast_y*z
 local clearance=math.max(0,z+bottom)
 local opacity=.47/(1+.36*clearance)
 local blur=.15+.20*clearance/math.max(.25,radius)
 local core=math.max(.18,1-blur*.75)
 local edge=1+blur
 local function vertex(point,scale,alpha)
  -- Black with alpha darkens the existing grain and preserves its hue.
  return {cx+(point[1]-cx)*scale,cy+(point[2]-cy)*scale,.012,
          0,0,0,0,1,0,0,0,alpha}
 end
 local center=vertex({cx,cy},0,opacity)
 local inner,outer={},{}
 for i,point in ipairs(hull) do
  inner[i]=vertex(point,core,opacity)
  outer[i]=vertex(point,edge,0)
 end
 local vertices={}
 for i=1,#hull do
  local j=i%#hull+1
  local n=#vertices
  vertices[n+1],vertices[n+2],vertices[n+3]=center,inner[i],inner[j]
  vertices[n+4],vertices[n+5],vertices[n+6]=inner[i],outer[i],outer[j]
  vertices[n+7],vertices[n+8],vertices[n+9]=inner[i],outer[j],inner[j]
 end
 -- One mesh per die survives rotation, even when its outline gains a corner.
 for i=#vertices+1,8*9 do vertices[i]=center end
 return vertices
end

return shadow_vertices
end)()

return Parts
