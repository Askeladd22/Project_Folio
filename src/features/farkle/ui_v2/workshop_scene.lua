-- The engraver's waking workshop breaks into the Merchant's dream.
-- 2D scenery only: no interactive hitboxes, dice, shaders or simulation state.
-- Drawn behind the g3d tray; all silhouettes stay inside the rear room band.
local W={}
local ink={.17,.105,.071}
local oak={.35,.18,.097}
local oak_light={.52,.31,.17}
local paper={.87,.79,.62}
local function color(c,a)
 love.graphics.setColor(c[1],c[2],c[3],a or 1)
end
local function beam(x,y,w,h)
 local g=love.graphics
 color(ink,.36);g.rectangle('fill',x+5,y+6,w,h,2)
 color(oak,.97);g.rectangle('fill',x,y,w,h,2)
 color(oak_light,.83);g.rectangle('fill',x+2,y+2,math.max(0,w-4),math.min(4,h-3))
 color(ink,.68);g.rectangle('line',x+.5,y+.5,w-1,h-1,2)
end
function W.bounds()
 return {
  proof={x=354,y=129,w=155,h=182},
  press={x=1538,y=102,w=295,h=231},
 }
end
local function proof(r)
 local g=love.graphics
 -- A proof sheet, not a new item, button or score surface.
 color(ink,.22);g.rectangle('fill',r.x+7,r.y+7,r.w,r.h,1)
 color(paper,.94);g.rectangle('fill',r.x,r.y,r.w,r.h,1)
 color(ink,.74);g.rectangle('line',r.x+.5,r.y+.5,r.w-1,r.h-1)
 color(ink,.77)
 local x,y=r.x+18,r.y+27
 -- Compact printed city vignette: the plate reads as an ink impression
 -- from a distance without introducing a second readable interface.
 g.rectangle('line',x,y,119,111)
 g.line(x+4,y+93,x+115,y+93)
 for i=0,3 do
  local bx=x+7+i*28
  local roof=25+(i%2)*12
  g.rectangle('line',bx,y+roof,22,91-roof)
  g.line(bx-3,y+roof,bx+11,y+roof-10,bx+25,y+roof)
  for j=0,2 do
   local wy=y+roof+12+j*19
   if wy<y+91 then g.rectangle('line',bx+7,wy,7,11) end
  end
 end
 for j=0,5 do
  g.setColor(.20,.13,.09,.24)
  g.line(x+4,y+100+j*1.3,x+115,y+100+j*1.3)
 end
 color(ink,.34);g.line(r.x+23,r.y+154,r.x+130,r.y+154)
 g.line(r.x+23,r.y+161,r.x+96,r.y+161)
 -- Two tiny paper fasteners (not glowing gameplay markers).
 color(oak,.8);g.circle('fill',r.x+11,r.y+10,2.8)
 g.circle('fill',r.x+r.w-12,r.y+10,2.8)
end
local function press(r)
 local g=love.graphics
 local x,y=r.x,r.y
 -- Hand press of the print shop, deliberately kept behind the far seam.
 -- A restrained timber silhouette instead of fantasy ornamentation.
 beam(x+20,y+182,248,15)       -- press bed
 beam(x+38,y+34,19,154)       -- left upright
 beam(x+234,y+34,19,154)      -- right upright
 beam(x+7,y+18,274,24)        -- cap beam
 beam(x+82,y+1,125,18)        -- cross brace
 color(ink,.84)
 g.rectangle('fill',x+143,y+46,11,85,1) -- central screw
 color(oak_light,.91)
 for i=0,5 do
  local yy=y+49+i*12
  g.line(x+143,yy,x+154,yy+5)
 end
 beam(x+108,y+130,83,13)      -- moving platen
 beam(x+99,y+147,101,14)
 color(oak_light,.92);g.setLineWidth(7)
 g.line(x+149,y+83,x+241,y+59) -- lever
 color(ink,.68);g.setLineWidth(1)
 g.circle('line',x+149,y+83,9)
 color(ink,.55)
 for _,bx in ipairs({x+46,x+243}) do
  g.circle('fill',bx,y+27,3)
  g.circle('fill',bx,y+181,3)
 end
 -- A thin proof sheet in the bed makes the machine recognizable as a press.
 color(paper,.90);g.rectangle('fill',x+111,y+175,83,6,1)
end
function W.draw(layout)
 local g=love.graphics
 local b=W.bounds()
 -- No painted elements may enter the interactive tray viewport.
 assert(b.proof.y+b.proof.h<=layout.tray.y and
  b.press.y+b.press.h<=layout.tray.y,
  'printshop props must remain behind the 3D play surface')
 g.push('all')
 proof(b.proof)
 press(b.press)
 g.pop()
end
return W
