local Parts = {}

-- Settled face inspection
Parts.face_state = (function()
require('lib.core')
local F={min_up=math.cos(math.rad(5)),min_gap=.8,floor_slop=.002}
function F.inspect(entry)
 local b=entry.body;local best,second=-math.huge,-math.huge;local face,up,scale
 for i,indices in ipairs(entry.die.faces) do
  local center=vector{0,0,0};for _,k in ipairs(indices) do center=center+b[k] end
  center=center/#indices
  if center[3]>best then second=best;best=center[3];face=i;scale=center:abs();up=best/scale
  elseif center[3]>second then second=center[3] end
 end
 local gap=(best-second)/(scale or 1);local floor=math.huge
 for _,v in ipairs(b) do floor=math.min(floor,v[3]+b.position[3]) end
 local mechanical=b.asleep==true and b.velocity:abs()<.15 and b.angular:abs()<.20
 local valid=up and up>=F.min_up and gap>=F.min_gap and floor>=-F.floor_slop
 return {mechanical=mechanical,valid=not not valid,face=face,up=up,gap=gap,floor=floor,
   reason=not mechanical and 'moving' or floor < -F.floor_slop and 'penetration' or not valid and 'ambiguous' or 'valid'}
end
return F
end)()

-- Roll resolution
Parts.resolution = (function()
local F=Parts.face_state
local M={timeout=20,max_retries=2,stable_delay=.15}
function M.new(indices) return {indices=indices,age=0,stable=0,retries=0,events={},done=false} end
function M.advance(s,dt,entries)
 if s.done or dt<=0 then return end
 s.age=s.age+dt
 local resting,valid=true,true;local reasons={}
 for _,i in ipairs(s.indices) do local q=F.inspect(entries[i]);resting=resting and q.mechanical;valid=valid and q.valid
  if not q.valid or not q.mechanical then reasons[#reasons+1]={index=i,state=q} end
 end
 if resting and valid then
  s.stable=s.stable+dt
  if s.stable>=M.stable_delay then s.done=true;return 'accept' end
  return
 end
 s.stable=0
 if resting or s.age>=M.timeout then
  local event={reason=resting and 'ambiguous' or 'timeout',age=s.age,retries=s.retries,details=reasons}
  s.events[#s.events+1]=event
  if s.retries>=M.max_retries then s.done=true;return 'failed',event end
  s.retries=s.retries+1;s.age=0;return 'retry',event
 end
end
return M
end)()

Parts.resolution.face_state = Parts.face_state
return Parts.resolution
