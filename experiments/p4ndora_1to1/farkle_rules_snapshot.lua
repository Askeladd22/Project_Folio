local Parts = {}

-- Commission progress
Parts.progress = (function()
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
end)()

-- Scoring and combinations
Parts.scoring = (function()
-- Pure Lua. Physical IDs are preserved; no renderer, randomness or physics access.
local S={points={single={[1]=10,[5]=5},kind={
 [3]={75,20,30,40,50,60},[4]={110,120,130,140,150,160},
 [5]={320,340,360,380,400,420},[6]={625,650,675,700,725,750}},
 small=100,straight=200,pairs=150,full=200,triples=250}}
local function bit(mask,i) return math.floor(mask/2^(i-1))%2==1 end
local function valid(values,ids)
 if #values<1 or #values>6 or #values~=#ids then return false end
 local seen={}
 for i,v in ipairs(values) do
  local id=ids[i]
  if type(v)~='number' or v%1~=0 or v<1 or v>6 or type(id)~='number' or id%1~=0 or id<1 or id>6 or seen[id] then return false end
  seen[id]=true
 end
 return true
end
local names={[3]='Three of a kind',[4]='Four of a kind',[5]='Five of a kind',[6]='Six of a kind'}
local function atom(values,ids,mask)
 local c={0,0,0,0,0,0};local chosen={};local n=0
 for i,v in ipairs(values) do if bit(mask,i) then c[v]=c[v]+1;n=n+1;chosen[#chosen+1]=ids[i] end end
 local points,label,group
 if n==1 then for v=1,6 do if c[v]==1 and S.points.single[v] then points=S.points.single[v];label='Single '..v end end end
 for v=1,6 do if n>=3 and c[v]==n then points=S.points.kind[n][v];label=names[n]..' of '..v;group=true end end
 local pairs,triples,quad,distinct=0,0,0,0
 for v=1,6 do if c[v]>0 then distinct=distinct+1 end;if c[v]==2 then pairs=pairs+1 end;if c[v]==3 then triples=triples+1 end;if c[v]==4 then quad=quad+1 end end
 if n==5 and distinct==5 and (c[1]==0 or c[6]==0) then points=S.points.small;label='Small straight' end
 if n==6 then
  if distinct==6 then points=S.points.straight;label='Large straight'
  elseif pairs==3 then points=S.points.pairs;label='Three pairs'
  elseif quad==1 and pairs==1 then points=S.points.full;label='Full house (4+2)';group=true
  elseif triples==2 then points=S.points.triples;label='Two triplets';group=true end
 end
 if points then return {points=points,label=label,group=group or false,ids=chosen} end
end
local cache,cacheSize={},0
function S.options(values,ids)
 ids=ids or {};if #ids==0 then for i=1,#values do ids[i]=i end end
 if not valid(values,ids) then return {} end
 local key=table.concat(ids,',')..':'..table.concat(values,',')
 if cache[key] then return cache[key] end
 local atoms,memo={}, {[0]={points=0,group=false,groups={}}}
 for mask=1,2^#values-1 do atoms[mask]=atom(values,ids,mask) end
 local function solve(mask)
  if memo[mask]~=nil then return memo[mask] end
  local first;for i=1,#values do if bit(mask,i) then first=i;break end end
  local best=false
  for sub,a in pairs(atoms) do
   if bit(sub,first) then
    local contained=true;for i=1,#values do if bit(sub,i) and not bit(mask,i) then contained=false;break end end
    if contained then
     local rest=solve(mask-sub)
     if rest then
      local points=a.points+rest.points;local group=a.group or rest.group
      if not best or points>best.points or points==best.points and group and not best.group then
       local groups={a};for _,g in ipairs(rest.groups) do groups[#groups+1]=g end
       best={points=points,group=group,groups=groups}
      end
     end
    end
   end
  end
  memo[mask]=best;return best
 end
 local result={}
 for mask=1,2^#values-1 do
  local solved=solve(mask)
  if solved then
   local chosen,physicalMask={},0
   for i,id in ipairs(ids) do if bit(mask,i) then chosen[#chosen+1]=id;physicalMask=physicalMask+2^(id-1) end end
   result[#result+1]={ids=chosen,mask=physicalMask,points=solved.points,group=solved.group,groups=solved.groups,remaining=#ids-#chosen}
  end
 end
 -- Stable ordering by number of dice, then identity; never auto-select the maximum.
 table.sort(result,function(a,b) if #a.ids~=#b.ids then return #a.ids<#b.ids end;return a.mask<b.mask end)
 if cacheSize>=256 then cache={};cacheSize=0 end
 cache[key]=result;cacheSize=cacheSize+1;return result
end
local scores={}
function S.score(values)
 if #values<1 or #values>6 then return nil end
 local copy={};for i,v in ipairs(values) do if type(v)~='number' or v%1~=0 or v<1 or v>6 then return nil end;copy[i]=v end
 table.sort(copy);local key=table.concat(copy,',')
 if scores[key]~=nil then if scores[key] then return scores[key].points,scores[key].group end;return nil end
 local options=S.options(copy);local full=2^#copy-1
 for _,o in ipairs(options) do if o.mask==full then scores[key]=o;return o.points,o.group end end
 scores[key]=false;return nil
end
return S
end)()

-- Medals
Parts.medals = (function()
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
 local medal=M.get(s.medal);s.medalCharges=medal and medal.max_uses or nil
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
end)()

-- Turn and game rules
Parts.rules = (function()
local Progress=Parts.progress
local R={contracts=Progress.contracts}
local Scoring=Parts.scoring
local Medals=Parts.medals
R.points=Scoring.points
R.score=Scoring.score
function R.has_points(values)
 local c={};for _,v in ipairs(values) do if v==1 or v==5 then return true end;c[v]=(c[v] or 0)+1;if c[v]>=3 then return true end end
 local pairCount=0;for _,n in pairs(c) do if n==2 then pairCount=pairCount+1 end end
 return #values==6 and pairCount==3
end
function R.count_free(s) local n=0;for i=1,6 do if not s.used[i] then n=n+1 end end;return n end
function R.options(s)
 if s.phase~='ready' then return {} end
 local values,ids={},{}
 for i=1,6 do if not s.used[i] and s.hand[i] then values[#values+1]=s.hand[i];ids[#ids+1]=i end end
 return Scoring.options(values,ids)
end
function R.selection_option(s)
 if s.phase~='ready' then return nil end
 local mask=0
 for i in pairs(s.selected) do
  if type(i)~='number' or i%1~=0 or i<1 or i>6 or s.used[i] or not s.hand[i] then return nil end
  mask=mask+2^(i-1)
 end
 for _,o in ipairs(R.options(s)) do if o.mask==mask then return o end end
end
function R.selection(s)
 local o=R.selection_option(s);if o then return o.points,o.group end
end
function R.bank_status(s)
 local minimum=Progress.minimum(s)
 local selected=next(s.selected)~=nil;local pts=R.selection(s)
 local total=s.pot+(pts or 0)
 if s.phase~='ready' then return false,total,minimum,'Turn not ready' end
 if selected and not pts then return false,total,minimum,'Invalid selection' end
 if not s.scored and not pts then return false,total,minimum,'Set aside at least one scoring selection from this roll' end
 if total<=0 then return false,total,minimum,'No points to bank' end
 if total<minimum then return false,total,minimum,'You need '..(minimum-total)..' more points: keep rolling' end
 return true,total,minimum,'Banking allowed'
end
local function turn(s)
 s.phase='fresh';s.pot=0;s.used={};s.selected={};s.hand={};s.hot=false;s.scored=false;s.turnGroup=false;s.turnHot=false
 s.last='Roll six dice. Select only scoring dice.'
end
function R.new(mode)
 local s={mode=mode or 'build',stage=1,turn=1,bank=0,build='normal',medal='none',medalUsed=false,group=false,hotBank=false,entered=false}
 turn(s);return s
end
local function next_stage(s)
 s.stage=s.stage+1;s.entered=false;s.turn=1;s.bank=0;s.group=false;s.hotBank=false;s.medalUsed=false;turn(s)
 Medals.reset(s)
end
function R.can_roll(s) return s.phase=='fresh' or s.phase=='ready' and s.scored and next(s.selected)==nil end
function R.start(s)
 if not R.can_roll(s) then return false end
 if s.hot then s.used={};s.hot=false end
 s.active={};for i=1,6 do if not s.used[i] then s.active[#s.active+1]=i end end
 if #s.active==0 then return false end
 s.referenceReroll=nil;s.phase='rolling';s.scored=false;return true
end
function R.fail(s)
 if s.phase~='rescue' and s.phase~='rolling' then return false end
 s.pot=0;s.turnGroup=false;s.turnHot=false;s.selected={};s.last='FARKLE: turn points lost. Banked points are safe.'
 s.phase=s.turn>=R.contracts[s.stage].limit and 'lost' or 'ended';return true
end
function R.settle(s,values)
 if s.phase~='rolling' then return false end
 for _,i in ipairs(s.active) do local v=values[i];if type(v)~='number' or v%1~=0 or v<1 or v>6 then return false end end
 for _,i in ipairs(s.active) do s.hand[i]=values[i] end
 local h={}
 if s.referenceReroll then
  -- A medal corrects this throw, retaining unrerolled, unspent dice.
  s.active={};for i=1,6 do if not s.used[i] and s.hand[i] then s.active[#s.active+1]=i end end
 end
 for _,i in ipairs(s.active) do h[#h+1]=s.hand[i] end
 s.referenceReroll=nil
 s.selected={};s.last='Select scoring dice; set them aside to reroll, or bank.'
 if not R.has_points(h) then
  if s.medal=='retry' and not s.medalUsed then s.phase='rescue';s.last='Farkle: use your medal or accept the loss.'
  else R.fail(s) end
 else s.phase='ready' end
 return true
end
function R.toggle(s,i)
 if s.phase~='ready' or not s.hand[i] or s.used[i] then return false end
 s.selected[i]=not s.selected[i] or nil;return true
end
function R.take(s)
 if s.phase~='ready' then return false end
 local pts,g=R.selection(s);if not pts then return false end
 s.pot=s.pot+pts;s.turnGroup=s.turnGroup or g
 for i=1,6 do if s.selected[i] then s.used[i]=true end end
 s.selected={};s.scored=true
 if R.count_free(s)==0 then s.hot=true;s.turnHot=true;s.last='HOT DICE: reroll all six; your turn total remains at risk.'
 else s.last='Turn points updated. Bank or reroll the remaining dice.' end
 return true
end
function R.bank_turn(s)
 if not R.bank_status(s) then return false end
 if next(s.selected) then assert(R.take(s)) end
 s.entered=true
 s.bank=s.bank+s.pot;s.pot=0;s.group=s.group or s.turnGroup;s.hotBank=s.hotBank or s.turnHot
 if Progress.completed(s) then
  s.phase=Progress.completion_phase(s)
 else s.phase=s.turn>=Progress.contracts[s.stage].limit and 'lost' or 'ended' end
 s.last='Points banked and manuscript progress secured.';return true
end
function R.next_turn(s)
 if s.phase~='ended' then return false end
 s.turn=s.turn+1;turn(s);return true
end
function R.advance(s) if s.phase~='advance' then return false end;next_stage(s);return true end
function R.choose_build(s,build)
 if s.phase~='upgrade' or (build~='weighted' and build~='engraved' and build~='normal') then return false end
 s.build=build;next_stage(s);return true
end
function R.choose_medal(s,medal)
 if s.phase~='medal' or (medal~='retry' and medal~='none') then return false end
 s.medal=medal;next_stage(s);return true
end
function R.rescue(s)
 if s.phase~='rescue' or s.medalUsed or s.medal~='retry' then return false end
 s.medalUsed=true;s.phase='rolling';s.last='Medal used: a second chance with the same dice.';return true
end
-- Reference medals are opt-in. Equipment cannot refill an ongoing commission.
function R.equip_reference(s,id)
 local d=Medals.get(id)
 if not d or not d.enabled or s.phase~='fresh' or s.turn~=1 or s.bank~=0 or s.pot~=0 then return false end
 s.medal=id;s.medalUsed=false;Medals.reset(s);return true
end
function R.reference_status(s,ids)
 local d=Medals.get(s.medal)
 if not d then return false,'No reference medal equipped.' end
 if not d.enabled then return false,d.reason end
 if s.phase~='ready' then return false,'Available after a scoring roll, once the dice have stopped.' end
 if Medals.remaining(s)<=0 then return false,'No uses left for this commission.' end
 if d.effect=='bank_multiplier' then
  local ok,total,_,reason=R.bank_status(s)
  return ok,ok and ('Bank '..total..' x '..d.parameters.factor..' = '..total*d.parameters.factor..'; end the turn.') or reason
 end
 if d.effect=='selective_reroll' then
  if type(ids)~='table' or #ids==0 then return false,'Select 1 to '..d.parameters.count..' dice that are not set aside.' end
  if #ids>d.parameters.count then return false,'Too many dice for this medal.' end
  local seen={};local value
  for _,i in ipairs(ids) do
   if type(i)~='number' or i%1~=0 or i<1 or i>6 or seen[i] or s.used[i] or not s.hand[i] then return false,'Dice unavailable or selected more than once.' end
   seen[i]=true
   if d.parameters.same_value and value and value~=s.hand[i] then return false,'Two dice with the same value are required.' end
   value=s.hand[i]
  end
  if d.parameters.same_value and #ids~=2 then return false,'Exactly two matching dice are required.' end
  return true,'Reroll '..#ids..(#ids==1 and ' physical die' or ' physical dice')..'; keep the others. Uses 1 charge.'
 end
 return false,'Effect unavailable.'
end
function R.use_reference(s,ids)
 if not R.reference_status(s,ids) then return false end
 local d=Medals.get(s.medal)
 if d.effect=='bank_multiplier' then
  if next(s.selected) then assert(R.take(s)) end
  assert(Medals.spend(s));s.pot=s.pot*d.parameters.factor
  assert(R.bank_turn(s));s.last='Medal applied: turn total doubled and banked.'
 else
  assert(Medals.spend(s));s.active={};for _,i in ipairs(ids) do s.active[#s.active+1]=i end
  s.selected={};s.referenceReroll=true;s.phase='rolling';s.scored=false
  s.last='Medal active: physically rerolling the selected dice.'
 end
 return true
end
return R
end)()

Parts.rules.progress = Parts.progress
Parts.rules.scoring = Parts.scoring
Parts.rules.medals = Parts.medals
return Parts.rules
