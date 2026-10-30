-- Multi-die grip built on real physical MouseThrow bodies. No fake mesh
-- offsets, solver replacement or extra Farkle logical rolls.
local Single=require('src.features.farkle.mouse_throw')
local G={}
local function within(v,min,max)
 if min>max then return (min+max)*.5 end
 return math.max(min,math.min(max,v))
end


function G.begin(indices,dice,x,y,time)
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
 return {group=true,index=indices[1],indices=indices,held=held,
  x0=x,y0=y,x=x,y=y}
end

function G.move(g,x,y,time,view,scale,bounds)
 if not g or not g.group then return false end
 g.x,g.y=x,y
 -- Translate the entire group as a rigid formation. Individually clamping
 -- each die at the board rim would squeeze them into overlapping positions.
 local tx,ty=Single.world_motion(x-g.x0,y-g.y0,view,scale)
 local lowX,highX,lowY,highY=-math.huge,math.huge,-math.huge,math.huge
 for _,member in ipairs(g.held) do
  local b=member.body
  local pad=math.max(.4,(b.radius or .5)*.7)
  local hw=(bounds and bounds.half_x or 9.2)-pad
  local hh=(bounds and bounds.half_y or 3.8)-pad
  local start=member.original.position
  lowX=math.max(lowX,-hw-start[1]);highX=math.min(highX,hw-start[1])
  lowY=math.max(lowY,-hh-start[2]);highY=math.min(highY,hh-start[2])
 end
 tx=within(tx,lowX,highX)
 ty=within(ty,lowY,highY)
 for _,member in ipairs(g.held) do
  if not Single.move(member,x,y,time,view,scale,bounds) then return false end
  member.body.position[1]=member.original.position[1]+tx
  member.body.position[2]=member.original.position[2]+ty
 end
 return true
end

function G.tick(g,dt)
 if not g or not g.group then return end
 for _,member in ipairs(g.held) do Single.tick(member,dt) end
end

function G.cancel(g)
 if not g or not g.group then return end
 for _,member in ipairs(g.held) do Single.cancel(member) end
end

function G.release(g,x,y,time,view,scale,bounds)
 if not g or not g.group then return nil end
 -- Each die is released from its own moved physical position, with the
 -- same gesture velocity. Distinct original positions maintain spacing.
 if not G.move(g,x,y,time,view,scale,bounds) then return nil end
 local positions={}
 for j,member in ipairs(g.held) do
  positions[j]={member.body.position[1],member.body.position[2]}
 end
 local results={}
 for j,member in ipairs(g.held) do
  local released=Single.release(member,x,y,time,view,scale,bounds)
  if not released then return nil end
  -- Single.release refreshes its own position once. Restore the clamped
  -- *group* translation while preserving its release velocity and spin.
  member.body.position[1],member.body.position[2]=positions[j][1],positions[j][2]
  results[#results+1]=released
 end
 return results
end
return G
