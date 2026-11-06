return {
    assets = {
        -- Manuzio printshop ships in the repository (from 0.1.9).
        -- The former illustration is an optional local compatibility
        -- fallback; menu.png remains the final shipping fallback.
        manuzio_background_path = "resources/ui/menu_manuzio.png",
        illustrated_background_path = "resources/ui/menu_illustrated.png",
        background_path = "resources/ui/menu.png",
        font_text = "resources/font/GoudyBookletter1911.ttf",
        font_uppercase = "resources/font/GoudyBookletter1911.ttf",
        font_fallback = "resources/font/GoudyBookletter1911.ttf",
    },
    colors = {
        -- Ink and ochre on the shared manuscript surface; sliders only.
        title_gold = {0.57, 0.37, 0.13},
        text_secondary = {0.64, 0.49, 0.31},
    },
    text = {
        branding_title = {
            key = "branding.title",
            default = "Project Folio",
        },
        subtitle_sections = {
            key = "settings.subtitle.sections",
            default = "Settings",
        },
        action_back = {
            key = "settings.action.back",
            default = "Back",
        },
        value_yes = {
            key = "settings.value.yes",
            default = "Yes",
        },
        value_no = {
            key = "settings.value.no",
            default = "No",
        },
    },
    flow = {
        view_mode_sections = "sections",
        view_mode_content = "content",
        confirm_mouse_button = 1,
        slider_drag_margin = 12,
        audio_toggle = "toggle",
        audio_confirm = "confirm",
        audio_back = "back",
        audio_hover = "hover",
        exit_module = "main_menu",
    },
}
