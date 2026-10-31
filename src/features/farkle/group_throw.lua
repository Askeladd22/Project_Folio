-- Tabletop-style group grip. Selected REAL die bodies converge toward
-- the pointer and tumble while held, then all enter normal physics on release.
-- This is one official Farkle roll; queued/kept dice remain excluded.
local Single=require('src.features.farkle.mouse_throw')
local G={}
local function clamp(x,a,b)
 if a>b then return (a+b)*.5 end
 return math.max(a,math.min(b,x))
end
local function camera(view)
 return view or {yaw=0,pitch=.48,focus=5,distance=14.1}
end
local function spacing_for(held)
 local radius=0
 for _,g in ipairs(held) do
  radius=math.max(radius,g.body.radius or .52)
 end
 -- The solver uses spherical collision separation. Never squeeze actual
 -- rigid bodies merely to create a visually convincing pile.
 return math.max(1.12,2*radius+.18)
end

-- Deliberately irregular TWO-LEVEL heap, not an evenly spaced 3x2 grid.
-- The templates are in *collision spacing* units. All die centers remain
-- separated in 3D, so stacked dice neither interpenetrate while held nor
-- burst apart violently on release. D6 is a 3 + 3 triangular pile.
local layouts={
 [2]={{-.58,0,0},{.58,0,0}},
 [3]={{-.60,-.22,0},{.60,-.22,0},{0,.20,1.08}},
 [4]={{-.78,-.35,0},{.78,-.35,0},{0,.82,0},{0,-.07,1.15}},
 [5]={{-.78,-.35,0},{.78,-.35,0},{0,.82,0},
       {-.55,-.05,1.15},{.55,-.05,1.15}},
 [6]={{-.78,-.35,0},{.78,-.35,0},{0,.82,0},
       {-.66,.20,1.10},{.66,.20,1.10},{0,-.83,1.13}}
}
function G.formation(count,spacing)
 assert(type(count)=='number' and count>=2 and count%1==0)
 spacing=spacing or 1.2
 local preset=layouts[count]
 -- Support future larger groups without modifying the six-die gameplay:
 -- keep a conservative, separated grid for unsupported counts.
 if not preset then
  local cols=math.min(3,math.ceil(math.sqrt(count)))
  local rows=math.ceil(count/cols)
  preset={}
  for n=1,count do
   local row=math.floor((n-1)/cols)
   local rowCount=math.min(cols,count-row*cols)
   local col=(n-1)%cols
   preset[n]={(col-(rowCount-1)*.5)*1.15,(row-(rows-1)*.5)*1.15,0}
  end
 end
 local meanX,meanY=0,0
 for _,p in ipairs(preset) do meanX=meanX+p[1];meanY=meanY+p[2] end
 meanX,meanY=meanX/#preset,meanY/#preset
 local offsets={}
 for i,p in ipairs(preset) do
  offsets[i]={x=(p[1]-meanX)*spacing,
              y=(p[2]-meanY)*spacing,
              z=p[3]*spacing}
 end
 return offsets
end
-- Exposed as a pure 3-D invariant for experiments; no engine or RNG access.
function G.clearance(offsets)
 local minimum=math.huge
 for i=1,#offsets do for j=i+1,#offsets do
  local a,b=offsets[i],offsets[j]
  local dx,dy,dz=a.x-b.x,a.y-b.y,(a.z or 0)-(b.z or 0)
  minimum=math.min(minimum,math.sqrt(dx*dx+dy*dy+dz*dz))
 end end
 return minimum
end

-- anchor_index is the die right-clicked, not necessarily the smallest ID
-- in the selection. The cursor-to-picked-center offset avoids a hand jump.
function G.begin(indices,dice,x,y,time,view,scale,bounds,anchor_index,hit_x,hit_y)
 if type(indices)~='table' or #indices<2 or type(dice)~='table' then return nil end
 local held={}
 for _,index in ipairs(indices) do
  local entry=dice[index]
  if not entry or not entry.body or entry.kept or entry.body._grabbed or
     not entry.body._manual_pending then
   for _,g in ipairs(held) do Single.cancel(g) end
   return nil
  end
  local gesture=Single.begin(index,entry.body,x,y,time)
  if not gesture then
   for _,g in ipairs(held) do Single.cancel(g) end
   return nil
  end
  held[#held+1]=gesture
 end
 local picked=dice[anchor_index or indices[1]] or dice[indices[1]]
 local ax,ay=picked.body.position[1],picked.body.position[2]
 if hit_x and hit_y then
  local wx,wy=Single.world_motion(x-hit_x,y-hit_y,camera(view),scale)
  ax,ay=ax+wx,ay+wy
 end
 local g={group=true,index=indices[1],indices=indices,held=held,
  x0=x,y0=y,x=x,y=y,anchor_x=ax,anchor_y=ay,
  offsets=G.formation(#held,spacing_for(held)),targets={}}
 G.move(g,x,y,time,view,scale,bounds)
 return g
end

function G.move(g,x,y,time,view,scale,bounds)
 if not g or not g.group then return false end
 local dx,dy=Single.world_motion(x-g.x0,y-g.y0,camera(view),scale)
 local cx,cy=g.anchor_x+dx,g.anchor_y+dy
 local limx=(bounds and bounds.half_x or 9.2)
 local limy=(bounds and bounds.half_y or 3.8)
 -- Clamp the *whole* constellation against the physical board, not each
 -- body separately. This preserves spacing and prevents stacked dice.
 local loX,hiX,loY,hiY=-math.huge,math.huge,-math.huge,math.huge
 for j,member in ipairs(g.held) do
  local off=g.offsets[j]
  local pad=math.max(.42,(member.body.radius or .52)*.90)
  loX=math.max(loX,-limx+pad-off.x)
  hiX=math.min(hiX,limx-pad-off.x)
  loY=math.max(loY,-limy+pad-off.y)
  hiY=math.min(hiY,limy-pad-off.y)
 end
 cx,cy=clamp(cx,loX,hiX),clamp(cy,loY,hiY)
 local targets={}
 for j,member in ipairs(g.held) do
  if not Single.track(member,x,y,time) then return false end
  local off=g.offsets[j]
  -- Layering is real 3D displacement. Preserve a high enough hand pose
  -- that every upper die remains below the ceiling, even with large dice.
  local top=(bounds and bounds.height or 10)-.85
  local lift=math.max(2.35,math.min(4.0,member.original.position[3]+1.3))
  targets[j]={x=cx+off.x,y=cy+off.y,
   z=math.min(top,lift+(off.z or 0))}
 end
 g.x,g.y=x,y
 g.targets=targets
 return true
end

function G.tick(g,dt)
 if not g or not g.group or not dt or dt<=0 then return end
 -- Convergence runs even when the pointer is motionless after right-click.
 -- The held physics bodies, not merely their meshes, fly toward the hand.
 local alpha=1-math.exp(-math.min(dt,.05)*20)
 for i,member in ipairs(g.held) do
  local pos=member.body.position
  local target=g.targets[i]
  if target then
   pos[1]=pos[1]+(target.x-pos[1])*alpha
   pos[2]=pos[2]+(target.y-pos[2])*alpha
   pos[3]=pos[3]+(target.z-pos[3])*alpha
  end
  Single.tick(member,dt)
 end
end

function G.cancel(g)
 if not g or not g.group then return end
 for _,member in ipairs(g.held) do Single.cancel(member) end
end

function G.release(g,x,y,time,view,scale,bounds)
 if not g or not g.group then return nil end
 if not G.move(g,x,y,time,view,scale,bounds) then return nil end
 -- Release from the gathered formation even after a very fast click. Do not
 -- let Single.release teleport the body back to its original scattered spot.
 local poses=g.targets
 local results={}
 for i,member in ipairs(g.held) do
  local released=Single.release(member,x,y,time,camera(view),scale,bounds)
  if not released then return nil end
  local target=poses[i]
  member.body.position[1]=target.x
  member.body.position[2]=target.y
  member.body.position[3]=target.z
  results[#results+1]=released
 end
 return results
end
return G
