-- Reproducible simulation RNG only. Never used to override a physical die.
local M={}
function M.new(seed)
 local state=seed
 for _=1,32 do state=(state*16807)%2147483647 end
 return function(n)
  state=(state*16807)%2147483647
  return math.floor((state-1)/2147483646*n)+1
 end
end
return M
