-- Pure Lua sign bag: category is announced; exact strength is hidden until
-- resolution. No reinsert until the bag is empty, no access to physical dice.
local M={}
local Bag={}
Bag.__index=Bag

local function copy(s)
 return {id=s.id,category=s.category,strength=s.strength}
end
function M.new(entries,random)
 assert(type(entries)=='table' and #entries>0,'nonempty sign fixture needed')
 assert(type(random)=='function','independent random(lo,hi) needed')
 local seen,original={},{}
 for i,item in ipairs(entries) do
  assert(type(item)=='table' and type(item.id)=='string' and item.id~='',
   'sign '..i..' needs id')
  assert(not seen[item.id],'duplicate sign id '..item.id)
  assert(type(item.category)=='string' and item.category~='',
   'sign category required')
  assert(type(item.strength)=='number' and item.strength>0
   and item.strength%1==0,'sign strength must be positive integer')
  seen[item.id]=true;original[i]=copy(item)
 end
 local self=setmetatable({
  original=original,pool={},discard={},active=nil,
  random=random,cycles=0,draws=0,
 },Bag)
 self:refill(original)
 return self
end

function Bag:refill(from)
 assert(not self.active,'cannot refill while a sign is active')
 assert(#self.pool==0,'cannot refill a bag with available signs')
 assert(#from>0,'cannot refill from empty discard')
 for i,item in ipairs(from) do self.pool[i]=copy(item) end
 for i=#self.pool,2,-1 do
  local j=self.random(1,i)
  assert(type(j)=='number' and j%1==0 and j>=1 and j<=i,
   'invalid unbiased-bag RNG return')
  self.pool[i],self.pool[j]=self.pool[j],self.pool[i]
 end
end

function Bag:announce()
 assert(not self.active,'resolve current sign before another announcement')
 if #self.pool==0 then
  self:refill(self.discard)
  self.discard={}
  self.cycles=self.cycles+1
 end
 self.active=table.remove(self.pool)
 self.draws=self.draws+1
 -- Information boundary: publicly reveal category, never strength/id.
 return {category=self.active.category,remaining=#self.pool,
  recycle_count=self.cycles}
end
function Bag:resolve()
 assert(self.active,'cannot resolve without announcing a sign')
 local result=copy(self.active)
 self.discard[#self.discard+1]=copy(self.active)
 self.active=nil
 return result
end
function Bag:count()
 return #self.pool,#self.discard,self.active and 1 or 0
end
return M
