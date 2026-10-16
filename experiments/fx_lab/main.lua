local M=require('model'); local V=require('visuals'); local S=require('shaders')
local g=love.graphics
local titles={'Die transfer','Staged points','Ink reveal','Gold sheen','Desk light'}
local notes={
 'A graphical 2D proxy follows a timed arc. No physics simulation.',
 '40 base + 35 combination + 25 bonus. Each stage has one stable endpoint.',
 'An original procedural botanical ornament is revealed across the paper.',
 'A single soft highlight crosses the medal; the rest of the scene stays still.',
 'One warm light envelope stays localized to the desk. No flicker.',
}
lab={model=M.new(),selected=1,enabled={true,true,true,true,true},frames=0,draw_seconds=0,update_seconds=0}
local buttons={}; local fonts={}; local audit=os.getenv('FX_LAB_AUDIT'); local auditStep=1; local auditFrames=0
local auditRows={}; local samples={draw=0,update=0,n=0}
local canvasCalls=0; local canvasCallsAtLoad=0; local pixelChecks={}; local pixelFailures=0
local contentChecks={}
local inputChecks={}
local function setAuditMode(w,h)
 love.window.setMode(w,h,{resizable=true,vsync=0})
 -- setMode can invalidate Canvas pixels even when existing objects survive.
 V.refresh()
 contentChecks[#contentChecks+1]=w..'x'..h..': '..V.checkContent()
end
if audit then
 function love.errorhandler(message)
  local f=io.open(audit..'/error.txt','w')
  if f then f:write(debug.traceback(tostring(message),2)); f:close() end
  return function() return 1 end
 end
end
function lab.select(i) lab.selected=i; lab.model:set_disabled(not lab.enabled[i]); lab.model:play() end
function lab.play() lab.model:play() end
function lab.draw_scene(id,p,intensity,animated) V.draw(id,p,intensity,animated) end
local function button(text,x,y,w,fn,active)
 g.setColor(active and .35 or .18,active and .32 or .22,active and .22 or .22)
 g.rectangle('fill',x,y,w,34,5); g.setColor(.93,.88,.75); g.printf(text,x,y+8,w,'center')
 buttons[#buttons+1]={x=x,y=y,w=w,h=34,fn=fn}
end
local function inputSmoke(w,h)
 local saved={}; for k,v in pairs(lab.model) do saved[k]=v end
 local selected=lab.selected; local enabled={unpack(lab.enabled)}; local m=lab.model
 local function click(x,y) love.mousepressed(lab.ox+x*lab.scale,lab.oy+y*lab.scale,1) end
 m:set_reduced(false)
 for i=1,5 do
  lab.enabled[i]=true; love.keypressed(tostring(i)); assert(lab.selected==i,'keyboard tab')
  click(50+(6-i-1)*240,105); assert(lab.selected==6-i,'transformed mouse tab')
 end
 love.keypressed('1'); love.keypressed('r'); assert(m.playing and m:progress()==0,'replay')
 love.keypressed('space'); assert(not m.playing,'pause')
 click(100,610); assert(m.playing,'mouse play')
 m:update(.2); click(250,610); assert(m:progress()==0 and m.playing,'mouse replay')
 local repeating=m.loop; click(380,610); assert(m.loop~=repeating,'repeat toggle')
 love.keypressed('b'); assert(m.disabled and m:progress()==1 and not m.playing,'keyboard disable')
 love.keypressed('2'); assert(not m.disabled,'independent enabled state')
 click(550,610); assert(m.disabled and not lab.enabled[2],'mouse disable')
 love.keypressed('1'); assert(m.disabled and not lab.enabled[1],'remember effect disable')
 love.keypressed('3'); assert(not m.disabled and lab.enabled[3],'third effect independent')
 love.keypressed('m'); assert(m.reduced and m:progress()==1 and not m.playing,'reduced immediate')
 love.keypressed('r'); assert(m:progress()==1 and not m.playing,'reduced replay stays final')
 click(760,610); assert(not m.reduced and m.playing,'mouse reduced toggle')
 m:set_duration(2); m.intensity=.5
 love.keypressed('right'); assert(math.abs(m.duration-2.2)<1e-8,'duration key')
 click(90,656); assert(math.abs(m.duration-2)<1e-8,'duration mouse')
 love.keypressed('up'); assert(math.abs(m.intensity-.6)<1e-8,'intensity key')
 click(480,656); assert(math.abs(m.intensity-.5)<1e-8,'intensity mouse')
 for k,v in pairs(saved) do m[k]=v end
 lab.selected=selected; lab.enabled=enabled
 inputChecks[#inputChecks+1]=string.format('%dx%d: synthetic keyboard/mouse callbacks PASS',w,h)
end
function love.load()
 if audit then
  local originalNewCanvas=g.newCanvas
  g.newCanvas=function(...) canvasCalls=canvasCalls+1; return originalNewCanvas(...) end
 end
 fonts.normal=g.newFont(16); fonts.small=g.newFont(13); fonts.title=g.newFont(28); fonts.big=g.newFont(64)
 g.setFont(fonts.normal); S.load(); V.load(fonts.normal,fonts.big); lab.play()
 canvasCallsAtLoad=canvasCalls
 if audit then setAuditMode(1280,720) end
end
function love.resize() V.refresh() end
function love.update(dt)
 if audit then
  auditFrames=auditFrames+1
  lab.selected=(auditStep-1)%5+1
  lab.model.disabled=auditStep>10; lab.model.playing=auditStep<=10
  lab.model.time=lab.model.duration*.5
  if (auditStep==6 or auditStep==16) and auditFrames==1 then setAuditMode(1920,1080) end
  if auditStep==11 and auditFrames==1 then setAuditMode(1280,720) end
 end
 local started=love.timer.getTime(); lab.model:update(dt)
 lab.update_seconds=love.timer.getTime()-started
 -- Keep the comparison pose stable AFTER measuring a real active update.
 if audit then lab.model.time=lab.model.duration*((auditFrames==59) and 1 or .5) end
end
local function auditDraw(w,h,elapsed)
 if auditFrames==1 and (auditStep==1 or auditStep==6) then inputSmoke(w,h) end
 if auditFrames>10 then samples.draw=samples.draw+elapsed; samples.update=samples.update+lab.update_seconds; samples.n=samples.n+1 end
 if auditFrames==59 then
  local id=lab.selected; local mode=auditStep>10 and 'disabled' or 'endpoint'
  g.captureScreenshot(function(data)
   local scale=w/1280; local different=0; local maximum=0
   -- Compare only interiors of the identically sized scene panels.
   for y=0,math.floor(370*scale)-1 do
    for x=0,math.floor(540*scale)-1 do
     local ar,ag,ab,aa=data:getPixel(math.floor(60*scale)+x,math.floor(177*scale)+y)
     local br,bg,bb,ba=data:getPixel(math.floor(680*scale)+x,math.floor(177*scale)+y)
     local d=math.max(math.abs(ar-br),math.abs(ag-bg),math.abs(ab-bb),math.abs(aa-ba))
     maximum=math.max(maximum,d); if d>1/255+.00001 then different=different+1 end
    end
   end
   pixelChecks[#pixelChecks+1]=string.format('%d,%dx%d,%s,%d,%.8f',id,w,h,mode,different,maximum)
   if different>0 then pixelFailures=pixelFailures+1 end
  end)
 elseif auditFrames==60 then
  local mode=auditStep>10 and 'disabled' or 'animated'
  local path=audit..'/effect-'..lab.selected..'-'..w..'x'..h..'-'..mode..'.png'
  g.captureScreenshot(function(data) local f=assert(io.open(path,'wb')); f:write(data:encode('png'):getString()); f:close() end)
 elseif auditFrames>=64 then
  local stats=g.getStats()
  auditRows[#auditRows+1]=string.format('%d,%dx%d,%s,%d,%.6f,%.6f,%d,%d',lab.selected,w,h,auditStep>10 and 'disabled' or 'animated',samples.n,samples.draw/samples.n*1000,samples.update/samples.n*1000,stats.drawcalls,stats.texturememory)
  samples={draw=0,update=0,n=0}; auditStep=auditStep+1; auditFrames=0
  if auditStep>20 then
   local f=assert(io.open(audit..'/metrics.csv','w'))
   f:write('effect,resolution,mode,samples,CPU_draw_submission_ms,CPU_model_update_ms,draw_calls,texture_memory_bytes\n'..table.concat(auditRows,'\n')..'\n'); f:close()
   f=assert(io.open(audit..'/runtime.txt','w'))
   local major,minor,revision,codename=love.getVersion()
   local renderer,version,vendor,device=g.getRendererInfo()
   f:write(string.format('LOVE=%d.%d.%d %s\nRenderer=%s\nRenderer_version=%s\nVendor=%s\nDevice=%s\n',major,minor,revision,codename,renderer,version,vendor,device))
   f:write('GPU_time=not_measured\nCanvas calls during load='..canvasCallsAtLoad..'\nCanvas calls total='..canvasCalls..'\nCanvas calls after load='..(canvasCalls-canvasCallsAtLoad)..'\n')
   f:write('Canvas refreshes='..V.refreshes..'\n'..table.concat(contentChecks,'\n')..'\n')
   f:write(table.concat(inputChecks,'\n')..'\n')
   for _,name in ipairs({'ink','gold','light'}) do f:write(name..'='..(S.items[name] and 'compiled' or ('fallback: '..S.errors[name]))..'\n') end
   f:close()
   f=assert(io.open(audit..'/pixel-checks.csv','w'))
   f:write('effect,resolution,mode,pixels_over_1_byte,max_channel_difference\n'..table.concat(pixelChecks,'\n')..'\n'); f:close()
   assert(canvasCalls==canvasCallsAtLoad,'Canvas allocated after load')
   assert(pixelFailures==0,'Scene equivalence failed; inspect pixel-checks.csv')
   love.event.quit()
  end
 end
end
function love.draw()
 local started=love.timer.getTime(); local w,h=g.getDimensions(); local scale=math.min(w/1280,h/720)
 lab.scale=scale; lab.ox=(w-1280*scale)/2; lab.oy=(h-720*scale)/2
 g.clear(.065,.085,.085); g.push(); g.translate(lab.ox,lab.oy); g.scale(scale); buttons={}
 g.setColor(.94,.89,.76); g.setFont(fonts.title); g.print('MANUSCRIPT / ORIGINAL FX LAB',44,25)
 g.setFont(fonts.small); g.setColor(.63,.71,.67); g.print('PROCEDURAL STUDIES   /   LOVE 11   /   PHYSICS FROZEN',45,63)
 g.setFont(fonts.normal)
 for i,title in ipairs(titles) do button(i..'  '..title,44+(i-1)*240,91,228,function() lab.select(i) end,lab.selected==i) end
 g.setColor(.68,.73,.69); g.print('A / NO EFFECT - FINAL STATE',60,145); g.print('B / ANIMATED',680,145)
 g.push(); g.translate(60,177); lab.draw_scene(lab.selected,1,0,false); g.pop()
 local m=lab.model; local animated=not m:immediate()
 g.push(); g.translate(680,177); lab.draw_scene(lab.selected,m:progress(),m.intensity,animated); g.pop()
 g.setColor(.75,.77,.68); g.setFont(fonts.small); g.print(notes[lab.selected],60,560); g.setFont(fonts.normal)
 button(m.playing and 'Pause [Space]' or 'Play [Space]',44,594,150,function() love.keypressed('space') end)
 button('Replay [R]',204,594,120,lab.play)
 button('Repeat: '..(m.loop and 'ON' or 'OFF'),334,594,140,function() m.loop=not m.loop end,m.loop)
 button('Effect: '..(lab.enabled[lab.selected] and 'ON' or 'OFF')..' [B]',484,594,170,function() love.keypressed('b') end,lab.enabled[lab.selected])
 button('Reduced motion: '..(m.reduced and 'ON' or 'OFF')..' [M]',664,594,245,function() love.keypressed('m') end,m.reduced)
 button('Duration -',44,640,110,function() m:set_duration(m.duration-.2) end)
 button('Duration +',164,640,110,function() m:set_duration(m.duration+.2) end)
 button('Intensity -',434,640,110,function() love.keypressed('down') end)
 button('Intensity +',554,640,110,function() love.keypressed('up') end)
 g.setColor(.85,.81,.66); g.print(string.format('%.1f s',m.duration),292,648); g.print(string.format('%.0f%%',m.intensity*100),682,648)
 g.setFont(fonts.small); g.setColor(.58,.67,.63); g.print('Arrows: duration / intensity | Sound: OFF | Esc: exit',790,651)
 g.printf(string.format('Progress %03d%%\n%s',math.floor(m:progress()*100+.5),m:immediate() and 'Immediate final state' or 'Timed playback'),930,594,300,'center')
 g.setFont(fonts.normal); g.pop()
 lab.frames=lab.frames+1; local elapsed=love.timer.getTime()-started; lab.draw_seconds=lab.draw_seconds+elapsed
 if audit then auditDraw(w,h,elapsed) end
end
function love.mousepressed(x,y,b)
 if b~=1 then return end
 x=(x-(lab.ox or 0))/(lab.scale or 1); y=(y-(lab.oy or 0))/(lab.scale or 1)
 for _,v in ipairs(buttons) do if x>=v.x and x<=v.x+v.w and y>=v.y and y<=v.y+v.h then v.fn(); return end end
end
function love.keypressed(key)
 local m=lab.model; local n=tonumber(key)
 if n and n>=1 and n<=5 then lab.select(n)
 elseif key=='escape' then love.event.quit()
 elseif key=='space' then if m.playing then m:pause() elseif m:progress()>=1 then m:play() else m.playing=not m:immediate() end
 elseif key=='r' then lab.play()
 elseif key=='b' then lab.enabled[lab.selected]=not lab.enabled[lab.selected]; m:set_disabled(not lab.enabled[lab.selected]); if not m.disabled then lab.play() end
 elseif key=='m' then m:set_reduced(not m.reduced); if not m.reduced then lab.play() end
 elseif key=='left' then m:set_duration(m.duration-.2)
 elseif key=='right' then m:set_duration(m.duration+.2)
 elseif key=='up' then m.intensity=M.clamp(m.intensity+.1,0,1)
 elseif key=='down' then m.intensity=M.clamp(m.intensity-.1,0,1) end
end
