return {
    sizes = {
        base = 0.92,
        min = 0.74,
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
            row_spacing = 1.20,
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
}
