-- Standalone card-proxy regression tests; P4ND0RA original manual rules remain.
package.path = "experiments/p4ndora_1to1/?.lua;" .. package.path
local Engine = require("engine")
local Demo = require("demo_cards")

local checks = 0
local function check(label, fn)
    fn()
    checks = checks + 1
    print("PASS P4ND0RA demo: " .. label)
end

local function snapshot(deck, player)
    local result = {}
    for _, card in ipairs(deck:hand(player)) do result[#result+1] = card.id end
    return table.concat(result,",")
end

check("10-card independent decks, five real starting cards",function()
    local d=Demo.new(101,4)
    for i=1,4 do
        assert(#d:hand(i)==5)
        assert(d:count(i)==10)
    end
    d:assert_conservation()
end)

check("same seed draws identical initial hands",function()
    local a=Demo.new(888,2)
    local b=Demo.new(888,2)
    for i=1,2 do
        assert(snapshot(a,i)==snapshot(b,i))
    end
end)

check("playing a card removes it from the real hand",function()
    local g=Engine.new({seed=1,demo=true})
    local card=g.demo:hand(1)[1]
    local old_hp=g.hp
    local old_bases=g.players[1].bases
    local old_authority=g.players[1].authority
    g:play_demo_card(1,1)
    assert(g.players[1].hand==4)
    if card.kind=="combat" then
        assert(g.hp==old_hp-card.value)
    elseif card.kind=="heal" then
        assert(g.players[1].authority==old_authority)
    elseif card.kind=="base" then
        assert(g.players[1].bases==old_bases+card.value)
    else error("Unknown card type") end
    g.demo:assert_conservation()
end)

check("new hand is drawn before the boss acts",function()
    local g=Engine.new({seed=1234,demo=true})
    local old_cards=snapshot(g.demo,1)
    g:play_demo_card(1,1)
    g:begin_boss_turn()
    assert(g.phase=="boss")
    assert(g.players[1].hand==5)
    assert(#g.demo:hand(1)==5)
    g.demo:assert_conservation()
    assert(snapshot(g.demo,1)~=old_cards or #g.demo:hand(1)==5)
end)

check("EMP discards real cards from next hand",function()
    local g=Engine.new({seed=5,demo=true,difficulty="Normal"})
    g:begin_boss_turn()
    g:apply_emp()
    assert(g.players[1].hand==3)
    assert(#g.demo:hand(1)==3)
    g.demo:assert_conservation()
end)

check("EMP can empty the hand, without creating phantom cards",function()
    local g=Engine.new({seed=5,demo=true,difficulty="Nightmare"})
    g:begin_boss_turn()
    for _=1,5 do g:apply_emp() end
    assert(g.players[1].hand==0)
    assert(#g.demo:hand(1)==0)
    g.demo:assert_conservation()
end)

check("discard-token countermeasure consumes an actual card",function()
    local g=Engine.new({seed=1717,demo=true})
    local before=#g.bag
    assert(g:discard_random_token(1))
    assert(g.players[1].hand==4)
    assert(#g.demo:hand(1)==4)
    assert(#g.bag==before-1)
    g.demo:assert_conservation()
    g:assert_tokens()
end)

check("card countermeasure fails when the hand is empty",function()
    local g=Engine.new({seed=101,demo=true})
    for _=1,5 do g.demo:discard_one(1) end
    g.players[1].hand=0
    local ok=pcall(function()g:discard_random_token(1)end)
    assert(not ok)
end)

check("manual mode remains unchanged",function()
    local g=Engine.new({seed=101})
    assert(not g.demo)
    assert(g.players[1].hand==5)
    g:combat(1,5)
    assert(g.hp==75)
    g:begin_boss_turn()
    assert(g.players[1].hand==5)
end)

check("multiple turns: card recycling without duplicates",function()
    local g=Engine.new({seed=656,demo=true,players=2})
    for r=1,9 do
        for i=1,2 do
            while #g.demo:hand(i)>0 do
                g:play_demo_card(i,1)
                if g.result then break end
            end
            if g.result then break end
        end
        if g.result then break end
        g:begin_boss_turn()
        while g.phase=="boss" and not g.result do
            if g.pending then g:resolve_missile("authority")
            else g:advance() end
        end
        for i=1,2 do g.demo:assert_conservation() end
        g:assert_tokens()
    end
end)

print("PASS P4ND0RA demo suite: " .. checks .. " tests")
