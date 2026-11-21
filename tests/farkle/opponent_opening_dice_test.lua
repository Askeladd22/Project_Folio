local D=require('src.farkle.dice')
local entries={}
for i=1,6 do
 entries[i]={restPose={{.5,.5,.5},{-.5,-.5,-.5}},
  body={{.4,.2,-.7},{-.4,-.2,.7},position={8,-5,7},
   velocity={1,2,3},angular={2,2,1},_grabbed=true,_manual_pending=true}}
end
D.stage_opening(entries)
for i,e in ipairs(entries) do
 local b=e.body
 assert(b.asleep and not b._grabbed and not b._manual_pending)
 assert(b.position[2]>2 and b.position[3]+b[2][3]==0)
 for k=1,3 do assert(b.velocity[k]==0 and b.angular[k]==0) end
 for j=1,i-1 do
  local other=entries[j].body.position
  assert(math.abs(other[1]-b.position[1])>1 or math.abs(other[2]-b.position[2])>1)
 end
end
print('PASS opening rack: six distinct positions, supported rest pose and reset velocities')
