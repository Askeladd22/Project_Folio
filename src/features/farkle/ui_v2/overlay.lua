-- Legible marks beside the pips, with silhouettes taken from the same
-- projected physical dice the pointer picks.
local Model=require('src.features.farkle.ui_v2.overlay_model')
local UI=require('src.core.runtime_ui')
local Bridge=require('src.core.engine_bridge')
local Res=require('src.core.resolution_manager')
local M={}
local fonts={}
local function palette()
 if UI.high_contrast() then
  return {physical={.30,1,1,1},score={1,.86,.20,1},
    eligibleHint={1,.92,.71,.75},
    partial={1,.86,.20,1},invalid={1,.52,.46,1},eligible={1,.96,.64,1},
    neutral={1,1,1,.85},hover={1,1,.94,1}}
 end
 return {physical={.40,.83,.91,.96},score={1,.80,.30,.98},
   eligibleHint={.92,.77,.48,.47},
   partial={.96,.78,.41,1},invalid={1,.54,.46,1},eligible={.96,.82,.52,.95},
   neutral={.88,.84,.76,.52},hover={1,.95,.77,.94}}
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
local edgeInk={.18,.12,.065,.86}
local function score_mark(m,colors,scale,floorEdge)
 local g=love.graphics
 local chosen=m.kind=='score' or m.kind=='partial' or m.kind=='invalid'
 -- Trace the actual cube contour for hover and selection. The ink backing
 -- keeps a hairline legible against both ivory and brightly lit wood.
 local eligible=m.kind=='eligible'
 if m.outline and (m.hovered or chosen or eligible) then
  local stroke=chosen and 2.5 or m.hovered and 1.4 or .75
  -- Passive availability is a restrained silhouette, not the old
  -- horizontal dash below every scoreable D6. Hover/selection stay stronger.
  if m.hovered or chosen then
   g.setLineWidth((stroke+1.8)*scale);colour(edgeInk)
   g.polygon('line',m.outline)
  end
  g.setLineWidth(stroke*scale)
  colour(chosen and colors[m.kind] or m.hovered and colors.hover or colors.eligibleHint)
  g.polygon('line',m.outline)
 end
 if m.kind=='neutral' or eligible then return end
 -- The anchor follows the lower (or, at the front rail, upper) hull edge
 -- so the mark never moves across the pips of a large foreground die.
 local low,high=m.y+m.r,m.y-m.r
 if m.outline then
  low,high=-math.huge,math.huge
  for i=2,#m.outline,2 do low=math.max(low,m.outline[i]);high=math.min(high,m.outline[i]) end
 end
 local y=low+4*scale
 if floorEdge and y>floorEdge-6*scale then y=high-6*scale end
 local x=m.x
 local function glyph()
  if m.kind=='score' then
   g.line(x-7*scale,y,x-2*scale,y+3*scale,x+7*scale,y-3*scale)
  elseif m.kind=='invalid' then
   g.line(x-3*scale,y-3*scale,x+3*scale,y+3*scale)
   g.line(x+3*scale,y-3*scale,x-3*scale,y+3*scale)
  elseif m.kind=='partial' then
   g.line(x-8*scale,y,x-3*scale,y)
   g.line(x+3*scale,y,x+8*scale,y)
  else
   g.line(x-8*scale,y,x+8*scale,y)
  end
 end
 g.setLineWidth((chosen and 4.8 or 4)*scale);colour(edgeInk);glyph()
 g.setLineWidth((chosen and 2.5 or 2)*scale);colour(colors[m.kind]);glyph()
end
function M.draw(u,hits)
 local hover
 if u.game and u.game.phase=='ready' and not u.modal and not u.mouseThrow and
    not u.marquee and love.mouse and love.mouse.getPosition then
  hover=Bridge.pickTrayDie(love.mouse.getPosition())
 end
 local model=Model.build(u,hits,hover)
 local g=love.graphics
 g.push('all')
 local colors=palette()
 local viewportScale=math.max(.8,math.min(2,Res.get_scale()*UI.scale()))
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
  if m.kind=='physical' then
   -- Drag-grab remains cyan but stays close to the projected die.
   g.setLineWidth(2.1*viewportScale)
   corner_marks(m.x,m.y,math.min(24,m.r),false)
  else
   score_mark(m,colors,viewportScale,u.trayProjection and u.trayProjection.floorEnd)
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
