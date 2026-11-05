-- Project the physical corners onto the tabletop along the dice material's key light.
local light=require('src.engine3d.g3d_materials').light
local cast_x,cast_y=-light[1]/light[3],-light[2]/light[3]

local function turn(a,b,c)
 return (b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])
end

local function convex_outline(points)
 table.sort(points,function(a,b)
  return a[1]<b[1] or (a[1]==b[1] and a[2]<b[2])
 end)
 local hull={}
 local function append(point,start)
  while #hull>start and turn(hull[#hull-1],hull[#hull],point)<=1e-9 do
   hull[#hull]=nil
  end
  hull[#hull+1]=point
 end
 for _,point in ipairs(points) do append(point,1) end
 local split=#hull
 for i=#points-1,1,-1 do append(points[i],split) end
 hull[#hull]=nil -- the first point closes both chains
 return hull
end

local function shadow_vertices(body,offset,preview)
 local position=body.position
 local x=position[1]-(offset or 0)+(preview and preview.x or 0)
 local y=position[2]+(preview and preview.y or 0)
 local z=position[3]+(preview and preview.z or 0)
 local radius=body.radius or .65
 local bottom=#body>0 and math.huge or -radius
 local projected={}
 for _,corner in ipairs(body) do
  bottom=math.min(bottom,corner[3])
  local height=z+corner[3]
  projected[#projected+1]={x+corner[1]+cast_x*height,y+corner[2]+cast_y*height}
 end
 -- Radius-only proxies have no physical silhouette to project.
 if #projected<3 then
  local cx,cy=x+cast_x*z,y+cast_y*z
  projected={{cx-radius,cy-radius},{cx+radius,cy-radius},
             {cx+radius,cy+radius},{cx-radius,cy+radius}}
 end
 local hull=convex_outline(projected)
 local cx,cy=x+cast_x*z,y+cast_y*z
 local clearance=math.max(0,z+bottom)
 local opacity=.47/(1+.36*clearance)
 local blur=.15+.20*clearance/math.max(.25,radius)
 local core=math.max(.18,1-blur*.75)
 local edge=1+blur
 local function vertex(point,scale,alpha)
  -- Black with alpha darkens the existing grain and preserves its hue.
  return {cx+(point[1]-cx)*scale,cy+(point[2]-cy)*scale,.012,
          0,0,0,0,1,0,0,0,alpha}
 end
 local center=vertex({cx,cy},0,opacity)
 local inner,outer={},{}
 for i,point in ipairs(hull) do
  inner[i]=vertex(point,core,opacity)
  outer[i]=vertex(point,edge,0)
 end
 local vertices={}
 for i=1,#hull do
  local j=i%#hull+1
  local n=#vertices
  vertices[n+1],vertices[n+2],vertices[n+3]=center,inner[i],inner[j]
  vertices[n+4],vertices[n+5],vertices[n+6]=inner[i],outer[i],outer[j]
  vertices[n+7],vertices[n+8],vertices[n+9]=inner[i],outer[j],inner[j]
 end
 -- One mesh per die survives rotation, even when its outline gains a corner.
 for i=#vertices+1,8*9 do vertices[i]=center end
 return vertices
end

return shadow_vertices
