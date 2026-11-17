-- EX-002b exploratory diagnostic, added AFTER the frozen 1000..1999 pilot.
-- It tests a deliberately different, non-optimized player strategy, NOT mastery.
local X=require('experiments.ex002_reactivity_lab.simulate')
local M={}
local function csv(...)
 local cols={...}
 for i,value in ipairs(cols) do
  local v=tostring(value)
  if v:find('[,"\r\n]') then v='"'..v:gsub('"','""')..'"' end
  cols[i]=v
 end
 return table.concat(cols,',')..'\n'
end
local function bucket()
 return {wins=0,losses=0,draws=0,rounds=0,busts=0,choices=0,
  sensitive=0,nonlocking_sensitive=0,banked=0}
end
local function add(b,s,stats)
 if s.winner=='player' then b.wins=b.wins+1
 elseif s.winner=='rival' then b.losses=b.losses+1
 else b.draws=b.draws+1 end
 b.rounds=b.rounds+s.round;b.busts=b.busts+s.busts
 b.choices=b.choices+stats.choice_states
 b.sensitive=b.sensitive+stats.target_sensitive
 b.nonlocking_sensitive=b.nonlocking_sensitive+stats.nonlocking_target_sensitive
 b.banked=b.banked+s.banked
end
function M.report(first,last,dir)
 assert(type(first)=='number' and first%1==0 and first>=7000,
  'exploratory seed window must be outside pilot and reserved holdout')
 assert(type(last)=='number' and last%1==0 and last>=first and last-first<=999,
  'EX-002b max 1000 seeds per policy')
 local f
 if dir then
  f=assert(io.open(dir..'/ex002b_matches.csv','w'))
  f:write('seed,dice_policy,mode,winner,rounds,busts,banked,claims,target_sensitive,nonlocking_target_sensitive,chosen_rival_targets\n')
 end
 local out={'EX-002b POST-PILOT EXPLORATORY stress: last-open category only',
  'Seeds '..first..'..'..last..'; no holdout 2000..6999; no human skill model.',
  'dice | mode | P/R/D | mean rounds | target-sensitive / claims | nonlocking-sensitive',
  'Paired delta R-F win (normal approx 95%); sample hypothesis-generating only.'}
 local n=last-first+1
 for _,dice in ipairs(X.dice_policies) do
  local bs={reactive=bucket(),fixed=bucket()}
  local sum,sq=0,0
  local divergent_target_matches=0
  local divergent_outcome_matches=0
  for seed=first,last do
   local played={}
   for _,mode in ipairs(X.rival_modes) do
    local targets={}
    local s,stats=X.play(seed,mode,dice,'last',function(round,marks,probe,row,chosen)
     if row.lane==chosen then
      targets[#targets+1]=round..':'..row.rival_target
     end
    end)
    played[mode]={s=s,targets=table.concat(targets,'|')}
    add(bs[mode],s,stats)
    if f then f:write(csv(seed,dice,mode,s.winner,s.round,s.busts,s.banked,
      stats.choice_states,stats.target_sensitive,stats.nonlocking_target_sensitive,
      played[mode].targets)) end
   end
   if played.reactive.targets~=played.fixed.targets then
    divergent_target_matches=divergent_target_matches+1
   end
   if played.reactive.s.winner~=played.fixed.s.winner then
    divergent_outcome_matches=divergent_outcome_matches+1
   end
   local d=(played.reactive.s.winner=='player' and 1 or 0)-
           (played.fixed.s.winner=='player' and 1 or 0)
   sum=sum+d;sq=sq+d*d
  end
  for _,mode in ipairs(X.rival_modes) do
   local b=bs[mode]
   out[#out+1]=string.format('%s | %s | %d/%d/%d | %.3f | %d/%d | %d',
    dice,mode,b.wins,b.losses,b.draws,b.rounds/n,
    b.sensitive,b.choices,b.nonlocking_sensitive)
  end
  local mean=sum/n
  local var=n>1 and math.max(0,(sq-sum*sum/n)/(n-1)) or 0
  local margin=1.96*math.sqrt(var/n)
  out[#out+1]=string.format(
   '%s paired win delta R-F %+.4f approx95 [%+.4f,%+.4f]; mismatched target traces %d/%d; mismatched winners %d/%d',
   dice,mean,mean-margin,mean+margin,divergent_target_matches,n,
   divergent_outcome_matches,n)
 end
 if f then f:close() end
 return table.concat(out,'\n')
end
return M
