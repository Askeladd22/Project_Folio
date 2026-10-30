-- Opt-in g3d GPU dice + book rim for the real Scriptorium.
-- Owns graphics only. Reads existing physical positions, faces and textures,
-- never RNG, dice scores, physics steps, input picking or HUD state.
-- Vendored g3d is deliberately loaded ONLY after explicit opt-in.
local M={}
M.__index=M

local function supported(entries)
 for _,entry in ipairs(entries) do
  local die=(entry.entry or entry).die
  if not die or not die.faces or #die.faces~=6 or not die.faceValueMap then
   return false
  end
  for i,face in ipairs(die.faces) do
   if #face~=4 or not die.faceValueMap[i] then return false end
  end
 end
 return true
end

function M.new()
 return setmetatable({
  enabled=true,failed=nil,models={},images={},canvas=nil,
  width=0,height=0,walls=nil,wall_signature=nil,
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

function M:_ensure(entries,extents,border,viewport)
 local g=love.graphics
 if not self.g3d then
  self.g3d=require('experiments.g3d_lab.g3d')
  self.mesh=require('experiments.g3d_lab.mesh')
  self.camera=require('experiments.g3d_lab.camera')
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
  string.format('%.5f',border),
  string.format('%.5f',extents[1]),string.format('%.5f',extents[2]),
  string.format('%.5f',extents[3]),string.format('%.5f',extents[4])
 },':')
 if self.wall_signature~=rimkey then
  if self.walls and self.walls.mesh then self.walls.mesh:release() end
  self.walls=self.g3d.newModel(
   rim_vertices(self.mesh,extents,.85,border),self.white)
  self.wall_signature=rimkey
 end
end

function M:_update_faces(entries,draw_offset)
 local g3d=self.g3d
 local active={}
 for _,item in ipairs(entries) do
  local entry=item.entry
  local key=item.index
  local record=self.models[key]
  if not record or record.body~=entry.body or record.die~=entry.die then
   if record then
    for _,model in ipairs(record.faces) do model.mesh:release() end
   end
   record={body=entry.body,die=entry.die,faces={}}
   self.models[key]=record
  end
  active[key]=true
  for i,face in ipairs(entry.die.faces) do
   local value=entry.die.faceValueMap[i]
   local img=self.images[value]
   local verts=vertices(self.mesh,entry,face,draw_offset)
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
 end
 -- Avoid retaining stale references to dice replaced by the controller.
 for index,record in pairs(self.models) do
  if not active[index] then
   for _,model in ipairs(record.faces) do model.mesh:release() end
   self.models[index]=nil
  end
 end
end

function M:_draw_scene(args)
 local g=love.graphics
 local vp=args.viewport
 self:_ensure(args.entries,args.extents,args.height,vp)
 self:_update_faces(args.entries,args.offset)
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
   g.setDepthMode('lequal',true)
   g.setShader()
   g.setBlendMode('alpha','alphamultiply')
   g.setColor(1,1,1,1)
   self.walls:draw()
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
  -- Keep the legacy renderer playable after a graphics failure.
  pcall(function()
   love.graphics.setCanvas()
   love.graphics.setDepthMode()
   love.graphics.setStencilTest()
   love.graphics.setScissor()
   love.graphics.origin()
  end)
  print('[Manuscript experimental g3d] falling back to painter: '..tostring(err))
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
return M
