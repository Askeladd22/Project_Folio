return {
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
        -- Explicit physical parameters; these preserve the pre-audit runtime.
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
            -- Full usable inner parchment area in the visible g3d board.
            -- Old 6.3/8.4 world-unit trapezoid made the ordinary six-D6
            -- roll bounce against invisible boundaries inside the tray.
            -- Keep a small margin from the real box walls on all four sides.
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
}
