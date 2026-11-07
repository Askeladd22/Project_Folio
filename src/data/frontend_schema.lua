local Bundle = {}
Bundle.palette = (function()
-- Project Folio's canonical muted manuscript palette.
-- Inspired by illustrated medieval landscapes, incunabula and material
-- pigments, not by photographic colour-grading or generic fantasy UI.
-- Pure Lua: safe to load in headless tests, independent of LÖVE/renderer.
local P={}
P.hex={
 paper='#E7DCC8',paper_mid='#D8C9B1',paper_shadow='#C3B097',
 plaster='#DCD5C8',stone='#BFB4A1',dust='#9B9285',
 timber_light='#A78663',timber='#856448',earth='#6E533C',
 earth_dark='#4E3B2C',ink='#352A23',
 sage_light='#AAB09A',sage='#8E957B',olive='#72785C',
 forest='#59604A',
 clay='#C38B7A',brick='#A85F52',cinnabar='#8D4B43',
 burgundy='#6F3A35',
 mist='#B3C0C1',slate_light='#8E9EA0',
 slate='#6F8087',slate_dark='#4F5E66',
 ochre_light='#D4B66A',ochre='#BE9A4F',ochre_dark='#9F8344',
}
P.roles={
 background='plaster',
 surface='paper',
 surface_alt='paper_mid',
 surface_recessed='paper_shadow',
 text='ink',
 text_muted='earth',
 border='timber',
 focus='slate_dark',
 selection='sage',
 reward='ochre_dark',
 risk='cinnabar',
 quiet='dust',
 physical='mist',
}
local cache={}
local function resolve(name)
 local role=P.roles[name] or name
 local hex=P.hex[role]
 assert(hex,'Unknown Project Folio colour: '..tostring(name))
 return role,hex
end
function P.hex_for(name)
 local _,hex=resolve(name)
 return hex
end
function P.rgb(name)
 local role,hex=resolve(name)
 if not cache[role] then
  cache[role]={
   tonumber(hex:sub(2,3),16)/255,
   tonumber(hex:sub(4,5),16)/255,
   tonumber(hex:sub(6,7),16)/255,
  }
 end
 -- Return a copy, never leak the shared palette to drawing code that
 -- changes alpha or modifies a component in-place.
 return {cache[role][1],cache[role][2],cache[role][3]}
end
function P.rgba(name,alpha)
 local c=P.rgb(name)
 c[4]=alpha==nil and 1 or alpha
 return c
end
return P
end)()
Bundle.settings = (function()
local Art = Bundle.palette

return {
    persistence = {
        file_path = "settings_data.json",
        legacy_file_path = "settings_data.lua",
        format = "json",
    },
    tabs = {
        {
            label_key = "settings.tab.game",
            default_label = "Game Settings",
            label = "Game Settings",
            controls = {
                {
                    type = "choice",
                    label_key = "settings.control.language",
                    default_label = "Language",
                    label = "Language",
                    options = {"English"},
                    option_label_keys = {"settings.option.language.english"},
                    option_label_defaults = {"English"},
                    option_labels = {"English"},
                    value_index = 1,
                    default_index = 1,
                    setting = "game.language",
                },
                {
                    type = "toggle",
                    label_key = "settings.control.verbose_logs",
                    default_label = "Verbose logs",
                    label = "Verbose logs",
                    value = false,
                    default = false,
                    setting = "game.verbose_logs",
                },
            },
        },
        {
            label_key = "settings.tab.controls",
            default_label = "Controls",
            label = "Controls",
            controls = {
                {type = "slider", label_key = "settings.control.mouse_sensitivity", default_label = "Mouse sensitivity", label = "Mouse sensitivity", value = 0.55, default = 0.55, step = 0.05, setting = "controls.mouse_sensitivity"},
                {type = "toggle", label_key = "settings.control.invert_y", default_label = "Invert Y axis", label = "Invert Y axis", value = false, default = false, setting = "controls.invert_y"},
                {
                    type = "choice",
                    label_key = "settings.control.input_prompt",
                    default_label = "Input prompt",
                    label = "Input prompt",
                    options = {"Controller", "Keyboard"},
                    option_label_keys = {"settings.option.input.controller", "settings.option.input.keyboard"},
                    option_label_defaults = {"Controller", "Keyboard"},
                    option_labels = {"Controller", "Keyboard"},
                    value_index = 2,
                    default_index = 2,
                    setting = "controls.prompt_input",
                },
            },
        },
        {
            label_key = "settings.tab.accessibility",
            default_label = "Accessibility",
            label = "Accessibility",
            controls = {
                {type = "toggle", label_key = "settings.control.large_text", default_label = "Large text", label = "Large text", value = false, default = false, setting = "accessibility.big_text"},
                {type = "toggle", label_key = "settings.control.high_contrast", default_label = "High contrast", label = "High contrast", value = false, default = false, setting = "accessibility.high_contrast"},
                {type = "toggle", label_key = "settings.control.reduced_animations", default_label = "Reduced animations", label = "Reduced animations", value = false, default = false, setting = "accessibility.reduced_animations"},
            },
        },
        {
            label_key = "settings.tab.video",
            default_label = "Video Settings",
            label = "Video Settings",
            controls = {
                {
                    type = "choice",
                    label_key = "settings.control.window_mode",
                    default_label = "Window mode",
                    label = "Window mode",
                    options = {"Windowed", "Borderless", "Fullscreen"},
                    option_label_keys = {"settings.option.window_mode.windowed", "settings.option.window_mode.borderless", "settings.option.window_mode.fullscreen"},
                    option_label_defaults = {"Windowed", "Borderless", "Fullscreen"},
                    option_labels = {"Windowed", "Borderless", "Fullscreen"},
                    value_index = 2,
                    default_index = 2,
                    setting = "video.window_mode",
                },
                {
                    type = "choice",
                    label_key = "settings.control.fps_limit",
                    default_label = "FPS limit",
                    label = "FPS limit",
                    options = {"Unlimited", "30", "60", "120", "144", "240"},
                    option_label_keys = {"settings.option.fps.unlimited"},
                    option_label_defaults = {"Unlimited", "30", "60", "120", "144", "240"},
                    option_labels = {"Unlimited", "30", "60", "120", "144", "240"},
                    value_index = 1,
                    default_index = 1,
                    value_map = {0, 30, 60, 120, 144, 240},
                    setting = "video.fps_limit",
                },
                {type = "toggle", label_key = "settings.control.show_fps", default_label = "Show FPS", label = "Show FPS", value = false, default = false, setting = "video.show_fps"},
            },
        },
        {
            label_key = "settings.tab.audio",
            default_label = "Audio Settings",
            label = "Audio Settings",
            controls = {
                {type = "slider", label_key = "settings.control.master_volume", default_label = "Master volume", label = "Master volume", value = 0.8, default = 0.8, step = 0.05, setting = "audio.master_volume"},
                {type = "slider", label_key = "settings.control.sfx_volume", default_label = "SFX volume", label = "SFX volume", value = 0.7, default = 0.7, step = 0.05, setting = "audio.sfx_volume"},
                {type = "slider", label_key = "settings.control.music_volume", default_label = "Music volume", label = "Music volume", value = 0.6, default = 0.6, step = 0.05, setting = "audio.music_volume"},
                {type = "toggle", label_key = "settings.control.mute_sfx", default_label = "Mute SFX", label = "Mute SFX", value = false, default = false, setting = "audio.mute_sfx"},
                {type = "toggle", label_key = "settings.control.mute_music", default_label = "Mute music", label = "Mute music", value = false, default = false, setting = "audio.mute_music"},
            },
        },
    },
    actions = {
        {label_key = "settings.action.reset", default_label = "Reset", label = "Reset", action = "reset"},
        {label_key = "settings.action.confirm", default_label = "Confirm", label = "Confirm", action = "confirm"},
        {label_key = "settings.action.back", default_label = "Back", label = "Back", action = "back"},
    },
    assets = {
        manuzio_background_path = "resources/ui/menu_manuzio.png",
        illustrated_background_path = "resources/ui/menu_illustrated.png",
        background_path = "resources/ui/menu.png",
        font_text = "resources/font/AldineAetna-Regular.ttf",
        font_uppercase = "resources/font/AldineAetna-Regular.ttf",
        font_fallback = "resources/font/Cardo-Regular.ttf",
    },
    colors = {
        title_gold = Art.rgb("reward"),
        text_secondary = Art.rgb("quiet"),
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
end)()
Bundle.frontend = (function()
local Parts = {}

-- Main menu
Parts.menu = (function()
return {
    assets = {
        -- Manuzio printshop ships in the repository (from 0.1.9).
        -- The former illustration is an optional local compatibility
        -- fallback; menu.png remains the final shipping fallback.
        manuzio_background_path = "resources/ui/menu_manuzio.png",
        illustrated_background_path = "resources/ui/menu_illustrated.png",
        background_path = "resources/ui/menu.png",
        music_path = "resources/sounds/maintitle.ogg",
        font_text = "resources/font/AldineAetna-Regular.ttf",
        font_uppercase = "resources/font/AldineAetna-Regular.ttf",
        font_fallback = "resources/font/Cardo-Regular.ttf",
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
end)()

-- Campaign selection
Parts.campaign = (function()
return {
    campaigns = {
        {
            id = "farkle-prototype",
            title = "Farkle Roguelite",
            detail = "Playable prototype · three commissions",
            implemented = true,
        },
    },
    assets = {
        -- Manuzio printshop ships in the repository (from 0.1.9).
        -- The former illustration is an optional local compatibility
        -- fallback; menu.png remains the final shipping fallback.
        manuzio_background_path = "resources/ui/menu_manuzio.png",
        illustrated_background_path = "resources/ui/menu_illustrated.png",
        background_path = "resources/ui/menu.png",
        font_text = "resources/font/AldineAetna-Regular.ttf",
        font_uppercase = "resources/font/AldineAetna-Regular.ttf",
        font_fallback = "resources/font/Cardo-Regular.ttf",
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
end)()

-- Startup splash
Parts.splash = (function()
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
        title_font_primary = "resources/font/AldineAetna-Regular.ttf",
        title_font_fallback = "resources/font/Cardo-Regular.ttf",
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
end)()

return Parts
end)()
Bundle.frontend.palette = Bundle.palette
Bundle.frontend.settings = Bundle.settings
return Bundle.frontend
