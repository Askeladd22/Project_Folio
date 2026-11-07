-- Lua 5.4 / LuaJIT headless regression tests for the original P4ND0RA lab.
package.path = "experiments/p4ndora_1to1/?.lua;" .. package.path
local Engine = require("engine")

local function equal(actual, expected, label)
    assert(actual == expected,
           (label or "value") .. ": expected " .. tostring(expected) ..
           ", got " .. tostring(actual))
end

local function rig_bag(game, wanted)
    local remain = {}
    for k,v in pairs(Engine.TOKENS) do remain[k] = v end
    game.bag,game.discard,game.drawn = {},{},{}
    for _,token in ipairs(wanted) do
        assert(remain[token] and remain[token] > 0)
        remain[token] = remain[token]-1
        game.bag[#game.bag+1] = token
    end
    for _,token in ipairs(Engine.TOKEN_ORDER) do
        for _=1,remain[token] do
            game.discard[#game.discard+1] = token
        end
    end
    game:assert_tokens()
end

local total=0
local function check(name, fn)
    fn()
    total=total+1
    print("PASS P4ND0RA " .. name)
end

check("20 tokens with original proportions",function()
    local g=Engine.new()
    equal(#g.bag,20)
    equal(#g.discard,0)
    g:assert_tokens()
    local a=g:count_tokens()
    for k,v in pairs(Engine.TOKENS) do equal(a[k],v,k) end
end)

check("difficulty settings from original Lua",function()
    local e=Engine.stats("Easy",1)
    equal(e.max_health,50);equal(e.draw,1)
    equal(e.attack,1);equal(e.repair,1);equal(e.shield,1)
    local n=Engine.stats("Normal",4)
    equal(n.max_health,80);equal(n.draw,3)
    equal(n.attack,4);equal(n.repair,3);equal(n.shield,4)
    local h=Engine.stats("Hard",1)
    equal(h.max_health,100);equal(h.draw,1);equal(h.repair,3)
    local x=Engine.stats("Nightmare",4)
    equal(x.attack,7);equal(x.repair,7);equal(x.shield,8)
    equal(x.draw,5);equal(x.missile,6);equal(x.cqc,2)
    assert(x.faction_must)
end)

check("seeded token sequence reproducibility",function()
    local a=Engine.new({seed=2026,players=2})
    local b=Engine.new({seed=2026,players=2})
    for i=1,#a.bag do equal(a.bag[i],b.bag[i]) end
    a:begin_boss_turn(); b:begin_boss_turn()
    for i=1,#a.drawn do equal(a.drawn[i],b.drawn[i]) end
end)

check("attack targets living player and uses Authority",function()
    local g=Engine.new({seed=7,difficulty="Normal"})
    rig_bag(g,{"attack"})
    g:begin_boss_turn()
    equal(g.drawn_actions[1],"attack")
    g:advance()
    equal(g.players[1].authority,49)
    g:advance()
    equal(g.phase,"players")
    g:assert_tokens()
end)

check("next boss token is neutralized by sacrificing a base",function()
    local g=Engine.new()
    rig_bag(g,{"attack"})
    g.players[1].bases=1
    assert(g:blank_token(1))
    equal(g.players[1].bases,0)
    g:begin_boss_turn()
    equal(g.drawn_actions[1],"blank")
    g:advance()
    equal(g.players[1].authority,50)
    equal(g.blank_next,0)
end)

check("discard token requires card and preserves 20 tokens",function()
    local g=Engine.new()
    equal(g.players[1].hand,5)
    assert(g:discard_random_token(1))
    equal(g.players[1].hand,4)
    equal(#g.bag,19)
    equal(#g.discard,1)
    g:assert_tokens()
end)

check("missile lets player destroy base",function()
    local g=Engine.new()
    rig_bag(g,{"oneStar"})
    g.players[1].bases=2
    g:begin_boss_turn()
    equal(g:advance(),"oneStar")
    assert(g.pending and g.pending.type=="missile")
    g:resolve_missile("base")
    equal(g.players[1].bases,1)
    equal(g.players[1].authority,50)
    assert(not g.pending)
    g:advance()
end)

check("missile Authority option",function()
    local g=Engine.new({difficulty="Hard"})
    rig_bag(g,{"oneStar"})
    g:begin_boss_turn()
    g:advance()
    g:resolve_missile("authority")
    equal(g.players[1].authority,45)
end)

check("EMP discards cards and Nightmare faction if possible",function()
    local g=Engine.new({difficulty="Nightmare"})
    rig_bag(g,{"twoStar"})
    g.players[1].hand=4
    g.players[1].faction=2
    g:begin_boss_turn()
    g:advance()
    equal(g.players[1].hand,2)
    equal(g.players[1].faction,1)
end)

check("active CQC halves incoming combat with floor",function()
    local g=Engine.new({difficulty="Normal"})
    rig_bag(g,{"threeStar"})
    g:begin_boss_turn()
    g:advance()
    equal(g.active_defense_turns,1)
    g:advance()
    equal(g.phase,"players")
    equal(g:combat(1,7),3)
    equal(g.hp,77)
end)

check("fourth Special launches nuclear strike",function()
    local g=Engine.new()
    rig_bag(g,{"special"})
    g.special_counter=3
    g.players[1].bases=4
    g:begin_boss_turn()
    g:advance()
    equal(g.special_counter,0)
    equal(g.players[1].bases,0)
    equal(g.players[1].authority,30)
end)

check("repairs capped at max HP; shield absorbs damage",function()
    local g=Engine.new()
    g.hp=79
    rig_bag(g,{"repairs","defense"})
    g:begin_boss_turn()
    while g.queue[1].token~="end" do g:advance() end
    equal(g.hp,80)
    equal(g.shield,2)
    g:advance()
    equal(g:combat(1,3),1)
    equal(g.hp,79)
    equal(g.shield,0)
end)

check("multiple upgrade tokens trigger one upgrade",function()
    local g=Engine.new()
    rig_bag(g,{"upgrade","upgrade"})
    g:begin_boss_turn()
    equal(#g.queue,2)
    g:advance()
    equal(g.upgrades,1)
    equal(g.stats.attack,2)
    equal(g.stats.repair,3)
    equal(g.stats.shield,3)
end)

check("bag exhaustion grows draw and refills after boss",function()
    local g=Engine.new()
    rig_bag(g,{"defense"})
    g:begin_boss_turn()
    equal(g.draw_power,3)
    assert(g.exhausted_this_turn)
    g:advance()
    g:advance()
    equal(#g.bag,20)
    equal(#g.discard,0)
    equal(g.bag_cycles,1)
    g:assert_tokens()
end)

check("Authority zero eliminates permanently",function()
    local g=Engine.new()
    g:lose_authority(1,50)
    equal(g.result,"boss_wins")
    equal(g.players[1].alive,false)
end)

check("boss HP zero wins and shields zero at next boss turn",function()
    local g=Engine.new()
    g:combat(1,80)
    equal(g.result,"players_win")
    local next_g=Engine.new()
    next_g.shield=10
    next_g:begin_boss_turn()
    equal(next_g.shield,0)
end)

print("PASS P4ND0RA LAB: " .. total .. " headless regression scenarios")
