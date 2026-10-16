-- Launch from the project root: python scripts/run_desk_smoke.py
-- Uses a separate LOVE save identity; never reads/writes the player's saves.
local root = assert(os.getenv("SCRIPTORIUM_TEST_ROOT"), "use scripts/run_desk_smoke.py")
local log = assert(io.open(root .. "/desk-smoke.log", "w"))
local function record(s) log:write(s .. "\n"); log:flush(); print(s) end
function love.errorhandler(err)
    record("FAIL: " .. tostring(err) .. "\n" .. debug.traceback())
    log:close()
    return function() return 1 end
end
record("Source root: " .. root)
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
dofile(root .. "/main.lua")
local S = require("src.features.scriptorium.module")
local Resolution = require("src.core.resolution_manager")
local Layout = require("src.features.scriptorium.page_layout")
local Bridge = require("src.core.engine_bridge")
local Config = require("src.data.scriptorium_module_config")
local load_game, update_game, draw_game = love.load, love.update, love.draw
local elapsed, frames, stage = 0, 0, 0
local screenshot_pending = false
local undo_checked = false
local function check_png_layers()
    local View=require("src.features.scriptorium.desk_view")
    local original=Config.desk_assets
    local pixels=love.image.newImageData(4,4)
    pixels:mapPixel(function() return 0.2,0.4,0.6,1 end)
    pixels:encode("png","desk-layer-fixture.png")
    love.filesystem.write("desk-layer-broken.png","invalid PNG")
    Config.desk_assets={background="desk-layer-fixture.png",desk="desk-layer-broken.png",lectern="not-present.png"}
    View.reload_assets()
    love.graphics.push("all")
    local canvas=love.graphics.newCanvas(8,8)
    love.graphics.setCanvas(canvas)
    love.graphics.origin()
    local rect={x=0,y=0,w=8,h=8}
    local fallbacks=0
    local function fallback() fallbacks=fallbacks+1 end
    assert(View.draw_layer("background",rect,fallback),"real PNG did not load")
    love.graphics.setCanvas()
    local r,g,b=canvas:newImageData():getPixel(4,4)
    assert(math.abs(r-0.2)<0.02 and math.abs(g-0.4)<0.02 and math.abs(b-0.6)<0.02,"PNG layer pixels incorrect")
    assert(not View.draw_layer("desk",rect,fallback),"invalid PNG did not fall back")
    assert(not View.draw_layer("lectern",rect,fallback),"missing PNG did not fall back")
    assert(fallbacks==2)
    love.graphics.pop()
    Config.desk_assets=original
    View.reload_assets()
    record("PASS real PNG pixels and missing/corrupt PNG fallbacks")
end
local function click(r)
    assert(r,"missing clickable control at stage " .. stage)
    local x,y = Resolution.to_screen(r.x+r.w/2,r.y+r.h/2)
    S:mousepressed(x,y,1)
end
local function pick_die()
    local r=Bridge.getDiceTrayRect()
    for y=math.ceil(r.y),math.floor(r.y+r.h),3 do
        for x=math.ceil(r.x),math.floor(r.x+r.w),3 do
            local index=Bridge.pickTrayDie(x,y)
            if index then
                S:mousepressed(x,y,1)
                local die=S:getSelectedDie()
                if die and die.index==index then return true end
            end
        end
    end
    return false
end
local function screenshot(name)
    screenshot_pending=true
    love.graphics.captureScreenshot(function(data)
        local file=assert(io.open(root .. "/" .. name,"wb"))
        file:write(data:encode("png"):getString()); file:close()
        screenshot_pending=false
    end)
end
function love.load()
    load_game()
    math.randomseed(12345)
    love.math.setRandomSeed(12345)
    love.window.setMode(1280,720,{resizable=true,vsync=0})
    love.resize(1280,720)
    require("src.core.navigation").go("scriptorium", {seed=12345})
    record("Loaded desk using isolated identity: " .. love.filesystem.getIdentity())
end
function love.update(dt)
    elapsed=elapsed+dt
    assert(elapsed<90,"smoke test timed out at stage " .. stage .. " state=" .. S.state)
    update_game(math.min(dt,0.05))
end
function love.draw()
    draw_game()
    frames=frames+1
    if frames%8~=0 then return end
    if stage==0 then
        check_png_layers()
        if S.show_run_setup then click(S.ui_hit.setup_start_button) end
        assert(not S.show_run_setup,"parchment setup did not close")
        if S.show_ruling_overlay then click(S.ui_hit.ruling_done_button) end
        stage=1
    elseif stage==1 then
        click(S.ui_hit.roll_button)
        assert(S.state=="rolling","roll click did not roll")
        record("PASS initial roll click")
        stage=2
    elseif stage==2 and S.state=="placing" then
        assert(pick_die(),"3D die not pickable")
        record("PASS initial 3D picking")
        stage=3
    elseif stage==3 then
        assert(#S.ui_hit.dice_chips==0,"desk duplicated the 3D dice as chips")
        -- Select a real rolled die with at least one valid target.
        local hit=S.ui_hit.placement_cells[1]
        if not hit then
            for i=1,#S.dice_results do
                S:setSelectedDie(i)
                local focus=S:buildPlacementFocus()
                if focus and focus.total_legal>0 then return end
            end
            error("seed produced no playable dice")
        end
        click(hit.rect)
        stage=4
    elseif stage==4 then
        if S.palette_picker then click(S.ui_hit.palette_color_buttons[1].rect) end
        assert(S.run.current_folio:getWetCount()==1,"cell click did not queue placement")
        record("PASS cell click / pigment picker / wet placement")
        screenshot("desk-preview.png")
        stage=undo_checked and 5 or 20
    elseif stage==20 then
        local roll_index=S.run.current_folio.wet_buffer[1].source_roll_index
        click(S.ui_hit.wet_buffer_undo_buttons[1] and S.ui_hit.wet_buffer_undo_buttons[1].rect)
        assert(S.run.current_folio:getWetCount()==0,"compact buffer undo failed")
        assert(S:setSelectedDieByRollIndex(roll_index),"undo did not restore original die")
        undo_checked=true
        record("PASS compact buffer undo and die restoration")
        stage=3
    elseif stage==5 then
        click(S.ui_hit.push_all_button)
        assert(S.state=="rolling","reroll click did not roll")
        record("PASS reroll click")
        stage=6
    elseif stage==6 and S.state=="placing" then
        S.message=nil
        love.window.setMode(1000,900,{resizable=true,vsync=0})
        love.resize(1000,900)
        stage=7
    elseif stage==7 then
        assert(pick_die(),"3D picking failed after non-16:9 resize")
        local before=S.selected_die
        S:showMessage("Modal check", "The dice stay behind this overlay", 100)
        stage=8
        record("PASS 3D picking after 1000x900 resize")
        S._smoke_selected=before
    elseif stage==8 then
        screenshot("desk-modal.png")
        S:mousepressed(500,800,1)
        assert(S.message==nil and S.selected_die==S._smoke_selected,"modal leaked a click")
        record("PASS message modal consumes click")
        -- A color popup must consume a click over the tray without selecting it.
        S.palette_picker={element="TEXT",row=1,col=1,options={"ROSSO"},anchor_x=700,anchor_y=160}
        stage=9
    elseif stage==9 then
        local before=S.selected_die
        local tray=Bridge.getDiceTrayRect()
        S:mousepressed(tray.x+tray.w/2,tray.y+tray.h/2,1)
        assert(not S.palette_picker and before==S.selected_die,"popup leaked to tray")
        record("PASS pigment popup consumes outside click")
        love.window.setMode(1920,1080,{resizable=true,vsync=0})
        love.resize(1920,1080)
        stage=10
    elseif stage==10 then
        assert(pick_die(),"3D picking failed after 1920x1080 resize")
        record("PASS 3D picking after 1920x1080 resize")
        screenshot("desk-preview-1080.png")
        stage=13
    elseif stage==13 then
        local hit=S.ui_hit.placement_cells[1]
        if not hit then
            for i=1,#S.dice_results do
                S:setSelectedDie(i)
                local focus=S:buildPlacementFocus()
                if focus and focus.total_legal>0 then return end
            end
            error("no playable die after resize")
        end
        local wet=S.run.current_folio:getWetCount()
        local r=hit.rect
        local x,y=Resolution.to_screen(r.x+r.w+1,r.y+5)
        S:mousepressed(x,y,1)
        assert(S.run.current_folio:getWetCount()==wet and not S.palette_picker,"gap accepted a placement")
        click(r)
        stage=14
    elseif stage==14 then
        if S.palette_picker then click(S.ui_hit.palette_color_buttons[1].rect) end
        assert(S.run.current_folio:getWetCount()==2,"placement after resize failed")
        record("PASS placement and non-clickable gap after resize")
        stage=15
    elseif stage==15 then
        click(S.ui_hit.stop_button)
        assert(S.run.current_folio:getWetCount()==0,"commit click failed")
        record("PASS commit click")
        stage=16
    elseif stage==16 then
        if S.message then S:mousepressed(1,1,1); return end
        assert(S.show_ruling_overlay,"expected ruling modal after commit")
        screenshot("desk-ruling.png")
        S:mousepressed(1,1,1)
        assert(S.show_ruling_overlay,"ruling modal dismissed by background")
        click(S.ui_hit.ruling_done_button)
        assert(not S.show_ruling_overlay,"ruling done click failed")
        record("PASS ruling modal blocks background and closes via its control")
        click(S.ui_hit.system_button)
        stage=22
    elseif stage==22 then
        assert(S.show_system_menu and S.ui_hit.system_settings_button and S.ui_hit.system_main_menu_button
            and S.ui_hit.system_restart_button,"compact system menu lost an action")
        S:mousepressed(1,1,1)
        assert(not S.show_system_menu,"system menu did not consume outside click")
        record("PASS compact system menu actions and dismissal")
        Config.layout_mode="legacy"
        stage=11
    elseif stage==11 then
        assert(S.page_rect and S.ui_hit.placement_cells,"legacy layout failed to draw")
        screenshot("desk-legacy.png")
        record("PASS legacy layout draws")
        stage=12
    elseif stage==12 and not screenshot_pending then
        record("PASS all real LOVE smoke checks")
        log:close()
        love.event.quit(0)
    end
end
