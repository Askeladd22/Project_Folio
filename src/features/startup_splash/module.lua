local Splash = {}

local AudioManager = require("src.core.audio_manager")
local I18n = require("src.core.i18n")
local Navigation = require("src.core.navigation")
local RuntimeUI = require("src.core.runtime_ui")
local Schema = require("src.core.schema")
local StartupSplashSchema = require("src.data.startup_splash_schema")

local PI = math.pi

local ASSET_SCHEMA = StartupSplashSchema.assets or {}
local COLOR_SCHEMA = StartupSplashSchema.colors or {}
local TIMING_SCHEMA = StartupSplashSchema.timing or {}
local METRICS_SCHEMA = StartupSplashSchema.metrics or {}
local TEXT_SCHEMA = StartupSplashSchema.text or {}
local FLOW_SCHEMA = StartupSplashSchema.flow or {}

local expect_string = Schema.expect_string
local expect_number = Schema.expect_number
local expect_entry = Schema.expect_entry
local expect_color3 = Schema.expect_color3
local expect_string_list = Schema.expect_string_list

local COLOR_PINK = expect_color3(COLOR_SCHEMA.pink, "colors.pink")
local COLOR_BLUE = expect_color3(COLOR_SCHEMA.blue, "colors.blue")
local COLOR_BLACK = expect_color3(COLOR_SCHEMA.black, "colors.black")
local COLOR_WHITE = expect_color3(COLOR_SCHEMA.white, "colors.white")

local SHADER_FILL_PATH = expect_string(ASSET_SCHEMA.shader_fill_path, "assets.shader_fill_path")
local SHADER_SHRINK_PATH = expect_string(ASSET_SCHEMA.shader_shrink_path, "assets.shader_shrink_path")
local SHADER_TITLE_PATH = expect_string(ASSET_SCHEMA.shader_title_path, "assets.shader_title_path")
local SHADER_TITLE_OVERLAY_PATH = expect_string(ASSET_SCHEMA.shader_title_overlay_path, "assets.shader_title_overlay_path")
local IMAGE_CIRCLE_PATH = expect_string(ASSET_SCHEMA.image_circle_path, "assets.image_circle_path")
local IMAGE_HEART_PATH = expect_string(ASSET_SCHEMA.image_heart_path, "assets.image_heart_path")
local IMAGE_LOVE_PATH = expect_string(ASSET_SCHEMA.image_love_path, "assets.image_love_path")
local IMAGE_TITLE_STROKE_MAP_PATH = expect_string(ASSET_SCHEMA.image_title_stroke_map_path, "assets.image_title_stroke_map_path")
local IMAGE_TITLE_LOGO_CANDIDATES = expect_string_list(ASSET_SCHEMA.image_title_logo_candidates, "assets.image_title_logo_candidates")
local TITLE_FONT_PRIMARY = expect_string(ASSET_SCHEMA.title_font_primary, "assets.title_font_primary")
local TITLE_FONT_FALLBACK = expect_string(ASSET_SCHEMA.title_font_fallback, "assets.title_font_fallback")
local TITLE_BASE_FONT_SIZE = expect_number(ASSET_SCHEMA.title_base_font_size, "assets.title_base_font_size")
local BRANDING_TITLE_ENTRY = expect_entry(TEXT_SCHEMA.branding_title, "text.branding_title")
local NEXT_MODULE = expect_string(FLOW_SCHEMA.next_module, "flow.next_module")
local SKIP_AUDIO_SFX = expect_string(FLOW_SCHEMA.skip_audio, "flow.skip_audio")
local SKIP_MOUSE_BUTTON = expect_number(FLOW_SCHEMA.skip_mouse_button, "flow.skip_mouse_button")

local HEART_DIAMETER_RATIO = expect_number(METRICS_SCHEMA.heart_diameter_ratio, "metrics.heart_diameter_ratio")
local CIRCLE_DIAMETER_RATIO = expect_number(METRICS_SCHEMA.circle_diameter_ratio, "metrics.circle_diameter_ratio")
local LOVE_DIAMETER_RATIO = expect_number(METRICS_SCHEMA.love_diameter_ratio, "metrics.love_diameter_ratio")

local function tr(key, fallback, params)
    return I18n.t(key, fallback, params)
end

local function get_title_text()
    return tr(BRANDING_TITLE_ENTRY.key, BRANDING_TITLE_ENTRY.default)
end

local BASE_SPLASH_DURATION = expect_number(TIMING_SCHEMA.base_splash_duration, "timing.base_splash_duration")
local BASE_HEART_AT = expect_number(TIMING_SCHEMA.base_heart_at, "timing.base_heart_at")
local BASE_HEART_BOUNCE_TIME = expect_number(TIMING_SCHEMA.base_heart_bounce_time, "timing.base_heart_bounce_time")
local BASE_HEART_BOUNCE_DELAY = expect_number(TIMING_SCHEMA.base_heart_bounce_delay, "timing.base_heart_bounce_delay")
local BASE_HEART_START_ANGLE = expect_number(TIMING_SCHEMA.base_heart_start_angle, "timing.base_heart_start_angle")
local BASE_SHIFT_DELAY = expect_number(TIMING_SCHEMA.base_shift_delay, "timing.base_shift_delay")
local BASE_SHIFT_DURATION = expect_number(TIMING_SCHEMA.base_shift_duration, "timing.base_shift_duration")
local BASE_TITLE_DURATION = expect_number(TIMING_SCHEMA.base_title_duration, "timing.base_title_duration")
local BASE_TITLE_FADE_IN = expect_number(TIMING_SCHEMA.base_title_fade_in, "timing.base_title_fade_in")
local BASE_TITLE_FADE_OUT = expect_number(TIMING_SCHEMA.base_title_fade_out, "timing.base_title_fade_out")

local REDUCED_TIMING_SCALE = expect_number(TIMING_SCHEMA.reduced_timing_scale, "timing.reduced_timing_scale")
local MIN_REDUCED_TITLE_DURATION = expect_number(TIMING_SCHEMA.min_reduced_title_duration, "timing.min_reduced_title_duration")

local timer = 0
local splashDuration = BASE_SPLASH_DURATION
local heartAt = BASE_HEART_AT
local heartBounceTime = BASE_HEART_BOUNCE_TIME
local heartBounceDelay = BASE_HEART_BOUNCE_DELAY
local heartStartAngle = BASE_HEART_START_ANGLE
local shiftDelay = BASE_SHIFT_DELAY
local shiftDuration = BASE_SHIFT_DURATION
local titleDuration = BASE_TITLE_DURATION
local titleFadeIn = BASE_TITLE_FADE_IN
local titleFadeOut = BASE_TITLE_FADE_OUT

local fillShader = nil
local shrinkShader = nil

local circleImage = nil
local circleImageW = 1
local circleImageH = 1

local heartImage = nil
local heartImageW = 1
local heartImageH = 1

local loveImage = nil
local loveImageW = 1
local loveImageH = 1

local titleLogoImage = nil
local titleLogoW = 1
local titleLogoH = 1
local titleLogoPath = nil
local titleStrokeMapImage = nil
local titleFallbackMapImage = nil

local screenW = 0
local screenH = 0
local minLength = 0
local heartDiameter = 0
local circleDiameter = 0
local loveDiameter = 0

local titleFont = nil
local titleFontSize = 0
local titleShader = nil
local titleOverlayShader = nil

local function clamp01(v)
    if v < 0 then
        return 0
    end
    if v > 1 then
        return 1
    end
    return v
end

local function refreshMetrics()
    screenW, screenH = love.graphics.getDimensions()
    minLength = math.min(screenW, screenH)
    heartDiameter = minLength * HEART_DIAMETER_RATIO
    circleDiameter = minLength * CIRCLE_DIAMETER_RATIO
    loveDiameter = minLength * LOVE_DIAMETER_RATIO
end

local function tryLoadShader(path)
    if not (love.graphics and love.graphics.newShader) then
        return nil
    end
    if love.filesystem and love.filesystem.getInfo and not love.filesystem.getInfo(path) then
        return nil
    end
    local ok, shader = pcall(function()
        return love.graphics.newShader(path)
    end)
    if ok then
        return shader
    end
    return nil
end

local function tryLoadImage(path)
    if not (love.graphics and love.graphics.newImage) then
        return nil, 1, 1
    end
    if love.filesystem and love.filesystem.getInfo and not love.filesystem.getInfo(path) then
        return nil, 1, 1
    end
    local ok, image = pcall(function()
        return love.graphics.newImage(path)
    end)
    if not ok or not image then
        return nil, 1, 1
    end
    return image, image:getWidth(), image:getHeight()
end

local function tryLoadFirstAvailableImage(paths)
    if type(paths) ~= "table" then
        return nil, 1, 1, nil
    end
    for _, path in ipairs(paths) do
        local image, iw, ih = tryLoadImage(path)
        if image then
            return image, iw, ih, path
        end
    end
    return nil, 1, 1, nil
end

local function tryBuildSolidImage(r, g, b, a)
    if not (love.image and love.image.newImageData and love.graphics and love.graphics.newImage) then
        return nil
    end
    local ok, data = pcall(function()
        local imageData = love.image.newImageData(1, 1)
        imageData:setPixel(0, 0, r, g, b, a)
        return imageData
    end)
    if not ok or not data then
        return nil
    end
    local okImage, image = pcall(function()
        return love.graphics.newImage(data)
    end)
    if okImage and image then
        return image
    end
    return nil
end

local function tryBuildProceduralStrokeMap(logoPath, logoImage)
    if not (love.image and love.image.newImageData and love.graphics and love.graphics.newImage) then
        return nil
    end

    local sourceData = nil
    if logoPath and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(logoPath) then
        local ok, data = pcall(function()
            return love.image.newImageData(logoPath)
        end)
        if ok and data then
            sourceData = data
        end
    end

    if (not sourceData) and logoImage and logoImage.newImageData then
        local ok, data = pcall(function()
            return logoImage:newImageData()
        end)
        if ok and data then
            sourceData = data
        end
    end

    if not sourceData then
        return nil
    end

    local sw, sh = sourceData:getDimensions()
    if sw <= 0 or sh <= 0 then
        return nil
    end

    local outData = love.image.newImageData(sw, sh)
    local denomX = math.max(1, sw - 1)
    local denomY = math.max(1, sh - 1)
    local pi2 = PI * 2

    for y = 0, sh - 1 do
        local v = y / denomY
        for x = 0, sw - 1 do
            local _, _, _, srcA = sourceData:getPixel(x, y)
            if srcA > 0.01 then
                local u = x / denomX
                local base = u * 0.76 + (1 - v) * 0.22
                local curve = 0.06 * math.sin((u * 11.0 + v * 4.0) * pi2)
                    + 0.03 * math.sin((u * 23.0 - v * 15.0) * pi2)
                local seed = math.sin((x * 12.9898 + y * 78.233) * 0.0174532925) * 43758.5453
                local jitter = (seed - math.floor(seed)) - 0.5
                local progress = clamp01(base + curve + jitter * 0.05)
                outData:setPixel(x, y, progress, progress, progress, srcA)
            else
                outData:setPixel(x, y, 0, 0, 0, 0)
            end
        end
    end

    local okImage, outImage = pcall(function()
        return love.graphics.newImage(outData)
    end)
    if okImage and outImage then
        outImage:setFilter("linear", "linear")
        return outImage
    end
    return nil
end

local function switchToMainMenu()
    local ok = Navigation.go(NEXT_MODULE)
    return ok
end

local function skipSplash(playSound)
    if playSound then
        AudioManager.play_ui(SKIP_AUDIO_SFX)
    end
    switchToMainMenu()
end

local function interpolateBounce(x)
    return 1 - 2 ^ (-8 * x ^ 0.7) * math.cos(6.5 * PI * x)
end

local function interpolateMovement(x)
    return 0.5 * math.sin(PI * ((x - 1) ^ 2 + 0.5)) + 0.5
end

local function setColor(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

local function drawSplitBackground()
    local leftW = math.floor(screenW * 0.5)
    setColor(COLOR_PINK)
    love.graphics.rectangle("fill", 0, 0, leftW, screenH)
    setColor(COLOR_BLUE)
    love.graphics.rectangle("fill", leftW, 0, screenW - leftW, screenH)
end

local function drawHeartFallback(centerX, centerY, diameter, angle, scale)
    local s = math.max(0.001, scale or 1)
    local unit = diameter * 0.19

    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(angle or 0)
    love.graphics.scale(s, s)

    setColor(COLOR_WHITE)
    love.graphics.circle("fill", -unit * 0.85, -unit * 0.12, unit)
    love.graphics.circle("fill", unit * 0.85, -unit * 0.12, unit)
    love.graphics.polygon("fill",
        -unit * 1.86, unit * 0.08,
        0, unit * 2.25,
        unit * 1.86, unit * 0.08
    )

    love.graphics.pop()
end

local function drawCircleFallback(centerX, centerY, diameter, angle)
    local r = diameter * 0.5
    local rotation = angle or 0

    setColor(COLOR_BLUE)
    love.graphics.arc("fill", "pie", centerX, centerY, r, rotation, rotation + PI)

    setColor(COLOR_PINK)
    love.graphics.arc("fill", "pie", centerX, centerY, r, rotation + PI, rotation + (2 * PI))
end

local function tryLoadTitleFont(desiredSize)
    local candidates = {
        TITLE_FONT_PRIMARY,
        TITLE_FONT_FALLBACK,
    }
    for _, fname in ipairs(candidates) do
        if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(fname) then
            local ok, font = pcall(function()
                return love.graphics.newFont(fname, desiredSize)
            end)
            if ok and font then
                return font
            end
        end
    end

    local ok, fallback = pcall(function()
        return love.graphics.newFont(desiredSize)
    end)
    if ok and fallback then
        return fallback
    end
    return love.graphics.getFont()
end

local function drawTitleCard()
    setColor(COLOR_BLACK)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    local elapsed = timer - splashDuration
    local fadeInAlpha = clamp01(elapsed / math.max(0.001, titleFadeIn))
    local fadeOutStart = math.max(0, titleDuration - titleFadeOut)
    local fadeOutAlpha = clamp01((elapsed - fadeOutStart) / math.max(0.001, titleFadeOut))
    local alpha = fadeInAlpha * (1 - fadeOutAlpha)
    if alpha <= 0 then
        return
    end

    local highContrast = RuntimeUI.high_contrast()
    local reduced = RuntimeUI.reduced_animations()

    if titleOverlayShader then
        local overlayTime = math.max(0, elapsed) * (reduced and 0.55 or 1.0)
        pcall(function()
            titleOverlayShader:send("screen", {screenW, screenH})
        end)
        pcall(function()
            titleOverlayShader:send("time", overlayTime)
        end)
        pcall(function()
            titleOverlayShader:send("alpha", alpha * (highContrast and 0.50 or 0.38))
        end)

        love.graphics.setShader(titleOverlayShader)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        love.graphics.setShader()
    end

    if titleLogoImage then
        local maxW = screenW * (RuntimeUI.big_text() and 0.94 or 0.88)
        local maxH = screenH * 0.64
        local logoScale = math.min(maxW / titleLogoW, maxH / titleLogoH)
        if logoScale > 0 then
            local drawW = titleLogoW * logoScale
            local drawH = titleLogoH * logoScale
            local tx = (screenW - drawW) * 0.5
            local ty = (screenH - drawH) * 0.5

            love.graphics.setColor(0.03, 0.02, 0.015, alpha * (highContrast and 0.84 or 0.64))
            love.graphics.draw(titleLogoImage, tx + RuntimeUI.sized(2), ty + RuntimeUI.sized(2), 0, logoScale, logoScale)

            if titleShader and love.graphics.stencil and love.graphics.setStencilTest then
                love.graphics.stencil(function()
                    love.graphics.draw(titleLogoImage, tx, ty, 0, logoScale, logoScale)
                end, "replace", 1)
                love.graphics.setStencilTest("greater", 0)

                local shaderTime = math.max(0, elapsed) * (reduced and 0.65 or 1.00)
                local strokeMapForShader = titleStrokeMapImage or titleFallbackMapImage
                pcall(function()
                    titleShader:send("screen", {screenW, screenH})
                end)
                pcall(function()
                    titleShader:send("time", shaderTime)
                end)
                pcall(function()
                    titleShader:send("alpha", alpha)
                end)
                pcall(function()
                    titleShader:send("logoRect", {tx, ty, drawW, drawH})
                end)
                pcall(function()
                    titleShader:send("strokeMapMix", titleStrokeMapImage and 1.0 or 0.0)
                end)
                if strokeMapForShader then
                    pcall(function()
                        titleShader:send("strokeMap", strokeMapForShader)
                    end)
                end

                love.graphics.setShader(titleShader)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.rectangle("fill", 0, 0, screenW, screenH)
                love.graphics.setShader()
                love.graphics.setStencilTest()

                love.graphics.setColor(1, 1, 1, alpha * (highContrast and 0.52 or 0.36))
                love.graphics.draw(titleLogoImage, tx, ty, 0, logoScale, logoScale)
            else
                love.graphics.setColor(1, 1, 1, alpha)
                love.graphics.draw(titleLogoImage, tx, ty, 0, logoScale, logoScale)
            end
        end
        return
    end

    local prevFont = love.graphics.getFont()
    local font = titleFont or prevFont
    love.graphics.setFont(font)
    local title_text = get_title_text()

    local textWidth = font:getWidth(title_text)
    local textHeight = font:getHeight()
    local tx = (screenW - textWidth) * 0.5
    local ty = (screenH - textHeight) * 0.5

    love.graphics.setColor(0.04, 0.03, 0.02, alpha * (highContrast and 0.8 or 0.6))
    love.graphics.print(title_text, tx + 2, ty + 2)

    if titleShader and love.graphics.stencil and love.graphics.setStencilTest then
        love.graphics.stencil(function()
            love.graphics.print(title_text, tx, ty)
        end, "replace", 1)
        love.graphics.setStencilTest("greater", 0)

        local shaderTime = math.max(0, elapsed) * (reduced and 0.65 or 1.00)
        local strokeMapForShader = titleStrokeMapImage or titleFallbackMapImage
        pcall(function()
            titleShader:send("screen", {screenW, screenH})
        end)
        pcall(function()
            titleShader:send("time", shaderTime)
        end)
        pcall(function()
            titleShader:send("alpha", alpha)
        end)
        pcall(function()
            titleShader:send("logoRect", {0, 0, screenW, screenH})
        end)
        pcall(function()
            titleShader:send("strokeMapMix", 0.0)
        end)
        if strokeMapForShader then
            pcall(function()
                titleShader:send("strokeMap", strokeMapForShader)
            end)
        end

        love.graphics.setShader(titleShader)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        love.graphics.setShader()
        love.graphics.setStencilTest()

        love.graphics.setColor(1, 1, 1, alpha * (highContrast and 0.38 or 0.24))
        love.graphics.print(title_text, tx, ty)
    else
        love.graphics.setColor(highContrast and 1 or 0.95, highContrast and 0.98 or 0.91, highContrast and 0.94 or 0.83, alpha)
        love.graphics.print(title_text, tx, ty)
    end

    if prevFont then
        love.graphics.setFont(prevFont)
    end
end

local function applyTimingConfig(reduced, timingScale)
    splashDuration = BASE_SPLASH_DURATION * timingScale
    heartAt = BASE_HEART_AT * timingScale
    heartBounceTime = BASE_HEART_BOUNCE_TIME * timingScale
    heartBounceDelay = BASE_HEART_BOUNCE_DELAY * timingScale
    heartStartAngle = BASE_HEART_START_ANGLE
    shiftDelay = BASE_SHIFT_DELAY * timingScale
    shiftDuration = BASE_SHIFT_DURATION * timingScale
    titleDuration = BASE_TITLE_DURATION * timingScale
    if reduced then
        titleDuration = math.max(MIN_REDUCED_TITLE_DURATION, titleDuration)
    end
    titleFadeIn = math.min(titleDuration, BASE_TITLE_FADE_IN * timingScale)
    titleFadeOut = math.min(titleDuration, BASE_TITLE_FADE_OUT * timingScale)
end

local function loadTransitionAssets()
    fillShader = tryLoadShader(SHADER_FILL_PATH)
    shrinkShader = tryLoadShader(SHADER_SHRINK_PATH)

    circleImage, circleImageW, circleImageH = tryLoadImage(IMAGE_CIRCLE_PATH)
    heartImage, heartImageW, heartImageH = tryLoadImage(IMAGE_HEART_PATH)
    loveImage, loveImageW, loveImageH = tryLoadImage(IMAGE_LOVE_PATH)
end

local function loadTitleAssets()
    titleLogoImage, titleLogoW, titleLogoH, titleLogoPath = tryLoadFirstAvailableImage(IMAGE_TITLE_LOGO_CANDIDATES)

    local loadedStrokeMap = tryLoadImage(IMAGE_TITLE_STROKE_MAP_PATH)
    if not loadedStrokeMap then
        loadedStrokeMap = tryBuildProceduralStrokeMap(titleLogoPath, titleLogoImage)
    end
    titleStrokeMapImage = loadedStrokeMap

    if not titleFallbackMapImage then
        titleFallbackMapImage = tryBuildSolidImage(1, 1, 1, 1)
    end

    local desiredTitleFontSize = RuntimeUI.sized(TITLE_BASE_FONT_SIZE)
    if not titleFont or titleFontSize ~= desiredTitleFontSize then
        titleFont = tryLoadTitleFont(desiredTitleFontSize)
        titleFontSize = desiredTitleFontSize
    end

    titleShader = tryLoadShader(SHADER_TITLE_PATH)
    titleOverlayShader = tryLoadShader(SHADER_TITLE_OVERLAY_PATH)
end

function Splash:enter()
    timer = 0

    local reduced = RuntimeUI.reduced_animations()
    local timingScale = reduced and REDUCED_TIMING_SCALE or 1.0

    applyTimingConfig(reduced, timingScale)
    loadTransitionAssets()
    loadTitleAssets()

    refreshMetrics()
end

function Splash:update(dt)
    timer = timer + dt
    refreshMetrics()

    if timer >= (splashDuration + titleDuration) then
        skipSplash(false)
    end
end

function Splash:draw()
    refreshMetrics()

    if love.graphics.clear then
        love.graphics.clear(COLOR_BLACK[1], COLOR_BLACK[2], COLOR_BLACK[3], 1)
    end

    if timer < heartAt then
        if fillShader then
            love.graphics.setShader(fillShader)
            pcall(function()
                fillShader:send("t", timer ^ 0.9)
            end)
            love.graphics.rectangle("fill", 0, 0, screenW, screenH)
            love.graphics.setShader()
        else
            drawSplitBackground()
        end
        return
    end

    if timer < (heartAt + shiftDelay) then
        if shrinkShader then
            love.graphics.setShader(shrinkShader)
            pcall(function()
                shrinkShader:send("t", timer - heartAt)
            end)
            love.graphics.rectangle("fill", 0, 0, screenW, screenH)
            love.graphics.setShader()
        else
            setColor(COLOR_BLACK)
            love.graphics.rectangle("fill", 0, 0, screenW, screenH)
            drawCircleFallback(screenW * 0.5, screenH * 0.5, circleDiameter, PI / 4)
        end

        local x = (timer - heartAt - heartBounceDelay) / math.max(0.001, heartBounceTime)
        if x >= 0 then
            x = clamp01(x)
            local bounce = interpolateBounce(x)
            local centerX = screenW * 0.5
            local centerY = screenH * 0.5
            local angle = heartStartAngle - heartStartAngle * bounce

            if heartImage then
                setColor(COLOR_WHITE)
                love.graphics.draw(
                    heartImage,
                    centerX,
                    centerY,
                    angle,
                    bounce * (heartDiameter / heartImageW),
                    bounce * (heartDiameter / heartImageH),
                    heartImageW * 0.5,
                    heartImageH * 0.5
                )
            else
                drawHeartFallback(centerX, centerY, heartDiameter, angle, bounce)
            end
        end

        return
    end

    if timer >= splashDuration then
        drawTitleCard()
        return
    end

    setColor(COLOR_BLACK)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    local shiftX = (timer - (heartAt + shiftDelay)) / math.max(0.001, shiftDuration)
    shiftX = clamp01(shiftX)
    local shift = interpolateMovement(shiftX)
    local centerX = screenW * 0.5
    local centerY = screenH * 0.5

    setColor(COLOR_WHITE)

    if loveImage then
        love.graphics.draw(
            loveImage,
            centerX,
            centerY,
            0,
            loveDiameter / loveImageW,
            loveDiameter / loveImageW,
            loveImageW * 0.5 - (loveImageW * 0.5 * (shift * 1.2)),
            loveImageH * 0.5
        )
    else
        local barW = loveDiameter * 2.0
        local barH = loveDiameter
        love.graphics.rectangle("fill", centerX - barW * 0.5 * (1 - shift * 1.2), centerY - barH * 0.5, barW, barH)
    end

    if circleImage then
        love.graphics.draw(
            circleImage,
            centerX,
            centerY,
            PI / 4,
            circleDiameter / circleImageW,
            circleDiameter / circleImageH,
            circleImageW * 0.5 + (circleImageW * 0.5 * (shift * 1.2) * 0.707),
            circleImageH * 0.5 + (circleImageW * 0.5 * (shift * 1.2) * -0.707)
        )
    else
        drawCircleFallback(centerX, centerY, circleDiameter, PI / 4)
    end

    if heartImage then
        love.graphics.draw(
            heartImage,
            centerX,
            centerY,
            0,
            heartDiameter / heartImageW,
            heartDiameter / heartImageH,
            heartImageW * 0.5 + (heartImageW * 0.5 * (shift * 1.2) * (circleDiameter / heartDiameter)),
            heartImageH * 0.5
        )
    else
        drawHeartFallback(
            centerX + (heartDiameter * 0.5 * shift * 1.2 * (circleDiameter / heartDiameter)),
            centerY,
            heartDiameter,
            0,
            1
        )
    end
end

function Splash:keypressed(_key)
    skipSplash(true)
end

function Splash:mousepressed(_x, _y, button)
    if button == SKIP_MOUSE_BUTTON then
        skipSplash(true)
    end
end

return Splash
