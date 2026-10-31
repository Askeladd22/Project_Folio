-- FPS -> original Manuscript physics HANDOFF study, never gameplay.
-- The complete oriented die mesh, velocities and physical face IDs are
-- transferred before any gravity/contact step. No fake face values.
local N=require('experiments.physics_lab.fps')
local O=require('experiments.physics_lab.old')
local H=require('experiments.physics_lab.handoff')
local M=require('experiments.physics_lab.metrics')
local schema=require('src.data.dice_scene_schema').box
local function input(seed)
 local rows={}
 for i=1,6 do
  local col=(i-1)%3
  local row=math.floor((i-1)/3)
  rows[i]={
   position={(col-1)*2.15+.10*math.sin(seed*7+i*3),
             (row-.5)*2.10+.1*math.cos(seed*5+i*2),
             3.15+.04*i},
   velocity={0,0,0},angular={0,0,0}
  }
 end
 return rows
end
local function overlap_count(rows)
 local count,maxdepth=0,0
 for i=1,#rows do for j=i+1,#rows do
  local depth=M.overlap(rows[i],rows[j])
  if depth>.0001 then count=count+1 end
  maxdepth=math.max(maxdepth,depth)
 end end
 return count,maxdepth
end
local function nonfinite(rows)
 for _,s in ipairs(rows) do
  for _,v in ipairs(s.position) do
   if v~=v or math.abs(v)>100 then return true end
  end
 end
 return false
end
local seeds=tonumber(arg and arg[1]) or 8
assert(seeds>=1 and seeds<=64 and seeds%1==0,'seed count must be 1..64')
local rounds=0
local worst_snap=0
local worst_first_step=0
local worst_overlap=0
local total_invalid,total_unsettled=0,0
local failure_count=0
local first_example
local by_mode={
 native={runs=0,first_step=0,envelope=0,max_overlap=0,invalid=0},
 compatible={runs=0,first_step=0,envelope=0,max_overlap=0,invalid=0}
}
for seed=1,seeds do
 for variant=1,4 do
  local compatible=(variant>2)
  local moving=(variant%2==0)
  local mode=compatible and 'compatible' or 'native'
  local metrics=by_mode[mode]
  local world,n=N.new(input(seed))
  for i=1,n do
   N.set_euler(world,i,.18*math.sin(i+seed),.22*math.cos(i+seed),.12*i)
  end
  -- Same force-based gripping as Lab 4. Force contacts enabled.
  -- 240 steps x .005s = 1.2s of pickup, before immediate release.
  for step=1,240 do
   local time=step*.005
   local hand={0,0,3.35}
   local shake=0
   if moving then
    hand[1]=.9*math.sin(3.4*time)
    hand[2]=.6*math.cos(4.1*time)
    hand[3]=3.35+.18*math.sin(2*time)
    shake=5*math.sin(13*time)
   end
   if compatible then
    N.grip_step_compatible(world,hand,.005,23,8,shake,1.64,180)
   else
    N.grip_step(world,hand,.005,23,8,shake,true)
   end
  end
  local original=N.snapshot(world,n)
  local pairs,overlap=overlap_count(original)
  worst_overlap=math.max(worst_overlap,overlap)
  local handoff=H.handoff(original)
  local maxEnvelope=0
  for i=1,n do for j=i+1,n do
   local ai,aj=handoff[i],handoff[j]
   local dx=ai.position[1]-aj.position[1]
   local dy=ai.position[2]-aj.position[2]
   local dz=ai.position[3]-aj.position[3]
   local separation=math.sqrt(dx*dx+dy*dy+dz*dz)
   maxEnvelope=math.max(maxEnvelope,
       math.max(0,ai.radius+aj.radius-separation))
  end end
  metrics.envelope=math.max(metrics.envelope,maxEnvelope)
  metrics.max_overlap=math.max(metrics.max_overlap,overlap)
  local err=H.error(original,handoff)
  local maxerr=math.max(err.vertex,err.position,err.velocity,err.spin)
  worst_snap=math.max(worst_snap,maxerr)
  -- Face numbers must remain *exactly* the same across solvers.
  local imported=O.snapshot(handoff)
  for i=1,n do
   local oldFace=M.top_value(original[i])
   local newFace=M.top_value(imported[i])
   assert(oldFace==newFace,'handoff changed D6 face mapping')
   assert(not handoff[i]._manual_pending and not handoff[i].asleep,
    'imported dice must resume live production gravity/collisions')
  end
  assert(maxerr<.00001,'handoff itself must not move or reorient a D6')
  O.step(handoff,.01)
  local immediately=O.snapshot(handoff)
  assert(not nonfinite(immediately),'first production physics step produced invalid position')
  for i=1,n do
   local a,b=original[i].position,immediately[i].position
   local move=math.sqrt((a[1]-b[1])^2+(a[2]-b[2])^2+(a[3]-b[3])^2)
   worst_first_step=math.max(worst_first_step,move)
   metrics.first_step=math.max(metrics.first_step,move)
  end
  local out=M.new()
  M.observe(out,immediately,.01,schema.half_x,schema.half_y)
  for step=2,500 do
   O.step(handoff,.01)
   if step%10==0 then
    local bodies=O.snapshot(handoff)
    assert(not nonfinite(bodies),'unbounded physical position after handoff')
    M.observe(out,bodies,step*.01,schema.half_x,schema.half_y)
   end
  end
  local final=O.snapshot(handoff)
  M.finish(out,final)
  total_invalid=total_invalid+out.invalid_faces
  total_unsettled=total_unsettled+out.unsettled
  if out.invalid_faces>0 then failure_count=failure_count+1 end
  rounds=rounds+1
  metrics.runs=metrics.runs+1
  metrics.invalid=metrics.invalid+out.invalid_faces
  if not first_example then first_example={pairs=pairs,overlap=overlap} end
 end
end
print(string.format('HANDOFF runs=%d dice=%d transferMax=%.9f firstStepMax=%.5f fpsGripPeakFinalOverlap=%.5f',
 rounds,rounds*6,worst_snap,worst_first_step,worst_overlap))
for _,mode in ipairs({'native','compatible'}) do
 local m=by_mode[mode]
 print(string.format('HANDOFF_MODE %s runs=%d dice=%d firstStepMax=%.5f envelopeDeficit=%.5f fpsOverlap=%.5f invalid=%d',
 mode,m.runs,m.runs*6,m.first_step,m.envelope,m.max_overlap,m.invalid))
end
print(string.format('HANDOFF finalInvalid=%d/%d unsettled=%d failingRuns=%d/%d initialOverlapPairs=%d initialOverlap=%.5f',
 total_invalid,rounds*6,total_unsettled,failure_count,rounds,
 first_example.pairs,first_example.overlap))
print('HANDOFF NOTE: Matching pose/velocity at the instant of transfer is a separate gate from physical landing and scoring.')
assert(worst_snap<.00001,'lossless physical transfer is required for any hybrid')
print('PASS FPS Lab 5: validated exact pose+motion transfer, same D6 faces and production drop simulation')
