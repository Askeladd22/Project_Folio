-- Physical one-at-a-time mouse handling for Manuscript's existing solver.
-- The held body is real; its vertices rotate while _manual_pending freezes
-- ordinary gravity/collisions. Release restores dynamic physics immediately.
local T={}
local function clamp(x,lo,hi) return math.max(lo,math.min(hi,x)) end
local function finite(x) return type(x)=='number' and x==x and math.abs(x)<math.huge end
local function copy3(v) return {v[1],v[2],v[3]} end

function T.world_motion(dx,dy,view,scale)
 local zoom=(view.focus or 5)/(view.distance or 14.1)
 local k=math.max(.001,(scale or 1)*zoom)
 local yaw,pitch=view.yaw or 0,view.pitch or .48
 local sx=dx/k
 local sy=dy/(k*math.max(.15,math.cos(pitch)))
 local c,s=math.cos(yaw),math.sin(yaw)
 return c*sx+s*sy,-s*sx+c*sy
end

function T.begin(index,body,x,y,time)
 if type(index)~='number' or index<1 or index%1~=0 or
    type(body)~='table' or not body.position or
    not (finite(x) and finite(y) and finite(time)) then return nil end
 local original={position=copy3(body.position),velocity=copy3(body.velocity),
  angular=copy3(body.angular),asleep=body.asleep,sleep_timer=body.sleep_timer,
  vertices={}}
 for i,v in ipairs(body) do original.vertices[i]=copy3(v) end
 body._manual_pending=true
 body._grabbed=true
 body.asleep=true
 body.sleep_timer=0
 body.velocity[1],body.velocity[2],body.velocity[3]=0,0,0
 local g={index=index,body=body,x0=x,y0=y,x=x,y=y,t0=time,t=time,
  original=original,samples={{x=x,y=y,t=time}},
  angular={2.0,1.4,.6}}
 body.position[3]=math.max(body.position[3],2.1)
 return g
end

-- Update the gesture/swing without teleports. Group handling uses this
-- while guiding several ACTUAL rigid bodies to a compact formation.
function T.track(g,x,y,time)
 if not g or not(finite(x) and finite(y) and finite(time)) then return false end
 local dt=math.max(.001,math.min(.05,time-g.t))
 local dx,dy=x-g.x,y-g.y
 g.x,g.y,g.t=x,y,math.max(g.t,time)
 g.angular[1]=clamp(2.0+dy*.050/dt,-13,13)
 g.angular[2]=clamp(1.4+dx*.050/dt,-13,13)
 g.angular[3]=clamp(.6+(dx-dy)*.012/dt,-8,8)
 local sample=g.samples
 sample[#sample+1]={x=x,y=y,t=g.t}
 while #sample>2 and g.t-sample[1].t>.18 do table.remove(sample,1) end
 return true
end

function T.move(g,x,y,time,view,scale,bounds)
 if not T.track(g,x,y,time) then return false end
 local vx,vy=T.world_motion(x-g.x0,y-g.y0,view,scale)
 local b=g.body
 local pad=math.max(.4,(b.radius or .5)*.7)
 local hw=(bounds and bounds.half_x or 9.2)-pad
 local hh=(bounds and bounds.half_y or 3.8)-pad
 b.position[1]=clamp(g.original.position[1]+vx,-hw,hw)
 b.position[2]=clamp(g.original.position[2]+vy,-hh,hh)
 b.position[3]=math.max(2.1,math.min(4.2,g.original.position[3]+1.2))
 return true
end

function T.tick(g,dt)
 if not g or not dt or dt<=0 then return end
 local b=g.body
 if not b._grabbed then return end
 dt=math.min(.05,dt)
 b.velocity[1],b.velocity[2],b.velocity[3]=0,0,0
 b.angular[1],b.angular[2],b.angular[3]=g.angular[1],g.angular[2],g.angular[3]
 b:update(dt) -- physically rotate the true mesh vertices, no translation
 g.angular[1]=g.angular[1]*(.99^ (dt*60))
 g.angular[2]=g.angular[2]*(.99^ (dt*60))
 g.angular[3]=g.angular[3]*(.99^ (dt*60))
end

function T.cancel(g)
 if not g then return end
 local b,old=g.body,g.original
 for j=1,3 do
  b.position[j]=old.position[j]
  b.velocity[j]=old.velocity[j]
  b.angular[j]=old.angular[j]
 end
 for i,v in ipairs(old.vertices) do for j=1,3 do b[i][j]=v[j] end end
 b._grabbed=false
 b._manual_pending=true -- still needs an official physical release
 b.asleep=true
 b.sleep_timer=0
end

function T.release(g,x,y,time,view,scale,bounds)
 if not g then return nil end
 T.move(g,x,y,time,view,scale,bounds)
 local sample=g.samples
 local recent=sample[1]
 for i=1,#sample do
  if g.t-sample[i].t<=.15 then recent=sample[i];break end
 end
 local dt=math.max(.025,g.t-recent.t)
 local dx,dy=T.world_motion(g.x-recent.x,g.y-recent.y,view,scale)
 local vx,vy=clamp(dx/dt,-18,18),clamp(dy/dt,-18,18)
 local b=g.body
 -- A simple release still drops the held die; vigorous swipes impart speed.
 b.velocity[1],b.velocity[2],b.velocity[3]=vx,vy,-3.5-math.min(7,math.sqrt(vx*vx+vy*vy)*.22)
 b.angular[1]=clamp(g.angular[1],-14,14)
 b.angular[2]=clamp(g.angular[2],-14,14)
 b.angular[3]=clamp(g.angular[3],-10,10)
 b.asleep=false
 b.sleep_timer=0
 b._grabbed=false
 b._manual_pending=false
 return {index=g.index,velocity=copy3(b.velocity),angular=copy3(b.angular)}
end
return T
