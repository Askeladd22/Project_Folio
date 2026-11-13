local S=require('src.farkle.ui').opponent_scene
local L=require('src.farkle.ui').layout.build()
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
assert(portrait.w<=800 and portrait.h<=580 and portrait.h>550 and
 portrait.y>=9 and
 portrait.y+portrait.h==L.host.h+35-L.portrait_lift and
 math.abs(portrait.x+portrait.w*.5-L.tray.x-L.tray.w*.5)<.01)
local cache={images=0,draws=0,paths={},shaderSource=nil,uniforms={},passes={}}
local shader={
 send=function(_,name,value) cache.uniforms[name]=value end,
}
local activeShader
local g={
 newImage=function(p) cache.images=cache.images+1
  cache.paths[#cache.paths+1]=p
  return {getWidth=function()return 700 end,getHeight=function()return 1000 end,
   setFilter=function()end}
 end,
 newShader=function(path)
  local file=assert(io.open(path,'rb'))
  cache.shaderSource=file:read('*a');file:close()
  return shader
 end,
 setShader=function(s) activeShader=s end,
 setColor=function()end,
 draw=function()
  cache.draws=cache.draws+1
  cache.passes[#cache.passes+1]={shader=activeShader,shadow=cache.uniforms.shadowPass}
 end,
}
S.draw_portrait(legacy,L,g)
local failing={}
for k,v in pairs(g) do failing[k]=v end
failing.newShader=function() error('shader compile failed') end
local compiled,compileErr=pcall(S.draw_portrait,a,L,failing,{x=0,y=0,breath=0})
assert(not compiled and compileErr:find('shader compile failed',1,true),
 'shader compilation errors must not be silently ignored')
S.draw_portrait(a,L,g,{x=0,y=0,breath=0})
S.draw_portrait(b,L,g,{x=0,y=0,breath=0})
S.draw_portrait(a,L,g,{x=0,y=0,breath=0})
assert(cache.images==2 and cache.draws==6 and
 cache.paths[1]==merchant and cache.paths[2]==monk,
 'portraits must be independent and cached per filename')
assert(cache.shaderSource:find('inkTone',1,true) and
 cache.shaderSource:find('paperTone',1,true) and
 cache.shaderSource:find('shadowPass',1,true) and
 cache.shaderSource:find('shadowTexel * 7.0',1,true) and
 cache.shaderSource:find('coverage +=',1,true),
 'portrait shader should preserve engraved ink, warm paper and cast-shadow pass')
assert(cache.uniforms.shadowPass==0 and
 cache.uniforms.shadowTexel[1]>0 and
 cache.uniforms.inkTone[1]<cache.uniforms.paperTone[1],
 'portrait should use warm palette tones after drawing its shadow')
for i,pass in ipairs(cache.passes) do
 assert(pass.shader==shader and pass.shadow==(i%2==1 and 1 or 0),
  'both shadow and portrait must be drawn with the correct shader pass')
end
assert(activeShader==nil,'portrait shader must not leak into later draws')
print('PASS swap opponent PNG without baked Merchant or changes to 3D gameplay')
