
require("core")
local Physics = require("src.engine3d.physics")
local Geometry = require("src.engine3d.geometry")
local view = require("src.engine3d.view")
local box = Physics.box
local materials = Physics.materials
local d6 = Geometry.d6
local d8 = Geometry.d8
local newD6Body = Geometry.newD6Body
local newD8Body = Geometry.newD8Body

-- Controller is injected by the canonical root entry; no legacy module alias.
local Scriptorium = assert(..., "A dice game controller is required")
local PageLayout = require("src.features.scriptorium.page_layout")
local SettingsState = require("src.core.settings_state")
local AudioManager = require("src.core.audio_manager")
local Logger = require("src.core.logger")
local DiceConfig = require("src.core.dice_config")
local TrayLayout = require("src.data.tray_layout")
local RuntimeUI = require("src.core.runtime_ui")
local RuntimeState = require("src.core.runtime_state")
local ResolutionManager = require("src.core.resolution_manager")
local GameManager = require("src.core.game_manager")
local Navigation = require("src.core.navigation")
local EngineBridge = require("src.core.engine_bridge")
local ExecutionOrder = require("src.core.execution_order")

-- g3d is the sole 3D renderer for the six D6, tray and all F8 variants.
-- No F9 alternate painter and no silent fallback on graphics errors.
local live_g3d = require('src.engine3d.g3d_live').new()
local material_notice_until = 0

local game_manager = nil
local app_events = nil

local rollAllDice
local checkDiceSettled
local physicalResolution
local manual_session=nil
local RollResolution = require('src.engine3d.roll_resolution')
local MouseThrow = require('src.features.farkle.mouse_throw')
local onDiceSettled
local readDiceValues
local readDieFace
local DICE_CONFIG = DiceConfig.load()
local DICE_BOARD_IMAGE_PATH = DICE_CONFIG.board_image_path

dice = {}
local DICE_SIZE_SCHEMA = DICE_CONFIG.sizes
local DICE_POOL_SCHEMA = DICE_CONFIG.pool
local DICE_SPAWN_LAYOUT_SCHEMA = DICE_CONFIG.spawn_layout
local DICE_INITIAL_STATE_SCHEMA = DICE_CONFIG.initial_state
local DICE_REGION_SPAWN_SCHEMA = DICE_CONFIG.region_spawn
local DICE_THROW_SCHEMA = DICE_CONFIG.throw
local DICE_AUDIO_SCHEMA = DICE_CONFIG.audio
local DICE_VISUAL_PROTOTYPE_SCHEMA = DICE_CONFIG.visual.prototypes
local DICE_VISUAL_FACE_SCHEMA = DICE_CONFIG.visual.face_colors

local DICE_SIZE_BASE = DICE_SIZE_SCHEMA.base
local DICE_SIZE_MIN = DICE_SIZE_SCHEMA.min
local DICE_SIZE_SCALE_REFERENCE_COUNT = DICE_SIZE_SCHEMA.scale_reference_dice_count
local DICE_SPAWN_ROW_OFFSET = DICE_SPAWN_LAYOUT_SCHEMA.row_offset
local DICE_SPAWN_ROW_CLAMP_INSET = DICE_SPAWN_LAYOUT_SCHEMA.row_clamp_inset
local DICE_SPAWN_X_INSET = DICE_SPAWN_LAYOUT_SCHEMA.x_inset
local DICE_SPAWN_MAIN_SCHEMA = DICE_SPAWN_LAYOUT_SCHEMA.main
local DICE_SPAWN_MINI_SCHEMA = DICE_SPAWN_LAYOUT_SCHEMA.mini
local DICE_SPAWN_MAIN_COLS = DICE_SPAWN_MAIN_SCHEMA.cols
local DICE_SPAWN_MINI_COLS = DICE_SPAWN_MINI_SCHEMA.cols
local DICE_SPAWN_MAIN_ROW_SPACING = DICE_SPAWN_MAIN_SCHEMA.row_spacing
local DICE_SPAWN_MINI_ROW_SPACING = DICE_SPAWN_MINI_SCHEMA.row_spacing
local DICE_INITIAL_POSITION_Z = DICE_INITIAL_STATE_SCHEMA.position_z
local DICE_INITIAL_VELOCITY_EVEN = DICE_INITIAL_STATE_SCHEMA.velocity_even
local DICE_INITIAL_VELOCITY_ODD = DICE_INITIAL_STATE_SCHEMA.velocity_odd
local DICE_INITIAL_SPIN = DICE_INITIAL_STATE_SCHEMA.spin
local DICE_REGION_SPAWN_INSET_Y = DICE_REGION_SPAWN_SCHEMA.inset_y
local DICE_REGION_SPAWN_SIDE_WALL_INSET_MAX = DICE_REGION_SPAWN_SCHEMA.side_wall_inset_max
local DICE_REGION_SPAWN_CENTER_INSET = DICE_REGION_SPAWN_SCHEMA.center_inset
local DICE_THROW_RZ_BASE = DICE_THROW_SCHEMA.rz_base
local DICE_THROW_RZ_RANDOM = DICE_THROW_SCHEMA.rz_random
local DICE_THROW_VERTICAL_BASE = DICE_THROW_SCHEMA.vertical_base
local DICE_THROW_VERTICAL_RANDOM = DICE_THROW_SCHEMA.vertical_random
local DICE_THROW_LATERAL_MULT_BASE = DICE_THROW_SCHEMA.lateral_mult_base
local DICE_THROW_LATERAL_MULT_RANDOM = DICE_THROW_SCHEMA.lateral_mult_random
local DICE_THROW_JITTER = DICE_THROW_SCHEMA.jitter
local DICE_THROW_ANGULAR_MAX = DICE_THROW_SCHEMA.angular_max
local DICE_THROW_NOISE = DICE_THROW_SCHEMA.noise
local DICE_THROW_NOISE_Z_MULT = DICE_THROW_SCHEMA.noise_z_mult
local DICE_ROLL_CONFIRM_SFX = DICE_AUDIO_SCHEMA.roll_confirm
local DICE_SETTLED_SFX = DICE_AUDIO_SCHEMA.settled

local DICE_TEMPLATE_BY_KIND = {
    d6 = {template = d6, body_factory = newD6Body, sides = 6},
    d8 = {template = d8, body_factory = newD8Body, sides = 8},
}

local function build_dice_pool()
    local pool = {}
    for _, entry in ipairs(DICE_POOL_SCHEMA) do
        local kind_spec = DICE_TEMPLATE_BY_KIND[entry.kind]
        if not kind_spec then
            error("Unsupported dice kind in pool schema: " .. tostring(entry.kind))
        end
        pool[#pool + 1] = {
            kind = entry.kind,
            count = entry.count,
            sides = entry.sides,
            template = kind_spec.template,
            body_factory = kind_spec.body_factory,
        }
    end
    return pool
end

local DICE_POOL = build_dice_pool()

local function get_total_dice_count()
    local total = 0
    for _, spec in ipairs(DICE_POOL) do
        total = total + math.max(0, math.floor(spec.count or 0))
    end
    return total
end

local D6_PROTO_COLOR = DICE_VISUAL_PROTOTYPE_SCHEMA.d6_color
local D6_PROTO_TEXT = DICE_VISUAL_PROTOTYPE_SCHEMA.d6_text
local D8_PROTO_COLOR = DICE_VISUAL_PROTOTYPE_SCHEMA.d8_color
local D8_PROTO_TEXT = DICE_VISUAL_PROTOTYPE_SCHEMA.d8_text
local D6_BLACK_FACE_COLOR = DICE_VISUAL_FACE_SCHEMA.d6_black
local D8_FACE_COLORS = DICE_VISUAL_FACE_SCHEMA.d8_cycle

local function build_face_colors(spec, face_count)
    if not spec then
        return nil
    end
    if spec.kind == "d8" then
        local colors = {}
        local n = #D8_FACE_COLORS
        for face_idx = 1, face_count do
            local src = D8_FACE_COLORS[((face_idx - 1) % n) + 1]
            colors[face_idx] = {src[1], src[2], src[3], src[4]}
        end
        return colors
    end
    if spec.kind ~= "d6" then
        return nil
    end
    local colors = {}
    for face_idx = 1, face_count do
        local src = D6_BLACK_FACE_COLOR
        colors[face_idx] = {src[1], src[2], src[3], src[4]}
    end
    return colors
end

local diceSettled = false
local diceSettledTimer = 0
local SETTLE_DELAY = DICE_CONFIG.settle_delay
local last_roll_indices = nil
local tray_die_hits = {}

local fps_font = nil
local fps_font_size = 0
local last_frame_present = nil

local MAIN_TRAY_LAYOUT = TrayLayout.main
local TRAY_LAYOUT_SHARED = TrayLayout.shared

local DICE_OVERLAY_SCALE_MULT = TrayLayout.overlay.scale_mult
local DICE_OVERLAY_CENTER_Y = TrayLayout.overlay.center_y

local DICE_SCENE_CAMERA_SCHEMA = DICE_CONFIG.scene.camera
local DICE_SCENE_BOX_SCHEMA = DICE_CONFIG.scene.box
local DICE_SCENE_REGION_SCHEMA = DICE_CONFIG.scene.regions

local TRAY_CAMERA_LOCKED = DICE_SCENE_CAMERA_SCHEMA.locked
local TRAY_CAMERA = {
    yaw = DICE_SCENE_CAMERA_SCHEMA.yaw,
    pitch = DICE_SCENE_CAMERA_SCHEMA.pitch,
    distance = DICE_SCENE_CAMERA_SCHEMA.distance,
}

local DICE_BOX_HALF_X = DICE_SCENE_BOX_SCHEMA.half_x
local DICE_BOX_HALF_Y = DICE_SCENE_BOX_SCHEMA.half_y
local DICE_BOX_HEIGHT = DICE_SCENE_BOX_SCHEMA.height
local DICE_BOX_LINEAR_DAMPING = DICE_SCENE_BOX_SCHEMA.linear_damping
local DICE_BOX_ANGULAR_DAMPING = DICE_SCENE_BOX_SCHEMA.angular_damping
local DICE_BOX_BORDER_HEIGHT = DICE_SCENE_BOX_SCHEMA.border_height

local D6_REGION_RATIO = DICE_SCENE_REGION_SCHEMA.d6_ratio
local DICE_REGIONS = DICE_SCENE_REGION_SCHEMA

local function clamp(v, min_v, max_v)
    if v < min_v then return min_v end
    if v > max_v then return max_v end
    return v
end

local last_mouse_x = nil
local last_mouse_y = nil

local function get_mouse_delta()
    local delta_fn = (love and love.mouse) and rawget(love.mouse, "delta") or nil
    if type(delta_fn) == "function" then
        return delta_fn()
    end
    if not (love and love.mouse and love.mouse.getPosition) then
        return 0, 0
    end
    local mx, my = love.mouse.getPosition()
    if last_mouse_x == nil or last_mouse_y == nil then
        last_mouse_x, last_mouse_y = mx, my
        return 0, 0
    end
    local dx, dy = mx - last_mouse_x, my - last_mouse_y
    last_mouse_x, last_mouse_y = mx, my
    return dx, dy
end

local function apply_tray_camera_lock()
    view.yaw = TRAY_CAMERA.yaw
    view.pitch = TRAY_CAMERA.pitch
    view.distance = TRAY_CAMERA.distance
    view.cos_pitch, view.sin_pitch = math.cos(view.pitch), math.sin(view.pitch)
    view.cos_yaw, view.sin_yaw = math.cos(view.yaw), math.sin(view.yaw)
end

local function with_view_yaw_offset(offset_rad, fn)
    if not offset_rad or offset_rad == 0 then
        fn()
        return
    end

    local old_yaw = view.yaw
    local old_cos_yaw = view.cos_yaw
    local old_sin_yaw = view.sin_yaw

    view.yaw = old_yaw + offset_rad
    view.cos_yaw, view.sin_yaw = math.cos(view.yaw), math.sin(view.yaw)

    local ok, err = pcall(fn)

    view.yaw = old_yaw
    view.cos_yaw, view.sin_yaw = old_cos_yaw, old_sin_yaw

    if not ok then
        error(err)
    end
end

local function get_tray_rects(window_w, window_h)
    if Scriptorium.getTrayRect and Scriptorium:isDeskLayout() then
        return Scriptorium:getTrayRect()
    end
    if Scriptorium:isDeskLayout() then
        return PageLayout.screen_tray(ResolutionManager)
    end
    local tray_w = clamp(window_w * MAIN_TRAY_LAYOUT.width_ratio, MAIN_TRAY_LAYOUT.min_width, MAIN_TRAY_LAYOUT.max_width)
    local tray_h = clamp(window_h * MAIN_TRAY_LAYOUT.height_ratio, MAIN_TRAY_LAYOUT.min_height, MAIN_TRAY_LAYOUT.max_height)

    return {
        x = (window_w - tray_w) * 0.5,
        y = window_h - tray_h - TRAY_LAYOUT_SHARED.bottom_margin,
        w = tray_w,
        h = tray_h,
    }
end

local function get_dice_tray_rect()
    local w, h = love.graphics.getDimensions()
    local tray = get_tray_rects(w, h)
    return tray
end

local function get_tray_floor_polygon(tray, tray_layout)
    tray_layout = tray_layout or MAIN_TRAY_LAYOUT
    local cx = tray.x + tray.w * 0.5
    local top_y = tray.y + tray.h * tray_layout.floor_top_ratio
    local bottom_y = tray.y + tray.h * tray_layout.floor_bottom_ratio
    local top_half = (tray.w * tray_layout.floor_top_width_ratio) * 0.5
    local bottom_half = (tray.w * tray_layout.floor_bottom_width_ratio) * 0.5
    local poly = {
        cx - top_half, top_y,
        cx + top_half, top_y,
        cx + bottom_half, bottom_y,
        cx - bottom_half, bottom_y,
    }

    local rotation_deg = tray_layout.overlay_rotation_deg or 0
    if rotation_deg ~= 0 then
        local pivot_y = tray.y + tray.h * (tray_layout.overlay_center_y or DICE_OVERLAY_CENTER_Y)
        local angle = math.rad(rotation_deg)
        local cos_a, sin_a = math.cos(angle), math.sin(angle)
        for i = 1, #poly, 2 do
            local dx = poly[i] - cx
            local dy = poly[i + 1] - pivot_y
            poly[i] = cx + dx * cos_a - dy * sin_a
            poly[i + 1] = pivot_y + dx * sin_a + dy * cos_a
        end
    end

    return poly
end

local function get_base_region(region)
    if region and type(region.parent) == "string" then
        local parent = DICE_REGIONS[region.parent]
        if parent then
            return parent
        end
    end
    return region
end

local function get_region_full_x_bounds_at_y(base_region, y)
    local t = (y - base_region.y_back) / (base_region.y_front - base_region.y_back)
    t = clamp(t, 0, 1)
    local half_w = base_region.half_back + (base_region.half_front - base_region.half_back) * t
    local cx = base_region.x_center or 0
    return cx - half_w, cx + half_w
end

-- A split D6/D8 board is a deliberate special mode, not the default.
-- Previously nil ~= false implicitly enabled a 2/3 invisible D6 lane
-- while the player saw a single full-width parchment tray.
local function is_tray_divided()
    return Scriptorium.tray_divided == true
end

local function get_region_x_bounds_at_y(region, y)
    local base_region = get_base_region(region)
    if not base_region then
        return -1, 1
    end

    local left_x, right_x = get_region_full_x_bounds_at_y(base_region, y)
    local slot = region and region.slot or nil
    if is_tray_divided() and (slot == "main" or slot == "mini") then
        local split_x = left_x + (right_x - left_x) * D6_REGION_RATIO
        if slot == "main" then
            right_x = split_x
        else
            left_x = split_x
        end
    end

    return left_x, right_x
end

local function get_region_center_at_y(region, y)
    local left_x, right_x = get_region_x_bounds_at_y(region, y)
    return (left_x + right_x) * 0.5
end

local function get_region_divider_x_at_y(region, y)
    local base_region = get_base_region(region)
    local left_x, right_x = get_region_full_x_bounds_at_y(base_region, y)
    return left_x + (right_x - left_x) * D6_REGION_RATIO
end

local function get_region_for_die(die_entry)
    if die_entry and die_entry.kind == "d8" then
        return DICE_REGIONS.mini
    end
    return DICE_REGIONS.main
end

local function is_scriptorium_active()
    return game_manager ~= nil and game_manager.current == Scriptorium
end

local function get_world_extents_for_region(region)
    local base_region = get_base_region(region)
    local y_back = base_region.y_back
    local y_front = base_region.y_front
    local back_left, back_right = get_region_x_bounds_at_y(region, y_back)
    local front_left, front_right = get_region_x_bounds_at_y(region, y_front)

    return {
        math.min(back_left, front_left),
        math.max(back_right, front_right),
        y_back,
        y_front,
    }
end

local function constrain_dice_to_regions()
    if not is_scriptorium_active() then
        return
    end
    if not dice or #dice == 0 then
        return
    end

    for i = 1, #dice do
        local die_entry = dice[i]
        local body = die_entry and die_entry.body or nil
        if body and body.position and body.velocity and not die_entry.kept and not body._manual_pending then
            local region = get_region_for_die(die_entry)
            local base_region = get_base_region(region)
            local y_min = base_region.y_back
            local y_max = base_region.y_front
            local bounce = region.bounce or base_region.bounce or 0.34
            local slide_damping = region.slide_damping or base_region.slide_damping or 0.90
            local radius_scale = (die_entry and die_entry.kind == "d8") and 0.62 or 0.50
            local radius = math.max(0.15, (body.radius or 0.4) * radius_scale)

            local px = body.position[1]
            local py = body.position[2]
            local vx = body.velocity[1]
            local vy = body.velocity[2]
            local corrected = false

            local min_y = y_min + radius
            local max_y = y_max - radius

            if py < min_y then
                py = min_y
                if vy < 0 then
                    vy = -vy * bounce
                end
                vx = vx * slide_damping
                corrected = true
            elseif py > max_y then
                py = max_y
                if vy > 0 then
                    vy = -vy * bounce
                end
                vx = vx * slide_damping
                corrected = true
            end

            local left_x, right_x = get_region_x_bounds_at_y(region, py)
            local min_x = left_x + radius
            local max_x = right_x - radius
            if max_x < min_x then
                local mid_x = (left_x + right_x) * 0.5
                min_x = mid_x
                max_x = mid_x
            end

            if px > max_x then
                px = max_x
                if vx > 0 then
                    vx = -vx * bounce
                end
                vy = vy * slide_damping
                corrected = true
            elseif px < min_x then
                px = min_x
                if vx < 0 then
                    vx = -vx * bounce
                end
                vy = vy * slide_damping
                corrected = true
            end

            if corrected then
                -- Legacy safety region, not a collision with the visible rim.
                -- A sub-contact-scale correction must not restart the sleep clock.
                require('src.engine3d.containment').apply(body,px,py,vx,vy,body._supported)
            end
        end
    end
end

local function get_usable_dice_map()
    local usable = {}
    if not is_scriptorium_active() then
        return usable
    end
    if type(Scriptorium.dice_results) ~= "table" then
        return usable
    end
    for _, die_state in ipairs(Scriptorium.dice_results) do
        local idx = tonumber(die_state and die_state.index)
        if idx then
            idx = math.floor(idx)
            if idx >= 1 and idx <= #dice and (not die_state.used) and (not die_state.unusable) then
                usable[idx] = true
            end
        end
    end

    local selected_chip = tonumber(Scriptorium.selected_die)
    if selected_chip then
        selected_chip = math.floor(selected_chip)
        local selected_state = Scriptorium.dice_results[selected_chip]
        local selected_idx = tonumber(selected_state and selected_state.index)
        if selected_idx then
            selected_idx = math.floor(selected_idx)
            if selected_idx >= 1 and selected_idx <= #dice and (not selected_state.used) then
                usable[selected_idx] = true
            end
        end
    end

    return usable
end

local function pick_tray_die_at_screen(x, y)
    if not tray_die_hits or #tray_die_hits <= 0 then
        return nil
    end
    local mx = tonumber(x)
    local my = tonumber(y)
    if not mx or not my then
        return nil
    end

    local best = nil
    local best_score = nil
    for _, hit in ipairs(tray_die_hits) do
        local dx = mx - hit.x
        local dy = my - hit.y
        local dist2 = dx * dx + dy * dy
        local r = math.max(1, hit.r or 1)
        local r2 = r * r
        if dist2 <= r2 then
            local score = dist2 / r2
            if (not best) or score < best_score or (score == best_score and (hit.depth or -math.huge) > (best.depth or -math.huge)) then
                best = hit
                best_score = score
            end
        end
    end
    return best and best.index or nil
end

local function draw_single_tray(tray, tray_layout, region, die_predicate, usable_map, glow_enabled, collect_hits, draw_divider)
    if not tray or not region then
        return
    end

    local tray_floor_poly = get_tray_floor_polygon(tray, tray_layout)
    local world_extents = get_world_extents_for_region(region)
    local old_pitch, old_cos_pitch, old_sin_pitch = view.pitch, view.cos_pitch, view.sin_pitch
    local old_projection = view.projection
    local fitted_x, fitted_y, fitted_scale
    if Scriptorium.getTrayProjection then
        fitted_x, fitted_y, fitted_scale = Scriptorium:getTrayProjection(tray, view, world_extents)
    end
    local draw_offset_x = region.x_center or 0

    local function with_draw_offset(body, fn)
        if (not body) or draw_offset_x == 0 then
            fn()
            return
        end
        local old_x = body.position and body.position[1] or 0
        body.position[1] = old_x - draw_offset_x
        fn()
        body.position[1] = old_x
    end

    love.graphics.setScissor(
        math.floor(tray.x),
        math.floor(tray.y),
        math.ceil(tray.w),
        math.ceil(tray.h)
    )
    if not fitted_scale and love.graphics.stencil and love.graphics.setStencilTest then
        if love.graphics.setColorMask then
            love.graphics.setColorMask(false, false, false, false)
        end
        love.graphics.stencil(function()
            love.graphics.polygon("fill", unpack(tray_floor_poly))
        end, "replace", 1)
        if love.graphics.setColorMask then
            love.graphics.setColorMask(true, true, true, true)
        end
        love.graphics.setStencilTest("greater", 0)
    end

    love.graphics.push()
    local cx = tray.x + tray.w * 0.5
    local cy = tray.y + tray.h * (tray_layout.overlay_center_y or DICE_OVERLAY_CENTER_Y)
    local scale_mult = tray_layout.overlay_scale_mult or DICE_OVERLAY_SCALE_MULT
    local scale = math.max(1, (math.min(tray.w * 0.5, tray.h * 0.5) / 4) * scale_mult)
    if fitted_scale then cx, cy, scale = fitted_x, fitted_y, fitted_scale end
    love.graphics.translate(cx, cy)
    love.graphics.scale(scale)

    local rotation_rad = math.rad(tray_layout.overlay_rotation_deg or 0)
    with_view_yaw_offset(rotation_rad, function()
        -- The 3D floor, walls, dividers, shadows and physical D6 belong
        -- exclusively to g3d. The CPU painter has been retired.
        local x1, x2, y1, y2 = world_extents[1], world_extents[2], world_extents[3], world_extents[4]
        local gpu_candidates = {}
        local gpu_style = require('src.features.farkle.tray_workshop').current
        local gpu_divider = nil
        if draw_divider then
            local inset = math.max(0, tonumber(tray_layout.divider_y_inset) or 0)
            local back_y,front_y = y1+inset,y2-inset
            if front_y <= back_y then back_y,front_y=y1,y2 end
            gpu_divider = {
                back_x=get_region_divider_x_at_y(region,back_y),
                front_x=get_region_divider_x_at_y(region,front_y),
                back_y=back_y,front_y=front_y,
                width=tray_layout.divider_half_width or 0.13,
                height=math.max(tray_layout.divider_height_min or .24,
                    (box.border_height or .74)*(tray_layout.divider_height_scale or .88))
            }
        end
        for i = 1, #dice do
            local die_entry = dice[i]
            if die_predicate(die_entry, i) then
                with_draw_offset(die_entry.body, function()
                    if collect_hits and die_entry.body and die_entry.body.position then
                        local bx = die_entry.body.position[1]
                        local by = die_entry.body.position[2]
                        local bz = die_entry.body.position[3] or 0
                        local px, py, depth = view.project(bx, by, bz)
                        local radius_world = math.max(0.20, (die_entry.body.radius or 0.38) * 0.90)
                        local pxr, pyr = view.project(bx + radius_world, by, bz)
                        local radius_screen = math.max(10, math.sqrt((pxr - px) * (pxr - px) + (pyr - py) * (pyr - py)) * scale * 1.55)
                        local sx = cx + px * scale
                        local sy = cy + py * scale
                        if sx >= tray.x and sx <= (tray.x + tray.w) and sy >= tray.y and sy <= (tray.y + tray.h) then
                            tray_die_hits[#tray_die_hits + 1] = {
                                index = i,
                                x = sx,
                                y = sy,
                                r = radius_screen,
                                depth = depth or -math.huge,
                            }
                        end
                    end

                end)
                gpu_candidates[#gpu_candidates + 1] = {index=i, entry=die_entry}
            end
        end

        assert(live_g3d:draw({
            entries=gpu_candidates, view=view,
            extents=world_extents, height=box.border_height or 1.1,
            style=gpu_style,divider=gpu_divider,
            offset=draw_offset_x,
            viewport=tray,cx=cx,cy=cy,scale=scale,
            usable=glow_enabled and usable_map or nil,
            mask=not fitted_scale and true or false,
        }), 'g3d tray failed to render')
    end)
    love.graphics.pop()

    if love.graphics.setStencilTest then
        love.graphics.setStencilTest()
    end
    love.graphics.setScissor()
    view.pitch, view.cos_pitch, view.sin_pitch = old_pitch, old_cos_pitch, old_sin_pitch
    view.projection = old_projection
end

local function draw_dice_tray_overlay()
    tray_die_hits = {}
    if not is_scriptorium_active() then
        return
    end
    if not dice or #dice == 0 then
        return
    end

    love.graphics.origin()
    love.graphics.setBlendMode("alpha")
    if love.graphics.setShader then
        love.graphics.setShader()
    end
    if love.graphics.setCanvas then
        love.graphics.setCanvas()
    end
    if love.graphics.setColorMask then
        love.graphics.setColorMask(true, true, true, true)
    end

    local w, h = love.graphics.getDimensions()
    local tray = get_tray_rects(w, h)
    local usable_map = get_usable_dice_map()

    draw_single_tray(
        tray,
        MAIN_TRAY_LAYOUT,
        DICE_REGIONS.unified,
        function(die_entry, index)
            return die_entry ~= nil and (not Scriptorium.shouldDrawTrayDie or Scriptorium:shouldDrawTrayDie(index))
        end,
        usable_map,
        true,
        true,
        is_tray_divided()
    )

    love.graphics.setScissor()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha")
end

local function configure_dice_box()
    box:configure(DICE_SCENE_BOX_SCHEMA)
    box.after_step = function(_,dt)
        constrain_dice_to_regions()
        if physicalResolution then checkDiceSettled(dt) end
    end
end

local function initial_position_for_slot(slot, slot_index)
    local region = (slot == "mini") and DICE_REGIONS.mini or DICE_REGIONS.main
    local cols = (slot == "mini") and DICE_SPAWN_MINI_COLS or DICE_SPAWN_MAIN_COLS
    local row_spacing = (slot == "mini") and DICE_SPAWN_MINI_ROW_SPACING or DICE_SPAWN_MAIN_ROW_SPACING
    local row = math.floor((slot_index - 1) / cols) + DICE_SPAWN_ROW_OFFSET
    local sy = row * row_spacing

    local base_region = get_base_region(region)
    sy = clamp(sy, base_region.y_back + DICE_SPAWN_ROW_CLAMP_INSET, base_region.y_front - DICE_SPAWN_ROW_CLAMP_INSET)

    local left_x, right_x = get_region_x_bounds_at_y(region, sy)
    local safe_left = left_x + DICE_SPAWN_X_INSET
    local safe_right = right_x - DICE_SPAWN_X_INSET
    if safe_right < safe_left then
        local mid = (left_x + right_x) * 0.5
        safe_left = mid
        safe_right = mid
    end

    local col = (slot_index - 1) % cols
    local t = (cols > 1) and (col / (cols - 1)) or 0.5
    local sx = safe_left + (safe_right - safe_left) * t
    return sx, sy, side
end

local function spawn_initial_dice()
    local total_dice = get_total_dice_count()
    local spawn_dice_size = DICE_SIZE_BASE
    if total_dice > DICE_SIZE_SCALE_REFERENCE_COUNT then
        local scale = math.sqrt(DICE_SIZE_SCALE_REFERENCE_COUNT / total_dice)
        spawn_dice_size = math.max(DICE_SIZE_MIN, math.min(DICE_SIZE_BASE, DICE_SIZE_BASE * scale))
    end
    local die_index = 0
    local main_slot_index = 0
    local mini_slot_index = 0

    for _, spec in ipairs(DICE_POOL) do
        local die_template = spec.template or d6
        local body_factory = spec.body_factory or newD6Body
        local faces = die_template.faces or {}
        local count = math.max(0, math.floor(spec.count or 0))

        for _ = 1, count do
            die_index = die_index + 1
            local tray_slot = (spec.kind == "d8") and "mini" or "main"
            if tray_slot == "mini" then
                mini_slot_index = mini_slot_index + 1
            else
                main_slot_index = main_slot_index + 1
            end
            local slot_idx = (tray_slot == "mini") and mini_slot_index or main_slot_index
            local sx, sy = initial_position_for_slot(tray_slot, slot_idx)

            local faceColors = build_face_colors(spec, #faces)
            local is_d8 = (spec.kind == "d8")
            local die_color = is_d8 and D8_PROTO_COLOR or D6_PROTO_COLOR
            local die_text = is_d8 and D8_PROTO_TEXT or D6_PROTO_TEXT

            dice[die_index] = {
                body = body_factory(spawn_dice_size):set(
                    {sx, sy, DICE_INITIAL_POSITION_Z},
                    (die_index % 2 == 0)
                        and {DICE_INITIAL_VELOCITY_EVEN[1], DICE_INITIAL_VELOCITY_EVEN[2], DICE_INITIAL_VELOCITY_EVEN[3]}
                        or {DICE_INITIAL_VELOCITY_ODD[1], DICE_INITIAL_VELOCITY_ODD[2], DICE_INITIAL_VELOCITY_ODD[3]},
                    {DICE_INITIAL_SPIN[1], DICE_INITIAL_SPIN[2], DICE_INITIAL_SPIN[3]}
                ),
                die = clone(die_template, {
                    faceColors = faceColors,
                    color = die_color,
                    text = die_text,
                    shadow = {20, 0, 0, 150}
                }),
                kind = spec.kind or "d6",
                sides = math.max(2, math.floor(spec.sides or 6)),
                tray_slot = tray_slot,
                kept = false,
                value = nil,
            }

            materials.apply(dice[die_index].body, materials.get("bone"))
            box[die_index] = dice[die_index].body
        end
    end
end

local function seed_rng()
    -- Optional reproducible *logical input* seed for diagnostics. The
    -- physical solver is not guaranteed bitwise deterministic across GPUs.
    local requested = os.getenv and tonumber(os.getenv("MANUSCRIPT_SEED"))
    local seed = os.time()
    if requested and requested == requested and requested % 1 == 0
        and requested >= 1 and requested <= 2147483647 then
        seed = requested
    end
    math.randomseed(seed)
    if love.math then
        love.math.setRandomSeed(seed)
    end
    return seed
end

local function initialize_runtime()
    SettingsState.load()
    SettingsState.apply()
    ResolutionManager.init(1920, 1080)

    EngineBridge.configure({
        get_dice_tray_rect = get_dice_tray_rect,
        get_tray_die_hits = function() return tray_die_hits end,
        pick_scriptorium_tray_die = pick_tray_die_at_screen,
        to_virtual_ui = function(x, y)
            return ResolutionManager.to_virtual(x, y)
        end,
        to_screen_ui = function(x, y)
            return ResolutionManager.to_screen(x, y)
        end,
    })

    if love.graphics then
        local desired_fps_size = RuntimeUI.sized(14)
        local ok, font = pcall(function()
            return love.graphics.newFont(desired_fps_size)
        end)
        fps_font = ok and font or love.graphics.getFont()
        fps_font_size = desired_fps_size
    end
    if love.timer then
        last_frame_present = love.timer.getTime()
    end

    apply_tray_camera_lock()
end

local function setup_game_manager()
    game_manager = GameManager.new({
        metadata = {
            app = "manuscript-farkle-roguelite",
        },
    })
    app_events = game_manager:get_event_bus()
    EngineBridge.set_event_bus(app_events)
    game_manager:get_context().services = {
        engine_bridge = EngineBridge,
        events = app_events,
        resolution = ResolutionManager,
        audio = AudioManager,
        runtime_ui = RuntimeUI,
    }

    game_manager:register("scriptorium", Scriptorium)
    for _, name in ipairs({"startup_splash", "main_menu", "campaign_select", "settings"}) do
        game_manager:register(name, require("src.features." .. name .. ".module"))
    end
end

local function register_execution_order_hooks()
    ExecutionOrder.register(game_manager, {
        resolution_refresh = function()
            ResolutionManager.refresh()
        end,
        physics_step = function(dt)
            -- Freeze the physics integration and settle timer outside the
            -- manuscript. Do not accumulate an off-screen catch-up backlog.
            if is_scriptorium_active() then
                box:update(dt)
            else
                box.timeleft=0
            end
        end,
        dice_constrain_regions = function()
            -- Physical constraints now run in box.after_step, never per frame.
        end,
        dice_settle_check = function(dt)
            if is_scriptorium_active() and not physicalResolution then
                checkDiceSettled(dt)
            end
        end,
        tray_camera_control = function()
            if TRAY_CAMERA_LOCKED then
                apply_tray_camera_lock()
            else
                local dx, dy = get_mouse_delta()
                if love.mouse.isDown(2) then
                    view.raise(dy / 100)
                    view.turn(dx / 100)
                end
            end
        end,
        tray_overlay = function()
            draw_dice_tray_overlay()
            if is_scriptorium_active() then
                Scriptorium:drawDeskOverlays(tray_die_hits)
            end
        end,
    })
end

local function configure_navigation()
    local function route_to(name, params)
        return game_manager:switch(name, params)
    end

    Navigation.configure(route_to)
end

-- One logical Farkle roll can consist of several separate real die throws.
-- Score resolution is held until EVERY active physical die has been released.
local function begin_manual_roll(indices)
    assert(not manual_session,'a second physical manual session was requested')
    local pending={}
    for _,i in ipairs(indices) do pending[i]=true end
    manual_session={pending=pending,count=#indices}
    last_roll_indices={}
    for _,i in ipairs(indices) do last_roll_indices[#last_roll_indices+1]=i end
    physicalResolution=RollResolution.new(last_roll_indices)
    Scriptorium.physicalResolution=physicalResolution
    Scriptorium.physicalNotice=nil
    Scriptorium.physicalFailure=nil
    diceSettled=false
    diceSettledTimer=0
    for _,i in ipairs(indices) do
        local body=dice[i].body
        body._manual_pending=true
        body._grabbed=false
        body.asleep=true
        body.sleep_timer=0
        body.velocity[1],body.velocity[2],body.velocity[3]=0,0,0
        body.angular[1],body.angular[2],body.angular[3]=0,0,0
    end
    EngineBridge.emit('dice.roll_started',{
        count=#indices,indices=last_roll_indices,
        logical_roll_id=Scriptorium.logicalRollId,
        physical_attempt_id=Scriptorium.physicalAttemptId,
        manual=true
    })
end

local function release_manual_die(index)
    if not manual_session or not manual_session.pending[index] then return false end
    assert(not dice[index].body._manual_pending,'release must activate physical die')
    manual_session.pending[index]=nil
    manual_session.count=manual_session.count-1
    EngineBridge.emit('dice.manual_die_released',{
        index=index,remaining=manual_session.count,
        logical_roll_id=Scriptorium.logicalRollId
    })
    if manual_session.count==0 then manual_session=nil end
    return true
end

---@diagnostic disable: duplicate-set-field
function love.load()
    configure_dice_box()
    spawn_initial_dice()
    Scriptorium.sessionSeed=seed_rng()
    initialize_runtime()
    setup_game_manager()
    register_execution_order_hooks()
    configure_navigation()
    Scriptorium.onRollRequest = function(max_dice, roll_indices, technical, gesture)
        rollAllDice(max_dice, roll_indices, false, technical, gesture)
    end
    Scriptorium.onManualRollBegin=begin_manual_roll
    Scriptorium.onManualRollRelease=release_manual_die
end

function love.resize(w, h)
    ResolutionManager.refresh(w, h)
    -- Projected picking circles are rebuilt by the next tray draw.
    tray_die_hits = {}
end

function love.update(dt)
    if game_manager then
        game_manager:update(dt)
    end
end

function love.draw()
    if game_manager then
        game_manager:draw()
    end

    if is_scriptorium_active() and (
        os.getenv('MANUSCRIPT_G3D_DEBUG') == '1' or
        (love.timer and love.timer.getTime() < material_notice_until)) then
        local g=love.graphics
        g.push('all')
        g.origin()
        g.setCanvas()
        g.setDepthMode()
        g.setShader()
        g.setColor(.96,.82,.50,.92)
        local label='Renderer: g3d'
        label=label..'  |  Dadi: '..live_g3d.material_mode..' [F10]'..' | Smusso: '..(live_g3d.bevel_enabled and 'ON' or 'OFF')..' [F11]'
        g.print(label,15,g.getHeight()-24)
        g.pop()
    end

    if RuntimeState.should_show_fps() then
        local desired_fps_size = RuntimeUI.sized(14)
        if love.graphics and desired_fps_size ~= fps_font_size then
            local ok, f = pcall(function()
                return love.graphics.newFont(desired_fps_size)
            end)
            fps_font = ok and f or love.graphics.getFont()
            fps_font_size = desired_fps_size
        end
        local high_contrast = RuntimeUI.high_contrast()
        local prev_font = love.graphics.getFont()
        if fps_font then
            love.graphics.setFont(fps_font)
        end
        love.graphics.setColor(0, 0, 0, high_contrast and 0.75 or 0.55)
        love.graphics.rectangle("fill", 8, 8, 92, 24, 4, 4)
        love.graphics.setColor(high_contrast and 1.0 or 0.95, high_contrast and 0.97 or 0.92, high_contrast and 0.90 or 0.82, 1)
        love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 14, 12)
        if prev_font then
            love.graphics.setFont(prev_font)
        end
    end

    local target_fps = tonumber(RuntimeState.get_target_fps())
    if target_fps and target_fps > 0 and love.timer then
        local target_dt = 1 / target_fps
        local now = love.timer.getTime()
        if last_frame_present then
            local elapsed = now - last_frame_present
            if elapsed < target_dt then
                love.timer.sleep(target_dt - elapsed)
                now = love.timer.getTime()
            end
        end
        last_frame_present = now
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key=='f11' and live_g3d and is_scriptorium_active() then
        local enabled=live_g3d:toggle_bevel()
        material_notice_until=(love.timer and love.timer.getTime() or 0)+2.8
        print('[Manuscript visual bevel] '..(enabled and 'ON' or 'OFF')..' [F11]')
        return
    end
    if key=='f10' and live_g3d and is_scriptorium_active() then
        local mode=live_g3d:cycle_material()
        material_notice_until=(love.timer and love.timer.getTime() or 0)+2.8
        print('[Manuscript dice material] '..mode..' [F10]')
        return
    end
    if game_manager then
        game_manager:keypressed(key, scancode, isrepeat)
    end
end

function love.mousepressed(x, y, button)
    if game_manager then
        game_manager:mousepressed(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if game_manager then
        game_manager:mousemoved(x, y, dx, dy, istouch)
    end
end

function love.mousereleased(x, y, button)
    if game_manager then
        game_manager:mousereleased(x, y, button)
    end
end

function love.wheelmoved(x, y)
    if game_manager then
        game_manager:wheelmoved(x, y)
    end
end
---@diagnostic enable: duplicate-set-field

local function pick_spawn_for_region(region, rnd, forced_side)
    local base_region = get_base_region(region)
    local inset_y = DICE_REGION_SPAWN_INSET_Y
    local min_y = base_region.y_back + inset_y
    local max_y = base_region.y_front - inset_y
    local side = math.floor(rnd() * 4) + 1
    side = forced_side or side
    local sx, sy

    local function random_x_with_inset(y, inset)
        local left_x, right_x = get_region_x_bounds_at_y(region, y)
        local width = right_x - left_x
        local effective_inset = math.max(0, math.min(inset or 0, width * 0.5))
        local min_x = left_x + effective_inset
        local max_x = right_x - effective_inset
        if max_x < min_x then
            local mid = (left_x + right_x) * 0.5
            return mid
        end
        return min_x + rnd() * (max_x - min_x)
    end

    if side == 1 or side == 2 then
        sy = min_y + rnd() * (max_y - min_y)
        local left_x, right_x = get_region_x_bounds_at_y(region, sy)
        local wall_inset = math.min(DICE_REGION_SPAWN_SIDE_WALL_INSET_MAX, math.max(0, (right_x - left_x) * 0.5))
        if side == 1 then
            sx = left_x + wall_inset
        else
            sx = right_x - wall_inset
        end
    elseif side == 3 then
        sy = min_y
        sx = random_x_with_inset(sy, DICE_REGION_SPAWN_CENTER_INSET)
    else
        sy = max_y
        sx = random_x_with_inset(sy, DICE_REGION_SPAWN_CENTER_INSET)
    end

    return sx, sy, side
end

function rollAllDice(max_dice, roll_indices, recovery, technical, gesture)
    -- Automatic Space/technical retries preserve the existing launch path.
    manual_session=nil
    for _,entry in ipairs(dice) do
        entry.body._manual_pending=false
        entry.body._grabbed=false
    end
    local rnd = (love and love.math and love.math.random) or math.random
    
    local to_roll = {}
    if type(roll_indices) == "table" and #roll_indices > 0 then
        local seen = {}
        for _, idx in ipairs(roll_indices) do
            local i = tonumber(idx)
            if i then
                i = math.floor(i)
                if i >= 1 and i <= #dice and not seen[i] then
                    to_roll[#to_roll + 1] = i
                    seen[i] = true
                end
            end
        end
    else
        for i = 1, #dice do
            if not dice[i].kept then
                table.insert(to_roll, i)
            end
        end
    end
    
    if #to_roll == 0 then
        Logger.debug("[Dice] No dice available to roll.")
        EngineBridge.emit("dice.roll_skipped", {
            reason = "no_dice_available",
            requested_max = max_dice,
        })
        return
    end

    if max_dice and max_dice > 0 and #to_roll > max_dice then
        local target = math.max(1, math.floor(max_dice))
        local selected = {}
        while #selected < target and #to_roll > 0 do
            local at = math.floor(rnd() * #to_roll) + 1
            selected[#selected + 1] = to_roll[at]
            table.remove(to_roll, at)
        end
        to_roll = selected
    end

    table.sort(to_roll)

    local Spawn=require('src.engine3d.spawn_clearance')
    local spawn_rows,spawn_before={},{}
    local spawn_cubes=true
    for _,i in ipairs(to_roll) do
        local d=dice[i];local b=d.body
        if d.kind~='d6' then spawn_cubes=false end
        spawn_before[i]={position=b.position,velocity=b.velocity,angular=b.angular,
            asleep=b.asleep,sleep_timer=b.sleep_timer,wall_hits=b.wall_hits,value=d.value}
    end
    last_roll_indices = {}
    for i = 1, #to_roll do
        last_roll_indices[i] = to_roll[i]
    end
    if not recovery then
        physicalResolution=nil
        local cubes=true;for _,i in ipairs(to_roll) do if dice[i].kind~='d6' then cubes=false end end
        if cubes and type(Scriptorium.onPhysicalFailure)=='function' then
            physicalResolution=RollResolution.new(last_roll_indices)
        end
        Scriptorium.physicalResolution=physicalResolution
        Scriptorium.physicalNotice=nil;Scriptorium.physicalFailure=nil
    end
    EngineBridge.emit((recovery or technical) and "dice.physical_attempt" or "dice.roll_started", {
        count = #to_roll,
        indices = last_roll_indices,
        requested_max = max_dice,
        technical = recovery == true or technical == true,
        logical_roll_id = Scriptorium.logicalRollId,
        physical_attempt_id = Scriptorium.physicalAttemptId,
    })
    
    diceSettled = false
    diceSettledTimer = 0
    
    if Scriptorium then
        Scriptorium.state = "rolling"
    end
    
    for _, i in ipairs(to_roll) do
        local die_entry = dice[i]
        local region = get_region_for_die(die_entry)
        local base_region = get_base_region(region)
        local sx, sy, spawn_side = pick_spawn_for_region(region, rnd)
        local rz = box.z * 0.5 + DICE_THROW_RZ_BASE + rnd() * DICE_THROW_RZ_RANDOM

        local center_y = (base_region.y_back + base_region.y_front) * 0.5
        local center_x = get_region_center_at_y(region, sy)
        local to_center = vector{center_x - sx, center_y - sy, 0}
        local len = math.sqrt(to_center[1]^2 + to_center[2]^2)
        if len < 1e-4 then
            local angle = rnd() * 2 * math.pi
            to_center = vector{math.cos(angle), math.sin(angle), 0}
        else
            to_center[1] = to_center[1] / len
            to_center[2] = to_center[2] / len
        end

        local vertical_speed = -(DICE_THROW_VERTICAL_BASE + rnd() * DICE_THROW_VERTICAL_RANDOM)
        local lateral_speed = math.abs(vertical_speed) * (DICE_THROW_LATERAL_MULT_BASE + rnd() * DICE_THROW_LATERAL_MULT_RANDOM)
        local base_velocity = vector{
            to_center[1] * lateral_speed,
            to_center[2] * lateral_speed,
            vertical_speed
        }
        -- Mouse throw changes launch momentum only, never dice identity,
        -- rotation-to-face mapping, scoring or the physics solver.
        -- Use inward spawn momentum plus a bounded camera-aligned gesture;
        -- the existing side reflection still protects the playable walls.
        if gesture and not recovery and not technical then
            local power=clamp(tonumber(gesture.power) or 0,0,1.45)
            local gx=clamp(tonumber(gesture.x) or 0,-1,1)
            local gy=clamp(tonumber(gesture.y) or 0,-1,1)
            local extra=8.0*power
            base_velocity[1]=base_velocity[1]+gx*extra
            base_velocity[2]=base_velocity[2]+gy*extra
        end

        local jitter = DICE_THROW_JITTER * (i - (#dice + 1) / 2)
        die_entry.body.position = vector{sx + jitter, sy - jitter, rz}
        die_entry.body.asleep = false
        die_entry.body.sleep_timer = 0
        die_entry.body.wall_hits = 0
        die_entry.body.angular = vector{
            (rnd() - 0.5) * DICE_THROW_ANGULAR_MAX,
            (rnd() - 0.5) * DICE_THROW_ANGULAR_MAX,
            (rnd() - 0.5) * DICE_THROW_ANGULAR_MAX
        }
        if gesture and not recovery and not technical then
            local power=clamp(tonumber(gesture.power) or 0,0,1.45)
            local gx=clamp(tonumber(gesture.x) or 0,-1,1)
            local gy=clamp(tonumber(gesture.y) or 0,-1,1)
            die_entry.body.angular[1]=clamp(die_entry.body.angular[1]-gy*2.5*power,
                -DICE_THROW_ANGULAR_MAX,DICE_THROW_ANGULAR_MAX)
            die_entry.body.angular[2]=clamp(die_entry.body.angular[2]+gx*2.5*power,
                -DICE_THROW_ANGULAR_MAX,DICE_THROW_ANGULAR_MAX)
        end
        die_entry.value = nil
        
        local noise = DICE_THROW_NOISE
        die_entry.body.velocity = vector{
            base_velocity[1] + (rnd() - 0.5) * noise,
            base_velocity[2] + (rnd() - 0.5) * noise,
            base_velocity[3] + (rnd() - 0.5) * noise * DICE_THROW_NOISE_Z_MULT
        }

        spawn_rows[#spawn_rows+1]={index=i,body=die_entry.body,position=die_entry.body.position,
            side=spawn_side,region=region,jitter=jitter}
    end
    if spawn_cubes then
        local positions,spawn_stats=Spawn.place(spawn_rows,function(row,retry_rng,side)
            local x,y,chosen=pick_spawn_for_region(row.region,retry_rng,side)
            return vector{x+row.jitter,y-row.jitter,row.position[3]},chosen
        end)
        if not positions then
            -- Atomic failure: restore pre-launch bodies and use the existing
            -- technical retry UI; never run an overlapping fallback layout.
            for _,i in ipairs(to_roll) do
                local b=dice[i].body;local old=spawn_before[i]
                for _,key in ipairs{'position','velocity','angular','asleep','sleep_timer','wall_hits'} do b[key]=old[key] end
                dice[i].value=old.value
            end
            diceSettled=true
            if physicalResolution then physicalResolution.done=true end
            Scriptorium.physicalFailure='No valid space for spawning: retry the physical roll.'
            if Scriptorium.onPhysicalFailure then Scriptorium:onPhysicalFailure({reason='spawn_exhausted'}) end
            return
        end
        for _,i in ipairs(to_roll) do
            local b=dice[i].body
            b.position=positions[i]
            local sides=spawn_stats.sides[i]
            if sides[1]~=sides[2] then
                -- A different spawn side must not inherit an outward launch.
                -- Reflect only that horizontal component: speed, vz and spin
                -- are preserved, with no new RNG draws or face adjustment.
                local side=sides[2]
                local axis=side<=2 and 1 or 2
                local inward=(side==1 or side==3) and 1 or -1
                if b.velocity[axis]*inward<0 then
                    b.velocity[axis]=-b.velocity[axis]
                end
            end
        end
    end
    
    AudioManager.play_ui(DICE_ROLL_CONFIRM_SFX)
    Logger.debug("[Dice] Rolled " .. #to_roll .. " dice")
end

function checkDiceSettled(dt)
    if diceSettled or (manual_session and manual_session.count>0) then return end
    if physicalResolution then
        local action,event=RollResolution.advance(physicalResolution,dt,dice)
        if action=='accept' then diceSettled=true;Scriptorium.physicalNotice=nil;onDiceSettled()
        elseif action=='retry' then
            Scriptorium.physicalNotice='Ambiguous result: physical retry '..physicalResolution.retries..'/2 with the same dice.'
            EngineBridge.emit('dice.physical_retry',event)
            rollAllDice(nil,physicalResolution.indices,true)
        elseif action=='failed' then
            diceSettled=true
            Scriptorium.physicalFailure='Roll unresolved after 3 physical attempts. No result accepted.'
            Scriptorium.physicalNotice=nil
            if Scriptorium.onPhysicalFailure then Scriptorium:onPhysicalFailure(event) end
            EngineBridge.emit('dice.physical_failure',event)
        end
        return
    end
    
    local all_stable = true
    for i = 1, #dice do
        local s = dice[i].body
        if not s.asleep then
            all_stable = false
            break
        end
    end
    
    if all_stable then
        diceSettledTimer = diceSettledTimer + dt
        if diceSettledTimer >= SETTLE_DELAY then
            diceSettled = true
            onDiceSettled()
        end
    else
        diceSettledTimer = 0
    end
end

function onDiceSettled()
    if type(last_roll_indices) ~= "table" or #last_roll_indices == 0 then
        return
    end

    local values = readDiceValues(last_roll_indices)
    local log_values = {}
    for i = 1, #values do
        log_values[i] = tostring(values[i].value)
    end
    Logger.debug("[Dice] Settled: " .. table.concat(log_values, ", "))
    -- Mechanical settlement is not necessarily an accepted gameplay throw:
    -- a weighted die may reject its face and request another physical attempt.
    local indices = last_roll_indices
    local RollEvents = require("src.core.roll_events")
    local accepted = RollEvents.complete(EngineBridge.emit,
        Scriptorium.onDiceSettled and function(v) return Scriptorium:onDiceSettled(v) end or nil,
        {values = values, indices = indices,
         logical_roll_id = Scriptorium.logicalRollId,
         physical_attempt_id = Scriptorium.physicalAttemptId,
         session_seed = Scriptorium.sessionSeed})
    if accepted then AudioManager.play_ui(DICE_SETTLED_SFX) end
    last_roll_indices = nil
end

function readDiceValues(indices)
    local values = {}
    
    local source = indices
    if type(source) ~= "table" or #source == 0 then
        source = {}
        for i = 1, #dice do
            source[#source + 1] = i
        end
    end

    for _, i in ipairs(source) do
        local die_entry = dice[i]
        if die_entry and die_entry.body and die_entry.die then
            local value = readDieFace(die_entry.die, die_entry.body)
            table.insert(values, {
                value = value,
                sides = die_entry.sides or 6,
                kind = die_entry.kind or "d6",
                index = i,
            })
        end
    end
    
    return values
end

function readDieFace(die, body)
    local faces = (die and die.faces) or d6.faces
    local face_map = (die and (die.faceValueMap or die.pipMap)) or d6.faceValueMap or d6.pipMap
    
    local best_face = 1
    local best_z = -math.huge
    
    for face_idx, face in ipairs(faces) do
        local center_z = 0
        
        for _, vert_idx in ipairs(face) do
            local vertex = body[vert_idx]
            center_z = center_z + vertex[3]
        end
        center_z = center_z / #face
        
        if center_z > best_z then
            best_z = center_z
            best_face = face_idx
        end
    end
    
    return (face_map and face_map[best_face]) or best_face
end
