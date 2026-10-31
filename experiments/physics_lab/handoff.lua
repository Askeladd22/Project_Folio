-- FPS held-body -> ORIGINAL Manuscript D6 physical-body handoff.
-- Experimental only; NEVER loaded by src/app or release builds.
-- FPS emits *world-space* vertices; Manuscript stores *local* vertices
-- separately from body.position. A blind vertex copy would double-translate.
local O=require('experiments.physics_lab.old')
local M={}
local function finite(x)
 return type(x)=='number' and x==x and math.abs(x)<math.huge
end
local function dist(a,b)
 local d=0
 for j=1,3 do d=d+(a[j]-b[j])^2 end
 return math.sqrt(d)
end
-- Vertex order is immutable and shared with Manuscript geometry.d6:
-- first upper rectangle, second lower rectangle, matching pip face map.
local edges={{1,2},{2,3},{3,4},{4,1},
 {5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
local function valid3(a)
 if type(a)~='table' or #a~=3 then return false end
 for i=1,3 do if not finite(a[i]) then return false end end
 return true
end
local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
local function diff(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
function M.check(state)
 if type(state)~='table' or not valid3(state.position) or
  not valid3(state.velocity) or not valid3(state.angular) or
  type(state.vertices)~='table' or #state.vertices~=8 then
  return false,'missing/invalid physical transform or velocities'
 end
 for _,p in ipairs(state.vertices) do
  if not valid3(p) then return false,'non-finite world-space vertex' end
 end
 -- Preserve a rigid, right-handed, non-distorted *1.25-unit* D6.
 -- Crucial for face mapping, shadow bounds and collision radius.
 local edge=1.25
 for _,pair in ipairs(edges) do
  local length=dist(state.vertices[pair[1]],state.vertices[pair[2]])
  if math.abs(length-edge)>.025 then
   return false,'FPS transform distorted a physical D6 edge'
  end
 end
 local x=diff(state.vertices[4],state.vertices[1])
 local y=diff(state.vertices[2],state.vertices[1])
 local z=diff(state.vertices[5],state.vertices[1])
 if math.abs(dot(x,y))>.08 or math.abs(dot(x,z))>.08 or
    math.abs(dot(y,z))>.08 then
  return false,'FPS transform is not orthogonal'
 end
 local cross={x[2]*y[3]-x[3]*y[2],
              x[3]*y[1]-x[1]*y[3],
              x[1]*y[2]-x[2]*y[1]}
 -- x and y point toward decreasing local x and y, z negative:
 -- their handedness is flipped for this vertex order.
 if dot(cross,z)>-.01 then return false,'FPS transform flipped handedness' end
 local center={0,0,0}
 for _,p in ipairs(state.vertices) do
  for k=1,3 do center[k]=center[k]+p[k]/8 end
 end
 if dist(center,state.position)>.02 then
  return false,'world vertices and rigid body origin disagree'
 end
 return true
end

function M.handoff(rows)
 assert(type(rows)=='table' and #rows>=1 and #rows<=6,
  'handoff requires one through six complete D6 bodies')
 -- Validate *every* body first: no partial handoff on a corrupt FPS state.
 for i,state in ipairs(rows) do
  local ok,reason=M.check(state)
  assert(ok,'FPS handoff die '..i..': '..tostring(reason))
 end
 local world=O.new(rows)
 for i,state in ipairs(rows) do
  local body=world[i]
  -- O.new already sets position, velocity, angular, material and identity.
  -- Override just the local physical vertices (world - center).
  for corner,p in ipairs(state.vertices) do
   body[corner]=vector{p[1]-body.position[1],
                       p[2]-body.position[2],
                       p[3]-body.position[3]}
  end
  body.asleep=false
  body.sleep_timer=0
  body._manual_pending=false
  body._grabbed=false
 end
 return world
end
function M.error(rows,world)
 local maximum_position,maximum_vertex,maximum_velocity,maximum_spin=0,0,0,0
 local snapshot=O.snapshot(world)
 for i,s in ipairs(rows) do
  maximum_position=math.max(maximum_position,dist(s.position,snapshot[i].position))
  for j=1,8 do
   maximum_vertex=math.max(maximum_vertex,dist(s.vertices[j],snapshot[i].vertices[j]))
  end
  local b=world[i]
  maximum_velocity=math.max(maximum_velocity,
    dist(s.velocity,{b.velocity[1],b.velocity[2],b.velocity[3]}))
  maximum_spin=math.max(maximum_spin,
    dist(s.angular,{b.angular[1],b.angular[2],b.angular[3]}))
 end
 return {position=maximum_position,vertex=maximum_vertex,
         velocity=maximum_velocity,spin=maximum_spin}
end
return M
