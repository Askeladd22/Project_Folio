-- End-to-end fixed-step regression for the visible low-energy tail.
require('lib.core')
love = {graphics = {newImage = function() end}}
local Physics = require('src.engine3d.physics')
local Geometry = require('src.engine3d.geometry')
local Face = require('src.engine3d.roll_resolution').face_state

local function world()
    return clone(Physics.box, {timeleft=0, simulated_time=0, log_buffer={}})
        :set(14.5, 6.3, 10, 25, 0.25, 0.75, 0.01)
end

local function die(position, velocity, spin)
    local body = Geometry.newD6Body(0.8):set(position, velocity, spin)
    Physics.materials.apply(body, Physics.materials.get('bone'))
    return body
end

local function settle(w, body)
    local entry = {body=body, die=Geometry.d6}
    local last_face, stable_ticks = nil, 0
    for _ = 1, 400 do
        w:update(0.01)
        local state = Face.inspect(entry)
        if state.valid and math.abs(state.floor) < 0.006 then
            stable_ticks = state.face == last_face and stable_ticks + 1 or 1
            last_face = state.face
        else
            last_face, stable_ticks = nil, 0
        end
        if body.asleep then
            assert(state.valid and stable_ticks > 0, 'must rest on a readable face')
            return (stable_ticks - 1) * 0.01
        end
    end
    error('D6 failed to settle')
end

for spin = 1, 5 do
    local w = world()
    w[1] = die({0,0,1.8}, {1,0,0}, {spin,2,1})
    assert(settle(w, w[1]) < 0.4, 'prolonged residual rocking on the floor')
end

local w = world()
local resting = die({0,0,0.5}, {0,0,0}, {0,0,0})
resting.asleep = true
w[1], w[2] = resting, die({-1.2,0,0.51}, {5,0,0}, {0,0,0})
for _ = 1, 10 do w:update(0.01) end
assert(resting.position[1] > 0.01, 'a resting D6 must move when struck')

local edge_world = world()
local tilted = die({0,0,0}, {0,0,0}, {0.5,0,0})
local rotate = rotation():set(math.rad(40), vector{1,0,0})
for i, v in ipairs(tilted) do
    tilted[i] = rotate(v)
    tilted.position[3] = math.max(tilted.position[3], -tilted[i][3])
end
edge_world[1] = tilted
assert(not Face.inspect({body=tilted,die=Geometry.d6}).valid)
settle(edge_world, tilted)
print('PASS D6 floor support: short settling tail, impact wake-up and edge roll')
