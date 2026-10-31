-- Headless visual-material regressions. GPU compilation is checked by
-- Windows LÖVE; this test protects data flow, winding and material presets.
local Material=require('src.engine3d.g3d_materials')
local Mesh=require('src.engine3d.g3d_mesh')
local Live=require('src.engine3d.g3d_live')
assert(Material.default=='ivory')
local expected={'original','unlit','normals','diffuse','ivory','original'}
local current='original'
for i=2,#expected do
 current=Material.next(current)
 assert(current==expected[i],'F10 mode order/regression at '..i)
end
assert(not Material.uses_shader('original') and Material.uses_shader('ivory'))
assert(Material.shader_mode('unlit')==1 and Material.shader_mode('normals')==2
 and Material.shader_mode('diffuse')==3 and Material.shader_mode('ivory')==4)
local view={yaw=0,pitch=.62}
local seen={}
local fake={send=function(_,name,value) seen[name]=value end}
Material.configure(fake,'ivory',view,false)
assert(seen.debugMode==4 and seen.specularStrength>0)
assert(seen.materialTint[1]>seen.materialTint[3] and
 seen.materialTint[3]>.6,'warm ivory material values must be subtle')
assert(seen.viewDirection[3]>0 and seen.lightDirection[3]>.5,
 'light and camera directions must be front-facing')
Material.configure(fake,'diffuse',view,false)
assert(seen.debugMode==3 and seen.materialTint[1]==1,
 'diffuse control must not tint reference material')
Material.configure(fake,'ivory',view,true)
assert(seen.materialTint[1]==1 and seen.materialTint[2]==1,
 'D8 colored faces must not become ivory')
local body={
 {1,1,1},{1,-1,1},{-1,-1,1},{-1,1,1},
 {1,1,-1},{1,-1,-1},{-1,-1,-1},{-1,1,-1},
 position={0,0,0}
}
local faces={{1,2,3,4},{5,6,7,8},{1,2,6,5},
 {2,3,7,6},{3,4,8,7},{4,1,5,8}}
for _,f in ipairs(faces) do
 local old=Mesh.face_vertices(body,f)
 local raw=Mesh.face_vertices(body,f,true)
 assert(#old==6 and #raw==6)
 local sumx,sumy,sumz=0,0,0
 for _,i in ipairs(f) do
  sumx=sumx+body[i][1];sumy=sumy+body[i][2];sumz=sumz+body[i][3]
 end
 local dot=raw[1][6]*sumx+raw[1][7]*sumy+raw[1][8]*sumz
 assert(dot>1,'face normal must face outward')
 for i=1,6 do
  assert(raw[i][9]==1 and raw[i][10]==1 and raw[i][11]==1,
   'custom lighting must not be applied twice')
  assert(old[i][6]==raw[i][6] and old[i][7]==raw[i][7]
    and old[i][8]==raw[i][8],'shader must use original physical normals')
 end
end
local actual=Live.new()
assert(actual.toggle==nil and Material.valid(actual.material_mode))
assert(Material.valid(actual:cycle_material()))
assert(not package.loaded['lib.g3d'],
 'headless material/normal checks must never require GPU initialization')
local file=assert(io.open(Material.shader_path,'r'))
local shader=file:read('*a');file:close()
for _,part in ipairs({'vec4 effect(', 'normalize(vertexNormal)',
  'debugMode == 2','debugMode == 4','Texel(texture, uv)',
  'materialTint','return albedo;'}) do
 assert(shader:find(part,1,true),'shader diagnostic/material step missing: '..part)
end
local file2=assert(io.open('src/engine3d/g3d_live.lua','r'))
local live=file2:read('*a');file2:close()
assert(live:find('Materials.configure(shader,self.material_mode,args.view',1,true),
 'shader settings not passed to 3D models')
assert(live:find('m:draw(shader)',1,true),
 'dice must receive dedicated shader without modifying base g3d')
print('PASS g3d die materials: outward normals, F10 presets, pure shader config, unshaded meshes')
