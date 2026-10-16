local schema=require('src.data.commission_menu')
assert(#schema==1 and schema[1].id=='farkle-prototype')
assert(schema[1].implemented and not schema[1].folios)
-- No graphics needed to verify that menu cannot load/delete a chromatic save.
local f=assert(io.open('src/features/main_menu/module.lua'));local s=f:read('*a');f:close()
assert(not s:find('SaveState',1,true),'menu imports old persistence')
local c=assert(io.open('src/features/campaign_select/module.lua'));s=c:read('*a');c:close()
assert(not s:find('src.content.commissions',1,true),'frontend imports chromatic objectives')
print('PASS single Farkle option, no placeholders or chromatic persistence')
