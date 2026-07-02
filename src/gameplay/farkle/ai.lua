local Ai = {}

local function score_of(player)
    if type(player) ~= "table" then
        return 0
    end
    return tonumber(player.score) or 0
end

local function get_scores(match)
    local players = type(match.players) == "table" and match.players or {}
    return score_of(players[2]), score_of(players[1])
end

local function current_player_score(match)
    local players = type(match.players) == "table" and match.players or {}
    return score_of(players[match.current_player_index or 2])
end

function Ai.bank_threshold(match)
    local ai_score, human_score = get_scores(match or {})
    if ai_score >= human_score then
        return 450
    end
    if human_score - ai_score >= 1000 then
        return 900
    end
    return 700
end

function Ai.decide(match)
    if type(match) ~= "table" or match.phase == nil then
        return {kind = "wait", reason = "missing_match"}
    end

    if match.phase == "awaiting_roll" then
        return {kind = "roll", dice_count = match.available_dice or 6}
    end

    if match.phase == "selecting" then
        local group = match.latest_groups and match.latest_groups[1]
        if not group then
            return {kind = "wait", reason = "no_group"}
        end
        return {
            kind = "keep",
            group_id = group.id,
            group_kind = group.kind,
            score = group.score,
        }
    end

    if match.phase == "can_bank_or_roll" then
        local turn_score = tonumber(match.turn_score) or 0
        local target_score = tonumber(match.target_score) or 5000
        if current_player_score(match) + turn_score >= target_score then
            return {kind = "bank", reason = "wins"}
        end
        if turn_score >= Ai.bank_threshold(match) then
            return {kind = "bank", reason = "threshold"}
        end
        return {kind = "reroll", dice_count = match.available_dice or 6}
    end

    return {kind = "wait", reason = "unsupported_phase"}
end

return Ai
