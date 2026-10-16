-- Temporary visual workshop. No physics, gameplay, camera or RNG ownership.
local W={current='current'}
local order={'current','A','B','C'}
local labels={current='Attuale',A='A / Vassoio artigianale',B='B / Plancia integrata',C='C / Tavolo da gioco'}
local images,meshes={},{}
function W.cycle()
 for i,id in ipairs(order) do if id==W.current then W.current=order[i%#order+1];return end end
end
local function quad(view,points,color,texture,key)
 local g=love.graphics;local vertices,flat={},{}
 for i,p in ipairs(points) do
  local x,y=view.project(p[1],p[2],p[3] or 0)
  flat[#flat+1]=x;flat[#flat+1]=y
  local uv=({{0,0},{1,0},{1,1},{0,1}})[i]
  vertices[i]={x,y,uv[1],uv[2],1,1,1,1}
 end
 g.setColor(unpack(color))
 if texture then
  images[texture]=images[texture] or g.newImage('resources/textures/'..texture..'.png')
  local mesh=meshes[key]
  if not mesh then mesh=g.newMesh(vertices,'fan','dynamic');meshes[key]=mesh else mesh:setVertices(vertices) end
  mesh:setTexture(images[texture]);g.draw(mesh)
 else g.polygon('fill',unpack(flat)) end
end
local function plane(view,x1,x2,y1,y2,z,color,texture,key)
 quad(view,{{x1,y1,z},{x2,y1,z},{x2,y2,z},{x1,y2,z}},color,texture,key)
end
function W.floor(view,x1,x2,y1,y2)
 if W.current=='current' then return false end
 local id=W.current
 local colors={A={.26,.13,.065,1},B={.115,.135,.115,1},C={.34,.29,.20,1}}
 plane(view,x1,x2,y1,y2,0,colors[id],id~='A' and 'felt' or nil,'floor-'..id)
 if id=='A' then
  -- Reuse the existing deterministic leather treatment, rather than tinting
  -- green felt (whose baked colour cannot produce brown leather).
  local g=love.graphics;g.setLineWidth(.014)
  for row=1,24 do for col=1,46 do
   local x=x1+.15+(x2-x1-.3)*(col-.5)/46
   local y=y1+.15+(y2-y1-.3)*(row-.5)/24
   local a,b=view.project(x,y,0);local c,d=view.project(x+.035,y+.012,0)
   g.setColor(.57,.35,.18,.10+((row*17+col*13)%7)*.008);g.line(a,b,c,d)
  end end
 end
 -- Stitching/inlay stays on the original floor; no reduced playable area.
 local inset=id=='A' and .12 or id=='B' and .08 or .04
 local g=love.graphics;g.setLineWidth(.018)
 for _,p in ipairs({{x1+inset,y1+inset,x2-inset,y1+inset},{x2-inset,y1+inset,x2-inset,y2-inset},
  {x2-inset,y2-inset,x1+inset,y2-inset},{x1+inset,y2-inset,x1+inset,y1+inset}}) do
  local a,b=view.project(p[1],p[2],0);local c,d=view.project(p[3],p[4],0)
  g.setColor(.66,.48,.26,id=='A' and .6 or .35);g.line(a,b,c,d)
 end
 g.setLineWidth(1);return true
end
function W.border(render,view,height)
 local Scriptorium=require('src.features.farkle.controller')
 if Scriptorium and Scriptorium.hud_variant=='minimal' and W.current=='current' then
  return require('src.features.farkle.hud_minimal').border(render,view,height)
 end
 local id=W.current;if id=='current' then return false end
 if id=='A' then render.tray_border(render.zbuffer,.85,height,{66,38,21});return true end
 if id=='C' then
  -- Thin full-height retaining lip: an open look without invisible walls.
  render.tray_border(render.zbuffer,.13,height,{133,110,65});return true
 end
 local x1,x2,y1,y2=unpack(render.board_extents)
 -- Wide side worktops join the existing desk visually. Only the dark opening
 -- is the playable floor; the surround is outside the unchanged collider.
 local outer={{x1-4.5,y1-.85,height},{x2+4.5,y1-.85,height},{x2+4.5,y2+.85,height},{x1-4.5,y2+.85,height}}
 local inner={{x1,y1,height},{x2,y1,height},{x2,y2,height},{x1,y2,height}}
 for i=1,4 do
  local j=i%4+1
  local a,b=inner[i],inner[j]
  local rim={outer[i],outer[j],b,a}
  local wall={{a[1],a[2],0},{b[1],b[2],0},b,a}
  local _,_,z=view.project((a[1]+b[1])/2,(a[2]+b[2])/2,height/2)
  render.zbuffer(z,function()
   -- Coplanar countertop surround, no freestanding outside fascia.
   quad(view,wall,{.10,.065,.035,1})
   quad(view,rim,{.48,.33,.20,1},'wood','countertop-'..i)
  end)
 end
 return true
end
-- Returns graphical collection coordinates only; identities and transfer timing
-- remain in presentation_view. The current shelf is deliberately untouched.
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
