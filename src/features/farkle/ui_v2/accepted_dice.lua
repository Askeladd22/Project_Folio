-- UI 2.0: accepted-dice manuscript register. No old walnut canalina.
-- Drawn AFTER g3d so accepted dice never occupy the 3D rolling surface.
-- Captures use only g3d; no CPU painter, legacy HUD or gameplay mutation.
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local Presentation=require('src.features.farkle.presentation')
local Res=require('src.core.resolution_manager')
local UI=require('src.core.runtime_ui')
local M={}
local fonts={}
local function font(n)
 local px=math.floor(n*(UI.big_text() and 1.15 or 1)+.5)
 if not fonts[px] then
  fonts[px]=love.graphics.newFont('resources/font/IMFeENsc28P.ttf',px)
 end
 return fonts[px]
end
function M.slots(layout)
 local area=(layout or Layout.build('single_folio')).shelf
 local result={}
 local gutter=12
 local step=(area.w-gutter*2)/6
 for i=1,6 do
  result[i]={x=area.x+gutter+(i-1)*step,y=area.y+4,
   w=step-4,h=area.h-8}
 end
 return result
end

function M.draw(u)
 local s=u and u.game
 if not s or not s.used then return end
 local g=love.graphics
 local slots=M.slots()
 local p=u.presentation
 local contributors=p and Presentation.contributing_dice(p) or {}
 g.push('all')
 Res.begin_ui()
 for i,rect in ipairs(slots) do
  local used=s.used[i] and true or false
  local active=contributors[i] and true or false
  local high=UI.high_contrast()
  if used then g.setColor(.32,.25,.17,.94)
  else g.setColor(.88,.78,.57,.68) end
  g.rectangle('fill',rect.x,rect.y,rect.w,rect.h,5)
  if active then g.setColor(.96,.80,.38,1)
  else g.setColor(high and .18 or .43,.33,.23,.82) end
  g.setLineWidth(active and 2.4 or 1)
  g.rectangle('line',rect.x+.5,rect.y+.5,rect.w-1,rect.h-1,5)
  local entry=p and p.shelf and p.shelf[i]
  if used and entry and dice and dice[i] and u.trayProjection then
   if not entry.g3dPortrait then
    entry.g3dPortrait=require('src.engine3d.g3d_portrait')
     .capture(dice[i],u.trayProjection)
   end
   if entry.g3dPortrait then
    g.push('all')
    g.setBlendMode('alpha','premultiplied')
    g.setColor(1,1,1,1)
    local scale=.37
    g.draw(entry.g3dPortrait,rect.x+9,rect.y+1,0,scale,scale)
    g.pop()
   end
  end
  g.setFont(font(17))
  g.setColor(used and 1 or .35,used and .92 or .25,
   used and .70 or .16,1)
  local label=used and tostring(s.hand and s.hand[i] or i) or tostring(i)
  g.printf(label,rect.x+rect.w-45,rect.y+15,36,'center')
 end
 Res.end_ui()
 g.pop()
end
return M
