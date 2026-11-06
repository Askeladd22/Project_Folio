-- Presentation-only gating for true fixed-step contacts. This module
-- never modifies impulses, positions, bodies, faces or gameplay RNG.
local M = {}
M.__index = M

local min_speed = {floor = 1.3, rim = 1.5, pair = 1.1}
local min_interval = {floor = 0.085, rim = 0.095, pair = 0.07}

function M.new()
    return setmetatable({last = {}}, M)
end

function M:accept(kind, index, other, speed, time)
    local threshold = min_speed[kind]
    if not threshold or type(index) ~= "number" or
        type(speed) ~= "number" or speed ~= speed or
        type(time) ~= "number" or time ~= time or
        speed < threshold then
        return nil
    end
    local key
    if kind == "pair" then
        if type(other) ~= "number" or other == index then return nil end
        local lo, hi = math.min(index, other), math.max(index, other)
        key = "pair:" .. lo .. ":" .. hi
    else
        key = kind .. ":" .. index
    end
    local last = self.last[key]
    if last and time - last < min_interval[kind] then return nil end
    self.last[key] = time
    return math.min(1, math.max(0.15, (speed - threshold) / 7))
end

return M
