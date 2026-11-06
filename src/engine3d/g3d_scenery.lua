-- Pure geometry for F8 tray skins; never changes physical collision geometry.
-- GPU scene remains independent from Farkle rules, fixed stepping and picking.
local S={}
local PALETTE={
 merchant={.45,.24,.105},book={.76,.67,.51},current={.35,.215,.12},
 A={.31,.18,.095},B={.48,.33,.20},C={.52,.43,.255},
}
-- Plain, non-textured floors keep the physical dice visually prominent.
-- Unlike the old painter's manuscript rubrics these meshes share g3d depth.
local FLOORS={
 merchant={1,1,1},book={.88,.79,.64},current={.36,.29,.22},
 A={.32,.23,.17},B={.29,.35,.31},C={.45,.39,.30},
}
function S.floor_vertices(mesh,extents,style)
 local color=FLOORS[style] or FLOORS.book
 local out=mesh.floor_vertices(extents[1],extents[2],extents[3],extents[4])
 for _,v in ipairs(out) do
  v[9],v[10],v[11],v[12]=color[1],color[2],color[3],1
 end
 return out
end
local function vertex(pos,color,alpha)
 return {pos[1],pos[2],pos[3],0,0,0,0,1,color[1],color[2],color[3],alpha or 1}
end
local function quad(out,a,b,c,d,color)
 for _,p in ipairs({a,b,c,a,c,d}) do out[#out+1]=vertex(p,color) end
end
function S.style_vertices(mesh,extents,height,style)
 style=PALETTE[style] and style or 'book'
 local x1,x2,y1,y2=unpack(extents)
 -- Thin decorative housing; the underlying collision walls do not change.
 local width=style=='book' and .32 or style=='current' and .28
  or style=='C' and .13 or .40
 local v=mesh.tray_border_vertices(x1,x2,y1,y2,width,height,8)
 local colors=PALETTE[style]
 -- All wall sections retain the same physical heights; only the skin changes.
 for side=1,4 do
  for part=1,3 do
   local shade=part==1 and .95 or part==2 and .67 or 1.08
   local c=colors
   if style=='book' then
    c=side==4 and ({[1]={.26,.12,.075},[2]={.37,.225,.14},[3]={.31,.17,.105}})[part]
      or ({[1]={.76,.67,.51},[2]={.60,.50,.355},[3]={.86,.775,.61}})[part]
    shade=1
   end
   for vertex_index=0,47 do
    -- Mesh order within each side: segment, then outer/inner/rim quad.
    local segment=math.floor(vertex_index/6)
    local i=((side-1)*8+segment)*18+(part-1)*6+vertex_index%6+1
    v[i][9]=math.min(1,c[1]*shade)
    v[i][10]=math.min(1,c[2]*shade)
    v[i][11]=math.min(1,c[3]*shade)
   end
  end
 end
 -- The illustration supplies the merchant's far end. Join its wood directly
 -- to the physical floor instead of laying a second crossbar across it.
 if style=='merchant' then
  local sides={}
  for i=8*3*6+1,#v do
   local point=v[i]
   -- A flush joint at the illustrated edge, rising to full rail height
   -- over the first segment. Keep both sides of each joint coincident.
   local rise=math.max(0,math.min(1,(point[2]-y1)/1.4))
   point[2]=math.max(y1,point[2])
   point[3]=point[3]*rise
   -- U follows each timber's length (front across X, side rails along Y).
   local front=i>2*8*18 and i<=3*8*18
   point[4]=front and (point[1]-x1+width)/(x2-x1+2*width)
    or (point[2]-y1)/(y2-y1+width)
   point[5]=.4+.20*(1-point[3]/height)
   if point[3]>height*.98 then
    for channel=9,11 do point[channel]=math.min(1,point[channel]+.09) end
   end
   -- Sink the near apron under the floor so it cannot mask a resting die.
   local drop=math.max(0,math.min(1,(point[2]-y2+1.4)/1.4))
   point[3]=point[3]-height*drop
   sides[#sides+1]=point
  end
  return sides
 end
 -- Variant B is a wide counter around an unchanged tray opening.
 if style=='B' then
  local inner={{x1,y1},{x2,y1},{x2,y2},{x1,y2}}
  local outer={{x1-4.5,y1-.85},{x2+4.5,y1-.85},
               {x2+4.5,y2+.85},{x1-4.5,y2+.85}}
  for i=1,4 do
   local j=i%4+1
   local a,b=inner[i],inner[j]
   local c,d=outer[i],outer[j]
   quad(v,{c[1],c[2],height},{d[1],d[2],height},
    {b[1],b[2],height},{a[1],a[2],height},{.48,.33,.20})
  end
 end
 return v
end
function S.divider_vertices(info)
 if not info then return nil end
 local x1,x2=assert(info.back_x),assert(info.front_x)
 local y1,y2=assert(info.back_y),assert(info.front_y)
 local w=assert(info.width)
 local z=assert(info.height)
 assert(y2>y1 and w>0 and z>0,'valid divider geometry')
 local p={}
 quad(p,{x1-w,y1,.01},{x2-w,y2,.01},{x2-w,y2,z},{x1-w,y1,z},{.24,.17,.11})
 quad(p,{x2+w,y2,.01},{x1+w,y1,.01},{x1+w,y1,z},{x2+w,y2,z},{.42,.30,.20})
 quad(p,{x1-w,y1,z},{x1+w,y1,z},{x2+w,y2,z},{x2-w,y2,z},{.56,.40,.28})
 quad(p,{x1-w,y1,.01},{x1-w,y1,z},{x1+w,y1,z},{x1+w,y1,.01},{.31,.22,.15})
 quad(p,{x2-w,y2,.01},{x2+w,y2,.01},{x2+w,y2,z},{x2-w,y2,z},{.31,.22,.15})
 return p
end
function S.face_color(die,i)
 local color=die.faceColors and die.faceColors[i] or die.color or {255,255,255,255}
 local n=math.max(color[1] or 255,color[2] or 255,color[3] or 255)
 local divisor=n>1 and 255 or 1
 return {math.max(0,math.min(1,(color[1] or 255)/divisor)),
         math.max(0,math.min(1,(color[2] or 255)/divisor)),
         math.max(0,math.min(1,(color[3] or 255)/divisor))}
end
return S
