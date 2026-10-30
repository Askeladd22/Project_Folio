-- Commission goals and reward transitions; Farkle scoring is intentionally unaware.
local Progress={}
Progress.contracts={
 {name='Parish Psalter',target=100,limit=4,entry_min=0,bank_min=0,provisional=true,condition='Banked points only'},
 {name="Merchant's Book of Hours",target=150,limit=5,entry_min=40,bank_min=20,provisional=true,condition='Bank at least one group of 3 or more matching dice'},
 {name='Presentation Codex',target=200,limit=5,entry_min=50,bank_min=25,provisional=true,condition='Bank after at least one hot dice cycle'}
}
function Progress.minimum(s)
 local contract=assert(Progress.contracts[s.stage],'missing commission')
 return s.entered and (contract.bank_min or 0) or (contract.entry_min or 0)
end
function Progress.completed(s)
 local c=assert(Progress.contracts[s.stage],'missing commission')
 return s.bank>=c.target and (s.stage~=2 or s.group) and (s.stage~=3 or s.hotBank)
end
function Progress.completion_phase(s)
 if s.stage==#Progress.contracts then return 'won' end
 if s.mode=='control' then return 'advance' end
 return s.stage==1 and 'upgrade' or 'medal'
end
return Progress
