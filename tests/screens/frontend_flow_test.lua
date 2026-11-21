local schema=require('src.data.frontend_schema').campaign.campaigns
assert(#schema==1 and schema[1].id=='opponent-duel'
 and schema[1].mode=='duel' and schema[1].implemented,
 'only the Opponent Duel may appear in the playable menu')
local h=assert(io.open('src/data/frontend_schema.lua','rb'))
local cfg=h:read('*a');h:close()
assert(cfg:find('navigation_new_game = "scriptorium"',1,true))
local f=assert(io.open('src/screens/frontend.lua','rb'))
local code=f:read('*a');f:close()
assert(code:find('mode = "duel", opponent_id = "opponent"',1,true),
 'New Game must launch the duel directly')
assert(not code:find('src.content.commissions',1,true))
assert(not code:find('SaveState',1,true),'menu must not load old persistence')
print('PASS one playable Opponent Duel: direct New Game and no legacy campaign selector')
