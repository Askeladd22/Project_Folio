-- Project Folio / Merchant table: deterministic decorative texture.
-- This is a GPU-only asset constructed once at render initialization.
-- Never uses gameplay RNG, changes a body, or affects depth/picking.
-- The 3D floor and rail geometry belong to g3d_scenery.lua.
local S={}
S.width=1024
S.height=512
S.palette={
 leather={.35,.165,.125}, -- warm iron-oxide dyed, matte leather
 grain_light={.53,.27,.20},
 grain_dark={.18,.08,.065},
 border={.72,.48,.26},
 border_dim={.43,.27,.17},
 ornament={.75,.56,.34},
}

local function leaf(g,x,y,angle,scale)
 g.push()
 g.translate(x,y)
 g.rotate(angle)
 g.scale(scale,scale)
 g.polygon('fill',0,0,15,-9,32,-5,24,4,8,8)
 g.setColor(.17,.09,.07,.62)
 g.setLineWidth(1)
 g.line(3,0,27,-1)
 g.pop()
end

local function flourish(g)
 -- A small, deliberate foliate cut; occupies only the outer corners.
 -- The central 72% x 66% remains free from graphics beneath the dice.
 g.setColor(.70,.47,.28,.85)
 g.setLineWidth(2.5)
 g.line(0,74,20,69,41,58,57,42,67,20)
 g.line(25,65,34,75,52,81,74,81)
 g.line(49,50,62,58,80,59)
 g.setColor(.75,.55,.32,.87)
 leaf(g,22,67,-.62,1.0)
 g.setColor(.75,.55,.32,.87)
 leaf(g,42,55,-.85,.85)
 g.setColor(.75,.55,.32,.87)
 leaf(g,57,42,-1.05,.7)
 g.setColor(.66,.45,.26,.8)
 leaf(g,53,77,-.14,.75)
 g.setColor(.68,.48,.28,.8)
 leaf(g,73,60,-.35,.56)
 g.setColor(.65,.43,.25,.78)
 g.setLineWidth(1.5)
 g.line(61,23,68,11,78,7)
end

function S.create(g)
 assert(g and g.newCanvas and g.setCanvas and g.push and g.pop,
  'Merchant surface needs a LÖVE graphics context')
 local w,h=S.width,S.height
 local canvas=g.newCanvas(w,h)
 g.push('all')
 local ok,err=xpcall(function()
  g.origin()
  g.setCanvas(canvas)
  local leather=S.palette.leather
  g.clear(leather[1],leather[2],leather[3],1)
  -- Broad, low-contrast fibres: unlike photographed marquetry,
  -- this texture stays quiet while the dice move.
  for k=1,34 do
   local y=k*h/35
   local strength=(k%4==0) and .075 or .035
   g.setColor(.13,.055,.045,strength)
   g.setLineWidth(1+(k%3)*.35)
   g.line(0,y+3*math.sin(k*.73),w,y+2*math.sin(k*.44))
  end
  -- Sparse deterministic grain, no math.random / love.math.random.
  -- Drawn once into the texture, never on each game frame.
  for i=1,1700 do
   local x=(i*641)%w
   local y=(i*257)%h
   local a=.012+((i*23)%7)*.002
   local light=i%3==0
   local c=light and S.palette.grain_light or S.palette.grain_dark
   g.setColor(c[1],c[2],c[3],a)
   g.rectangle('fill',x,y,1+(i%3),1)
  end
  -- The double hairline border is printed, not raised. Leave a generous
  -- inner panel free of filigree for all six real 3D dice.
  local border=S.palette.border
  g.setColor(border[1],border[2],border[3],.70)
  g.setLineWidth(3)
  g.rectangle('line',20,20,w-40,h-40,3,3)
  local dim=S.palette.border_dim
  g.setColor(dim[1],dim[2],dim[3],.78)
  g.setLineWidth(6)
  g.rectangle('line',28,28,w-56,h-56,2,2)
  g.setColor(.78,.56,.35,.55)
  g.setLineWidth(1)
  g.rectangle('line',35,35,w-70,h-70,2,2)
  -- Four mirrored motifs only: no central medallion, lattice, or HUD.
  local corners={
   {52,49,1,1},{w-52,49,-1,1},
   {52,h-49,1,-1},{w-52,h-49,-1,-1}
  }
  for _,corner in ipairs(corners) do
   g.push()
   g.translate(corner[1],corner[2])
   g.scale(corner[3],corner[4])
   flourish(g)
   g.pop()
  end
 end,debug.traceback)
 g.pop() -- reset render target, shader, transforms and colour even on error
 if not ok then canvas:release();error(err) end
 canvas:setFilter('linear','linear')
 return canvas
end
return S
