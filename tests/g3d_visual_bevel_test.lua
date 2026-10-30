-- D6 bevel is VISUAL ONLY: fixed physics cube, face-value mapping and UVs.
local Bevel=require('src.engine3d.g3d_bevel')
local Mesh=require('src.engine3d.g3d_mesh')
local Materials=require('src.engine3d.g3d_materials')
local Live=require('src.engine3d.g3d_live')
local points={
 {1,1,1},{1,-1,1},{-1,-1,1},{-1,1,1},
 {1,1,-1},{1,-1,-1},{-1,-1,-1},{-1,1,-1}
}
local faces={{1,2,3,4},{5,6,7,8},{1,2,6,5},
 {2,3,7,6},{3,4,8,7},{4,1,5,8}}
local body={position={3,-2,5}}
for i,p in ipairs(points) do body[i]={p[1],p[2],p[3]} end
local before={}
for i,p in ipairs(body) do before[i]={p[1],p[2],p[3]} end
local size=Bevel.default_fraction
assert(size>0 and size<Bevel.max_fraction)
local original=Mesh.face_vertices(body,faces[1],true)
local inset=Bevel.face_vertices(Mesh,body,faces[1],true,size)
assert(#inset==6 and #original==6)
assert(inset[1][1]<original[1][1] and inset[1][2]<original[1][2],
 'flat face must shrink toward its physical face center')
assert(inset[1][3]==original[1][3],
 'flat face must remain on its original physical face plane')
assert(inset[1][4]>original[1][4] and inset[1][5]>original[1][5],
 'do not stretch pips into the visual chamfer')
for _,face in ipairs(faces) do
 local v=Bevel.face_vertices(Mesh,body,face,true,size)
 assert(#v==6)
 for _,p in ipairs(v) do
  assert(p[4]>=0 and p[4]<=1 and p[5]>=0 and p[5]<=1)
 end
end
local rim=Bevel.rim_vertices(body,faces,size)
-- Twelve four-sided edge strips + eight triangular corner patches.
assert(#rim==12*6+8*3,'visual cube must have 12 strips and 8 sealed corners')
for i=1,#rim,3 do
 local n=rim[i]
 assert(math.abs(n[6]*n[6]+n[7]*n[7]+n[8]*n[8]-1)<1e-6,
  'chamfer surface must have a normalized normal')
 local a,b,c=rim[i],rim[i+1],rim[i+2]
 local center={(a[1]+b[1]+c[1])/3,(a[2]+b[2]+c[2])/3,
  (a[3]+b[3]+c[3])/3}
 local outward=n[6]*(center[1]-body.position[1])+
  n[7]*(center[2]-body.position[2])+
  n[8]*(center[3]-body.position[3])
 assert(outward>.01,'chamfer normal points inward')
 for _,v in ipairs({a,b,c}) do
  assert(v[9]==1 and v[10]==1 and v[11]==1 and v[12]==1,
   'white bevel geometry must acquire material tint only from the shader')
 end
end
for i,p in ipairs(body) do
 for j=1,3 do assert(p[j]==before[i][j],
  'visual bevel must never alter physics vertices') end
end
assert(body.position[1]==3 and body.position[3]==5)
local live=Live.new()
assert(live.bevel_enabled and live:uses_bevel({die={faces=faces}}))
assert(not live:uses_bevel({die={faces={{1,2,3}}}}))
assert(not live:toggle_bevel() and not live:uses_bevel({die={faces=faces}}))
assert(live:toggle_bevel())
live.material_mode='original'
assert(not live:uses_bevel({die={faces=faces}}),
 'original F10 preset must remain the exact original mesh')
live.material_mode='unlit'
assert(not live:uses_bevel({die={faces=faces}}),
 'unlit comparison must preserve the original flat six-face geometry')
live.material_mode='normals'
assert(live:uses_bevel({die={faces=faces}}),
 'normal debug must include the visual bevel faces')
live.material_mode='ivory'
assert(live:uses_bevel({die={faces=faces}}))
local sent={}
local fake={send=function(_,name,v) sent[name]=v end}
Materials.configure(fake,'ivory',{yaw=0,pitch=.7},false)
assert(sent.pipTexel[1]==0 and sent.pipReliefStrength>0)
Materials.configure_pips(fake,'ivory',{getDimensions=function() return 256,128 end})
assert(sent.pipTexel[1]==1/256 and sent.pipTexel[2]==1/128)
Materials.configure_pips(fake,'ivory',nil)
assert(sent.pipTexel[1]==0 and sent.pipTexel[2]==0,
 'non-textured bevels must not inherit pip engraving offset')
Materials.configure_pips(fake,'diffuse',{getDimensions=function()return 256,256 end})
assert(sent.pipTexel[1]==0,'diffuse comparison must not apply pip engraving')
local f=assert(io.open('resources/shaders/dice_lit.glsl','r'))
local sh=f:read('*a');f:close()
assert(sh:find('pipReliefStrength',1,true))
assert(sh:find('debugMode == 4 && pipTexel.x > 0.0',1,true))
local f2=assert(io.open('src/engine3d/g3d_live.lua','r'))
local liveSource=f2:read('*a');f2:close()
assert(liveSource:find('record.bevel.mesh:setVertices(cut)',1,true))
assert(liveSource:find('models.bevel:draw(shader)',1,true))
assert(not package.loaded['lib.g3d'],'pure material test should run without GPU')
print('PASS D6 visual bevel: complete sealed mesh, outward normals, UV cropping, zero physics changes and F11')
