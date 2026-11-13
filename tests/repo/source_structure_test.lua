local obsolete={
 'src/engine3d/g3d_live.lua',
 'src/engine3d/glb_loader.lua',
 'src/engine3d/containment.lua',
 'src/engine3d/fps_bounds.lua',
 'src/engine3d/spawn_clearance.lua',
 'src/engine3d/face_state.lua',
 'src/farkle/commission_progress.lua',
 'src/farkle/scoring.lua',
 'src/farkle/medals.lua',
 'src/core/menu_background.lua',
 'src/core/menu_particles.lua',
 'src/core/dice_impact_audio.lua',
 'src/core/runtime_ui.lua',
 'src/core/roll_events.lua',
 'src/core/settings_data_codec.lua',
 'src/core/lua_table_store.lua',
 'src/data/commission_menu.lua',
 'src/data/settings_ui_schema.lua',
 'src/data/settings_persistence_schema.lua',
 'src/data/dice_roll_schema.lua',
 'src/data/dice_scene_schema.lua',
 'src/data/dice_visual_schema.lua',
 'src/data/tray_layout.lua',
 'src/data/execution_order_plan.lua',
 'src/data/main_menu_schema.lua',
 'src/data/campaign_select_schema.lua',
 'src/data/startup_splash_schema.lua',
 'src/core/event_bus.lua','src/core/logger.lua','src/core/schema.lua',
 'src/core/dice_config.lua','src/core/settings_state.lua',
 'src/core/settings_store.lua','src/core/resolution_manager.lua',
 'src/core/execution_order.lua','src/core/i18n.lua','src/core/typography.lua',
 'src/core/version.lua','src/core/menu_visuals.lua',
 'src/data/art_palette.lua','src/data/settings_schema.lua',
 'src/engine3d/face_texture.lua','src/engine3d/projected_die.lua',
 'src/features/main_menu/module.lua','src/features/campaign_select/module.lua',
 'src/features/settings/module.lua','src/features/ui_v2/menu_surface.lua',
 'src/features/scriptorium/page_layout.lua','src/features/scriptorium/folio_ink_text.lua',
 'src/features/scriptorium/miniature_2d.lua','src/features/scriptorium/dream_postfx_2d.lua',
 'src/features/scriptorium/presentation.lua',
 'src/farkle/hud_model.lua','src/farkle/folio_view.lua',
 'src/farkle/medal_panel.lua','src/farkle/toast_messages.lua',
 'src/farkle/tray_view.lua','src/farkle/tray_workshop.lua',
}
for _,name in ipairs{'bevel','camera','materials','mesh','portrait','scenery','shadow'} do
 obsolete[#obsolete+1]='src/engine3d/g3d_'..name..'.lua'
 obsolete[#obsolete+1]='src/engine3d/g3d/'..name..'.lua'
end
for _,name in ipairs{
 'group_hold_projection','group_shaker','group_throw',
 'marquee_selection','mouse_throw','shake_detector',
} do
 obsolete[#obsolete+1]='src/farkle/'..name..'.lua'
 obsolete[#obsolete+1]='src/farkle/interaction/'..name..'.lua'
end
for _,name in ipairs{
 'accepted_dice','actions','label_fit','layout_candidates',
 'modal_layout','overlay_model','paragraph_fit',
 'hud','layout','text_fit','overlay','dialogs','opponent_scene',
} do
 obsolete[#obsolete+1]='src/farkle/ui_v2/'..name..'.lua'
end
for _,path in ipairs(obsolete) do
 local old=io.open(path,'rb')
 if old then old:close() end
 assert(not old,'merged or legacy module still exists: '..path)
end

local modules={
 'src/core/dice_runtime.lua',
 'src/core/audio_manager.lua',
 'src/core/config.lua',
 'src/core/engine_bridge.lua',
 'src/core/game_manager.lua',
 'src/core/navigation.lua',
 'src/core/presentation.lua',
 'src/core/runtime_state.lua',
 'src/data/dice_schema.lua',
 'src/data/frontend_schema.lua',
 'src/data/locale_en.lua',
 'src/engine3d/bounds.lua',
 'src/engine3d/geometry.lua',
 'src/engine3d/physics.lua',
 'src/engine3d/roll_resolution.lua',
 'src/engine3d/view.lua',
 'src/engine3d/g3d/scene.lua',
 'src/engine3d/g3d/live.lua',
 'src/engine3d/g3d/glb_loader.lua',
 'src/screens/folio_surface.lua',
 'src/screens/frontend.lua',
 'src/farkle/controller.lua',
 'src/farkle/dice.lua',
 'src/farkle/rules.lua',
 'src/farkle/interaction.lua',
 'src/farkle/presentation.lua',
 'src/farkle/tabletop.lua',
 'src/farkle/ui.lua',
 'src/screens/startup_splash.lua',
}
assert(#modules==29,'production allowlist must contain exactly 29 Lua files')
local expected={}
for _,path in ipairs(modules) do
 local current=assert(io.open(path,'rb'),'missing consolidated module: '..path)
 current:close()
 expected[path]=true
end
local windows=package.config:sub(1,1)=='\\'
local listing=assert(io.popen(windows and 'dir /s /b src\\*.lua' or "find src -type f -name '*.lua'"))
local count=0
for path in listing:lines() do
 path=path:gsub('\\','/'):gsub('^.-/src/','src/')
 assert(expected[path],'unexpected production module: '..path)
 count=count+1
end
assert(listing:close(),'cannot enumerate production modules')
assert(count==29,'expected exactly 29 production Lua files, found '..count)

local function exists(path)
 local command=windows and ('if exist "'..path:gsub('/','\\')..'" (exit 0) else (exit 1)')
  or ("test -e '"..path.."'")
 local result=os.execute(command)
 return result==true or result==0
end
local folders={'src/core','src/data','src/engine3d','src/engine3d/g3d','src/farkle','src/screens'}
for _,path in ipairs(folders) do assert(exists(path),'missing source folder: '..path) end
for _,path in ipairs{
 'src/app','src/features','src/gameplay','src/data/localization','third_party',
 'core.lua','probe_tmp.lua','lib/dice_glow.glsl','scripts/test_luajit.py',
} do assert(not exists(path),'retired folder layout still present: '..path) end
for _,path in ipairs{'lib/core.lua','lib/licenses','resources/shaders/dice_glow.glsl',
 'scripts/run_lua_tests.py','scripts/tests/test_versioning.py','run_game.cmd',
 '.github/workflows/lua_tests.yml','docs/art_direction.md','docs/farkle_rules.md',
 'docs/project_vision.md','docs/technical.md','docs/versioning.md',
 'docs/windows_technical_qa.md'} do
 assert(exists(path),'missing relocated path: '..path)
end
for _,path in ipairs{'Avvia.cmd','.github/workflows/lua-tests.yml',
} do
 assert(not exists(path),'old filename still present: '..path)
end
local doc_listing=assert(io.popen(windows and 'dir /b docs' or "find docs -maxdepth 1 -type f -printf '%f\\n'"))
local expected_docs={
 ['README.md']=true,['art_direction.md']=true,['farkle_rules.md']=true,
 ['project_vision.md']=true,['technical.md']=true,['versioning.md']=true,
 ['windows_technical_qa.md']=true,
}
local doc_count=0
for name in doc_listing:lines() do
 assert(expected_docs[name],'unexpected document filename: '..name)
 expected_docs[name]=nil
 doc_count=doc_count+1
end
assert(doc_listing:close(),'cannot enumerate documentation files')
assert(doc_count==7 and next(expected_docs)==nil,'documentation names must remain lowercase snake_case')
local root_tests=assert(io.popen(windows and 'dir /b tests\\*_test.lua 2>nul' or "find tests -maxdepth 1 -name '*_test.lua'"))
local stray=root_tests:read('*a')
root_tests:close()
assert(not stray:find('%S'),'tests must live in an area subfolder: '..stray)

local workflow=assert(io.open('.github/workflows/lua_tests.yml','rb'))
local workflow_source=workflow:read('*a')
workflow:close()
local workflow_paths=0
for path in workflow_source:gmatch('src/[%w_./-]+%.lua') do
 local source=assert(io.open(path,'rb'),'workflow references missing module: '..path)
 source:close()
 workflow_paths=workflow_paths+1
end
assert(workflow_paths>0,'workflow source paths were not checked')

local rules=require('src.farkle.rules')
assert(rules.points==rules.scoring.points and rules.score==rules.scoring.score)
assert(rules.contracts==rules.progress.contracts and type(rules.medals.get)=='function')
local input=require('src.farkle.interaction')
for _,name in ipairs{'shake','single','shaker','group','selection','projection'} do
 assert(type(input[name])=='table','missing interaction section: '..name)
end
local bounds=require('src.engine3d.bounds')
assert(type(bounds.containment.apply)=='function' and type(bounds.fps.footprint)=='function'
 and type(bounds.spawn.place)=='function')
assert(type(require('src.engine3d.roll_resolution').face_state.inspect)=='function')
assert(not package.loaded['lib.g3d'],'GPU library must not load before rendering')
local scene=require('src.engine3d.g3d.scene')
assert(type(scene.shadow)=='function' and type(scene.materials.light)=='table'
 and type(scene.camera.screen)=='function' and type(scene.mesh.face_vertices)=='function')
local renderer=require('src.engine3d.g3d.live')
assert(type(renderer.new)=='function' and type(renderer.portrait.capture)=='function')
assert(not package.loaded['lib.g3d'],'loading scene or portrait must remain GPU-lazy')
local ui=require('src.farkle.ui')
local hud=ui.hud
assert(type(hud.draw)=='function' and type(hud.actions.build)=='function'
 and type(hud.accepted.draw)=='function')
assert(type(ui.overlay.model.build)=='function')
assert(type(ui.layout.modal.validate)=='function')
local fit=ui.text_fit
assert(type(fit.label.fit)=='function' and type(fit.paragraph.fit)=='function')
assert(type(require('src.core.runtime_state').ui.scale)=='function')
assert(type(require('src.core.runtime_state').store.codec.decode)=='function')
assert(type(require('src.core.engine_bridge').roll_events.complete)=='function')
local frontend=require('src.data.frontend_schema')
assert(frontend.menu.assets and frontend.campaign.campaigns and frontend.splash.assets)
assert(require('src.data.dice_schema').tray.main)
local surfaces=require('src.screens.folio_surface')
local menus=require('src.screens.frontend')
assert(menus.menu_surface==surfaces.menu_surface,'frontend must reuse shared surfaces')
for _,name in ipairs{'main_menu','campaign_select','settings'} do
 assert(menus.modules[name]==menus[name] and type(menus[name].draw)=='function')
end
assert(type(surfaces.page_layout.get)=='function' and type(surfaces.miniature_2d.new)=='function')
assert(type(require('src.core.config').dice.load)=='function')
assert(type(require('src.core.config').schema.expect_string)=='function')
assert(type(require('src.core.game_manager').execution_order.register)=='function')
assert(type(require('src.core.engine_bridge').EventBus.new)=='function')
assert(not package.loaded['lib.g3d'],'shared UI and frontend must remain GPU-lazy')
local entry=assert(io.open('main.lua','rb'))
local startup=entry:read('*a');entry:close()
assert(not startup:find('src.core.renderer_lab_boot',1,true)
 and not startup:find('experiments.',1,true),
 'normal startup must not dispatch into unavailable experiment modules')
print('PASS source structure: exactly 29 modules, shared APIs, lazy GPU and isolated startup')
