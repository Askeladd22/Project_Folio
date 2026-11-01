-- Current V2 screenshot gate is separate from the historical P0 script.
-- The original LOVE splash, gameplay engine and physical dice are untouched.
local function read(path)
 local f=assert(io.open(path,'rb'));local content=f:read('*a')
 f:close();return content
end
local smoke=read('tests/smoke/farkle_hud.lua')
local runner=read('scripts/run_smoke.py')
local capture=read('scripts/capture_ui_v2_review.py')
local doc=read('docs/UI_V2_VISUAL_REVIEW.md')
for _,needle in ipairs({
 "MANUSCRIPT_UI_V2_REVIEW_CAPTURE",
 "review_scenario(1920,1080)",
 "review_scenario(1280,720)",
 "physical_grip_baseline(prefix)",
 "Bridge.getTrayDieHits()",
 "U:mousepressed(x0,y0,1)",
 "U:mousepressed(first.x,first.y,2)",
 "U:keypressed('escape')",
 "settingsState.apply_settings(original)",
 "shot(prefix..'help')",
 "shot(prefix..'help-scores')",
 "shot(prefix..'choices-fixture')",
 "shot(prefix..'upgrade-fixture')",
 "shot(prefix..'medal-fixture')",
 "shot(prefix..'monk-live')",
 "PASS current UI V2 visual review at both resolutions",
 "write_review_hitboxes(name)",
 "Res.to_screen(r.x,r.y)",
 "Res.get_scale()",
 "local active=U.modal and U.modalButtons or U.buttons",
 ".hitboxes.tsv",
 "source\\n",
}) do assert(smoke:find(needle,1,true),'missing real capture path: '..needle) end
assert(smoke:find("if os.getenv('MANUSCRIPT_UI_V2_REVIEW_CAPTURE')=='1' then",1,true))
assert(smoke:find("else\n    scenario(1920,1080)",1,true),
 'legacy smoke must remain isolated from current V2 review')
assert(runner:find("--ui-v2-review",1,true))
assert(runner:find("env['MANUSCRIPT_UI_V2_REVIEW_CAPTURE']='1'",1,true))
assert(capture:find('png_dimensions(path)',1,true))
assert(capture:find('fingerprint(path)',1,true))
assert(capture:find('"manual_visual_qa_approved": False',1,true))
assert(capture:find('report_html(frames, commit)',1,true))
assert(capture:find('review_checklist(commit)',1,true))
assert(capture:find('read_hitboxes(hud / hitbox_name, width, height)',1,true))
assert(capture:find('class="overlay"',1,true))
assert(capture:find('Mostra hitbox reali',1,true))
assert(doc:find('python scripts/capture_ui_v2_review.py',1,true))
assert(not capture:find('hud_minimal',1,true),
 'new review may not request the deleted fallback HUD')
print('PASS active UI V2 capture routing, actual controller grip, diagnostic fixtures and honest QA boundary')
