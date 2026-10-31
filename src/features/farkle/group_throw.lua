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
 return math.max(1.12,2*radius+.16)
end

-- Pack into a compact, non-overlapping constellation centered on the hand.
-- Each die has its own real-body pose, orientation and later trajectory.
function G.formation(count,spacing)
 assert(type(count)=='number' and count>=2 and count%1==0)
 spacing=spacing or 1.2
 local cols=math.min(3,math.ceil(math.sqrt(count)))
 local rows=math.ceil(count/cols)
 local offsets={}
 for n=1,count do
  local row=math.floor((n-1)/cols)
  local rowCount=math.min(cols,count-row*cols)
  local col=(n-1)%cols
  offsets[n]={x=(col-(rowCount-1)*.5)*spacing,
              y=(row-(rows-1)*.5)*spacing}
 end
 return offsets
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
  targets[j]={x=cx+off.x,y=cy+off.y,
   z=math.max(2.35,math.min(4.0,member.original.position[3]+1.3))}
 end
 g.x,g.y=x,y
 g.targets=targets
 return true
end

function G.tick(g,dt)
 if not g or not g.group or not dt or dt<=0 then return end
 -- Convergence runs even when the pointer is motionless after right-click.
 -- The held physics bodies, not merely their meshes, fly toward the hand.
 local alpha=1-math.exp(-math.min(dt,.05)*18)
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
