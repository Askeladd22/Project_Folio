local R=require('src.gameplay.farkle.rules')
local P=require('src.gameplay.farkle.commission_progress')
assert(R.contracts==P.contracts and #P.contracts==3)
assert(P.contracts[1].target==100 and P.contracts[2].entry_min==40 and
 P.contracts[3].bank_min==25)
for stage=1,3 do
 local s=R.new();s.stage=stage;s.bank=0
 assert(not P.completed(s))
 assert(P.minimum(s)==P.contracts[stage].entry_min)
 s.entered=true
 assert(P.minimum(s)==P.contracts[stage].bank_min)
end
assert(P.completion_phase({stage=1,mode='build'})=='upgrade')
assert(P.completion_phase({stage=2,mode='build'})=='medal')
assert(P.completion_phase({stage=3,mode='build'})=='won')
assert(P.completion_phase({stage=1,mode='control'})=='advance')
print('PASS commission extraction preserves previous scoring and transition configuration')
