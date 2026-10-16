-- Pure Lua. Physical IDs are preserved; no renderer, randomness or physics access.
local S={points={single={[1]=10,[5]=5},kind={
 [3]={75,20,30,40,50,60},[4]={110,120,130,140,150,160},
 [5]={320,340,360,380,400,420},[6]={625,650,675,700,725,750}},
 small=100,straight=200,pairs=150,full=200,triples=250}}
local function bit(mask,i) return math.floor(mask/2^(i-1))%2==1 end
local function valid(values,ids)
 if #values<1 or #values>6 or #values~=#ids then return false end
 local seen={}
 for i,v in ipairs(values) do
  local id=ids[i]
  if type(v)~='number' or v%1~=0 or v<1 or v>6 or type(id)~='number' or id%1~=0 or id<1 or id>6 or seen[id] then return false end
  seen[id]=true
 end
 return true
end
local names={[3]='Three of a kind',[4]='Four of a kind',[5]='Five of a kind',[6]='Six of a kind'}
local function atom(values,ids,mask)
 local c={0,0,0,0,0,0};local chosen={};local n=0
 for i,v in ipairs(values) do if bit(mask,i) then c[v]=c[v]+1;n=n+1;chosen[#chosen+1]=ids[i] end end
 local points,label,group
 if n==1 then for v=1,6 do if c[v]==1 and S.points.single[v] then points=S.points.single[v];label='Single '..v end end end
 for v=1,6 do if n>=3 and c[v]==n then points=S.points.kind[n][v];label=names[n]..' of '..v;group=true end end
 local pairs,triples,quad,distinct=0,0,0,0
 for v=1,6 do if c[v]>0 then distinct=distinct+1 end;if c[v]==2 then pairs=pairs+1 end;if c[v]==3 then triples=triples+1 end;if c[v]==4 then quad=quad+1 end end
 if n==5 and distinct==5 and (c[1]==0 or c[6]==0) then points=S.points.small;label='Small straight' end
 if n==6 then
  if distinct==6 then points=S.points.straight;label='Large straight'
  elseif pairs==3 then points=S.points.pairs;label='Three pairs'
  elseif quad==1 and pairs==1 then points=S.points.full;label='Full house (4+2)';group=true
  elseif triples==2 then points=S.points.triples;label='Two triplets';group=true end
 end
 if points then return {points=points,label=label,group=group or false,ids=chosen} end
end
local cache,cacheSize={},0
function S.options(values,ids)
 ids=ids or {};if #ids==0 then for i=1,#values do ids[i]=i end end
 if not valid(values,ids) then return {} end
 local key=table.concat(ids,',')..':'..table.concat(values,',')
 if cache[key] then return cache[key] end
 local atoms,memo={}, {[0]={points=0,group=false,groups={}}}
 for mask=1,2^#values-1 do atoms[mask]=atom(values,ids,mask) end
 local function solve(mask)
  if memo[mask]~=nil then return memo[mask] end
  local first;for i=1,#values do if bit(mask,i) then first=i;break end end
  local best=false
  for sub,a in pairs(atoms) do
   if bit(sub,first) then
    local contained=true;for i=1,#values do if bit(sub,i) and not bit(mask,i) then contained=false;break end end
    if contained then
     local rest=solve(mask-sub)
     if rest then
      local points=a.points+rest.points;local group=a.group or rest.group
      if not best or points>best.points or points==best.points and group and not best.group then
       local groups={a};for _,g in ipairs(rest.groups) do groups[#groups+1]=g end
       best={points=points,group=group,groups=groups}
      end
     end
    end
   end
  end
  memo[mask]=best;return best
 end
 local result={}
 for mask=1,2^#values-1 do
  local solved=solve(mask)
  if solved then
   local chosen,physicalMask={},0
   for i,id in ipairs(ids) do if bit(mask,i) then chosen[#chosen+1]=id;physicalMask=physicalMask+2^(id-1) end end
   result[#result+1]={ids=chosen,mask=physicalMask,points=solved.points,group=solved.group,groups=solved.groups,remaining=#ids-#chosen}
  end
 end
 -- Stable ordering by number of dice, then identity; never auto-select the maximum.
 table.sort(result,function(a,b) if #a.ids~=#b.ids then return #a.ids<#b.ids end;return a.mask<b.mask end)
 if cacheSize>=256 then cache={};cacheSize=0 end
 cache[key]=result;cacheSize=cacheSize+1;return result
end
local scores={}
function S.score(values)
 if #values<1 or #values>6 then return nil end
 local copy={};for i,v in ipairs(values) do if type(v)~='number' or v%1~=0 or v<1 or v>6 then return nil end;copy[i]=v end
 table.sort(copy);local key=table.concat(copy,',')
 if scores[key]~=nil then if scores[key] then return scores[key].points,scores[key].group end;return nil end
 local options=S.options(copy);local full=2^#copy-1
 for _,o in ipairs(options) do if o.mask==full then scores[key]=o;return o.points,o.group end end
 scores[key]=false;return nil
end
return S
