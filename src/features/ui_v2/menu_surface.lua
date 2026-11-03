-- Shared manuscript surfaces for Project Folio frontend and UI V2.
-- Lightweight LÖVE drawing primitives. No old HUD, CPU painter or fallback.
-- Pure geometry functions are usable in headless Lua tests.
local M={}
M.palette={
 ink={.24,.15,.09},
 muted={.47,.33,.22},
 gold={.57,.37,.13},
 parchment={.89,.81,.65},
 border={.48,.32,.16},
}
local function color(c,a)
 love.graphics.setColor(c[1],c[2],c[3],a or 1)
end
function M.within(rect,w,h)
 return type(rect)=='table' and rect.x>=0 and rect.y>=0
  and rect.w>0 and rect.h>0 and rect.x+rect.w<=w+1
  and rect.y+rect.h<=h+1
end
function M.contains(rect,x,y)
 return rect and x>=rect.x and y>=rect.y
  and x<=rect.x+rect.w and y<=rect.y+rect.h
end

-- No full-width legacy letterbox/header/footer strips: keep the original
-- illuminated workshop illustration visible beyond one bounded leaf.
function M.backdrop(w,h,high_contrast,opacity,opts)
 local g=love.graphics
 g.push('all')
 local quiet=opts and opts.quiet
 g.setColor(.055,.047,.042,
  (quiet and (high_contrast and .41 or .28)
   or (high_contrast and .32 or .16))*(opacity or 1))
 g.rectangle('fill',0,0,w,h)
 g.pop()
end

-- Four thin rules and ink corner ornaments read as a folio, not a window.
function M.panel(r,opts)
 opts=opts or {}
 local alpha=opts.alpha or 1
 local high=opts.high_contrast
 local g=love.graphics
 if opts.style=="editorial" then
  g.push('all')
  -- A restrained paper leaf: straight edges, one hairline border and
  -- restrained paper warmth instead of faux embossed gold ornament.
  g.setColor(.015,.013,.012,.44*alpha)
  g.rectangle('fill',r.x+5,r.y+7,r.w,r.h)
  g.setColor(.915,.878,.797,(high and 1 or .98)*alpha)
  g.rectangle('fill',r.x,r.y,r.w,r.h)
  g.setColor(.27,.22,.17,(high and .70 or .42)*alpha)
  g.setLineWidth(1)
  g.rectangle('line',r.x+.5,r.y+.5,r.w-1,r.h-1)
  g.pop()
  return
 end
 g.push('all')
 g.setColor(.028,.018,.011,.45*alpha)
 g.rectangle('fill',r.x+8,r.y+11,r.w,r.h,8,8)
 g.setColor(.88,.79,.61,(high and .98 or .94)*alpha)
 g.rectangle('fill',r.x,r.y,r.w,r.h,7,7)
 g.setColor(.99,.94,.82,.49*alpha)
 g.rectangle('fill',r.x+8,r.y+8,r.w-16,r.h-16,3,3)
 color(M.palette.border,.82*alpha)
 g.setLineWidth(2)
 g.rectangle('line',r.x+1,r.y+1,r.w-2,r.h-2,7,7)
 g.setColor(.50,.32,.16,.60*alpha)
 g.setLineWidth(1)
 g.rectangle('line',r.x+11,r.y+11,r.w-22,r.h-22,3,3)
 for _,dx in ipairs({1,-1}) do
  for _,dy in ipairs({1,-1}) do
   local x=dx==1 and r.x+20 or r.x+r.w-20
   local y=dy==1 and r.y+20 or r.y+r.h-20
   g.line(x,y+dy*13,x,y,x+dx*13,y)
  end
 end
 g.pop()
end

function M.rule(x,y,w,alpha,opts)
 local g=love.graphics
 if opts and opts.quiet then
  g.push('all')
  g.setColor(.34,.28,.22,.34*(alpha or 1))
  g.setLineWidth(1)
  g.line(x,y,x+w,y)
  g.pop()
  return
 end
 g.push('all')
 color(M.palette.border,.50*(alpha or 1))
 g.setLineWidth(1)
 local center=x+w*.5
 g.line(x,y,center-12,y)
 g.line(center+12,y,x+w,y)
 color(M.palette.gold,.9*(alpha or 1))
 g.polygon('fill',center,y-5,center+5,y,center,y+5,center-5,y)
 g.pop()
end

function M.item(rect,opts)
 opts=opts or {}
 local g=love.graphics
 local alpha=opts.alpha or 1
 local active=opts.active and true or false
 local disabled=opts.disabled and true or false
 local primary=opts.primary and true or false
 if opts.style=="editorial" then
  g.push('all')
  -- Index-like navigation rather than six embossed parchment buttons.
  if active and not disabled then
   g.setColor(.30,.25,.20,.095*alpha)
   g.rectangle('fill',rect.x,rect.y,rect.w,rect.h)
   g.setColor(.27,.22,.17,.88*alpha)
   g.rectangle('fill',rect.x+1,rect.y+6,3,math.max(1,rect.h-12))
  end
  g.setColor(.35,.30,.25,(disabled and .10 or .19)*alpha)
  g.setLineWidth(1)
  g.line(rect.x+1,rect.y+rect.h-.5,rect.x+rect.w-1,rect.y+rect.h-.5)
  g.pop()
  return
 end
 g.push('all')
 local fill=active and {.97,.88,.65} or primary and {.94,.87,.70}
  or {.94,.88,.75}
 color(fill,(disabled and .38 or active and .95 or .68)*alpha)
 g.rectangle('fill',rect.x,rect.y,rect.w,rect.h,5,5)
 color(M.palette.border,(active and .93 or .36)*alpha)
 g.setLineWidth(active and 2 or 1)
 g.rectangle('line',rect.x+.5,rect.y+.5,rect.w-1,rect.h-1,5,5)
 if active then
  color(M.palette.gold,.95*alpha)
  g.rectangle('fill',rect.x+2,rect.y+7,3,rect.h-14)
  local x=rect.x+rect.w-23
  local cy=rect.y+rect.h/2
  g.polygon('fill',x,cy-5,x+5,cy,x,cy+5,x-5,cy)
 end
 g.pop()
end

return M
