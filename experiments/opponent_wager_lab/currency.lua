-- Venetian lira di piccoli is an ACCOUNTING unit (not a physical coin).
-- All wager amounts are nonnegative whole denari: 1 lira = 20 soldi = 240 denari.
local M={DENARI_PER_SOLDO=12,SOLDI_PER_LIRA=20,DENARI_PER_LIRA=240}
local function integer(n)
 return type(n)=='number' and n==math.floor(n) and n>=0 and n<9007199254740991
end
function M.is_valid(n) return integer(n) end
function M.from_units(lire,soldi,denari)
 lire,soldi,denari=lire or 0,soldi or 0,denari or 0
 assert(integer(lire) and integer(soldi) and integer(denari),'invalid monetary units')
 assert(soldi<20 and denari<12,'non-canonical lira/soldo/denaro amount')
 local n=lire*240+soldi*12+denari
 assert(integer(n),'monetary overflow')
 return n
end
function M.split(n)
 assert(integer(n),'money must be a nonnegative integer number of denari')
 local l=math.floor(n/240)
 local remainder=n-l*240
 local s=math.floor(remainder/12)
 return l,s,remainder-s*12
end
function M.format(n)
 local l,s,d=M.split(n)
 local out={}
 if l>0 then out[#out+1]=l..(l==1 and ' lira' or ' lire') end
 if s>0 then out[#out+1]=s..(s==1 and ' soldo' or ' soldi') end
 if d>0 or #out==0 then out[#out+1]=d..(d==1 and ' denaro' or ' denari') end
 return table.concat(out,' · ')
end
return M
