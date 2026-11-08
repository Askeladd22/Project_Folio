-- Deterministic Park-Miller RNG, independent streams for player dice and Merchant box.
local M={}
function M.new_rng(seed)
 assert(type(seed)=='number' and seed%1==0 and seed>=1 and seed<2147483647,
  'seed must be integer 1..2147483646')
 local value=seed
 return function(min,max)
  value=(value*16807)%2147483647
  return math.min(min+math.floor(value/2147483647*(max-min+1)),max)
 end
end
return M
