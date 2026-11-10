# EX-001 — Merchant V4 opening-X A/B (research only)

Base: main at 8dfa7c87da96afa25d16df11899acada92aac5b3, 2026-11-09.
This is NOT a canonical rules change. No production files under src/, dice physics, or UI were touched.

## The variants

A (baseline, DEFAULT): draw exactly two tokens initially. Any opening X immediately awards the hand to the artist before dice.
B (redraw, OPT-IN): discard opening X tokens from the same public type box until exactly two numeric tokens are obtained. X still defeats the Merchant during subsequent counteroffers. The box refill rule is unchanged.

Only the lab API receives optional opening_x_mode='redraw'. All regular Merchant V4 callers retain the original behavior. The initial box is V10x6, V20x5, V25x4, V55x2, Xx3. Voluntary raises are disabled for this experiment, not removed from V4.

## Execute from repository root

    lua5.4 tests/labs/ex001_merchant_x_test.lua
    luajit tests/labs/ex001_merchant_x_test.lua
    lua5.4 experiments/ex001_merchant_x_lab/run.lua 1000 1999

For raw rows, first make an empty output folder, then pass it as a third argument:

    mkdir -p /tmp/folio-ex001
    lua5.4 experiments/ex001_merchant_x_lab/run.lua 1000 1999 /tmp/folio-ex001

The CSV files are ex001_matches.csv and ex001_hands.csv. Pilot seed window: 1000-1999. Holdout 2000-6999 must not be used for calibration. Policies are prudent (bank threshold 30), balanced (50), daring (80), and random_legal (uniform valid subsets, equal bank/take when bank possible). These are scripted diagnostics, not human skill models.

Technical guards: same opening first two draws for fixed seed, default A preserved, B consumes X and continues, no double payout, 480 denari conserved, Merchant policy and scoring unchanged, repeatable outcomes. Pilot output reports Wilson 95% intervals by arm and approximate paired-difference intervals; paired seeds do not guarantee the same complete random path after token consumption diverges.

A corrected first-hand X rule alone does not prove a better duel. Evaluate actor agency, payout, number of real choices, and predictability of Merchant response before any design decision. No asset/UI work or PR merge.
