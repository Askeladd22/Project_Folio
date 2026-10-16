local R=require('experiments.arte_del_rischio.rules')
local A=require('experiments.arte_del_rischio.agents')
local RNG=require('experiments.arte_del_rischio.rng')
local out=assert(io.open('experiments/arte_del_rischio/results.csv','w'))
out:write('variant,agent,n,wins,mean,p10,p50,p90,projects1,projects2,projects3,changes,temptations,risk_rolls,risk_success,stop_better,roll_better,near_tie,completed_stops,tempt1,tempt2,tempt3,tempt4plus,reroll1,reroll2,reroll3,reroll4,tempt_opportunities\n')
local games=assert(io.open('experiments/arte_del_rischio/games.csv','w'))
games:write('variant,agent,seed,score,win,p1,p2,p3,temptations\n')
local policies={'random','opportunist','planner','planner_no_tempt','planner_no_risk','fixed1','fixed2','fixed3','threshold_planner'}
for _,variant in ipairs({'A','B','C'}) do for _,label in ipairs(policies) do
 local policy=label=='random' and 'random' or label=='opportunist' and 'opportunist' or label=='threshold_planner' and label or 'planner'
 local fixed=tonumber(label:match('fixed(%d)')); local nt=label=='planner_no_tempt'
 local stats={wins=0,sum=0,projects={0,0,0},changes=0,tempt=0,risk=0,success=0,stop=0,roll=0,tie=0,stops=0,ts={0,0,0,0},scores={},rr={0,0,0,0},to=0}
 for seed=10001,12000 do
  local face_rng,random=RNG.new(seed),RNG.new(seed+987654)
  local function face() return face_rng(6) end
  local s=R.new(variant)
  local function roll(mask,tempt)
   local risk=R.score(s.project,s.hand)>0
   if s.phase=='ready' then local n=0; for i=1,4 do if R.has(mask,i) then n=n+1 end end; stats.rr[n]=stats.rr[n]+1 end
   assert(R.start(s,mask,tempt))
   local h={}; for i=1,4 do if R.has(mask,i) then h[i]=face() end end
   assert(R.settle(s,h))
   if risk then stats.risk=stats.risk+1; if s.phase=='ready' then stats.success=stats.success+1 end end
   if tempt then stats.tempt=stats.tempt+1; local k=math.min(4,s.temptations); stats.ts[k]=stats.ts[k]+1 end
  end
  while not s.finished do
   if s.phase=='choose' then
    if variant~='B' then R.select(s,policy=='random' and random(3) or A.initial(s,policy,fixed,nt)) end
    roll(15,false)
   elseif s.phase=='ended' then assert(R.next_turn(s))
   else
    local p,v
    if policy=='random' then
     p=s.project or random(3)
     if variant=='C' and not s.changed and random(4)==1 then p=random(3) end
    else p,v=A.choose(s,policy,fixed,nt) end
    if p~=s.project then local prior=s.project; assert(R.select(s,p)); if prior then stats.changes=stats.changes+1 end end
    local complete=R.score(s.project,s.hand)>0
    if s.rerolls==0 and not s.tempted and not nt then stats.to=stats.to+1 end
    if policy~='random' and complete and (s.rerolls>0 or (not s.tempted and not nt)) then
     local gap=v.roll-v.bank
     if gap>.05 then stats.roll=stats.roll+1 elseif gap<-.05 then stats.stop=stats.stop+1 else stats.tie=stats.tie+1 end
    end
    if policy=='random' then
     if complete and random(2)==1 then R.bank(s); stats.stops=stats.stops+1
     elseif s.rerolls>0 then roll(random(15),false)
     elseif not s.tempted and random(2)==1 then roll(random(15),true)
     elseif complete then R.bank(s); stats.stops=stats.stops+1 else R.abandon(s) end
    elseif v.kind=='bank' or (label=='planner_no_risk' and complete) then R.bank(s); stats.stops=stats.stops+1
    elseif v.kind=='roll' then roll(A.mask(s.hand,v.kept),v.tempt)
    else R.abandon(s) end
   end
  end
  stats.sum=stats.sum+s.score; stats.wins=stats.wins+(s.won and 1 or 0); stats.scores[#stats.scores+1]=s.score
  for p=1,3 do stats.projects[p]=stats.projects[p]+s.counts[p] end
  games:write(table.concat({variant,label,seed,s.score,s.won and 1 or 0,s.counts[1],s.counts[2],s.counts[3],s.temptations},',')..'\n')
 end
 table.sort(stats.scores)
 local row={variant,label,2000,stats.wins,stats.sum/2000,stats.scores[200],stats.scores[1000],stats.scores[1800],unpack(stats.projects)}
 for _,v in ipairs({stats.changes,stats.tempt,stats.risk,stats.success,stats.stop,stats.roll,stats.tie,stats.stops,unpack(stats.ts)}) do row[#row+1]=v end
 for _,v in ipairs(stats.rr) do row[#row+1]=v end; row[#row+1]=stats.to
 out:write(table.concat(row,',')..'\n'); out:flush(); games:flush()
 print(variant,label,'wins',stats.wins,'mean',stats.sum/2000,'risk',stats.risk,'tempt',stats.tempt)
end end
out:close(); games:close()
