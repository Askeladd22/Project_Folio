local Scoring = {}

local TRIPLE_SCORES = {
    [1] = 1000,
    [2] = 200,
    [3] = 300,
    [4] = 400,
    [5] = 500,
    [6] = 600,
}

local function normalize_roll(values)
    local entries = {}
    for roll_pos, item in ipairs(values or {}) do
        local value = item
        local source_index = roll_pos

        if type(item) == "table" then
            value = item.value
            if item.source_index ~= nil then
                source_index = item.source_index
            elseif item.index ~= nil then
                source_index = item.index
            end
        end

        value = tonumber(value)
        if value and value >= 1 and value <= 6 and value == math.floor(value) then
            entries[#entries + 1] = {
                roll_pos = roll_pos,
                source_index = source_index,
                value = value,
            }
        end
    end
    return entries
end

local function copy_dice(dice)
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

local function build_counts(entries)
    local counts = {}
    local dice_by_value = {}

    for _, die in ipairs(entries) do
        local value = die.value
        counts[value] = (counts[value] or 0) + 1
        dice_by_value[value] = dice_by_value[value] or {}
        dice_by_value[value][#dice_by_value[value] + 1] = die
    end

    return counts, dice_by_value
end

local function make_group(kind, label, score, dice)
    local copied = copy_dice(dice)
    return {
        id = kind,
        kind = kind,
        label = label,
        score = score,
        dice = copied,
        dice_count = #copied,
    }
end

local function has_straight(counts)
    for value = 1, 6 do
        if (counts[value] or 0) ~= 1 then
            return false
        end
    end
    return true
end

local function collect_all_dice(dice_by_value)
    local dice = {}
    for value = 1, 6 do
        for _, die in ipairs(dice_by_value[value] or {}) do
            dice[#dice + 1] = die
        end
    end
    return dice
end

local function count_pairs(counts)
    local pairs = 0
    for value = 1, 6 do
        if (counts[value] or 0) == 2 then
            pairs = pairs + 1
        end
    end
    return pairs
end

local function kind_score(count, value)
    if count >= 6 then
        return 3000
    end
    if count == 5 then
        return 2000
    end
    if count == 4 then
        return 1000
    end
    return TRIPLE_SCORES[value]
end

local function kind_name(count)
    if count >= 6 then
        return "six"
    end
    if count == 5 then
        return "five"
    end
    if count == 4 then
        return "four"
    end
    return "three"
end

local function kind_label(count, value)
    if count >= 6 then
        return "Six " .. tostring(value) .. "s"
    end
    if count == 5 then
        return "Five " .. tostring(value) .. "s"
    end
    if count == 4 then
        return "Four " .. tostring(value) .. "s"
    end
    return "Three " .. tostring(value) .. "s"
end

local function add_kind_group(groups, value, count, dice_by_value)
    local used_count = math.min(count, 6)
    local dice = {}
    for i = 1, used_count do
        dice[i] = dice_by_value[value][i]
    end

    local prefix = kind_name(used_count)
    groups[#groups + 1] = make_group(
        prefix .. "_kind_" .. tostring(value),
        kind_label(used_count, value),
        kind_score(used_count, value),
        dice
    )
end

local function add_single_groups(groups, value, dice_by_value)
    local score = value == 1 and 100 or 50
    local kind = value == 1 and "single_one" or "single_five"
    local label = value == 1 and "Single 1" or "Single 5"

    for _, die in ipairs(dice_by_value[value] or {}) do
        groups[#groups + 1] = make_group(kind, label, score, {die})
    end
end

local function first_die_number(group, field)
    local die = group.dice and group.dice[1] or nil
    local value = die and tonumber(die[field]) or nil
    return value or math.huge
end

function Scoring.normalize_roll(values)
    return normalize_roll(values)
end

function Scoring.get_scoring_groups(values)
    local entries = normalize_roll(values)
    local counts, dice_by_value = build_counts(entries)
    local groups = {}

    if #entries == 6 and has_straight(counts) then
        groups[#groups + 1] = make_group("straight", "Straight 1-6", 2500, collect_all_dice(dice_by_value))
    end

    if #entries == 6 and count_pairs(counts) == 3 then
        groups[#groups + 1] = make_group("three_pairs", "Three pairs", 1500, collect_all_dice(dice_by_value))
    end

    for value = 1, 6 do
        local count = counts[value] or 0
        if count >= 3 then
            add_kind_group(groups, value, count, dice_by_value)
        elseif value == 1 or value == 5 then
            add_single_groups(groups, value, dice_by_value)
        end
    end

    table.sort(groups, function(a, b)
        if a.score == b.score then
            if a.dice_count == b.dice_count then
                if a.kind == b.kind then
                    local a_roll_pos = first_die_number(a, "roll_pos")
                    local b_roll_pos = first_die_number(b, "roll_pos")
                    if a_roll_pos == b_roll_pos then
                        local a_source_index = first_die_number(a, "source_index")
                        local b_source_index = first_die_number(b, "source_index")
                        return a_source_index < b_source_index
                    end
                    return a_roll_pos < b_roll_pos
                end
                return a.kind < b.kind
            end
            return a.dice_count > b.dice_count
        end
        return a.score > b.score
    end)

    for i, group in ipairs(groups) do
        group.id = group.kind .. ":" .. tostring(i)
    end

    return groups
end

function Scoring.is_bust(values)
    return #Scoring.get_scoring_groups(values) == 0
end

function Scoring.best_group(values)
    local groups = Scoring.get_scoring_groups(values)
    return groups[1]
end

function Scoring.find_group(groups, group_id)
    for _, group in ipairs(groups or {}) do
        if group.id == group_id or group.kind == group_id then
            return group
        end
    end
    return nil
end

return Scoring
