local V={}; local M=require('model'); local S=require('shaders'); local g=love.graphics
local function color(r,b,c,a) g.setColor(r,b,c,a or 1) end
local function paper()
 color(.83,.75,.57); g.rectangle('fill',75,45,390,290,5)
 color(.36,.28,.18); g.rectangle('line',90,60,360,260)
 for y=200,295,16 do color(.49,.39,.26,.5); g.rectangle('fill',115,y,280-(y%3)*20,2) end
end
local function ornament()
 color(.22,.29,.25)
 for i=0,18 do
  local x=115+i*16; local y=133+math.sin(i*.55)*19
  g.circle('fill',x,y,3); g.line(x,y,x+9,y-16); g.ellipse('fill',x+9,y-19,5,10)
  g.line(x,y,x-5,y+15); g.ellipse('fill',x-5,y+18,5,9)
 end
 g.setLineWidth(2); g.line(112,135,420,135); g.setLineWidth(1)
end
local function medal()
 color(.23,.35,.37); g.polygon('fill',240,77,280,77,308,210,260,185,213,210)
 color(.58,.35,.08); g.circle('fill',260,211,72)
 color(.85,.65,.23); g.circle('fill',260,205,68)
 color(.53,.35,.10); g.setLineWidth(3); g.circle('line',260,205,56); g.setLineWidth(1)
 color(.97,.81,.39); g.polygon('fill',260,165,271,191,300,194,278,212,285,241,260,225,235,241,242,212,220,194,249,191)
end
local function desk()
 color(.22,.16,.12); g.rectangle('fill',0,0,540,370)
 for y=18,370,28 do color(.32,.23,.16,.6); g.line(0,y,540,y+8) end
 paper(); color(.13,.16,.16); g.circle('fill',445,275,23)
 color(.6,.43,.22); g.push(); g.translate(420,205); g.rotate(-.5); g.rectangle('fill',-4,-80,8,150); g.pop()
end
function V.load(normal,big)
 V.normal=normal; V.big=big; V.canvas={}; V.allocations=0
 V.inkQuad=g.newQuad(0,0,540,370,540,370)
 for _,name in ipairs({'ink','gold','light'}) do
  V.canvas[name]=g.newCanvas(540,370); V.allocations=V.allocations+1
 end
 V.refresh()
end
function V.refresh()
 if not V.canvas then return end
 g.push('all'); g.origin(); g.setShader(); g.setBlendMode('alpha','alphamultiply')
 for _,name in ipairs({'ink','gold','light'}) do
  g.setCanvas(V.canvas[name]); g.clear(0,0,0,0)
  if name=='ink' then ornament() elseif name=='gold' then medal() else desk() end
 end
 g.setCanvas(); g.pop()
 V.refreshes=(V.refreshes or 0)+1
end
function V.checkContent()
 local rows={}
 for _,name in ipairs({'ink','gold','light'}) do
  -- GPU readback is deliberately outside all timed update/draw intervals.
  local pixels=V.canvas[name]:newImageData(); local opaque=0; local lo=1; local hi=0
  for y=0,369,4 do for x=0,539,4 do
   local r,green,b,a=pixels:getPixel(x,y)
   if a>.9 then opaque=opaque+1; lo=math.min(lo,r,green,b); hi=math.max(hi,r,green,b) end
  end end
  pixels:release()
  local threshold=({ink=20,gold=200,light=1000})[name]
  assert(opaque>threshold and hi-lo>.05,'Blank or invalid '..name..' Canvas after window mode change')
  rows[#rows+1]=string.format('%s: opaque_samples=%d,channel_range=%.5f',name,opaque,hi-lo)
 end
 return table.concat(rows,'; ')
end
local function die(x,y,angle)
 g.push(); g.translate(x,y); g.rotate(angle)
 color(.06,.07,.07,.3); g.rectangle('fill',-31,-26,68,68,11)
 color(.91,.85,.69); g.rectangle('fill',-34,-34,68,68,10)
 color(.31,.24,.17); g.rectangle('line',-34,-34,68,68,10)
 for _,p in ipairs({{-17,-17},{17,-17},{0,0},{-17,17},{17,17}}) do g.circle('fill',p[1],p[2],5) end
 g.pop()
end
function V.draw(id,p,intensity,animated)
 local blend,alpha=g.getBlendMode()
 color(.15,.18,.18); g.rectangle('fill',0,0,540,370,8)
 if id==1 then
  color(.38,.29,.19); g.rectangle('fill',320,268,180,18,3)
  color(.22,.27,.26); g.rectangle('fill',32,270,170,50,8)
  local t=M.ease.cubic(p); local arc=animated and math.sin(p*math.pi)*92*intensity or 0
  die(110+300*t,234-arc,animated and (1-t)*-.45*intensity or 0)
 elseif id==2 then
  local a=M.ease.out(M.stage(p,0,.4)); local b=M.ease.out(M.stage(p,.42,.72)); local c=M.ease.out(M.stage(p,.74,1))
  local values={math.floor(40*a+.5),math.floor(35*b+.5),math.floor(25*c+.5)}
  color(.76,.69,.53); g.print('BASE',54,56); g.print('COMBINATION',54,98); g.print('BONUS',54,140)
  for i,v in ipairs(values) do g.printf(tostring(v),390,14+i*42,80,'right') end
  color(.88,.72,.36); g.rectangle('fill',54,200,416,2)
  g.setFont(V.big); g.printf(tostring(values[1]+values[2]+values[3]),0,225,540,'center'); g.setFont(V.normal)
 elseif id==3 then
  paper(); color(1,1,1); g.setBlendMode('alpha','premultiplied')
  local shader=animated and S.use('ink',p,intensity)
  if shader or p>=1 then g.draw(V.canvas.ink)
  elseif p>0 then V.inkQuad:setViewport(0,0,540*p,370,540,370); g.draw(V.canvas.ink,V.inkQuad) end
  S.clear()
 elseif id==4 then
  color(1,1,1); g.setBlendMode('alpha','premultiplied'); if animated then S.use('gold',p,intensity) end
  g.draw(V.canvas.gold); S.clear()
 elseif id==5 then
  color(1,1,1); g.setBlendMode('alpha','premultiplied'); if animated then S.use('light',p,intensity) end
  g.draw(V.canvas.light); S.clear()
 end
 g.setBlendMode(blend,alpha); color(1,1,1)
end
return V
