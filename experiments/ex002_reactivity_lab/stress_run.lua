-- EX-002b exploratory stress. Never substitute for frozen EX-002 pilot.
local first=tonumber(arg[1]) or 8000
local last=tonumber(arg[2]) or 8999
print(require('experiments.ex002_reactivity_lab.stress').report(first,last,arg[3]))
