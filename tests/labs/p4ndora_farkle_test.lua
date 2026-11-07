-- Hybrid lab regressions: six canonical Project Folio D6 vs P4ND0RA.
package.path = "experiments/p4ndora_1to1/?.lua;" .. package.path
local Engine = require("engine")
local Farkle = require("farkle_player")
local Rules = require("farkle_rules_snapshot")
local checks = 0
local function check(label,fn)
    fn()
    checks=checks+1
    print("PASS P4ND0RA Farkle: "..label)
end
local function new_scoring_seed(minimum)
    for seed=1,5000 do
        local g=Engine.new({farkle=true,seed=seed})
        local result=g:roll_farkle(1)
        if result=="ready" then
            local best
            for _,option in ipairs(Rules.options(g.farkle.states[1])) do
                if (not best or option.points>best.points) then
                    best=option
                end
            end
            if best and best.points>=minimum then return g,best end
        end
    end
    error("No scoring roll found")
end
local function select_and_bank(g,option,mode)
    for _,id in ipairs(option.ids) do g:toggle_farkle(1,id) end
    return g:bank_farkle(1,mode or "attack")
end
local function rig_bag(game,drawn)
    local remaining={}
    for key,count in pairs(Engine.TOKENS) do remaining[key]=count end
    game.bag,game.discard,game.drawn={},{},{}
    for _,key in ipairs(drawn) do
        assert(remaining[key]>0)
        remaining[key]=remaining[key]-1
        game.bag[#game.bag+1]=key
    end
    for _,key in ipairs(Engine.TOKEN_ORDER) do
        for _=1,remaining[key] do
            game.discard[#game.discard+1]=key
        end
    end
    game:assert_tokens()
end

check("uses the exact canonical production module API",function()
    assert(type(Rules.start)=="function")
    assert(type(Rules.options)=="function")
    assert(type(Rules.take)=="function")
    assert(type(Rules.bank_turn)=="function")
    assert(type(Rules.settle)=="function")
    assert(Farkle.Rules==Rules)
end)

check("six dice and stable seed produce identical faces",function()
    local a=Engine.new({farkle=true,seed=101})
    local b=Engine.new({farkle=true,seed=101})
    assert(a:roll_farkle(1)==b:roll_farkle(1))
    local aa=a.farkle.states[1]
    local bb=b.farkle.states[1]
    for id=1,6 do
        assert(aa.hand[id]==bb.hand[id],"seed mismatch")
        assert(type(aa.hand[id])=="number" and aa.hand[id]>=1 and aa.hand[id]<=6)
    end
    assert(not a.demo)
end)

check("boss cannot start until Farkle bank or bust",function()
    local g=Engine.new({farkle=true,seed=12})
    local ok=pcall(function()g:begin_boss_turn()end)
    assert(not ok)
end)

check("player must select valid scoring dice to bank",function()
    local g,best=new_scoring_seed(5)
    local ok=pcall(function()g:bank_farkle(1)end)
    assert(not ok)
    local out=select_and_bank(g,best)
    assert(out.points==best.points)
    assert(g.farkle:is_finished(1))
    assert(g.hp==g.stats.max_health-math.floor(best.points/5))
end)

check("Farkle bust is zero points and ends player's turn",function()
    local matched
    for seed=1,6000 do
        local g=Engine.new({farkle=true,seed=seed})
        if g:roll_farkle(1)=="farkle" then
            matched=g
            break
        end
    end
    assert(matched, "Expected at least one Farkle")
    assert(matched.farkle:result(1).points==0)
    assert(matched.farkle:is_finished(1))
    assert(matched.hp==matched.stats.max_health)
    matched:begin_boss_turn()
    assert(matched.phase=="boss")
end)

check("banked 20 points can neutralize next boss token",function()
    local g,best=new_scoring_seed(20)
    local out=select_and_bank(g,best,"blank")
    assert(out.points>=20)
    assert(g.blank_next==1)
    assert(g.hp==g.stats.max_health-math.floor((out.points-20)/5))
    g:begin_boss_turn()
    assert(g.drawn_actions[1]=="blank")
    assert(g.blank_next==0)
    g:assert_tokens()
end)

check("banked 30 points can discard one token from the bag",function()
    local g,best=new_scoring_seed(30)
    local n=#g.bag
    local out=select_and_bank(g,best,"discard")
    assert(out.points>=30)
    assert(#g.bag==n-1)
    assert(#g.discard==1)
    assert(g.hp==g.stats.max_health-math.floor((out.points-30)/5))
    g:assert_tokens()
end)

check("EMP locks two dice on NEXT opening roll, not the current one",function()
    local g,best=new_scoring_seed(5)
    select_and_bank(g,best)
    assert(not g.result)
    rig_bag(g,{"twoStar"})
    g:begin_boss_turn()
    g:advance()
    assert(g.farkle.penalties[1]==2)
    assert(g.farkle.states[1].penalty==0)
    g:advance()
    assert(g.phase=="players")
    local s=g.farkle.states[1]
    assert(s.penalty==2)
    assert(Rules.count_free(s)==4)
    g:roll_farkle(1)
    assert(#s.active==4)
    assert(s.used[1] and s.used[2])
end)

check("multiple EMPs cap the temporary loss at three dice",function()
    local f=Farkle.new(109,1)
    assert(f:apply_emp(1,2)==2)
    assert(f:apply_emp(1,2)==3)
    local g=Engine.new({farkle=true,seed=111})
    local _,best=new_scoring_seed(5)
    -- independent Farkle fixture; directly exercise new_turn after a bust
    f.finished[1]=true
    local s=f:new_turn(1)
    assert(s.penalty==3)
    assert(Rules.count_free(s)==3)
    assert(g.farkle.states[1].phase=="fresh")
end)

check("separate seeded streams: boss bag cannot affect dice rolls",function()
    local a=Engine.new({farkle=true,seed=909})
    local b=Engine.new({farkle=true,seed=909})
    a.random(20);a.random(20);a.random(20)
    a:roll_farkle(1)
    b:roll_farkle(1)
    for id=1,6 do
        assert(a.farkle.states[1].hand[id]==b.farkle.states[1].hand[id])
    end
end)

check("original manual boss rules remain an independent control",function()
    local g=Engine.new({seed=101})
    assert(not g.farkle)
    assert(g.players[1].hand==5)
    g:combat(1,5)
    assert(g.hp==75)
    g:begin_boss_turn()
end)

print("PASS P4ND0RA Farkle lab: "..checks.." cases")
