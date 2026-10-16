require('core')
local F={min_up=math.cos(math.rad(5)),min_gap=.8,floor_slop=.002}
function F.inspect(entry)
 local b=entry.body;local best,second=-math.huge,-math.huge;local face,up,scale
 for i,indices in ipairs(entry.die.faces) do
  local center=vector{0,0,0};for _,k in ipairs(indices) do center=center+b[k] end
  center=center/#indices
  if center[3]>best then second=best;best=center[3];face=i;scale=center:abs();up=best/scale
  elseif center[3]>second then second=center[3] end
 end
 local gap=(best-second)/(scale or 1);local floor=math.huge
 for _,v in ipairs(b) do floor=math.min(floor,v[3]+b.position[3]) end
 local mechanical=b.asleep==true and b.velocity:abs()<.15 and b.angular:abs()<.20
 local valid=up and up>=F.min_up and gap>=F.min_gap and floor>=-F.floor_slop
 return {mechanical=mechanical,valid=not not valid,face=face,up=up,gap=gap,floor=floor,
   reason=not mechanical and 'moving' or floor < -F.floor_slop and 'penetration' or not valid and 'ambiguous' or 'valid'}
end
return F
