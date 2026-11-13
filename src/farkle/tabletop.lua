local Bundle = {}
Bundle.tray_workshop = (function()
-- Temporary visual workshop. No physics, gameplay, camera or RNG ownership.
-- First visual book silhouette. F8 preserves access to the original variants.
local W={current='book'}
local order={'book','current','A','B','C'}
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
