-- Force-following six-die grip in the ISOLATED native FPS lab.
-- Unlike the visual layout in Manuscript, all six bodies chase ONE target.
-- Compare colliding/non-colliding FPS worlds under an identical hand motion.
-- Do not interpret these holding-only results as a valid Farkle landing test.
local N=require('experiments.physics_lab.fps')
local M=require('experiments.physics_lab.metrics')
local function initial()
 local rows={}
 for i=1,6 do
  local col=(i-1)%3
  local line=math.floor((i-1)/3)
  rows[i]={
   position={(col-1)*2.1,(line-.5)*2.1,3+line*.18},
   velocity={0,0,0},angular={0,0,0}
  }
 end
 return rows
end
local function distance(a,b)
 local dx,dy,dz=a[1]-b[1],a[2]-b[2],a[3]-b[3]
 return math.sqrt(dx*dx+dy*dy+dz*dz)
end
local function summarize(bodies,hand)
 local n=#bodies
 local sumdist,intersections,depth=0,0,0
 local nearest=math.huge
 for i,a in ipairs(bodies) do
  sumdist=sumdist+distance(a.position,hand)
  for j=i+1,n do
   local b=bodies[j]
   local overlap=M.overlap(a,b)
   if overlap>1e-4 then
    intersections=intersections+1
    depth=math.max(depth,overlap)
   end
   nearest=math.min(nearest,distance(a.position,b.position))
  end
 end
 return {mean_distance=sumdist/n,overlap_pairs=intersections,
         max_overlap=depth,min_centers=nearest}
end
local function simulate(enabled,moving)
 local world,n=N.new(initial())
 local first=summarize(N.snapshot(world,n),{0,0,3.2})
 local hand={0,0,3.2}
 local observed={peak_overlap=0,overlap_frames=0,closest=math.huge,peak_distance=0}
 local frames=320
 for step=1,frames do
  local t=step*.005
  if moving then
   hand[1]=.88*math.sin(2.3*t)
   hand[2]=.50*math.sin(3.1*t+.3)
   hand[3]=3.2+.14*math.cos(3.1*t)
  end
  local shake=moving and 4.0*math.sin(14*t) or 0
  N.grip_step(world,hand,.005,23,8,shake,enabled)
  if step%10==0 or step==frames then
   local state=N.snapshot(world,n)
   local a=summarize(state,hand)
   observed.peak_overlap=math.max(observed.peak_overlap,a.max_overlap)
   observed.peak_distance=math.max(observed.peak_distance,a.mean_distance)
   observed.closest=math.min(observed.closest,a.min_centers)
   if a.overlap_pairs>0 then observed.overlap_frames=observed.overlap_frames+1 end
   for _,body in ipairs(state) do
    for _,v in ipairs(body.position) do
     assert(v==v and math.abs(v)<100,
       'force grip must not generate non-finite or runaway positions')
    end
   end
  end
 end
 local endstate=N.snapshot(world,n)
 local finish=summarize(endstate,hand)
 assert(finish.mean_distance<first.mean_distance,
   'all held bodies should approach their shared hand point')
 return {initial=first,final=finish,observed=observed,frames=frames}
end
local variants={
 {name='static_no_contacts',collisions=false,moving=false},
 {name='static_contacts',collisions=true,moving=false},
 {name='moving_no_contacts',collisions=false,moving=true},
 {name='moving_contacts',collisions=true,moving=true},
}
local results={}
for _,v in ipairs(variants) do
 local out=simulate(v.collisions,v.moving)
 results[v.name]=out
 print(string.format('GRIP %s: initialDist=%.3f finalDist=%.3f overlapPairs=%d maxOverlap=%.4f peakOverlap=%.4f minCenters=%.3f overlapFrames=%d',
    v.name,out.initial.mean_distance,out.final.mean_distance,
    out.final.overlap_pairs,out.final.max_overlap,
    out.observed.peak_overlap,out.final.min_centers,
    out.observed.overlap_frames))
end
assert(results.static_no_contacts.final.mean_distance<
       results.static_no_contacts.initial.mean_distance*.65,
       'spring must materially converge the free bodies toward the hand')
local free=results.static_no_contacts.final
local colliding=results.static_contacts.final
print(string.format('GRIP_COMPARE still_hand: contactsDepth=%.4f noContactsDepth=%.4f contactsPairs=%d noContactsPairs=%d',
 colliding.max_overlap,free.max_overlap,
 colliding.overlap_pairs,free.overlap_pairs))
print('NOTE: This lab tests holding only, not floor collision, drop settling, face validity or production safety.')
print('PASS FPS Lab 4: six force-driven real bodies chase one hand; optional native contacts remain experimental')
