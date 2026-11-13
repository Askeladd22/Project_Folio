local Bundle = {}
Bundle.tray_workshop = (function()
-- Temporary visual workshop. No physics, gameplay, camera or RNG ownership.
-- First visual book silhouette. F8 preserves access to the original variants.
local W={current='book'}
local order={'book','current','A','B','C'}
local labels={book='Libro aperto / prototipo',current='Attuale',A='A / Vassoio artigianale',B='B / Plancia integrata',C='C / Tavolo da gioco'}
-- F8 remains the gameplay-facing switch for g3d book/tray skins.
function W.cycle()
 for i,id in ipairs(order) do
  if id==W.current then
   W.current=order[i%#order+1]
   return W.current
  end
 end
 error('unrecognized g3d tray style')
end

-- Returns graphical collection coordinates only; identities and transfer timing
-- remain in the accepted-dice register. F8 does not alter them.
function W.shelf(ax,ay,bx,by)
 if W.current=='current' then return end
 local g=love.graphics;local id=W.current;local depth=48
 if id=='C' then
  local dx,dy=(bx-ax)*.16,(by-ay)*.16
  ax,ay,bx,by=ax+dx,ay+dy+12,bx-dx,by-dy+12;depth=38
  g.setColor(.025,.015,.008,.5);g.rectangle('fill',ax-9,ay-depth+6,bx-ax+18,depth+8,12)
  g.setColor(.32,.20,.10);g.rectangle('fill',ax-8,ay-depth,bx-ax+16,depth+7,10)
  g.setColor(.12,.085,.045);g.rectangle('fill',ax,ay-depth+6,bx-ax,depth-5,7)
 elseif id=='B' then
  depth=40
  g.setColor(.36,.23,.13);g.polygon('fill',ax-10,ay-depth-8,bx+10,by-depth-8,bx+10,by+10,ax-10,ay+10)
  g.setColor(.075,.05,.025);g.rectangle('fill',ax,ay-depth,bx-ax,depth,3)
  g.setColor(.51,.36,.20);g.rectangle('line',ax,ay-depth,bx-ax,depth,3)
 else
  depth=50
  g.setColor(.075,.035,.015);g.polygon('fill',ax-10,ay-depth,bx+10,by-depth,bx+10,by+12,ax-10,ay+12)
  g.setColor(.32,.18,.08);g.rectangle('fill',ax-10,ay-depth,bx-ax+20,depth+4,5)
  g.setColor(.12,.055,.025);g.rectangle('fill',ax,ay-depth+7,bx-ax,depth-10,3)
  g.setColor(.58,.39,.19);g.line(ax-6,ay-depth+3,bx+6,by-depth+3)
 end
 for i=1,5 do local t=i/6;local x=ax+(bx-ax)*t;local y=ay+(by-ay)*t
  g.setColor(.58,.40,.21,.6);g.line(x,y-depth+9,x,y-7)
 end
 return ax,ay,bx,by,depth
end
function W.caption(txt)
 local Res=require('src.core.navigation').resolution
 Res.begin_ui()
 txt('F8  Workshop: '..labels[W.current],56,148,1250,20,{.94,.84,.65,1})
 Res.end_ui()
end
return W
end)()
Bundle.tray_view = (function()
-- Presentation only: fit the unchanged tray and physical vertices into the HUD.
local T={}
function T.fit(owner,tray,view,extents)
 view.projection='perspective'
 local scene=require('src.data.dice_schema').scene
 view.distance=scene.tray_camera.distance
 view.pitch=scene.tray_camera.pitch
 view.cos_pitch=math.cos(view.pitch);view.sin_pitch=math.sin(view.pitch)
 local minx,miny,maxx,maxy=math.huge,math.huge,-math.huge,-math.huge
 local points={}
 local function include(x,y,z)
  local px,py=view.project(x,y,z);points[#points+1]={px,py}
  minx=math.min(minx,px);maxx=math.max(maxx,px);miny=math.min(miny,py);maxy=math.max(maxy,py)
 end
 -- Fit the merchant's visible rim; flight space is rendered above it.
 local rim=.40
 local top=scene.box.border_height
 for _,x in ipairs({extents[1]-rim,extents[2]+rim}) do
  for _,y in ipairs({extents[3]-rim,extents[4]+rim}) do
   for _,z in ipairs({y>extents[4] and -top or 0,top}) do include(x,y,z) end
  end
 end
 for _,d in ipairs(dice) do for _,v in ipairs(d.body) do
  local px,py=view.project(v[1]+d.body.position[1],v[2]+d.body.position[2],v[3]+d.body.position[3]);points[#points+1]={px,py}
 end end
 -- One perspective transform for the 3D scene and die hit testing.
 -- The rear floor seam stays anchored to the opponent room.
 local layout=require('src.farkle.ui').layout.build()
 local left=view.project(extents[1]-rim,extents[3],0)
 local right=view.project(extents[2]+rim,extents[3],0)
 local _,rear=view.project(0,extents[3],0)
 local inset=(layout.host.y+layout.host.h-layout.tray.y)*tray.h/layout.tray.h
 local scale=math.min(tray.w/(maxx-minx),(tray.h-inset)/(maxy-rear),
  tray.w*(layout.rear_span/layout.tray.w)/(right-left))
 owner.trayScale=scale
 local cx=tray.x+tray.w/2-(minx+maxx)*scale/2
 local cy=tray.y+inset-rear*scale
 owner.trayProjection={cx=cx,cy=cy,scale=scale,points=points,rect=tray,pitch=view.pitch}
 local corners={}
 for _,p in ipairs({{extents[1]-rim,extents[3]-rim},{extents[2]+rim,extents[3]-rim},{extents[2]+rim,extents[4]+rim},{extents[1]-rim,extents[4]+rim}}) do
  local x,y=view.project(p[1],p[2],0);corners[#corners+1]={x=cx+x*scale,y=cy+y*scale}
 end
 local best,edge=-math.huge,nil
 for i,a in ipairs(corners) do local b=corners[i%4+1];local y=(a.y+b.y)/2
  if y>best then best=y;edge={a,b} end
 end
 if edge[1].x>edge[2].x then edge={edge[2],edge[1]} end
 local _,frontFloor=view.project(0,extents[4],0)
 owner.trayProjection.floorEnd=cy+frontFloor*scale
 owner.trayProjection.front=edge
 owner.trayProjection.yaw=view.yaw
 return cx,cy,scale
end
return T
end)()
return Bundle
