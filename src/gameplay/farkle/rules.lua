local Progress=require('src.gameplay.farkle.commission_progress')
local R={contracts=Progress.contracts}
local Scoring=require('src.gameplay.farkle.scoring')
local Medals=require('src.gameplay.farkle.medals')
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
 else s.phase=s.turn>=c.limit and 'lost' or 'ended' end
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
