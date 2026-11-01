-- Regression for the physical group-grip pile seen in the 2026-11-01
-- Windows review: six real D6 used to stack on top of one another.
-- The hand formation must stay separated IN PROJECTION, not merely in 3D.
local G=require('src.features.farkle.group_throw')

local function screen_clearance(offsets,pitch)
 local minimum=math.huge
 for i=1,#offsets do
  for j=i+1,#offsets do
   local a,b=offsets[i],offsets[j]
   local dx=a.x-b.x
   local dy=(a.y-b.y)*math.cos(pitch)-(a.z-b.z)*math.sin(pitch)
   minimum=math.min(minimum,math.sqrt(dx*dx+dy*dy))
  end
 end
 return minimum
end
-- Current production radius is sampled at grab time. These spans include
-- smaller/larger held dice without changing any die's size or collision data.
for _,spacing in ipairs{1.12,1.35,1.65} do
 for count=2,6 do
  local formation=G.formation(count,spacing)
  assert(#formation==count)
  assert(G.clearance(formation)>=spacing*1.42,
   'group must be collision-separated in world space')
  for _,pitch in ipairs{0,.48,.62} do
   assert(screen_clearance(formation,pitch)>=spacing*1.23,
    'held dice overlap in screen-space projection: count='..count..
      ', pitch='..pitch)
  end
  local minz,maxz=math.huge,-math.huge
  local meanx,meany=0,0
  for _,v in ipairs(formation) do
   minz=math.min(minz,v.z)
   maxz=math.max(maxz,v.z)
   meanx,meany=meanx+v.x,meany+v.y
  end
  assert(maxz-minz<1e-9,'old two-tier heap returned')
  assert(math.abs(meanx)<1e-9 and math.abs(meany)<1e-9,
   'grip must stay centered on the pointer')
 end
end
local six=G.formation(6,1.12)
local xs={}
for i,v in ipairs(six) do xs[i]=v.x end
assert(xs[1]<xs[2] and xs[2]<xs[3],
 'first three dice should occupy distinct hand columns')
assert(xs[4]<xs[5] and xs[5]<xs[6],
 'second row should occupy distinct hand columns')
assert(math.abs(six[1].y-six[4].y)>1.12,
 'separate rows are essential for visibility in the pitched camera')
-- Stable deterministic layout: no RNG introduced into actual physical roll.
local again=G.formation(6,1.12)
for i,p in ipairs(six) do
 assert(p.x==again[i].x and p.y==again[i].y and p.z==again[i].z)
end
print('PASS group-grip fan: 2-6 physical dice with readable screen clearance, no stacking, stable offsets and centered hand')
