-- Run from repository root. Never run holdout 2000..6999 for tuning.
local first=tonumber(arg[1]) or 1000
local last=tonumber(arg[2]) or 1999
print(require('experiments.ex002_reactivity_lab.simulate').pilot(first,last,arg[3]))
