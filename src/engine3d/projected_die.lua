-- The cube vertices are already in world orientation. Their screen-space
-- convex hull follows the same pose and camera used by g3d, at any tray size.
local P={}
local function cross(a,b,c)
 return (b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])
end

function P.from_body(index,body,project,cx,cy,scale)
 local bx,by,bz=body.position[1],body.position[2],body.position[3]
 local px,py,depth=project(bx,by,bz)
 local x,y=cx+px*scale,cy+py*scale
 local points,r2={},0
 for i,v in ipairs(body) do
  local vx,vy=project(bx+v[1],by+v[2],bz+v[3])
  local sx,sy=cx+vx*scale,cy+vy*scale
  points[i]={sx,sy}
  r2=math.max(r2,(sx-x)^2+(sy-y)^2)
 end
 table.sort(points,function(a,b) return a[1]<b[1] or a[1]==b[1] and a[2]<b[2] end)
 -- Lower and upper convex chains; drop collinear interior vertices.
 local hull={}
 local function append(p,base)
  while #hull>=base+2 and cross(hull[#hull-1],hull[#hull],p)<=0 do
   hull[#hull]=nil
  end
  hull[#hull+1]=p
 end
 for _,p in ipairs(points) do append(p,0) end
 local base=#hull-1
 for i=#points-1,1,-1 do append(points[i],base) end
 local outline={}
 for i=1,#hull-1 do
  outline[#outline+1]=hull[i][1];outline[#outline+1]=hull[i][2]
 end
 return {index=index,x=x,y=y,r=math.sqrt(r2),depth=depth,outline=outline}
end

local function contains(outline,x,y)
 local j=#outline-1
 for i=1,#outline,2 do
  local ax,ay=outline[j],outline[j+1]
  if (outline[i]-ax)*(y-ay)-(outline[i+1]-ay)*(x-ax)<-1e-6 then return false end
  j=i
 end
 return #outline>=6
end

function P.pick(hits,x,y)
 if type(x)~='number' or type(y)~='number' then return nil end
 local best
 for _,h in ipairs(hits) do
  if (not best or h.depth>best.depth) and contains(h.outline,x,y) then best=h end
 end
 return best and best.index
end
return P
