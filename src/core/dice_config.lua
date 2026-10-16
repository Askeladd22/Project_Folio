local Schema = require("src.core.schema")
local DefaultRollSchema = require("src.data.dice_roll_schema")
local DefaultVisualSchema = require("src.data.dice_visual_schema")
local DefaultSceneSchema = require("src.data.dice_scene_schema")

local DiceConfig = {}

local expect_table = Schema.expect_table
local expect_non_empty_list = Schema.expect_non_empty_list
local expect_string = Schema.expect_string
local expect_number = Schema.expect_number
local expect_boolean = Schema.expect_boolean

local function fail(path, message)
    error(string.format("Invalid schema at %s: %s", path, message))
end

local function expect_integer(value, path, min_value)
    local parsed = expect_number(value, path)
    local rounded = math.floor(parsed)
    if rounded ~= parsed then
        fail(path, "expected integer")
    end
    if min_value ~= nil and rounded < min_value then
        fail(path, string.format("expected integer >= %d", min_value))
    end
    return rounded
end

local function expect_vec3(value, path)
    local vec = expect_table(value, path)
    return {
        expect_number(vec[1], path .. "[1]"),
        expect_number(vec[2], path .. "[2]"),
        expect_number(vec[3], path .. "[3]"),
    }
end

local function expect_color(value, path)
    local color = expect_table(value, path)
    local parsed = {
        expect_number(color[1], path .. "[1]"),
        expect_number(color[2], path .. "[2]"),
        expect_number(color[3], path .. "[3]"),
    }
    if color[4] ~= nil then
        parsed[4] = expect_number(color[4], path .. "[4]")
    end
    return parsed
end

local function parse_roll_schema(roll_schema)
    local root = expect_table(roll_schema, "dice_roll_schema")
    local sizes = expect_table(root.sizes, "dice_roll_schema.sizes")
    local pool_list = expect_non_empty_list(root.pool, "dice_roll_schema.pool")
    local spawn_layout = expect_table(root.spawn_layout, "dice_roll_schema.spawn_layout")
    local spawn_main = expect_table(spawn_layout.main, "dice_roll_schema.spawn_layout.main")
    local spawn_mini = expect_table(spawn_layout.mini, "dice_roll_schema.spawn_layout.mini")
    local initial_state = expect_table(root.initial_state, "dice_roll_schema.initial_state")
    local region_spawn = expect_table(root.region_spawn, "dice_roll_schema.region_spawn")
    local throw = expect_table(root.throw, "dice_roll_schema.throw")
    local audio = expect_table(root.audio, "dice_roll_schema.audio")

    local parsed_pool = {}
    for index, entry in ipairs(pool_list) do
        local path = string.format("dice_roll_schema.pool[%d]", index)
        local spec = expect_table(entry, path)
        local kind = expect_string(spec.kind, path .. ".kind")
        if kind ~= "d6" and kind ~= "d8" then
            fail(path .. ".kind", "expected supported kind (d6 or d8)")
        end

        parsed_pool[#parsed_pool + 1] = {
            kind = kind,
            count = expect_integer(spec.count, path .. ".count", 0),
            sides = expect_integer(spec.sides, path .. ".sides", 2),
        }
    end

    return {
        sizes = {
            base = expect_number(sizes.base, "dice_roll_schema.sizes.base"),
            min = expect_number(sizes.min, "dice_roll_schema.sizes.min"),
            scale_reference_dice_count = expect_integer(
                sizes.scale_reference_dice_count,
                "dice_roll_schema.sizes.scale_reference_dice_count",
                1
            ),
        },
        pool = parsed_pool,
        spawn_layout = {
            row_offset = expect_number(spawn_layout.row_offset, "dice_roll_schema.spawn_layout.row_offset"),
            row_clamp_inset = expect_number(
                spawn_layout.row_clamp_inset,
                "dice_roll_schema.spawn_layout.row_clamp_inset"
            ),
            x_inset = expect_number(spawn_layout.x_inset, "dice_roll_schema.spawn_layout.x_inset"),
            main = {
                cols = expect_integer(spawn_main.cols, "dice_roll_schema.spawn_layout.main.cols", 1),
                row_spacing = expect_number(
                    spawn_main.row_spacing,
                    "dice_roll_schema.spawn_layout.main.row_spacing"
                ),
            },
            mini = {
                cols = expect_integer(spawn_mini.cols, "dice_roll_schema.spawn_layout.mini.cols", 1),
                row_spacing = expect_number(
                    spawn_mini.row_spacing,
                    "dice_roll_schema.spawn_layout.mini.row_spacing"
                ),
            },
        },
        initial_state = {
            position_z = expect_number(initial_state.position_z, "dice_roll_schema.initial_state.position_z"),
            velocity_even = expect_vec3(initial_state.velocity_even, "dice_roll_schema.initial_state.velocity_even"),
            velocity_odd = expect_vec3(initial_state.velocity_odd, "dice_roll_schema.initial_state.velocity_odd"),
            spin = expect_vec3(initial_state.spin, "dice_roll_schema.initial_state.spin"),
        },
        region_spawn = {
            inset_y = expect_number(region_spawn.inset_y, "dice_roll_schema.region_spawn.inset_y"),
            side_wall_inset_max = expect_number(
                region_spawn.side_wall_inset_max,
                "dice_roll_schema.region_spawn.side_wall_inset_max"
            ),
            center_inset = expect_number(region_spawn.center_inset, "dice_roll_schema.region_spawn.center_inset"),
        },
        throw = {
            rz_base = expect_number(throw.rz_base, "dice_roll_schema.throw.rz_base"),
            rz_random = expect_number(throw.rz_random, "dice_roll_schema.throw.rz_random"),
            vertical_base = expect_number(throw.vertical_base, "dice_roll_schema.throw.vertical_base"),
            vertical_random = expect_number(throw.vertical_random, "dice_roll_schema.throw.vertical_random"),
            lateral_mult_base = expect_number(
                throw.lateral_mult_base,
                "dice_roll_schema.throw.lateral_mult_base"
            ),
            lateral_mult_random = expect_number(
                throw.lateral_mult_random,
                "dice_roll_schema.throw.lateral_mult_random"
            ),
            jitter = expect_number(throw.jitter, "dice_roll_schema.throw.jitter"),
            angular_max = expect_number(throw.angular_max, "dice_roll_schema.throw.angular_max"),
            noise = expect_number(throw.noise, "dice_roll_schema.throw.noise"),
            noise_z_mult = expect_number(throw.noise_z_mult, "dice_roll_schema.throw.noise_z_mult"),
        },
        settle_delay = expect_number(root.settle_delay, "dice_roll_schema.settle_delay"),
        audio = {
            roll_confirm = expect_string(audio.roll_confirm, "dice_roll_schema.audio.roll_confirm"),
            settled = expect_string(audio.settled, "dice_roll_schema.audio.settled"),
        },
    }
end

local function parse_visual_schema(visual_schema)
    local root = expect_table(visual_schema, "dice_visual_schema")
    local prototypes = expect_table(root.prototypes, "dice_visual_schema.prototypes")
    local face_colors = expect_table(root.face_colors, "dice_visual_schema.face_colors")
    local d8_cycle = expect_non_empty_list(face_colors.d8_cycle, "dice_visual_schema.face_colors.d8_cycle")
    local glow = expect_table(root.glow, "dice_visual_schema.glow")

    local parsed_cycle = {}
    for index, color in ipairs(d8_cycle) do
        parsed_cycle[index] = expect_color(color, string.format("dice_visual_schema.face_colors.d8_cycle[%d]", index))
    end

    return {
        prototypes = {
            d6_color = expect_color(prototypes.d6_color, "dice_visual_schema.prototypes.d6_color"),
            d6_text = expect_color(prototypes.d6_text, "dice_visual_schema.prototypes.d6_text"),
            d8_color = expect_color(prototypes.d8_color, "dice_visual_schema.prototypes.d8_color"),
            d8_text = expect_color(prototypes.d8_text, "dice_visual_schema.prototypes.d8_text"),
        },
        face_colors = {
            d6_black = expect_color(face_colors.d6_black, "dice_visual_schema.face_colors.d6_black"),
            d8_cycle = parsed_cycle,
        },
        glow = {
            shader_path = expect_string(glow.shader_path, "dice_visual_schema.glow.shader_path"),
            color = expect_vec3(glow.color, "dice_visual_schema.glow.color"),
            intensity = expect_number(glow.intensity, "dice_visual_schema.glow.intensity"),
        },
    }
end

local function parse_scene_schema(scene_schema)
    local root = expect_table(scene_schema, "dice_scene_schema")
    local board = expect_table(root.board, "dice_scene_schema.board")
    local camera = expect_table(root.tray_camera, "dice_scene_schema.tray_camera")
    local box = expect_table(root.box, "dice_scene_schema.box")
    local regions = expect_table(root.regions, "dice_scene_schema.regions")
    local unified = expect_table(regions.unified, "dice_scene_schema.regions.unified")
    local main = expect_table(regions.main, "dice_scene_schema.regions.main")
    local mini = expect_table(regions.mini, "dice_scene_schema.regions.mini")

    local d6_ratio = expect_number(regions.d6_ratio, "dice_scene_schema.regions.d6_ratio")
    if d6_ratio <= 0 or d6_ratio >= 1 then
        fail("dice_scene_schema.regions.d6_ratio", "expected number in range (0, 1)")
    end

    return {
        board_image_path = expect_string(board.image_path, "dice_scene_schema.board.image_path"),
        camera = {
            locked = expect_boolean(camera.locked, "dice_scene_schema.tray_camera.locked"),
            yaw = expect_number(camera.yaw, "dice_scene_schema.tray_camera.yaw"),
            pitch = expect_number(camera.pitch, "dice_scene_schema.tray_camera.pitch"),
            distance = expect_number(camera.distance, "dice_scene_schema.tray_camera.distance"),
        },
        box = {
            half_x = expect_number(box.half_x, "dice_scene_schema.box.half_x"),
            half_y = expect_number(box.half_y, "dice_scene_schema.box.half_y"),
            height = expect_number(box.height, "dice_scene_schema.box.height"),
            gravity = expect_number(box.gravity, "dice_scene_schema.box.gravity"),
            restitution = expect_number(box.restitution, "dice_scene_schema.box.restitution"),
            fixed_dt = expect_number(box.fixed_dt, "dice_scene_schema.box.fixed_dt"),
            friction = expect_number(box.friction, "dice_scene_schema.box.friction"),
            linear_damping = expect_number(box.linear_damping, "dice_scene_schema.box.linear_damping"),
            angular_damping = expect_number(box.angular_damping, "dice_scene_schema.box.angular_damping"),
            border_height = expect_number(box.border_height, "dice_scene_schema.box.border_height"),
        },
        regions = {
            d6_ratio = d6_ratio,
            unified = {
                x_center = expect_number(unified.x_center, "dice_scene_schema.regions.unified.x_center"),
                y_back = expect_number(unified.y_back, "dice_scene_schema.regions.unified.y_back"),
                y_front = expect_number(unified.y_front, "dice_scene_schema.regions.unified.y_front"),
                half_back = expect_number(unified.half_back, "dice_scene_schema.regions.unified.half_back"),
                half_front = expect_number(unified.half_front, "dice_scene_schema.regions.unified.half_front"),
                bounce = expect_number(unified.bounce, "dice_scene_schema.regions.unified.bounce"),
                slide_damping = expect_number(
                    unified.slide_damping,
                    "dice_scene_schema.regions.unified.slide_damping"
                ),
            },
            main = {
                parent = expect_string(main.parent, "dice_scene_schema.regions.main.parent"),
                slot = expect_string(main.slot, "dice_scene_schema.regions.main.slot"),
                y_back = expect_number(main.y_back, "dice_scene_schema.regions.main.y_back"),
                y_front = expect_number(main.y_front, "dice_scene_schema.regions.main.y_front"),
                bounce = expect_number(main.bounce, "dice_scene_schema.regions.main.bounce"),
                slide_damping = expect_number(main.slide_damping, "dice_scene_schema.regions.main.slide_damping"),
            },
            mini = {
                parent = expect_string(mini.parent, "dice_scene_schema.regions.mini.parent"),
                slot = expect_string(mini.slot, "dice_scene_schema.regions.mini.slot"),
                y_back = expect_number(mini.y_back, "dice_scene_schema.regions.mini.y_back"),
                y_front = expect_number(mini.y_front, "dice_scene_schema.regions.mini.y_front"),
                bounce = expect_number(mini.bounce, "dice_scene_schema.regions.mini.bounce"),
                slide_damping = expect_number(mini.slide_damping, "dice_scene_schema.regions.mini.slide_damping"),
            },
        },
    }
end

---@param options? { roll_schema?: table, visual_schema?: table, scene_schema?: table }
---@return table
function DiceConfig.load(options)
    local opts = options or {}
    local roll = parse_roll_schema(opts.roll_schema or DefaultRollSchema)
    local visual = parse_visual_schema(opts.visual_schema or DefaultVisualSchema)
    local scene = parse_scene_schema(opts.scene_schema or DefaultSceneSchema)

    return {
        sizes = roll.sizes,
        pool = roll.pool,
        spawn_layout = roll.spawn_layout,
        initial_state = roll.initial_state,
        region_spawn = roll.region_spawn,
        throw = roll.throw,
        settle_delay = roll.settle_delay,
        audio = roll.audio,
        visual = visual,
        scene = scene,
        board_image_path = scene.board_image_path,
    }
end

return DiceConfig
