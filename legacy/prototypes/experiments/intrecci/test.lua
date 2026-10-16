local R=require('experiments.intrecci.rules')
local function rejects(f) assert(not pcall(f)) end
local m=R.motifs[1]
assert(R.status({[1]='rosso',[2]='blu',[6]='blu',[7]='rosso'},m)==1)
assert(R.status({[1]='rosso',[7]='blu'},m)==-1)
assert(R.status({[1]='rosso',[2]='rosso'},m)==-1)
assert(R.status({[3]='rosso',[4]='blu',[8]='verde',[9]='nero'},R.motifs[2])==1)
assert(R.status({[3]='rosso',[9]='rosso'},R.motifs[2])==-1)
assert(R.feasible({},12)); assert(not R.feasible({},9))
local impossible={[1]='rosso',[2]='rosso',[3]='blu',[4]='blu'}
assert(not R.feasible(impossible,20))
local s=R.new(42,{turns=8,rerolls=4})
local c=s.hand[1]; R.place(s,1,1); assert(s.board[1]==c)
rejects(function() R.place(s,1,2) end)
rejects(function() R.place(s,2,1) end)
rejects(function() R.reroll(s,{1}) end)
local before=s.rerolls; rejects(function() R.reroll(s,{2,2}) end); assert(s.rerolls==before)
for i=1,4 do R.reroll(s,{2}) end
rejects(function() R.reroll(s,{2}) end)
R.place(s,2,2); rejects(function() R.place(s,3,3) end)
rejects(function() R.reroll(s,{3}) end)
R.next_turn(s); assert(s.board[1]==c and s.rerolls==0 and s.placed==0)
for i=1,7 do R.next_turn(s) end
assert(R.result(s)=='loss'); rejects(function() R.place(s,1,3) end)
local winning={[1]='rosso',[2]='blu',[6]='blu',[7]='rosso',
    [3]='rosso',[4]='blu',[8]='verde',[9]='nero',[12]='blu',[13]='nero'}
assert(R.summary(winning)==3)
s.board=winning; assert(R.result(s)=='win')
for seed=1,100 do for d=1,4 do assert(R.roll(seed,2,d,1)==R.roll(seed,2,d,1)) end end
print('PASS motifs, joint feasibility, permanent pigment placement, budgets, atomic rejection, terminal states')
-- Production simulations assume independent uniform faces, not a color chooser.
local counts={}; for _,c in ipairs(R.colors) do counts[c]=0 end
local same,total=0,0
for seed=1,2000 do for t=1,8 do
    local previous
    for d=1,4 do
        local c=R.roll(seed,t,d,0); counts[c]=counts[c]+1
        if previous then total=total+1; if c==previous then same=same+1 end end
        previous=c
    end
end end
for _,n in pairs(counts) do assert(math.abs(n/64000-1/6)<0.01,'face imbalance') end
assert(math.abs(same/total-1/6)<0.01,'neighboring dice correlated')
local b={[7]='rosso',[12]='rosso'}
assert(R.status(b,R.motifs[3])==-1)
assert(R.feasible(b,20),'one sacrificed motif should not end game')
b[3]='blu'; b[4]='blu'; assert(not R.feasible(b,20))
R.motifs[1].palette={'rosso','blu'}
assert(R.status({[1]='verde'},R.motifs[1])==-1)
R.motifs[1].palette=nil
local min
for n=0,20 do if R.feasible({},n) then min=n; break end end
assert(min==10,'unexpected minimum placement budget')
print('PASS color frequency and pair diagnostic; minimum winning occupancy=10; recoverable and fatal sacrifices')
local A=require('experiments.intrecci.agents')
for _,kind in ipairs({'random','greedy','planner'}) do
    local game=R.new(19,{turns=8,rerolls=4})
    local previous={}
    while R.result(game)=='playing' do
        if game.placed==2 then R.next_turn(game) else A.act(game,kind,function() return 1 end) end
        for i,c in pairs(previous) do assert(game.board[i]==c,'agent altered permanent placement') end
        for i,c in pairs(game.board) do previous[i]=c end
        assert(game.rerolls>=0 and game.placed<=2)
    end
end
print('PASS all agents preserve permanent board and budgets')
