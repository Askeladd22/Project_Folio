-- Historical base numbering and visual values share the actual physical map.
local previousLove=love
love=love or {graphics={}}
love.graphics=love.graphics or {}
local Geometry=require('src.engine3d.geometry')
local Dice=require('src.farkle.dice')
local Material=require('src.engine3d.g3d.scene').materials
local pairsFound=0
for i,a in ipairs(Geometry.d6.faces) do
 for j=i+1,#Geometry.d6.faces do
  local b=Geometry.d6.faces[j]
  local shared=false
  for _,x in ipairs(a) do
   for _,y in ipairs(b) do if x==y then shared=true end end
  end
  if not shared then
   pairsFound=pairsFound+1
   assert(Geometry.d6.faceValueMap[i]+Geometry.d6.faceValueMap[j]==7,
    'opposite physical base faces must sum to seven')
   for index=1,6 do
    local values=Dice.values('normal',index)
    assert(values[i]+values[j]==7,'base Farkle die must follow sevens')
   end
  end
 end
end
assert(pairsFound==3,'a cube must have exactly three opposite face pairs')
local sent={}
local shader={send=function(_,key,value) sent[key]=value end}
local view={yaw=.2,pitch=.62}
local originalRandom=math.random
math.random=function() error('visual materials must not consume gameplay RNG') end
Material.configure(shader,'ivory',view,false,4)
assert(sent.boneSurface==1,'D6 ivory must select the aged bone surface')
assert(sent.boneSeed==3,'patina must follow the stable die identity')
for value=1,6 do
 Material.configure_pips(shader,'ivory',nil,value)
 assert(sent.pipValue==value,'shader must receive the actual physical face value')
end
-- The changed 2 -> 1 face uses the same mapping as gameplay scoring.
local engraved=Dice.values('engraved',1)
assert(engraved[6]==1 and Geometry.d6.faceValueMap[6]==2)
Material.configure_pips(shader,'ivory',nil,engraved[6])
assert(sent.pipValue==1,'engraved face must display its modified value')
Material.configure_pips(shader,'ivory',nil)
assert(sent.pipValue==0,'bevel surfaces must clear the previous face markings')
Material.configure_pips(shader,'diffuse',nil,6)
assert(sent.pipValue==0,'reference material must retain its texture')
Material.configure(shader,'ivory',view,true,4)
assert(sent.boneSurface==0,'D8 color faces must retain their material')
math.random=originalRandom
love=previousLove
print('PASS bone dice: physical sevens, real face values, engraved variant and stable patina')
