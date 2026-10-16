local M=require('experiments.contesi.model')
local A=require('experiments.contesi.agents')
local N=tonumber(os.getenv('CONTESI_N')) or 2000
local f=assert(io.open('experiments/contesi/results.csv','w'))
local raw=assert(io.open('experiments/contesi/games.csv','w'))
f:write('config,agent,n,wins,win_rate,route_BCD,route_ACD,mean_rerolls,mean_commit_turn,dead_states,seconds\n')
raw:write('config,agent,seed,win,route,rerolls,commit_turn,dead\n')
for _,cfg in ipairs(M.configs) do
 for _,kind in ipairs({'random','greedy','planner','planner_no_rerolls','fixed_BCD','fixed_ACD','greedy_fixed_BCD','greedy_fixed_ACD'}) do
  local wins,spent,commit,dead=0,0,0,0; local routes={0,0}; local start=os.clock()
  for seed=10001,10000+N do
   local s=M.new(cfg,seed,kind=='planner_no_rerolls' and 0 or 4)
   local rngstate=seed+700001
   local function rng(n) rngstate=(rngstate*48271)%2147483647; return math.floor(rngstate/2147483647*n)+1 end
   local committed=0; local steps=0
   while s.turn<=8 and not M.winner(s) do
    local obs=M.observe(s)
    if kind=='fixed_BCD' or kind=='greedy_fixed_BCD' then obs.routes={s.routes[1]}
    elseif kind=='fixed_ACD' or kind=='greedy_fixed_ACD' then obs.routes={s.routes[2]} end
    local policy=kind=='random' and 'random' or (kind:find('greedy') and 'greedy' or 'planner')
    local act=A.choose(obs,policy,rng)
    local old={}; for i,c in pairs(s.board) do old[i]=c end
    M.apply(s,act)
    for i,c in pairs(old) do assert(s.board[i]==c) end
    if committed==0 and #M.live(s)==1 then committed=math.min(8,s.turn) end
    steps=steps+1; assert(steps<=28)
   end
   local winner=M.winner(s); local isdead=#M.live(s)==0
   if winner then wins=wins+1; routes[winner]=routes[winner]+1 end
   spent=spent+s.spent; commit=commit+committed; if isdead then dead=dead+1 end
   raw:write(string.format('%s,%s,%d,%d,%d,%d,%d,%d\n',cfg.name,kind,seed,winner and 1 or 0,winner or 0,s.spent,committed,isdead and 1 or 0))
  end
  local row=string.format('%s,%s,%d,%d,%.5f,%d,%d,%.3f,%.3f,%d,%.2f',cfg.name,kind,N,wins,wins/N,routes[1],routes[2],spent/N,commit/N,dead,os.clock()-start)
  f:write(row..'\n'); f:flush(); raw:flush(); print(row); io.stdout:flush()
 end
end
f:close(); raw:close()
