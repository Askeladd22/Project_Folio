local Parts = {}

-- Safety containment
Parts.containment = (function()
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
end)()

-- Body footprint
Parts.fps = (function()
-- XY component of fps_part_boundary_update, Free Physics Solver 1.2.5.
-- Copyright (c) 2024 Dice, MIT. See lib/licenses/LICENSE_fps.
-- The solver stores each corner already rotated and scaled about the body
-- origin. Translation is applied by the caller when testing the four walls.
local Bounds = {}

function Bounds.footprint(body)
    local first = body[1]
    local xmin, xmax = first[1], first[1]
    local ymin, ymax = first[2], first[2]
    for i = 2, #body do
        local vertex = body[i]
        xmin, xmax = math.min(xmin, vertex[1]), math.max(xmax, vertex[1])
        ymin, ymax = math.min(ymin, vertex[2]), math.max(ymax, vertex[2])
    end
    return xmin, xmax, ymin, ymax
end

return Bounds
end)()

-- Spawn clearance
Parts.spawn = (function()
-- Spawn-only SAT. Never called by the step/collision solver.
require('lib.core')
local S={margin=.01,same_side_attempts=32,other_side_attempts=96,scan_per_side=64}
local function axes(b)
 return {(b[2]-b[1]):norm(),(b[4]-b[1]):norm(),(b[5]-b[1]):norm()}
end
function S.intersects(a,pa,b,pb,margin)
 local aa,bb=axes(a),axes(b);local ns={}
 for _,n in ipairs(aa) do ns[#ns+1]=n end;for _,n in ipairs(bb) do ns[#ns+1]=n end
 for _,x in ipairs(aa) do for _,y in ipairs(bb) do local n=x^y;local l=n:abs();if l>1e-9 then ns[#ns+1]=n/l end end end
 for _,n in ipairs(ns) do
  local amin,amax,bmin,bmax=math.huge,-math.huge,math.huge,-math.huge
  for _,v in ipairs(a) do local p=(v+pa)..n;amin=math.min(amin,p);amax=math.max(amax,p) end
  for _,v in ipairs(b) do local p=(v+pb)..n;bmin=math.min(bmin,p);bmax=math.max(bmax,p) end
  if bmin-amax>=margin or amin-bmax>=margin then return false end
 end
 return true
end
local function private_rng(rows)
 -- Position-only seed: no face identity/value or extra gameplay RNG draw.
 local h=104729
 for _,r in ipairs(rows) do
  local s=string.format('%d:%.17g:%.17g:%.17g;',r.index,r.position[1],r.position[2],r.position[3])
  for j=1,#s do h=(h*131+s:byte(j))%2147483647 end
 end
 if h==0 then h=1 end
 return function()h=(h*48271)%2147483647;return (h-1)/2147483646 end,h
end
function S.place(rows,sample)
 local rnd,seed=private_rng(rows)
 local stats={seed=seed,retries=0,fallbacks=0,scans=0,moved=0,side_changes=0,failed=false,order={},sides={}}
 local order={};for i=1,#rows do order[i]=i end
 for i=#order,2,-1 do local j=math.floor(rnd()*i)+1;order[i],order[j]=order[j],order[i] end
 local placed,positions={},{}
 local function valid(row,p)
  for _,q in ipairs(placed) do if S.intersects(row.body,p,q.body,q.position,S.margin) then return false end end
  return true
 end
 for _,i in ipairs(order) do
  local row=rows[i];local p,side=row.position,row.side
  stats.order[#stats.order+1]=row.index
  if not valid(row,p) then
   p=nil
   for attempt=1,S.same_side_attempts do
    local candidate,cs=sample(row,rnd,row.side);stats.retries=stats.retries+1
    if valid(row,candidate) then p,side=candidate,cs;break end
   end
   if not p then
    stats.fallbacks=stats.fallbacks+1
    for attempt=1,S.other_side_attempts do
     local candidate,cs=sample(row,rnd,nil);stats.retries=stats.retries+1
     if valid(row,candidate) then p,side=candidate,cs;break end
    end
   end
   if not p then
    stats.scans=stats.scans+1
    local start=math.floor(rnd()*4);local offset=rnd()
    for step=0,3 do
     local side_scan=(start+step)%4+1
     for k=0,S.scan_per_side-1 do
      local u=(offset+k/S.scan_per_side)%1
      local candidate,cs=sample(row,function()return u end,side_scan)
      stats.retries=stats.retries+1
      if valid(row,candidate) then p,side=candidate,cs;break end
     end
     if p then break end
    end
   end
   if not p then stats.failed=true;S.last=stats;return nil,stats end
   stats.moved=stats.moved+1
  end
  if side~=row.side then stats.side_changes=stats.side_changes+1 end
  stats.sides[row.index]={row.side,side}
  positions[row.index]=p;placed[#placed+1]={body=row.body,position=p}
 end
 S.last=stats;return positions,stats
end
return S
end)()

return Parts
