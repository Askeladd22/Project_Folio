-- Headless: GLB parsing, node transforms and Z-up conversion for static props.
local L=require('src.engine3d.g3d.glb_loader')
local ffi=require('ffi')
local function u32(n)
 return string.char(n%256,math.floor(n/256)%256,math.floor(n/65536)%256,math.floor(n/16777216)%256)
end
local floats=ffi.new('float[9]',{0,0,0, 1,0,0, 0,1,0})
local bin=ffi.string(floats,36)
local json=[[{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],
"nodes":[{"children":[1],"translation":[10,0,0]},{"mesh":0,"scale":[2,2,2]}],
"meshes":[{"primitives":[{"attributes":{"POSITION":0}}]}],
"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3"}],
"bufferViews":[{"buffer":0,"byteLength":36}],"buffers":[{"byteLength":36}]}]]
while #json%4~=0 do json=json..' ' end
local glb='glTF'..u32(2)..u32(12+8+#json+8+#bin)..u32(#json)..'JSON'..json..u32(#bin)..'BIN\0'..bin
local m=L.parse(glb)
assert(#m.verts==3,'one triangle expected')
assert(m.verts[2][1]==12 and m.verts[3][2]==2,'parent and child transforms must compose')
assert(m.min[1]==10 and m.max[1]==12 and m.max[2]==2)
L.to_z_up(m)
assert(m.verts[3][3]==2 and m.verts[3][2]==0,'glTF Y-up must become tray Z-up')
assert(not pcall(L.parse,'nope'),'invalid data must fail explicitly')
local Scenery=require('src.engine3d.g3d.scene').scenery
local box={verts={{-1.22,-.76,0,0,0,0,0,1,1,1,1,1},{1.22,.76,.88,0,0,0,0,1,1,1,1,1}},
 min={-1.22,-.76,0},max={1.22,.76,.88}}
Scenery.place_table(box,{-14,14,-6.05,6.05},.28)
assert(math.abs(box.max[3])<1e-9 and box.verts[2][3]==0,'table top must be flush with the old floor')
assert(box.min[1]<-14.28 and box.max[1]>14.28 and box.min[2]<-6.33 and box.max[2]>6.33,
 'table top must extend under the whole tray and rim')
local f=io.open('resources/models/old_wooden_table.glb','rb')
if f then
 local real=L.parse(f:read('*a'));f:close()
 assert(#real.verts==1772*3 and real.image and #real.image>1000,'sample table not parsed')
end
print('PASS GLB loader: binary chunks, accessors, node transforms, Z-up and base colour texture')
