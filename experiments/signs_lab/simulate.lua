-- Paired-seed diagnostic A/B/C only. No graphical game integration.
-- Outcomes are incomparable "wins" under different goals: analyze choices,
-- not raw difficulty or counts. All rolls use official Rules via farkle_turn.
local Turn=require('experiments.signs_lab.farkle_turn')
local Encounter=require('experiments.signs_lab.encounter')
local Fixture=require('experiments.signs_lab.fixture')
local Rules=require('src.gameplay.farkle.rules')
local M={}
M.policies={'prudent','audace','reattiva'}
M.modes={'A','B','C'}
-- A = current first commission (100 banked in <=4 hands).
-- B = simple progress proxy (100 banked in <=6 hands).
-- C = experimental signs duel: first to 3 marks, <=6 hands.
-- These are NOT equally difficult objectives. Track choice sensitivity.

local function run(mode,strategy,seed)
 assert(mode=='A' or mode=='B' or mode=='C','unknown prototype')
 local dice=Turn.new_rng(seed)
 local bag=Turn.new_rng(((seed*13+103)%2147483646)+1)
 local encounter=mode=='C' and Encounter.new(Fixture,bag) or nil
 local limit=mode=='A' and Rules.contracts[1].limit or Fixture.max_hands
 local total,bust,rolls,hands,diff=0,0,0,0,0
 local choices={bank=0,roll=0}
 local last
 for _=1,limit do
  local announced=encounter and encounter:announce() or nil
  local cat=announced and announced.category or nil
  local result=Turn.play(dice,strategy,cat,function(snapshot,decision)
   choices[decision]=choices[decision]+1
   -- All three policies inspect the SAME public pre-decision state.
   -- This is a choice disagreement counter, not a proof of superiority.
   local first=Turn.decision('prudent',snapshot)
   local second=Turn.decision('audace',snapshot)
   local third=Turn.decision('reattiva',snapshot)
   if first~=second or first~=third then diff=diff+1 end
  end)
  hands=hands+1
  bust=bust+(result.farkle and 1 or 0)
  rolls=rolls+result.rolls
  total=total+result.banked
  if encounter then
   last=encounter:resolve(result)
   if encounter.finished then break end
  elseif total>=Rules.contracts[1].target then break end
 end
 local won
 if encounter then won=encounter.winner=='player'
 else won=total>=Rules.contracts[1].target end
 return {
  mode=mode,policy=strategy,seed=seed,hands=hands,bust=bust,
  rolls=rolls,banked=total,won=won,
  decisions=choices,disagreements=diff,
  player_marks=encounter and encounter.player_marks or nil,
  enemy_marks=encounter and encounter.enemy_marks or nil,
  sign_history=encounter and encounter.history or nil,
  winner=encounter and encounter.winner or (won and 'player' or 'none'),
  last_sign=last,
 }
end
M.run=run

function M.compare(samples,start_seed)
 assert(type(samples)=='number' and samples%1==0
  and samples>0 and samples<=10000,'sample size must be 1..10000')
 start_seed=start_seed or 1
 local out={}
 for _,mode in ipairs(M.modes) do
  for _,policy in ipairs(M.policies) do
   local row={mode=mode,policy=policy,samples=samples,
    success=0,hands=0,bust=0,rolls=0,banked=0,
    bank_choices=0,roll_choices=0,disagreements=0,
    outcomes={player=0,enemy=0,tie=0,none=0}}
   for i=0,samples-1 do
    local sample=run(mode,policy,start_seed+i)
    row.success=row.success+(sample.won and 1 or 0)
    row.hands=row.hands+sample.hands
    row.bust=row.bust+sample.bust
    row.rolls=row.rolls+sample.rolls
    row.banked=row.banked+sample.banked
    row.bank_choices=row.bank_choices+sample.decisions.bank
    row.roll_choices=row.roll_choices+sample.decisions.roll
    row.disagreements=row.disagreements+sample.disagreements
    row.outcomes[sample.winner]=row.outcomes[sample.winner]+1
   end
   out[#out+1]=row
  end
 end
 return out
end
return M
