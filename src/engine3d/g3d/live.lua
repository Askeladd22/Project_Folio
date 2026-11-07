local Parts = {}

-- Accepted-die portrait
Parts.portrait = (function()
-- GPU portrait of an already accepted physical die for the shelf HUD.
-- Captures once per held die, without stepping physics or changing a score.
local P={}
local images={}
local Scene=require('src.engine3d.g3d.scene')
local Materials=Scene.materials
local Bevel=Scene.bevel
local dice_shader
local function physical_pose(entry)
 local body=assert(entry.body,'die body required')
 local copy={position={0,0,0}}
 -- Undo the tabletop scale on the portrait copy to retain its framing.
 local scale=entry.tableScale or 1
 for i,v in ipairs(body) do copy[i]={v[1]/scale,v[2]/scale,v[3]/scale} end
 return copy
end
P.physical_pose=physical_pose
function P.capture(entry,projection,index)
 assert(entry and entry.die and entry.body,'held die required')
 assert(projection and projection.pitch and projection.yaw,'tray projection required')
 local g=assert(love and love.graphics,'LÖVE graphics required')
 local models={}
 local image=nil
 g.push('all')
 local ok,result=xpcall(function()
  local g3d=require('lib.g3d')
  local Mesh=Scene.mesh
  local Camera=Scene.camera
  local body=physical_pose(entry)
  local is_d8=#entry.die.faces==8
  local shader
  if Materials.uses_shader(Materials.default) then
   dice_shader=dice_shader or g.newShader(Materials.shader_path,Materials.vertex_path)
   shader=dice_shader
  end
  local size=112
  image=g.newCanvas(size,size)
  local v={yaw=projection.yaw,pitch=projection.pitch,distance=14.1,focus=5}
  Camera.apply(v,g3d.camera,size,size,150)
  g.origin()
  g.setCanvas({image,depth=true})
  g.clear(0,0,0,0,true,1)
  g.setDepthMode('lequal',true)
  g.setShader()
  g.setColor(1,1,1,1)
  g.setBlendMode('alpha','alphamultiply')
  if not images.white then
   local pixel=love.image.newImageData(1,1)
   pixel:setPixel(0,0,1,1,1,1)
   images.white=g.newImage(pixel)
  end
  if shader then Materials.configure(shader,Materials.default,v,is_d8,index) end
  for face_idx,face in ipairs(entry.die.faces) do
   local key=entry.die.faceValueMap[face_idx]
   local texture
   if #face==4 and key and key>=1 and key<=6 then
    if not images[key] then images[key]=g.newImage('resources/dice/'..key..'.png') end
    texture=images[key]
   else
    texture=images.white
   end
   local vertices=not is_d8 and Bevel.face_vertices(Mesh,body,face,true,Bevel.default_fraction)
    or Mesh.face_vertices(body,face,shader~=nil)
   if #face==3 then
    local tint=Scene.scenery.face_color(entry.die,face_idx)
    for _,vert in ipairs(vertices) do
     vert[9]=vert[9]*tint[1]
     vert[10]=vert[10]*tint[2]
     vert[11]=vert[11]*tint[3]
    end
   end
   local model=g3d.newModel(vertices,texture)
   models[#models+1]=model
   if shader then Materials.configure_pips(shader,Materials.default,texture,not is_d8 and key or nil) end
   model:draw(shader)
  end
  if not is_d8 then
   local bevel=g3d.newModel(Bevel.rim_vertices(body,entry.die.faces,Bevel.default_fraction),images.white)
   models[#models+1]=bevel
   if shader then Materials.configure_pips(shader,Materials.default,nil) end
   bevel:draw(shader)
  end
  g.setDepthMode()
  g.setCanvas()
  return image
 end,debug.traceback)
 for _,model in ipairs(models) do pcall(function() model.mesh:release() end) end
 g.pop()
 if not ok then
  if image then pcall(function() image:release() end) end
  error(result)
 end
 return result
end
return P
end)()

-- Live 3D renderer
Parts.renderer = (function()
-- Production g3d GPU dice and book rim. The only 3D renderer.
-- Owns graphics only. Reads existing physical positions, faces and textures,
-- never RNG, dice scores, physics steps, input picking or HUD state.
-- The GPU library loads lazily on first supported draw; physics and gameplay are untouched.
local M={}
M.__index=M
local Scene=require('src.engine3d.g3d.scene')
local Scenery=Scene.scenery
local Materials=Scene.materials
local Bevel=Scene.bevel
local shadow_vertices=Scene.shadow

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
 local override=os.getenv('MANUSCRIPT_DICE_MATERIAL')
 local mode=Materials.valid(override) and override or Materials.default
 return setmetatable({
  models={},images={},canvas=nil,
  material_mode=mode,dice_shader=nil,
  bevel_enabled=true,bevel_fraction=Bevel.default_fraction,
  width=0,height=0,floor_model=nil,walls=nil,lines=nil,divider_model=nil,wall_signature=nil,
 },M)
end

-- F10 visual A/B: legacy baked-lighting, unlit textures, face-normal
-- diagnostics, diffuse, and warm ivory. Does not affect game physics.
function M:cycle_material()
 self.material_mode=Materials.next(self.material_mode)
 return self.material_mode
end

-- F11: visually compare exact physical box edges against chamfered art.
-- 'original' and 'unlit' retain the pristine original D6 reference faces.
function M:toggle_bevel()
 self.bevel_enabled=not self.bevel_enabled
 return self.bevel_enabled
end
function M:uses_bevel(entry)
 return self.bevel_enabled and Materials.uses_shader(self.material_mode)
  and self.material_mode~='unlit'
  and entry and entry.die and #entry.die.faces==6
end


-- Geometry follows the physical bodies, including draw offsets for old
-- logical tray regions. No mutation of body.position or face values.
local function vertices(mesh,entry,face,offset,preview,raw_lighting,bevel_fraction)
 local out=bevel_fraction and Bevel.face_vertices(
  mesh,entry.body,face,raw_lighting,bevel_fraction)
   or mesh.face_vertices(entry.body,face,raw_lighting)
 for _,v in ipairs(out) do
  v[1]=v[1]-(offset or 0)+(preview and preview.x or 0)
  v[2]=v[2]+(preview and preview.y or 0)
  v[3]=v[3]+(preview and preview.z or 0)
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
  self.mesh=Scene.mesh
  self.camera=Scene.camera
  -- g3d sets global depth on import; 2D UI must retain its initial state.
  g.setDepthMode()
 end
 if Materials.uses_shader(self.material_mode) and not self.dice_shader then
  -- Required shader compilation errors are explicit, never silently
  -- replaced by another material or a second renderer.
  self.dice_shader=g.newShader(Materials.shader_path,Materials.vertex_path)
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
  if self.table_prop and self.table_prop.mesh then self.table_prop.mesh:release() end
  self.table_prop=nil
  if self.walls and self.walls.mesh then self.walls.mesh:release() end
  if self.lines and self.lines.mesh then self.lines.mesh:release() end
  if self.divider_model and self.divider_model.mesh then self.divider_model.mesh:release() end
  -- The single opaque GPU floor replaces the historical overlaid 2D book
  -- ornaments. It participates in the SAME depth buffer as walls and dice.
  -- Merchant imagery now lives in the independent 2D opponent layer.
  -- The former floor and carving JPGs were deleted with that art split:
  -- only the retained shared wood texture is part of the GPU tray.
  local floor_texture=self.white
  if style=='merchant' then
   if not self.merchantWood then
    self.merchantWood=g.newImage('resources/textures/wood.png',{mipmaps=true})
    self.merchantWood:setFilter('linear','linear')
    self.merchantWood:setMipmapFilter('linear')
   end
   floor_texture=self.merchantWood
   -- Optional decorative GLB table; physics walls and picking never see it.
   local prop=Scenery.table_prop
   if love.filesystem.getInfo(prop.path,'file') then
    self.table_prop=require('src.engine3d.g3d.glb_loader').load(self.g3d,prop.path,function(model)
     if prop.remap then Scenery.remap_axes(model,prop.remap) end
     Scenery.place_table(model,extents,.28)
    end,prop)
    self.table_shader=self.table_shader or g.newShader(prop.shader,'lib/g3d/g3d.vert')
    self.table_shader:send('tableCenter',{
     (extents[1]+extents[2])*.5,(extents[3]+extents[4])*.5})
    self.table_shader:send('tableHalf',{
     (extents[2]-extents[1])*.5,(extents[4]-extents[3])*.5})
    self.table_prop.shader=self.table_shader
   end
  end
  self.floor_model=self.g3d.newModel(
   Scenery.floor_vertices(self.mesh,extents,style),floor_texture)
  self.walls=self.g3d.newModel(
   Scenery.style_vertices(self.mesh,extents,border,style),floor_texture)
  -- Do not overlay ruling lines across the play surface in the clean mode.
  self.lines=nil
  local divider_vertices=Scenery.divider_vertices(divider)
  self.divider_model=divider_vertices and self.g3d.newModel(divider_vertices,self.white) or nil
  self.wall_signature=rimkey
 end
end

function M:_update_faces(entries,draw_offset,usable_map,drag_preview)
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
    if record.bevel then record.bevel.mesh:release() end
   end
   record={body=entry.body,die=entry.die,faces={}}
   self.models[key]=record
  end
  active[key]=true
  local bevel_on=self:uses_bevel(entry)
  local preview=drag_preview and drag_preview.index==key and drag_preview or nil
  for i,face in ipairs(entry.die.faces) do
   local value=entry.die.faceValueMap[i]
   local img=#face==4 and self.images[value] or self.white
   local verts=vertices(self.mesh,entry,face,draw_offset,preview,
     Materials.uses_shader(self.material_mode),bevel_on and self.bevel_fraction or nil)
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
  if bevel_on then
   local cut=Bevel.rim_vertices(entry.body,entry.die.faces,self.bevel_fraction)
   for _,v in ipairs(cut) do
    v[1]=v[1]-(draw_offset or 0)+(preview and preview.x or 0)
    v[2]=v[2]+(preview and preview.y or 0)
    v[3]=v[3]+(preview and preview.z or 0)
   end
   if record.bevel then record.bevel.mesh:setVertices(cut)
   else record.bevel=g3d.newModel(cut,self.white) end
  elseif record.bevel then
   record.bevel.mesh:release()
   record.bevel=nil
  end
  local shadow=shadow_vertices(entry.body,draw_offset,preview)
  if record.shadow then record.shadow.mesh:setVertices(shadow)
  else record.shadow=g3d.newModel(shadow,self.white) end
 end
 -- Avoid retaining stale references to dice replaced by the controller.
 for index,record in pairs(self.models) do
  if not active[index] then
   for _,model in ipairs(record.faces) do model.mesh:release() end
   if record.shadow then record.shadow.mesh:release() end
   if record.bevel then record.bevel.mesh:release() end
   self.models[index]=nil
  end
 end
end

function M:_draw_scene(args)
 local g=love.graphics
 local vp=args.viewport
 self:_ensure(args.entries,args.extents,args.height,vp,args.style,args.divider)
 self:_update_faces(args.entries,args.offset,args.usable,args.drag_preview)
 local cam=self.g3d.camera
 local dx=args.cx-vp.x-self.width/2
 local dy=args.cy-vp.y-self.height/2
 self.camera.apply(args.view,cam,self.width,self.height,args.scale,dx,dy)
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
   if self.table_prop then self.table_prop:draw() else self.floor_model:draw() end
   g.setDepthMode('lequal',false)
   -- A shadow may darken an opaque floor pixel, but cannot create tray pixels
   -- beyond its edge. Keep the receiver alpha when blending pure black.
   g.setColorMask(true,true,true,false)
   for _,item in ipairs(args.entries) do
    self.models[item.index].shadow:draw()
   end
   g.setColorMask(true,true,true,true)
   g.setDepthMode('lequal',true)
   self.walls:draw()
   if self.divider_model then self.divider_model:draw() end
   for _,item in ipairs(args.entries) do
    local models=self.models[item.index]
    local shader=Materials.uses_shader(self.material_mode) and self.dice_shader or nil
    if shader then
     Materials.configure(shader,self.material_mode,args.view,#item.entry.die.faces==8,item.index)
    end
    for face_index,m in ipairs(models.faces) do
     if shader then
      local value=#item.entry.die.faces==6 and item.entry.die.faceValueMap[face_index] or nil
      Materials.configure_pips(shader,self.material_mode,m.texture,value)
     end
     m:draw(shader)
    end
    if models.bevel then
     if shader then Materials.configure_pips(shader,self.material_mode,nil) end
     models.bevel:draw(shader)
    end
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
  assert(type(args)=='table' and type(args.entries)=='table',
   'g3d needs an explicit scene')
  assert(supported(args.entries),'unsupported die mesh in g3d scene')
  -- _draw_scene restores the complete LÖVE graphics state on error.
  -- Fail explicitly rather than silently switching renderers mid-roll.
  self:_draw_scene(args)
  return true
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
end)()

Parts.renderer.portrait = Parts.portrait
return Parts.renderer
