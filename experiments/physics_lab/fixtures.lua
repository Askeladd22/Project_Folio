-- Deterministic, game-scale initial conditions shared by both solvers.
-- Deliberately independent of gameplay/math.random and face-value RNG.
local F={count=6,size=1.0,dt=.01,default_steps=450}
local function rng(seed)
 local state=math.floor(seed)%2147483647
 if state==0 then state=1 end
 return function()
  state=(state*48271)%2147483647
  return (state-1)/2147483646
 end
end
function F.generate(seed)
 local random=rng(seed)
 local rows={}
 for i=1,F.count do
  local col=(i-1)%3
  local row=math.floor((i-1)/3)
  rows[i]={
   position={-2.2+col*2.2+(random()-.5)*.4,
             (row-.5)*1.7+(random()-.5)*.35,
             2.6+i*.47},
   velocity={(random()-.5)*6,(random()-.5)*4,random()*1.4},
   angular={(random()-.5)*9,(random()-.5)*9,(random()-.5)*8},
  }
 end
 return rows
end
return F
