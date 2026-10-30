local Live=require('src.engine3d.g3d_live')
local M=require('experiments.g3d_lab.mesh')
local d6={
 faces={{1,2,3,4},{5,6,7,8},{1,2,6,5},{2,3,7,6},{3,4,8,7},{4,1,5,8}},
 faceValueMap={1,6,3,5,4,2}
}
local r=Live.new()
assert(r.enabled and not r.failed and r.width==0 and not r.g3d)
assert(r:toggle()==false and r:toggle()==true)
local entries={{index=1,entry={die=d6}},{index=2,entry={die=d6}}}
assert(Live.supported(entries),'real runtime candidate format incorrectly rejected')
assert(Live.supported({{die=d6}}),'direct lab die should be supported')
assert(not Live.supported({{index=1,entry={die={faces={{1,2,3}},faceValueMap={1}}}}}),
       'D8 or triangle face must always use the old renderer')
assert(not Live.supported({{index=1,entry={die={faces={},faceValueMap={}}}}}),
       'empty dice entry must never enter GPU')
local verts=Live.rim_vertices(M,{-9.2,9.2,-3.8,3.8},.85,.74)
assert(#verts==4*3*8*6,'book rim dimensions and tessellation')
local first=verts[1]
local spine=verts[(3*3)*8*6+1]
assert(math.abs(first[9]-.76)<1e-9 and math.abs(first[10]-.67)<1e-9,
       'book page block default palette')
assert(math.abs(spine[9]-.26)<1e-9 and math.abs(spine[10]-.12)<1e-9,
       'left binding must retain original dark spine')
assert(not package.loaded['experiments.g3d_lab.g3d'],
       'g3d must not initialize graphics until an opted-in scene is drawn')
print('PASS opt-in live g3d: D6-only gate, reversible toggle, book rim and lazy renderer')
