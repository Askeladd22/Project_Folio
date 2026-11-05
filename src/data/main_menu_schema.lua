return {
    assets = {
        -- Manuzio printshop ships in the repository (from 0.1.9).
        -- The former illustration is an optional local compatibility
        -- fallback; menu.png remains the final shipping fallback.
        manuzio_background_path = "resources/ui/menu_manuzio.png",
        illustrated_background_path = "resources/ui/menu_illustrated.png",
        background_path = "resources/ui/menu.png",
        music_path = "resources/sounds/maintitle.ogg",
        font_text = "resources/font/ManuskriptGothischUNZ1A.ttf",
        font_uppercase = "resources/font/IMFeENsc28P.ttf",
        font_fallback = "resources/font/EagleLake-Regular.ttf",
    },
    links = {
        wishlist_url = "https://store.steampowered.com/",
    },
    transitions = {
        fade_duration = 0.50,
        switch_delay = 0.60,
    },
    flow = {
        confirm_mouse_button = 1,
        audio_toggle = "toggle",
        audio_confirm = "confirm",
        audio_hover = "hover",
        navigation_new_game = "campaign_select",
        navigation_continue = "scriptorium",
        navigation_settings = "settings",
        music_track_id = "main_menu",
        -- 0.25 = -12 dB relative to the Music volume slider. Applies only
        -- to maintitle.ogg; dice, UI and gameplay SFX are not attenuated.
        main_theme_mix_gain = 0.25,
    },
    labels = {
        branding_title = {
            key = "branding.title",
            default = "Project Folio",
        },
        subtitle = {
            key = "main_menu.subtitle",
            default = "A Dream of Ink and Dice",
        },
        footer_alpha = {
            key = "main_menu.footer.alpha",
            default = "alpha",
        },
    },
    modals = {
        no_save = {
            key = "main_menu.modal.no_save",
            default = "No saved game found. Start a New Game instead.",
        },
        wishlist_fallback = {
            key = "main_menu.modal.wishlist_fallback",
            default = "Open the store to wishlist the game: {url}",
        },
    },
    menu_items = {
        {
            id = "continue",
            label = {
                key = "main_menu.item.continue",
                default = "Continue",
            },
            primary = true,
            enabled = false,
            delay = 0.20,
        },
        {
            id = "new-game",
            label = {
                key = "main_menu.item.new_game",
                default = "New Game",
            },
            primary = true,
            enabled = true,
            delay = 0.28,
        },
        {
            id = "settings",
            label = {
                key = "main_menu.item.settings",
                default = "Settings",
            },
            primary = false,
            enabled = true,
            delay = 0.45,
        },
        {
            id = "wishlist",
            label = {
                key = "main_menu.item.wishlist",
                default = "Wishlist",
            },
            primary = false,
            enabled = true,
            delay = 0.53,
        },
        {
            id = "quit",
            label = {
                key = "main_menu.item.quit",
                default = "Quit",
            },
            primary = false,
            enabled = true,
            delay = 0.61,
        },
    },
}
