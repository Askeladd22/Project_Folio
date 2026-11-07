-- Callbacks report actual solver contacts without changing any physics state.
require('lib.core')
love = love or {graphics = {newImage = function() end}}
local Physics = require("src.engine3d.physics")
local Geometry = require("src.engine3d.geometry")

local function world()
    local w = clone(Physics.box, {timeleft = 0, simulated_time = 0, log_buffer = {}})
        :set(9.2, 3.8, 10, 16, 0.3, 0.6, 0.01)
    w.linear_damping, w.angular_damping = 0, 0
    local b = Geometry.newD6Body(0.8):set({0, 0, 3}, {0, 0, -3}, {0, 0, 0})
    Physics.materials.apply(b, Physics.materials.get("bone"))
    w[1] = b
    return w, b
end

local silent, plain = world()
local audible, heard = world()
local impacts = {}
heard.on_contact = function(_, kind, speed)
    impacts[#impacts + 1] = {kind = kind, speed = speed}
end
for _ = 1, 100 do
    silent:update(0.01)
    audible:update(0.01)
end
local floor = false
for _, e in ipairs(impacts) do
    if e.kind == "floor" and e.speed > 1 then floor = true end
end
assert(floor, "Actual contact with the tabletop should emit a floor event")
for axis = 1, 3 do
    assert(math.abs(plain.position[axis] - heard.position[axis]) < 1e-9,
        "Audio callback must not change physical position")
    assert(math.abs(plain.velocity[axis] - heard.velocity[axis]) < 1e-9,
        "Audio callback must not change velocity")
end
assert(plain.asleep == heard.asleep)
for k = 1, #plain do
    for axis = 1, 3 do
        assert(math.abs(plain[k][axis] - heard[k][axis]) < 1e-9,
            "Audio callback must not change face orientation")
    end
end

local pairs_world = clone(Physics.box, {
    timeleft = 0, simulated_time = 0, log_buffer = {}
}):set(9.2, 3.8, 10, 0.0001, 0.3, 0.6, 0.01)
for i, pos in ipairs({-0.3, 0.3}) do
    local velocity = (i == 1) and 2 or -2
    local b = Geometry.newD6Body(0.8):set({pos, 0, 2},
        {velocity, 0, 0}, {0, 0, 0})
    Physics.materials.apply(b, Physics.materials.get("bone"))
    pairs_world[i] = b
end
local pair_events = 0
pairs_world.on_contact = function(_, kind, first, second, speed)
    assert(kind == "pair" and first ~= second and speed > 0)
    pair_events = pair_events + 1
end
for _ = 1, 10 do pairs_world:update(0.01) end
assert(pair_events > 0, "Approaching dice must create pair contact events")

print("PASS production contact callbacks: floor/pair timing and physics invariance")
