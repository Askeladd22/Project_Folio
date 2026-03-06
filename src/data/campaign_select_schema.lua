return {
    assets = {
        background_path = "resources/ui/menu.png",
        font_text = "resources/font/ManuskriptGothischUNZ1A.ttf",
        font_uppercase = "resources/font/IMFeENsc28P.ttf",
        font_fallback = "resources/font/EagleLake-Regular.ttf",
    },
    colors = {
        title_gold = {0.90, 0.74, 0.34},
        subtitle_ivory = {0.84, 0.80, 0.72},
        text_active = {0.97, 0.86, 0.62},
        text_primary = {0.88, 0.80, 0.68},
        text_secondary = {0.68, 0.61, 0.52},
        text_shadow = {0.02, 0.015, 0.01},
        accent_fill = {0.86, 0.66, 0.24},
    },
    text = {
        branding_title = {
            key = "branding.title",
            default = "Scriptorium",
        },
        subtitle = {
            key = "campaign_select.subtitle",
            default = "Choose Commission",
        },
        item_back = {
            key = "campaign_select.item.back",
            default = "Back",
        },
        detail_folios = {
            key = "campaign_select.detail.folios",
            default = "{count} folios",
        },
        detail_dirty_threshold = {
            key = "campaign_select.detail.dirty_threshold",
            default = "{folios} | Dirty threshold: {threshold}+ stains",
        },
        detail_standard_scoring = {
            key = "campaign_select.detail.standard_scoring",
            default = "{folios} | Standard quality scoring",
        },
    },
    flow = {
        confirm_mouse_button = 1,
        audio_hover = "hover",
        audio_confirm = "confirm",
        audio_back = "back",
        back_module = "main_menu",
        campaign_module = "scriptorium",
    },
}
