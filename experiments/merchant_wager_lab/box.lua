-- Public 20-character box for the Merchant's V3 counteroffers.
local M={}
M.symbols={
 {id='V10',label='V10',points=10,count=6},
 {id='V20',label='V20',points=20,count=5},
 {id='V30',label='V30',points=30,count=4},
 {id='V40',label='V40',points=40,count=2},
 {id='X',label='X',points=0,count=3},
}
local counts={6,5,4,2,3}
local values={10,20,30,40,0}
local function shuffled(cards,random)
 for i=#cards,2,-1 do
  local j=random(1,i)
  cards[i],cards[j]=cards[j],cards[i]
 end
 return cards
end
local function full_box()
 local cards={}
 for kind,symbol in ipairs(M.symbols) do
  for _=1,symbol.count do cards[#cards+1]={id=symbol.id,kind=kind,points=symbol.points} end
 end
 return cards
end
local function counts_of(cards)
 local result={0,0,0,0,0}
 for _,card in ipairs(cards) do result[card.kind]=result[card.kind]+1 end
 return result
end

function M.new(random)
 assert(type(random)=='function','box requires its seeded random stream')
 return {random=random,draw_pile=shuffled(full_box(),random),discard={},drawn={},reshuffles=0}
end

function M.draw(box)
 if #box.draw_pile==0 then
  assert(#box.discard==20,'empty type box must account for all 20 characters')
  box.draw_pile=shuffled(box.discard,box.random);box.discard={};box.reshuffles=box.reshuffles+1
 end
 local card=table.remove(box.draw_pile)
 box.discard[#box.discard+1]=card;box.drawn[#box.drawn+1]=card
 return card
end

function M.remaining(box) return counts_of(box.draw_pile) end
function M.discarded(box) return counts_of(box.discard) end
function M.total(box) return #box.draw_pile+#box.discard end

-- Exact probability of exceeding target before an X, using only the public
-- residual composition. If the current numeric-only stock is exhausted, model
-- its prescribed refill from discards once; that refill contains all 20 types.
function M.probability_to_exceed(box,target,current)
 local start=counts_of(box.draw_pile)
 local memo={}
 local function solve(c,total,can_refill)
  if total>target then return 1 end
  local remaining=0;for i=1,5 do remaining=remaining+c[i] end
  if remaining==0 then
   if can_refill then return solve(counts, total, false) end
   return 0
  end
  local key=table.concat(c,',')..':'..total..':'..tostring(can_refill)
  if memo[key]~=nil then return memo[key] end
  local p=0
  for i=1,5 do
   if c[i]>0 then
    local chance
    if i==5 then chance=0
    else
     local next_counts={c[1],c[2],c[3],c[4],c[5]}
     next_counts[i]=next_counts[i]-1
     chance=solve(next_counts,total+values[i],can_refill)
    end
    p=p+c[i]/remaining*chance
   end
  end
  memo[key]=p
  return p
 end
 return solve(start,current or 0,true)
end

function M.description()
 local out={}
 for _,symbol in ipairs(M.symbols) do
  out[#out+1]=('%s × %d%s'):format(symbol.label,symbol.count,
   symbol.points>0 and (' (+'..symbol.points..')') or ' (fallimento)')
 end
 return table.concat(out,'  ·  ')
end
return M
