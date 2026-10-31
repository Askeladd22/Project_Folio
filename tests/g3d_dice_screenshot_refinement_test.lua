-- Screenshot-driven refinement: never modify rigid bodies or Farkle scoring.
local B=require('src.engine3d.g3d_bevel')
local G=require('src.engine3d.g3d_live')
local Materials=require('src.engine3d.g3d_materials')
local Mesh=require('src.engine3d.g3d_mesh')
assert(B.default_fraction>0.035 and B.default_fraction<.075,
 'D6 visual edge must be subtle rather than a thick second panel')
local body={position={4,-2,.65}}
for i,p in ipairs({{.625,.625,.625},{.625,-.625,.625},
 {-.625,-.625,.625},{-.625,.625,.625},
 {.625,.625,-.625},{.625,-.625,-.625},
 {-.625,-.625,-.625},{-.625,.625,-.625}}) do
 body[i]={p[1],p[2],p[3]}
end
local faces={{1,2,3,4},{5,6,7,8},{1,2,6,5},
 {2,3,7,6},{3,4,8,7},{4,1,5,8}}
local first=Mesh.face_vertices(body,faces[1],true)
local tiny=B.face_vertices(Mesh,body,faces[1],true,B.default_fraction)
assert(#tiny==#first and tiny[1][3]==first[1][3],
 'render-only bevel may shrink surface but cannot alter face height')
for i,v in ipairs(body) do
 assert(v[1]==({.625,.625,-.625,-.625,.625,.625,-.625,-.625})[i],
  'bevel must not modify physical body corners')
end
local ring=B.rim_vertices(body,faces,B.default_fraction)
assert(#ring==96,'12 bevel strips + 8 sealed corners')
local contact=G.shadow_vertices({position={0,0,.65},radius=.65},0)
local airborne=G.shadow_vertices({position={0,0,3},radius=.65},0)
assert(#contact==72 and #airborne==72)
assert(contact[1][12]>airborne[1][12],
 'contact shadow must be stronger for a die resting on the floor')
assert(contact[2][12]==0,'contact disk must feather to transparency')
assert(contact[2][1]-contact[1][1]>.7,
 'floor shadow must extend visibly beyond the cube footprint')
local offset=G.shadow_vertices({position={2,0,.65},radius=.65},2)
assert(math.abs(offset[1][1]-contact[1][1])<1e-8,
 'world shadow must honor split-tray rendering offset')
local sent={}
local fake={send=function(_,k,v) sent[k]=v end}
Materials.configure(fake,'ivory',{yaw=0,pitch=.62},false)
assert(sent.ambientStrength>=.42 and sent.ambientStrength<=.50)
assert(sent.specularStrength<.1,'bone should not look like glossy plastic')
assert(sent.pipReliefStrength<.07,'pips should look recessed, not like marbles')
local f=assert(io.open('resources/shaders/dice_lit.glsl','r'))
local code=f:read('*a');f:close()
assert(code:find('ivoryReflectance',1,true)
 and code:find('spec * key * ivoryReflectance',1,true),
 'ivory specular must not illuminate matte black pips')
assert(not package.loaded['lib.g3d'],'pure material tests must work without GPU')
print('PASS dice screenshot refinements: thin bevel, matte pip reflection, visible contact and unchanged physics')
