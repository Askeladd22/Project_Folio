local R=require('experiments.intrecci.rules')
local A=require('experiments.intrecci.agents')
local count=tonumber(os.getenv('INTRECCI_N')) or 2000
local configurations={{name='base',turns=8,rerolls=4},{name='less_rerolls',turns=8,rerolls=3},{name='less_turns',turns=7,rerolls=4},{name='fixed_pairs',turns=8,rerolls=4,fixed=true},{name='connected',turns=8,rerolls=4,connected=true}}
local f=assert(io.open('experiments/intrecci/results.csv','w'))
f:write('config,agent,games,wins,win_rate,mean_completed,mean_rerolls,impossible_at_end,omit1,omit2,omit3,omit4,seconds\n')
local raw=assert(io.open('experiments/intrecci/games.csv','w'))
raw:write('config,agent,seed,win,completed,rerolls,feasible_at_end\n')
for _,config in ipairs(configurations) do
 R.motifs[1].palette=config.fixed and {'rosso','blu'} or nil
 R.motifs[4].palette=config.fixed and {'marrone','verde'} or nil
 R.motifs[4].cells=config.connected and {12,13,17,18} or {14,15,19,20}
 for _,kind in ipairs({'random','greedy','planner'}) do
    local start=os.clock(); local wins,completed,rerolls,impossible=0,0,0,0
    local omissions={0,0,0,0}
    for seed=1,count do
        local s=R.new(seed,config); local state=seed+773
        local function rng(n) state=(state*48271)%2147483647; return state%n+1 end
        local steps=0
        while R.result(s)=='playing' do
            steps=steps+1; assert(steps<100)
            if s.placed==2 then R.next_turn(s) else A.act(s,kind,rng) end
        end
        local won=R.result(s)=='win'; local done=R.summary(s.board)
        local possible=R.feasible(s.board,20)
        if won then
            wins=wins+1
            for k,m in ipairs(R.motifs) do if R.status(s.board,m)~=1 then omissions[k]=omissions[k]+1 end end
        end
        if not possible then impossible=impossible+1 end
        completed=completed+done; rerolls=rerolls+s.used_rerolls
        raw:write(string.format('%s,%s,%d,%d,%d,%d,%d\n',config.name,kind,seed,won and 1 or 0,done,s.used_rerolls,possible and 1 or 0))
    end
    local row=string.format('%s,%s,%d,%d,%.4f,%.3f,%.3f,%d,%d,%d,%d,%d,%.2f',config.name,kind,count,wins,wins/count,completed/count,rerolls/count,impossible,omissions[1],omissions[2],omissions[3],omissions[4],os.clock()-start)
    f:write(row..'\n'); f:flush(); raw:flush(); print(row); io.stdout:flush()
 end
end
f:close(); raw:close()
