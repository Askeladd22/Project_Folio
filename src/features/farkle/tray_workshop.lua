-- Temporary visual workshop. No physics, gameplay, camera or RNG ownership.
-- First visual book silhouette. F8 preserves access to the original variants.
local W={current='book'}
local order={'book','current','A','B','C'}
local labels={book='Libro aperto / prototipo',current='Attuale',A='A / Vassoio artigianale',B='B / Plancia integrata',C='C / Tavolo da gioco'}
-- F8 remains the gameplay-facing switch for g3d book/tray skins.
function W.cycle()
 for i,id in ipairs(order) do
  if id==W.current then
   W.current=order[i%#order+1]
   return W.current
  end
 end
 error('unrecognized g3d tray style')
end

-- Returns graphical collection coordinates only; identities and transfer timing
-- remain in the active hud_minimal upper-shelf presenter. F8 does not alter them.
function W.shelf(ax,ay,bx,by)
 if W.current=='current' then return end
 local g=love.graphics;local id=W.current;local depth=48
 if id=='C' then
  local dx,dy=(bx-ax)*.16,(by-ay)*.16
  ax,ay,bx,by=ax+dx,ay+dy+12,bx-dx,by-dy+12;depth=38
  g.setColor(.025,.015,.008,.5);g.rectangle('fill',ax-9,ay-depth+6,bx-ax+18,depth+8,12)
  g.setColor(.32,.20,.10);g.rectangle('fill',ax-8,ay-depth,bx-ax+16,depth+7,10)
  g.setColor(.12,.085,.045);g.rectangle('fill',ax,ay-depth+6,bx-ax,depth-5,7)
 elseif id=='B' then
  depth=40
  g.setColor(.36,.23,.13);g.polygon('fill',ax-10,ay-depth-8,bx+10,by-depth-8,bx+10,by+10,ax-10,ay+10)
  g.setColor(.075,.05,.025);g.rectangle('fill',ax,ay-depth,bx-ax,depth,3)
  g.setColor(.51,.36,.20);g.rectangle('line',ax,ay-depth,bx-ax,depth,3)
 else
  depth=50
  g.setColor(.075,.035,.015);g.polygon('fill',ax-10,ay-depth,bx+10,by-depth,bx+10,by+12,ax-10,ay+12)
  g.setColor(.32,.18,.08);g.rectangle('fill',ax-10,ay-depth,bx-ax+20,depth+4,5)
  g.setColor(.12,.055,.025);g.rectangle('fill',ax,ay-depth+7,bx-ax,depth-10,3)
  g.setColor(.58,.39,.19);g.line(ax-6,ay-depth+3,bx+6,by-depth+3)
 end
 for i=1,5 do local t=i/6;local x=ax+(bx-ax)*t;local y=ay+(by-ay)*t
  g.setColor(.58,.40,.21,.6);g.line(x,y-depth+9,x,y-7)
 end
 return ax,ay,bx,by,depth
end
function W.caption(txt)
 local Res=require('src.core.resolution_manager')
 Res.begin_ui()
 txt('F8  Workshop: '..labels[W.current],56,148,1250,20,{.94,.84,.65,1})
 Res.end_ui()
end
return W
