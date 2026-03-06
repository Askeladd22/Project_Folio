local RuntimeState = {}

local state = {
    game_settings = nil,
    show_fps = false,
    target_fps = 0,
    ui_scale = 1.0,
    ui_high_contrast = false,
    ui_reduced_animations = false,
}

local function copy_table(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = copy_table(v)
    end
    return out
end

function RuntimeState.apply_settings(settings)
    local next_settings = copy_table(settings or {})
    local video = type(next_settings.video) == "table" and next_settings.video or {}
    local accessibility = type(next_settings.accessibility) == "table" and next_settings.accessibility or {}

    state.game_settings = next_settings
    state.show_fps = video.show_fps and true or false
    state.target_fps = tonumber(video.fps_limit) or 0
    state.ui_scale = accessibility.big_text and 1.18 or 1.0
    state.ui_high_contrast = accessibility.high_contrast and true or false
    state.ui_reduced_animations = accessibility.reduced_animations and true or false
end

function RuntimeState.get_game_settings()
    return copy_table(state.game_settings)
end

function RuntimeState.should_show_fps()
    return state.show_fps
end

function RuntimeState.get_target_fps()
    return state.target_fps
end

function RuntimeState.get_ui_scale()
    return state.ui_scale
end

function RuntimeState.is_ui_high_contrast()
    return state.ui_high_contrast
end

function RuntimeState.is_ui_reduced_animations()
    return state.ui_reduced_animations
end

return RuntimeState
