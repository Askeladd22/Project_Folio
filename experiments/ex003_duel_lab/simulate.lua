-- EX-003 D vs C: separate-rule comparative pilot with within-model
-- paired seed policy contrasts. NOT a causal D-C estimate and NOT mastery.
local E=require('experiments.encounter_ac_lab.engine')
local Rules=require('src.farkle.rules')
local RNG=require('experiments.opponent_wager_lab.rng')
local Direct=require('experiments.ex003_duel_lab.direct')
local Policy=require('experiments.ex003_duel_lab.policy')
local M={}
M.models={'D','C'}
M.policies=Policy.profiles
M.first_pilot=16000
M.last_pilot=16199

local function play_c(seed,profile)
 local s=E.new('C',seed,{rival_target_mode='reactive'})
 local out={model='C',seed=seed,policy=profile,winner=nil,
  rounds=0,player_banked=0,rival_banked=nil,player_busts=0,
  rival_busts=nil,player_rolls=0,rival_rolls=0,bank_choices=0,
  stop_differences=0,claim_choices=0,claim_differences=0}
 for step=1,300 do
  if s.phase=='finished' then
   out.winner=s.winner
   out.rounds=s.round
   out.player_banked=s.banked
   out.player_busts=s.busts
   assert(out.rounds<=6 and out.player_banked>=0)
   return out
  end
  if s.phase=='dice' then
   if s.turn.phase=='fresh' then
    s.random=RNG.new_rng(Policy.stream_seed(seed,s.round,1))
   end
   if E.can_roll(s) then
    assert(E.roll(s))
    out.player_rolls=out.player_rolls+1
   else
    local o=Policy.best_option(s.turn,profile)
    local potential=s.turn.pot+o.points
    local free_after=Rules.count_free(s.turn)-#o.ids
    local context={round=s.round,lanes=s.lanes}
    local bank=Policy.wants_bank('C',profile,context,potential,free_after)
    local balanced=Policy.wants_bank('C','balanced',context,potential,free_after)
    out.bank_choices=out.bank_choices+1
    if bank~=balanced then
     out.stop_differences=out.stop_differences+1
    end
    for _,id in ipairs(o.ids) do assert(E.toggle(s,id)) end
    if bank then
     assert(E.can_bank(s),'C bank selection not legal')
     assert(E.bank(s))
    else
     assert(E.take(s))
    end
   end
  elseif s.phase=='claim' then
   local chosen,first,diff=Policy.choose_claim(s,profile)
   out.claim_choices=out.claim_choices+1
   if diff then out.claim_differences=out.claim_differences+1 end
   assert(s.lanes[chosen] and not s.lanes[chosen].owner)
   assert(E.claim(s,chosen))
  elseif s.phase=='round_end' then
   assert(E.next_round(s))
  else
   error('EX-003 unexpected C phase '..tostring(s.phase))
  end
 end
 error('EX-003 C exceeded 300 steps at seed '..seed)
end

function M.play(model,seed,profile)
 assert(model=='D' or model=='C')
 assert(type(seed)=='number' and seed>=1 and seed<1000000 and seed%1==0)
 assert(Policy.stops[profile] or profile=='situational')
 if model=='D' then return Direct.play(seed,profile) end
 return play_c(seed,profile)
end

local function csv(...)
 local fields={...}
 local count=select('#',...)
 for i=1,count do
  local v=fields[i]
  local s=tostring(v==nil and '' or v)
  if s:find('[,"\r\n]') then s='"'..s:gsub('"','""')..'"' end
  fields[i]=s
 end
 return table.concat(fields,',')..'\n'
end

local function blank()
 return {n=0,player=0,rival=0,draw=0,player_banked=0,
  rival_banked=0,player_busts=0,rival_busts=0,
  player_rolls=0,rival_rolls=0,rounds=0,
  bank_choices=0,stop_differences=0,claim_choices=0,claim_differences=0}
end
local function add(b,s)
 b.n=b.n+1
 b[s.winner]=b[s.winner]+1
 for _,key in ipairs({'player_banked','rival_banked','player_busts',
   'rival_busts','player_rolls','rival_rolls','rounds',
   'bank_choices','stop_differences','claim_choices','claim_differences'}) do
  b[key]=b[key]+(s[key] or 0)
 end
end
local function win(s) return s.winner=='player' and 1 or 0 end
local function fmt(n) return ('%.3f'):format(n) end

-- Pre-registered pilot 16000..16199. Run only for a dedicated branch.
function M.pilot(first,last,dir)
 assert(type(first)=='number' and first%1==0 and first>=M.first_pilot)
 assert(type(last)=='number' and last%1==0 and last>=first
  and last<=M.last_pilot and last-first<1000)
 local n=last-first+1
 local file
 if dir then
  file=assert(io.open(dir..'/ex003_matches.csv','w'))
  file:write(csv('seed','model','profile','winner','rounds','player_banked',
   'rival_banked','player_busts','rival_busts','player_rolls',
   'rival_rolls','bank_choices','stop_differences',
   'claim_choices','claim_differences'))
 end
 local report={'EX-003 preregistered PILOT '..first..'..'..last..
  ' ('..n..' matched seeds / model / profile)',
  'Within-arm paired analysis ONLY. D and C have DIFFERENT win rules; raw win rates are not a causal D-C comparison.',
  'Same seeded player die stream at each round start; later dice can diverge after different selections.',
  'model | profile | player/rival/draw | mean P bank | mean R bank (D only) | mean P bust | stop differences / decisions | claim differences / decisions'}
 for _,model in ipairs(M.models) do
  local rows={}
  local sums,sq=0,0
  local buckets={}
  for _,profile in ipairs(M.policies) do buckets[profile]=blank() end
  for seed=first,last do
   for _,profile in ipairs(M.policies) do
    local s=M.play(model,seed,profile)
    assert(s.winner=='player' or s.winner=='rival' or s.winner=='draw')
    rows[profile]=s
    add(buckets[profile],s)
    if file then
     file:write(csv(seed,model,profile,s.winner,s.rounds,
      s.player_banked,s.rival_banked,s.player_busts,
      s.rival_busts,s.player_rolls,s.rival_rolls,
      s.bank_choices,s.stop_differences,s.claim_choices,
      s.claim_differences))
    end
   end
   local delta=win(rows.situational)-win(rows.balanced)
   sums=sums+delta
   sq=sq+delta*delta
  end
  for _,profile in ipairs(M.policies) do
   local b=buckets[profile]
   assert(b.n==n)
   report[#report+1]=table.concat({model,profile,
    b.player..'/'..b.rival..'/'..b.draw,
    fmt(b.player_banked/n),
    model=='D' and fmt(b.rival_banked/n) or 'not-applicable',
    fmt(b.player_busts/n),
    b.stop_differences..'/'..b.bank_choices,
    b.claim_differences..'/'..b.claim_choices},' | ')
  end
  local mean=sums/n
  local variance=n>1 and math.max(0,(sq-sums*sums/n)/(n-1)) or 0
  local margin=1.96*math.sqrt(variance/n)
  report[#report+1]=model..' within-arm Δwin(P situational-balanced): '..
   fmt(mean)..' approx95 ['..fmt(mean-margin)..', '..fmt(mean+margin)..
   '] (exploratory normal interval, not a mastery estimate)'
 end
 if file then assert(file:close()) end
 return table.concat(report,'\n')
end

return M
