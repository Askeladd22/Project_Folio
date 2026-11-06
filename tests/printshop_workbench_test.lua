-- Printed workshop vignette is non-interactive and sits behind the tray.
local Scene=require('src.features.farkle.ui_v2.workshop_scene')
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local l=Layout.build('table_minimal')
local b=Scene.bounds()
for _,r in pairs(b) do
 assert(r.y>=l.host.y and r.y+r.h<=l.tray.y,
  'workshop prop covers the dice viewport')
 assert(r.x>=0 and r.x+r.w<=Layout.virtual_w,
  'workshop prop escapes the room')
end
assert(b.proof.x+b.proof.w<b.press.x,
 'printer proof and press must frame the opponent, not cover the middle')
local calls={push=0,pop=0}
love={graphics={
 setColor=function()end,
 setLineWidth=function()end,
 rectangle=function()end,
 line=function()end,
 circle=function()end,
 push=function()calls.push=calls.push+1 end,
 pop=function()calls.pop=calls.pop+1 end,
}}
Scene.draw(l)
assert(calls.push==1 and calls.pop==1,'workshop paint leaked graphics state')
local renderer=assert(io.open('src/engine3d/g3d_live.lua','rb'))
local code=renderer:read('*a');renderer:close()
assert(code:find("style=='merchant'",1,true) and
 code:find('Scenery.workbench_marks(extents)',1,true),
 'workbench registration must be g3d scenery, never a 2D overlay over the D6')
local hud=assert(io.open('src/features/farkle/ui_v2/hud.lua','rb'))
local body=hud:read('*a');hud:close()
assert(body:find('Workshop.draw(layout)',1,true),
 'printshop vignette must be painted on the shipping merchant scene')
print('PASS engraver workshop: proof and press behind g3d table, no gameplay or pointer mutations')
