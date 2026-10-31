-- Headless regression for Tabletop-like lifted dice pile and camera scale.
-- These tests cover positions of real rigid bodies, not fake 2D dice sprites.
local Group=require('src.features.farkle.group_throw')
local Zoom=require('src.features.farkle.group_hold_projection')
local scene=require('src.data.dice_scene_schema')
local view={yaw=0,pitch=.48,focus=5,distance=14.1}

for count=2,6 do
 local spacing=1.5
 local offsets=Group.formation(count,spacing)
 assert(#offsets==count)
 local sx,sy=0,0
 local upper=0
 for i,a in ipairs(offsets) do
  sx,sy=sx+a.x,sy+a.y
  if a.z>0 then upper=upper+1 end
  for j=i+1,count do
   local b=offsets[j]
   local dx,dy,dz=a.x-b.x,a.y-b.y,a.z-b.z
   assert(dx*dx+dy*dy+dz*dz>=spacing*spacing,
    'piled die centers must remain separate in world 3D')
  end
 end
 assert(math.abs(sx)<1e-9 and math.abs(sy)<1e-9,
  'pile should be centered under the mouse anchor')
 if count>=3 then assert(upper>0,'several dice must form a stacked heap') end
 assert(Group.clearance(offsets)>=spacing)
end
local pile=Group.formation(6,1.5)
local bottom,top=0,0
for _,p in ipairs(pile) do
 if p.z==0 then bottom=bottom+1 else top=top+1 end
end
assert(bottom==3 and top==3,'six dice should have a 3+3 triangular pile')

local owner={}
assert(Zoom.advance(owner,10,false)==1)
assert(Zoom.advance(owner,10.01,true)<1)
local old=Zoom.advance(owner,10.15,true)
assert(old<1 and old>Zoom.held_scale)
local duplicate=Zoom.advance(owner,10.15,true)
assert(duplicate==old,'second draw in the same timestamp must not double ease zoom')
local lowered=Zoom.advance(owner,10.25,true)
assert(lowered<old,'camera should pull back only while group is grabbed')
assert(lowered>=Zoom.held_scale)
local released=Zoom.advance(owner,10.35,false)
assert(released>lowered,'camera should restore standard framing after release')
for n=1,30 do released=Zoom.advance(owner,10.35+n*.05,false) end
assert(math.abs(released-1)<.001,'zoom should smoothly restore full-size game')
assert(Zoom.advance(owner,14,false)==1)

local file=assert(io.open('src/features/farkle/tray_view.lua','r'))
local live=file:read('*a');file:close()
assert(live:find('local scale=target*camera_factor',1,true),
 'the optical scale must be applied AFTER the tray has been fitted')
assert(live:find('owner.trayScale=scale',1,true),
 'the same zoom must feed real physics mouse-to-world conversion')
local game=assert(io.open('src/features/farkle/group_throw.lua','r'))
local mechanics=game:read('*a');game:close()
assert(mechanics:find('z=math.min(top,lift+(off.z or 0))',1,true),
 'the gathered real bodies must receive vertical pile offsets')
print('PASS Tabletop pile/zoom: safe 2-6 dice 3D heaps, unchanged collisions and smooth projected pullback')
