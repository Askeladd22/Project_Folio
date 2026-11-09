-- Run at repository root; optional existing output directory for raw CSV.
local first=tonumber(arg[1]) or 1000
local last=tonumber(arg[2]) or 1999
print(require('experiments.ex001_merchant_x_lab.simulate').report(first,last,arg[3]))
