local Colors = {}

Colors.default_color = "MARRONE"
Colors.default_pigment = "OCRA_GIALLA"

Colors.inkwell_order = {
    "ROSSO",
    "VERDE",
    "GIALLO",
    "BLU",
    "MARRONE",
    "NERO",
    "VIOLA",
    "BIANCO",
}

Colors.turn_d8_order = {
    "ROSSO",
    "BLU",
    "VERDE",
    "GIALLO",
    "NERO",
    "MARRONE",
    "BIANCO",
    "VIOLA",
}

Colors.common_colors = {
    "BLU",
    "VERDE",
    "ROSSO",
    "GIALLO",
    "MARRONE",
    "NERO",
    "VIOLA",
    "BIANCO",
}

Colors.value_to_color = {
    [1] = "MARRONE",
    [2] = "VERDE",
    [3] = "NERO",
    [4] = "ROSSO",
    [5] = "BLU",
    [6] = "GIALLO",
}

Colors.color_to_value = {
    MARRONE = 1,
    VERDE = 2,
    NERO = 3,
    ROSSO = 4,
    BLU = 5,
    GIALLO = 6,
}

Colors.aliases = {
    RED = "ROSSO",
    BLUE = "BLU",
    GREEN = "VERDE",
    YELLOW = "GIALLO",
    PURPLE = "VIOLA",
    BLACK = "NERO",
    BROWN = "MARRONE",
    WHITE = "BIANCO",
}

Colors.swatch = {
    MARRONE = {0.55, 0.35, 0.20},
    VERDE = {0.25, 0.55, 0.30},
    NERO = {0.14, 0.14, 0.14},
    ROSSO = {0.72, 0.20, 0.15},
    BLU = {0.24, 0.37, 0.70},
    GIALLO = {0.85, 0.70, 0.25},
    VIOLA = {0.56, 0.34, 0.70},
    BIANCO = {0.93, 0.93, 0.93},
}

return Colors
