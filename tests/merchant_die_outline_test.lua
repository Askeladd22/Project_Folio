-- Screen geometry is shared by the outline and production pointer picking.
-- Project the two layers of a turned die onto a diamond; the envelope is
-- not an axis-aligned box or a circle centered at its physical position.
local P=require('src.engine3d.projected_die')
local faces={{1,2,3,4},{5,6,7,8},{1,2,6,5},{2,3,7,6},{3,4,8,7},{4,1,5,8}}
local body={position={2,3,0}}
for _,z in ipairs{-1,1} do
 for _,xy in ipairs{{-2,0},{0,-1},{2,0},{0,1}} do
  body[#body+1]={xy[1],xy[2],z}
 end
end
local function project(x,y,z) return x,y-z*.5,-12+z end
local h=P.from_body(3,body,project,100,100,10,faces,false)
assert(h.x==120 and h.y==130 and h.index==3 and #h.outline==12,
 'silhouette must follow camera, viewport origin, and all transformed cube corners')
assert(P.pick({h},120,130)==3 and P.pick({h},139,130)==3)
assert(P.pick({h},139,143)==nil,
 'empty space inside the projected bounding box is not the die')
body.position={2,3.5,1} -- closer, with the same orthographic silhouette
local near=P.from_body(4,body,project,100,100,10,faces,false)
assert(P.pick({near,h},120,130)==4 and P.pick({h,near},120,130)==4,
 'the visible die wins independent of iteration order')

-- Two separated, grounded D6 at the right side of the merchant table.
-- At this pixel the camera sees the top of die 2 before the side of die 1,
-- even though die 1's centre is nearer according to camera-space Z.
local view=require('src.engine3d.view')
local camera=require('src.data.dice_scene_schema').tray_camera
view.yaw,view.pitch,view.distance=camera.yaw,camera.pitch,camera.distance
view.cos_yaw,view.sin_yaw=math.cos(view.yaw),math.sin(view.yaw)
view.cos_pitch,view.sin_pitch=math.cos(view.pitch),math.sin(view.pitch)
view.projection='perspective'
local function settled(index,x,y)
 local b={position={x,y,.47}}
 for _,z in ipairs{.47,-.47} do
  for _,xy in ipairs{{.47,.47},{.47,-.47},{-.47,-.47},{-.47,.47}} do
   b[#b+1]={xy[1],xy[2],z}
  end
 end
 return P.from_body(index,b,view.project,0,0,1000,faces,true)
end
local side,top=settled(1,8.96,.03),settled(2,8,0)
assert(P.pick({side},890,-40)==1 and P.pick({top},890,-40)==2,'fixture needs two overlapping hulls')
assert(P.pick({side,top},890,-40)==2 and P.pick({top,side},890,-40)==2,
 'the visible top face must win over the neighboring die with the nearer centre')
local Model=require('src.features.farkle.ui_v2.overlay_model')
local R=require('src.gameplay.farkle.rules')
local game=R.new()
assert(R.start(game) and R.settle(game,{3,3,3,2,4,6}))
local function marker(hover)
 return Model.build({game=game},{h},hover).markers[1]
end
assert(marker(nil).kind=='eligible' and not marker(nil).hovered)
assert(marker(3).hovered and marker(3).outline==h.outline,
 'hover attaches to the exact projected die rather than an estimated radius')
assert(R.toggle(game,3))
assert(marker(nil).kind=='partial' and not marker(nil).hovered)
assert(R.toggle(game,1) and R.toggle(game,2))
assert(marker(nil).kind=='score' and marker(nil).outline==h.outline,
 'moving the pointer away must leave the complete selection indicated')
-- Inspect screen-space strokes emitted by the real painter: hover and
-- selection must follow the silhouette, including when the pointer leaves.
local Overlay=require('src.features.farkle.ui_v2.overlay')
local Bridge=require('src.core.engine_bridge')
local x,y,contours=0,0,{}
local function capture(mode,polygon)
 if mode=='line' then contours[#contours+1]=polygon end
end
love={mouse={getPosition=function() return x,y end},graphics={
 push=function()end,pop=function()end,setColor=function()end,
 setLineWidth=function()end,line=function()end,polygon=capture}}
Bridge.configure({pick_scriptorium_tray_die=function(mx,my) return P.pick({h},mx,my) end})
local function outline_painted()
 contours={}
 Overlay.draw({game=game},{h})
 for _,outline in ipairs(contours) do
  if outline==h.outline then return true end
 end
 return false
end
assert(outline_painted(),'selected contour must remain after pointer exit')
assert(R.toggle(game,1) and R.toggle(game,2) and R.toggle(game,3))
assert(outline_painted(),'passive eligibility must have a subtle cube outline instead of the under-die dash')
x,y=120,130
assert(outline_painted(),'pointer over a scoring die must trace its projected edges')
assert(not next(game.selected) and game.pot==0,'hover must not change the game')
assert(R.toggle(game,1) and R.toggle(game,2) and R.toggle(game,3))
assert(R.take(game))
assert(marker(3)==nil,'spent dice have no scoring hover or highlight')
print('PASS silhouette picking, frontmost overlap, group-only hover and persistent selection')
