local schema=require('src.data.frontend_schema').campaign.campaigns
assert(#schema==2 and schema[1].id=='farkle-prototype' and schema[1].mode=='build')
assert(schema[2].id=='merchant-duel' and schema[2].implemented and schema[2].mode=='duel')
assert(schema[1].implemented and not schema[1].folios)
-- No graphics needed to verify that menu cannot load/delete a chromatic save.
local f=assert(io.open('src/screens/frontend.lua'));local s=f:read('*a');f:close()
assert(not s:find('SaveState',1,true),'menu imports old persistence')
local c=assert(io.open('src/screens/frontend.lua'));s=c:read('*a');c:close()
assert(not s:find('src.content.commissions',1,true),'frontend imports chromatic objectives')
print('PASS solo and Merchant duel options, no placeholders or chromatic persistence')
