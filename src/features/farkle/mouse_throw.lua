-- Mouse grab/throw for the existing six-die Farkle roll.
-- This module ONLY maps a gesture to a bounded launch vector and a
-- render-only held-die preview: no FPS dependency, RNG or physics mutation.
local T={}
local MIN_DRAG=28        -- screen pixels, ignore accidental right-clicks
local MAX_PREVIEW=210    -- screen pixels, keep the held die near the tray
local MAX_DURATION=1.2
local MIN_DURATION=.06
local MIN_CAMERA_CP=.15

local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=='number' and v==v and v~=math.huge and v~=-math.huge end

function T.begin(index,x,y,time)
 if not (finite(x) and finite(y) and finite(time)) then return nil end
 if type(index)~='number' or index<1 or index%1~=0 then return nil end
 return {index=index,x0=x,y0=y,x=x,y=y,t0=time,t=time}
end

function T.move(gesture,x,y,time)
 if not gesture or not (finite(x) and finite(y) and finite(time)) then return false end
 gesture.x,gesture.y=x,y
 gesture.t=math.max(gesture.t0,time)
 return true
end

-- Camera-aligned inverse of the established orthographic view.project().
-- Reuses the SAME camera yaw/pitch/zoom and screen scale as die picking.
function T.world_motion(dx,dy,view,scale)
 local zoom=(view.focus or 5)/(view.distance or 14.1)
 local factor=math.max(.001,(scale or 1)*zoom)
 local yaw,pitch=view.yaw or 0,view.pitch or .48
 local cosine=math.max(MIN_CAMERA_CP,math.cos(pitch))
 local sx=dx/factor
 local sy=dy/(factor*cosine)
 local c,s=math.cos(yaw),math.sin(yaw)
 return c*sx+s*sy,-s*sx+c*sy
end

function T.preview(gesture,view,scale)
 if not gesture then return nil end
 local dx,dy=gesture.x-gesture.x0,gesture.y-gesture.y0
 local length=math.sqrt(dx*dx+dy*dy)
 if length>MAX_PREVIEW then
  dx,dy=dx*MAX_PREVIEW/length,dy*MAX_PREVIEW/length
 end
 local wx,wy=T.world_motion(dx,dy,view,scale)
 return {index=gesture.index,x=wx,y=wy,z=.35+.85*clamp(length/160,0,1)}
end

function T.finish(gesture,x,y,time,view,scale)
 if not T.move(gesture,x,y,time) then return nil end
 local dx,dy=gesture.x-gesture.x0,gesture.y-gesture.y0
 local dist=math.sqrt(dx*dx+dy*dy)
 if dist<MIN_DRAG then return nil end
 local wx,wy=T.world_motion(dx,dy,view,scale)
 local length=math.sqrt(wx*wx+wy*wy)
 if length<.0001 then return nil end
 local duration=clamp(gesture.t-gesture.t0,MIN_DURATION,MAX_DURATION)
 local speed=dist/duration
 return {x=wx/length,y=wy/length,power=clamp(speed/950,.35,1.45)}
end
return T
