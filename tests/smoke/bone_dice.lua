-- Opt-in real GPU smoke. Exercises the shipping shader, renderer and portraits.
local S={}
function S.install()
 love.load=function()
  local ok,err=xpcall(function()
   local g=love.graphics
   local Material=require('src.engine3d.g3d_materials')
   local Mesh=require('src.engine3d.g3d_mesh')
   local Camera=require('src.engine3d.g3d_camera')
   local Geometry=require('src.engine3d.geometry')
   local Dice=require('src.features.farkle.dice')
   local Live=require('src.engine3d.g3d_live')
   local Portrait=require('src.engine3d.g3d_portrait')
   local g3d=require('lib.g3d')
   local shader=g.newShader(Material.shader_path,Material.vertex_path)
   local pixel=love.image.newImageData(1,1)
   pixel:setPixel(0,0,1,1,1,1)
   local white=g.newImage(pixel)
   local faceBody={{1,1,1},{1,-1,1},{-1,-1,1},{-1,1,1},position={0,0,0}}
   local face=g3d.newModel(Mesh.face_vertices(faceBody,{1,2,3,4},true),white)
   local flatView={yaw=0,pitch=0,distance=5,focus=5}
   local function rendered_face(value,is_d8)
    local canvas=g.newCanvas(128,128)
    g.push('all')
    g.origin();g.setScissor();g.setStencilTest();g.setMeshCullMode('none')
    g.setCanvas({canvas,depth=true});g.clear(0,0,0,0,true,1)
    g.setDepthMode('lequal',true);g.setColor(1,1,1,1)
    Camera.apply(flatView,g3d.camera,128,128,64)
    Material.configure(shader,'ivory',flatView,is_d8,1)
    Material.configure_pips(shader,'ivory',white,value)
    face:draw(shader)
    g.pop()
    local data=canvas:newImageData()
    canvas:release()
    return data
   end
   local function luminance(data,x,y)
    local r,green,b=data:getPixel(x,y)
    return .299*r+.587*green+.114*b
   end
   local function hole_count(data,positions)
    local count=0
    for _,x in ipairs(positions) do
     for _,y in ipairs(positions) do
      if luminance(data,x,y)<.30 then count=count+1 end
     end
    end
    return count
   end
   for value=1,6 do
    local data=rendered_face(value,false)
    local count=hole_count(data,{32,64,96})
    assert(count==value,('GPU face %d shows %d pip holes'):format(value,count))
    if value==1 then
     assert(luminance(data,64,64)<.30,'central pip must be recessed and dark')
     assert(luminance(data,73,64)+.08<luminance(data,69,64),
      'incised ring must be darker than its inner bone surface')
    end
    data:release()
   end
   local plain=rendered_face(0,false)
   assert(luminance(plain,64,64)>.60,'bevel must clear the previous face pip')
   plain:release()
   local d8=rendered_face(nil,true)
   local red,green,blue=d8:getPixel(64,64)
   assert(math.abs(red-green)<.03 and math.abs(green-blue)<.03,
    'D8 reference white must retain neutral color')
   d8:release()
   print('PASS GPU bone faces: six exact pip counts, incised rings and uniform reset')

   local entries={}
   local rotations={{0,0},{math.pi/2,0},{0,-math.pi/2},
    {0,math.pi/2},{-math.pi/2,0},{math.pi,0}}
   for i,angles in ipairs(rotations) do
    local body=Geometry.newD6Body(1):set(
     {((i-1)%3-1)*2.6,math.floor((i-1)/3)*2.7-1.35,.625},{0,0,0},{0,0,0})
    local cx,sx=math.cos(angles[1]),math.sin(angles[1])
    local cy,sy=math.cos(angles[2]),math.sin(angles[2])
    for _,point in ipairs(body) do
     local x,y,z=point[1],point[2],point[3]
     local rx,rz=x*cy+z*sy,-x*sy+z*cy
     point[1],point[2],point[3]=rx,y*cx-rz*sx,y*sx+rz*cx
    end
    local die={faces=Geometry.d6.faces,faceValueMap=Dice.values('normal',i)}
    entries[i]={index=i,entry={body=body,die=die}}
   end
   local view={yaw=-.25,pitch=.65,distance=14.1,focus=5}
   local renderer=Live.new()
   renderer.material_mode='ivory'
   renderer:draw{
    entries=entries,extents={-5.5,5.5,-3.5,3.5},height=.74,
    viewport={x=0,y=0,w=960,h=620},cx=480,cy=310,scale=210,
    view=view,style='merchant',offset=0,
   }
   -- Portrait capture uses the same face maps, patina and chamfer.
   for i,item in ipairs(entries) do
    g.setColor(.2,.3,.4,.5)
    local portrait=Portrait.capture(item.entry,view,i)
    local r,green,b,a=g.getColor()
    assert(math.abs(r-.2)<.001 and math.abs(a-.5)<.001,
     'portrait must restore graphics state')
    local data=portrait:newImageData()
    local visible=0
    for y=0,111 do
     for x=0,111 do
      local _,_,_,alpha=data:getPixel(x,y)
      if alpha>.5 then visible=visible+1 end
     end
    end
    assert(visible>300,'shelf portrait is empty')
    data:release();portrait:release()
   end
   -- Face 6 is the base 2 and points upward on this physical fixture.
   -- Reuse the same body, die and model cache while changing only its map.
   local entry=entries[2].entry
   local oldX,oldY=entry.body.position[1],entry.body.position[2]
   entry.body.position[1],entry.body.position[2]=0,0
   local focused={{index=1,entry=entry}}
   for _,build in ipairs{'normal','engraved'} do
    entry.die.faceValueMap=Dice.values(build,1)
    renderer:draw{
     entries=focused,extents={-1.5,1.5,-1.5,1.5},height=.74,
     viewport={x=0,y=0,w=128,h=128},cx=64,cy=64,scale=64,
     view=flatView,style='merchant',offset=0,
    }
    local data=renderer.canvas:newImageData()
    local expected=build=='normal' and 2 or 1
    assert(hole_count(data,{44,64,84})==expected,
     build..' live physical face has wrong pip count')
    assert((luminance(data,64,64)<.30)==(expected==1),
     'live face must change from diagonal holes to a central hole')
    data:release()
    local portrait=Portrait.capture(entry,flatView,1)
    local held=portrait:newImageData()
    assert(hole_count(held,{39,56,72})==expected,
     build..' accepted portrait has wrong pip count')
    assert((luminance(held,56,56)<.30)==(expected==1),
     'portrait must change from diagonal holes to a central hole')
    held:release();portrait:release()
   end
   print('PASS GPU physical 2 -> 1 mapping in live model cache and accepted portrait')
   entry.die.faceValueMap=Dice.values('normal',2)
   entry.body.position[1],entry.body.position[2]=oldX,oldY
   renderer:draw{
    entries=entries,extents={-5.5,5.5,-3.5,3.5},height=.74,
    viewport={x=0,y=0,w=960,h=620},cx=480,cy=310,scale=210,
    view=view,style='merchant',offset=0,
   }
   local preview=g.newCanvas(640,414)
   g.push('all')
   g.origin();g.setCanvas(preview);g.clear(.16,.12,.08,1)
   g.setDepthMode();g.setShader();g.setColor(1,1,1,1)
   g.setBlendMode('alpha','premultiplied')
   g.draw(renderer.canvas,0,0,0,640/960,414/620)
   g.pop()
   local image=preview:newImageData()
   local png=image:encode('png')
   local encoded=love.data.encode('string','base64',png:getString())
   print('BONE_PREVIEW_BEGIN')
   for i=1,#encoded,4096 do print(encoded:sub(i,i+4095)) end
   print('BONE_PREVIEW_END')
   image:release();preview:release();png:release()
   print('PASS GPU bone live renderer, engraved mapping and six shelf portraits')
  end,debug.traceback)
  if not ok then print('FAIL GPU bone dice: '..tostring(err)) end
  love.event.quit(ok and 0 or 1)
 end
end
return S
