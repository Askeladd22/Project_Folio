-- Run from repo root: lua5.4 experiments/signs_lab/run.lua [samples] [seed]
-- No LÖVE, GPU or physics required; reproducible statistical PROTOTYPE.
local Sim=require('experiments.signs_lab.simulate')
local samples=tonumber(arg and arg[1]) or 100
local seed=tonumber(arg and arg[2]) or 20261031
assert(samples%1==0 and samples>=1 and samples<=10000)
assert(seed%1==0 and seed>=1 and seed<2147483647)
io.write('MODE POLICY SAMPLES TARGET_REACHED AVG_HANDS AVG_ROLLS FARKLES',
 ' BANK_CHOICES REROLLS POLICY_DISAGREEMENTS\n')
for _,row in ipairs(Sim.compare(samples,seed)) do
 io.write(string.format('%s %s %d %.3f %.2f %.2f %d %d %d %d\n',
  row.mode,row.policy,row.samples,row.success/row.samples,
  row.hands/row.samples,row.rolls/row.samples,row.bust,
  row.bank_choices,row.roll_choices,row.disagreements))
end
io.write('NOTE: A is current 4-hand commission, B is 6-hand fixed progress,',
 ' C is an unapproved 6-hand signs fixture. Success rates are NOT',
 ' normalized for objective difficulty. Virtual rolls use official',
 ' Farkle rules, not g3d. No gameplay integration.\n')
