local Bundle = {}
Bundle.projected_die = (function()
-- The cube vertices are already in world orientation. Their screen-space
-- convex hull follows the same pose and camera used by g3d, at any tray size.
local P={}
local function cross(a,b,c)
 return (b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])
end

function P.from_body(index,body,project,cx,cy,scale,faces,perspective)
 local bx,by,bz=body.position[1],body.position[2],body.position[3]
 local px,py,depth=project(bx,by,bz)
 local x,y=cx+px*scale,cy+py*scale
 local points,vertices,r2={},{},0
 for i,v in ipairs(body) do
  local vx,vy,vz=project(bx+v[1],by+v[2],bz+v[3])
  local sx,sy=cx+vx*scale,cy+vy*scale
  -- Eye Z is negative. In perspective 1 / distance varies linearly
  -- across the screen triangle; in orthographic projection eye Z does.
  -- Both keys increase toward the viewer.
  vertices[i]={sx,sy,perspective and -1/vz or vz}
  points[i]=vertices[i]
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
 return {index=index,x=x,y=y,r=math.sqrt(r2),depth=depth,outline=outline,
  faces=faces,vertices=vertices}
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

local function surface_depth(hit,pointer)
 local nearest=-math.huge
 for _,face in ipairs(hit.faces) do
  local a=hit.vertices[face[1]]
  for i=2,#face-1 do
   local b,c=hit.vertices[face[i]],hit.vertices[face[i+1]]
   local area=cross(a,b,c)
   if math.abs(area)>1e-12 then
    local wa=cross(b,c,pointer)/area
    local wb=cross(c,a,pointer)/area
    local wc=1-wa-wb
    if wa>=-1e-8 and wb>=-1e-8 and wc>=-1e-8 then
     nearest=math.max(nearest,wa*a[3]+wb*b[3]+wc*c[3])
    end
   end
  end
 end
 return nearest
end

function P.pick(hits,x,y)
 if type(x)~='number' or type(y)~='number' then return nil end
 local best,bestDepth,pointer
 for _,h in ipairs(hits) do
  if contains(h.outline,x,y) then
   if best then
    -- Evaluate faces only when two or more silhouettes contain the pointer.
    pointer=pointer or {x,y}
    bestDepth=bestDepth or surface_depth(best,pointer)
    local candidate=surface_depth(h,pointer)
    if candidate>bestDepth then best,bestDepth=h,candidate end
   else
    best=h
   end
  end
 end
 return best and best.index
end
return P
end)()
Bundle.view = (function()

local view={
  yaw=1.2,
  pitch=1.2,
  distance=12,
  focus=5
}
view.cos_pitch, view.sin_pitch=math.cos(view.pitch), math.sin(view.pitch)
view.cos_yaw, view.sin_yaw=math.cos(view.yaw), math.sin(view.yaw)

local function clamp(value, min_v, max_v)
  if value < min_v then return min_v end
  if value > max_v then return max_v end
  return value
end

function view.raise(delta)
  view.pitch=clamp(view.pitch-delta,0.1,1.5)
  view.cos_pitch,view.sin_pitch=math.cos(view.pitch), math.sin(view.pitch)
end
function view.turn(delta)
  view.yaw=view.yaw-delta
  view.cos_yaw,view.sin_yaw=math.cos(view.yaw), math.sin(view.yaw)
end
function view.move(delta)
  view.distance=clamp(view.distance*delta,20,100)
end

function view.project(x,y,z)
  local v=view
  x,y= v.cos_yaw*x-v.sin_yaw*y, v.sin_yaw*x+v.cos_yaw*y
  y,z = v.cos_pitch*y-v.sin_pitch*z, v.sin_pitch*y+v.cos_pitch*z
  z = view.distance-z
  local p=view.focus/(view.projection=='orthographic' and view.distance or z)
  if p<0 then p=1000 end
  return x*p, y*p, -z, p
end

function view.get()
  local v,x,y,z=view,0,0,view.distance
  y,z = v.cos_pitch*y+v.sin_pitch*z, -v.sin_pitch*y+v.cos_pitch*z
  x,y= v.cos_yaw*x+v.sin_yaw*y, -v.sin_yaw*x+v.cos_yaw*y
  return x,y,z
end

-- Direction toward the viewer: constant for orthographic projection.
function view.to_camera(x,y,z)
  local cx,cy,cz=view.get()
  if view.projection=='orthographic' then return cx,cy,cz end
  return cx-x,cy-y,cz-z
end

return view
end)()
Bundle.view.projected_die = Bundle.projected_die
return Bundle.view
