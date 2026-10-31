-- CLI research report: luajit experiments/signs_lab/run.lua [N] [seed]
-- All Farkle decisions use the official rules. This is NOT a playable mode.
local Sim=require('experiments.signs_lab.simulate')
local samples=tonumber(arg and arg[1]) or 128
local seed=tonumber(arg and arg[2]) or 20261031
local study=Sim.analyze(samples,seed)
io.write('EXPERIMENT ',samples,' matched seed scenarios from ',seed,'\n')
io.write('MODE POLICY N SUCCESS AVG_HANDS AVG_ROLLS FARKLES',
 ' BANK_CHOICES REROLLS DISAGREEMENT_MARKS\n')
for _,row in ipairs(study.rows) do
 io.write(string.format('%s %s %d %.3f %.2f %.2f %d %d %d %d\n',
  row.mode,row.policy,row.samples,row.success/row.samples,
  row.hands/row.samples,row.rolls/row.samples,row.bust,
  row.bank_choices,row.roll_choices,row.disagreements))
end
io.write('\nPAIRED_OUTCOMES POLICY BASE VARIANT BOTH BASE_ONLY VARIANT_ONLY',
 ' NEITHER DELTA LOW95 HIGH95\n')
for _,pair in ipairs(study.pairs) do
 io.write(string.format('%s %s %s %d %d %d %d %.4f %.4f %.4f\n',
  pair.policy,pair.control,pair.variant,pair.both,
  pair.control_only,pair.variant_only,pair.neither,
  pair.delta,pair.low,pair.high))
end
io.write('\nPUBLIC_CATEGORY_CHOICES MODE POLICY CATEGORY BANK REROLL DISAGREE\n')
for _,row in ipairs(study.rows) do
 if row.mode=='C' or row.mode=='C0' then
  for _,category in ipairs{'assalto','guardia','occasione'} do
   local d=row.categories[category] or
    {bank=0,roll=0,disagreements=0}
   io.write(string.format('%s %s %s %d %d %d\n',
    row.mode,row.policy,category,d.bank,d.roll,d.disagreements))
  end
 end
end
io.write('\nINTERPRETATION: B and C both aim for 3 marks within 6 hands.',
 ' B=one mark for >=35 banked points per turn; C0=same hidden',
 ' Signs as C without double-mark effects; C=proposed Sign bonuses.\n')
io.write('Matched RNG is indexed by (seed, hand, roll, physical die ID)',
 ' and sign decks use a separate matched seed; alternative',
 ' policies may diverge in reached states/number of turns.\n')
io.write('95% intervals are normal approximate intervals of PAIRED',
 ' success differences, not proof of fun, balance or causality.',
 ' A is the shipping 4-turn Farkle control and is not',
 ' a difficulty-matched baseline.\n')
