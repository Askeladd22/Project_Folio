-- Reference metadata is internal. Public labels deliberately use neutral names.
-- Unknown timing/parameters are disabled, never replaced by invented rules.
local M={list={},by_id={}}
local function add(id,reference,label,tier,effect,uses,parameters,reason)
 local d={id=id,functional_id=effect,reference=reference,label=label,tier=tier,effect=effect,
  max_uses=uses,parameters=parameters or {},enabled=reason==nil,reason=reason,
  solo=effect~='cancel_opponent',verification=reason and 'UNVERIFIED / BLOCKED' or 'Documented; research limitations apply',
  trigger='after_valid_throw',duration='single_activation',activation=reason and 'UNVERIFIED' or 'manual',
  conditions={phase='ready',remaining_uses=true,solo=true},source='KCD2_MEDAGLIE_RICERCA.md'}
 M.list[#M.list+1]=d;M.by_id[id]=d;return d
end
local tiers={'tin','silver','gold'}
local labels={'tin','silver','gold'}
for n,t in ipairs(tiers) do
 add('reroll_'..t,'Fortune '..t,'Reroll '..labels[n],t,'selective_reroll',1,{count=n})
 local d=add('bust_retry_'..t,'Resurrection '..t,'Recovery '..labels[n],t,'bust_retry',n,{},'Unverified: point retention and activation window after Farkle.')
 d.trigger='after_bust'
 d=add('extra_die_'..t,'Might '..t,'Extra die '..labels[n],t,'extra_die',n,{},'Unavailable: a seventh physical die exceeds the six-die engine contract.')
 d.trigger='UNVERIFIED';d.duration='UNVERIFIED'
 d=add('transform_'..t,'Transmutation '..t,'Transform into '..({3,5,1})[n],t,'transform',1,{value=({3,5,1})[n]},'Unverified: timing, duration and consistent temporary face display.')
 d.duration='UNVERIFIED'
 add('last_throw_'..t,'Doppelganger '..t,'Double roll '..labels[n],t,'last_throw_multiplier',n,{factor=2},'Unverified: last roll already set aside or empty selection; turn ending.')
 d=add('bank_multiplier_'..t,'Warlord '..t,'Bank '..({'+25%','+50%','x2'})[n],t,'bank_multiplier',1,{factor=({1.25,1.5,2})[n]},n<3 and 'Unverified: rounding for Manuscript scores.' or nil)
 d.trigger='bank';d.duration='current_turn'
 d=add('headstart_'..t,'Headstart '..t,'Head start '..labels[n],t,'headstart',1,{},'Unverified: exact starting bonus.')
 d.trigger='commission_start';d.duration='commission';d.activation='automatic'
 d=add('defence_'..t,'Defence '..t,'Cancel opponent '..labels[n],t,'cancel_opponent',false,{},'Incompatible: solo play has no opponent.')
 d.trigger='passive';d.duration='commission';d.activation='passive'
end
add('exchange_silver','Swap-out / Exchange silver','Single exchange','silver','selective_reroll',1,{count=1})
local d=add('exchange_gold','Swap-out / Exchange gold','Matching pair exchange','gold','selective_reroll',1,{count=2,same_value=true})
d.same_value=true
for i,r in ipairs{{'Carpenter','3+5'},{'Executioner','4+5+6'},{'Parish Priest','1+3+5'}} do
 d=add('formation_'..i,r[1]..' Advantage','Formation '..r[2],tiers[i],'formation',false,{combination=r[2]},'Unverified: scoring, repeats and overlapping combinations.')
 d.trigger='score';d.duration='commission'
end
d=add('triple_ones','Emperor gold','Ones group bonus','gold','group_multiplier',false,{value=1,factor=3},'Unverified: larger groups and competing combinations.')
d.trigger='score';d.duration='commission'
add('extra_die_special','Bird King / Silver King','Special extra die','silver','extra_die',2,{},'Unavailable: seventh physical die; duration unverified.')
add('reroll_wedding','Wedding gold','Special three-die reroll','gold','selective_reroll',1,{count=3})
d=add('triple_sixes','Tyche gold','Sixes group bonus','gold','group_multiplier',false,{value=6,factor=2},'Unverified: larger groups and competing combinations.')
d.trigger='score';d.duration='commission';d.content='Legacy of the Forge DLC'
d=add('special_die_transform','Balatro tin','Transform special die','tin','special_transform',1,{},'Unavailable: special die not present; scope unverified.')
d.content='Update 1.5.6'
function M.get(id) return M.by_id[id] end
function M.reset(s)
 local d=M.get(s.medal);s.medalCharges=d and d.max_uses or nil
end
function M.remaining(s)
 if s.medal=='retry' then return s.medalUsed and 0 or 1 end
 return s.medalCharges or 0
end
function M.spend(s)
 if M.remaining(s)<=0 then return false end
 s.medalCharges=s.medalCharges-1;return true
end
return M
