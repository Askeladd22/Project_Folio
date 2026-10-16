local Colors = require("src.data.colors")

return {
    windows_json_path = "resources/tiles/Windows.json",
    grid_rows = 4,
    grid_cols = 5,
    color_map = Colors.aliases,
    common_colors = Colors.common_colors,
    fallback_pattern = {
        id = "fallback_window",
        name_key = "window_pattern.name.fallback_window",
        name_default = "Fallback Window",
        token = 0,
        source_card_id = -1,
    },
    localized_names = {
        ["kaleidoscopic dream"] = {
            key = "window_pattern.name.kaleidoscopic_dream",
            default = "Kaleidoscopic Dream",
        },
        firmitas = {
            key = "window_pattern.name.firmitas",
            default = "Firmitas",
        },
        ["fractal drops"] = {
            key = "window_pattern.name.fractal_drops",
            default = "Fractal Drops",
        },
        ["ripple of light"] = {
            key = "window_pattern.name.ripple_of_light",
            default = "Ripple of Light",
        },
        ["lux mundi"] = {
            key = "window_pattern.name.lux_mundi",
            default = "Lux Mundi",
        },
        ["lux astram"] = {
            key = "window_pattern.name.lux_astram",
            default = "Lux Astram",
        },
        gravitas = {
            key = "window_pattern.name.gravitas",
            default = "Gravitas",
        },
        ["water of life"] = {
            key = "window_pattern.name.water_of_life",
            default = "Water of Life",
        },
        ["sun catcher"] = {
            key = "window_pattern.name.sun_catcher",
            default = "Sun Catcher",
        },
        ["shadow thief"] = {
            key = "window_pattern.name.shadow_thief",
            default = "Shadow Thief",
        },
        ["aurorae magnificus"] = {
            key = "window_pattern.name.aurorae_magnificus",
            default = "Aurorae Magnificus",
        },
        ["aurora sagradis"] = {
            key = "window_pattern.name.aurora_sagradis",
            default = "Aurora Sagradis",
        },
        ["symphony of light"] = {
            key = "window_pattern.name.symphony_of_light",
            default = "Symphony of Light",
        },
        virtus = {
            key = "window_pattern.name.virtus",
            default = "Virtus",
        },
        firelight = {
            key = "window_pattern.name.firelight",
            default = "Firelight",
        },
        ["sun's glory"] = {
            key = "window_pattern.name.suns_glory",
            default = "Sun's Glory",
        },
        batllo = {
            key = "window_pattern.name.batllo",
            default = "Batllo",
        },
        bellesguard = {
            key = "window_pattern.name.bellesguard",
            default = "Bellesguard",
        },
        ["fulgor del cielo"] = {
            key = "window_pattern.name.fulgor_del_cielo",
            default = "Fulgor del Cielo",
        },
        ["luz celestial"] = {
            key = "window_pattern.name.luz_celestial",
            default = "Luz Celestial",
        },
        ["chromatic splendor"] = {
            key = "window_pattern.name.chromatic_splendor",
            default = "Chromatic Splendor",
        },
        comitas = {
            key = "window_pattern.name.comitas",
            default = "Comitas",
        },
        ["via lux"] = {
            key = "window_pattern.name.via_lux",
            default = "Via Lux",
        },
        industria = {
            key = "window_pattern.name.industria",
            default = "Industria",
        },
    },
}
