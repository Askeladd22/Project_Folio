-- PROTOTYPE C: 2026-10-31 proposed Duello delle Poste, NOT game rules.
-- Independent encounter ledger: only accepts a completed, officially scored
-- turn (banked points / Farkle); never changes Rules, dice or physical events.
local Bag=require('experiments.signs_lab.bag')
local M={}
local Encounter={}
Encounter.__index=Encounter

function M.new(fixture,random)
 assert(type(fixture)=='table' and fixture.signs,'encounter fixture needed')
 for _,key in ipairs{'target_wins','max_hands','occasion_margin',
  'assault_farkle_enemy_marks'} do
  assert(type(fixture[key])=='number' and fixture[key]>=0
   and fixture[key]%1==0,'invalid experiment fixture '..key)
 end
 assert(fixture.target_wins>0 and fixture.max_hands>0)
 return setmetatable({
  fixture=fixture,bag=Bag.new(fixture.signs,random),
  hands=0,player_marks=0,enemy_marks=0,
  current=nil,finished=false,winner=nil,history={},
 },Encounter)
end

function Encounter:announce()
 assert(not self.finished and not self.current,'encounter not awaiting a sign')
 self.current=self.bag:announce()
 return {category=self.current.category,remaining=self.current.remaining,
  recycle_count=self.current.recycle_count}
end

function Encounter:resolve(result)
 assert(self.current and not self.finished,'announce one sign first')
 assert(type(result)=='table','completed Farkle turn required')
 assert(type(result.banked)=='number' and result.banked%1==0 and
  result.banked>=0,'banked points must come from the official turn')
 assert(type(result.farkle)=='boolean','explicit completed Farkle status required')
 assert(not result.farkle or result.banked==0,'Farkle cannot bank points')
 local sign=self.bag:resolve()
 local won=not result.farkle and result.banked>=sign.strength
 local margin=result.banked-sign.strength
 local gain=1
 if won and sign.category=='occasione' and
  margin>=self.fixture.occasion_margin then gain=2 end
 if not won and result.farkle and sign.category=='assalto' then
  gain=self.fixture.assault_farkle_enemy_marks
 end
 if won then self.player_marks=self.player_marks+gain
 else self.enemy_marks=self.enemy_marks+gain end
 self.hands=self.hands+1
 self.current=nil
 if self.player_marks>=self.fixture.target_wins or
  self.enemy_marks>=self.fixture.target_wins or
  self.hands>=self.fixture.max_hands then
  self.finished=true
  if self.player_marks>self.enemy_marks then self.winner='player'
  elseif self.enemy_marks>self.player_marks then self.winner='enemy'
  else self.winner='tie' end
 end
 local report={hand=self.hands,category=sign.category,id=sign.id,
  strength=sign.strength,banked=result.banked,farkle=result.farkle,
  winner_of_hand=won and 'player' or 'enemy',marks=gain,
  player_marks=self.player_marks,enemy_marks=self.enemy_marks,
  finished=self.finished,winner=self.winner,margin=margin}
 self.history[#self.history+1]=report
 return report
end
return M
