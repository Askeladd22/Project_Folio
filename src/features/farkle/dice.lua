local D={}
local face_texture=require('src.engine3d.face_texture')
function D.values(build,index)
 return {1,6,3,5,4,(build=='engraved' and index==1) and 1 or 2}
end
function D.accept(value,u) return value==1 or u<.5 end
function D.probabilities(build,index)
 if index==1 and build=='weighted' then return {2/7,1/7,1/7,1/7,1/7,1/7} end
 if index==1 and build=='engraved' then return {2/6,0,1/6,1/6,1/6,1/6} end
 return {1/6,1/6,1/6,1/6,1/6,1/6}
end
local risks={}
function D.risk(build,indices)
 local weighted=false;for _,i in ipairs(indices) do if i==1 then weighted=true end end
 local key=build..':'..#indices..':'..tostring(weighted);if risks[key] then return risks[key] end
 local c={0,0,0,0,0,0};local sum=0
 local function visit(j,p)
  if j>#indices then
   local pairs=0;for _,n in ipairs(c) do if n==2 then pairs=pairs+1 end end
   if #indices~=6 or pairs~=3 then sum=sum+p end
   return
  end
  local dist=D.probabilities(build,indices[j])
  -- Bust requires no 1/5, triple or three pairs. Straights contain a 5;
  -- full house and two triples necessarily contain a triple.
  for _,v in ipairs({2,3,4,6}) do if c[v]<2 and dist[v]>0 then c[v]=c[v]+1;visit(j+1,p*dist[v]);c[v]=c[v]-1 end end
 end
 visit(1,1);risks[key]=sum;return sum
end
function D.install(build)
 for i,entry in ipairs(dice) do
  local die=entry.die;die.faceValueMap=D.values(build,i);die.pipMap=die.faceValueMap
  die.faceColors={};for f=1,6 do die.faceColors[f]=(i==1 and build~='normal') and {157,113,47,255} or {74,54,35,255} end
  -- Unlike the original d6.image closure, this reads this individual die's map.
  die.image=function(face,a,b,c,d,e,f,g,h)
   if not (a and b and c and d and g and h) then return end
   local img=love.graphics.getImage('resources/dice/'..die.faceValueMap[face]..'.png')
   love.graphics.setColor(1,1,1,1)
   face_texture.draw(img,a,b,c,d,e,f,g,h)
  end
 end
end
return D
