-- Held-stage virtual dice shaker, inspired by Tabletop Simulator's cup feel.
-- It is NOT a separate dice solver or a scripted result: confirmed mouse
-- reversals inject momentum into independent real D6 bodies, which rattle
-- against each other and a short-lived, invisible cup around the hand.
-- This module never imports gameplay RNG, creates dice or decides faces.
local Shake=require('src.features.farkle.shake_detector')
local Single=require('src.features.farkle.mouse_throw')
local M={}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function radius(member)
 return math.max(.32,member.body.radius or .52)
end

function M.new(x,y,time)
 return {detector=Shake.new(0,x,y,time),energy=0,events=0,
   pending=nil,phase=0}
end

-- Sampling lives in the mouse-event path, NOT love.update: a quick
-- unidirectional flick cannot start the shaker by itself.
function M.sample(s,x,y,time,view,scale)
 if not s then return false end
 local previous=s.detector
 local ox,oy=previous.x,previous.y
 local spin=Shake.sample(previous,x,y,time)
 if not spin then return false end
 local dx,dy=Single.world_motion(x-ox,y-oy,view,scale)
 local length=math.sqrt(dx*dx+dy*dy)
 local nx,ny=1,0
 if length>1e-6 then nx,ny=dx/length,dy/length end
 s.events=s.events+1
 local strength=previous.strength
 s.energy=clamp(math.max(s.energy,.45)+.48*strength,0,1.25)
 s.pending={x=nx,y=ny,strength=strength,number=s.events}
 return true
end

-- Only once per CONFIRMED reversing gesture, transfer hand acceleration
-- into the bodies: directional inertia, per-body swirl, vertical clatter,
-- and different real rotations. Fixed phase offsets just break symmetry.
function M.advance(g,dt)
 local s=g and g.shaker
 if not s then return 0 end
 dt=math.max(0,math.min(dt or 0,.04))
 s.phase=s.phase+dt*16
 s.energy=s.energy*math.exp(-dt*2.9)
 local pulse=s.pending
 local targetRadius=math.min(2.55,1.55+.17*#g.held)
 if pulse then
  -- Cup walls gradually close from the current scattered distribution;
  -- an instantaneous hard radius would teleport distant held bodies.
  local outer=targetRadius
  for _,member in ipairs(g.held) do
   local p=member.body.position
   local dx,dy=p[1]-g.hand.x,p[2]-g.hand.y
   outer=math.max(outer,math.sqrt(dx*dx+dy*dy)+radius(member)*.45+.10)
  end
  s.cup_radius=math.max(s.cup_radius or 0,outer)
  s.pending=nil
  for i,member in ipairs(g.held) do
   local vel=g.hold_velocity[i]
   local angle=i*2.3999632297+pulse.number*1.6180339887
   local weight=clamp(pulse.strength,.4,1)
   vel[1]=clamp(vel[1]-pulse.x*4.8*weight+
    math.cos(angle)*3.0*weight,-12,12)
   vel[2]=clamp(vel[2]-pulse.y*4.8*weight+
    math.sin(angle)*3.0*weight,-12,12)
   vel[3]=clamp(vel[3]+(2.7+1.7*(i%3)/2)*weight,-12,12)
   local rotation=member.angular
   rotation[1]=clamp(rotation[1]+math.sin(angle)*5*weight,-14,14)
   rotation[2]=clamp(rotation[2]+math.cos(angle)*5*weight,-14,14)
   rotation[3]=clamp(rotation[3]+(i%2==0 and 1 or -1)*3.2*weight,-10,10)
  end
 end
 -- Velocity turbulence is active only for the decaying post-shake window.
 -- The existing grip spring/contact solver remains responsible for motion
 -- and real collision separation; this is agitation, not a teleport.
 local energy=s.energy
 if s.cup_radius then
  s.cup_radius=math.max(targetRadius,s.cup_radius-4.6*dt)
 end
 if energy<.015 or dt<=0 then
  if energy<.015 then s.energy=0 end
  return s.energy
 end
 for i,member in ipairs(g.held) do
  local p=member.body.position
  local v=g.hold_velocity[i]
  local dx,dy=p[1]-g.hand.x,p[2]-g.hand.y
  local phase=s.phase+i*2.3999632297
  local swirl=energy*8*dt
  v[1]=clamp(v[1]+(-dy*.65+math.cos(phase))*swirl,-12,12)
  v[2]=clamp(v[2]+(dx*.65+math.sin(phase))*swirl,-12,12)
  v[3]=clamp(v[3]+math.sin(phase*1.25)*energy*13*dt,-12,12)
 end
 return energy
end

-- A short-lived invisible cup stops active shaken dice flying away from
-- the hand; no visible mesh is necessary and the free throw has no cup.
-- Call after the ordinary held-stage pair contacts, so we never move
-- bodies that have been released to the real physics solver.
function M.contain(g)
 local s=g and g.shaker
 if not s or s.energy<.06 then return end
 local h=g.hand
 local count=#g.held
 local cupRadius=s.cup_radius or math.min(2.55,1.55+.17*count)
 for i,member in ipairs(g.held) do
  local p=member.body.position
  local v=g.hold_velocity[i]
  local dx,dy=p[1]-h.x,p[2]-h.y
  local d=math.sqrt(dx*dx+dy*dy)
  local limit=math.max(.8,cupRadius-radius(member)*.45)
  if d>limit and d>1e-7 then
   local nx,ny=dx/d,dy/d
   p[1]=h.x+nx*limit
   p[2]=h.y+ny*limit
   local outward=v[1]*nx+v[2]*ny
   if outward>0 then
    v[1]=v[1]-nx*outward*1.25
    v[2]=v[2]-ny*outward*1.25
   end
  end
  local floor=h.z-1.25
  local ceiling=h.z+1.28
  if p[3]<floor then
   p[3]=floor
   if v[3]<0 then v[3]=-v[3]*.35 end
  elseif p[3]>ceiling then
   p[3]=ceiling
   if v[3]>0 then v[3]=-v[3]*.35 end
  end
 end
end

return M
