return {
    assets = {
        shader_fill_path = "resources/shaders/startup_splash/fill.glsl",
        shader_shrink_path = "resources/shaders/startup_splash/shrink.glsl",
        shader_title_path = "resources/shaders/startup_splash/title_reveal.glsl",
        shader_title_overlay_path = "resources/shaders/startup_splash/title_overlay.glsl",
        image_circle_path = "resources/ui/startup_splash/circle.png",
        image_heart_path = "resources/ui/startup_splash/heart.png",
        image_love_path = "resources/ui/startup_splash/love.png",
        image_title_stroke_map_path = "resources/ui/startup_splash/scriptorium_stroke_map.png",
        -- The original image contains the retired Scriptorium lettering.
        -- Use live text until a final logo is approved.
        image_title_logo_enabled = false,
        image_title_logo_candidates = {
            "resources/ui/startup_splash/scriptorium_logo.png",
            "resources/ui/startup_splash/scriptorium_logo.jpg",
            "resources/ui/startup_splash/scriptorium_logo.jpeg",
        },
        title_font_primary = "resources/font/IMFeENsc28P.ttf",
        title_font_fallback = "resources/font/EagleLake-Regular.ttf",
        title_base_font_size = 96,
    },
    colors = {
        pink = {231 / 255, 74 / 255, 153 / 255},
        blue = {39 / 255, 170 / 255, 224 / 255},
        black = {0.1, 0.1, 0.15},
        white = {1, 1, 1},
    },
    timing = {
        base_splash_duration = 7.5,
        base_heart_at = 2.7,
        base_heart_bounce_time = 0.8,
        base_heart_bounce_delay = 0.5,
        base_heart_start_angle = math.pi / 4,
        base_shift_delay = 1.5,
        base_shift_duration = 0.7,
        base_title_duration = 5.0,
        base_title_fade_in = 0.55,
        base_title_fade_out = 1.05,
        reduced_timing_scale = 0.45,
        min_reduced_title_duration = 3.0,
    },
    metrics = {
        heart_diameter_ratio = 0.17,
        circle_diameter_ratio = 0.30,
        love_diameter_ratio = 0.29,
    },
    text = {
        branding_title = {
            key = "branding.title",
            default = "Project Folio",
        },
    },
    flow = {
        next_module = "main_menu",
        skip_audio = "confirm",
        skip_mouse_button = 1,
    },
}
