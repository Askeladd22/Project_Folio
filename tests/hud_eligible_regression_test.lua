package.path="./?.lua;./?/init.lua;"..package.path
local R=require('src.gameplay.farkle.rules')
local H=require('src.features.farkle.hud_model')
-- Reference implementation from the pre-optimization hint: brute-force
-- 63 subsets of the six physical dice and compare against the new cached
-- R.options-based eligible() function.
local function baseline(s)
 local found={};local count=0
 if s.phase~='ready' then return found,0 end
 for mask=1,63 do
  local hand,ids={},{};local valid=true
  for i=1,6 do
   if math.floor(mask/2^(i-1))%2==1 then
    if s.used[i] or not s.hand[i] then valid=false;break end
    hand[#hand+1]=s.hand[i];ids[#ids+1]=i
   end
  end
  if valid and R.score(hand) then
   for _,i in ipairs(ids) do found[i]=true end
  end
 end
 for _ in pairs(found) do count=count+1 end
 return found,count
end
local s=R.new()
local seed=123456
local function rnd()
 seed=(seed*16807)%2147483647
 return seed
end
for trial=1,400 do
 s.phase=trial%8==0 and 'rolling' or 'ready'
 s.used={};s.hand={};s.selected={}
 for i=1,6 do
  s.hand[i]=rnd()%6+1
  if rnd()%5==0 then s.used[i]=true end
 end
 local old,n=baseline(s)
 local new,m=H.eligible(s)
 assert(n==m,'Eligible count changed on trial '..trial)
 for i=1,6 do assert(not not old[i]==(not not new[i]),
   'Eligible die changed at index '..i..' trial '..trial) end
end
print('PASS eligible hints unchanged over 400 deterministic Farkle states')
