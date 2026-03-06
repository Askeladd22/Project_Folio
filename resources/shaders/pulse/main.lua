local gr = love.graphics
local floor,pi,sin,cos,rad = math.floor,math.pi,math.sin,math.cos,math.rad
local pulse = require 'pulse'

love.load = function()
	local w, h = 800,600
	screen	= { w = w, h = h }
	love.window.setMode( screen.w, screen.h )
	love.window.setTitle( 'Pulse Shader Test - a gradient stencil' )
	gr.setFont(gr.newFont( 'davidbd.ttf', screen.w/40 ))
	gr.setBackgroundColor( 0, 0, 0, 255 )
	imageName = 'PulseImage.png'
	image = gr.newImage('MyTest1.bmp')
	star = {
		{
		x	= screen.w/2,
		y	= screen.h/2,
		rd	= screen.w/4.5,	-- outer radius
		tk	= 0.35,			-- relative thickness
		n	= 5,			-- number of sides
		a	= pi,			-- rotation
		bc	= {255,0,0},	-- bright triangle color
		dc	= {125,0,0},	-- dark triangle color
		md	= 'fill'		-- mode
		},
		{
		x	= screen.w/2,
		y	= screen.h/2,
		rd	= screen.w/4.5,
		tk	= 0.35,
		n	= 5,
		a	= pi,
		bc	= {0,0,0,155},
		dc	= {0,0,0,155},
		md	= 'line'
		},
		{
		x	= 150,
		y	= 100,
		rd	= 20,		-- small star
		tk	= 0.35,
		n	= 5,
		a	= pi,
		bc	= {255,0,0,255},
		dc	= {155,0,0,255},
		md	= 'fill'
		} }
	border = {
		x	= 80,
		y	= 40,
		r	= 60,
		c	= {5,5,255,255},
		draw= function()
			gr.setLineWidth(2)
			for i = 1, 25 do
				gr.setColor( border.c[1], border.c[2], border.c[3]-2*i, border.c[4]-10*i )
				roundrect( 'line', border.x+i, border.y+i, screen.w-2*(border.x+i), screen.h-2*border.y-2*i,border.r-i )
				end
			gr.setLineWidth(1)
			end
		}
	text = {
		x	= screen.w-8*screen.w/35,
		y	= screen.h - 100,
		m	= 'Pulse',
		c	= {255,255,0},
		draw = function()
			gr.setColor( text.c )
			gr.print( text.m, text.x, text.y )
			end
		}
	pu = {
		center	= { w/2, h/2 },				-- center of area to remove
		time	= 0.0,
		radius	= 1.0,						-- radius of area to remove
		min		= 0.0						-- minimum alpha remaining
		}
	for i,j in pairs( pu ) do pulse:send( i, j ) end
	end

love.draw = function()
gr.draw(image,400,300,0,.8,.8,image:getWidth()/2,image:getHeight()/2)
	drawGrid()
	for i = 1, #star do drawStar( star[i] ) end
	border.draw()
	text.draw()
	end

love.update = function( dt )
	star[3].a=star[3].a - 2 * dt
	pu.time = pu.time + dt
	pulse:send( 'time',pu.time)
	end

love.keypressed = function( key )
	if key == 'escape'	then love.event.push( 'quit' ) end
	if key == 's' then save	= true end
	end

drawGrid = function()
	gr.setShader( pulse )
		gr.setColor( 0, 0, 0, 255 )
		gr.rectangle( 'fill', 0, 0, 800, 600 )
		gr.setColor(185,0,0)
		for h = 55,  screen.h - 60, 7 do gr.line( 100, h, screen.w - 100, h ) end
		for v = 100, screen.w -100, 7 do gr.line( v,  60, v, screen.h -  60 ) end
		gr.setShader(  )
	end

drawStar = function( s )
	local point 		= { x = {}, y = {} }	-- Outer Points
	local p				= { x = {}, y = {} }	-- Inner Points
	local deg			= 360/s.n
	local j				= 0
	for i				= 0, 361 - deg, deg do
		j				= j + 1
		point.x[j]		= s.rd * sin( rad(i)+s.a ) + s.x
		point.y[j]		= s.rd * cos( rad(i)+s.a ) + s.y
		p.x[j]			= s.tk*s.rd * sin( rad(i+deg/2)+s.a ) + s.x
		p.y[j]			= s.tk*s.rd * cos( rad(i+deg/2)+s.a ) + s.y
		end
	-- Brighter Facets
	gr.setColor( s.bc )
	for i = 1, s.n do
		gr.polygon( s.md, point.x[i], point.y[i], p.x[i], p.y[i], s.x, s.y )
		end
	-- Darker Facets
	gr.setColor( s.dc )
	for i = 2, s.n do
		gr.polygon( s.md, point.x[i], point.y[i], p.x[i-1], p.y[i-1], s.x,s.y )
		end
	gr.polygon( s.md, point.x[1], point.y[1], p.x[s.n], p.y[s.n], s.x, s.y )
	end

roundrect = function(mode, x, y, width, height, rx, ry)
	local points = {}
	local rx = rx or 10
	local ry = ry or rx
	local tI, hP = table.insert, .5*pi
	if rx > width*.5 then rx = width*.5 end
	if ry > height*.5 then ry = height*.5 end
	local precision = (rx + ry) * .1
	local X1, Y1, X2, Y2 = x + rx, y + ry, x + width - rx, y + height - ry
	local sin, cos = math.sin, math.cos
	for i = 0, precision do
		local a = (i/precision-1)*hP
		tI(points, X2 + rx*cos(a))
		tI(points, Y1 + ry*sin(a))
	end
	for i = 0, precision do
		local a = (i/precision)*hP
		tI(points, X2 + rx*cos(a))
		tI(points, Y2 + ry*sin(a))
	end
	for i = 0, precision do
		local a = (i/precision+1)*hP
		tI(points, X1 + rx*cos(a))
		tI(points, Y2 + ry*sin(a))
	end
	for i = 0, precision do
		local a = (i/precision+2)*hP
		tI(points, X1 + rx*cos(a))
		tI(points, Y1 + ry*sin(a))
	end
	if mode == 'points' then return points end
	gr.polygon( mode, unpack( points ) )
end
