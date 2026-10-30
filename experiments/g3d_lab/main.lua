-- g3d renderer A/B: *one* original 3D physics simulation, two renderers.
-- Loaded only with MANUSCRIPT_G3D_LAB=1. Production Manuscript is untouched.
require('core')
local Scene=require('src.data.dice_scene_schema')
local Physics=require('src.engine3d.physics')
local Geometry=require('src.engine3d.geometry')
local Legacy=require('src.engine3d.render')
local View=require('src.engine3d.view')
local FaceTexture=require('src.engine3d.face_texture')
local Mesh=require('src.engine3d.g3d_mesh')
local Camera=require('src.engine3d.g3d_camera')
local Perf=require('experiments.g3d_lab.perf')
local G3D=require('lib.g3d')

local g=love.graphics
local state={
 mode=3,paused=false,show_walls=true,elapsed=0,
 old_stats=Perf.new(120),g3d_stats=Perf.new(120),
 world=nil,bodies={},models={},images={},floor=nil,walls=nil,wood=nil,
 old_canvas=nil,new_canvas=nil,pane_w=0,pane_h=0,scale=1,
}

local fixture={
 {-3.1,-1.30,4.00,  1.2, .1,-.15, 2.8, 1.7,1.4},
 { 0.0,-1.35,4.65, -.9, .4, .15, 1.6,-2.4,2.5},
 { 3.1,-1.25,5.30, -1.1,-.1,.10,-2.1, 1.2,1.8},
 {-3.1, 1.30,5.90,  1.1,-.4,.15, 1.8, 2.2,-1.4},
 { 0.0, 1.35,6.55,  .7,-.2,-.15, 2.3,-1.9,1.6},
 { 3.1, 1.25,7.15, -1.2,-.3,.10,-1.4, 1.8,2.1},
}
local legacy_die={
 faces=Geometry.d6.faces,
 image=Geometry.d6.image,
 color={.94,.90,.82,255},
 text={1,1,1},
 material=function(_point,normal)
  local diffuse=math.max(0,normal[1]*.25-normal[2]*.4+normal[3]*.88)
  return .57+.43*diffuse
 end
}

local function make_world()
 state.world=clone(Physics.box,{timeleft=0,log_buffer={}})
 state.world:configure(Scene.box)
 state.bodies={}
 for i,c in ipairs(fixture) do
  local b=Geometry.newD6Body(1.0):set(
    {c[1],c[2],c[3]},
    {c[4],c[5],c[6]},
    {c[7],c[8],c[9]})
  state.world[i]=b
  state.bodies[i]=b
 end
 state.elapsed=0
end

local function window_layout()
 local width,height=g.getDimensions()
 local margin=24
 local top=116
 local pane_h=math.max(160,math.floor(height-top-margin))
 local pane_w
 if state.mode==3 then
  pane_w=math.max(160,math.floor((width-3*margin)/2))
 else
  pane_w=math.max(160,math.floor(width-2*margin))
 end
 return margin,top,pane_w,pane_h
end

local function rebuild_buffers()
 local _,_,w,h=window_layout()
 if state.pane_w==w and state.pane_h==h then return end
 if state.old_canvas then state.old_canvas:release() end
 if state.new_canvas then state.new_canvas:release() end
 state.pane_w,state.pane_h=w,h
 state.old_canvas=g.newCanvas(w,h)
 state.new_canvas=g.newCanvas(w,h)
 local zoom=View.focus/View.distance
 state.scale=math.min(
  (w-36)/(2*(Scene.box.half_x+1.6)*zoom),
  (h-36)/(2*(Scene.box.half_y+3)*zoom))
 -- Both renderers share the same world-to-screen scale and viewport dimensions.
 Camera.apply(View,G3D.camera,w,h,state.scale)
end

local function set_cameras()
 View.projection='orthographic'
 View.distance=14.1
 View.focus=5
 View.pitch=.48
 View.cos_pitch,View.sin_pitch=math.cos(View.pitch),math.sin(View.pitch)
 -- No post-processing mirror: match the historical screen basis in the
 -- g3d VIEW matrix itself, including the GPU depth-axis convention.
 if state.pane_w>0 and state.pane_h>0 then
  Camera.apply(View,G3D.camera,state.pane_w,state.pane_h,state.scale)
 end
end

local function load_models()
 for n=1,6 do
  local path='resources/dice/'..n..'.png'
  state.images[n]=g.newImage(path)
  state.images[n]:setFilter('linear','linear')
 end
 state.wood=g.newImage('resources/textures/tray/walnut.png')
 state.wood:setFilter('linear','linear')
 state.models={}
 for i,b in ipairs(state.bodies) do
  state.models[i]={}
  for face_index,face in ipairs(Geometry.d6.faces) do
   local image=state.images[Mesh.pip(face_index,Geometry.d6)]
   state.models[i][face_index]=G3D.newModel(Mesh.face_vertices(b,face),image)
  end
 end
 state.floor=G3D.newModel(
  Mesh.floor_vertices(-Scene.box.half_x,Scene.box.half_x,
                      -Scene.box.half_y,Scene.box.half_y),state.wood)
 state.wood:setWrap('repeat','repeat')
 state.walls=G3D.newModel(Mesh.tray_border_vertices(
  -Scene.box.half_x,Scene.box.half_x,
  -Scene.box.half_y,Scene.box.half_y,
  .85,Scene.box.border_height or 1.1,8),state.wood)
 -- init.lua enables depth globally; the 2D UI must never inherit it.
 g.setDepthMode()
end

local function refresh_meshes()
 for i,b in ipairs(state.bodies) do
  for face_index,face in ipairs(Geometry.d6.faces) do
   -- The rendered positions come from the *same rotated physical vertices*
   -- as the legacy painter; no pose inference or separate randomization.
   state.models[i][face_index].mesh:setVertices(Mesh.face_vertices(b,face))
  end
 end
end

local function render_legacy()
 local t=love.timer.getTime()
 g.push('all')
 g.setCanvas(state.old_canvas)
 g.clear(.105,.088,.071,1)
 g.setDepthMode()
 g.translate(state.pane_w/2,state.pane_h/2)
 g.scale(state.scale)
 local x1,x2=-Scene.box.half_x,Scene.box.half_x
 local y1,y2=-Scene.box.half_y,Scene.box.half_y
 local coords={}
 for _,p in ipairs{{x1,y1},{x2,y1},{x2,y2},{x1,y2}} do
  local x,y=View.project(p[1],p[2],0)
  coords[#coords+1]=x;coords[#coords+1]=y
 end
 g.setColor(.80,.80,.80,1)
 FaceTexture.draw(state.wood,unpack(coords))
 Legacy.clear()
 if state.show_walls then
  Legacy.board_extents={x1,x2,y1,y2}
  Legacy.tray_border(Legacy.zbuffer,.85,Scene.box.border_height or 1.1,{83,51,31})
 end
 for _,b in ipairs(state.bodies) do Legacy.die(Legacy.zbuffer,legacy_die,b) end
 Legacy.paint()
 Legacy.clear()
 g.pop()
 state.old_stats:push((love.timer.getTime()-t)*1000)
end

local function render_g3d()
 local t=love.timer.getTime()
 -- Include streaming 36 physical face meshes in g3d timing, not merely draw().
 refresh_meshes()
 g.push('all')
 -- A fresh depth attachment prevents old geometry from affecting later frames.
 g.setCanvas({state.new_canvas,depth=true})
 g.clear(.105,.088,.071,1,true,1)
 g.setDepthMode('lequal',true)
 g.setColor(1,1,1,1)
 state.floor:draw()
 if state.show_walls then state.walls:draw() end
 for _,models in ipairs(state.models) do
  for _,model in ipairs(models) do model:draw() end
 end
 g.setDepthMode()
 g.pop()
 state.g3d_stats:push((love.timer.getTime()-t)*1000)
end

function love.load()
 love.window.setTitle('Manuscript - renderer A/B (g3d experiment)')
 View.yaw=0
 View.cos_yaw,View.sin_yaw=math.cos(View.yaw),math.sin(View.yaw)
 make_world()
 set_cameras()
 load_models()
 rebuild_buffers()
end

function love.update(dt)
 if not state.paused and dt>0 then
  state.world:update(math.min(dt,.10))
  state.elapsed=state.elapsed+dt
 end
end

local function panel(image,x,y,title)
 g.setColor(1,1,1,1)
 g.draw(image,x,y) -- identical composition; no image-space mirroring
 g.setColor(.66,.52,.34,1)
 g.rectangle('line',x-1,y-1,state.pane_w+2,state.pane_h+2)
 g.setColor(.92,.87,.73,1)
 g.print(title,x+10,y+8)
end

function love.draw()
 rebuild_buffers()
 set_cameras()
 if state.mode~=2 then render_legacy() end
 if state.mode~=1 then render_g3d() end
 g.push('all')
 g.setCanvas()
 g.setDepthMode()
 g.clear(.075,.063,.053,1)
 local margin,top,w=window_layout()
 g.setColor(.96,.90,.75,1)
 g.print('MANUSCRIPT  /  3D RENDERER A-B  /  WORKSHOP ONLY',margin,18,0,1.4,1.4)
 g.setColor(.76,.71,.60,1)
 g.print('Space: pause   R: reset   1/2/3: old/g3d/split   A/D: camera   W: walls   Esc: exit',margin,56)
 local phase=state.paused and 'PAUSED' or 'RUNNING'
 g.print(string.format('Shared physics: %s  |  %.1f s  |  %d dice  |  frame %.0f FPS',
  phase,state.elapsed,#state.bodies,love.timer.getFPS()),margin,78)
 if state.mode==3 then
  panel(state.old_canvas,margin,top,'Manuscript / projected painter')
  panel(state.new_canvas,margin*2+w,top,'g3d / GPU depth test')
 elseif state.mode==1 then
  panel(state.old_canvas,margin,top,'Manuscript / projected painter')
 else
  panel(state.new_canvas,margin,top,'g3d / GPU depth test')
 end
 local footer_y=top+state.pane_h-25
 g.setColor(.94,.83,.63,1)
 local function ms_text(stats)
  local n=stats:average()
  return n and string.format('%.2f ms',n) or 'n/a'
 end
 g.print(string.format('CPU render submission / last 120 samples (NOT GPU): old %s  |  g3d %s',
  ms_text(state.old_stats),ms_text(state.g3d_stats)),margin,footer_y)
 g.pop()
end

function love.resize()
 state.pane_w=0
 rebuild_buffers()
end

function love.keypressed(key)
 if key=='escape' then love.event.quit()
 elseif key=='space' then state.paused=not state.paused
 elseif key=='r' then make_world();state.paused=false
 elseif key=='1' or key=='2' or key=='3' then
  state.mode=tonumber(key)
  state.old_stats:reset()
  state.g3d_stats:reset()
  state.pane_w=0
  rebuild_buffers()
 elseif key=='a' then View.turn(.18)
 elseif key=='d' then View.turn(-.18)
 elseif key=='w' then state.show_walls=not state.show_walls
 end
end
