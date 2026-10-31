-- Reproducible CONTROLLED laboratory A/B/C0/C, not gameplay.
-- Every compared policy gets the same die face for a given
-- (seed, hand, roll index, physical die ID), irrespective of RNG consumption.
-- The hidden sign deck is independently shuffled using the same seed.
local Turn=require('experiments.signs_lab.farkle_turn')
local Encounter=require('experiments.signs_lab.encounter')
local Fixture=require('experiments.signs_lab.fixture')
local Rules=require('src.gameplay.farkle.rules')
local M={}
M.policies={'prudent','audace','reattiva'}
M.modes={'A','B','C0','C'}

-- A: shipping first commission, bank >=100 within 4 hands.
-- B: fixed three progress marks, bank >=35 once per hand, max 6 hands.
-- C0: exactly the same sign deck/forces as C, but no double-mark effects.
-- C: full unapproved six-Sign Leone della Bordura proposal.
-- B/C0/C share 3 marks and <=6 hands, but not identical stochastic goals.
local function no_bonus_fixture()
 local f={}
 for k,v in pairs(Fixture) do f[k]=v end
 f.occasion_margin=1000000 -- no legal 64-roll turn reaches this threshold
 f.assault_farkle_enemy_marks=1
 return f
end
local no_bonus=no_bonus_fixture()

local function valid_mode(mode)
 return mode=='A' or mode=='B' or mode=='C0' or mode=='C'
end

function M.run(mode,policy,seed)
 assert(valid_mode(mode),'unknown experimental control')
 assert(type(seed)=='number' and seed%1==0 and seed>=1
  and seed<2147483647,'invalid experiment seed')
 local bag=Turn.new_rng(((seed*13+103)%2147483646)+1)
 local encounter=(mode=='C' or mode=='C0')
  and Encounter.new(mode=='C' and Fixture or no_bonus,bag) or nil
 local limit=mode=='A' and Rules.contracts[1].limit or Fixture.max_hands
 local total,bust,rolls,hands,diff,marks=0,0,0,0,0,0
 local choices={bank=0,roll=0}
 local categories={}
 local last
 for hand=1,limit do
  local announced=encounter and encounter:announce() or nil
  local cat=announced and announced.category or 'nessuno'
  local category=categories[cat] or {bank=0,roll=0,disagreements=0}
  categories[cat]=category
  -- Per-hand stateless stream preserves the same common random outcomes
  -- even if another policy took more rolls or set aside different dice.
  local result=Turn.play(Turn.matched_rolls(seed,hand),policy,
   announced and announced.category or nil,
   function(snapshot,decision)
    choices[decision]=choices[decision]+1
    category[decision]=category[decision]+1
    local prudent=Turn.decision('prudent',snapshot)
    local audace=Turn.decision('audace',snapshot)
    local reattiva=Turn.decision('reattiva',snapshot)
    if prudent~=audace or prudent~=reattiva then
     diff=diff+1
     category.disagreements=category.disagreements+1
    end
   end)
  hands=hands+1
  bust=bust+(result.farkle and 1 or 0)
  rolls=rolls+result.rolls
  total=total+result.banked
  if encounter then
   last=encounter:resolve(result)
   if encounter.finished then break end
  elseif mode=='B' then
   if not result.farkle and result.banked>=35 then marks=marks+1 end
   if marks>=Fixture.target_wins then break end
  elseif total>=Rules.contracts[1].target then break end
 end
 local won=encounter and encounter.winner=='player' or
  mode=='B' and marks>=Fixture.target_wins or
  mode=='A' and total>=Rules.contracts[1].target or false
 return {
  mode=mode,policy=policy,seed=seed,hands=hands,bust=bust,
  rolls=rolls,banked=total,won=won,progress_marks=marks,
  decisions=choices,disagreements=diff,categories=categories,
  player_marks=encounter and encounter.player_marks or nil,
  enemy_marks=encounter and encounter.enemy_marks or nil,
  sign_history=encounter and encounter.history or nil,
  winner=encounter and encounter.winner or (won and 'player' or 'none'),
  last_sign=last,
 }
end

local function row(mode,policy,n)
 return {mode=mode,policy=policy,samples=n,
  success=0,hands=0,bust=0,rolls=0,banked=0,
  marks=0,bank_choices=0,roll_choices=0,disagreements=0,
  categories={},outcomes={player=0,enemy=0,tie=0,none=0}}
end
local function add(row,s)
 row.success=row.success+(s.won and 1 or 0)
 row.hands=row.hands+s.hands
 row.bust=row.bust+s.bust
 row.rolls=row.rolls+s.rolls
 row.banked=row.banked+s.banked
 row.marks=row.marks+(s.player_marks or s.progress_marks)
 row.bank_choices=row.bank_choices+s.decisions.bank
 row.roll_choices=row.roll_choices+s.decisions.roll
 row.disagreements=row.disagreements+s.disagreements
 row.outcomes[s.winner]=row.outcomes[s.winner]+1
 for cat,counts in pairs(s.categories) do
  local dest=row.categories[cat]
  if not dest then
   dest={bank=0,roll=0,disagreements=0}
   row.categories[cat]=dest
  end
  dest.bank=dest.bank+counts.bank
  dest.roll=dest.roll+counts.roll
  dest.disagreements=dest.disagreements+counts.disagreements
 end
end
local function new_pair(policy,control,variant,n)
 return {policy=policy,control=control,variant=variant,samples=n,
  both=0,control_only=0,variant_only=0,neither=0}
end
local function add_pair(pair,base,variant)
 if base.won and variant.won then pair.both=pair.both+1
 elseif base.won then pair.control_only=pair.control_only+1
 elseif variant.won then pair.variant_only=pair.variant_only+1
 else pair.neither=pair.neither+1 end
end
local function finish_pair(pair)
 local n=pair.samples
 local delta=(pair.variant_only-pair.control_only)/n
 local sum=pair.variant_only+pair.control_only
 local se=n>1 and math.sqrt(math.max(0,(sum-n*delta*delta)/
  (n*(n-1)))) or 0
 pair.delta=delta
 pair.se=se
 pair.low=math.max(-1,delta-1.96*se)
 pair.high=math.min(1,delta+1.96*se)
 -- Descriptive approximate 95% interval; this is NOT a p-value or
 -- evidence of human gameplay advantage.
end
function M.analyze(samples,start_seed)
 assert(type(samples)=='number' and samples%1==0
  and samples>0 and samples<=10000,'sample count 1..10000')
 start_seed=start_seed or 1
 assert(type(start_seed)=='number' and start_seed%1==0 and
  start_seed>=1 and start_seed+samples-1<2147483647,
  'invalid benchmark seed range')
 local rows,by_key,pairs={}, {},{}
 for _,mode in ipairs(M.modes) do
  by_key[mode]={}
  for _,policy in ipairs(M.policies) do
   local current=row(mode,policy,samples)
   rows[#rows+1]=current
   by_key[mode][policy]=current
  end
 end
 for _,policy in ipairs(M.policies) do
  pairs[policy]={
   new_pair(policy,'B','C',samples),
   new_pair(policy,'C0','C',samples),
  }
 end
 for i=0,samples-1 do
  for _,policy in ipairs(M.policies) do
   local sample={}
   for _,mode in ipairs(M.modes) do
    local current=M.run(mode,policy,start_seed+i)
    sample[mode]=current
    add(by_key[mode][policy],current)
   end
   add_pair(pairs[policy][1],sample.B,sample.C)
   add_pair(pairs[policy][2],sample.C0,sample.C)
  end
 end
 local flat={}
 for _,policy in ipairs(M.policies) do
  for _,pair in ipairs(pairs[policy]) do
   finish_pair(pair)
   flat[#flat+1]=pair
  end
 end
 return {rows=rows,pairs=flat,seed=start_seed,samples=samples}
end
function M.compare(samples,start_seed)
 return M.analyze(samples,start_seed).rows
end
return M
