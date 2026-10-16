require('core');love={graphics={newImage=function()end}}
local G=require('src.engine3d.geometry');local F=require('src.engine3d.face_state');local M=require('src.engine3d.roll_resolution')
local function entry(angle)
 local b=G.newD6Body(.92):set({0,0,2},{0,0,0},{0,0,0});local r=rotation():set(angle,vector{1,0,0});local low=math.huge
 for i,v in ipairs(b) do b[i]=r(v);low=math.min(low,b[i][3]) end;b.position[3]=-low;b.asleep=true
 return {body=b,die=G.d6}
end
local flat=entry(0);assert(F.inspect(flat).valid and F.inspect(flat).mechanical)
local edge=entry(math.pi/4);assert(not F.inspect(edge).valid and F.inspect(edge).mechanical,'edge is mechanically at rest, not an outcome')
assert(not F.inspect(entry(math.rad(6))).valid,'outside explicit angular tolerance')
local s=M.new{1};assert(not M.advance(s,0,{flat}));assert(not s.done)
assert(M.advance(s,.2,{flat})=='accept')
s=M.new{1};for i=1,2 do assert(M.advance(s,.01,{edge})=='retry') end
assert(M.advance(s,.01,{edge})=='failed');assert(not M.advance(s,100,{flat}),'failure is terminal, no recovery loop')
s=M.new{1};flat.body.asleep=false;assert(M.advance(s,20,{flat})=='retry','timeout is explicit')
print('PASS rest/geometry/acceptance, edge rejection, bounded retry, timeout')
