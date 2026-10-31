-- Isolated Project Folio 2D-figure animation workshop, opt-in only.
-- No physical D6, no tray mesh and no non-2D character are instantiated.
local Figure=require('src.features.scriptorium.miniature_2d')
local Ink=require('src.features.scriptorium.folio_ink_text')
local PostFX=require('src.features.scriptorium.dream_postfx_2d')
local Toasts=require('src.features.farkle.toast_messages')
local Res=require('src.core.resolution_manager')
local g=love.graphics
local state={reduced=false,visible=false,fx=nil,figure=nil,text=nil,
  heading=nil,caption=nil,sheet=nil}

local function frame(n)
 g.push()
 g.translate((n-1)*96,0)
 local sway=math.sin((n-1)*math.pi/2)*3
 -- Deliberately original procedural flat illuminated-knight placeholder.
 g.setColor(.55,.36,.15,1)
 g.rectangle('fill',23,131,50,6)
 g.setColor(.13,.19,.26,1)
 g.polygon('fill',24,120,31,66,66,66,75,120)
 g.setColor(.73,.22,.17,1)
 g.polygon('fill',34,68,60,72,65,123,31,123)
 g.setColor(.82,.67,.36,1)
 g.rectangle('fill',40,79,15,5)
 g.setColor(.98,.87,.66,1)
 g.circle('fill',48+sway,52,18)
 g.setColor(.34,.37,.46,1)
 g.polygon('fill',27+sway,54,35+sway,27,62+sway,27,69+sway,54,
   60+sway,52,35+sway,52)
 g.setColor(.95,.80,.44,1)
 g.rectangle('fill',34+sway,50,28,3)
 g.setColor(.12,.13,.18,1)
 g.rectangle('fill',45+sway,53,6,3)
 g.setColor(.77,.67,.47,1)
 g.setLineWidth(4)
 g.line(70,71,80+3*math.sin(n),92)
 g.setColor(.89,.84,.73,1)
 g.setLineWidth(3)
 g.line(80+3*math.sin(n),92,81+3*math.sin(n),30)
 g.setColor(.52,.37,.11,1)
 g.rectangle('fill',71,64,15,4)
 g.pop()
end

local function build_sheet()
 local canvas=g.newCanvas(96*4,144)
 g.push('all')
 g.setCanvas(canvas)
 g.clear(0,0,0,0)
 for i=1,4 do frame(i) end
 g.pop()
 return canvas
end

local function reveal()
 state.figure:move_to(545,522,1.65,1.05,state.reduced)
 state.visible=true
 Toasts.show('La miniatura si desta!')
 state.text=Ink.new('Dal margine del codice, una figura prende vita.',{
  font=state.caption,wrap=620,speed=.040,color={.25,.15,.07,1}
 })
end

local function retreat()
 state.figure:return_to_page(.80,state.reduced)
 state.visible=false
 Toasts.show('Il monaco ritorna nel folio.')
 state.text=Ink.new('La figura ritorna alla sua miniatura.',{
  font=state.caption,wrap=620,speed=.040,color={.25,.15,.07,1}
 })
end

function love.load()
 love.window.setTitle('Project Folio - 2D miniature & ink laboratory')
 love.window.setMode(1280,720,{resizable=true,vsync=1})
 Res.init(1920,1080)
 state.heading=g.newFont('resources/font/IMFeENsc28P.ttf',34)
 state.caption=g.newFont('resources/font/IMFeENsc28P.ttf',22)
 state.sheet=build_sheet()
 state.figure=Figure.new(state.sheet,{
  x=545,y=522,scale=.88,frameWidth=96,frameHeight=144,
  frames=4,frameTime=.17
 })
 state.fx=PostFX.new()
 state.text=Ink.new('Le miniature attendono il risveglio.',{
  font=state.caption,wrap=620,speed=.04,color={.25,.15,.07,1}
 })
end

function love.update(dt)
 Toasts.update(dt)
 state.figure:update(dt,state.reduced)
 state.text:update(dt,state.reduced)
end

local function draw_2d()
 local w,h=g.getDimensions()
 g.setColor(.085,.068,.056,1)
 g.rectangle('fill',0,0,w,h)
 local page_x,page_y=math.floor(w*.12),math.floor(h*.13)
 local page_w,page_h=math.floor(w*.76),math.floor(h*.77)
 g.setColor(.32,.19,.11,1)
 g.rectangle('fill',page_x-16,page_y-16,page_w+32,page_h+32,16)
 g.setColor(.88,.79,.61,1)
 g.rectangle('fill',page_x,page_y,page_w,page_h)
 g.setColor(.47,.30,.16,1)
 g.setLineWidth(3)
 g.rectangle('line',page_x+23,page_y+22,page_w-46,page_h-44)
 g.setLineWidth(1)
 for n=1,8 do
  g.setColor(.41,.29,.16,.17)
  local y=page_y+132+n*36
  g.line(page_x+110,y,page_x+page_w-75,y)
 end
 g.setFont(state.heading)
 g.setColor(.36,.21,.10,1)
 g.print('FOLIUM VIVENS',page_x+110,page_y+46)
 state.figure:draw()
 state.text:draw(page_x+110,page_y+172)
 -- No 3D replacement: this panel tests *only* flat manuscript figures.
end

function love.draw()
 g.push('all')
 if state.fx then state.fx:draw(draw_2d) else draw_2d() end
 Toasts.draw(false)
 g.setColor(1,.89,.68,1)
 g.setFont(state.caption)
 g.print('P: la miniatura esce    R: ritorna    V: vignettatura 2D    M: riduci movimento    Esc: esci',
   28,14)
 g.print('2D figure: anim8 + Flux   |   ink: SYSL-Text   |   FX: Moonshine (opt-in)',
   28,love.graphics.getHeight()-34)
 g.pop()
end

function love.resize(w,h)
 Res.refresh(w,h)
 if state.fx then state.fx:resize(w,h) end
end

function love.keypressed(key)
 if key=='escape' then love.event.quit()
 elseif key=='p' then reveal()
 elseif key=='r' then retreat()
 elseif key=='v' then state.fx.enabled=not state.fx.enabled
 elseif key=='m' then
  state.reduced=not state.reduced
  if state.reduced then
   state.figure:update(0,true)
   state.text:show_all()
  end
 end
end
