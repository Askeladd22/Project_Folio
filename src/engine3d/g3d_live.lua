-- Production g3d GPU dice + book rim; legacy is the F9 fallback.
-- Owns graphics only. Reads existing physical positions, faces and textures,
-- never RNG, dice scores, physics steps, input picking or HUD state.
-- The GPU library loads lazily on first supported draw; physics and gameplay are untouched.
local M={}
M.__index=M
local Scenery=require('src.engine3d.g3d_scenery')

local function supported(entries)
 for _,entry in ipairs(entries) do
  local die=(entry.entry or entry).die
  if not die or not die.faces or (#die.faces~=6 and #die.faces~=8) or not die.faceValueMap then
   return false
  end
  for i,face in ipairs(die.faces) do
   if (#face~=3 and #face~=4) or not die.faceValueMap[i] then return false end
  end
 end
 return true
end

function M.new()
 return setmetatable({
  enabled=true,failed=nil,models={},images={},canvas=nil,
  width=0,height=0,floor_model=nil,walls=nil,lines=nil,divider_model=nil,wall_signature=nil,
 },M)
end

-- Geometry follows the physical bodies, including draw offsets for old
-- logical tray regions. No mutation of body.position or face values.
local function vertices(mesh,entry,face,offset)
 local out=mesh.face_vertices(entry.body,face)
 for _,v in ipairs(out) do
  v[1]=v[1]-(offset or 0)
 end
 return out
end

local function rim_vertices(mesh,extents,thickness,height)
 local v=mesh.tray_border_vertices(
  extents[1],extents[2],extents[3],extents[4],thickness,height,8)
 -- The 'book' workshop uses parchment page blocks and a dark left spine.
 -- Keep its palette instead of the walnut border from the standalone A/B lab.
 local shades={
  {{.76,.67,.51},{.60,.50,.355},{.86,.775,.61}},
  {{.76,.67,.51},{.60,.50,.355},{.86,.775,.61}},
  {{.76,.67,.51},{.60,.50,.355},{.86,.775,.61}},
  {{.26,.12,.075},{.37,.225,.14},{.31,.17,.105}},
 }
 local stride=8*6
 for side=1,4 do
  for part=1,3 do
   local rgb=shades[side][part]
   local start=((side-1)*3+(part-1))*stride+1
   for i=start,start+stride-1 do
    local vertex=v[i]
    vertex[9],vertex[10],vertex[11]=rgb[1],rgb[2],rgb[3]
   end
  end
 end
 return v
end


-- Soft radial contact shadow on the unchanged z=0 manuscript floor.
local function shadow_vertices(body,offset)
 local p=assert(body.position,'physical body position required')
 local h=math.max(0,p[3] or 0)
 local radius=math.max(.32,(body.radius or .65)*.90)*(1+math.min(h,8)*.025)
 local alpha=.26/(1+h*.22)
 local cx=p[1]-(offset or 0)+h*.11
 local cy=p[2]-h*.07
 local vertices={}
 local function vertex(x,y,a)
  return {x,y,.012,0,0,0,0,1,.16,.105,.06,a}
 end
 for i=0,23 do
  local a=i*math.pi/12
  local b=(i+1)*math.pi/12
  vertices[#vertices+1]=vertex(cx,cy,alpha)
  vertices[#vertices+1]=vertex(cx+radius*math.cos(a),cy+radius*math.sin(a),0)
  vertices[#vertices+1]=vertex(cx+radius*math.cos(b),cy+radius*math.sin(b),0)
 end
 return vertices
end

-- Seven folio lines on the three visible paper edges, excluding leather spine.
local function page_rule_vertices(extents,width,height)
 local x1,x2,y1,y2=unpack(extents)
 local outer={{x1-width,y1-width},{x2+width,y1-width},
              {x2+width,y2+width},{x1-width,y2+width}}
 local vertices={}
 local function vertex(x,y,z)
  return {x,y,z,0,0,0,0,1,.32,.245,.155,.29}
 end
 for side=1,3 do
  local a,b=outer[side],outer[side+1]
  local dx,dy=b[1]-a[1],b[2]-a[2]
  local len=math.sqrt(dx*dx+dy*dy)
  local nx,ny=dy/len*.018,-dx/len*.018
  for layer=1,7 do
   local z=height*layer/9
   local ax,ay=a[1]+nx,a[2]+ny
   local bx,by=b[1]+nx,b[2]+ny
   local p=vertex(ax,ay,z-.014)
   local q=vertex(bx,by,z-.014)
   local r=vertex(bx,by,z+.014)
   local s=vertex(ax,ay,z+.014)
   vertices[#vertices+1]=p;vertices[#vertices+1]=q;vertices[#vertices+1]=r
   vertices[#vertices+1]=p;vertices[#vertices+1]=r;vertices[#vertices+1]=s
  end
 end
 return vertices
end

local function highlight_vertices(vertices,active)
 if active then
  for _,v in ipairs(vertices) do
   v[9]=math.min(1,v[9]*.87+.13)
   v[10]=math.min(1,v[10]*.81+.14)
   v[11]=math.min(1,v[11]*.65+.09)
  end
 end
 return vertices
end

function M:_ensure(entries,extents,border,viewport,style,divider)
 local g=love.graphics
 if not self.g3d then
  self.g3d=require('lib.g3d')
  self.mesh=require('src.engine3d.g3d_mesh')
  self.camera=require('src.engine3d.g3d_camera')
  -- g3d sets global depth on import; 2D UI must retain its initial state.
  g.setDepthMode()
 end
 local w=math.max(1,math.ceil(viewport.w))
 local h=math.max(1,math.ceil(viewport.h))
 if self.width~=w or self.height~=h then
  if self.canvas then self.canvas:release() end
  self.canvas=g.newCanvas(w,h)
  self.width,self.height=w,h
 end
 if not self.white then
  local pixel=love.image.newImageData(1,1)
  pixel:setPixel(0,0,1,1,1,1)
  self.white=g.newImage(pixel)
 end
 for n=1,6 do
  if not self.images[n] then
   self.images[n]=g.newImage('resources/dice/'..n..'.png')
   self.images[n]:setFilter('linear','linear')
  end
 end
 local rimkey=table.concat({
  tostring(style),tostring(divider and divider.back_x),
  tostring(divider and divider.front_x),tostring(divider and divider.back_y),
  tostring(divider and divider.front_y),tostring(divider and divider.width),
  tostring(divider and divider.height),
  string.format('%.5f',border),
  string.format('%.5f',extents[1]),string.format('%.5f',extents[2]),
  string.format('%.5f',extents[3]),string.format('%.5f',extents[4])
 },':')
 if self.wall_signature~=rimkey then
  if self.floor_model and self.floor_model.mesh then self.floor_model.mesh:release() end
  if self.walls and self.walls.mesh then self.walls.mesh:release() end
  if self.lines and self.lines.mesh then self.lines.mesh:release() end
  if self.divider_model and self.divider_model.mesh then self.divider_model.mesh:release() end
  -- The single opaque GPU floor replaces the historical overlaid 2D book
  -- ornaments. It participates in the SAME depth buffer as walls and dice.
  self.floor_model=self.g3d.newModel(
   Scenery.floor_vertices(self.mesh,extents,style),self.white)
  self.walls=self.g3d.newModel(
   Scenery.style_vertices(self.mesh,extents,border,style),self.white)
  -- Do not overlay ruling lines across the play surface in the clean mode.
  self.lines=nil
  local divider_vertices=Scenery.divider_vertices(divider)
  self.divider_model=divider_vertices and self.g3d.newModel(divider_vertices,self.white) or nil
  self.wall_signature=rimkey
 end
end

function M:_update_faces(entries,draw_offset,usable_map)
 local g3d=self.g3d
 local active={}
 for _,item in ipairs(entries) do
  local entry=item.entry
  local key=item.index
  local record=self.models[key]
  if not record or record.body~=entry.body or record.die~=entry.die then
   if record then
    for _,model in ipairs(record.faces) do model.mesh:release() end
    if record.shadow then record.shadow.mesh:release() end
   end
   record={body=entry.body,die=entry.die,faces={}}
   self.models[key]=record
  end
  active[key]=true
  for i,face in ipairs(entry.die.faces) do
   local value=entry.die.faceValueMap[i]
   local img=#face==4 and self.images[value] or self.white
   local verts=vertices(self.mesh,entry,face,draw_offset)
   if #face==3 then
    -- Historical D8 has no face texture; retain its per-face flat colours.
    local tint=Scenery.face_color(entry.die,i)
    for _,v in ipairs(verts) do
     v[9]=v[9]*tint[1];v[10]=v[10]*tint[2];v[11]=v[11]*tint[3]
    end
   end
   verts=highlight_vertices(verts,
    usable_map and usable_map[key])
   -- Real Farkle dice.image intentionally draws the white pip texture
   -- with setColor(1,1,1,1), overriding faceColors. Preserve that
   -- appearance; applying faceColors here would turn every die brown.
   if record.faces[i] then
    record.faces[i].mesh:setVertices(verts)
    record.faces[i].mesh:setTexture(img)
   else
    record.faces[i]=g3d.newModel(verts,img)
   end
  end
  local shadow=shadow_vertices(entry.body,draw_offset)
  if record.shadow then record.shadow.mesh:setVertices(shadow)
  else record.shadow=g3d.newModel(shadow,self.white) end
 end
 -- Avoid retaining stale references to dice replaced by the controller.
 for index,record in pairs(self.models) do
  if not active[index] then
   for _,model in ipairs(record.faces) do model.mesh:release() end
   if record.shadow then record.shadow.mesh:release() end
   self.models[index]=nil
  end
 end
end

function M:_draw_scene(args)
 local g=love.graphics
 local vp=args.viewport
 self:_ensure(args.entries,args.extents,args.height,vp,args.style,args.divider)
 self:_update_faces(args.entries,args.offset,args.usable)
 local cam=self.g3d.camera
 self.camera.apply(args.view,cam,self.width,self.height,args.scale)
 -- Shift orthographic clip space to the exact projected tray position.
 -- Camera.apply's centre is canvas centre; the legacy overlay may use
 -- a different centre due to fitting, so preserve that screen alignment.
 local dx=args.cx-vp.x-self.width/2
 local dy=args.cy-vp.y-self.height/2
 cam.projectionMatrix[4]=cam.projectionMatrix[4]+2*dx/self.width
 cam.projectionMatrix[8]=cam.projectionMatrix[8]-2*dy/self.height
 g.push('all')
 local ok,err=xpcall(function()
   -- Rendering happens in a tray-local Canvas, in pixel coordinates.
   -- Remove any parent's 2D transform, clipping or stencil during 3D draws.
   g.origin()
   g.setScissor()
   g.setStencilTest()
   g.setCanvas({self.canvas,depth=true})
   g.clear(0,0,0,0,true,1)
   g.setShader()
   g.setBlendMode('alpha','alphamultiply')
   g.setColor(1,1,1,1)
   -- Opaque floor writes depth first. Transparent shadows then test it
   -- without writing depth; the actual 3D walls and dice always occlude.
   g.setDepthMode('lequal',true)
   self.floor_model:draw()
   g.setDepthMode('lequal',false)
   for _,item in ipairs(args.entries) do
    self.models[item.index].shadow:draw()
   end
   g.setDepthMode('lequal',true)
   self.walls:draw()
   if self.divider_model then self.divider_model:draw() end
   for _,item in ipairs(args.entries) do
    local models=self.models[item.index]
    for _,m in ipairs(models.faces) do m:draw() end
   end
   g.setDepthMode()
   g.setCanvas()
   -- Restore the tray's original clip when compositing the transparent layer.
   g.setScissor(
    math.floor(vp.x),math.floor(vp.y),
    math.ceil(vp.w),math.ceil(vp.h))
   if args.mask then g.setStencilTest('greater',0) end
   g.setBlendMode('alpha','premultiplied')
   g.setColor(1,1,1,1)
   g.draw(self.canvas,vp.x,vp.y)
 end,debug.traceback)
 g.pop() -- always restore 2D transforms/clip/shaders even after an error
 if not ok then error(err) end
end

function M:draw(args)
 if not self.enabled then return false end
 if not supported(args.entries) then return false end
 local ok,err=xpcall(function() self:_draw_scene(args) end,debug.traceback)
 if not ok then
  self.failed=err
  self.enabled=false
  -- Preserve the painter's active translated/scaled tray transform.
  -- _draw_scene wraps graphics in push('all') / pop(); an additional
  -- graphics.origin() here previously broke the F9/error fallback.
  pcall(function() love.graphics.setDepthMode() end)
  print('[Manuscript g3d] reverting to legacy painter: '..tostring(err))
  return false
 end
 return true
end

function M:toggle()
 self.enabled=not self.enabled
 self.failed=nil
 return self.enabled
end

function M.supported(entries)
 return supported(entries)
end
function M.rim_vertices(mesh,extents,thickness,height)
 return rim_vertices(mesh,extents,thickness,height)
end
M.shadow_vertices=shadow_vertices
M.page_rule_vertices=page_rule_vertices
M.highlight_vertices=highlight_vertices
return M
