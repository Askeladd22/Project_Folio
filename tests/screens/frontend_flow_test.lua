-- Live New Game has one destination, with no orphaned campaign selector.
local cfg=require('src.data.frontend_schema')
local front=require('src.screens.frontend')
assert(cfg.campaign==nil,'unused campaign page schema still exported')
assert(front.campaign_select==nil and front.modules.campaign_select==nil,
 'unused campaign selector must not be registered')
local file=assert(io.open('src/data/frontend_schema.lua','rb'))
local schema=file:read('*a');file:close()
assert(schema:find('navigation_new_game = "scriptorium"',1,true))
file=assert(io.open('src/screens/frontend.lua','rb'))
local source=file:read('*a');file:close()
assert(source:find('mode = "duel", opponent_id = "opponent"',1,true),
 'New Game must start the single six-D6 duel')
assert(not source:find('Bundle.campaign_select',1,true))
assert(not source:find('src.content.commissions',1,true))
assert(not source:find('SaveState',1,true))
print('PASS single playable duel, no orphaned selector or chromatic persistence')
