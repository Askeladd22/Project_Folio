-- Pure geometry for F8 tray skins; never changes physical collision geometry.
-- GPU scene remains independent from Farkle rules, fixed stepping and picking.
local S={}
local PALETTE={
 book={.76,.67,.51},current={.35,.215,.12},
 A={.31,.18,.095},B={.48,.33,.20},C={.52,.43,.255},
}
local function vertex(pos,color,alpha)
 return {pos[1],pos[2],pos[3],0,0,0,0,1,color[1],color[2],color[3],alpha or 1}
end
local function quad(out,a,b,c,d,color)
 for _,p in ipairs({a,b,c,a,c,d}) do out[#out+1]=vertex(p,color) end
end
function S.style_vertices(mesh,extents,height,style)
 style=PALETTE[style] and style or 'book'
 local x1,x2,y1,y2=unpack(extents)
 local width=style=='current' and .40 or style=='C' and .13 or .85
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
   local first=((side-1)*3+(part-1))*48+1
   for i=first,first+47 do
    v[i][9]=math.min(1,c[1]*shade)
    v[i][10]=math.min(1,c[2]*shade)
    v[i][11]=math.min(1,c[3]*shade)
   end
  end
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
