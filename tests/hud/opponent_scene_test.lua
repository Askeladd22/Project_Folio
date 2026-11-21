local S=require('src.farkle.ui').opponent_scene
local L=require('src.farkle.ui').layout.build()
local room,opponent,monk=S.room_path,S.portrait_path('opponent'),S.portrait_path('monk')
local function exists(paths) return function(p) return paths[p] or false end end
assert(S.default_id=='opponent' and S.validate_id(nil)=='opponent',
 'generic opponent must be the only default identity')
assert(opponent=='resources/opponents/opponent.png')
local current=S.resolve(nil,exists({[room]=true,[opponent]=true}))
assert(current.id=='opponent' and current.portrait==opponent and
 current.room==room and not current.legacy)
local fallback=S.resolve(nil,exists({[room]=true}))
assert(fallback.id=='opponent' and fallback.legacy and
 fallback.room==room and not fallback.portrait,
 'missing default portrait may show only the clean room')
local a=S.resolve('opponent',exists({[room]=true,[opponent]=true}))
local b=S.resolve('monk',exists({[room]=true,[monk]=true}))
assert(a.portrait~=b.portrait and not a.legacy and not b.legacy)
local ok,err=pcall(S.resolve,'monk',exists({[monk]=true}))
assert(not ok and err:find(room,1,true),'missing room should fail clearly')
ok,err=pcall(S.resolve,'monk',exists({[room]=true}))
assert(not ok and err:find(monk,1,true),'missing extra opponent portrait must fail')
local controller=assert(io.open('src/farkle/controller.lua','rb'))
local controller_source=controller:read('*a');controller:close()
assert(controller_source:find('self:setOpponentVisual(params.opponent_id)',1,true))
for _,id in ipairs({'../monk','Monk','monk.png','',12}) do
 assert(not pcall(S.validate_id,id),'invalid filename injection allowed')
end
local portrait=S.portrait_bounds(700,1000,L)
assert(portrait.w<=850 and portrait.h<=500 and portrait.h>470 and
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
S.draw_portrait(fallback,L,g)
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
 cache.paths[1]==opponent and cache.paths[2]==monk,
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
print('PASS swap opponent PNG without baked Opponent or changes to 3D gameplay')
