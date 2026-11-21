local D={}
local face_texture=require('src.engine3d.geometry').face_texture
function D.values(build,index)
 return {1,6,3,5,4,(build=='engraved' and index==1) and 1 or 2}
end
function D.accept(value,u) return value==1 or u<.5 end
function D.probabilities(build,index)
 if index==1 and build=='weighted' then return {2/7,1/7,1/7,1/7,1/7,1/7} end
 if index==1 and build=='engraved' then return {2/6,0,1/6,1/6,1/6,1/6} end
 return {1/6,1/6,1/6,1/6,1/6,1/6}
end
local risks={}
function D.risk(build,indices)
 local weighted=false;for _,i in ipairs(indices) do if i==1 then weighted=true end end
 local key=build..':'..#indices..':'..tostring(weighted);if risks[key] then return risks[key] end
 local c={0,0,0,0,0,0};local sum=0
 local function visit(j,p)
  if j>#indices then
   local pairs=0;for _,n in ipairs(c) do if n==2 then pairs=pairs+1 end end
   if #indices~=6 or pairs~=3 then sum=sum+p end
   return
  end
  local dist=D.probabilities(build,indices[j])
  -- Bust requires no 1/5, triple or three pairs. Straights contain a 5;
  -- full house and two triples necessarily contain a triple.
  for _,v in ipairs({2,3,4,6}) do if c[v]<2 and dist[v]>0 then c[v]=c[v]+1;visit(j+1,p*dist[v]);c[v]=c[v]-1 end end
 end
 visit(1,1);risks[key]=sum;return sum
end
-- Stage the real bodies only when opening a run. A settled hand is never
-- rearranged, and the next roll still goes through the physical launcher.
function D.stage_opening(entries)
 for i,entry in ipairs(entries) do
  local b=entry.body
  local lowest=math.huge
  for index,v in ipairs(b) do
   local rest=entry.restPose[index]
   v[1],v[2],v[3]=rest[1],rest[2],rest[3]
   lowest=math.min(lowest,v[3])
  end
  b.position[1]=((i-1)%3-1)*1.85
  b.position[2]=2.55+math.floor((i-1)/3)*1.85
  b.position[3]=-lowest
  for axis=1,3 do b.velocity[axis]=0;b.angular[axis]=0 end
  b.asleep=true;b._grabbed=nil;b._manual_pending=nil
  b._kept_solid=nil -- returned to the physical hand
 end
end
-- Keep scored dice physically on the board instead of replacing them with UI icons.
-- Their die IDs and settled face orientation are unchanged; they cannot be
-- picked up or included in subsequent throws until the next turn/hot dice.
function D.stage_kept(entries,used)
 -- Staging is a teleport, NOT a physics step. It must not put a scored,
 -- immovable die inside an active die and then hope that the solver wakes.
 -- Probe the real oriented D6 shapes before committing to a rear slot.
 local Collision=require('src.engine3d.die_collision')
 local rear_y=-4.45
 local function vacant(entry,index,x,y)
  local body=entry.body
  if #body<8 then return true end -- miniature fixtures cannot support SAT
  -- Probing a candidate must not itself teleport the visible D6.
  -- In particular, a failed probe must leave a previously scored D6
  -- at its settled position rather than at the last rejected slot.
  local old_x,old_y=body.position[1],body.position[2]
  body.position[1],body.position[2]=x,y
  local free=true
  for j,other in ipairs(entries) do
   local test=other.body
   if j~=index and test and test.position and #test>=8
     and Collision.overlap(body,test) then
    free=false;break
   end
  end
  body.position[1],body.position[2]=old_x,old_y
  return free
 end
 for i,entry in ipairs(entries or {}) do
  if used and used[i] then
   local b=entry.body
   if b and b.position then
    local lowest=math.huge
    for _,v in ipairs(b) do lowest=math.min(lowest,v[3]) end
    if lowest<math.huge then
     local target_x=(i-3.5)*2.0
     local chosen_x,chosen_y
     b.position[3]=-lowest
     -- A previously scored body is already an object on the table.
     -- Re-scoring another die must not silently teleport that object
     -- back toward its preferred numbered slot.
     if b._kept_solid and vacant(entry,i,b.position[1],b.position[2]) then
      chosen_x,chosen_y=b.position[1],b.position[2]
     else
      -- Preserve the familiar rear row for newly scored dice. Probe
      -- each slot without mutating the body until one is proven free.
      local candidates={target_x,-10,-8,-6,-4,-2,0,2,4,6,8,10}
      for _,x in ipairs(candidates) do
       if vacant(entry,i,x,rear_y) then
        chosen_x,chosen_y=x,rear_y;break
       end
      end
     end
     assert(chosen_x,'no collision-free rear slot for a kept D6')
     b.position[1],b.position[2]=chosen_x,chosen_y
     for axis=1,3 do b.velocity[axis]=0;b.angular[axis]=0 end
     b.asleep=true;b.sleep_timer=999
     -- A scored D6 is kinematic but SOLID to the next moving die;
     -- an unreleased die is kinematic and NON-colliding instead.
     b._manual_pending=true
     b._kept_solid=true
    end
   end
  end
 end
end
function D.install(build)
 for i,entry in ipairs(dice) do
  local die=entry.die;die.faceValueMap=D.values(build,i);die.pipMap=die.faceValueMap
  die.faceColors={};for f=1,6 do die.faceColors[f]=(i==1 and build~='normal') and {157,113,47,255} or {74,54,35,255} end
  -- Unlike the original d6.image closure, this reads this individual die's map.
  die.image=function(face,a,b,c,d,e,f,g,h)
   if not (a and b and c and d and g and h) then return end
   local img=love.graphics.getImage('resources/dice/'..die.faceValueMap[face]..'.png')
   love.graphics.setColor(1,1,1,1)
   face_texture.draw(img,a,b,c,d,e,f,g,h)
  end
 end
end
return D
