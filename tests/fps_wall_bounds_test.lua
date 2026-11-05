local bounds = require("src.engine3d.fps_bounds")
local cos, sin = math.cos, math.sin
-- When supplied, compare against the same orientations evaluated by fps.h.
local oracle = arg[2] and assert(io.open(arg[2]))
for angle = 0, 359 do
    local a, b = math.rad(angle), angle * .031
    local corners = {}
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local tilted = y*cos(b) - z*sin(b)
                corners[#corners+1] = {
                    .625*(x*cos(a) - tilted*sin(a)),
                    .625*(x*sin(a) + tilted*cos(a))
                }
            end
        end
    end
    local xmin, xmax, ymin, ymax = bounds.footprint(corners)
    local hx = .625*(math.abs(cos(a)) + math.abs(sin(a))*(math.abs(cos(b)) + math.abs(sin(b))))
    local hy = .625*(math.abs(sin(a)) + math.abs(cos(a))*(math.abs(cos(b)) + math.abs(sin(b))))
    for i, actual in ipairs({xmin,xmax,ymin,ymax}) do
        local expected = ({-hx,hx,-hy,hy})[i]
        assert(math.abs(actual - expected) < 1e-10)
        if oracle then assert(math.abs(actual - oracle:read("*n")) < 1e-6) end
    end
end
if oracle then oracle:close() end
print("PASS rotated die footprint at 360 orientations")
