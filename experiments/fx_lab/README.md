# Original FX lab

Run `Avvia.cmd` or `love experiments/fx_lab` from the repository root. LOVE 11 required; no install, external assets, packaging or production changes. All drawing is original geometry with LOVE's default font. The die is a graphical proxy: physics is disabled.

Tabs 1–5 select die transfer, staged points, ink ornament, medal sheen and desk light. Left shows the final state without effects; right plays the selected effect. Space pauses/resumes, R restarts, B toggles the current effect, M toggles reduced motion. Left/right change duration; up/down change intensity. Repeat has its own button. Effect enablement is remembered independently per tab. Off/reduced motion immediately presents the final state. Sound is off; no audio module is loaded.

The pure Lua timeline uses elapsed time and clamped easing, with no fixed-delta stepping. Three canvases and three optional shaders are created only in load. Shader compilation failure yields a clipped ink reveal and static gold/light scenes. Intensity adjusts arc height, ink edge variation and shader brightness; count totals remain exact.

Model and syntax checks from repository root:

`rtk proxy python scripts/test_luajit.py experiments/fx_lab/test.lua experiments/fx_lab/model_test.lua`

`test.lua` was written and observed failing before model implementation, then passed. The provisional `tests/timeline_test.lua` assumed an unimplemented API and was removed; its timing/reduced/off cases are covered by the object-model tests. `model_test.lua` was adapted to the actual API.

Optional GUI audit (run serially with other graphics work):

`rtk powershell -ExecutionPolicy Bypass -File experiments/fx_lab/audit.ps1`

Override `-LoveExe` if needed. The opt-in FX_LAB_AUDIT environment variable points to an existing absolute output directory. The audit captures all five scenes at 1280×720 and 1920×1080, animated and disabled, reports shader compilation, and exits. `audit/metrics.csv` averages CPU draw submission and model update separately, after ten warmup frames per case. Draw measurements include both panes and UI; disabled is the comparison baseline. They are not GPU timings, frame latency, or whole-application benchmarks. Screenshot capture is excluded from the measured draw interval. Texture memory and draw-call statistics are LOVE counters. GPU time is explicitly unmeasured.

Harness API: global `lab.model` is the model object; `lab.select(1..5)`, `lab.play()`, and `lab.draw_scene(id, progress, intensity, animated)` are available after `love.load`. The draw helper uses local 540×370 coordinates. The whole UI uses a 1280×720 virtual surface and letterboxes to the window.

Audit detail: animated blocks measure an actual active model update, then restore a repeated halfway pose for comparable draw submissions (not continuous real-time playback). One endpoint frame per block compares panel pixels, tolerating at most one byte per channel; disabled blocks compare their final state against the baseline. Results are in `pixel-checks.csv`, and mismatches fail the audit. The audit wraps the actual `love.graphics.newCanvas` entry point before load and fails if its call count increases afterwards. All Canvas draws use premultiplied blending, restoring the incoming blend mode; ink reveal scales both RGB and alpha.

Canvas contents are repainted into the existing objects after resize or a window mode change, since the graphics backend can discard their pixels. Each audit mode change also reads all three canvases back outside the timed intervals, asserting substantial opaque content and color variation so two blank panels cannot pass merely by matching each other. Runtime output includes these content checks and LOVE/renderer/version/vendor/device metadata.

At both resolutions the audit calls the actual keyboard and mouse callbacks to check five tabs, play/pause/replay, repeat, independent remembered effect toggles, immediate reduced motion, duration and intensity. Mouse coordinates are transformed through the current letterbox scale/offset. These are synthetic callback tests, not operating-system input automation. Model and selection state are restored afterwards; the checks run outside benchmark sampling.


### Versionamento degli output grafici (31 ottobre 2026)

Gli screenshot di `audit/*.png` sono generati da `audit.ps1`, non
sono risorse del gioco: dopo la pulizia della repository non sono piu
tracciati e `.gitignore` li esclude da futuri commit. I report storici
`audit/{metrics.csv,pixel-checks.csv,runtime.txt}` sono conservati.
Per ricreare i 20 PNG a 720p/1080p rieseguire il comando di audit.
