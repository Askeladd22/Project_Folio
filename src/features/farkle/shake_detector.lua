-- Original LÖVE mouse-shake detector inspired by the mechanics observed
-- in Tabletop Simulator's .NET assembly. It does NOT contain TTS code.
-- A swift one-way throw is not a shake: require TWO strong reversals
-- inside a short window. All calculations use screen pixels and seconds.
local S={}
S.window=.85
S.min_distance=8
S.min_speed=230
S.reverse_dot=-.38
S.reversals_required=2
S.cooldown=.20
local function finite(v) return type(v)=='number' and v==v and math.abs(v)<math.huge end

local function next_unit(g)
 -- Private local PRNG: shaking a visual die never consumes Farkle RNG.
 g.seed=(g.seed*48271)%2147483647
 return (g.seed/2147483647)*2-1
end

function S.new(index,x,y,time)
 assert(finite(index) and finite(x) and finite(y) and finite(time))
 local seed=(math.floor(math.abs(x)*97)+math.floor(math.abs(y)*193)+
   math.floor(math.abs(time)*1000)*53+index*7919)%2147483646+1
 return {x=x,y=y,time=time,vx=0,vy=0,speed=0,first=0,
  reversals=0,events=0,last_event=-math.huge,strength=0,
  last_spin={0,0,0},seed=seed}
end

-- Returns a fresh rotation impulse only on a confirmed shake event.
function S.sample(g,x,y,time)
 if not g or not(finite(x) and finite(y) and finite(time)) or
    time<=g.time then return nil end
 local dt=time-g.time
 local dx,dy=x-g.x,y-g.y
 g.x,g.y,g.time=x,y,time
 if dt>.24 then
  g.reversals=0;g.vx,g.vy,g.speed=0,0,0
  return nil
 end
 local distance=math.sqrt(dx*dx+dy*dy)
 if distance<S.min_distance then return nil end
 local vx,vy=dx/dt,dy/dt
 local speed=distance/dt
 local previous=g.speed
 local a=previous>0 and
   (vx*g.vx+vy*g.vy)/(speed*previous) or 1
 if speed>=S.min_speed and previous>=S.min_speed and
    a<=S.reverse_dot then
  if g.reversals==0 or time-g.first>S.window then
   g.reversals=1;g.first=time
  else g.reversals=g.reversals+1 end
 elseif g.reversals>0 and time-g.first>S.window then
  g.reversals=0
 end
 g.vx,g.vy,g.speed=vx,vy,speed
 if g.reversals<S.reversals_required or time-g.last_event<S.cooldown then return nil end
 g.reversals=0
 g.last_event=time
 g.events=g.events+1
 g.strength=math.min(1.0,math.max(.4,(speed+previous)/1700))
 -- Independent rotational components; avoids a fixed face/spin outcome.
 local spin={
  next_unit(g)*7*g.strength,
  next_unit(g)*7*g.strength,
  next_unit(g)*5*g.strength
 }
 g.last_spin=spin
 return spin
end

function S.recent(g,time)
 return g and g.events>0 and finite(time) and time-g.last_event<=.70
end
return S
