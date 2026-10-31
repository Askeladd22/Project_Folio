-- Project Folio manuscript opening: one visual language from splash to HUD.
-- Retires the unrelated pink/blue heart/circle branding and its shader assets.
-- The automatic route, click/keyboard skip and reduced motion stay supported.
local Splash={}
local AudioManager=require('src.core.audio_manager')
local I18n=require('src.core.i18n')
local Navigation=require('src.core.navigation')
local RuntimeUI=require('src.core.runtime_ui')
local Schema=require('src.core.schema')
local Surface=require('src.features.ui_v2.menu_surface')
local Spec=require('src.data.startup_splash_schema')
local assets=Spec.assets or {}
local timing=Spec.timing or {}
local flow=Spec.flow or {}
local entry=Schema.expect_entry((Spec.text or {}).branding_title,'text.branding_title')
local background_path=Schema.expect_string(assets.background_path,'assets.background_path')
local font_path=Schema.expect_string(assets.title_font,'assets.title_font')
local subtitle_path=Schema.expect_string(assets.subtitle_font,'assets.subtitle_font')
local next_module=Schema.expect_string(flow.next_module,'flow.next_module')
local skip_audio=Schema.expect_string(flow.skip_audio,'flow.skip_audio')
local mouse_button=Schema.expect_number(flow.skip_mouse_button,'flow.skip_mouse_button')
local intro_seconds=Schema.expect_number(timing.intro_seconds,'timing.intro_seconds')
local title_seconds=Schema.expect_number(timing.title_seconds,'timing.title_seconds')
local reduced_factor=Schema.expect_number(timing.reduced_factor,'timing.reduced_factor')
local timer=0
local intro=0
local title_time=0
local finished=false
local bg=nil
local fonts={}
local function clamp(v)
 return math.max(0,math.min(1,v))
end
local function ease(v)
 v=clamp(v)
 return v*v*(3-2*v)
end
local function load_image()
 if bg or not (love.filesystem and love.filesystem.getInfo
   and love.filesystem.getInfo(background_path)) then return end
 local ok,image=pcall(love.graphics.newImage,background_path)
 if ok then bg=image end
end
local function get_font(path,size)
 local key=path..':'..size
 if fonts[key] then return fonts[key] end
 local ok,value=pcall(love.graphics.newFont,path,size)
 if not ok then value=love.graphics.newFont(size) end
 fonts[key]=value
 return value
end
local function finish(skip)
 if finished then return end
 finished=true
 if skip then AudioManager.play_ui(skip_audio) end
 Navigation.go(next_module)
end
function Splash:enter()
 timer=0
 finished=false
 local factor=RuntimeUI.reduced_animations() and reduced_factor or 1
 intro=intro_seconds*factor
 title_time=title_seconds*factor
 load_image()
end
function Splash:update(dt)
 if finished then return end
 timer=timer+math.max(0,dt or 0)
 if timer>=intro+title_time then finish(false) end
end
function Splash:draw()
 if finished then return end
 local g=love.graphics
 local w,h=g.getDimensions()
 g.push('all')
 g.clear(.085,.060,.039,1)
 if bg then
  local scale=math.max(w/bg:getWidth(),h/bg:getHeight())
  g.setColor(1,1,1,.62)
  g.draw(bg,(w-bg:getWidth()*scale)*.5,
    (h-bg:getHeight()*scale)*.5,0,scale,scale)
 end
 Surface.backdrop(w,h,RuntimeUI.high_contrast(),1)
 local width=math.min(w*.84,math.max(440,h*1.12))
 local height=math.min(h*.71,620)
 local frame={x=(w-width)*.5,y=(h-height)*.5,w=width,h=height}
 Surface.panel(frame,{high_contrast=RuntimeUI.high_contrast()})
 -- An illuminated folio appears, then a title takes over. No old
 -- two-color splash, mascot heart, duplicate title PNG or shader path.
 local alpha=timer<intro and ease(timer/math.max(.01,intro)) or 1
 local center=w*.5
 local motif_y=frame.y+height*.23
 g.setColor(.49,.31,.13,alpha*.85)
 g.setLineWidth(2)
 g.circle('line',center,motif_y,math.max(24,math.floor(h*.042)))
 g.setColor(.53,.34,.15,alpha)
 g.polygon('fill',center,motif_y-18,center+12,motif_y,
  center,motif_y+18,center-12,motif_y)
 Surface.rule(frame.x+width*.15,frame.y+height*.40,width*.70,alpha)
 if timer>=intro then
  local elapsed=timer-intro
  local fade=ease(elapsed/math.max(.01,title_time*.18))
  local tail=1-ease((elapsed-title_time*.80)/math.max(.01,title_time*.20))
  local opacity=fade*tail
  local scale=math.max(.63,math.min(1.16,h/1080))
  local face=get_font(font_path,math.max(30,math.floor(90*scale)))
  local subtitle=get_font(subtitle_path,math.max(14,math.floor(27*scale)))
  g.setFont(face)
  g.setColor(.28,.16,.08,opacity)
  g.printf(I18n.t(entry.key,entry.default),frame.x+25,
   frame.y+height*.46,width-50,'center')
  g.setFont(subtitle)
  g.setColor(.42,.29,.17,opacity)
  g.printf('A Dream of Ink and Dice',frame.x+28,
   frame.y+height*.67,width-56,'center')
 else
  local face=get_font(subtitle_path,math.max(15,math.floor(h*.024)))
  g.setFont(face)
  g.setColor(.42,.29,.17,alpha)
  g.printf('Ex libris',frame.x+24,frame.y+height*.54,
   width-48,'center')
 end
 g.pop()
end
function Splash:keypressed(_key) finish(true) end
function Splash:mousepressed(_x,_y,button)
 if button==mouse_button then finish(true) end
end
return Splash
