function love.load ()
    background = love.graphics.newImage('background.png')
    form = love.graphics.newImage('form.png')
    canvas = love.graphics.newCanvas()
    x, y = 320, 230
    enabled = true
    
    
    local pixelcode = [[
        
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
        
            // n represents where the source of the mirror pixels start.
            // 1.0 mirrors from the very top of the screen.
            // 0.5 mirrors from half-way up the screen.
            number n = 0.5;
            
            // Alter reflection with a slight blue tint
            vec4 overlayColor = vec4(0.1, 0.3, 0.6, 1.0);
        
            // Its a kind fo magic pink
            vec4 texcolor = Texel(texture, texture_coords);
            if (texcolor.r == 1.0 && texcolor.g == 0.0 && texcolor.b == 1.0)
            {
                // Mirror mirror on the wall
                vec2 mirrorpoint = vec2(
                    texture_coords.x,
                    1.0 - (texture_coords.y * n)
                    );
                
                return Texel(texture, mirrorpoint) * overlayColor;
                
            }
            else 
            {
                //vec4 texcolor = Texel(texture, texture_coords);
                return texcolor * color;
            }
        }
    ]]

    shader = love.graphics.newShader(pixelcode, nil)

end

function love.keypressed (key)
    if key == 'escape' then love.event.quit() end
    if key == 'tab' then enabled = not enabled end
end

function love.update (dt)
    if love.keyboard.isDown('left') then
        x = x - 200 * dt
    end
    if love.keyboard.isDown('right') then
        x = x + 200 * dt
    end
    
end

function love.draw ()
    
    -- i discovered you must draw the scene to a canvas before applying a shader,
    -- as the shader does not cross over between drawing elements, i.e.
    -- the man figure does not reflect into the background image.
    love.graphics.setCanvas(canvas)
    love.graphics.draw(background, 0, 0)
    love.graphics.draw(form, x, y)
    love.graphics.setCanvas()
    
    -- draw the canvas
    if enabled then
        love.graphics.setShader(shader)
    end
    love.graphics.draw(canvas, 0, 0)
    love.graphics.setShader()

    -- how fast can you go
    love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
    love.graphics.print("[tab] toggle", 150, 10)
end
