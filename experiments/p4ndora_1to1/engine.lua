-- P4ND0RA boss actions follow the original TTS script. The optional Farkle
-- bridge is explicitly an experimental adaptation, not Star Realms 1:1.
-- TTS object spawning/animation and the Star Realms card engine are intentionally
-- outside this module. See README for the exact abstraction boundaries.
local M = {}
local Game = {}
Game.__index = Game

M.TOKENS = {
    attack = 6, defense = 4, repairs = 2, oneStar = 3,
    twoStar = 2, threeStar = 1, special = 1, upgrade = 1,
}
M.TOKEN_ORDER = {"attack", "defense", "repairs", "oneStar",
                 "twoStar", "threeStar", "special", "upgrade"}
M.COLORS = {"Red", "Blue", "Green", "Yellow"}
M.TOKEN_TOTAL = 20

local function rng(seed)
    local state = (math.floor(tonumber(seed) or 101) % 2147483646) + 1
    return function(limit)
        assert(limit and limit > 0)
        state = (state * 16807) % 2147483647
        return 1 + state % limit
    end
end

local function shuffle(items, random)
    for i = #items, 2, -1 do
        local j = random(i)
        items[i], items[j] = items[j], items[i]
    end
end

function M.stats(difficulty, players)
    assert(players >= 1 and players <= 4, "P4ND0RA supports 1-4 players")
    if difficulty == "Easy" then
        return {
            max_health = 50, attack = players > 3 and 2 or 1,
            repair = players > 2 and 2 or 1,
            shield = players > 3 and 2 or 1, draw = math.max(1, players - 1),
            missile = 3, emp = 1, faction_must = false, cqc = 1,
        }
    elseif difficulty == "Normal" then
        return {
            max_health = 80, attack = players > 1 and players or 1,
            repair = players > 2 and 3 or 2,
            shield = players > 2 and players or 2,
            draw = players == 4 and 3 or math.max(2, players),
            missile = 4, emp = 2, faction_must = false, cqc = 1,
        }
    elseif difficulty == "Hard" then
        return {
            max_health = 100, attack = players + 1,
            repair = players == 1 and 3 or players + 1,
            shield = players + 1, draw = players,
            missile = 5, emp = 2, faction_must = false, cqc = 1,
        }
    elseif difficulty == "Nightmare" then
        return {
            max_health = 100,
            attack = players + (players > 2 and 3 or 2),
            repair = players + (players > 2 and 3 or 2),
            shield = players > 2 and players * 2 or players + 2,
            draw = players + 1,
            missile = 6, emp = 2, faction_must = true, cqc = 2,
        }
    end
    error("Unknown difficulty: " .. tostring(difficulty))
end

function Game:note(message)
    self.events[#self.events + 1] = message
    if #self.events > 180 then table.remove(self.events, 1) end
    self.last_event = message
end

function M.new(options)
    options = options or {}
    local count = options.players or 1
    local difficulty = options.difficulty or "Normal"
    local stats = M.stats(difficulty, count)
    local farkle = options.farkle and require("farkle_player").new(options.seed or 101, count) or nil
    local self = setmetatable({
        seed = options.seed or 101,
        random = rng(options.seed or 101),
        difficulty = difficulty,
        player_count = count,
        stats = stats,
        hp = stats.max_health, shield = 0, active_defense_turns = 0,
        special_counter = 0, draw_power = stats.draw,
        bag = {}, discard = {}, drawn = {}, queue = {},
        phase = "players", phase_index = 0, round = 1,
        blank_next = 0, pending = nil, result = nil,
        events = {}, last_event = "",
        bag_cycles = 0, upgrades = 0, exhausted_this_turn = false,
        players = {}, drawn_actions = {}, last_actions = {},
        max_authority = 50, limit_authority = true, farkle = farkle,
    }, Game)
    for i = 1, count do
        self.players[i] = {
            color = M.COLORS[i], authority = 50,
            hand = farkle and 0 or 5, faction = 0,
            bases = 0, alive = true,
        }
    end
    for _, name in ipairs(M.TOKEN_ORDER) do
        for _ = 1, M.TOKENS[name] do
            self.bag[#self.bag + 1] = name
        end
    end
    shuffle(self.bag, self.random)
    self:note("Players act first. Then P4ND0RA draws its action tokens.")
    return self
end

function Game:count_tokens()
    local count = {}
    for _, token in ipairs(M.TOKEN_ORDER) do count[token] = 0 end
    for _, pile in ipairs({self.bag, self.discard, self.drawn}) do
        for _, token in ipairs(pile) do count[token] = count[token] + 1 end
    end
    return count
end

function Game:assert_tokens()
    local actual, count = self:count_tokens(), 0
    for key, expected in pairs(M.TOKENS) do
        assert(actual[key] == expected, "Token conservation failure: " .. key)
        count = count + actual[key]
    end
    assert(count == M.TOKEN_TOTAL)
end

function Game:is_players_turn()
    return self.phase == "players" and not self.result
end

local function active_players(self)
    local living = {}
    for i, p in ipairs(self.players) do
        if p.alive then living[#living + 1] = i end
    end
    return living
end

function Game:check_end()
    if self.hp <= 0 then
        self.hp = 0
        self.result = "players_win"
        self.phase = "finished"
        self:note("P4ND0RA destroyed: the players win.")
    elseif #active_players(self) == 0 then
        self.result = "boss_wins"
        self.phase = "finished"
        self:note("All players eliminated: P4ND0RA wins.")
    end
end

function Game:lose_authority(index, amount)
    local p = assert(self.players[index], "player not found")
    if not p.alive then return end
    p.authority = math.max(0, p.authority - math.max(0, amount))
    if p.authority == 0 then
        p.alive = false
        self:note(p.color .. " eliminated (zero Authority, no resurrection).")
    end
    self:check_end()
end

function Game:combat(index, amount)
    assert(self:is_players_turn(), "Combat is available during the players' phase")
    local p = assert(self.players[index], "player not found")
    assert(p.alive, "Eliminated player cannot attack")
    assert(type(amount) == "number" and amount >= 0 and amount == math.floor(amount))
    local dealt = self.active_defense_turns > 0 and math.floor(amount / 2) or amount
    local absorbed = math.min(self.shield, dealt)
    self.shield = self.shield - absorbed
    self.hp = math.max(0, self.hp - (dealt - absorbed))
    self:note(p.color .. " deals " .. dealt .. " combat (" .. absorbed .. " shielded).")
    self:check_end()
    return dealt - absorbed
end

function Game:heal(index, amount)
    assert(self:is_players_turn())
    local p = assert(self.players[index], "player not found")
    assert(p.alive, "Players at 0 Authority cannot be resurrected")
    assert(type(amount) == "number" and amount >= 0 and amount == math.floor(amount))
    p.authority = self.limit_authority
        and math.min(self.max_authority, p.authority + amount)
        or p.authority + amount
    self:note(p.color .. " Authority: " .. p.authority)
end

-- Star Realms cards are tracked as manually entered resources. The player
-- supplies combat, healing, cards and bases according to their real play.
function Game:adjust_resource(index, resource, amount)
    assert(self:is_players_turn())
    assert(resource == "hand" or resource == "bases" or resource == "faction")
    local p = assert(self.players[index], "player not found")
    assert(p.alive)
    local new_value = p[resource] + amount
    assert(new_value >= 0, "Resource cannot become negative")
    p[resource] = new_value
    if resource == "hand" and p.faction > p.hand then p.faction = p.hand end
    if resource == "faction" then assert(p.faction <= p.hand, "Faction cards exceed hand") end
    self:note(p.color .. " " .. resource .. " = " .. new_value)
end

-- The Farkle player uses the shipped six-D6 scoring/selection rules.
-- Bridges are clearly marked experimental: 5 banked points = 1 Combat.
function Game:roll_farkle(index)
    assert(self.farkle and self:is_players_turn(), "Not the Farkle phase")
    assert(self.players[index] and self.players[index].alive)
    local status = self.farkle:roll(index)
    if status == "farkle" then
        self:note(self.players[index].color ..
                  " FARKLE: zero points, boss turn follows when everyone finishes.")
    else
        self:note(self.players[index].color .. " rolls the dice.")
    end
    return status
end

function Game:toggle_farkle(index, die)
    assert(self.farkle and self:is_players_turn())
    assert(self.players[index] and self.players[index].alive)
    return self.farkle:toggle(index,die)
end

function Game:take_farkle(index)
    assert(self.farkle and self:is_players_turn())
    local points = self.farkle:take(index)
    self:note(self.players[index].color .. " sets aside scoring dice (" ..
              points .. " provisional points).")
    return points
end

-- Three explicit choices: damage, or trade 20/30 Farkle points for a
-- one-token countermeasure (remainder still becomes Combat).
-- Countermeasure costs are NOT original P4ND0RA or Star Realms rules.
function Game:bank_farkle(index, choice)
    assert(self.farkle and self:is_players_turn())
    assert(self.players[index] and self.players[index].alive)
    choice = choice or "attack"
    local permitted, points = self.farkle:can_bank(index)
    assert(permitted, "Select scoring dice or set them aside before banking")
    local cost = choice == "blank" and 20 or choice == "discard" and 30 or 0
    assert(choice=="attack" or choice=="blank" or choice=="discard")
    assert(points>=cost, "Insufficient banked points for this countermeasure")
    if choice == "blank" then
        assert(self.blank_next < math.min(8,self.draw_power),
               "All upcoming boss tokens already neutralized")
    elseif choice == "discard" then
        assert(#self.bag>0,"No token remains in bag")
    end
    local result=self.farkle:bank(index)
    local damage = math.floor((result.points-cost)/5)
    if choice == "blank" then
        self.blank_next=self.blank_next+1
        self:note("Farkle countermeasure: next boss token neutralized (20 points).")
    elseif choice == "discard" then
        local token=table.remove(self.bag,self.random(#self.bag))
        self.discard[#self.discard+1]=token
        self:note("Farkle countermeasure: random boss token removed (30 points).")
        self:assert_tokens()
    end
    self:note(self.players[index].color .. " banks " .. result.points ..
              " points = " .. damage .. " Combat" ..
              (cost>0 and " after " .. cost .. " spent on defence." or "."))
    if damage>0 then self:combat(index,damage) end
    return result
end

function Game:discard_random_token(index)
    assert(self:is_players_turn())
    local p = assert(self.players[index])
    assert(p.alive and p.hand > 0, "One hand card must be discarded")
    if #self.bag == 0 then
        self:note("Bag empty; no token to discard.")
        return false
    end
    assert(not self.farkle, "Farkle uses paid banking countermeasures")
    p.hand = p.hand - 1
    p.faction = math.min(p.faction, p.hand)
    local token = table.remove(self.bag, self.random(#self.bag))
    self.discard[#self.discard + 1] = token
    self:note(p.color .. " discards 1 hand card to discard a random boss token.")
    self:assert_tokens()
    return true
end

function Game:blank_token(index)
    assert(self:is_players_turn())
    local p = assert(self.players[index])
    assert(not self.farkle, "Farkle uses paid banking countermeasures")
    assert(p.alive and p.bases > 0, "One base must be destroyed to blank a token")
    if self.blank_next >= self.draw_power then return false end
    p.bases = p.bases - 1
    self.blank_next = self.blank_next + 1
    self:note(p.color .. " destroys a base: next boss token " .. self.blank_next .. " blanked.")
    return true
end

function Game:begin_boss_turn()
    assert(self:is_players_turn(), "Players must act before P4ND0RA")
    if self.farkle then
        for i,p in ipairs(self.players) do
            assert(not p.alive or self.farkle:is_finished(i),
                   "All living players must bank or Farkle before the boss acts")
        end
    end
    self.phase = "boss"
    self.pending = nil
    self.queue = {}
    self.drawn, self.drawn_actions = {}, {}
    self.last_actions = {}
    self.shield = 0 -- Original: shield drops at the BEGINNING of each boss turn.
    if self.active_defense_turns > 0 then
        self.active_defense_turns = self.active_defense_turns - 1
    end
    self:note("Boss turn " .. self.round .. ": DRAW phase.")
    for _ = 1, math.min(8, self.draw_power) do
        if #self.bag == 0 then break end
        local token = table.remove(self.bag, self.random(#self.bag))
        self.drawn[#self.drawn + 1] = token
    end
    self.exhausted_this_turn = (#self.bag == 0)
    if self.exhausted_this_turn and self.draw_power < 8 then
        self.draw_power = self.draw_power + 1
        self:note("Bag exhausted: generator increases draw power to " .. self.draw_power .. ".")
    end
    for i, name in ipairs(self.drawn) do
        self.drawn_actions[i] = (i <= self.blank_next) and "blank" or name
    end
    self:note("Drawn " .. #self.drawn .. " token(s); first " ..
              math.min(self.blank_next, #self.drawn) .. " neutralized.")
    self.blank_next = 0

    local order = {
        oneStar = "ability", twoStar = "ability",
        threeStar = "ability", special = "ability",
        attack = "attack", defense = "defense", repairs = "defense",
    }
    local upgrade_seen = false
    for _, phase in ipairs({"ability", "attack", "defense"}) do
        for _, token in ipairs(self.drawn_actions) do
            if order[token] == phase then
                self.queue[#self.queue + 1] = {phase = phase, token = token}
            end
            if token == "upgrade" then upgrade_seen = true end
        end
    end
    -- Original checks for presence of any upgrade token and upgrades ONCE.
    if upgrade_seen then
        self.queue[#self.queue + 1] = {phase = "upgrade", token = "upgrade"}
    end
    self.queue[#self.queue + 1] = {phase = "end", token = "end"}
    self.phase_index = 0
    self:assert_tokens()
end

function Game:apply_emp()
    for i,p in ipairs(self.players) do
        if p.alive then
            if self.farkle then
                local locked=self.farkle:apply_emp(i,self.stats.emp)
                self:note(p.color .. " EMP: " .. locked ..
                          " dice unavailable at the next turn's opening roll.")
            else
                local discard=math.min(p.hand,self.stats.emp)
                p.hand=p.hand-discard
                if self.stats.faction_must and p.faction>0 and discard>0 then
                    p.faction=math.max(0,p.faction-1)
                end
                p.faction=math.min(p.faction,p.hand)
                self:note(p.color .. " discards " .. discard .. " cards" ..
                    (self.stats.faction_must and " (faction required if available)." or "."))
            end
        end
    end
end

function Game:advance()
    assert(self.phase == "boss", "Not in boss phase")
    assert(not self.pending, "Resolve pending player choice first")
    local action = table.remove(self.queue, 1)
    assert(action)
    self.phase_index = self.phase_index + 1
    local token = action.token
    self.last_actions[#self.last_actions + 1] = token
    if token == "oneStar" then
        self:note("ABILITY: Missile Barrage. Each player loses a base OR " ..
                  self.stats.missile .. " Authority.")
        local targets = active_players(self)
        self.pending = {type = "missile", targets = targets, current = 1}
    elseif token == "twoStar" then
        self:note("ABILITY: EMP pulse. Discard " .. self.stats.emp .. " cards each.")
        self:apply_emp()
    elseif token == "threeStar" then
        self.active_defense_turns = self.stats.cqc
        self:note("ABILITY: CQC active; incoming combat halved for " ..
                  self.stats.cqc .. " player turn(s).")
    elseif token == "special" then
        if self.special_counter < 3 then
            self.special_counter = self.special_counter + 1
            self:note("SPECIAL: Nuclear preparation " .. self.special_counter .. "/3.")
        else
            self.special_counter = 0
            self:note("SPECIAL: NUCLEAR STRIKE! -20 Authority, destroy ALL bases.")
            for i, p in ipairs(self.players) do
                if p.alive then
                    p.bases = 0
                    self:lose_authority(i, 20)
                end
            end
        end
    elseif token == "attack" then
        local targets = active_players(self)
        if #targets > 0 then
            local i = targets[self.random(#targets)]
            self:note("ATTACK: " .. self.players[i].color ..
                      " takes " .. self.stats.attack .. " Authority damage.")
            self:lose_authority(i, self.stats.attack)
        end
    elseif token == "defense" then
        self.shield = self.shield + self.stats.shield
        self:note("DEFENSE: +" .. self.stats.shield .. " shields.")
    elseif token == "repairs" then
        self.hp = math.min(self.stats.max_health, self.hp + self.stats.repair)
        self:note("REPAIR: boss HP now " .. self.hp .. ".")
    elseif token == "upgrade" then
        self.stats.attack = self.stats.attack + 1
        self.stats.repair = self.stats.repair + 1
        self.stats.shield = self.stats.shield + (self.player_count > 2 and 2 or 1)
        self.upgrades = self.upgrades + 1
        self:note("UPGRADE: Attack, repair and shields strengthened.")
    elseif token == "end" then
        for _, item in ipairs(self.drawn) do
            self.discard[#self.discard + 1] = item
        end
        self.drawn = {}
        if #self.bag == 0 then
            for _, item in ipairs(self.discard) do
                self.bag[#self.bag + 1] = item
            end
            self.discard = {}
            shuffle(self.bag, self.random)
            self.bag_cycles = self.bag_cycles + 1
            self:note("End of boss turn: discard reshuffled into the bag.")
        end
        if self.farkle then
            for i,p in ipairs(self.players) do
                if p.alive then self.farkle:new_turn(i) end
            end
        end
        self.phase = "players"
        self.round = self.round + 1
        self:note("Players' turn. P4ND0RA's shields have not reset yet.")
    end
    self:assert_tokens()
    return token
end

function Game:resolve_missile(choice)
    assert(self.phase == "boss" and self.pending and
           self.pending.type == "missile", "No missile choice pending")
    assert(choice == "base" or choice == "authority")
    local pending = self.pending
    local index = pending.targets[pending.current]
    local p = self.players[index]
    if p and p.alive then
        if choice == "base" then
            assert(p.bases > 0, "No base to sacrifice")
            p.bases = p.bases - 1
            self:note(p.color .. " destroys one base to absorb the missile.")
        else
            self:note(p.color .. " accepts missile damage.")
            self:lose_authority(index, self.stats.missile)
        end
    end
    pending.current = pending.current + 1
    if pending.current > #pending.targets or self.result then self.pending = nil end
    self:assert_tokens()
end

M.Game = Game
return M
