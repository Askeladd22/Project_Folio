local Scoring = require("src.gameplay.farkle.scoring")

local Match = {}
Match.__index = Match

local function clone_dice(dice)
    local out = {}
    for i, die in ipairs(dice or {}) do
        out[i] = {
            roll_pos = die.roll_pos,
            source_index = die.source_index,
            value = die.value,
        }
    end
    return out
end

local function clone_group(group)
    return {
        id = group.id,
        kind = group.kind,
        label = group.label,
        score = group.score,
        dice = clone_dice(group.dice),
        dice_count = group.dice_count,
    }
end

local function clone_groups(groups)
    local out = {}
    for i, group in ipairs(groups or {}) do
        out[i] = clone_group(group)
    end
    return out
end

local function clone_player(player, fallback)
    player = player or fallback
    return {
        id = player.id,
        name = player.name,
        score = player.score or 0,
        is_ai = player.is_ai == true,
    }
end

local function reset_turn_state(self)
    self.turn_score = 0
    self.available_dice = 6
    self.latest_roll = {}
    self.latest_groups = {}
    self.kept_dice = {}
end

local function switch_player(self)
    self.current_player_index = self.current_player_index == 1 and 2 or 1
    self.phase = "awaiting_roll"
end

function Match.new(opts)
    opts = opts or {}
    local players = opts.players or {}
    local target_score = tonumber(opts.target_score) or 5000
    if target_score < 100 then
        target_score = 100
    end

    local self = setmetatable({
        players = {
            clone_player(players[1] or opts.human, {id = "human", name = "You", score = 0, is_ai = false}),
            clone_player(players[2] or opts.ai, {id = "ai", name = "Opponent", score = 0, is_ai = true}),
        },
        target_score = target_score,
        current_player_index = 1,
        phase = "awaiting_roll",
        turn_score = 0,
        available_dice = 6,
        latest_roll = {},
        latest_groups = {},
        kept_dice = {},
        winner_id = nil,
        last_event = nil,
        message = nil,
    }, Match)

    return self
end

function Match:getCurrentPlayer()
    return self.players[self.current_player_index]
end

function Match:isCurrentPlayerAI()
    local player = self:getCurrentPlayer()
    return player and player.is_ai == true
end

function Match:applyRoll(values)
    if self.phase ~= "awaiting_roll" then
        return {ok = false, reason = "invalid_phase"}
    end

    local roll = Scoring.normalize_roll(values)
    local groups = Scoring.get_scoring_groups(values)

    if #groups == 0 then
        self.last_event = "bust"
        self.message = "Bust"
        reset_turn_state(self)
        switch_player(self)
        return {ok = true, bust = true}
    end

    self.latest_roll = clone_dice(roll)
    self.latest_groups = clone_groups(groups)
    self.phase = "selecting"
    self.last_event = "roll"
    self.message = nil

    return {ok = true, bust = false, groups = clone_groups(self.latest_groups)}
end

function Match:keepGroup(group_id)
    if self.phase ~= "selecting" then
        return {ok = false, reason = "invalid_phase"}
    end

    local group = Scoring.find_group(self.latest_groups, group_id)
    if not group then
        return {ok = false, reason = "group_unavailable"}
    end

    self.turn_score = self.turn_score + group.score
    for _, die in ipairs(group.dice or {}) do
        self.kept_dice[#self.kept_dice + 1] = {
            roll_pos = die.roll_pos,
            source_index = die.source_index,
            value = die.value,
        }
    end

    self.available_dice = self.available_dice - group.dice_count
    local hot_dice = false
    if self.available_dice <= 0 then
        self.available_dice = 6
        hot_dice = true
    end

    self.latest_groups = {}
    self.phase = "can_bank_or_roll"
    self.last_event = "keep"
    self.message = nil

    return {ok = true, hot_dice = hot_dice, group = clone_group(group)}
end

function Match:reroll()
    if self.phase ~= "can_bank_or_roll" then
        return {ok = false, reason = "invalid_phase"}
    end

    self.latest_roll = {}
    self.latest_groups = {}
    self.phase = "awaiting_roll"
    self.last_event = "reroll"
    self.message = nil

    return {ok = true}
end

function Match:bank()
    if self.phase ~= "can_bank_or_roll" or self.turn_score <= 0 then
        return {ok = false, reason = "cannot_bank"}
    end

    local player = self:getCurrentPlayer()
    player.score = player.score + self.turn_score
    self.last_event = "bank"
    self.message = nil
    self.turn_score = 0

    if player.score >= self.target_score then
        self.phase = "game_over"
        self.winner_id = player.id
        self.latest_roll = {}
        self.latest_groups = {}
        self.kept_dice = {}
        return {ok = true, game_over = true, winner_id = self.winner_id}
    end

    reset_turn_state(self)
    switch_player(self)
    return {ok = true, game_over = false}
end

function Match:passTurn(reason)
    if self.phase == "game_over" then
        return {ok = false, reason = "game_over"}
    end

    reset_turn_state(self)
    switch_player(self)
    self.last_event = reason or "pass"
    self.message = nil

    return {ok = true}
end

return Match
