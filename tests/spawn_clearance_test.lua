package.path='./?.lua;./?/init.lua;'..package.path
local S=require('src.engine3d.spawn_clearance')
love=love or {};love.graphics=love.graphics or {}
require('core')
local G=require('src.engine3d.geometry')
local function body(x,y,z) return G.newD6Body(.92):set({x,y,z},{0,0,0},{0,0,0}) end
local a,b=body(0,0,6),body(1.15,0,6)
assert(S.intersects(a,a.position,b,b.position,.01),'touching cubes violate margin')
b.position[1]=1.17;assert(not S.intersects(a,a.position,b,b.position,.01))
local r=rotation():set(math.pi/4,vector{0,0,1});for i=1,8 do a[i]=r(a[i]);b[i]=r(b[i]) end
b.position[1]=1.55;assert(S.intersects(a,a.position,b,b.position,.01),'sphere-missed corner contact')
b.position[1]=0;assert(S.intersects(a,a.position,b,b.position,.01),'coincident centers')
local rows={};for i=1,6 do rows[i]={index=i,body=body(0,0,6),position=vector{0,0,6},side=1} end
local p,stats=S.place(rows,function(row,rnd,side) return vector{(rnd()-.5)*12,(side or 1)*2-5,6},side or 1 end)
assert(p and stats.retries>0)
for i=1,6 do for j=i+1,6 do assert(not S.intersects(rows[i].body,p[i],rows[j].body,p[j],.01)) end end
local none,failed=S.place(rows,function(row,rnd,side)return vector{0,0,6},side or 1 end)
assert(not none and failed.failed and failed.retries<=6*384,'bounded failure')
print('PASS geometric margin, rotated corners, coincident centers, rejection and bounded failure')
local two={rows[1],rows[2]}
local count=0
local alt,as=S.place(two,function(row,rnd,side)
 count=count+1;return vector{side and 0 or 4,0,6},side or 2
end)
assert(alt and as.fallbacks==1 and as.side_changes==1 and count==33)
count=0
local scan,ss=S.place(two,function(row,rnd,side)
 count=count+1;return vector{count>128 and 4 or 0,0,6},side or 1
end)
assert(scan and ss.scans==1 and count==129)
print('PASS controlled alternate-side and finite-scan fallback paths')
