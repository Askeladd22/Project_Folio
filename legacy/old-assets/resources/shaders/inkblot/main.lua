local shader = require 'ink'
local gr = love.graphics
function love.load()
	wd, ht = 1250, 800
	--image = gr.newImage('test.jpg')
	--wd, ht = image:getWidth(), image:getHeight()
	love.window.setMode( wd, ht, {} )
	gt = 0
	love.window.setTitle( 'Ink' )
	screen = { wd, ht}
	love.mouse.setPosition( wd/2, ht/2 )
	shader.effect:send( 'screen', screen )
	love.mouse.setVisible( false )
	end

function love.update( dt )
	gt = gt + 0.5 * dt
	shader.effect:send( 'time', gt )
	mx, my = love.mouse.getPosition()
	--shader.effect:send( 'mouse', { mx / wd,( ht-my) / ht})
	 --shader.effect:send( 'mouse', { mx ,( ht-my)})
	end

function love.draw()
	gr.setColor(255,255,255,255)
	--gr.draw(image)
	gr.setShader( shader.effect )
		gr.rectangle( "fill", 0, 0, wd, ht )
		gr.setShader()

	gr.setColor( 255, 255, 255, 255 )
	gr.print( 'fps: '..love.timer.getFPS(), 0, 0 )
	end

function love.keypressed( key )
	if key == 'escape'	then love.event.push( 'quit' )	end
	end
