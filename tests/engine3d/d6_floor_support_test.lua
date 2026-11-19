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

-- The SAT tolerance permits this microscopic side overlap. The moving
-- die slides parallel to the contact plane, then turns into its neighbour.
local pairs_solver = require('src.engine3d.die_collision')
local group = world()
group[1] = die({0,0,0.5}, {0,0,0}, {0,0,0})
group[2] = die({1-0.000005,0,0.5}, {0,0.05,0}, {0,0,0})
group[1].asleep, group[1].sleep_timer = true, 0.09
group[2].sleep_timer = 0.04
local events = 0
group.on_contact = function() events = events + 1 end
assert(pairs_solver.overlap(group[1], group[2]))
pairs_solver.solve(group, nil, 0.01)
assert(group[1].asleep and group[1].sleep_timer == 0.09,
    'grazing contact woke a resting die')
assert(group[2].sleep_timer == 0.04 and events == 0,
    'passive contact reset time to rest or emitted sound')
group[2].velocity[1] = -1
pairs_solver.solve(group, nil, 0.01)
assert(not group[1].asleep and group[1].velocity[1] < 0 and events == 1,
    'closing impact must still wake the other die and sound once')
print('PASS resting pair: passive side contact and subsequent real impact')

-- Starting at one end, a tolerated contact must not wake the whole row.
local row = world()
for i = 1, 6 do
    row[i] = die({(i-1)*(1-0.000005),0,0.5}, {0,0,0}, {0,0,0})
    row[i].asleep = i > 1
end
row[1].velocity[2] = 0.05
pairs_solver.solve(row, nil, 0.01)
for i = 2, 6 do assert(row[i].asleep, 'spurious wake-up along the row') end
print('PASS passive contact preserves rest across six adjacent D6')

-- An almost motionless, level die still has to fall the last gap.
for _, gap in ipairs({0.004, 0.02, 0.04}) do
    local drop = world()
    drop[1] = die({0,0,0.5+gap}, {0,0,0}, {0,0,0})
    drop:update(0.01)
    assert(not drop[1].asleep and drop[1].position[3] < 0.5+gap,
        'level die slept before reaching the floor')
    settle(drop, drop[1])
    local bottom = Face.inspect({body=drop[1], die=Geometry.d6}).floor
    assert(math.abs(bottom) <= 0.001, 'final pose must be supported')
end
local floating = world()
floating.gravity = 0.2
floating[1] = die({0,0,0.8}, {0,0,0}, {0,0,0})
for _ = 1, 10 do floating:update(0.01) end
assert(not floating[1].asleep and floating[1].sleep_timer == 0,
    'slow airborne body accumulated time toward sleep')
print('PASS slow airborne dice must reach floor support before sleeping')
