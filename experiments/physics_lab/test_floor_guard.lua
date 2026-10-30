-- Requires a compiled native Physics Lab library; run after build-linux/build-windows.
-- Checks the optional correction mechanism, NOT real-world solver fidelity.
local N=require('experiments.physics_lab.fps')
local F=require('experiments.physics_lab.fixtures')
local M=require('experiments.physics_lab.metrics')

local function die_at(z)
 return {position={0,0,z},velocity={0,0,0},angular={0,0,0}}
end
local half=1/1.6
local world,count=N.new({die_at(.20)})
assert(count==1)
local before=N.snapshot(world,count)
assert(M.floor_height(before[1])<-.40,'fixture must begin penetrating the floor')
local corrected,max_depth=N.guard(world)
assert(corrected==1 and max_depth>.40,'guard must report a real correction')
local after=N.snapshot(world,count)
assert(math.abs(M.floor_height(after[1]))<1e-4,'guard must raise lowest corner to floor')
local again,depth2=N.guard(world)
assert(again==0 and depth2==0,'guard must be idempotent at a cleared pose')

local airborne,n=N.new({die_at(3.0)})
local c,d=N.guard(airborne)
assert(c==0 and d==0,'unsupported airborne die must not be snapped to floor')
assert(M.floor_height(N.snapshot(airborne,n)[1])>2,'airborne position unchanged')

local fixture=F.generate(1337)
local guarded,m=N.new(fixture)
local regular,j=N.new(fixture)
local total=0
for step=1,120 do
 N.step(regular,F.dt) -- original FPS path remains callable and unchanged
 local changes,raise=N.guarded_step(guarded,F.dt)
 assert(changes>=0 and raise>=0 and changes<=6,'invalid diagnostics')
 total=total+changes
 for _,b in ipairs(N.snapshot(guarded,m)) do
  local floor=M.floor_height(b)
  assert(floor==floor and floor>-.0023,'guard must prevent significant z<0 penetration')
 end
end
assert(#N.snapshot(regular,j)==6,'original FPS snapshot regression')
print('PASS FPS Lab 2: intentional floor overlap corrected, no airborne snap, original FPS path preserved; corrections='..total)
