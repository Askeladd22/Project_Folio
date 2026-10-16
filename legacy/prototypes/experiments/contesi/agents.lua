local M=require('experiments.contesi.model')
local A={}
local function actions(s)
 local out={}; local used={}
 for _,route in ipairs(M.live(s)) do for i,c in pairs(route.board) do if not s.board[i] then
  for d=1,4 do if s.hand[d]==c then
   local key=i..':'..d
   if not used[key] then out[#out+1]={kind='place',i=i,d=d}; used[key]=true end
  end end
 end end end
 table.sort(out,function(a,b) return a.i<b.i or (a.i==b.i and a.d<b.d) end)
 return out
end
local function immediate(s,a)
 local best=-1e9
 s.board[a.i]=s.hand[a.d]
 for _,route in ipairs(s.routes) do
  local _,n=M.deficits(s.board,route)
  if n then
   local complete=0
   for k,m in ipairs(s.config.motifs) do if k~=route.omit then
    local yes=true; for j,i in ipairs(m.cells) do if s.board[i]~=m.colors[j] then yes=false end end
    if yes then complete=complete+1 end
   end end
   best=math.max(best,route.count-n+complete*3)
  end
 end
 s.board[a.i]=nil; return best
end
local function fill(needs,hand,slots)
 local placed=0
 for _=1,slots do
  local d,best=nil,0
  for i=1,4 do local c=hand[i]; if c and needs[c]>best then d=i; best=needs[c] end end
  if not d then break end
  needs[hand[d]]=needs[hand[d]]-1; hand[d]=nil; placed=placed+1
 end
 return placed
end
local function utility(needs,reserve,turn,slots)
 local total,squares=0,0
 for _,c in ipairs(M.colors) do total=total+needs[c]; squares=squares+needs[c]^2 end
 if total==0 then return 100 end
 if total>math.max(0,8-turn)*2+slots then return -100-total end
 return -total-squares*0.12+reserve*0.35
end
-- Scenario expectation through the end of the NEXT turn. Route chosen before
-- samples are inspected; no clairvoyant max over routes inside future samples.
local function evaluate(s,a,samples)
 local best=-1e9
 for _,route in ipairs(s.routes) do
  local needs=M.deficits(s.board,route)
  if needs and (a.kind~='place' or route.board[a.i]==s.hand[a.d]) then
   local sum=0
   for _,sample in ipairs(samples) do
    local req={}; for _,c in ipairs(M.colors) do req[c]=needs[c] end
    local hand={}; for i=1,4 do hand[i]=s.hand[i] end
    local reserve,slots=s.rerolls,2-s.placed
    if a.kind=='place' then req[hand[a.d]]=req[hand[a.d]]-1; hand[a.d]=nil; slots=slots-1
    elseif a.kind=='reroll' then
     reserve=reserve-1; for _,d in ipairs(a.dice) do hand[d]=sample[d] end
    elseif a.kind=='pass' then slots=0 end
    local filled=fill(req,hand,slots); slots=slots-filled
    -- Causal rollout policy: reroll unhelpful dice only when a slot would be lost.
    if slots>0 and reserve>0 then
     reserve=reserve-1
     for d=1,4 do if hand[d] then hand[d]=sample[4+d] end end
     fill(req,hand,slots)
    end
    local turn=s.turn
    if turn<8 then
     turn=turn+1; local nextHand={sample[9],sample[10],sample[11],sample[12]}
     local used=fill(req,nextHand,2)
     if used<2 and reserve>0 then
      reserve=reserve-1
      for d=1,4 do if nextHand[d] then nextHand[d]=sample[12+d] end end
      fill(req,nextHand,2-used)
     end
    end
    sum=sum+utility(req,reserve,turn,0)
   end
   best=math.max(best,sum/#samples)
  end
 end
 return best
end
function A.choose(s,kind,rng)
 if s.placed==2 then return {kind='pass'} end
 local opts=actions(s)
 if kind=='random' and #opts>0 then return opts[rng(#opts)] end
 if kind=='greedy' and #opts>0 then
  local best,v=opts[1],-1e9
  for _,a in ipairs(opts) do local x=immediate(s,a); if x>v then best,v=a,x end end
  return best
 end
 if kind~='planner' then
  if s.rerolls>0 then local ds={}; for d=1,4 do if s.hand[d] then ds[#ds+1]=d end end
   if #ds>0 then return {kind='reroll',dice=ds} end
  end
  return {kind='pass'}
 end
 opts[#opts+1]={kind='pass'}
 if s.rerolls>0 then
  for mask=1,15 do
   local ds,ok={},true
   for d=1,4 do if math.floor(mask/2^(d-1))%2==1 then if not s.hand[d] then ok=false end; ds[#ds+1]=d end end
   if ok then opts[#opts+1]={kind='reroll',dice=ds} end
  end
 end
 local samples={}
 for j=1,12 do local t={}; for i=1,16 do t[i]=M.colors[rng(6)] end; samples[j]=t end
 local best,value=nil,-math.huge
 for _,a in ipairs(opts) do local v=evaluate(s,a,samples); if v>value then best,value=a,v end end
 return best
end
return A
