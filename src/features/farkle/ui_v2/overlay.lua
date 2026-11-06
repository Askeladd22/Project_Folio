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
    partial={1,.86,.20,1},invalid={1,.52,.46,1},eligible={1,.96,.64,1},
    neutral={1,1,1,.85},hover={1,1,.94,1}}
 end
 return {physical={.40,.83,.91,.96},score={1,.80,.30,.98},
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
local edgeInk={.18,.12,.065,.82}
-- Passive eligibility is already a subtle tint on the g3d die faces.
-- Score feedback draws only on the projected physical silhouette: there
-- must be no dashes, ticks or glyphs detached below the dice.
local function score_mark(m,colors,scale)
 if not m.outline then return end
 local chosen=m.kind=='score' or m.kind=='partial' or m.kind=='invalid'
 if not chosen and not m.hovered then return end
 local g=love.graphics
 local width=(chosen and 2.25 or 1.35)*scale
 g.setLineWidth(width+1.5*scale);colour(edgeInk)
 g.polygon('line',m.outline)
 g.setLineWidth(width)
 colour(chosen and colors[m.kind] or colors.hover)
 g.polygon('line',m.outline)
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
   score_mark(m,colors,viewportScale)
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
