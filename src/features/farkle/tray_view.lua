-- Presentation only: fit the unchanged tray and physical vertices into the HUD.
local T={}
function T.fit(owner,tray,view,extents)
 local merchant=owner.minimalHud
 view.projection=merchant and 'perspective' or 'orthographic'
 local scene=require('src.data.dice_scene_schema')
 if merchant then view.distance=scene.tray_camera.distance end
 view.pitch=merchant and scene.tray_camera.pitch or .48;view.cos_pitch=math.cos(view.pitch);view.sin_pitch=math.sin(view.pitch)
 local minx,miny,maxx,maxy=math.huge,math.huge,-math.huge,-math.huge
 local points={}
 local function include(x,y,z)
  local px,py=view.project(x,y,z);points[#points+1]={px,py}
  minx=math.min(minx,px);maxx=math.max(maxx,px);miny=math.min(miny,py);maxy=math.max(maxy,py)
 end
 -- Fit the merchant's visible rim; flight space is rendered above it.
 local rim=merchant and .40 or .85
 local top=merchant and scene.box.border_height or 9
 for _,x in ipairs({extents[1]-rim,extents[2]+rim}) do
  for _,y in ipairs({extents[3]-rim,extents[4]+rim}) do
   for _,z in ipairs({merchant and y>extents[4] and -top or 0,top}) do include(x,y,z) end
  end
 end
 for _,d in ipairs(dice) do for _,v in ipairs(d.body) do
  local px,py=view.project(v[1]+d.body.position[1],v[2]+d.body.position[2],v[3]+d.body.position[3]);points[#points+1]={px,py}
 end end
 local margin=(merchant and 0 or 18)*require('src.core.resolution_manager').get_scale()
 local target=math.min((tray.w-2*margin)/(maxx-minx),(tray.h-2*margin)/(maxy-miny))
 -- The merchant backdrop is fixed in screen space. Its tabletop must
 -- keep the same projection throughout pickup, hold and release.
 if merchant then
  local layout=require('src.features.farkle.ui_v2.layout_candidates').build('table_minimal')
  local left=view.project(extents[1]-rim,extents[3],0)
  local right=view.project(extents[2]+rim,extents[3],0)
  target=math.min(target,tray.w*(layout.host.w/layout.tray.w)/(right-left))
 end
 local scale=target
 if not merchant then
  local Zoom=require('src.features.farkle.group_hold_projection')
  local now=(love and love.timer and love.timer.getTime and love.timer.getTime()) or 0
  local grip=owner.mouseThrow
  scale=target*Zoom.advance(owner,now,grip and grip.group or false)
 end
 owner.trayScale=scale
 local cx=tray.x+tray.w/2-(minx+maxx)*scale/2
 local cy=tray.y+tray.h/2-(miny+maxy)*scale/2
 if merchant then
  local _,rear=view.project(0,extents[3],0)
  cy=tray.y-rear*scale
 end
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
