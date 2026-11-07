local Parts = {}

-- Dice and scene configuration
Parts.dice = (function()
return {
    roll = {
        sizes = {
            base = 0.80,
            min = 0.64,
            scale_reference_dice_count = 6,
        },
        pool = {
            {kind = "d6", count = 4, sides = 6},
            {kind = "d8", count = 3, sides = 8},
        },
        spawn_layout = {
            row_offset = -0.5,
            row_clamp_inset = 0.70,
            x_inset = 0.36,
            main = {
                cols = 3,
                row_spacing = 2.10,
            },
            mini = {
                cols = 2,
                row_spacing = 0.95,
            },
        },
        initial_state = {
            position_z = 8,
            velocity_even = {3, -2, 0},
            velocity_odd = {-3, 2, 0},
            spin = {1, 1, 2},
        },
        region_spawn = {
            inset_y = 0.26,
            side_wall_inset_max = 0.22,
            center_inset = 0.26,
        },
        throw = {
            rz_base = 1.0,
            rz_random = 1.5,
            vertical_base = 18,
            vertical_random = 8,
            lateral_mult_base = 0.80,
            lateral_mult_random = 0.25,
            jitter = 0.05,
            angular_max = 12,
            noise = 1.2,
            noise_z_mult = 0.5,
        },
        settle_delay = 0.3,
        audio = {
            roll_confirm = "confirm",
            settled = "move",
        },
    },
    scene = {
        board = {
            image_path = "resources/textures/wood.png",
        },
        tray_camera = {
            locked = true,
            yaw = 0.00,
            pitch = 1.00,
            distance = 52,
        },
        box = {
            half_x = 14.5,
            half_y = 6.30,
            height = 10,
            -- Explicit physical parameters preserve the established runtime.
            gravity = 25,
            restitution = 0.25,
            friction = 0.75,
            fixed_dt = 0.01,
            linear_damping = 0.12,
            angular_damping = 0.12,
            border_height = 0.74,
        },
        regions = {
            d6_ratio = 2 / 3,
            unified = {
                x_center = 0.0,
                -- Keep dice inside the visible board rather than the old,
                -- narrower invisible collision trapezoid.
                y_back = -6.05,
                y_front = 6.05,
                half_back = 14.00,
                half_front = 14.00,
                bounce = 0.34,
                slide_damping = 0.90,
            },
            main = {
                parent = "unified",
                slot = "main",
                y_back = -5.95,
                y_front = 5.95,
                bounce = 0.34,
                slide_damping = 0.90,
            },
            mini = {
                parent = "unified",
                slot = "mini",
                y_back = -5.95,
                y_front = 5.95,
                bounce = 0.34,
                slide_damping = 0.90,
            },
        },
    },
    visual = {
        prototypes = {
            d6_color = {200, 180, 160, 255},
            d6_text = {255, 255, 255},
            d8_color = {250, 235, 20, 255},
            d8_text = {0, 0, 0},
        },
        face_colors = {
            d6_black = {20, 20, 20, 255},
            d8_cycle = {
                {220, 45, 45, 255},
                {35, 95, 210, 255},
                {45, 170, 70, 255},
                {235, 210, 40, 255},
                {20, 20, 20, 255},
                {120, 72, 36, 255},
                {245, 245, 245, 255},
                {150, 70, 180, 255},
            },
        },
        glow = {
            shader_path = "resources/shaders/dice_glow.glsl",
            color = {1.0, 0.93, 0.62},
            intensity = 0.58,
        },
    },
}
end)()

-- Tray layout
Parts.tray = (function()
return {
    main = {
        width_ratio = 0.60,
        height_ratio = 0.29,
        max_width = 1240,
        max_height = 400,
        min_width = 680,
        min_height = 230,
        overlay_scale_mult = 2.20,
        overlay_center_y = 0.50,
        floor_top_ratio = 0.20,
        floor_bottom_ratio = 0.90,
        floor_top_width_ratio = 0.68,
        floor_bottom_width_ratio = 0.93,
        divider_half_width = 0.15,
        divider_y_inset = 0.42,
        divider_height_scale = 1.08,
        divider_height_min = 0.30,
    },
    shared = {
        bottom_margin = 8,
    },
    overlay = {
        scale_mult = 2.20,
        center_y = 0.50,
        shadows = false,
        flat_floor = true,
    },
}
end)()

Parts.dice.tray = Parts.tray
return Parts.dice
