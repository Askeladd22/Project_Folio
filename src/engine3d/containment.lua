-- Safety-region correction, distinct from body:box physical wall impulses.
-- Relative numerical tolerance: 1000x below the legacy .001 contact tolerance.
-- This is a wake-up tolerance, NOT permission to leave penetration uncorrected.
local C={relative_position_epsilon=1e-6,linear_sleep=.15,angular_sleep=.20}
function C.apply(b,x,y,vx,vy,supported)
 if supported==nil then
  -- Legacy solver has no support manifold. Use its existing ground band;
  -- absence of measured support must not preserve sleep in mid-air.
  supported=false
  for _,v in ipairs(b) do if v[3]+b.position[3]<=.05 then supported=true;break end end
 end
 local dx,dy=x-b.position[1],y-b.position[2]
 local displacement=math.sqrt(dx*dx+dy*dy)
 local speed=b.velocity:abs();local spin=b.angular:abs()
 b.position[1],b.position[2]=x,y;b.velocity[1],b.velocity[2]=vx,vy
 local wake=displacement>C.relative_position_epsilon*math.max(1,b.radius or 1)
   or speed>=C.linear_sleep or spin>=C.angular_sleep or supported==false
 if wake then b.asleep=false;b.sleep_timer=0 end
 return wake,displacement
end
return C
