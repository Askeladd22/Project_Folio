-- Project Folio: die-vs-die oriented-box contacts (SAT + swept SAT).
-- Deliberately not a port or embedding of Free Physics Solver.
-- Six D6 only; no extra physics library and no change to renderer or Farkle.
require('lib.core')
local C={}
local abs,min,max,sqrt=math.abs,math.min,math.max,math.sqrt
local EPS=1e-8
local pair_slop=1e-5
local approach_epsilon=.001

local function dot(a,b)
 return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]
end
local function cross(a,b)
 return {a[2]*b[3]-a[3]*b[2],
         a[3]*b[1]-a[1]*b[3],
         a[1]*b[2]-a[2]*b[1]}
end
local function sub(a,b)
 return {a[1]-b[1],a[2]-b[2],a[3]-b[3]}
end
local function addscaled(a,b,t)
 return {a[1]+b[1]*t,a[2]+b[2]*t,a[3]+b[3]*t}
end
local function unit(a)
 local length=sqrt(dot(a,a))
 if length<EPS then return nil end
 return {a[1]/length,a[2]/length,a[3]/length}
end
local function signed(axis,a,b,relative)
 local d=dot(sub(b,a),axis)
 if abs(d)<EPS then d=-dot(relative or {0,0,0},axis) end
 local sign=d>=0 and 1 or -1
 return {axis[1]*sign,axis[2]*sign,axis[3]*sign}
end

-- The D6 geometry indexes the three mutually perpendicular edges
-- 1->2, 1->4 and 1->5. All vertices already carry live rotation.
local function axes(a,b)
 local aa={unit(sub(a[2],a[1])),unit(sub(a[4],a[1])),
           unit(sub(a[5],a[1]))}
 local bb={unit(sub(b[2],b[1])),unit(sub(b[4],b[1])),
           unit(sub(b[5],b[1]))}
 local out={}
 for _,v in ipairs(aa) do if v then out[#out+1]=v end end
 for _,v in ipairs(bb) do if v then out[#out+1]=v end end
 for _,av in ipairs(aa) do
  if av then for _,bv in ipairs(bb) do
   if bv then
    local n=unit(cross(av,bv))
    if n then out[#out+1]=n end
   end
  end end
 end
 assert(#out>=3,'degenerate die collider')
 return out
end
local function project(body,pos,axis)
 local p=dot(body[1],axis)
 local lo,hi=p,p
 for i=2,#body do
  p=dot(body[i],axis)
  lo=min(lo,p);hi=max(hi,p)
 end
 local t=dot(pos,axis)
 return lo+t,hi+t
end
local function support(body,axis,largest)
 local extreme=largest and -math.huge or math.huge
 for i=1,#body do
  local p=dot(body[i],axis)
  if largest then extreme=max(extreme,p) else extreme=min(extreme,p) end
 end
 local sum={0,0,0};local n=0
 for i=1,#body do
  if abs(dot(body[i],axis)-extreme)<1e-5 then
   for k=1,3 do sum[k]=sum[k]+body[i][k] end
   n=n+1
  end
 end
 for k=1,3 do sum[k]=body.position[k]+sum[k]/n end
 return sum
end
local function contact(a,b,normal)
 local pa=support(a,normal,true)
 local pb=support(b,normal,false)
 return {(pa[1]+pb[1])*.5,(pa[2]+pb[2])*.5,
         (pa[3]+pb[3])*.5}
end

-- Normal points from A to B. Disjoint boxes produce NO physical impulse
-- or positional correction even if their legacy bounding spheres overlap.
function C.overlap(a,b)
 local normal,depth
 local relative=sub(b.velocity,a.velocity)
 for _,axis in ipairs(axes(a,b)) do
  local alo,ahi=project(a,a.position,axis)
  local blo,bhi=project(b,b.position,axis)
  local amount=min(ahi,bhi)-max(alo,blo)
  if amount<=EPS then return nil end
  if not depth or amount<depth then
   depth=amount
   normal=signed(axis,a.position,b.position,relative)
  end
 end
 return {normal=normal,depth=depth,swept=false}
end

-- Linear swept SAT over the previous fixed step. Orientation is frozen
-- to the END-step shape; fast angular tunnelling is a remaining limit.
-- Relative interval intersection finds contact even when both end apart.
function C.sweep(a,b,old_a,old_b)
 local da=sub(a.position,old_a)
 local db=sub(b.position,old_b)
 local relative=sub(db,da)
 if dot(relative,relative)<EPS*EPS then return nil end
 local enter,leave=0,1
 local hit_axis
 local separated_at_start=false
 for _,axis in ipairs(axes(a,b)) do
  local alo,ahi=project(a,old_a,axis)
  local blo,bhi=project(b,old_b,axis)
  if ahi<blo-EPS or bhi<alo-EPS then separated_at_start=true end
  local v=dot(relative,axis)
  if abs(v)<EPS then
   if ahi<blo-EPS or bhi<alo-EPS then return nil end
  else
   local t1=(alo-bhi)/v
   local t2=(ahi-blo)/v
   local first=min(t1,t2)
   local last=max(t1,t2)
   if first>enter then enter=first;hit_axis=axis end
   leave=min(leave,last)
   if enter>leave+EPS then return nil end
  end
 end
 if not separated_at_start or not hit_axis or enter<0 or enter>1
   or leave<0 then return nil end
 local at_a=addscaled(old_a,da,enter)
 local at_b=addscaled(old_b,db,enter)
 local normal=signed(hit_axis,at_a,at_b,relative)
 if dot(sub(b.velocity,a.velocity),normal)>=-EPS then return nil end
 return {normal=normal,depth=0,swept=true,toi=enter,
   old_a=old_a,old_b=old_b,da=da,db=db}
end

local function inverse_mass(body)
 if body._kept_solid then return 0 end
 return body.mass and body.mass>0 and 1/body.mass or 0
end
local function inverse_inertia(body)
 if body._kept_solid then return 0 end
 return body.theta and body.theta>0 and 1/body.theta or 0
end
local function effective_mass(a,b,ra,rb,axis)
 local arot=cross(ra,axis)
 local brot=cross(rb,axis)
 return inverse_mass(a)+inverse_mass(b)+
   dot(arot,arot)*inverse_inertia(a)+dot(brot,brot)*inverse_inertia(b)
end

-- Contact-relative velocity includes angular velocity. This feeds the
-- existing body:push(impulse, displacement) rotational pathway.
local function at_point(body,r)
 return body.velocity+(body.angular^vector(r))
end
function C.resolve(world,a,b,index_a,index_b,hit,dt,emitted_pairs)
 if not hit then return false end
 local n=vector(hit.normal)
 if hit.swept then
  -- Rewind the two translations to the first swept contact.
  -- Keep their current orientation; no mutation of gameplay RNG.
  if not a._kept_solid then a.position=vector(addscaled(hit.old_a,hit.da,hit.toi)) end
  if not b._kept_solid then b.position=vector(addscaled(hit.old_b,hit.db,hit.toi)) end
 else
  local im_a,im_b=inverse_mass(a),inverse_mass(b)
  local im=im_a+im_b
  if im>0 and hit.depth>pair_slop then
   local correction=n*((hit.depth-pair_slop)*.92/im)
   a.position=a.position-correction*im_a
   b.position=b.position+correction*im_b
  end
 end
 local cp=contact(a,b,n)
 local ra=vector(sub(cp,a.position))
 local rb=vector(sub(cp,b.position))
 local relative=at_point(b,rb)-at_point(a,ra)
 local speed=relative..n
 -- A tolerated overlap without an approaching contact applies no response.
 -- Preserve both sleep timers and skip further iterations for this pair.
 if not hit.swept and hit.depth<=pair_slop and speed>=-approach_epsilon then
  return false
 end
 if speed < -approach_epsilon then
  local denom=effective_mass(a,b,ra,rb,n)
  if denom>EPS then
   local ea=a.restitution or world.bounce or 0.3
   local eb=b.restitution or world.bounce or 0.3
   local e=min(ea,eb)
   local j=-(1+e)*speed/denom
   local impulse=n*j
   local pair_key=index_a..':'..index_b
   if world.on_contact and not (emitted_pairs and emitted_pairs[pair_key]) then
    if emitted_pairs then emitted_pairs[pair_key]=true end
    world.on_contact(world,'pair',index_a,index_b,-speed)
   end
   if not a._kept_solid then a:push(-impulse,ra) end
   if not b._kept_solid then b:push(impulse,rb) end
   local tang=at_point(b,rb)-at_point(a,ra)
   tang=tang-n*(tang..n)
   local length=tang:abs()
   if length>EPS then
    local t=tang/length
    local denom_t=effective_mass(a,b,ra,rb,t)
    if denom_t>EPS then
     local fa=a.friction or world.friction or 0.6
     local fb=b.friction or world.friction or 0.6
     local mu=sqrt(max(0,fa)*max(0,fb))
     local jt=min(length/denom_t,mu*j)
     local friction=t*jt
     if not a._kept_solid then a:push(friction,ra) end
     if not b._kept_solid then b:push(-friction,rb) end
    end
   end
   a._last_collision={other=index_b}
   b._last_collision={other=index_a}
  end
 end
 if hit.swept then
  -- body:push intentionally caps enormous impulse deltas (dv_max=50).
  -- A fast CCD hit may therefore remain closing after the bounded
  -- bounce. Project out ONLY the residual approaching center velocity,
  -- conserving linear momentum; do not integrate back through contact.
  -- This is an inelastic emergency safety correction, not extra bounce.
  local closing=(b.velocity-a.velocity)..n
  local im_a,im_b=inverse_mass(a),inverse_mass(b)
  local inv_total=im_a+im_b
  if closing<-.000001 and inv_total>EPS then
   local residual=(-closing)/inv_total
   a.velocity=a.velocity-n*(residual*im_a)
   b.velocity=b.velocity+n*(residual*im_b)
   world.ccd_safety_stops=(world.ccd_safety_stops or 0)+1
  end
  local remain=max(0,1-hit.toi)*dt
  if not a._kept_solid then a.position=a.position+a.velocity*remain end
  if not b._kept_solid then b.position=b.position+b.velocity*remain end
 end
 if not a.asleep or not b.asleep then
  if not a._kept_solid then a.asleep=false;a.sleep_timer=0 end
  if not b._kept_solid then b.asleep=false;b.sleep_timer=0 end
 end
 return true
end

-- At six dice an all-pairs SAT test is bounded (15 pairs × up to 15
-- separating axes). No new spatial tree or new physics dependencies.
function C.solve(world,old_positions,dt,emitted_pairs)
 local hits=0
 emitted_pairs=emitted_pairs or {}
 -- First pass handles swept time-of-impact. Later passes only recheck
 -- present-time overlaps: moving the middle die in a chain may reopen
 -- penetration in a pair already visited. Four bounded Gauss-Seidel
 -- passes are sufficient for six dice without a new physics engine.
 local passes=world.pair_solver_passes or 6
 assert(passes>=1 and passes<=8 and passes%1==0,
  'bounded pair_solver_passes (1..8) required')
 for pass=1,passes do
  local touched=false
  for i=1,#world-1 do
   local a=world[i]
   -- Held dice are excluded; scored dice have zero inverse mass,
   -- retain their orientation, but remain genuine collision obstacles.
   -- Sleeping is NOT proof of non-penetration: a pair can already be
   -- overlapping on the frame it settles or after staging/containment.
   -- Resolve those static overlaps without waking a quiet pair.
   if not a._manual_pending or a._kept_solid then
    for j=i+1,#world do
     local b=world[j]
     if (not b._manual_pending or b._kept_solid)
       and not (a._kept_solid and b._kept_solid)
       then
      local hit
      if pass==1 and old_positions and old_positions[i] and old_positions[j] then
       hit=C.sweep(a,b,old_positions[i],old_positions[j])
      end
      if not hit then hit=C.overlap(a,b) end
      if hit and C.resolve(world,a,b,i,j,hit,dt,emitted_pairs) then
       hits=hits+1
       touched=true
      end
     end
    end
   end
  end
  if not touched then break end
 end
 return hits
end
return C
