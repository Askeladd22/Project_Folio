-- Dice-only material configuration; no physics, gameplay, or external g3d edits.
-- Cycle with F10 while g3d is active. Pure helpers remain headless-testable.
local M={}
M.modes={'original','unlit','normals','diffuse','ivory'}
M.default='ivory'
M.shader_path='resources/shaders/dice_lit.glsl'
M.vertex_path='lib/g3d/g3d.vert'
local indexes={original=1,unlit=2,normals=3,diffuse=4,ivory=5}
local shader_modes={unlit=1,normals=2,diffuse=3,ivory=4}
function M.valid(mode) return indexes[mode]~=nil end
function M.next(mode)
 return M.modes[(indexes[mode] or 1)%#M.modes+1]
end
function M.uses_shader(mode) return shader_modes[mode]~=nil end
function M.shader_mode(mode) return shader_modes[mode] end
local function normalized(x,y,z)
 local len=math.sqrt(x*x+y*y+z*z)
 return {x/len,y/len,z/len}
end
M.light=normalized(-.46,-.34,.82)
M.fill=normalized(.65,.25,.72)
function M.view_direction(view)
 local yaw,pitch=view.yaw,view.pitch
 return normalized(math.sin(yaw)*math.sin(pitch),
                   math.cos(yaw)*math.sin(pitch),math.cos(pitch))
end
function M.tint(d8,mode)
 if mode=='diffuse' then return {1,1,1} end
 -- D8 has independently colored faces: don't turn its color cycle ivory.
 if d8 then return {1,1,1} end
 return {.98,.95,.89}
end
function M.configure(shader,mode,view,is_d8,index)
 assert(M.uses_shader(mode),'unsupported dice material mode')
 shader:send('debugMode',M.shader_mode(mode))
 shader:send('lightDirection',M.light)
 shader:send('fillDirection',M.fill)
 shader:send('viewDirection',M.view_direction(view))
 shader:send('materialTint',M.tint(is_d8,mode))
 local bone=mode=='ivory' and not is_d8
 shader:send('boneSurface',bone and 1 or 0)
 shader:send('boneSeed',((index or 1)-1)%6)
 shader:send('pipValue',0)
 shader:send('ambientStrength',bone and .50 or .46)
 shader:send('keyStrength',bone and .40 or .46)
 shader:send('fillStrength',bone and .18 or .15)
 shader:send('specularStrength',bone and .025 or .075)
 shader:send('specularExponent',30)
 shader:send('pipTexel',{0,0})
 shader:send('pipReliefStrength',.045)
end

-- Ivory uses the physical face value for procedural ring-and-dot pips.
-- Diagnostic textures retain their texel offset. Clear the value on bevels.
function M.configure_pips(shader,mode,texture,value)
 local step={0,0}
 if mode=='ivory' and texture and type(texture.getDimensions)=='function' then
  local w,h=texture:getDimensions()
  if w and h and w>0 and h>0 then step={1/w,1/h} end
 end
 shader:send('pipTexel',step)
 local pip=mode=='ivory' and type(value)=='number' and value%1==0
  and value>=1 and value<=6 and value or 0
 shader:send('pipValue',pip)
end
return M
