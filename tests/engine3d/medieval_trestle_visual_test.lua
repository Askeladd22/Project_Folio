-- Visual-only trestle and opposing score rails: no gameplay changes.
local SC=require('src.engine3d.g3d.scene').scenery
local L=require('src.farkle.ui').layout
local M=require('resources.models.old_wooden_table_fallback')
local Table=require('src.farkle.tabletop').tray_workshop
local Scene=require('src.data.dice_schema').scene
local layout=L.build()
assert(L.validate(layout))
assert(layout.score_panel.x==38 and layout.opponent_panel.x==1342)
assert(L.overlap(layout.score_panel,layout.opponent_panel)==0)
assert(L.overlap(layout.opponent_panel,layout.runmenu)==0)
assert(L.overlap(layout.opponent_panel,layout.tray)==0)
assert(Table.current=='old_wooden')
assert(M.finish.plank_tints[1]<.60 and M.finish.plank_tints[2]<.60,
 'the fallback must no longer use pale amber tabletop')
local ext={-14,14,-6.05,6.05}
local mesh=M.mesh(ext)
assert(#mesh.verts>300 and #mesh.verts%3==0,
 'tavern trestles need real decorative geometry')
local minz,maxz=math.huge,-math.huge
local avg=0
for _,v in ipairs(mesh.verts) do
 assert(#v==12 and v[1]>=ext[1]-1e-6 and v[1]<=ext[2]+1e-6
  and v[2]>=ext[3]-1e-6 and v[2]<=ext[4]+1e-6,
  'wood geometry escaped the physical D6 table')
 minz=math.min(minz,v[3]);maxz=math.max(maxz,v[3])
 if v[3]>-.01 and v[8]>.95 then avg=avg+v[9] end
end
assert(minz< -1.5 and maxz<=.003+1e-5 and avg>0,
 'table support or visible dark top disappeared')
local receiver=SC.floor_vertices(require('src.engine3d.g3d.scene').mesh,ext,'old_wooden')
assert(receiver[1][9]<.40,'under-table receiver remains too pale')
assert(Scene.regions.unified.half_back==14 and
 Scene.regions.unified.y_back==-6.05 and Scene.box.border_height==.74,
 'visual change altered physical D6 bounds')
print('PASS dark walnut trestle, opposing ledgers and untouched physical table')
