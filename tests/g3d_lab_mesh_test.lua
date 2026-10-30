local Lab=require('experiments.g3d_lab.mesh')
local cube={
 {1,1,1},{1,-1,1},{-1,-1,1},{-1,1,1},
 {1,1,-1},{1,-1,-1},{-1,-1,-1},{-1,1,-1},
 position={2,-3,4}
}
local faces={{1,2,3,4},{5,6,7,8},{1,2,6,5},{2,3,7,6},{3,4,8,7},{4,1,5,8}}
local pip={1,6,3,5,4,2}
for i,face in ipairs(faces) do
 local vertices=Lab.face_vertices(cube,face)
 assert(#vertices==6,'must triangulate each physical quad')
 assert(Lab.pip(i,{faceValueMap=pip})==pip[i],'pip-to-physical-face mapping changed')
 local v=vertices[1]
 local center={0,0,0}
 for _,idx in ipairs(face) do
  for axis=1,3 do center[axis]=center[axis]+cube[idx][axis]/4 end
 end
 local dot=v[6]*center[1]+v[7]*center[2]+v[8]*center[3]
 assert(dot>0.99,'face normal must point outward')
 for _,index in ipairs{1,2,3,4,5,6} do
  local out=vertices[index]
  assert(#out==12,'g3d vertex format must match x/y/z uv normal and color')
  assert(out[6]==v[6] and out[7]==v[7] and out[8]==v[8],'face normal differs within quad')
  for channel=9,11 do assert(out[channel]>=0 and out[channel]<=1) end
 end
 assert(v[1]==cube[face[1]][1]+2 and
        v[2]==cube[face[1]][2]-3 and
        v[3]==cube[face[1]][3]+4,'translation must preserve physical vertices')
end
local flat=Lab.floor_vertices(-4,4,-2,2)
assert(#flat==6 and flat[1][3]==0 and flat[1][8]==1)
print('PASS renderer A/B pure geometry: correct D6 UVs, 3D vertex mapping, outward normals')
