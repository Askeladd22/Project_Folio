return {
    pre_update = {
        {name = "resolution_refresh", order = 100},
        {name = "physics_step", order = 200},
        {name = "dice_constrain_regions", order = 300},
        {name = "dice_settle_check", order = 400},
    },
    post_update = {
        {name = "tray_camera_control", order = 100},
    },
    pre_draw = {},
    post_draw = {
        {name = "tray_overlay", order = 100},
    },
}
