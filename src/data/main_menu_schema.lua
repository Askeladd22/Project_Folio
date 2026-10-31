return {
    assets = {
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
        footer_version = {
            key = "main_menu.footer.version",
            default = "v0.1",
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
                default = "Wishlist Now!",
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
