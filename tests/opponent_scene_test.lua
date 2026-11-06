local S=require('src.features.farkle.ui_v2.opponent_scene')
local L=require('src.features.farkle.ui_v2.layout_candidates').build('table_minimal')
local room,merchant,monk=S.room_path,S.portrait_path('merchant'),S.portrait_path('monk')
local function exists(paths) return function(p) return paths[p] or false end end
local legacy=S.resolve(nil,exists({}))
assert(legacy.id=='merchant' and legacy.legacy and
 legacy.room==S.legacy_room and not legacy.portrait)
assert(S.resolve('merchant',exists({[room]=true})).legacy)
local a=S.resolve('merchant',exists({[room]=true,[merchant]=true}))
local b=S.resolve('monk',exists({[room]=true,[monk]=true}))
assert(a.room==room and b.room==room and a.portrait==merchant and
 b.portrait==monk and a.portrait~=b.portrait and not a.legacy and not b.legacy)
local ok,err=pcall(S.resolve,'monk',exists({[monk]=true}))
assert(not ok and err:find(room,1,true),
 'other opponent cannot use JPEG with Merchant already inside')
ok,err=pcall(S.resolve,'monk',exists({[room]=true}))
assert(not ok and err:find(monk,1,true),'missing PNG must fail explicitly')
for _,id in ipairs({'../monk','Monk','monk.png','',12}) do
 assert(not pcall(S.validate_id,id),'invalid filename injection allowed')
end
local portrait=S.portrait_bounds(700,1000,L)
assert(portrait.w<=606 and portrait.h<=408 and portrait.h>350 and
 portrait.y>=9 and
 portrait.y+portrait.h==L.tray.y+35 and
 math.abs(portrait.x+portrait.w*.5-L.tray.x-L.tray.w*.5)<.01)
local cache={images=0,draws=0,paths={}}
local g={
 newImage=function(p) cache.images=cache.images+1
  cache.paths[#cache.paths+1]=p
  return {getWidth=function()return 700 end,getHeight=function()return 1000 end,
   setFilter=function()end}
 end,
 setColor=function()end,
 draw=function()cache.draws=cache.draws+1 end,
}
S.draw_portrait(legacy,L,g)
S.draw_portrait(a,L,g);S.draw_portrait(b,L,g);S.draw_portrait(a,L,g)
assert(cache.images==2 and cache.draws==3 and
 cache.paths[1]==merchant and cache.paths[2]==monk,
 'portraits must be independent and cached per filename')
print('PASS swap opponent PNG without baked Merchant or changes to 3D gameplay')
