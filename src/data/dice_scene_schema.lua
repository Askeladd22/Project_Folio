return {
    board = {
        image_path = "resources/textures/wood.png",
    },
    tray_camera = {
        locked = true,
        -- A slight three-quarter angle makes two dice sides legible,
        -- without touching die poses, physical contacts or face results.
        yaw = 0.18,
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
            y_back = -3.45,
            y_front = 3.45,
            half_back = 6.3,
            half_front = 8.4,
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
