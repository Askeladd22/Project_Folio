-- Small self-contained training deck for the P4ND0RA boss-rules lab.
-- NOT the Star Realms deck. The original boss engine is unchanged in manual mode.
local M = {}
local Deck = {}
Deck.__index = Deck

-- Original generic cards, deliberately distinct from copyrighted Star Realms
-- card content. Exactly ten cards per player, five drawn per hand.
local CARDS = {
    {id = "strike", label = "Colpo", kind = "combat", value = 3, count = 4},
    {id = "heavy", label = "Assalto", kind = "combat", value = 5, count = 2},
    {id = "heal", label = "Ristoro", kind = "heal", value = 4, count = 2},
    {id = "base", label = "Presidio", kind = "base", value = 1, count = 2},
}
M.CARDS = CARDS

local function random_generator(seed)
    local n = (math.floor(tonumber(seed) or 101) % 2147483646) + 1
    return function(max)
        assert(type(max) == "number" and max > 0)
        n = (n * 16807) % 2147483647
        return 1 + n % max
    end
end

local function shuffle(cards, rnd)
    for i = #cards, 2, -1 do
        local j = rnd(i)
        cards[i], cards[j] = cards[j], cards[i]
    end
end

local function player(self, index)
    return assert(self.players[index], "Unknown demo player")
end

function M.new(seed, players)
    local self = setmetatable({players = {}}, Deck)
    for i = 1, players do
        local p = {
            draw = {}, discard = {}, hand = {}, played = {},
            random = random_generator(seed + 1009 * i),
        }
        for _, card in ipairs(CARDS) do
            for _ = 1, card.count do p.draw[#p.draw + 1] = card end
        end
        shuffle(p.draw, p.random)
        self.players[i] = p
        self:draw(i, 5)
    end
    return self
end

function Deck:draw(index, count)
    local p = player(self, index)
    for _ = 1, count do
        if #p.draw == 0 then
            if #p.discard == 0 then break end
            for _, card in ipairs(p.discard) do
                p.draw[#p.draw + 1] = card
            end
            p.discard = {}
            shuffle(p.draw, p.random)
        end
        p.hand[#p.hand + 1] = table.remove(p.draw)
    end
    return #p.hand
end

function Deck:hand(index)
    return player(self, index).hand
end

function Deck:count(index)
    local p = player(self, index)
    return #p.draw + #p.discard + #p.hand + #p.played
end

function Deck:assert_conservation()
    local total = 0
    for _, definition in ipairs(CARDS) do total = total + definition.count end
    for i = 1, #self.players do
        assert(self:count(i) == total,
            "Demo deck card conservation failed for player " .. i)
    end
end

function Deck:play(index, position)
    local p = player(self, index)
    assert(type(position) == "number" and position % 1 == 0)
    assert(position >= 1 and position <= #p.hand, "No card in hand at position")
    local card = table.remove(p.hand, position)
    p.played[#p.played + 1] = card
    self:assert_conservation()
    return card
end

function Deck:discard_one(index)
    local p = player(self, index)
    assert(#p.hand > 0, "No card to discard")
    local card = table.remove(p.hand, 1)
    p.discard[#p.discard + 1] = card
    self:assert_conservation()
    return card
end

function Deck:discard_random(index, count)
    local p = player(self, index)
    local discarded = {}
    for _ = 1, count do
        if #p.hand == 0 then break end
        local card = table.remove(p.hand, p.random(#p.hand))
        p.discard[#p.discard + 1] = card
        discarded[#discarded + 1] = card
    end
    self:assert_conservation()
    return discarded
end

-- The next hand is drawn at the END of the players' phase. Thus a boss
-- EMP discards from the real hand intended for the NEXT players' phase.
function Deck:end_players_turn(index)
    local p = player(self, index)
    for _, card in ipairs(p.hand) do p.discard[#p.discard + 1] = card end
    for _, card in ipairs(p.played) do p.discard[#p.discard + 1] = card end
    p.hand, p.played = {}, {}
    local count = self:draw(index, 5)
    self:assert_conservation()
    return count
end

return M
