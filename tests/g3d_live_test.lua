local Live=require('src.engine3d.g3d_live')
local M=require('src.engine3d.g3d_mesh')
local d6={
 faces={{1,2,3,4},{5,6,7,8},{1,2,6,5},{2,3,7,6},{3,4,8,7},{4,1,5,8}},
 faceValueMap={1,6,3,5,4,2}
}
local r=Live.new()
assert(r.width==0 and not r.g3d and r.toggle==nil,
 'g3d-only renderer must not expose the F9 painter switch')
local entries={{index=1,entry={die=d6}},{index=2,entry={die=d6}}}
assert(Live.supported(entries),'real runtime candidate format incorrectly rejected')
assert(Live.supported({{die=d6}}),'direct lab die should be supported')
local triangular={faces={},faceValueMap={}}
for i=1,8 do triangular.faces[i]={1,2,3};triangular.faceValueMap[i]=i end
assert(Live.supported({{index=1,entry={die=triangular}}}),
       'physical D8 triangle faces must be supported by g3d')
assert(not Live.supported({{index=1,entry={die={faces={{1,2,3}},faceValueMap={1}}}}}),
       'non-D6/D8 geometry must be rejected')
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
assert(not package.loaded['lib.g3d'],
       'g3d must not initialize graphics until an opted-in scene is drawn')
local shadow=Live.shadow_vertices({position={2,3,1},radius=.5},0)
assert(#shadow==72 and shadow[1][3]>.0,'contact shadows have a floor offset')
assert(shadow[1][12]>0 and shadow[2][12]==0,'soft shadow alpha fades to zero')
local moved=Live.shadow_vertices({position={2,3,1},radius=.5},2)
assert(math.abs(moved[1][1]-(shadow[1][1]-2))<1e-9,'shadow follows draw offset')
local rules=Live.page_rule_vertices({-9.2,9.2,-3.8,3.8},.85,.74)
assert(#rules==3*7*6,'seven lines on three paper edges, not the spine')
local verts=M.face_vertices({{1,1,1},{1,-1,1},{-1,-1,1},{-1,1,1},
 position={0,0,0}}, {1,2,3,4})
local original=verts[1][9]
Live.highlight_vertices(verts,true)
assert(verts[1][9]>original,'usable die gains a GPU tint')
assert(not package.loaded['lib.g3d'],'headless geometry must not load GPU')
print('PASS production g3d: default-ready, single-renderer, shadows, folio rules and highlights')

local Scene=require('src.engine3d.g3d_scenery')
for _,style in ipairs({'book','current','A','B','C'}) do
 local skin=Scene.style_vertices(M,{-9.2,9.2,-3.8,3.8},.74,style)
 assert(#skin>=4*3*8*6,'g3d renderer missing F8 style '..style)
 for _,vertex in ipairs(skin) do
  assert(vertex[9]>=0 and vertex[9]<=1,'GPU red component out of range')
  assert(vertex[10]>=0 and vertex[10]<=1,'GPU green component out of range')
  assert(vertex[11]>=0 and vertex[11]<=1,'GPU blue component out of range')
 end
 if style=='B' then assert(#skin>4*3*8*6,'countertop surround geometry missing') end
end
local divider=Scene.divider_vertices({back_x=0,front_x=.2,
 back_y=-3,front_y=3,width=.15,height=.8})
assert(#divider==30,'three-dimensional split-tray barrier incomplete')
assert(Scene.divider_vertices(nil)==nil)
local tint=Scene.face_color({faceColors={{20,50,80,255}}},1)
assert(math.abs(tint[1]-20/255)<1e-8 and math.abs(tint[3]-80/255)<1e-8)
print('PASS g3d migration: all F8 skins, split divider and D8 face colors')
