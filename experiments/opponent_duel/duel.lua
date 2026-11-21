-- Isolated competitive duel. No graphics, no physical-die replacement,
-- no changes to the canonically implemented solo commissions.
-- Faces are injected by the caller: the opponent never chooses the outcome.
local Scoring=require('src.farkle.rules').scoring
local Duel={}

local function add_event(s,kind,detail)
 s.events[#s.events+1]={actor=s.actor,kind=kind,detail=detail}
end
local function free_ids(s)
 local ids={}
 for id=1,6 do if not s.used[id] then ids[#ids+1]=id end end
 return ids
end
local function next_actor(s)
 s.actor=s.actor=='player' and 'opponent' or 'player'
 s.pot=0
 s.used={}
 s.options=nil
 s.last_roll=nil
 s.phase='roll'
 s.turn=s.turn+1
end
function Duel.new(target)
 target=target or 500
 assert(type(target)=='number' and target%1==0 and target>0,'target must be a positive integer')
 return {target=target,actor='player',phase='roll',turn=1,pot=0,
  score={player=0,opponent=0},used={},options=nil,last_roll=nil,
  winner=nil,events={},roll_count=0}
end
function Duel.available(s)
 if s.phase=='finished' then return 0 end
 local n=#free_ids(s)
 return n==0 and 6 or n
end
function Duel.roll(s,faces)
 if s.phase~='roll' or type(faces)~='table' then return false end
 local ids=free_ids(s)
 -- Hot dice are reset by continue(), not by a hidden reroll.
 if #ids~= #faces then return false end
 for i=1,#ids do
  local v=faces[i]
  if type(v)~='number' or v%1~=0 or v<1 or v>6 then return false end
 end
 s.last_roll={}
 for i,id in ipairs(ids) do s.last_roll[id]=faces[i] end
 s.options=Scoring.options(faces,ids)
 s.roll_count=s.roll_count+1
 if #s.options==0 then
  add_event(s,'farkle',s.pot)
  next_actor(s)
 else
  add_event(s,'roll',#ids)
  s.phase='select'
 end
 return true
end
function Duel.select(s,mask)
 if s.phase~='select' or type(mask)~='number' then return false end
 local selected
 for _,o in ipairs(s.options) do if o.mask==mask then selected=o;break end end
 if not selected then return false end
 for _,id in ipairs(selected.ids) do s.used[id]=true end
 s.pot=s.pot+selected.points
 add_event(s,'select',selected.points)
 s.options=nil
 s.phase='decision'
 return true
end
function Duel.bank(s)
 if s.phase~='decision' or s.pot<=0 then return false end
 local actor=s.actor
 local points=s.pot
 s.score[actor]=s.score[actor]+points
 add_event(s,'bank',points)
 if s.score[actor]>=s.target then
  s.winner=actor
  s.phase='finished'
 else
  next_actor(s)
 end
 return true
end
function Duel.continue(s)
 if s.phase~='decision' then return false end
 if #free_ids(s)==0 then
  s.used={} -- all six scoring dice have been used: hot dice
  add_event(s,'hot_dice',6)
 end
 s.phase='roll'
 return true
end
function Duel.mask_from_ids(ids)
 if type(ids)~='table' then return nil end
 local seen,mask={},0
 for _,id in ipairs(ids) do
  if type(id)~='number' or id%1~=0 or id<1 or id>6 or seen[id] then return nil end
  seen[id]=true; mask=mask+2^(id-1)
 end
 return mask
end

return Duel
