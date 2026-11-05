-- XY component of fps_part_boundary_update, Free Physics Solver 1.2.5.
-- Copyright (c) 2025 Dice, MIT. See experiments/physics_lab/vendor/LICENSE.
-- The solver stores each corner already rotated and scaled about the body
-- origin. Translation is applied by the caller when testing the four walls.
local Bounds = {}

function Bounds.footprint(body)
    local first = body[1]
    local xmin, xmax = first[1], first[1]
    local ymin, ymax = first[2], first[2]
    for i = 2, #body do
        local vertex = body[i]
        xmin, xmax = math.min(xmin, vertex[1]), math.max(xmax, vertex[1])
        ymin, ymax = math.min(ymin, vertex[2]), math.max(ymax, vertex[2])
    end
    return xmin, xmax, ymin, ymax
end

return Bounds
