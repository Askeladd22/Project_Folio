return {
    board = {
        image_path = "resources/textures/wood.png",
    },
    tray_camera = {
        locked = true,
        yaw = 0.00,
        pitch = 0.62,
        distance = 14.1,
    },
    box = {
        half_x = 9.2,
        half_y = 3.8,
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
            -- Keep a small margin from the real box walls at +/-9.2.
            y_back = -3.55,
            y_front = 3.55,
            half_back = 8.70,
            half_front = 8.70,
            bounce = 0.34,
            slide_damping = 0.90,
        },
        main = {
            parent = "unified",
            slot = "main",
            y_back = -3.45,
            y_front = 3.45,
            bounce = 0.34,
            slide_damping = 0.90,
        },
        mini = {
            parent = "unified",
            slot = "mini",
            y_back = -3.45,
            y_front = 3.45,
            bounce = 0.34,
            slide_damping = 0.90,
        },
    },
}
