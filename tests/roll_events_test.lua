local E=require('src.core.roll_events')
local calls={}
local function emit(name,info)
 calls[#calls+1]={name=name,info=info}
end
local payload={values={{index=1,value=5}},indices={1},logical_roll_id=7,
 physical_attempt_id=9,session_seed=123}
assert(not E.complete(emit,function() return false end,payload))
assert(#calls==1 and calls[1].name=='dice.physical_settled')
assert(E.complete(emit,function() return true end,payload))
assert(#calls==4 and calls[2].name=='dice.physical_settled' and
 calls[3].name=='dice.roll_settled' and calls[4].name=='dice.roll_accepted')
assert(calls[4].info==payload and calls[4].info.logical_roll_id==7)
-- Failed attempts cannot spend a Segno; semantic observers count only
-- accepted rolls, even when physical settle happens repeatedly.
local accepted,physical=0,0
for _,c in ipairs(calls) do
 if c.name=='dice.roll_accepted' then accepted=accepted+1 end
 if c.name=='dice.physical_settled' then physical=physical+1 end
end
assert(accepted==1 and physical==2)
print('PASS physical and semantic events remain distinct through rejection')
