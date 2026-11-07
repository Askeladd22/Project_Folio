-- Standalone six-D6 Farkle player, using a byte-for-byte snapshot of the
-- production Rules. CI checks it against src/farkle/rules.lua on EVERY PR.
-- The Lab is launched as 'love experiments/p4ndora_1to1', whose filesystem
-- cannot directly require files outside that LÖVE source directory.
local Rules = require("farkle_rules_snapshot")
local M = {}
M.Rules = Rules

local function rng(seed)
    local n = (math.floor(tonumber(seed) or 101) % 2147483646) + 1
    -- Small consecutive seeds otherwise force the FIRST die to 1 for
    -- thousands of games. Warm up this independent Park-Miller stream.
    for _=1,12 do n = n * 16807 % 2147483647 end
    return function()
        n = n * 16807 % 2147483647
        return 1 + math.floor(n / 2147483647 * 6)
    end
end

local Match = {}
Match.__index = Match

local function get(self, index)
    return assert(self.states[index], "No player with this index")
end

local function require_playing(self,index)
    assert(not self.finished[index], "Player's Farkle turn is finished")
    return get(self,index)
end

function M.new(seed, players)
    assert(type(players)=="number" and players>=1 and players<=4)
    local self = setmetatable({states={},random={},finished={},
        results={},penalties={},last_roll={},roll_count={}}, Match)
    for i=1,players do
        self.random[i]=rng((seed or 101)+1709*i)
        self:new_turn(i)
    end
    return self
end

function Match:new_turn(index)
    local previous = self.states[index]
    assert(not previous or self.finished[index], "Cannot replace an active turn")
    local penalty = math.min(3,self.penalties[index] or 0)
    local s=Rules.new("control")
    s.penalty=penalty
    for die=1,penalty do s.used[die]=true end
    self.states[index]=s
    self.finished[index]=false
    self.results[index]=nil
    self.last_roll[index]={}
    self.roll_count[index]=0
    self.penalties[index]=0
    return s
end

function Match:apply_emp(index,amount)
    assert(get(self,index))
    assert(type(amount)=="number" and amount>=0)
    self.penalties[index]=math.min(3,(self.penalties[index] or 0)+amount)
    return self.penalties[index]
end

function Match:roll(index)
    local s=require_playing(self,index)
    assert(Rules.start(s), "Roll not permitted: accantona selected scoring dice")
    local values={}
    for _,id in ipairs(s.active) do values[id]=self.random[index]() end
    self.roll_count[index]=self.roll_count[index]+1
    self.last_roll[index]=values
    assert(Rules.settle(s,values), "Cannot settle real Farkle roll")
    if s.phase=="ended" or s.phase=="lost" then
        self.finished[index]=true
        self.results[index]={points=0,farkle=true}
        return "farkle"
    end
    return "ready"
end

function Match:toggle(index,id)
    local s=require_playing(self,index)
    assert(Rules.toggle(s,id), "Cannot select that die")
    return Rules.selection_option(s)
end

function Match:take(index)
    local s=require_playing(self,index)
    assert(Rules.take(s), "Select a valid Farkle combination first")
    return s.pot
end

function Match:can_bank(index)
    if self.finished[index] then return false,0 end
    return Rules.bank_status(get(self,index))
end

function Match:bank(index)
    local s=require_playing(self,index)
    assert(Rules.bank_status(s), "Cannot bank: select scoring dice first")
    assert(Rules.bank_turn(s), "Canonical bank failed")
    self.finished[index]=true
    self.results[index]={points=s.bank,farkle=false}
    return self.results[index]
end

function Match:is_finished(index)
    return not not self.finished[index]
end

function Match:result(index)
    return self.results[index]
end

function Match:all_finished(living)
    for i,alive in ipairs(living) do
        if alive and not self.finished[i] then return false end
    end
    return true
end

return M
