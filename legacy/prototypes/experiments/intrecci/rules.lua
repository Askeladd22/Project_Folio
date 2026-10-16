-- Standalone experiment: no LOVE, production modules or player saves.
local M = {}
M.colors = {'rosso','blu','giallo','verde','marrone','nero'}
M.motifs = {
    {kind='checker',cells={1,2,6,7}},
    {kind='quartet',cells={3,4,8,9}},
    {kind='quartet',cells={7,8,12,13}},
    {kind='checker',cells={14,15,19,20}},
}
function M.status(board,m)
    local n=0
    for _,i in ipairs(m.cells) do if board[i] then
        n=n+1
        if m.palette and board[i]~=m.palette[1] and board[i]~=m.palette[2] then return -1,n end
    end end
    for a=1,4 do for b=a+1,4 do
        local x,y=board[m.cells[a]],board[m.cells[b]]
        if x and y then
            local equal=m.kind=='checker' and (a+b==5)
            if (equal and x~=y) or (not equal and x==y) then return -1,n end
        end
    end end
    return n==4 and 1 or 0,n
end
function M.summary(board)
    local done,possible,progress=0,0,0
    for _,m in ipairs(M.motifs) do
        local s,n=M.status(board,m)
        if s>=0 then possible=possible+1; progress=progress+n end
        if s==1 then done=done+1 end
    end
    return done,possible,progress
end
-- Joint feasibility, not just four independent local checks. Enumerate every
-- triple of objectives and solve their equality/inequality constraints.
function M.feasible(board,remaining)
    for omit=1,4 do
        local wanted,needed={},0
        for k,m in ipairs(M.motifs) do if k~=omit then
            for _,i in ipairs(m.cells) do wanted[i]=true end
        end end
        local cells={}
        for i=1,20 do if wanted[i] and not board[i] then cells[#cells+1]=i; needed=needed+1 end end
        if needed<=remaining then
            local function valid()
                for k,m in ipairs(M.motifs) do if k~=omit and M.status(board,m)<0 then return false end end
                return true
            end
            local function search(p)
                if not valid() then return false end
                if p>#cells then return true end
                local i=cells[p]
                for _,c in ipairs(M.colors) do
                    board[i]=c
                    if search(p+1) then board[i]=nil; return true end
                end
                board[i]=nil
                return false
            end
            if search(1) then return true end
        end
    end
    return false
end
-- Counter-addressed random tape: changing one agent's decisions never shifts
-- another die/turn. Color identifiers are strings; face numbers are transport only.
local tape_seed,tape,state
function M.roll(seed,turn,die,attempt)
    if tape_seed~=seed then
        tape_seed=seed; tape={}; state=seed%2147483646+1
        for _=1,32 do state=(state*48271)%2147483647 end
    end
    assert(attempt<16,'random tape attempt capacity exceeded')
    local index=((turn-1)*4+die-1)*16+attempt+1
    for i=#tape+1,index do
        state=(state*48271)%2147483647
        tape[i]=M.colors[math.floor(state/2147483647*6)+1]
    end
    return tape[index]
end
function M.new(seed,config)
    local s={board={},seed=seed,turn=0,placed=0,rerolls=config.rerolls or 4,
        turns=config.turns or 8,hand={},attempt={},used_rerolls=0}
    M.next_turn(s); return s
end
function M.result(s)
    if M.summary(s.board)>=3 then return 'win' end
    if s.turn>s.turns then return 'loss' end
    return 'playing'
end
function M.next_turn(s)
    s.turn=s.turn+1; s.placed=0; s.hand={}; s.attempt={}
    if s.turn<=s.turns then for d=1,4 do s.attempt[d]=0; s.hand[d]=M.roll(s.seed,s.turn,d,0) end end
end
function M.place(s,d,i)
    assert(M.result(s)=='playing' and s.placed<2,'turn ended')
    assert(s.hand[d] and i>=1 and i<=20 and i==math.floor(i) and not s.board[i],'illegal placement')
    s.board[i]=s.hand[d]; s.hand[d]=nil; s.placed=s.placed+1
end
function M.reroll(s,dice)
    assert(M.result(s)=='playing' and s.placed<2 and s.rerolls>0 and #dice>0,'illegal reroll')
    local seen={}
    for _,d in ipairs(dice) do assert(s.hand[d] and not seen[d],'unavailable die'); seen[d]=true end
    s.rerolls=s.rerolls-1; s.used_rerolls=s.used_rerolls+1
    for _,d in ipairs(dice) do s.attempt[d]=s.attempt[d]+1; s.hand[d]=M.roll(s.seed,s.turn,d,s.attempt[d]) end
end
return M
