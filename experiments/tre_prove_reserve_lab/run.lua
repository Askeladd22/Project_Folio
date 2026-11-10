-- EX-TP-001. From repository root. Example: lua5.4 .../run.lua 1001 1000 out-dir
local first=tonumber(arg[1]) or 1001
local count=tonumber(arg[2]) or 1000
local dir=arg[3]
local summary=require('experiments.tre_prove_reserve_lab.simulate').pilot(first,count,dir)
print(summary)
if dir then
  local f=assert(io.open(dir..'/report.txt','w'))
  f:write('EX-TP-001 SCRIPTED PILOT; canonical src/farkle/rules.lua\n')
  f:write('first='..first..' count='..count..' (seed labels shared, RNG may diverge)\n')
  f:write(summary..'\n');f:close()
end
