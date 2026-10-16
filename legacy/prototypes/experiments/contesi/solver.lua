local M=require('experiments.contesi.model')
local f=assert(io.open('experiments/contesi/solver.txt','w'))
for _,cfg in ipairs(M.configs) do
 f:write(cfg.name..'\n')
 for _,route in ipairs(M.solve(cfg)) do
  f:write('SAT omit='..route.omit..' placements='..route.count..' witness:\n')
  for row=1,4 do
   for col=1,5 do f:write((route.board[(row-1)*5+col] or '.')..' ') end
   f:write('\n')
  end
 end
 f:write('UNSAT triples omitting C or D: incompatible requirements of A and B.\n\n')
end
f:close()
