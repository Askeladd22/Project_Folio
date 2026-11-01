-- Regression for FPS-style elastic group grip and fitted camera scale.
-- The real held bodies remain independent; no fake 2D sprites.
local Group=require('src.features.farkle.group_throw')
local Zoom=require('src.features.farkle.group_hold_projection')
local scene=require('src.data.dice_scene_schema')
local view={yaw=0,pitch=.48,focus=5,distance=14.1}

local owner={}
assert(Zoom.advance(owner,10,false)==1)
assert(Zoom.advance(owner,10.01,true)<1)
local old=Zoom.advance(owner,10.15,true)
assert(old<1 and old>Zoom.held_scale)
local duplicate=Zoom.advance(owner,10.15,true)
assert(duplicate==old,'second draw in the same timestamp must not double ease zoom')
local lowered=Zoom.advance(owner,10.25,true)
assert(lowered<old,'camera should pull back only while group is grabbed')
assert(lowered>=Zoom.held_scale)
local released=Zoom.advance(owner,10.35,false)
assert(released>lowered,'camera should restore standard framing after release')
for n=1,30 do released=Zoom.advance(owner,10.35+n*.05,false) end
assert(math.abs(released-1)<.001,'zoom should smoothly restore full-size game')
assert(Zoom.advance(owner,14,false)==1)

local file=assert(io.open('src/features/farkle/tray_view.lua','r'))
local live=file:read('*a');file:close()
assert(live:find('local scale=target*camera_factor',1,true),
 'the optical scale must be applied AFTER the tray has been fitted')
assert(live:find('owner.trayScale=scale',1,true),
 'the same zoom must feed real physics mouse-to-world conversion')
local game=assert(io.open('src/features/farkle/group_throw.lua','r'))
local mechanics=game:read('*a');game:close()
assert(mechanics:find('Single.tick(member,dt)',1,true),
 'the live spring grip must rotate each genuine rigid body')
assert(mechanics:find('Single.release(member,x,y,time',1,true),
 'release must return held bodies to the production physics solver')
assert(not mechanics:find('G.formation(%#held',1,true),
 'the fixed 3+3 pile must not be reinstated')
print('PASS Tabletop grip/zoom: physical spring hand, production release and smooth projected pullback')
