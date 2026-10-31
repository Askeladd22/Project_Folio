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
local p=Group.formation(6,1.3)
assert(#p==6)
local lower,upper=0,0
for i=1,6 do
 if p[i].z==0 then lower=lower+1 else upper=upper+1 end
 for j=i+1,6 do
  local dx,dy,dz=p[i].x-p[j].x,p[i].y-p[j].y,p[i].z-p[j].z
  assert(dx*dx+dy*dy+dz*dz>1.3*1.3-.001,
   'real 3D piled bodies must not overlap each other')
 end
end
assert(lower==3 and upper==3,'six dice should form a real 3+3 pile, not a 3x2 grid')
assert(Group.clearance(p)>1.3,'pile must have a safe 3D separation')

local dice=make_dice()
local old={}
for i,d in ipairs(dice) do old[i]={d.body.position[1],d.body.position[2]} end
local grab=assert(Group.begin(indices,dice,650,390,1,view,scale,bounds,4,610,390))
assert(grab.anchor_x>old[4][1],
 'clicked die must align with cursor-to-die screen offset')
assert(#grab.targets==6 and grab.group)
assert(grab.held[1].body._manual_pending)
-- Moving only the clock must still draw all selected bodies toward the
-- pointer; convergence is not conditioned on a mousemoved callback.
for _=1,38 do Group.tick(grab,.025) end
local averageX,averageY=0,0
for j,g in ipairs(grab.held) do
 local b,t=g.body,grab.targets[j]
 assert(math.abs(b.position[1]-t.x)<.002 and
        math.abs(b.position[2]-t.y)<.002,
        'actual held bodies must gather smoothly under pointer')
 averageX=averageX+b.position[1]/6
 averageY=averageY+b.position[2]/6
end
assert(math.abs(averageX-grab.anchor_x)<.01 and
       math.abs(averageY-grab.anchor_y)<.01,
 'gathered constellation must be centered on cursor anchor, not old formation')
assert(math.abs(dice[6].body.position[1]-dice[1].body.position[1])<4,
 'six widely scattered dice must converge into a compact group')
Group.move(grab,18000,13000,2,view,scale,bounds)
for j,t in ipairs(grab.targets) do
 assert(t.x<=bounds.half_x and t.x>=-bounds.half_x and
        t.y<=bounds.half_y and t.y>=-bounds.half_y,
 'entire group must remain within physical board')
 for k=j+1,#grab.targets do
  local u=grab.targets[k]
  local dx,dy,dz=t.x-u.x,t.y-u.y,t.z-u.z
  local r1,r2=grab.held[j].body.radius,grab.held[k].body.radius
  assert(dx*dx+dy*dy+dz*dz>(r1+r2)^2,
   'board edge clamping must never compress 3D piled dice into each other')
 end
end
local results=assert(Group.release(grab,800,500,2.1,view,scale,bounds))
assert(#results==6)
for j,r in ipairs(results) do
 local b=dice[r.index].body
 assert(not b._manual_pending and not b._grabbed and not b.asleep)
 assert(math.abs(b.position[1]-grab.targets[j].x)<1e-8)
 assert(math.abs(b.position[2]-grab.targets[j].y)<1e-8)
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
print('PASS tabletop pointer-convergence: physical gather, bounded non-overlapping release, cancel, full tray area')
