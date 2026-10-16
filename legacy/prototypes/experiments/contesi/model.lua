local M={colors={'rosso','blu','giallo','verde','marrone','nero'}}
local function motif(cells,colors) return {cells=cells,colors=colors} end
local r,b,y,g,m,n=unpack(M.colors)
M.configs={
 {name='bivio',motifs={motif({1,2,6,7},{r,b,b,r}),motif({2,3,7,8},{g,y,y,g}),motif({11,12,16,17},{y,g,m,n}),motif({14,15,19,20},{r,b,m,n})}},
 {name='ponti',motifs={motif({7,8,12,13},{r,b,b,r}),motif({8,9,13,14},{g,y,y,g}),motif({1,2,6,7},{m,n,b,r}),motif({4,5,9,10},{m,n,y,b})}},
 {name='asimmetrico',motifs={motif({1,2,6,7},{r,b,b,r}),motif({2,3,7,8},{m,n,n,m}),motif({11,12,16,17},{r,b,y,g}),motif({14,15,19,20},{r,b,b,r})}},
}
-- Exact constraint solver: enumerate all four triples and unify cell assignments.
-- Conflicting assignments prove UNSAT; a consistent union is a full witness.
function M.solve(config)
 local routes={}
 for omit=1,4 do
  local board,ok,count={},true,0
  for k,v in ipairs(config.motifs) do if k~=omit then
   for j,i in ipairs(v.cells) do
    local c=v.colors[j]
    if board[i] and board[i]~=c then ok=false end
    if not board[i] then count=count+1 end
    board[i]=c
   end
  end end
  if ok and count<=16 then routes[#routes+1]={omit=omit,board=board,count=count} end
 end
 return routes
end
function M.compatible(board,target)
 for i,c in pairs(target) do if board[i] and board[i]~=c then return false end end
 return true
end
function M.deficits(board,route)
 if not M.compatible(board,route.board) then return nil end
 local out={}; for _,c in ipairs(M.colors) do out[c]=0 end
 local total=0
 for i,c in pairs(route.board) do if not board[i] then out[c]=out[c]+1; total=total+1 end end
 return out,total
end
function M.live(s)
 local out={}; for _,route in ipairs(s.routes) do if M.compatible(s.board,route.board) then out[#out+1]=route end end
 return out
end
function M.winner(s)
 for _,route in ipairs(s.routes) do local _,n=M.deficits(s.board,route); if n==0 then return route.omit end end
end
function M.observe(s)
 local q={board={},hand={},turn=s.turn,placed=s.placed,rerolls=s.rerolls,routes=s.routes,config=s.config}
 for i,c in pairs(s.board) do q.board[i]=c end
 for i=1,4 do q.hand[i]=s.hand[i] end
 return q -- No actual seed, random tape, or future outcomes.
end
local Tape=require('experiments.intrecci.rules')
function M.next(s)
 assert(not M.winner(s) and s.turn<=8)
 s.turn=s.turn+1; s.placed=0; s.hand={}; s.attempt={}
 if s.turn<=8 then for d=1,4 do s.attempt[d]=0; s.hand[d]=Tape.roll(s.seed,s.turn,d,0) end end
end
function M.new(config,seed,budget)
 local s={config=config,routes=M.solve(config),board={},turn=0,placed=0,seed=seed,rerolls=budget or 4,spent=0}
 M.next(s); return s
end
function M.apply(s,a)
 assert(s.turn<=8 and not M.winner(s),'terminal')
 if a.kind=='pass' then M.next(s); return end
 assert(s.placed<2)
 if a.kind=='place' then
  assert(a.i>=1 and a.i<=20 and a.i==math.floor(a.i) and s.hand[a.d] and not s.board[a.i])
  s.board[a.i]=s.hand[a.d]; s.hand[a.d]=nil; s.placed=s.placed+1
 elseif a.kind=='reroll' then
  assert(s.rerolls>0 and #a.dice>0)
  local seen={}; for _,d in ipairs(a.dice) do assert(s.hand[d] and not seen[d]); seen[d]=true end
  s.rerolls=s.rerolls-1; s.spent=s.spent+1
  for _,d in ipairs(a.dice) do s.attempt[d]=s.attempt[d]+1; s.hand[d]=Tape.roll(s.seed,s.turn,d,s.attempt[d]) end
 else error('unknown action') end
end
return M
