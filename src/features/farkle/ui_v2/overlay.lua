-- UI v2 P3: deliberately small screen-space indicators around g3d dice.
-- The legacy shelf/folio/modal painter remains a separate temporary path.
local Model=require('src.features.farkle.ui_v2.overlay_model')
local UI=require('src.core.runtime_ui')
local M={}
local fonts={}
local function palette()
 if UI.high_contrast() then
  return {physical={.30,1,1,1},score={1,.86,.20,1},
    invalid={1,.28,.28,1},eligible={1,.96,.64,1}}
 end
 return {physical={.40,.83,.91,.96},score={1,.80,.30,.98},
   invalid={.98,.34,.30,.98},eligible={.94,.81,.54,.74}}
end
local function colour(c)
 love.graphics.setColor(c[1],c[2],c[3],c[4])
end
local function corner_marks(x,y,r,extended)
 local g=love.graphics
 local reach=extended and 15 or 11
 local d=r+7
 -- Corner strokes stay outside the die's pips, unlike full-size circles.
 g.line(x-d,y-d+reach,x-d,y-d,x-d+reach,y-d)
 g.line(x+d-reach,y-d,x+d,y-d,x+d,y-d+reach)
 g.line(x-d,y+d-reach,x-d,y+d,x-d+reach,y+d)
 g.line(x+d-reach,y+d,x+d,y+d,x+d,y+d-reach)
end
function M.draw(u,hits)
 local model=Model.build(u,hits)
 local g=love.graphics
 g.push('all')
 local colors=palette()
 local viewportScale=math.max(.5,math.min(1.8,UI.scale()))
 if model.marquee then
  local r=model.marquee
  colour(colors.physical)
  g.setLineWidth(1.8)
  g.rectangle('line',r.x,r.y,r.w,r.h)
  g.setColor(colors.physical[1],colors.physical[2],
    colors.physical[3],.08)
  g.rectangle('fill',r.x,r.y,r.w,r.h)
 end
 for _,m in ipairs(model.markers) do
  colour(colors[m.kind])
  if m.kind=='eligible' then
   -- A short underline signals scoring availability without hiding faces.
   g.setLineWidth(2.3*viewportScale)
   local y=m.y+m.r+8
   g.line(m.x-9,y,m.x+9,y)
  else
   g.setLineWidth((m.kind=='physical' and 2.1 or 2.8)*viewportScale)
   corner_marks(m.x,m.y,m.r,m.kind=='score' or m.kind=='invalid')
  end
 end
 if model.hand then
  local hand=model.hand
  -- One pointer badge, not a ring for every die in the held constellation.
  colour(colors.physical)
  g.setLineWidth(2.3*viewportScale)
  g.line(hand.x-18,hand.y,hand.x-7,hand.y)
  g.line(hand.x+7,hand.y,hand.x+18,hand.y)
  g.line(hand.x,hand.y-18,hand.x,hand.y-7)
  g.line(hand.x,hand.y+7,hand.x,hand.y+18)
  local pts=math.max(14,math.min(27,math.floor(16*UI.scale()*
       (UI.big_text() and 1.2 or 1)+.5)))
  if not fonts[pts] then fonts[pts]=g.newFont(pts) end
  local title=hand.count>1 and (hand.count..' DADI IN MANO')
      or 'DADO IN MANO'
  local width=fonts[pts]:getWidth(title)+20
  local height=pts+16
  local x=hand.x+22
  local y=hand.y-height-15
  g.setColor(.08,.10,.11,.92)
  g.rectangle('fill',x,y,width,height,5)
  colour(colors.physical)
  g.setLineWidth(1.3)
  g.rectangle('line',x,y,width,height,5)
  g.setFont(fonts[pts])
  g.print(title,x+10,y+7)
 end
 g.pop()
 return model
end
return M
