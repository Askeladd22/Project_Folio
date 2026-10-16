local R=require('experiments.intrecci.rules')
local A={}
local function greedy(b)
    local score=0
    for _,m in ipairs(R.motifs) do
        local s,n=R.status(b,m)
        score=score+(s<0 and -12 or n+ (s==1 and 16 or 0))
    end
    return score
end
local function strategic(b)
    local scores={}
    for k,m in ipairs(R.motifs) do
        local s,n=R.status(b,m)
        scores[k]=s<0 and -1000 or n*n+(s==1 and 24 or 0)
    end
    table.sort(scores,function(a,b) return a>b end)
    return scores[1]+scores[2]+scores[3]+math.max(0,scores[4])*0.1
end
local function candidates(s,score)
    local out={}; local seen={}
    for d=1,4 do local c=s.hand[d]
        if c and not seen[c] then
            seen[c]=true
            for i=1,20 do if not s.board[i] then
                s.board[i]=c
                out[#out+1]={d=d,i=i,v=score(s.board)}
                s.board[i]=nil
            end end
        end
    end
    table.sort(out,function(a,b) if a.v==b.v then return a.i<b.i or (a.i==b.i and a.d<b.d) end return a.v>b.v end)
    return out
end
local function best(s,kind)
    local score=kind=='planner' and strategic or greedy
    local list=candidates(s,score)
    if #list==0 then return nil,0 end
    local base=score(s.board)
    if kind~='planner' or s.placed==1 then return list[1],list[1].v-base end
    local winner,value=list[1],-math.huge
    -- Beam: top four immediate moves, then exhaust all second placements.
    for k=1,math.min(4,#list) do
        local a=list[k]; local color=s.hand[a.d]
        s.board[a.i]=color; s.hand[a.d]=nil
        local nexts=candidates(s,score)
        local v=(nexts[1] and nexts[1].v or a.v)+a.v*0.001
        s.board[a.i]=nil; s.hand[a.d]=color
        if v>value then winner,value=a,v end
    end
    return winner,winner.v-base
end
function A.act(s,kind,rng)
    if kind=='random' then
        -- Random among productive moves that do not destroy any live motif.
        -- This is stronger than uniformly wasting placements outside objectives.
        local _,live,progress=R.summary(s.board)
        local list={}
        for d=1,4 do if s.hand[d] then for i=1,20 do if not s.board[i] then
            s.board[i]=s.hand[d]
            local _,p,n=R.summary(s.board)
            if p>=live and n>progress then list[#list+1]={d=d,i=i} end
            s.board[i]=nil
        end end end end
        if #list>0 then local a=list[rng(#list)]; R.place(s,a.d,a.i); return end
    else
        local a,gain=best(s,kind)
        if a and gain>0 then R.place(s,a.d,a.i); return end
    end
    if s.rerolls>0 then
        local dice={}; for d=1,4 do if s.hand[d] then dice[#dice+1]=d end end
        if #dice>0 then R.reroll(s,dice); return end
    end
    R.next_turn(s)
end
return A
