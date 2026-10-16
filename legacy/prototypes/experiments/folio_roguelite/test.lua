local R=require('experiments.folio_roguelite.rules')
local function roll(s,h) assert(R.start(s)); assert(R.settle(s,h)) end
local function fresh(h) local s=R.new(); roll(s,h or {1,3,2,6}); return s end
local s=fresh()
assert(not R.start(s),'must assign between positive throws')
assert(R.assign(s,1,1)); assert(not R.assign(s,1,3),'used die cannot be reused')
assert(not R.assign(s,2,1),'occupied slot')
assert(R.bank(s)); assert(s.slots[1]=='fixed' and s.phase=='ended')
assert(R.next_session(s)); assert(s.slots[1]=='fixed' and not s.used[1])
roll(s,{3,5,5,5}); assert(R.assign(s,1,2)); assert(R.start(s))
assert(R.settle(s,{[2]=5,[3]=5,[4]=5})); assert(s.phase=='ended')
assert(s.slots[1]=='fixed' and s.slots[2]==nil,'only wet work lost')

s=fresh({1,3,3,4}); for i=1,4 do assert(R.assign(s,i,i)) end
assert(s.phase=='ready' and not R.start(s),'completion of decorations is not session end')
assert(R.bank(s)); assert(R.next_session(s)); roll(s,{2,6,5,5})
assert(R.assign(s,1,5)); assert(R.assign(s,2,6)); assert(R.bank(s)); assert(s.phase=='choice')
assert(not R.next_session(s)); assert(not R.choose(s,'invalid'))
assert(R.choose(s,'fixative') and s.folio==2 and s.session==1)
roll(s,{1,2,5,5}); assert(R.assign(s,1,1)); assert(R.assign(s,2,2))
assert(R.protect(s,2)); assert(R.start(s)); assert(not R.protect(s,1))
assert(R.settle(s,{[3]=6,[4]=6})); assert(s.slots[2]=='fixed' and s.slots[1]==nil)
assert(s.phase=='ended' and not s.protected)

-- Transfer retains wet/fixed status and never restores a consumed die.
s=R.new(); s.phase='choice'; assert(R.choose(s,'model'))
roll(s,{2,4,1,5}); assert(R.assign(s,1,2))
assert(R.transfer(s,2,3)); assert(s.slots[2]==nil and s.slots[3]=='wet' and s.used[1])
assert(not R.transfer(s,3,2),'once per folio'); assert(R.bank(s))
assert(R.next_session(s) and s.model_used)
s=R.new(); s.phase='choice'; R.choose(s,'model'); s.slots[2]='fixed'
roll(s,{1,3,4,5}); assert(R.transfer(s,2,3)); assert(s.slots[3]=='fixed')

s=R.new(); for session=1,4 do
 roll(s,{5,5,5,5}); assert(R.bank(s))
 if session<4 then assert(R.next_session(s)) end
end
assert(s.phase=='lost' and not R.next_session(s))
s=fresh({5,5,5,5}); assert(R.start(s),'dead initial roll may retry')
assert(R.settle(s,{5,5,5,5}) and s.phase=='ended')

-- Invalid physical callback must not partially mutate or finish a roll.
s=R.new(); assert(R.start(s)); assert(not R.settle(s,{1,2,3,9}))
assert(s.phase=='rolling' and s.hand[1]==nil)
assert(R.settle(s,{1,2,3,4}))

s=R.new(); s.phase='choice'; R.choose(s,'model')
for i=1,5 do s.slots[i]='fixed' end
roll(s,{5,1,1,1}); assert(R.assign(s,1,6)); assert(not R.start(s))
assert(R.bank(s) and s.phase=='won')
assert(not R.assign(s,2,1) and not R.bank(s))
print('PASS persistence, dice conservation, failure, techniques, deadlines, terminal and atomic transitions')
