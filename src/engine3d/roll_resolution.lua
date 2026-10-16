local F=require('src.engine3d.face_state')
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
