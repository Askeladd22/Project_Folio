-- Presentation only: fit the unchanged tray and physical vertices into the HUD.
local T={}
function T.fit(owner,tray,view,extents)
 view.projection='orthographic'
 view.pitch=.48;view.cos_pitch=math.cos(view.pitch);view.sin_pitch=math.sin(view.pitch)
 local minx,miny,maxx,maxy=math.huge,math.huge,-math.huge,-math.huge
 local points={}
 local function include(x,y,z)
  local px,py=view.project(x,y,z);points[#points+1]={px,py}
  minx=math.min(minx,px);maxx=math.max(maxx,px);miny=math.min(miny,py);maxy=math.max(maxy,py)
 end
 for _,x in ipairs({extents[1]-.85,extents[2]+.85}) do
  for _,y in ipairs({extents[3]-.85,extents[4]+.85}) do
   for _,z in ipairs({0,9}) do include(x,y,z) end
  end
 end
 for _,d in ipairs(dice) do for _,v in ipairs(d.body) do
  local px,py=view.project(v[1]+d.body.position[1],v[2]+d.body.position[2],v[3]+d.body.position[3]);points[#points+1]={px,py}
 end end
 local margin=18*require('src.core.resolution_manager').get_scale()
 local target=math.min((tray.w-2*margin)/(maxx-minx),(tray.h-2*margin)/(maxy-miny))
 -- Fixed launch envelope, independent of body positions and frame rate.
 -- Apply a small optical pullback *after* fitting the scene. Altering
 -- only view.distance would be canceled by the fitter (and would break
 -- mouse picking if it did not update the whole projection).
 local Zoom=require('src.features.farkle.group_hold_projection')
 local now=(love and love.timer and love.timer.getTime and love.timer.getTime()) or 0
 local grip=owner.mouseThrow
 local camera_factor=Zoom.advance(owner,now,grip and grip.group or false)
 local scale=target*camera_factor
 owner.trayScale=scale
 local cx=tray.x+tray.w/2-(minx+maxx)*scale/2
 local cy=tray.y+tray.h/2-(miny+maxy)*scale/2
 owner.trayProjection={cx=cx,cy=cy,scale=scale,points=points,rect=tray,pitch=view.pitch}
 local corners={}
 for _,p in ipairs({{extents[1]-.85,extents[3]-.85},{extents[2]+.85,extents[3]-.85},{extents[2]+.85,extents[4]+.85},{extents[1]-.85,extents[4]+.85}}) do
  local x,y=view.project(p[1],p[2],0);corners[#corners+1]={x=cx+x*scale,y=cy+y*scale}
 end
 local best,edge=-math.huge,nil
 for i,a in ipairs(corners) do local b=corners[i%4+1];local y=(a.y+b.y)/2
  if y>best then best=y;edge={a,b} end
 end
 if edge[1].x>edge[2].x then edge={edge[2],edge[1]} end
 owner.trayProjection.front=edge
 owner.trayProjection.yaw=view.yaw
 return cx,cy,scale
end
return T
