-- Read-only projection of gameplay state. No bodies, RNG or rule mutations.
local P={transfer_duration=.52,feedback_duration=.45,score_duration=.7}
local closed={ended=true,lost=true,won=true,upgrade=true,medal=true,advance=true}
function P.new(s)
 return {game=s,stage=s.stage,turn=s.turn,bank=s.bank,pot=s.pot,phase=s.phase,shelf={},origins={},serial=0,ledger={},bonus=0,hot=s.hot,
  folio={bank=s.bank,pot=s.pot,fromBank=s.bank,fromPot=s.pot,age=P.score_duration}}
end
function P.folio_values(p,s)
 local folio=p and p.folio
 if not folio then return s.bank,s.pot end
 local progress=math.min(1,folio.age/P.score_duration)
 progress=1-(1-progress)^3
 return folio.fromBank+(folio.bank-folio.fromBank)*progress,
  folio.fromPot+(folio.pot-folio.fromPot)*progress
end
-- Snapshot the authoritative partition BEFORE take/bank clears selection.
function P.prepare(p,s)
 local o=require('src.gameplay.farkle.rules').selection_option(s)
 local groups={}
 for _,g in ipairs(o and o.groups or {}) do
  local ids={};for _,id in ipairs(g.ids) do ids[#ids+1]=id end
  local rolls={};for _,id in ipairs(ids) do rolls[id]=p.origins[id] or 0 end
  groups[#groups+1]={label=g.label,points=g.points,ids=ids,rolls=rolls}
 end
 return {groups=groups,pot=s.pot,bank=s.bank}
end
function P.commit(p,s,before,kind,reduced)
 for _,g in ipairs(before.groups) do p.ledger[#p.ledger+1]=g end
 local banked=s.bank>before.bank
 local base=0;for _,g in ipairs(p.ledger) do base=base+g.points end
 p.bonus=banked and math.max(0,s.bank-before.bank-base) or 0
 local medal=p.bonus>0 and require('src.gameplay.farkle.medals').get(s.medal)
 p.bonusLabel=medal and medal.label or 'Medal'
 local channel=banked and 'bank' or 'pot'
 local from=banked and before.bank or P.display(p,'pot',before.pot)
 p.score={channel=channel,from=from,to=s[channel],base=base,bonus=p.bonus,
  age=reduced and P.score_duration or 0,groups=banked and p.ledger or before.groups,kind=kind}
end
-- Match physical identity AND accepted throw: hot dice reuse the same IDs.
function P.contributing_dice(p)
 local marked={};local e=p and p.score
 if not e or e.age>=P.score_duration then return marked end
 for _,group in ipairs(e.groups) do
  for _,id in ipairs(group.ids) do
   local held=p.shelf[id]
   if held and group.rolls and group.rolls[id]==held.roll then marked[id]=true end
  end
 end
 return marked
end
function P.display(p,channel,actual)
 local e=p and p.score
 if not e or e.channel~=channel then return actual end
 local t=math.min(1,e.age/P.score_duration);t=1-(1-t)^3
 return math.floor(e.from+(e.to-e.from)*t+.5)
end
function P.accepted(p,indices)
 p.serial=p.serial+1
 for _,i in ipairs(indices or {}) do p.origins[i]=p.serial end
end
function P.observe(p,s,hits,reduced)
 if p.game~=s or p.stage~=s.stage or p.turn~=s.turn then
  local serial=p.game==s and p.serial or 0
  local fresh=P.new(s);for k in pairs(p) do p[k]=nil end;for k,v in pairs(fresh) do p[k]=v end;p.serial=serial
 end
 local moved=false
 if p.folio.bank~=s.bank or p.folio.pot~=s.pot then
  local bank,pot=P.folio_values(p,s)
  p.folio={bank=s.bank,pot=s.pot,fromBank=bank,fromPot=pot,age=reduced and P.score_duration or 0}
 end
 for i=1,6 do
  if s.used[i] then
   if not p.shelf[i] then
    local origin
    for _,h in ipairs(hits or {}) do if h.index==i then origin={x=h.x,y=h.y};break end end
    p.shelf[i]={id=i,value=s.hand[i],roll=p.origins[i] or 0,stage=s.stage,turn=s.turn,
     age=reduced and P.transfer_duration or 0,origin=origin};moved=true
   end
  else p.shelf[i]=nil end
 end
 local event
 if closed[s.phase] and (not closed[p.phase] or s.bank>p.bank) then
  local gained=s.bank-p.bank
  p.conclusion={kind=gained>0 and 'bank' or 'loss',points=gained>0 and gained or p.pot,
   bank=s.bank,stage=s.stage,turn=s.turn,remaining=math.max(0,require('src.gameplay.farkle.rules').contracts[s.stage].limit-s.turn),
   age=reduced and P.feedback_duration or 0}
  event=p.conclusion.kind
  if event=='loss' then p.score=nil;p.bonus=0 end
 end
 local hot=s.hot and not p.hot
 p.bank=s.bank;p.pot=s.pot;p.phase=s.phase;p.hot=s.hot
 return event or (hot and 'hot' or moved and 'take' or nil)
end
function P.update(p,dt,reduced)
 if p.folio then p.folio.age=reduced and P.score_duration or math.min(P.score_duration,p.folio.age+math.max(0,dt)) end
 for _,e in pairs(p.shelf) do e.age=reduced and P.transfer_duration or math.min(P.transfer_duration,e.age+dt) end
 if p.conclusion then p.conclusion.age=reduced and P.feedback_duration or math.min(P.feedback_duration,p.conclusion.age+dt) end
 if p.score then p.score.age=reduced and P.score_duration or math.min(P.score_duration,p.score.age+math.max(0,dt)) end
end
function P.finish(p)
 P.update(p,math.max(P.transfer_duration,P.feedback_duration,P.score_duration),true)
end
return P
