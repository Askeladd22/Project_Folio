local M=require('experiments.contesi.model')
local A=require('experiments.contesi.agents')
for _,cfg in ipairs(M.configs) do
 local routes=M.solve(cfg); assert(#routes==2)
 assert(routes[1].omit==1 and routes[2].omit==2)
 assert(not M.compatible(routes[1].board,routes[2].board))
 for _,route in ipairs(routes) do
  local s=M.new(cfg,1); s.board=route.board; assert(M.winner(s)==route.omit)
  assert(route.count<=16)
 end
 local s=M.new(cfg,5); local obs=M.observe(s)
 assert(not obs.seed and not obs.attempt)
 local c=s.hand[1]; M.apply(s,{kind='place',d=1,i=20}); assert(s.board[20]==c)
 assert(not pcall(M.apply,s,{kind='place',d=1,i=19}))
 local budget=s.rerolls; assert(not pcall(M.apply,s,{kind='reroll',dice={2,2}})); assert(s.rerolls==budget)
 for _=1,4 do M.apply(s,{kind='reroll',dice={2}}) end
 assert(not pcall(M.apply,s,{kind='reroll',dice={2}}))
 M.apply(s,{kind='place',d=2,i=19})
 assert(not pcall(M.apply,s,{kind='place',d=3,i=18}))
 M.apply(s,{kind='pass'}); assert(s.board[20]==c and s.rerolls==0)
 for _=1,7 do M.apply(s,{kind='pass'}) end
 assert(s.turn==9 and not pcall(M.apply,s,{kind='place',d=1,i=1}))
 -- Same visible state, distinct hidden seeds: identical planner decision.
 local x=M.new(cfg,9); local y=M.new(cfg,99); y.hand=x.hand
 local function rng() return 2 end
 local a=A.choose(M.observe(x),'planner',rng); local b=A.choose(M.observe(y),'planner',rng)
 assert(a.kind==b.kind and a.i==b.i and a.d==b.d)
 print('PASS '..cfg.name..': two incompatible winning witnesses, budgets, persistence, hidden-seed isolation')
end
