-- Multi-die grip built on real physical MouseThrow bodies. No fake mesh
-- offsets, solver replacement or extra Farkle logical rolls.
local Single=require('src.features.farkle.mouse_throw')
local G={}

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
 for _,member in ipairs(g.held) do
  if not Single.move(member,x,y,time,view,scale,bounds) then return false end
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
 local results={}
 for _,member in ipairs(g.held) do
  local released=Single.release(member,x,y,time,view,scale,bounds)
  if not released then return nil end
  results[#results+1]=released
 end
 return results
end
return G
