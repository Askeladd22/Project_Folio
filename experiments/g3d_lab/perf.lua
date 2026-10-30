-- Moving-window CPU submission statistics; not GPU timings.
local P={}
P.__index=P
function P.new(limit)
 return setmetatable({limit=limit or 120,samples={},count=0,total=0},P)
end
function P:push(ms)
 assert(ms>=0 and ms<math.huge and ms==ms,'finite nonnegative ms')
 local idx=(self.count%self.limit)+1
 if self.count>=self.limit then self.total=self.total-self.samples[idx] end
 self.samples[idx]=ms
 self.total=self.total+ms
 self.count=self.count+1
end
function P:average()
 local n=math.min(self.count,self.limit)
 if n==0 then return nil end
 return self.total/n
end
function P:reset()
 self.samples={};self.count=0;self.total=0
end
return P
