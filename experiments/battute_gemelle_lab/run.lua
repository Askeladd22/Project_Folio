-- EX-BG-001. Run from repository root, optional pre-existing output directory.
local count=tonumber(arg[1]) or 1000
local first=tonumber(arg[2]) or 1001
local dir=arg[3]
print(require('experiments.battute_gemelle_lab.simulate').report(
  count,first,dir,80,96))
