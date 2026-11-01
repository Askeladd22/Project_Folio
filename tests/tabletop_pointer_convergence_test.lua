local Group=require('src.features.farkle.group_throw')
local Single=require('src.features.farkle.mouse_throw')
local scene=require('src.data.dice_scene_schema')
local view={yaw=0,pitch=.48,focus=5,distance=14.1}
local scale=26
local bounds=scene.box

local function make_dice()
 local dice={}
 for i=1,6 do
  local b={position={-7+i*2,((i%2)==0 and 2 or -2),.8},
   velocity={0,0,0},angular={0,0,0},radius=.55,
   asleep=false,sleep_timer=0,
   {1,1,1},{-1,-1,-1}}
  function b:update(dt) for _,v in ipairs(self) do v[1]=v[1]+dt*self.angular[2] end end
  b._manual_pending=true
  dice[i]={body=b,kept=false}
 end
 return dice
end
local indices={1,2,3,4,5,6}
local dice=make_dice()
local old={}
for i,d in ipairs(dice) do old[i]={d.body.position[1],d.body.position[2]} end
local grab=assert(Group.begin(indices,dice,650,390,1,view,scale,bounds,4,610,390))
assert(grab.anchor_x>old[4][1],
 'clicked die must align with cursor-to-die screen offset')
assert(grab.hand and #grab.held==6 and #grab.hold_velocity==6 and grab.group)
assert(grab.held[1].body._manual_pending)
-- No mouse movement: spring attraction still gathers six independent bodies.
for _=1,90 do Group.tick(grab,.025) end
local averageX,averageY=0,0
local gathered={}
for j,g in ipairs(grab.held) do
 local p=g.body.position
 gathered[j]={x=p[1],y=p[2],z=p[3]}
 averageX=averageX+p[1]/6
 averageY=averageY+p[2]/6
end
assert(math.abs(averageX-grab.hand.x)<2.5 and
       math.abs(averageY-grab.hand.y)<2.5,
 'FPS-style spring must bring the cluster near the hand')
assert(Group.clearance(gathered)>.35,
 'temporary held-stage contacts must keep real dice distinct')
Group.move(grab,18000,13000,2,view,scale,bounds)
for _=1,60 do Group.tick(grab,.025) end
local before={}
for j,member in ipairs(grab.held) do
 local p=member.body.position
 assert(p[1]<=bounds.half_x and p[1]>=-bounds.half_x and
        p[2]<=bounds.half_y and p[2]>=-bounds.half_y,
 'all physical dice must respect tray walls during moving grip')
 before[j]={p[1],p[2],p[3]}
end
local results=assert(Group.release(grab,800,500,2.1,view,scale,bounds))
assert(#results==6)
for j,r in ipairs(results) do
 local b=dice[r.index].body
 assert(not b._manual_pending and not b._grabbed and not b.asleep)
 assert(math.abs(b.position[1]-before[j][1])<1e-8 and
  math.abs(b.position[2]-before[j][2])<1e-8,
  'physical release must preserve actual spring/contact pose')
 assert(b.velocity[3]<0,'group release must restore gravity')
end
-- Cancel must undo convergence for all selected die bodies.
local retry=make_dice()
local again=Group.begin(indices,retry,500,340,3,view,scale,bounds,3,500,340)
for _=1,30 do Group.tick(again,.025) end
Group.cancel(again)
for i,entry in ipairs(retry) do
 local b=entry.body
 assert(b.position[1]==old[i][1] and b.position[2]==old[i][2],
  'Esc must restore each scattered physical position')
 assert(b._manual_pending and not b._grabbed)
end
-- The visible parchment and dynamic physical region must agree.
local region=scene.regions.unified
assert(region.half_back>=8.5 and region.half_front>=8.5,
 'full-width dice tray must not retain invisible narrow x boundaries')
assert(region.y_back<=-3.5 and region.y_front>=3.5,
 'full-width dice tray must use the majority of visible floor in y')
assert(region.half_back<bounds.half_x and region.y_front<bounds.half_y,
 'region must remain inside the real physical box walls')
local f=assert(io.open('src/app/dice_runtime.lua','r'))
local runtime=f:read('*a');f:close()
assert(runtime:find('return Scriptorium.tray_divided == true',1,true),
 'undivided full-width Farkle tray must be the default')
assert(not runtime:find('Scriptorium.tray_divided ~= false',1,true),
 'an unset divider flag must not silently restrict the D6 lane')
print('PASS tabletop pointer-convergence: FPS-inspired elastic real-body grip, release, cancel, full tray area')
