-- Deterministic contact gating independent of LÖVE, the solver and RNG.
local Gate = require("src.core.dice_impact_audio")
local g = Gate.new()
assert(g:accept("floor", 1, nil, 1.0, 0) == nil)
local hit = g:accept("floor", 1, nil, 5.0, 0)
assert(hit and hit > 0.2 and hit < 1)
assert(g:accept("floor", 1, nil, 6.0, 0.02) == nil,
    "Sustained penetration must not chatter")
assert(g:accept("floor", 1, nil, 4.0, 0.10))
assert(g:accept("floor", 2, nil, 4.0, 0.11),
    "Separate dice must produce independent impact events")
assert(g:accept("rim", 1, nil, 5.0, 0.11),
    "Rim should not be throttled by a floor hit")
assert(g:accept("pair", 1, 2, 5.0, 0.12))
assert(g:accept("pair", 2, 1, 5.0, 0.13) == nil,
    "Pair keys are order independent")
assert(g:accept("pair", 2, 1, 5.0, 0.21))
assert(g:accept("pair", 1, 1, 5.0, 0.30) == nil)
assert(g:accept("unknown", 1, nil, 5.0, 0.30) == nil)
assert(g:accept("floor", 1, nil, 0/0, 0.30) == nil)
assert(g:accept("floor", 1, nil, 5.0, 0/0) == nil)
assert(g:accept("floor", 3, nil, 100, 1) == 1)
print("PASS physical impact gate: threshold, independent surfaces/pairs, cooldown, NaN and clipping")
