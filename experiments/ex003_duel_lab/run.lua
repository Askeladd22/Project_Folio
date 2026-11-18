-- Execute from repo root, with an existing output directory:
-- lua5.4 experiments/ex003_duel_lab/run.lua 16000 16199 /tmp/ex003
local S=require('experiments.ex003_duel_lab.simulate')
local first=tonumber(arg[1] or S.first_pilot)
local last=tonumber(arg[2] or S.last_pilot)
local dir=assert(arg[3],'provide an existing destination directory')
local report=S.pilot(first,last,dir)
local f=assert(io.open(dir..'/ex003_summary.txt','w'))
f:write(report,'\n');assert(f:close())
print(report)
