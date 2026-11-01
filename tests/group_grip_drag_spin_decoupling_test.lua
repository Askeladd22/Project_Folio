-- Regression from Windows feedback: dragging six selected dice rolled them
-- all in the mouse direction, masking the Tabletop-style shaker.
-- In a multi-die hold TRANSLATION and SHAKE ROTATION must be independent.
local Group=require('src.features.farkle.group_throw')
local Single=require('src.features.farkle.mouse_throw')
local scene=require('src.data.dice_scene_schema')
local view={yaw=0,pitch=.48,focus=5,distance=14.1}
local function build(count)
 local dice,indices={},{}
 for i=1,count do
  local body={position={-3+(i-1)*1.15,(i%2==0) and .75 or -.75,1.1},
    velocity={0,0,0},angular={0,0,0},radius=.52,
    asleep=true,sleep_timer=0,_manual_pending=true,
    {1,1,1},{-1,-1,-1}}
  function body:update(dt)
   for _,vertex in ipairs(self) do
    vertex[1]=vertex[1]+dt*self.angular[2]
    vertex[2]=vertex[2]+dt*self.angular[1]
   end
  end
  dice[i]={body=body,kept=false}
  indices[i]=i
 end
 return dice,indices
end
local function norm(t)
 local total=0
 for _,member in ipairs(t.held) do
  local b=member.body
  total=total+math.abs(b.angular[1])+math.abs(b.angular[2])
   +math.abs(b.angular[3])
 end
 return total
end
for count=2,6 do
 local dice,indices=build(count)
 local g=assert(Group.begin(indices,dice,160,200,0,view,25,scene.box,1,160,200))
 for i,m in ipairs(g.held) do
  assert(m.group_hold and m.angular[1]==0 and m.angular[2]==0 and
   m.angular[3]==0,'group grip must begin without forced single-pointer spin')
 end
 local first=dice[1].body.position[1]
 for i=1,7 do
  local x=160+i*21
  assert(Group.move(g,x,200,i*.08,view,25,scene.box))
  for _=1,3 do Group.tick(g,.016) end
 end
 assert(dice[1].body.position[1]~=first,
  'the held physical dice must still follow the moving hand')
 assert(g.shaker.events==0 and g.shaker.energy==0,
  'one-direction dragging is not a shake')
 assert(norm(g)<1e-9,
  'plain group mouse drag must NOT impose rotational velocity')
 for _,member in ipairs(g.held) do
  local v=member.body[1]
  assert(v[1]==1 and v[2]==1,
   'plain mouse drag must not roll actual die vertices')
 end
 -- Two fast direction reversals cause genuine independent shake.
 local baseline=g.x
 for i,x in ipairs{baseline-60,baseline,baseline-60} do
  Group.move(g,x,200,.65+i*.09,view,25,scene.box)
  Group.tick(g,.018)
 end
 assert(g.shaker.events>=1,'two reversals must enable shake')
 assert(norm(g)>.1,'shake must now rotate physical dice')
 local distinct=false
 for i=2,#g.held do
  if math.abs(g.held[i].body.angular[1]-g.held[1].body.angular[1])>.001 then
   distinct=true
  end
 end
 assert(distinct,'shaker must not assign a single identical rotation to all D6')
 for _=1,130 do Group.tick(g,.016) end
 assert(g.shaker.energy<.02,'shaker must stop after hand becomes still')
 assert(norm(g)<.8,'held-group spin should settle after shaking ceases')
 -- Esc must restore each genuine body, regardless of the shaking.
 Group.cancel(g)
 for _,member in ipairs(g.held) do
  assert(member.body._manual_pending and not member.body._grabbed)
 end
end
-- The existing single-die pointer motion deliberately remains unchanged.
local one=build(1)
local single=assert(Single.begin(1,one[1].body,100,100,0))
assert(not single.group_hold)
Single.move(single,170,120,.10,view,25,scene.box)
assert(math.abs(single.angular[1])>2 or math.abs(single.angular[2])>2,
 'individual die handling must keep its original drag rotation')
Single.cancel(single)
print('PASS group drag/shake decoupling: movement without roll, independent shake tumble, quiet recovery, single-die unchanged')
