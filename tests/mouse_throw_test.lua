local T=require('src.features.farkle.mouse_throw')
local view={yaw=0,pitch=.48,focus=5,distance=14.1}
local bounds={half_x=9.2,half_y=3.8}
local function body()
 local b={position={0,0,1},velocity={2,-1,0},angular={.1,.2,.3},
  asleep=true,sleep_timer=999,{1,1,1},{-1,-1,-1}}
 function b:update(dt)
  for _,v in ipairs(self) do v[1]=v[1]+dt*self.angular[2] end
 end
 return b
end
assert(not T.begin(0,body(),10,10,1),'invalid die index should not be grabbed')
local b=body()
local grab=assert(T.begin(3,b,100,200,1))
assert(b._manual_pending and b._grabbed and b.asleep,'grabbing must freeze real physics')
assert(T.move(grab,150,165,1.08,view,20,bounds))
assert(b.position[1]>0 and b.position[2]<0 and b.position[3]>=2.1,
 'actual world-space body must follow the mouse above floor')
local old_vert=b[1][1]
T.tick(grab,.02)
assert(b[1][1]~=old_vert,'the real die vertices must rotate in hand')
assert(T.move(grab,250,110,1.16,view,20,bounds))
local impulse=assert(T.release(grab,270,100,1.17,view,20,bounds))
assert(impulse.index==3 and not b._manual_pending and not b._grabbed,
 'release must return die to physical solver')
assert(not b.asleep and b.velocity[3]<0,'released die must fall')
assert(math.abs(b.velocity[1])<=18 and math.abs(b.velocity[2])<=18,
 'mouse-directed launch must be bounded')
local c=body()
local held=T.begin(1,c,0,0,0)
T.move(held,100,100,.1,view,20,bounds)
T.tick(held,.02)
T.cancel(held)
assert(c._manual_pending and not c._grabbed,'cancelled die stays queued')
assert(c.position[1]==0 and c.position[2]==0 and c.position[3]==1,
 'cancel must restore physical position')
assert(c[1][1]==1 and c[2][1]==-1,'cancel must restore original 3D orientation')
local d=body()
local simple=assert(T.begin(2,d,5,5,1))
assert(T.release(simple,5,5,1.2,view,20,bounds),
 'releasing without a swipe should drop one die')
local function source(p) local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local controller=source('src/features/farkle/controller.lua')
local runtime=source('src/app/dice_runtime.lua')
local physics=source('src/engine3d/physics.lua')
assert(controller:find('onManualRollBegin',1,true) and controller:find('onManualRollRelease',1,true))
assert(controller:find('MouseThrow.tick(self.mouseThrow,dt)',1,true))
assert(controller:find('self.manualRoll.pending[i]',1,true),'release needs queued-die gate')
assert(runtime:find('manual_session.count>0',1,true),'cannot score partial hand')
assert(runtime:find("physicalResolution=RollResolution.new(last_roll_indices)",1,true))
assert(physics:find('if s._manual_pending then',1,true))
assert(physics:find('if b._manual_pending then goto continue_pair end',1,true))
assert(not package.loaded['lib.g3d'],'physics tests must not need a GPU')
print('PASS tabletop individual dice: physical hold/rotate/release, queue, cancel, and delayed Farkle scoring')
