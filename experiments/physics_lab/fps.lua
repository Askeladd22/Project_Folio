-- LuaJIT FFI adapter, intentionally never imported by normal Manuscript.
local ffi=require('ffi')
local schema=require('src.data.dice_scene_schema').box
ffi.cdef[[
typedef struct fpslab fpslab;
fpslab *fpslab_new(int n,const float *states,float edge,float hx,float hy,float rim,float gravity);
void fpslab_free(fpslab *);
int fpslab_step(fpslab *,float dt);
int fpslab_state(const fpslab *,int index,float *out22);
int fpslab_sleeping(const fpslab *,int index);
int fpslab_floor_guard(fpslab *,float *max_depth);
int fpslab_probe(const fpslab *,float *out4);
int fpslab_step_support(fpslab *,float dt);
int fpslab_set_euler(fpslab *,int index,float rx,float ry,float rz);
int fpslab_version(void);
]]
local so=ffi.os=='Windows' and './experiments/physics_lab/build/fpslab.dll'
  or './experiments/physics_lab/build/libfpslab.so'
local ok,lib=pcall(ffi.load,so)
if not ok then error('Build native FPS first: '..tostring(lib)) end
assert(lib.fpslab_version()==125,'Pinned FPS bridge version mismatch')
local N={}
local local_vertices={
 {1,1,1},{1,-1,1},{-1,-1,1},{-1,1,1},
 {1,1,-1},{1,-1,-1},{-1,-1,-1},{-1,1,-1}
}
function N.new(rows)
 local data=ffi.new('float[?]',#rows*9)
 for i,row in ipairs(rows) do
  local v={row.position,row.velocity,row.angular}
  for j=1,3 do for k=1,3 do
   data[(i-1)*9+(j-1)*3+(k-1)]=v[j][k]
  end end
 end
 local edge=2*(1/1.6) -- geometry.newD6Body(1.0)
 local world=lib.fpslab_new(#rows,data,edge,schema.half_x,schema.half_y,
                            schema.border_height,schema.gravity)
 assert(world~=nil,'FPS native world creation failed')
 return ffi.gc(world,lib.fpslab_free),#rows
end
function N.step(world,dt)
 assert(lib.fpslab_step(world,dt)==1,'FPS step failed')
end
-- Explicit diagnostic intervention. Never enabled during ordinary FPS stepping.
-- The guard raises penetrated dice and clamps only downward linear velocity.
-- This is NOT a physical fix to the upstream collision solver.
function N.guard(world)
 local depth=ffi.new('float[1]')
 local corrected=lib.fpslab_floor_guard(world,depth)
 assert(corrected>=0,'FPS floor diagnostic guard failed')
 return corrected,tonumber(depth[0])
end
function N.guarded_step(world,dt)
 N.step(world,dt)
 return N.guard(world)
end
-- Per-substep, read-only FPS Lab 3 support/penetration measurements.
local probe_buffer=ffi.new('float[4]')
function N.probe(world)
 assert(lib.fpslab_probe(world,probe_buffer)==1,'FPS diagnostic probe failed')
 return {airborne=tonumber(probe_buffer[0]),
  penetrating=tonumber(probe_buffer[1]),
  max_depth=tonumber(probe_buffer[2]),
  min_height=tonumber(probe_buffer[3])}
end
-- Experimental alternative: wake unsupported sleeping dice before the
-- unchanged upstream FPS step. Never used by the live Scriptorium.
function N.support_step(world,dt)
 local wakes=lib.fpslab_step_support(world,dt)
 assert(wakes>=0,'FPS support test failed')
 return wakes
end
function N.set_euler(world,index,rx,ry,rz)
 assert(lib.fpslab_set_euler(world,index-1,rx,ry,rz)==1,
  'invalid FPS single-die orientation')
end
function N.snapshot(world,count)
 local result={}
 local state=ffi.new('float[22]')
 local half=1/1.6
 for i=1,count do
  assert(lib.fpslab_state(world,i-1,state)==1)
  local vertices={}
  for j,unit in ipairs(local_vertices) do
   local x,y,z=half*unit[1],half*unit[2],half*unit[3]
   vertices[j]={
    state[0]*x+state[1]*y+state[2]*z+state[3],
    state[4]*x+state[5]*y+state[6]*z+state[7],
    state[8]*x+state[9]*y+state[10]*z+state[11]
   }
  end
  result[i]={position={state[3],state[7],state[11]},
             vertices=vertices,asleep=lib.fpslab_sleeping(world,i-1)==1}
 end
 return result
end
return N
