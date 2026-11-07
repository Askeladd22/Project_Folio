-- P0 capture wiring must use genuine LÖVE/controller state, never
-- simulated Farkle scores or a disconnected cosmetic preview.
local function load(path)
 local h=assert(io.open(path,'r'));local s=h:read('*a');h:close()
 return s
end
local smoke=load('tests/smoke/farkle_hud.lua')
local runner=load('scripts/run_smoke.py')
local capture=load('scripts/capture_ui_v2_baseline.py')
for _,key in ipairs({
 'MANUSCRIPT_UI_V2_P0_CAPTURE',
 'Bridge.getTrayDieHits()',
 'U:mousepressed(x0,y0,1)',
 'U:mousereleased(x1,y1,1)',
 'U:mousepressed(first.x,first.y,2)',
 "shot(prefix..'physical-group-held')",
 "shot(prefix..'marquee-six')",
 "shot(prefix..'accessibility-on')",
 "U:keypressed('escape')",
 'state.apply_settings(settings)',
}) do assert(smoke:find(key,1,true),'real P0 smoke missing: '..key) end
assert(runner:find('--ui-v2-baseline',1,true))
assert(runner:find("env['MANUSCRIPT_UI_V2_P0_CAPTURE']='1'",1,true))
for _,name in ipairs({
 'fresh-pre-grip','marquee-six','physical-group-held',
 'accessibility-on','fresh-after-cancel','folio','upgrade',
}) do assert(capture:find(name,1,true),'manifest does not require '..name) end
assert(capture:find('fingerprint(p)',1,true))
assert(capture:find('dirty_at_capture',1,true))
print('PASS UI v2 P0 capture wiring uses real gestures, screenshot requirements and safe settings restore')
